using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading;
using MongoDB.Bson;
using MongoDB.Driver;

namespace AccountGranter
{
    /// <summary>
    /// Описание одного поля, которое необходимо выдать аккаунту.
    /// Бывает двух видов: обычное (фиксированное минимальное значение)
    /// и временное (метка времени "сейчас + срок", в миллисекундах Unix).
    /// </summary>
    class Grant
    {
        /// <summary>Имя поля в документе MongoDB.</summary>
        public string Field;

        private readonly BsonValue _fixed;     // фиксированное значение (для обычных полей)
        private readonly TimeSpan _ahead;      // срок вперёд от текущего момента (для полей-времени)
        private readonly bool _isTime;         // true, если поле хранит время

        /// <summary>Обычное поле: фиксированное минимальное значение.</summary>
        public Grant(string field, BsonValue value)
        {
            Field = field;
            _fixed = value;
            _isTime = false;
        }

        /// <summary>Поле-время: значение = текущий момент + срок (мс Unix, Int64).</summary>
        public Grant(string field, TimeSpan ahead)
        {
            Field = field;
            _ahead = ahead;
            _isTime = true;
        }

        /// <summary>Текущее время в миллисекундах Unix.</summary>
        private static long NowMs()
        {
            return (long)(DateTime.UtcNow - new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc)).TotalMilliseconds;
        }

        /// <summary>Что записываем в базу через $max.</summary>
        public BsonValue Value
        {
            get
            {
                if (_isTime) return new BsonInt64(NowMs() + (long)_ahead.TotalMilliseconds);
                return _fixed;
            }
        }

        /// <summary>
        /// Порог для проверки: если значение в базе меньше, выдача нужна.
        /// Для времени это "сейчас" (то есть срок уже истёк).
        /// </summary>
        public BsonValue MinValue
        {
            get
            {
                if (_isTime) return new BsonInt64(NowMs());
                return _fixed;
            }
        }
    }

    /// <summary>
    /// Главный класс программы: следит за коллекцией accounts
    /// и выдаёт новым аккаунтам заданные ресурсы.
    /// </summary>
    class Program
    {
        // ===== Настройки =====
        /// <summary>Строка подключения к локальной MongoDB.</summary>
        const string ConnStr = "mongodb://127.0.0.1:27017";

        /// <summary>Имя коллекции с аккаунтами.</summary>
        const string CollName = "accounts";

        /// <summary>Имя файла конфигурации (используется, если база не найдена автоматически).</summary>
        const string ConfigFile = "config.txt";

        /// <summary>Файл, в котором хранится _id последнего обработанного аккаунта.</summary>
        const string StateFile = "last_id.txt";

        /// <summary>Маска файла-признака базы данных игры в папке data.</summary>
        const string DbFilePattern = "cosmosim_*.ns";

        /// <summary>Пауза между итерациями опроса коллекции, мс.</summary>
        const int PollMs = 1000;

        /// <summary>Сколько секунд перепроверять аккаунт после выдачи.</summary>
        const int RecheckSeconds = 90;
        // =====================

        /// <summary>
        /// Что выдаём. $max поднимает значение и никогда не уменьшает.
        /// eventCredits обязательно Int64 (NumberLong), иначе в базе окажется обычный int.
        /// eventCreditsTime = текущий момент + 5 лет.
        /// </summary>
        static readonly Grant[] Grants = new Grant[]
        {
            new Grant("tokenCredits",     new BsonInt64(999999999)),   // Токены (64-бит)
            new Grant("vesselExpPool",    new BsonInt32(999999999)),   // Опыт корабля
            new Grant("accountExpPool",   new BsonInt32(10000)),       // Опыт аккаунта
            new Grant("accountRank",      new BsonInt32(25)),          // Ранг аккаунта
            new Grant("eventCredits",     new BsonInt64(999999999)),   // Ивентовые кредиты (64-бит)
            new Grant("eventCreditsTime", TimeSpan.FromDays(365 * 10))  // Срок действия: 10 лет
        };

        /// <summary>
        /// Загружает конфигурацию из текстового файла.
        /// Ожидаемый формат строк: ключ = "значение";
        /// </summary>
        static Dictionary<string, string> LoadConfig(string path)
        {
            Dictionary<string, string> result =
                new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            string text = File.ReadAllText(path);
            foreach (Match m in Regex.Matches(text, @"(\w+)\s*=\s*""([^""]*)""\s*;"))
            {
                result[m.Groups[1].Value] = m.Groups[2].Value;
            }
            return result;
        }

        /// <summary>
        /// Ищет базу в папке данных MongoDB игры: по файлу cosmosim_XXX.ns определяет имя базы.
        /// stats_cosmosim_XXX.ns под маску "cosmosim_*.ns" не попадает.
        /// </summary>
        static string FindDbInAppData()
        {
            try
            {
                string dir = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    @"Targem\StarConflict\cloud\mongodb\data");
                if (!Directory.Exists(dir))
                    return null;

                string[] files = Directory.GetFiles(dir, DbFilePattern);
                if (files.Length == 0)
                    return null;

                // если баз несколько - берём ту, что менялась последней
                string best = files.OrderByDescending(f => File.GetLastWriteTime(f)).First();
                return Path.GetFileNameWithoutExtension(best);
            }
            catch (Exception e)
            {
                Console.WriteLine("Не удалось просканировать AppData: " + e.Message);
                return null;
            }
        }

        /// <summary>
        /// Собирает UpdateDefinition для всех полей из Grants (оператор $max).
        /// </summary>
        static UpdateDefinition<BsonDocument> BuildUpdate()
        {
            UpdateDefinitionBuilder<BsonDocument> b = Builders<BsonDocument>.Update;
            UpdateDefinition<BsonDocument> u = null;
            foreach (Grant g in Grants)
            {
                if (u == null) u = b.Max(g.Field, g.Value);
                else u = u.Max(g.Field, g.Value);
            }
            return u;
        }

        /// <summary>
        /// Проверяет, нужно ли выдать аккаунту ресурсы (хотя бы одно поле меньше порога
        /// или отсутствует/не является числом).
        /// </summary>
        static bool NeedsGrant(BsonDocument d)
        {
            foreach (Grant g in Grants)
            {
                BsonValue cur;
                if (!d.TryGetValue(g.Field, out cur) || !cur.IsNumeric || cur.ToDouble() < g.MinValue.ToDouble())
                    return true;
            }
            return false;
        }

        /// <summary>
        /// Точка входа. Определяет имя базы, подключается к MongoDB
        /// и в бесконечном цикле обрабатывает новые и недавно изменённые аккаунты.
        /// "--all" — обработать и уже существующие аккаунты.
        /// </summary>
        static void Main(string[] args)
        {
            // ===== Определение имени базы =====
            // 1. Автопоиск в AppData
            string dbName = FindDbInAppData();
            if (!string.IsNullOrWhiteSpace(dbName))
            {
                Console.WriteLine("База найдена в AppData: " + dbName);
            }
            else
            {
                // 2. Не нашли - читаем из конфига
                Console.WriteLine("База в AppData не найдена, читаю конфиг...");

                // ищем сначала в текущей папке, потом рядом с exe
                string cfgPath = File.Exists(ConfigFile)
                    ? ConfigFile
                    : Path.Combine(AppDomain.CurrentDomain.BaseDirectory, ConfigFile);
                if (!File.Exists(cfgPath))
                {
                    Console.WriteLine("Файл конфигурации не найден: " + ConfigFile);
                    return;
                }

                Dictionary<string, string> cfg = LoadConfig(cfgPath);
                if (!cfg.TryGetValue("database_name", out dbName) || string.IsNullOrWhiteSpace(dbName))
                {
                    Console.WriteLine("В конфиге не задан database_name");
                    return;
                }
                Console.WriteLine("База из конфига: " + dbName);
            }
            // ==================================

            IMongoCollection<BsonDocument> col =
                new MongoClient(ConnStr).GetDatabase(dbName).GetCollection<BsonDocument>(CollName);

            // "--all" = обработать и уже существующие аккаунты
            ObjectId last;
            if (args.Contains("--all"))
                last = ObjectId.Empty;
            else if (File.Exists(StateFile))
                last = ObjectId.Parse(File.ReadAllText(StateFile).Trim());
            else
                last = ObjectId.GenerateNewId(DateTime.UtcNow);   // только новые с этого момента

            Dictionary<ObjectId, DateTime> watch = new Dictionary<ObjectId, DateTime>();   // аккаунты на перепроверке

            Console.WriteLine("Старт. База: " + dbName + ", last = " + last);

            while (true)
            {
                try
                {
                    // 1. Новые аккаунты
                    List<BsonDocument> fresh = col
                        .Find(Builders<BsonDocument>.Filter.Gt("_id", last))
                        .Sort(Builders<BsonDocument>.Sort.Ascending("_id"))
                        .ToList();

                    foreach (BsonDocument doc in fresh)
                    {
                        ObjectId id = doc["_id"].AsObjectId;
                        col.UpdateOne(Builders<BsonDocument>.Filter.Eq("_id", id), BuildUpdate());
                        watch[id] = DateTime.UtcNow;
                        last = id;
                        File.WriteAllText(StateFile, last.ToString());
                        Console.WriteLine(string.Format("{0:T} выдано: {1} ({2})",
                            DateTime.Now, doc.GetValue("nickName", "?"), id));
                    }

                    // 2. Перепроверка: Shard мог перезаписать профиль своей копией
                    foreach (KeyValuePair<ObjectId, DateTime> kv in watch.ToList())
                    {
                        ObjectId wid = kv.Key;
                        if ((DateTime.UtcNow - kv.Value).TotalSeconds > RecheckSeconds)
                        {
                            watch.Remove(wid);
                            continue;
                        }

                        BsonDocument d = col.Find(Builders<BsonDocument>.Filter.Eq("_id", wid)).FirstOrDefault();
                        if (d != null && NeedsGrant(d))
                        {
                            col.UpdateOne(Builders<BsonDocument>.Filter.Eq("_id", wid), BuildUpdate());
                            Console.WriteLine(string.Format("{0:T} перевыдано (Shard перезаписал): {1}",
                                DateTime.Now, wid));
                        }
                    }
                }
                catch (Exception e)
                {
                    Console.WriteLine("Ошибка: " + e.Message);
                    Thread.Sleep(2000);
                }

                Thread.Sleep(PollMs);
            }
        }
    }
}
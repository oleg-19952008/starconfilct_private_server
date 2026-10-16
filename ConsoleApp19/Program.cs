using System;                              // Подключаем базовые типы (Console, DateTime, Environment и т.д.)
using System.Collections.Generic;          // Нужен для Dictionary, KeyValuePair, List
using System.IO;                           // Работа с файлами и путями (File, Path, Directory)
using System.Linq;                         // LINQ-методы: OrderByDescending, ToList, Contains и др.
using System.Text.RegularExpressions;      // Регулярные выражения (Regex, Match)
using System.Threading;                    // Thread.Sleep
using MongoDB.Bson;                        // BsonValue, BsonDocument, ObjectId
using MongoDB.Driver;                      // MongoClient, IMongoCollection, Builders

namespace AccountGranter                // Пространство имён приложения
{
    /// <summary>
    /// Описание одного поля, которое необходимо выдать аккаунту.
    /// Хранит имя поля и минимальное значение, до которого нужно поднять.
    /// </summary>
    class Grant                                     // Класс-описание одного правила выдачи
    {
        /// <summary>Имя поля в документе MongoDB.</summary>
        public string Field;                        // Имя поля (например, "tokenCredits")

        /// <summary>Минимальное значение, которое должно быть у поля.</summary>
        public BsonValue Value;                     // Значение для $max (например, BsonInt64)

        /// <summary>
        /// Создаёт описание правила выдачи.
        /// </summary>
        /// <param name="field">Имя поля в документе.</param>
        /// <param name="value">Минимальное значение поля.</param>
        public Grant(string field, BsonValue value) // Конструктор правила
        {
            Field = field;                          // Запоминаем имя поля
            Value = value;                          // Запоминаем значение
        }
    }

    /// <summary>
    /// Главный класс программы: следит за коллекцией accounts
    /// и выдаёт новым аккаунтам заданные ресурсы.
    /// </summary>
    class Program                                     // Основной класс приложения
    {
        // ===== Настройки =====
        /// <summary>Строка подключения к локальной MongoDB.</summary>
        const string ConnStr = "mongodb://127.0.0.1:27017";   // Адрес локального MongoDB-сервера

        /// <summary>Имя коллекции с аккаунтами.</summary>
        const string CollName = "accounts";                    // Коллекция, которую отслеживаем

        /// <summary>Имя файла конфигурации (используется, если база не найдена автоматически).</summary>
        const string ConfigFile = "config.txt";                // Имя конфиг-файла

        /// <summary>Файл, в котором хранится _id последнего обработанного аккаунта.</summary>
        const string StateFile = "last_id.txt";                // Файл состояния (last ObjectId)

        /// <summary>Маска файла-признака базы данных игры в папке data.</summary>
        const string DbFilePattern = "cosmosim_*.ns";          // Шаблон имени NS-файла MongoDB

        /// <summary>Пауза между итерациями опроса коллекции, мс.</summary>
        const int PollMs = 1000;                               // 1000 мс = 1 секунда

        /// <summary>Сколько секунд перепроверять аккаунт после выдачи.</summary>
        const int RecheckSeconds = 90;                         // Окно перепроверки аккаунта
        // =====================

        /// <summary>
        /// Что выдаём (поле -> минимальное значение). $max поднимает до значения и не уменьшает.
        /// </summary>
        static readonly Grant[] Grants = new Grant[]           // Массив правил выдачи
        {
            new Grant("tokenCredits",   new BsonInt64(999999999)),  // Токены (64-бит)
            new Grant("vesselExpPool",  new BsonInt32(999999999)),  // Опыт корабля
            new Grant("accountExpPool", new BsonInt32(10000)),      // Опыт аккаунта
            new Grant("accountRank",    new BsonInt32(15))          // Ранг аккаунта
        };

        /// <summary>
        /// Загружает конфигурацию из текстового файла.
        /// Ожидаемый формат строк: ключ = "значение";
        /// </summary>
        /// <param name="path">Путь к файлу конфигурации.</param>
        /// <returns>Словарь параметров (без учёта регистра ключей).</returns>
        static Dictionary<string, string> LoadConfig(string path)                // Парсит config.txt
        {
            Dictionary<string, string> result =
                new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase); // Словарь без учёта регистра
            string text = File.ReadAllText(path);                                 // Читаем весь файл целиком
            foreach (Match m in Regex.Matches(text, @"(\w+)\s*=\s*""([^""]*)""\s*;")) // Ищем пары ключ="значение";
            {
                result[m.Groups[1].Value] = m.Groups[2].Value;                   // Сохраняем в словарь
            }
            return result;                                                        // Возвращаем результат
        }

        /// <summary>
        /// Ищет базу в папке данных MongoDB игры: по файлу cosmosim_XXX.ns определяет имя базы.
        /// stats_cosmosim_XXX.ns под маску "cosmosim_*.ns" не попадает.
        /// </summary>
        /// <returns>Имя найденной базы или null, если найти не удалось.</returns>
        static string FindDbInAppData()                                          // Автопоиск имени БД
        {
            try                                                                  // Ловим любые ошибки ФС
            {
                string dir = Path.Combine(                                       // Склеиваем путь к папке
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), // %LOCALAPPDATA%
                    @"Targem\StarConflict\cloud\mongodb\data");                  // Подпапка игры
                if (!Directory.Exists(dir))                                      // Если папки нет —
                    return null;                                                 // возвращаем null

                string[] files = Directory.GetFiles(dir, DbFilePattern);         // Ищем cosmosim_*.ns
                if (files.Length == 0)                                           // Если ничего не нашли —
                    return null;                                                 // возвращаем null

                // если баз несколько - берём ту, что менялась последней
                string best = files.OrderByDescending(f => File.GetLastWriteTime(f)).First(); // Самая "свежая"
                return Path.GetFileNameWithoutExtension(best);                   // Имя без .ns — это имя БД
            }
            catch (Exception e)                                                  // Если что-то пошло не так
            {
                Console.WriteLine("Не удалось просканировать AppData: " + e.Message); // Пишем в консоль
                return null;                                                     // Возвращаем null
            }
        }

        /// <summary>
        /// Собирает UpdateDefinition для всех полей из Grants.
        /// Для каждого поля применяется оператор $max, чтобы значение не уменьшалось.
        /// </summary>
        /// <returns>Готовое определение обновления документа.</returns>
        static UpdateDefinition<BsonDocument> BuildUpdate()                      // Сборка $max-обновления
        {
            UpdateDefinitionBuilder<BsonDocument> b = Builders<BsonDocument>.Update; // Билдер обновлений
            UpdateDefinition<BsonDocument> u = null;                              // Итоговое обновление
            foreach (Grant g in Grants)                                           // Проходим по всем правилам
            {
                if (u == null) u = b.Max(g.Field, g.Value);                       // Первый элемент — создаём
                else u = u.Max(g.Field, g.Value);                                 // Последующие — добавляем
            }
            return u;                                                             // Возвращаем собранное
        }

        /// <summary>
        /// Проверяет, нужно ли выдать аккаунту ресурсы (хотя бы одно поле меньше требуемого
        /// или отсутствует/не является числом).
        /// </summary>
        /// <param name="d">Документ аккаунта.</param>
        /// <returns>true, если требуется выдача.</returns>
        static bool NeedsGrant(BsonDocument d)                                   // Проверка "нужно ли выдать"
        {
            foreach (Grant g in Grants)                                          // Проходим по правилам
            {
                BsonValue cur;                                                   // Текущее значение поля
                if (!d.TryGetValue(g.Field, out cur) || !cur.IsNumeric || cur.ToDouble() < g.Value.ToDouble()) // Если поля нет/не число/меньше
                    return true;                                                 // Значит, выдача нужна
            }
            return false;                                                        // Все поля уже достаточны
        }

        /// <summary>
        /// Точка входа. Определяет имя базы, подключается к MongoDB
        /// и в бесконечном цикле обрабатывает новые и недавно изменённые аккаунты.
        /// </summary>
        /// <param name="args">Аргументы командной строки. "--all" — обработать и уже существующие аккаунты.</param>
        static void Main(string[] args)                                          // Главный метод
        {
            // ===== Определение имени базы =====
            // 1. Автопоиск в AppData
            string dbName = FindDbInAppData();                                   // Пробуем найти БД автоматически
            if (!string.IsNullOrWhiteSpace(dbName))                              // Если нашли —
            {
                Console.WriteLine("База найдена в AppData: " + dbName);          // Сообщаем в консоль
            }
            else                                                                 // Иначе —
            {
                // 2. Не нашли - читаем из конфига
                Console.WriteLine("База в AppData не найдена, читаю конфиг..."); // Пишем, что идём в конфиг

                // ищем сначала в текущей папке, потом рядом с exe
                string cfgPath = File.Exists(ConfigFile)                         // Если config.txt в CWD —
                    ? ConfigFile                                                 // берём его
                    : Path.Combine(AppDomain.CurrentDomain.BaseDirectory, ConfigFile); // иначе рядом с exe
                if (!File.Exists(cfgPath))                                       // Если и там нет —
                {
                    Console.WriteLine("Файл конфигурации не найден: " + ConfigFile); // Сообщаем
                    return;                                                      // и выходим
                }

                Dictionary<string, string> cfg = LoadConfig(cfgPath);            // Читаем конфиг
                if (!cfg.TryGetValue("database_name", out dbName) || string.IsNullOrWhiteSpace(dbName)) // Берём database_name
                {
                    Console.WriteLine("В конфиге не задан database_name");       // Если пусто —
                    return;                                                      // выходим
                }
                Console.WriteLine("База из конфига: " + dbName);                 // Сообщаем имя БД
            }
            // ==================================

            IMongoCollection<BsonDocument> col =                                  // Получаем коллекцию accounts
                new MongoClient(ConnStr).GetDatabase(dbName).GetCollection<BsonDocument>(CollName);

            // "--all" = обработать и уже существующие аккаунты
            ObjectId last;                                                       // Граница "последнего обработанного"
            if (args.Contains("--all"))                                          // Если указан ключ --all,
                last = ObjectId.Empty;                                           // начинаем с самого начала
            else if (File.Exists(StateFile))                                     // Если есть файл состояния,
                last = ObjectId.Parse(File.ReadAllText(StateFile).Trim());       // читаем из него
            else                                                                 // Иначе —
                last = ObjectId.GenerateNewId(DateTime.UtcNow);                  // только новые с этого момента

            Dictionary<ObjectId, DateTime> watch = new Dictionary<ObjectId, DateTime>(); // Аккаунты на перепроверке

            Console.WriteLine("Старт. База: " + dbName + ", last = " + last);    // Пишем стартовую информацию

            while (true)                                                         // Бесконечный цикл опроса
            {
                try                                                              // Ловим любые ошибки цикла
                {
                    // 1. Новые аккаунты
                    List<BsonDocument> fresh = col                                // Ищем документы
                        .Find(Builders<BsonDocument>.Filter.Gt("_id", last))     // _id > last
                        .Sort(Builders<BsonDocument>.Sort.Ascending("_id"))      // по возрастанию _id
                        .ToList();                                               // материализуем в список

                    foreach (BsonDocument doc in fresh)                          // По каждому новому аккаунту
                    {
                        ObjectId id = doc["_id"].AsObjectId;                     // Достаём _id
                        col.UpdateOne(Builders<BsonDocument>.Filter.Eq("_id", id), BuildUpdate()); // Применяем $max
                        watch[id] = DateTime.UtcNow;                             // Ставим на перепроверку
                        last = id;                                               // Обновляем границу
                        File.WriteAllText(StateFile, last.ToString());           // Сохраняем состояние на диск
                        Console.WriteLine(string.Format("{0:T} выдано: {1} ({2})", // Логируем
                            DateTime.Now, doc.GetValue("nickName", "?"), id));   // ник и _id
                    }

                    // 2. Перепроверка: Shard мог перезаписать профиль своей копией
                    foreach (KeyValuePair<ObjectId, DateTime> kv in watch.ToList()) // Идём по копии словаря
                    {
                        ObjectId wid = kv.Key;                                   // ID аккаунта
                        if ((DateTime.UtcNow - kv.Value).TotalSeconds > RecheckSeconds) // Если окно истекло —
                        {
                            watch.Remove(wid);                                   // убираем из наблюдения
                            continue;                                            // и идём дальше
                        }

                        BsonDocument d = col.Find(Builders<BsonDocument>.Filter.Eq("_id", wid)).FirstOrDefault(); // Читаем документ
                        if (d != null && NeedsGrant(d))                          // Если он существует и требует выдачи —
                        {
                            col.UpdateOne(Builders<BsonDocument>.Filter.Eq("_id", wid), BuildUpdate()); // Обновляем повторно
                            Console.WriteLine(string.Format("{0:T} перевыдано (Shard перезаписал): {1}", // Логируем
                                DateTime.Now, wid));                             // перевыдачу
                        }
                    }
                }
                catch (Exception e)                                              // Если в цикле ошибка —
                {
                    Console.WriteLine("Ошибка: " + e.Message);                   // Логируем
                    Thread.Sleep(2000);                                          // Пауза 2 секунды
                }

                Thread.Sleep(PollMs);                                            // Пауза перед следующим опросом
            }
        }
    }
}

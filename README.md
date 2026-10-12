# Star Conflict — Cloud Server (`/cloud`)

Полное описание структуры игрового сервера («облака» / cloud) игры **Star Conflict** (Targem Games).
Ветка репозитория содержит готовую к запуску сборку серверной части: исполняемые файлы сервисов,
конфигурационные и игровые данные, а также встроенный MongoDB.

Документ объединяет два описания: структуру каталогов/файлов (разделы 1–7) и подробный разбор
конфигурации — `.cfg` файлов и `default_platform_config.lua` (разделы 8–9).

---

## 1. Общая архитектура

Сервер представляет собой набор отдельных процессов (микросервисов), которые запускаются
координатором — **Hub**. Список сервисов и на каких узлах их запускать задаётся в
`data/cloud.xml`. Все сервисы общаются между собой по TCP; клиент подключается через
**LoadBalancer**, который направляет его на свободный **Shard**.

Типовая схема запуска (в порядке приоритета из `cloud.xml`):

```
MongoDB (mongodb/launch.bat)
   └─> Hub.exe ──spawn──> LoadBalancer, Shard, MatchMaker, Authenticator, ChatServer,
                           ConfigServer, Universe, QuestServer, ZoneCoordinator,
                           LobbyServer, AchievementServer, LeaderboardServer,
                           ClanServer, Tournament, ScriptsServer, AdventureServer,
                           GameRewardDispencer (+ DedicatedServer'ы для боёв)
```

Ключевые типы сервисов (перечисление задокументировано прямо в комментариях `data/cloud.xml`):

| Код | Тип сервиса            | Бинарник                 |
|----:|------------------------|--------------------------|
| 1   | LoadBalancer           | `LoadBalancer.exe`       |
| 2   | Shard                  | `Shard.exe`              |
| 3   | MatchMaker             | `MatchMaker.exe`         |
| 4   | DedicatedServer        | `DedicatedServer.exe`    |
| 5   | Hub                    | `Hub.exe`                |
| 7   | GameRewardDispencer    | `GameRewardDispencer.exe`|
| 8   | Authenticator          | `Authenticator.exe`      |
| 9   | ChatServer             | `ChatServer.exe`         |
| 11  | ConfigServer           | `ConfigServer.exe`       |
| 12  | Universe               | `Universe.exe`           |
| 13  | QuestServer            | `QuestServer.exe`        |
| 14  | ZoneCoordinator        | `ZoneCoordinator.exe`    |
| 16  | LobbyServer            | `LobbyServer.exe`        |
| 17  | AchievementServer      | `AchievementServer.exe`  |
| 18  | LeaderboardServer      | `LeaderboardServer.exe`  |
| 19  | ClanServer             | `ClanServer.exe`         |
| 20  | Tournament             | `Tournament.exe`         |
| 21  | EarlyMatchMaker        | `EarlyMatchMaker.exe`    |
| 22  | ScriptsServer          | `ScriptsServer.exe`      |
| 23  | AdventureServer        | `AdventureServer.exe`    |

---

## 2. Корень `/cloud` — исполняемые файлы и скрипты

### 2.1 Сервисы (.exe)

| Файл                      | За что отвечает |
|---------------------------|-----------------|
| `Hub.exe`                 | Координатор («хаб»): запускает и мониторит все дочерние сервисы облака, следит за их состоянием. Слушает порт **3850** (`hub.cfg`). |
| `LoadBalancer.exe`        | Балансировщик нагрузки: точка входа для клиентов, распределяет игроков по шардам. Порт **3801** (`loadbalancer.cfg`). |
| `Shard.exe`               | Основной игровой сервис: хранит сессии игроков, аккаунты, прогресс; отсюда спавнятся выделенные серверы боёв. Порт **3802** (`shard.cfg`). Крупнейший бинарник (~2.7 МБ) — ядро облака. |
| `DedicatedServer.exe`     | Выделенный игровой сервер: собственно бой/инстанс зоны (физика, AI, стрельба). Также используется офлайн для подготовки общих данных (`prepare_shared.bat`). Конфиг — `dediserver.cfg`. |
| `MatchMaker.exe`          | Матчмейкер: подбирает игроков/команды в бои по рейтингу и навыкам (`matchmaker.cfg`). |
| `EarlyMatchMaker.exe`     | «Ранний» матчмейкер: предварительный подбор/очереди на этапе лобби (тип 21). |
| `Authenticator.exe`       | Аутентификация и авторизация игроков, проверка лицензии/платформы (Steam и т.п.), микротранзакции (`authenticator.cfg`). |
| `ChatServer.exe`          | Чат: каналы, фильтры. Порт **3815** (`chat_server.cfg`), словари фильтрации — `data/chat/`. |
| `ConfigServer.exe`        | Раздача клиентам конфигов и обновлений настроек (тип 11). |
| `Universe.exe`            | Глобальная вселенная: состояние космических зон, войны фракций, события (`universe.xml`, тип 12). |
| `QuestServer.exe`         | Квестовый сервер: выдача, отслеживание и завершение квестов (`quests.xml`, `ship_quests.xml`, `clan_quests.xml`, `quest_server.cfg`). |
| `ZoneCoordinator.exe`     | Координатор зон: управляет инстансами зон вселенной, запросами DedicatedServer'ов (`zone_coordinator.cfg`). |
| `LobbyServer.exe`         | Лобби: сбор игроков перед матчем, команды, подготовка боя (`lobby_server.cfg`). |
| `AchievementServer.exe`   | Достижения: прогресс и выдача ачивок (`achievements.xml`, `achievement_server.cfg`). |
| `LeaderboardServer.exe`   | Таблицы лидеров/рейтинги (тип 18). |
| `ClanServer.exe`          | Кланы: состав, эмблемы, клановый корабль, клановые квесты (`clan_emblems.xml`, `clan_ship.xml`, `clan_quests.xml`). |
| `Tournament.exe`          | Турниры/лиги: расписание раундов, награды (`tournaments.xml`, `league_equipment_lists.xml`). |
| `ScriptsServer.exe`       | Сервер игровых скриптов/Lua-логики платформы (тип 22, в `cloud.xml` запущен с priority=0 — последним). |
| `AdventureServer.exe`     | Приключенческий режим/PvE-адвенчуры (тип 23). |
| `GameRewardDispencer.exe` | Раздача внутриигровых наград (руны, сундуки, бандлы) — `game_reward_dispencer.cfg`, `loot_tables.xml`, `battle_pass.xml`. |
| `StatServer.exe`          | Сбор статистики и метрик со всех сервисов; потоки метрик описаны в `stat_server_cfg.xml`, параметры усреднения — `statserver.cfg`. |
| `CrashReporter.exe`       | Приём и обработка краш-репортов сервисов (конфиг — `crash-reporter.cfg`). |

### 2.2 Библиотеки (.dll)

| Файл                     | За что отвечает |
|--------------------------|-----------------|
| `libcurl.dll`            | HTTP/HTTPS-клиент: сетевые запросы платформенных API (Steam, платежи, метрики). |
| `libssl-1_1_tg.dll`      | TLS/SSL (сборка OpenSSL с суффиксом `_tg` — Targem) для шифрованных соединений. |
| `libcrypto-1_1_tg.dll`   | Криптографическая часть OpenSSL (хеши, подписи), используется libssl. |

### 2.3 Скрипты и списки путей

| Файл                        | За что отвечает |
|-----------------------------|-----------------|
| `prepare_shared.bat`        | Офлайн-подготовка «общих данных»: прогоняет `DedicatedServer.exe -prepareSharedData` по путям из `datasources_defs_build.txt`, компилирует/кэширует XML-данные (логи → `prepare_shared.log`). |
| `datasources.txt`           | Порядок поиска папок с данными при обычном запуске: `.\data`, `..\data`, `..\sys_data`, `..\local_data` (первые побеждают, локальные переопределения кладутся в `local_data`). |
| `datasources_cloud.txt`     | То же, но вариант для cloud-сервисов (тот же список путей). |
| `datasources_defs_build.txt`| Пути только для этапа сборки shared-данных (`prepare_shared.bat`): `.\data`, `..\data`, `..\sys_data`. |
| `crash-reporter.cfg`        | Конфиг CrashReporter; сейчас пустой (комментарий: «пустой конфиг, чтобы сбросить crash reporter к дефолтам»). |

---

## 3. `/cloud/data` — конфигурация и игровые данные

### 3.1 Конфигурация облака (XML)

| Файл                   | За что отвечает |
|------------------------|-----------------|
| `cloud.xml`            | **Главный файл оркестрации**: описание топологии облака — узлы (`Node address="127.0.0.1:3850"`, id, регион), какие сервисы (`Service type="N"`) на них запускать, приоритет запуска, общие CVars. Содержит документацию по всем типам сервисов. |
| `stat_server_cfg.xml`  | Конфиг StatServer: провайдеры метрик по сервисам и их адреса — lb:4000, shard:4001, mm:4002, main_hub:4003, auth:4004, chat:4005, quest:4006, achiev:4007, zone:4008; плюс именованные потоки статистики avg/max по подсистемам (SessionManager, Persistence, CloudTaskManager и т.д.). |
| `geo.gbin`             | Бинарная база GeoIP: определение страны игрока по IP (нужна для регионализации, `regions.xml`). |

### 3.2 Конфиги сервисов (.cfg) — обзор

Все cfg-файлы имеют одинаковый паттерн: базовые настройки + строка
`exec <имя>_local.cfg` — подключение **локального переопределяющего конфига**, которого нет в
репозитории (создаётся администратором на конкретном сервере; там хранятся секреты, реальные
адреса БД Redis/Mongo и т.п.). Подробное содержимое каждого файла — в разделе 8.

| Файл                          | Сервис / содержимое |
|-------------------------------|---------------------|
| `common.cfg`                  | Общие CVars для всех процессов (fps, redis-хост закомментирован, Steam sandbox); в конце `exec common_local.cfg`. |
| `shard.cfg`                   | Shard: порт 3802, микро-транзакции Steam в песочнице, лимит перегрузки. |
| `hub.cfg`                     | Hub: порт 3850, таймаут координатора, `hub_detachChildProcesses`. |
| `loadbalancer.cfg`            | LoadBalancer: порт 3801. |
| `authenticator.cfg`           | Authenticator: только `exec authenticator_local.cfg` (всё специфичное — в локальном конфиге). |
| `chat_server.cfg`             | ChatServer: порт 3815. |
| `dediserver.cfg`              | DedicatedServer: тонкая настройка симуляции — fps=32 (кратно updateRate 15), GC Lua, AI (радиусы патрулей/конвоев), время сбора лута, SSH-порт 2222 и пр. Единственный cfg без exec local-файла. |
| `matchmaker.cfg`              | MatchMaker. |
| `lobby_server.cfg`            | LobbyServer. |
| `quest_server.cfg`            | QuestServer. |
| `zone_coordinator.cfg`        | ZoneCoordinator. |
| `achievement_server.cfg`      | AchievementServer. |
| `leaderboard*`                | (конфиг не выделен — используется общий/local). |
| `clan*`                       | (конфиг не выделен — используется общий/local). |
| `tournament*`                 | (конфиг не выделен — используется общий/local). |
| `game_reward_dispencer.cfg`   | GameRewardDispencer. |
| `statserver.cfg`              | StatServer: период усреднения метрик 60 с. |

### 3.3 Игровые данные (XML)

| Файл                                | За что отвечает |
|-------------------------------------|-----------------|
| `zones.xml`                         | Космические зоны карты вселенной: id, уровень, требования по рангу аккаунта/корабля, макс. игроков, раса, tier, награды, интервалы конфликтов, координаты для отладки. |
| `universe.xml`                      | Параметры глобальной вселенной: длительность конфликта, стоимость/длительность гражданских зон, коэффициенты перемещения, стадии новогоднего события. |
| `war.xml`                           | Настройки войн фракций (стоимость возрождения клана, базовая награда). |
| `quests.xml`                        | Группы квестов и их состав. |
| `ship_quests.xml`                   | Ежедневные корабельные квесты: параметры по рангам, тексты. |
| `clan_quests.xml`                   | Клановые квесты (сейчас пусто). |
| `achievements.xml`                  | Достижения: условия сравнения, награды. |
| `medals.xml`                        | Медали боя (мультикиллы, серии, выживание и т.д.). |
| `titles.xml`                        | Титулы/звания аккаунта (Developer, Tester, …) и длительность. |
| `stickers.xml`                      | Чат-стикеры и их цены по длительности. |
| `account_auras.xml`                 | Ауры аккаунта (бустеры, скидки, множители кредитов) — ~400 шт. |
| `karma.xml`                         | Пороги уровней кармы. |
| `faction_rep.xml`                   | Стартовая репутация фракций. |
| `aux_limits.xml`                    | Лимиты, привязанные к рангу репутации. |
| `store_rules.xml`                   | Правила магазина/замен предметов (def → newDefName, цены в валюте). |
| `defmod_rules.xml` / `defmod_rules_new.xml` | Правила модификации дефиниций (замена модулей/кораблей, silent-замены). `_new` — сгенерирован экспорт-скриптом Targem из `export_subtypes.ods`. |
| `vessel_presets.xml`                | Пресеты кораблей: готовые сборки (модули по слотам) для магазинов/ботов/стартовых наборов. |
| `vessel_custom_elements.xml`        | Кастомные элементы кораблей (внешний вид/обвесы) — крупнейший XML (~1.4 МБ). |
| `vessel_custom_elements_rules.xml`  | Правила применения кастомных элементов. |
| `starter_pack.xml`                  | Стартовый набор нового игрока (корабль `Ship_Race1_M_T1`). |
| `loot_tables.xml`                   | Таблицы лута (PVE-наборы, шансы дропа store-предметов). |
| `offers.xml`                        | Предложения/бандлы в магазине: приоритеты, кулдауны, условия показа. |
| `battle_pass.xml`                   | Награды боевого пропуска по стадиям (бандлы, цена). |
| `slot_machines.xml`                 | «Слот-машины» (гача/рулетки): комбинации и награды, валюта запуска. |
| `skills.xml`                        | Дерево талантов по рангам корабля. |
| `clan_emblems.xml`                  | Эмблемы кланов и цены (золото/иридий). |
| `clan_ship.xml`                     | Части кланового корабля: цены и длительность аренды. |
| `league_equipment_lists.xml`        | Разрешённые дефы кораблей/модулей для лиг/турниров. |
| `bot_preset_exclusion_lists.xml`    | Списки исключений пресетов ботов (какие корабли не использовать). |
| `tournaments.xml`                   | Турниры: включение, число раундов, тайминги регистрации/подготовки/раунда, множители наград за победы. |
| `autogen.xml`                       | Данные автогенерации контента. |
| `autogen_special_values.xml`        | Версия autogen и число элементов (118). |
| `atlas_special_values.xml`          | Версия атласа и число элементов (1205). |
| `special_values.xml`                | Особые экономические значения (курс обмена золота — 400 и т.п.). |
| `regions.xml`                       | Регионы распределения серверов: списки кодов стран (RU и др.) — используется вместе с `geo.gbin`. |
| `sstring.flog`                      | Словарь «flying strings» — interned-строк (поля Mongo `$…`, имена коллекций/атрибутов аккаунтов). Оптимизация сериализации строк. |
| `default_platform_config.lua`       | **Главный Lua-конфиг платформы**: экономика, события (даты начала/конца, требуют кратности часу), цены извлечения опыта, параметры x3fw и десятки других геймплейных правил. Правится вручную. Подробный разбор — в разделе 9. |
| `default_platform_config — копия.lua` | Резервная копия предыдущей версии того же конфига (не используется сервером; следить, чтобы не загружалась вместо актуального). |

### 3.4 `/cloud/data/chat` — фильтр чата

| Файл               | За что отвечает |
|--------------------|-----------------|
| `stop-list.txt`    | Корни обсценных слов (нижний регистр) — то, что подлежит фильтрации в ChatServer. |
| `white-list.txt`   | Корни-исключения: слова, содержащие эти корни, **не** фильтруются (ложные срабатывания). |

---

## 4. `/cloud/mongodb` — база данных

Встроенная MongoDB **2.6.12** (Windows-сборка) — хранилище аккаунтов, персонажей, кланов и т.д.

| Файл / группа              | За что отвечает |
|----------------------------|-----------------|
| `mongod.exe`               | Сервер БД (демон). Запускается скриптом ниже. |
| `launch.bat`               | Старт `mongod`: создаёт каталог данных в `%LOCALAPPDATA%\Targem\StarConflict\cloud\mongodb\data` и запускает сервер с `config.cfg`. |
| `config.cfg`               | Конфиг демона: `dbpath=./data`, `bind_ip=127.0.0.1` (только локально), опции noscripting/rest закомментированы. |
| `admin.bat`                | Быстрое открытие mongo-шелла: `mongo.exe 127.0.0.1/cosmosim` (база `cosmosim`). |
| `mongo.exe`                | Интерактивный шелл для администрирования. |
| `mongos.exe`               | Маршрутизатор для шардированного кластера (на случай шардинга БД). |
| `mongodump.exe` / `mongorestore.exe` | Логический бэкап/восстановление БД. |
| `mongoexport.exe` / `mongoimport.exe` | Экспорт/импорт JSON/CSV данных. |
| `mongofiles.exe`           | Работа с GridFS. |
| `mongooplog.exe`           | Повторная запись oplog (репликация/аварийное восстановление). |
| `mongostat.exe` / `mongotop.exe` | Утилиты мониторинга производительности. |
| `mongoperf.exe`            | Тест производительности дисковой подсистемы. |
| `bsondump.exe`             | Конвертация BSON-файлов в JSON. |
| `mongo-r2.6.12.zip`        | Архив оригинальной дистрибуции MongoDB 2.6.12. |
| `GNU-AGPL-3.0`, `README`, `THIRD-PARTY-NOTICES` | Лицензии и документация дистрибутива. |

---

## 5. Порядок запуска (quick start)

```bat
:: 1. База данных
cd cloud\mongodb && launch.bat

:: 2. Подготовка общих данных (после изменения XML в data/)
cd .. && prepare_shared.bat

:: 3. Облако: достаточно запустить Hub — он поднимет всё из data/cloud.xml
Hub.exe
```

Клиент подключается к порту **3801** (LoadBalancer) на адресе узла из `cloud.xml`.

## 6. Как добавлять свои настройки

1. Не правьте базовые `.cfg` в `data/` — создавайте `<имя>_local.cfg` рядом: базовые конфиги сами делают `exec *_local.cfg`, а `datasources*.txt` поддерживают наложение каталогов (`local_data` поверх `data`).
2. После правки XML-данных (зоны, квесты, стора) выполните `prepare_shared.bat`.
3. Состав и адреса сервисов меняются только в `data/cloud.xml`.
4. Секреты (Redis, ключи Steam/платформы) держите в `authenticator_local.cfg`, `shard_local.cfg`, `common_local.cfg` — их нет в репозитории.

## 7. Полезные порты (по умолчанию)

| Порт | Кто |
|-----:|-----|
| 3801 | LoadBalancer (вход для клиентов) |
| 3802 | Shard |
| 3815 | ChatServer |
| 3850 | Hub |
| 27017| MongoDB (bind 127.0.0.1) |
| 4000–4008 | Метрики StatServer по сервисам: lb:4000, shard:4001, mm:4002, main_hub:4003, auth:4004, chat:4005, quest:4006, achiev:4007, zone:4008 (см. `stat_server_cfg.xml`) |
| 2222 | SSH DedicatedServer (`ssh_port`) |

---

## 8. Подробный разбор `.cfg` файлов

Синтаксис консольного языка конфигурации движка: `//` — комментарий, `set <cvar> <значение>` — установка
переменной, `exec <файл>` — подключение другого cfg. Почти каждый сервисный cfg заканчивается
`exec *_local.cfg`, но ни одного `*_local.cfg` в репозитории нет (проверено поиском) — это ожидаемые
пользовательские overrides, которых в поставке нет.

### `cloud/crash-reporter.cfg`
Пустая конфигурация CrashReporter.exe — сбрасывает crash reporter к дефолтам. Больше ничего не содержит.

### `cloud/mongodb/config.cfg`
Конфиг запуска встроенного mongod:
- `dbpath = ./data` — база лежит в `cloud/mongodb/data`;
- `bind_ip = 127.0.0.1` — только локально;
- закомментированы `noscripting` и `rest`.

### `cloud/data/common.cfg`
Общий конфиг, подтягивается всеми сервисами:
- закомментированная строка `db_redisHost` (следов Redis в остальной конфигурации нет, активно не используется);
- `cl_maxFps 60` — ограничение FPS;
- `bind alt+f4 "quit" 255` — горячая клавиша выхода;
- закомментирован `cl_versionType "live"`;
- `exec common_local.cfg`.

### `cloud/data/hub.cfg` — Hub.exe (координатор облака)
- `hub_listenTo "3850"` — порт, на который смотрит `cloud.xml` (`Node address="127.0.0.1:3850"`);
- закомментирован `coordinator_timeout 3000`;
- `hub_detachChildProcesses 1` — запускать дочерние сервисы отдельными процессами.

### `cloud/data/loadbalancer.cfg` — LoadBalancer.exe
- `lb_listenTo "3801"` — входной порт для клиентов.

### `cloud/data/shard.cfg` — Shard.exe (игровые сессии/логин в мир)
- `shard_listenTo "3802"`;
- `steam_useMicroTxnSandbox 1` — песочница Steam-микротранзакций;
- `sm_overloadCounterLimit 20` — лимит счётчика перегрузки (что именно считается — по файлу неясно).

### `cloud/data/chat_server.cfg` — ChatServer.exe
- `chat_server_port "3815"`.

### `cloud/data/statserver.cfg` — StatServer.exe
- `ss_averagingPeriod "60.0"` — период усреднения статистики. Сам StatServer описан через соседний
  `stat_server_cfg.xml`: провайдеры метрик (avg/max потоков NetEndpoint, db, Hub, Quest, Achievement,
  Zone и т.д.) на localhost:4000–4008 по числу сервисов.

### `cloud/data/dediserver.cfg` — DedicatedServer.exe (боевые серверы)
Самый насыщенный cfg, с русскими комментариями автора:
- `cl_maxFps 32` — серверный FPS (кратен `sv_updateRate=15`, слегка выше, чтобы получалось чуть меньше `cl_maxFps` клиента);
- `script_gcWorkBudget 0` — Lua GC почти не нужен;
- `s_masterVolume 0` — звук выключен, `script_initRemoteDebugger 0`;
- `ship_controlForceMode -1` — не форсировать режим управления;
- `tm_enable 0` — «not need any async working»;
- `ssh_port 2222` — SSH-порт сервиса;
- AI: `ai_logSquads 5` (полное логирование отрядов), `ai_convoyDefendRadius 300`, `ai_kiteDistance 5000` (дистанция патрулей);
- `sv_lootCrateScanTime 3` — время сбора лута.

### Остальные сервисные cfg — тонкие обёртки
`achievement_server.cfg`, `authenticator.cfg`, `lobby_server.cfg`, `matchmaker.cfg`, `quest_server.cfg`,
`zone_coordinator.cfg`, `game_reward_dispencer.cfg` содержат только комментарий и `exec <имя>_local.cfg`.
У `zone_coordinator.cfg` комментарий ошибочно гласит «config for achievement server» — по всей
видимости копипаст (в файле это единственный намёк, точную причину утверждать нельзя).

---

## 9. `default_platform_config.lua` (~2200 строк) — главный конфиг облака

**Механика.** Файл определяет набор функций `Configure<Сервис>()`, а в конце диспетчер по глобальной
`service_type` (её выставляет сам сервис перед исполнением конфига) вызывает нужную. Внутри всё
делается через запись в таблицу `cvars` (те же cvar'ы, что и в `.cfg`, но типизированные и с
документацией на русском) и через вызовы API движка (`MatchMaker_ReconfigureQueues`,
`Shard_SetupBattlePassActivation`, `DedicatedServcerServices_SetLootRules` — с опечаткой в имени, так в
исходнике, `Leaderboards_Configure` и т.п.).

### 9.1 Верхний блок (строки 1–62) — общие локальные переменные
- `x3fw = 3` — множитель опыта «первая победа дня» (x3 FIRST WIN), переиспользуется в DediServer, ZoneInstance и LoadBalancer;
- `store_vesselExpExtractionCost = 0.006666666` — стоимость извлечения опыта корабля;
- даты событий: `event_custom`, `creditsEventStart/End` (2026‑10‑09 → 2027‑01‑09), `battlePassStart` + `battlePassEndTable` (этапы 1–3). Комментарий требует менять время кратно часу, иначе квест imaginary ведёт себя непредсказуемо;
- `leagueForbiddenDefs` — чёрный список кораблей/модулей для лиг (NY-оружие T3–T5, уникальные модули, Glass-модули и пр.);
- `botPresetForbiddenDefs` — запрещённые дефы для адаптивных пресетов ботов;
- `numAdaptivePresets = 32`.

### 9.2 `ConfigureShard()` — экономика, магазин, матчмейк-параметры аккаунта
- **Аккаунты/доступ:** `auth_allowInternalAutoCreate=1` (автосоздание внутреннего аккаунта), `auth_infinitePremiumForRoles="gm;support"`, `sm_sandboxAccess=4`, антибот-порог для почты;
- **Стартовые ресурсы нового аккаунта:** `gold_on_start` / `credits_on_start` = 999999999, `premium_on_start` = 999 — явно тестовые значения этого приватного сервера;
- **Магазин:** множители цен `store_vesselPriceMod` / `modulePriceMod` / `munitionPriceMod` = 0.1 (все цены ×0.1); престиж (формула в комментарии: обычные корабли ×0.01 + прем ×0.01); `store_maxTransactionSum=20000`; лимиты unique-модулей (30 / 2 на премиуме); офферы включаются списком `sv_offerEnable="6,7,17,18,19"` — id берутся из `offers.xml`;
- **MMV/матчмейкинг-рейтинг игрока:** параметры формул по eff-rating, KPM, win/lose (Base/Step/Cap), таблицы `mm_mmvMdBattles/Penalty/min/UniqFingerprintClamp` — списки по 18 рангов;
- **Wings/отряды:** `squad_maxNonWingSize=4`, `squad_maxWingSize=12`, min/max wing для sector/raid очередей, `mm_raidSquadFilter` (0–4, кто может в raid);
- Battle Pass активация (`Shard_SetupBattlePassActivation`), запрет оборудования в лигах, расписание потасовок `brawlSchedule` (цикл 28 дней от первого понедельника 2018; сейчас все дни — `three_teams_dm`) через `BrawlManager_SetupSchedule`;
- дневной лимит token credits (1000), шанс бонусного набора при покупке (0.2 × prestige/maxPrestige).

### 9.3 `InstantiateQueueTemplate()` + `ConfigureMatchmaker()` — очереди матчмейкера
Хелпер клонирует шаблон очереди и подставляет диапазоны `mmRank/mmSquadRank/mmValue` в MongoDB-style запрос (`$gte/$lte/$lt`). Дальше два набора очередей:
- `queuesConfigLo` («низкий онлайн») и `queuesConfig` (обычный): training (practice), pve, arcade (10 MMV-слоёв), coop_vs_ai (10 слоёв), brawl-очереди (football, gtdm, atdm, sentinel, capture_the_base, hunger_games, one_against_all, zombie, close_distance, autogen_dm, three_teams_dm, april_control — каждая со своей картой и gameMode-номером, справочник режимов 0–31 приведён у `mm_defaultGameplay`);
- sector battle (qid=501, wing vs wing с ботами BotsBZS по тирам) и league arena (qid=502, без ботов), pve raid;
- `MatchMaker_ReconfigureQueues(queuesConfig)` и второй вызов с флагом `true` для Lo-набора; гистерезис режима низкого онлайна: вход при онлайне < 250, выход при ≥ 300;
- `MatchMaker_SetRewardRates(reward_mult)` — недельное расписание бонусов (понедельник=0: gold 50 ночью, 100 в субботу днём);
- `MatchMaker_SetPveSchedule(pveSchedule)` — ротация PvE-карт (12 максимум, ротация каждые 2 часа) + постоянная карта;
- отладка очередей: `mm_decisionLog` (битовая маска категорий) и `mm_decisionDbg`.

### 9.4 `ConfigureAdventureServer()`
Определена дважды; вторая версия пустая — фактически применяется пустая. Единственная содержательная строка: `adventure_saveGiverOffers = 0`.

### 9.5 `ConfigureScriptsServer()`
- `sv_enableCommunticationWithSS = 1` (обмен зон с сервером скриптов);
- большой закомментированный блок `ScriptsServer:ConfigureGlobalEvents(...)` — ручная форсация глобальных «зелёных» эвентов (pre-event=7, владение=2, вторжение=1, пред-экспансия=6, контратака=8 и т.д.) по номерам локаций; вся расшифровка кодов — из комментариев автора;
- `SetTimerScale(1)` — ускорение таймеров эвентов (закомментирован вариант 3600).

### 9.6 `ConfigureDediServer()` — боевой сервер: награды, лут, боты
- базовые: FPS 18 (в `dediserver.cfg` задано 32 — итоговое значение зависит от порядка применения), AFK-кик 120 сек, `sv_dbgJoinInProgress`, уровни combat-лога 0–4 (расшифрованы в комментарии);
- **лут после боя:** включён, `sv_lootFailChance=0`, scan 1 сек, длительность 120; salvage-конверсии (обычная 0.2, premium 0.6, цена premium 0.0008 от tokenPrice);
- **iterative loot rules по рангам 1–15:** `DedicatedServcerServices_SetLootRules({...})` — для каждого ранга таблицы CommonRanks_* / RareT* / RareTMono / epic и массивы `iter` (номера выдач, когда падает rare/epic; 100000 = практически никогда; реально работают NeodiumDrop с ранга 8 и LezortiumDrop с 11);
- **плавающие шансы rare/epic:** `sv_rarePicksNumberWithFloatingChances=100`, `sv_epic...=150`, базовые шансы и формула веса `weight = max(0, CfA*(attempts-(it+CfOffset))+CfB)` — приведена в комментарии;
- **first win x3:** четыре `sv_dailyWin*ExpRewardCf = x3fw`;
- события-переключатели (`event_cosmonauticsDay`, `event_halloween`, ... = 0), кастомное событие = `event_custom`;
- **адаптивные пресеты ботов (SC-115316):** сохранять топ-2 игроков с эффективностью ≥1500, 32 пресета в БД, запрашивать 20 уникальных, диапазон рангов 3; `sm_bflRoleInc/Dec` (bfl = battle time for life time, из комментария);
- **leave-штрафы:** `sv_leaveFineRewardCoef=0.8`, leaveCounter decay/add, leaverReputation, `sv_leaverBanTime=0` (бан за выход выключен);
- kick если ботов больше чем игроков; синергия free-space коэффициенты; `gold_on_start`-related здесь отсутствует — это в Shard.

### 9.7 `ConfigureDediServerFlags(queueFlags)`
Переопределение для конкретных очередей: newbie → `sv_respawnTimePenalty=0`; наличие rank → `sv_mmBattleRank`.

### 9.8 `ConfigureZoneInstance()` — открытый космос (OW/free space)
- respawn event-объектов 60–420 сек, `sv_eventObjectEndTime`;
- корпоративный иридий: picked loot → clan resource курс 0.1, отправка раз в 6 часов;
- сид-чипы/autogen modules выключены (`sv_autogenModulesEnabled=0`, SC-112454);
- масштабирование урона по разнице рангов: `sv_ranksDiff="-5,-2,0,2,5,10"` + коэффициенты `sv_ranksDiffCoeff` (комментарии объясняют: сколько Rplayer−Rmob и цифры «в диапазонах»);
- AI-логи (telemetry: `ai_logSquads=5` и т.д.), агрессор-таймеры (3000 урона по NPC → статус агрессора, 30 сек), цена воскрешения 100000 кредитов, жизнь инстанса без игроков 720 сек;
- опыт в free space: mastery-таблица по 18 рангам, `sv_freeSpaceExpRewards=2` (всем), кап/запрет опыта за урон;
- `sv_randomLootDef = "LootCrate_Craft_paradise_Weapon20"` — деф crate для случайного лута (требования к дефу описаны в комментарии);
- большая таблица `DedicatedServerServices_SetIterativeLoot({...})` — привязка конкретных OW-локаций (дефов зон вида `*_ow`) к лут-крейтам по диапазонам рангов;
- фракционная враждебность: friendly damage coef 0.25, порог враждебности 6 урона, 45 сек плохих отношений, накопление/декей счётчика (SC-113076 пиратский эвент).

### 9.9 `ConfigureGRD()` — GameRewardDispencer (раздача наград)
- бонус-gold победителям/проигравшим = 0;
- период и значения события «gold за первую и пятую победу» (`reward_eventGoldTimePeriod/Value`, формат «;»-списков пояснён комментарием);
- `cron_enabled=1`; те же даты кредит-события и дневной лимит token credits;
- `reward_leaveCounterMax=12` (SC-113769).

### 9.10 `ConfigureLoadBalancer()`
- `lb_disallowAccess=0`; `lb_limitPlayersOnShardTo=800`;
- усреднение времени очереди (min clamp 10, окно 10);
- `lb_minNextPlayerDelay=0.05`, `lb_maxTaskQLenOnShard=500`;
- `LoadBalancer_SetGreetingMessageCVars({...})` — набор cvar, рассылаемых клиентам как «приветственные» настройки (множители first win, реклама купленных кораблей, параметры клан-корабля, флаги событий).

### 9.11 `ConfigureChatServer()` — антиспам
Две одинаковые по структуре группы: обычный чат и trade-чат. Модель: *awareness* — накопительный счётчик спама:
- растёт по частоте (прирост = A/dt, dt ≥ 0.5) и по похожести сообщений (прирост = K * similarity^P; similarity определена в комментарии);
- спад 10/сек;
- пороги notify/autoban (450/500 и 150/200), бан 60 сек.

Всё это расшифровано прямо в комментариях файла.

### 9.12 `ConfigureUniverse()` — глобальная карта/войны фракций
- `universe_unid=2`; old NY-params (2018, похоже артефакт); kills-множители империи/федерации/Иерихона = 0;
- доли владельца зоны в награде (0.4) и decay влияния (owner 0.25 / rival 0.1 / idle 0.5, SC-111290);
- формула штрафа владельца: вклад = влияние/(A*место+B) (коэффициенты 2 и 3, комментарий «1/3, 1/5, 1/7»);
- параметры глобальной войны `war_coeffAssist/RivalA/RivalB/Neutral/Bot`, пересчёт raw-очков в military exp (×10) и урон корпорации (×100), decay стоимости войны;
- `universe_allowExternalControl=1` (SC-112644);
- расовые бонусы влияния (+10% за совпадение расы с системой/зоной).

### 9.13 `ConfigureQuestServer()`
- квесты включены; даты событий: newYear (сейчас = дата кастомного события), summer/summerShip/halloween = 1;
- `quests_dbgLog=31` (маска: 1 кэш, 2 доступность, 4 состояние, 8 выбор, 16 прогресс);
- формула убывающей награды imaginary-квестов (в комментарии): `floor((A-1)*(1-tanh(B*(прохождения-1)))+1)`, A=25, B=0.17 (SC-109926);
- активация Battle Pass (`QuestServer_SetupBattlePassActivation`).

### 9.14 `ConfigureAchievementServer()`
`achievements_enable=1`, wave max uids 100, dbg лог 0.

### 9.15 `ConfigureLobbyServer()` — пользовательские игры
`lobby_enabled=1`, reward rate 1, min/max игроков PvE-lobby 3/4, лимиты unique-модулей (3/2, #85547/#0098493), запрет оборудования в лигах.

### 9.16 `ConfigureLeaderboardServer()` — самая декларативная часть
Локальные константы-энумы (типы сущностей `LET_*`, действия при истечении `LEA_*`, типы наград `LRT_*`, способы обновления `LUT_*`), затем два регистра:
- **`lbrds`** — сами лидерборды:
  - перманентные (prestige, pvp/pve effectiveness с decay 0.1/сутки, battles, wins, kills, karma good/bad (dir=1 — сортировка обратная), goals, hunger games, pressure, рейдовые времена `time_pve_raid*` через `SET_IF_LESSER`, unlim PvE волны);
  - недельные с наградами (kills/eff max/pve wins — tokenCredits 400/200/100 за top-3; eff_rating — призы tid 31–33);
  - клан-участники (`cm_*`);
  - клановые (`CLS_PVP/PVE_RATING` с decay 1%/час, war damage/rating, zone captures);
  - зелёная война (`event_green_war_*`);
  - временные (april win, close distance, марафон до timestamp 1652659200000);
- **`routes`** — сопоставление коротких имён событий, которые шлют игровые серверы (`pvp_eff`, `gwin`, `kills_ht`, `warDamage`, `zoneCapture`, ...), с целевыми лидербордами и режимом обновления;
- много закомментированных исторических блоков (ELO корпораций, гонок рас, лиг) — оставлены как есть;
- итоговые вызовы: `Leaderboards_Configure(lbrds)`, `Leaderboards_Routes(routes)`.

### 9.17 `ConfigureZoneCoordinator()`
Единственный рабочий cvar `zc_enableZoneBlocks=0` — блокировка OW-зон по raid-расписанию выключена (механика описана в комментарии).

### 9.18 `ConfigureTournament()`
Список карт турнира, `battleRank=17`, `gamemode=12` (TDM по справочнику выше), `teamSize=8`, интервал создания игр 2000 мс, `tournament_idOffset` (сдвиг отображаемых имён команд в UI — объяснён в комментарии).

### 9.19 `ConfigureClanServer()` — клановый корабль
- этапы стройки дредноута: `clan_shipPartsCanBuild=4` (этапы 0–4), `clan_shipUpgradeCanBuild=3` (T3/T4/T5);
- нужно 3 человека 9 ранга;
- минимум ирисок для лога корпы (10);
- награда за победу в войне — аура `Bundle_ClanWar_Win`.

### 9.20 `ConfigureHub()`
Не cvar'ы, а глобальная таблица `RegionWeightProportion` — матрица вероятностей распределения игроков по регионам ru/eu/us (0.7 своя + 0.2/0.1 чужие).

---

### 9.21 Справочник игровых режимов (`mm_defaultGameplay`, `special.gameMode`)

Приведён в комментарии к `cvars.mm_defaultGameplay` в `ConfigureMatchmaker()`; там же оговорено «не все работают»:

| № | Режим | № | Режим | № | Режим |
|---|---|---|---|---|---|
| 0 | none | 11 | bomb the base | 22 | battle royale |
| 1 | space battle | 12 | TDM | 23 | capture the base 2 |
| 2 | capture the flag | 13 | GTDM | 24 | hunger games |
| 3 | capture the base | 14 | clanship | 25 | one against all |
| 4 | control | 15 | capture the frag | 26 | ATDM |
| 5 | practice | 16 | last man standing | 27 | zombie |
| 6 | tutorial | 17 | transport escort | 28 | close distance |
| 7 | PvE mission | 18 | open space | 29 | autogen DM |
| 8 | free space | 19 | mission script | 30 | three teams DM |
| 9 | sentinel | 20 | PvP mission | 31 | april control |
| 10 | king of the hill | 21 | football | | |

Коды эвентов ScriptsServer (из комментариев к `ScriptsServer:ConfigureGlobalEvents`): 7 — зелёный pre-event, 2 — владение, 1 — вторжение, 6 — GREEN_PRE_EXPANSION (таймер подготовки к вторжению), 8 — управление контратакой, 9 — подготовка к вторжению, 12 — вторжение; `newEventState = 1000` и `-100501` (TIMEOUT_EVENT) — управляемые состояния эвента. Назначение остальных значений расшифровки в файле не имеет.

### 9.22 Полный справочник cvar по функциям

Ниже — все включённые (не закомментированные) присваивания `cvars.*` из файла, сгруппированные по функциям-конфигураторам. Формулировки «назначения» взяты **дословно из комментариев самого файла** — там, где комментария нет, оставлено прочерк. Значения приведены как в конфиге (часть из них ссылается на локальные переменные верхнего блока: `x3fw`, `event_custom`, `creditsEventStart/End`, `numAdaptivePresets`). Дублирующиеся в нескольких функциях cvar перечислены в каждой из них (это разные точки применения одного параметра).

##### `ConfigureShard()` — 58 cvar

| Cvar | Значение | Назначение (комментарий из файла) |
|---|---|---|
| `auth_allowInternalAutoCreate` | `1` | Разрешает автоматическое создание внутреннего аккаунта при первом входе. (тип: логический) |
| `sm_sandboxAccess` | `4` | Уровень доступа к sandbox-функциям. (тип: целое число) |
| `shard_minAntibotCounterForMailSending` | `50` | Минимальное значение антибот-счётчика для отправки почты. (тип: целое число; диапазон: 0..100) |
| `auth_infinitePremiumForRoles` | `"gm;support"` | Список admRole через ;, для которых действует бесконечный premium. (тип: строка) |
| `squad_maxNonPremiumSize` | `12` | Размер отряда, которому не требуется premium для постановки в очередь. (тип: целое число) |
| `store_allowAllItemsForBying` | `0` | Разрешает покупать предметы магазина, даже если у них стоит флаг cant_be_bought. (тип: логический) |
| `shipQuests_dbgLog` | `0` | Включает логирование корабельных квестов. (тип: логический) |
| `gold_on_start` | `999999999` | Стартовое количество gold для нового аккаунта. (тип: целое число) |
| `premium_on_start` | `999` | Стартовое premium-время/значение для нового аккаунта. (тип: целое число) |
| `credits_on_start` | `999999999` | Стартовое количество credits для нового аккаунта. (тип: целое число) |
| `store_prestigePerVssl` | `0.01` | Коэффициент вклада одного обычного корабля в prestige аккаунта. Итоговый prestige считается как: обычные корабли * store_prestigePerVssl + premium-корабли * store_prestigePerPremVssl. (тип: дробное число) |
| `store_prestigePerPremVssl` | `0.01` | Коэффициент вклада одного premium-корабля в prestige аккаунта. Чем выше значение, тем сильнее premium-корабли повышают prestige. (тип: дробное число) |
| `store_vesselExpExtractionCost` | `store_vesselExpExtractionCost` | Стоимость извлечения опыта корабля. (тип: дробное число) |
| `store_vesselExpExtractionCostVisualBonus` | `0 или 1` | Визуальный бонус/индикатор стоимости извлечения опыта корабля. (тип: дробное число) |
| `store_vesselPriceMod` | `0.1` | Множитель цен кораблей в магазине. Умножает все типы цены корабля: credits, premium, tokens и event-цену. (тип: дробное число; диапазон: 0.001f..100.0f) |
| `store_modulePriceMod` | `0.1` | Множитель цен модулей в магазине. Умножает credits, premium, tokens и event-цену для предметов типа module. (тип: дробное число; диапазон: 0.001f..100.0f) |
| `store_munitionPriceMod` | `0.1` | Множитель цен боеприпасов в магазине. Умножает credits, premium, tokens и event-цену для предметов типа munition. (тип: дробное число; диапазон: 0.001f..100.0f) |
| `mm_squad1AsSquad` | `0` | Считать одиночного игрока отрядом из одного человека при подборе боя. |
| `mm_totalMMVMdCap` | `2` | Общий лимит суммарной поправки MMV от эффективности, KPM, побед и других факторов. |
| `mm_effRatingMMVMdBase` | `0` | Параметр формулы MMV по рейтингу эффективности: Base - порог, Step - шаг, Cap - максимум. |
| `mm_effRatingMMVMdStep` | `25` | Параметр формулы MMV по рейтингу эффективности: Base - порог, Step - шаг, Cap - максимум. |
| `mm_effRatingMMVMdCap` | `50` | Параметр формулы MMV по рейтингу эффективности: Base - порог, Step - шаг, Cap - максимум. |
| `mm_kpmMMVBase` | `0` | Параметр формулы MMV по KPM: Base - порог, Step - шаг, Cap - максимум. |
| `mm_kpmMMVStep` | `0.0325` | Параметр формулы MMV по KPM: Base - порог, Step - шаг, Cap - максимум. |
| `mm_kpmMMVCap` | `50` | Параметр формулы MMV по KPM: Base - порог, Step - шаг, Cap - максимум. |
| `mm_winLoseMMVMinBattles` | `2000` | Параметр формулы MMV по соотношению побед и поражений; MinBattles включает поправку только после нужного числа боёв.; Clamp (winLose - mm_winLoseMMVBase)/mm_winLoseMMVStep ; 0 ; mm_winLoseMMVCap ) |
| `mm_winLoseMMVBase` | `0.75` | Параметр формулы MMV по соотношению побед и поражений. |
| `mm_winLoseMMVStep` | `0.012` | Параметр формулы MMV по соотношению побед и поражений. |
| `mm_winLoseMMVCap` | `50` | Параметр формулы MMV по соотношению побед и поражений. |
| `mm_mmvMdBattles` | `"200,200,200,200,200,200,200,100,0,0,0,0,0,0,0,0,0,0"` | Таблица MMV-значений по рангам/группам матчмейкинга. |
| `mm_mmvMdPenalty` | `"30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30"` | Таблица MMV-значений по рангам/группам матчмейкинга. |
| `mm_mmvMin` | `"30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30"` | Нижняя граница итогового MMV по рангам корабля, которая начинает действовать после порога боёв из mm_mmvMdBattles.; Не даёт штрафам и другим отрицательным поправкам опустить MMV ниже указанного значения.; Задаётся списком чисел: первое число для 1-го ранга, второе для 2-го и т. д.; количество значений должно совпадать с mm_mmvMdBattles. |
| `mm_mmvMdUniqFingerprintClamp` | `"30,30,30,30,30,30,30,80,80,80,80,80,80,80,80,80,80,80"` | Верхняя граница итогового MMV для игроков с уникальным fingerprint ПК, пока у них меньше боёв, чем порог из mm_mmvMdBattles.; Ограничивает, насколько высоко матчмейкинг может оценить нового игрока по его статистике.; Задаётся списком чисел по рангам; если список заполнен, его длина должна совпадать с mm_mmvMdBattles. |
| `sm_initialKeepAliveTime` | `120` | Время ожидания keep-alive от клиента после подключения; если ответа нет, клиента отключают. |
| `ctm_taskRecoveryInterval` | `5` | Интервал, с которым shard-сервер проверяет в хранилище отложенные административные задачи и берёт их в работу.; Чем меньше значение, тем быстрее задачи начнут выполняться, но тем чаще будут опросы хранилища.; Указывается в секундах; допустимый диапазон: 0.01..5. |
| `squad_maxNonWingSize` | `4` | WINGS; Максимальный размер обычного отряда, который ещё не считается wing-группой.; Если при приглашении игроков этот лимит будет превышен, нужно создавать wing-группу. |
| `squad_maxWingSize` | `12` | Максимальный размер wing-группы при приглашении игроков в отряд.; После достижения этого лимита новых участников добавить в wing нельзя. |
| `mm_sectorMinWingSize` | `5` | Минимальный размер wing-группы для входа в sector-очерь матчмейкера.; Отряды меньше этого размера не будут приняты в режимы, где требуется sector-wing. |
| `mm_sectorMaxWingSize` | `8` | Максимальный размер wing-группы для sector-очерей матчмейкера.; Отряды больше этого размера не будут приняты в режимы, где требуется sector-wing. |
| `mm_raidMinWingSize` | `10` | Минимальный размер wing-группы для входа в raid-очерь матчмейкера.; Отряды меньше этого размера не смогут встать в raid-очерь. |
| `mm_raidSquadFilter` | `0` | 0 - все типы составов: solo, обычные отряды и wing.; 1 - только solo; любые отряды и wing в raid-очерь не пускаются.; 2 - solo и обычные отряды; wing-группы не пускаются.; 3 - обычные отряды и wing; solo-игроки не пускаются.; 4 - только wing; solo и обычные отряды не пускаются.; Для режимов с wing дополнительно действует минимальный размер из mm_raidMinWingSize. |
| `mm_enablePveRaids` | `1` | Включает PvE-рейды в матчмейкере. |
| `mm_notArcadeSquadRankDiff` | `17` | Допустимая разница рангов в отряде для не-arcade режимов. |
| `raid_lootAuraInterval` | `1` | Интервал в днях, через который игроку снова выдаются loot-ауры для raid-миссий.; Проверка и выдача происходят при первом входе игрока в эти сутки.; Значение 1 означает ежедневную выдачу; 3 — раз в три дня. |
| `store_creditsEventStart` | `creditsEventStart` | Время начала события с кредитами. (тип: строка) |
| `store_creditsEventEnd` | `creditsEventEnd` | Время окончания события с кредитами. (тип: строка) |
| `store_maxTransactionSum` | `20000` | Trade; Максимальная сумма одной транзакции/письма. (тип: целое число) |
| `mm_decisionLog` | `0` | Включает детальный лог решения при попытке игрока или отряда встать в очередь матчмейкера.; 0 - лог выключен, любое число больше 0 - лог включён. |
| `store_maxUniqueModules` | `30` | Лимит одинаковых unique-модулей на один корабль; отдельно задаётся для обычных и premium-кораблей.; Balanse rule |
| `store_maxUniqueModulesOnPremium` | `2` | Лимит одинаковых unique-модулей на один корабль; отдельно задаётся для обычных и premium-кораблей.; #0098493: Сделать возможнсть установки экспериментальных модулей на прем. и ДЛЦ корабли в кол-ве 1 шт |
| `sv_offerEnable` | `"6,7,17,18,19"` | Список offerId офферов, которые нужно включить на shard-сервере.; Идентификаторы берутся из файла offers.xml в этой же папке: ищите атрибут offerId у нужного оффера.; Формат: числа через запятую, пробел или табуляцию; пустая строка отключает все офферы. |
| `store_bonusBundleChancePercentageMax` | `0.2` | Максимальный шанс получить бонусный набор при покупке набора; шанс умножается на коэффициент (prestige / maxPrestige). (тип: дробное число; диапазон: 0.0f..1.0f) |
| `premiumTimeForAccountRank` | `1 * 24 * 60 * 60` | Premium-время, выдаваемое за ранг аккаунта. (тип: целое число); премиум (в секундах, по умолчанию - день) |
| `sv_tokenCreditsDailyLimit` | `1000` | Дневной лимит token credits, которые игрок может заработать за день.; #106983 |
| `store_battlePassUnlockLvlBtnStart` | `"2026-10-09T00:00:00Z"` | Время, с которого появляется кнопка разблокировки уровня battle pass. (тип: строка) |
| `sm_bflRoleInc` | `0.5` | Адаптивные пресеты ботов.; Коэффициент увеличения BFL-роли. (тип: дробное число); bfl - battle time for life time; цвар на увеличение статистики пресетов SC-115316 |
| `sm_bflRoleDec` | `0.05` | Коэффициент уменьшения BFL-роли. (тип: дробное число); цвар на уменьшение статистики пресетов |
| `sm_numAdaptivePresetsToSaveDB` | `numAdaptivePresets` | Количество адаптивных пресетов, сохраняемых в БД. 0 - очищает данные. (тип: целое число; диапазон: 0..1000) |

##### `ConfigureMatchmaker()` — 9 cvar

| Cvar | Значение | Назначение (комментарий из файла) |
|---|---|---|
| `mm_lowOnlineLo` | `250` | Переход в режим низкого онлайна, если онлайн меньше этого значения. (тип: целое число) |
| `mm_lowOnlineHi` | `300` | Выход из режима низкого онлайна, если онлайн не меньше этого значения. (тип: целое число) |
| `mm_botsCount` | `6` | Количество ботов. (тип: целое число; диапазон: 0..31); Базовое количество ботов; в конкретной очереди может быть переопределено. |
| `mm_defaultGameplay` | `3` | 26 - ATDM; 27 - zombie; 28 - close distance; 29 - autogen DM; 30 - three teams DM; 31 - april control |
| `mm_timeInQueueAveragingCf` | `200` | Чем больше значение, тем плавнее и медленнее меняется среднее время в очереди. (тип: целое число; диапазон: 2..10000); 10 for dev/test, >100 for live |
| `rate_exp` | `"1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"` | Множители выдаваемого опыта по рангам, список через запятую. (тип: строка); reward multiplication rates |
| `rate_cred` | `"1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"` | Множители выдаваемых кредитов по рангам, список через запятую. (тип: строка) |
| `mm_decisionLog` | `0` | Детальность decision-log внутри матчмейкера. Это битовая маска: чтобы включить несколько категорий, сложите их числа.; 0 - выключено; 1 - базовые PvP-решения; 2 - PvP join-in-progress; 4 - PvP-кандидаты.; 8 - coop; 16 - coop join-in-progress; 32 - PvE; 64 - universe; 128 - brawl; 256 - brawl-кандидаты.; 512 - hunger games; 1024 - one against all; 2048 - zombie; 4096 - three teams; 8192 - close distance; 16384 - общие решения.; Пример: 33 включит базовый PvP-лог и PvE-лог (1 + 32). Все категории: 32767. |
| `mm_decisionDbg` | `0` | Способ вывода decision-log матчмейкера.; 0 - накапливать строки лога и выводить их одним блоком в info-лог после окончания разбора записей.; 1 - писать каждое сообщение сразу в debug-лог; удобно для онлайн-отладки, но может давать много записей. |

##### `ConfigureAdventureServer()` — 1 cvar

| Cvar | Значение | Назначение (комментарий из файла) |
|---|---|---|
| `adventure_saveGiverOffers` | `0` | Включает/выключает сохранение предложений adventure-giver в базу данных. (тип: логический); при 1 - сохраняются предложения, при 0 - не сохраняются |

##### `ConfigureScriptsServer()` — 1 cvar

| Cvar | Значение | Назначение (комментарий из файла) |
|---|---|---|
| `sv_enableCommunticationWithSS` | `1` | Должен ли экземпляр зоны обмениваться данными с сервером скриптов. (тип: логический) |

##### `ConfigureDediServer()` — 64 cvar

| Cvar | Значение | Назначение (комментарий из файла) |
|---|---|---|
| `cl_maxFps` | `18` | Ограничивает FPS этим значением; 0 — ограничение выключено. (тип: дробное число) |
| `sv_dbgJoinInProgress` | `0` | Отладка подключения к уже идущему бою. (тип: логический) |
| `cl_combatLog` | `0` | Логирование combat-событий в файл лога; каждый уровень включает все предыдущие.; 0 - отключено; 1 - убийства/смерти/награды; 2 - +использование модулей, ракет и аур.; 3 - +весь урон; 4 - +коэффициенты параметров геймплейных аур. |
| `db_logMessages` | `0` | Логирование протокола базы данных: 1 — краткое, 2 — полное. (тип: целое число); to catch some nasty stuff |
| `sv_respawnTimePenalty` | `-1` | Переопределяет игровую настройку штрафа времени возрождения за смерть. (тип: дробное число); to use gameplaysettings values |
| `sv_afkCheckDuration` | `120` | Время в секундах, через которое игрок кикается за AFK, если он не присылал управляющие ввод или они не менялись.; Большое значение (напр. 3600) фактически отключает AFK-кик. (тип: дробное число) |
| `sv_lootEnabled` | `1` | Включает/выключает послебоевой loot. (тип: логический) |
| `sv_lootFailChance` | `0` | Шанс ничего не найти. (тип: дробное число; диапазон: 0.0f..1.0f) |
| `sv_lootScanTime` | `1` | Время сканирования в секундах. (тип: дробное число) |
| `sv_lootDuration` | `120` | Длительность стадии сбора loot. (тип: дробное число) |
| `sv_salvageTokenConversion` | `0.2` | Коэффициент обычной salvage-конвертации найденного loot-предмета в токены.; Возврат считается от tokenPrice предмета: tokensRefund = tokenPrice * sv_salvageTokenConversion. (тип: дробное число) |
| `sv_salvagePremiumTokenConversion` | `0.6` | Коэффициент premium salvage-конвертации найденного loot-предмета в токены.; Premium-вариант требует оплату premium-валютой и возвращает токены по формуле: tokensRefund = tokenPrice * sv_salvagePremiumTokenConversion. (тип: дробное число) |
| `sv_salvagePremiumPriceConversion` | `0.0008` | Коэффициент стоимости premium salvage для найденного loot-предмета.; Цена premium-варианта считается от обычной цены предмета: premiumPrice = price * sv_salvagePremiumPriceConversion. (тип: дробное число) |
| `sv_universeWingVsWingRewardCf` | `2.0` | Коэффициент награды для BFS-боя wing vs wing. (тип: дробное число; диапазон: 1.0f..10.0f) |
| `ship_controlForceMode` | `-1` | Принудительный режим управления кораблём. (тип: целое число; диапазон: -1..5); Значения: -1 — не форсировать; 0 — FOLLOWING; 1 — COMBINED; 2 — LOCAL_TURRET; 3 — REMOTE_TURRET; 4 — LANDED; 5 — WOW. |
| `ship_ufoRotateX` | `1` | Особый режим поворота UFO-корабля по оси X.; UFO ship controls |
| `sv_achievementEnabled` | `1` | Включает/выключает игровые достижения. (тип: логический) |
| `sv_achievProgressTimer` | `3` | Минимальный интервал отправки прогресса игрока на сервер достижений, в секундах. (тип: дробное число) |
| `event_cosmonauticsDay` | `0` | Включает событие «День космонавтики». (тип: логический); EVENTS |
| `event_gameAnniversary` | `0` | Включает событие «Годовщина игры». (тип: логический) |
| `event_february23` | `0` | Включает событие «23 февраля». (тип: логический) |
| `event_march8` | `0` | Включает событие «8 марта». (тип: логический) |
| `event_botPrefix` | `0` | Включает событие с префиксом ботов. (тип: логический) |
| `event_claws` | `0` | Включает событие Claws. (тип: логический) |
| `event_knowledgeDay` | `0` | Включает событие «День знаний». (тип: логический) |
| `event_halloween` | `0` | Включает событие Halloween. (тип: целое число) |
| `event_invasionPVP` | `0` | Включает событие вторжения в PvP. (тип: логический) |
| `event_valentinesDay` | `0` | Включает событие «День святого Валентина». (тип: логический) |
| `ship_aiThink` | `1` | Включает AI-логику кораблей. (тип: логический); DEBUG |
| `sv_freeSynergyRewardCf` | `0.05` | Коэффициент награды свободной синергии. (тип: дробное число) |
| `sv_freeSynergyRewardCfPremiumVessel` | `0.2` | Коэффициент награды свободной синергии для premium-корабля. (тип: дробное число) |
| `sv_goldMunitionExpRewardCf` | `1.0` | Дополнительный коэффициент опыта синергии за убийство/помощь с gold munition. (тип: дробное число) |
| `script_gcWorkBudget` | `1` | Бюджет времени для инкрементальной работы Lua GC, в микросекундах. (тип: целое число) |
| `sv_dailyWinPveExpRewardCf` | `x3fw` | Множитель опыта за первую PvE-победу дня. (тип: дробное число); x3 FIRST WIN |
| `sv_dailyWinPvpExpRewardCf` | `x3fw` | Множитель опыта за первую PvP-победу дня. (тип: дробное число) |
| `sv_dailyWinCoopExpRewardCf` | `x3fw` | Множитель опыта за первую coop-победу дня. (тип: дробное число) |
| `sv_dailyWinBrawlExpRewardCf` | `x3fw` | Множитель опыта за первую brawl-победу дня. (тип: дробное число) |
| `sv_pvpLabelChances` | `"0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"` | Шанс выдачи event-label (пометки корабля как агента события для игрока) для PvP-боёв.; Задаётся по рангам как список из 18 дробных чисел от 0 до 1; первое число для 1-го ранга, второе для 2-го и т. д. (тип: строка) |
| `sv_pveLabelChances` | `"0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"` | То же, что и sv_pvpLabelChances, но для PvE-миссий и рейдов. (тип: строка) |
| `sv_rarePicksNumberWithFloatingChances` | `100` | Количество попыток выбора rare-таблицы loot с плавающими шансами. (тип: целое число); rare_limit |
| `sv_epicPicksNumberWithFloatingChances` | `150` | Количество попыток выбора epic-таблицы loot с плавающими шансами. (тип: целое число); epic_limit |
| `sv_overlootedRarePickChance` | `0.004` | Базовый шанс выбрать rare-таблицу loot. (тип: дробное число) |
| `sv_overlootedEpicPickChance` | `0` | Базовый шанс выбрать epic-таблицу loot. (тип: дробное число) |
| `sv_lootCommonPickChance` | `0.2` | Базовый шанс выбрать common-таблицу loot. (тип: дробное число); common_default_weight |
| `sv_lootMaxLevelRestriction` | `0` | Ограничивает rare- и epic-таблицы loot только кораблями максимального уровня. (тип: логический); max rank ships for loot |
| `sv_lootRuleCfA` | `0.25` | Множитель A в формуле веса выбора rare/epic loot-таблицы. (тип: дробное число) |
| `sv_lootRuleCfB` | `0.25` | Базовый вес B (свободный член) в формуле веса rare/epic loot-таблицы. (тип: дробное число) |
| `sv_lootRuleCfOffset` | `-1` | Сдвиг offset: корректирует порог attempts, с которого начинает расти плавающий шанс rare/epic. (тип: дробное число); Формула: weight = max(0, sv_lootRuleCfA * (attempts - (it + sv_lootRuleCfOffset)) + sv_lootRuleCfB).; attempts - число попыток без rare/epic; it - порог из iter в loot-правиле для текущей по счёту выдачи. |
| `sv_autorecordReplaysTo` | `""` | Путь для сохранения replay dedicated-сервера. (тип: строка) |
| `event_custom` | `event_custom` | Время начала кастомного события. (тип: строка); "Необходимо изменять время начала и конца кратно часу, иначе квест imaginary может вести себя |
| `sv_kickExcessiveBotsEnabled` | `1` | Кикать ли игроков из боя, если ботов стало больше, чем игроков. |
| `sv_numBestPlayerToSave` | `2` | Количество лучших игроков, чьи корабли сохраняются для адаптивных пресетов; -1 — все игроки и все корабли. (тип: целое число; диапазон: -1..MAX_PLAYERS); количество сохранения лучших игроков SC-115316 |
| `sv_minEfficiencyVesselToSave` | `1500` | Минимальная эффективность корабля для сохранения в базу адаптивных пресетов. (тип: целое число); минимальное количество очков для сохранения пресета корабля лучшего игрока |
| `sv_numAdaptivePresetsInDB` | `numAdaptivePresets` | Лимит записей адаптивных пресетов в БД для режима, ранга и роли; 0 очищает базу. |
| `sv_numUniqueAdaptivePresets` | `20` | Лимит от 0 до 100 на чтение из базы адаптивных пресетов для ранга и роли игрового режима. (тип: целое число; диапазон: 0..100); сколько уникальных пресетов запрашивает дедик с базы |
| `sv_rangeRankAdaptivePresets` | `3` | Диапазон рангов от 0 до MAX_SHIP_RANK для чтения из базы адаптивных пресетов. (тип: целое число; диапазон: 0..MAX_SHIP_RANK); разница запрашиваемых рангов пресетов с базы от максимального ранга очереди ( если максимальный ранг 12, то при цваре 3, минимальный ранг будет 9 ) |
| `sv_leaveFineRewardCoef` | `0.8` | Множитель награды для случая, когда игрок покидал предыдущие игры. (тип: дробное число; диапазон: 0.0f..1.0f); коэффициент награды. По умолчанию 1(нет штрафа). |
| `sv_leaveCounterMaxDecay` | `4` | Максимальное снижение счётчика выходов из боя. (тип: целое число; диапазон: 0..INT_MAX); максимальное значение, на которое может уменьшиться счетчик ливов, когда игрок получает штраф(счетчик ливов больше единицы. По умолчанию равен 3. Целое. |
| `sv_leaveCounterDecayWithoutFine` | `0.9` | Снижение leaveCounter, если игрок не получил штраф. (тип: дробное число; диапазон: 0.0f..FLT_MAX); значение, на которое уменьшается счетчик, когда игрок не получает штраф(счетчик меньше единицы). По умолчанию 0.1 . |
| `sv_normalLeaveCounterAdd` | `0` | Добавляет это значение к leaveCounter, если игрок вышел из игры штатно. (тип: дробное число); значение, на которое увеличивается счетчик при нормальном выходе из боя(нажал на кнопку "Покинул бой"). По умолчанию 0.5. |
| `sv_abnormalLeaveCounterAdd` | `0` | Добавляет это значение к leaveCounter, если игрок вышел из игры нештатно. (тип: дробное число); значение, на которое увеличивается счетчик при ненормальном выходе(упал клиент, пропала сеть). По умолчанию 0. |
| `sv_leaverReputationAdd` | `1` | Добавляет это значение к leaverReputation, если игрок получил leaver-ban. (тип: дробное число; диапазон: 0.0f..100.0f); [0, 100], по умолчанию 1. Это значение добавляется к leaverReputation, когда игрок получает бан. |
| `sv_leaverBanTime` | `0` | Минимальное время battle-ban при штрафе за выход, в секундах. (тип: дробное число; диапазон: 0.0f..1800.0f); [0, 1800], по умолчанию 300. Время, на которое игрок получает бан на вход в бой, в секундах. |
| `sv_leaverReputationDecay` | `0.9` | Снижение leaverReputation, если игрок не покидает игру. (тип: дробное число; диапазон: 0.0f..FLT_MAX); по умолчанию 0.01. На эту величину уменьшается leaverReputation, когда игрок не ливает. |

##### `ConfigureDediServerFlags()` — 2 cvar

| Cvar | Значение | Назначение (комментарий из файла) |
|---|---|---|
| `sv_respawnTimePenalty` | `0` | Переопределяет игровую настройку штрафа времени возрождения за смерть. (тип: дробное число) |
| `sv_mmBattleRank` | `queueFlags.rank` | Боевой ранг матча; передаётся в параметры боя и влияет на ранговые ограничения. |

##### `ConfigureZoneInstance()` — 47 cvar

| Cvar | Значение | Назначение (комментарий из файла) |
|---|---|---|
| `cl_maxFps` | `18` | restart cloud after changing these cvars; Ограничивает FPS этим значением; 0 — ограничение выключено. (тип: дробное число) |
| `ship_aiThink` | `1` | Включает AI-логику кораблей. (тип: логический) |
| `cl_combatLog` | `0` | Логирование combat-событий в файл лога; каждый уровень включает все предыдущие.; 0 - отключено; 1 - убийства/смерти/награды; 2 - +использование модулей, ракет и аур.; 3 - +весь урон; 4 - +коэффициенты параметров геймплейных аур. |
| `sv_shipWeaponDamageCoef` | `1` | Коэффициент урона оружия. (тип: дробное число; диапазон: 0.0f..FLT_MAX) |
| `sv_eventObjectRespawnTimeMin` | `60` | Минимальное время respawn event-объекта. (тип: дробное число) |
| `sv_eventObjectRespawnTimeMax` | `420` | Максимальное время respawn event-объекта. (тип: дробное число); задают диапазон для выбора случайно задержки первого и последующих созданий объекта. |
| `sv_eventObjectEndTime` | `"2027-01-09T00:00:00Z"` | Время отключения event-объекта. (тип: строка); время, после которого ивентовый объект больше не создается. |
| `event_claws` | `0` | Включает событие Claws. (тип: логический); April 1 |
| `sv_pickedLootRateToClanResource` | `0.1` | Коэффициент конвертации подобранного loot в ресурс клана. (тип: дробное число); 0.1 курс перевода числа подъемов лута в корпоративный иридиум |
| `sv_pickedLootUpdateTime` | `6 * 3600` | Время обновления подобранного loot. (тип: дробное число); интервал отправки иридиума в корпу в секундах. |
| `sv_spaceStationPortalTimer` | `3` | Отключает проверку формата Lua-данных при конвертации и сохранении в базу. 1 - данные записываются без сверки со схемой; только для не-live сборок.; cvars.dbg_disableLuaDataFormatChecking = 1; Таймер портала к станции в открытом космосе. |
| `sv_autogenModulesEnabled` | `0` | SC-112454 сид-чипы |
| `sv_dbgAutogenDefs` | `0` | Где показывать сид-чипы: 1 - только в игре, 2 - в игре и в ангаре.; 1 — в игре, 2 — в игре и в ангаре. (тип: целое число) |
| `sv_enableCommunticationWithSS` | `1` | Должен ли экземпляр зоны обмениваться данными с сервером скриптов. (тип: логический) |
| `sv_ranksDiff` | `"-5, -2, 0, 2, 5, 10"` | Интервалы разницы рангов для масштабирования урона, список через запятую. (тип: строка); сколько Rplayer - Rmob |
| `sv_ranksDiffCoeff` | `"-0.5, 0.2, 0.5, 0.6, 0.7, 0.8, 1"` | Коэффициенты масштабирования урона в OW по разнице рангов, список через запятую. (тип: строка); цифры "в диапозонах" предыдущей таблицы |
| `dbg_logRankDiffScaling` | `0` | Показывать ли параметры масштабирования. (тип: логический) |
| `ai_logSquads` | `5` | Логировать информацию squad: 1 — spawn, 2 — движение, 3 — бой, 5 — всё. (тип: целое число) |
| `ai_convoyDefendRadius` | `300` | Расстояние между игроком и точкой despawn. (тип: дробное число) |
| `sv_lootCrateScanTime` | `1` | Время сканирования loot crate в открытом космосе. |
| `ai_kiteDistance` | `5000` | Максимальная дистанция, на которую AI-отряд может отходить от точки старта при преследовании врага. (тип: дробное число) |
| `sv_dailyWinPveExpRewardCf` | `x3fw` | Множитель опыта за первую PvE-победу дня. (тип: дробное число); x3 FIRST WIN |
| `sv_dailyWinPvpExpRewardCf` | `x3fw` | Множитель опыта за первую PvP-победу дня. (тип: дробное число) |
| `sv_dailyWinCoopExpRewardCf` | `x3fw` | Множитель опыта за первую coop-победу дня. (тип: дробное число) |
| `sv_dailyWinBrawlExpRewardCf` | `x3fw` | Множитель опыта за первую brawl-победу дня. (тип: дробное число) |
| `sv_aggressorMinNPCDamage` | `3000` | Игрок получает статус агрессора после такого объёма урона по неигровой цели. (тип: дробное число) |
| `sv_aggressorTimer` | `30` | Максимальное значение таймера флага агрессора. (тип: дробное число) |
| `sv_resurrectionCreditsPrice` | `100000` | Цена воскрешения игрока в credits. |
| `sv_instanceLifeTime` | `720` | Через это время экземпляр зоны будет закрыт, если в нём нет клиентов, в секундах. (тип: дробное число) |
| `sv_freeSynergyRewardCf` | `0.05` | Коэффициент награды свободной синергии. (тип: дробное число); OW synergy |
| `sv_freeSynergyRewardCfPremiumVessel` | `0.20` | Коэффициент награды свободной синергии для premium-корабля. (тип: дробное число) |
| `sv_freeSpaceExpMastery` | `"1.95,1.95,1.95,1.95,1.95,1.95,1.95,2.35,2.575,3.04,3.4,3.64,3.915,4.045,4.1,4.1,4.1,4.1"` | Замена mastery корабля для free space, список по рангам через запятую. (тип: строка) |
| `sv_expRate` | `"1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"` | Множитель выдаваемого опыта по рангам, список через запятую. (тип: строка) |
| `sv_freeSpaceExpRewards` | `2` | Разрешает выдачу опыта кораблю за боевые действия в открытом космосе (Free Space).; 0 - никому, 1 - только premium-игрокам, 2 - всем игрокам. Дополнительно опыт ограничен рангом зоны и sv_freeSpaceExpCap. (тип: целое число) |
| `sv_expForDamageFreeSpace` | `0` | Выдавать опыт за урон во Free Space. (тип: логический); Fast Synergy Gain |
| `sv_randomLootDef` | `"LootCrate_Craft_paradise_Weapon20"` | Def-имя loot crate, который используется системой случайного лута в Free Space.; Указанный def должен быть сущностью типа LootCrate и иметь признак isRare; иначе случайный лут в зоне отключится с ошибкой в логах. (тип: строка) |
| `sv_afkCheckDuration` | `3600` | Время в секундах, через которое игрок кикается за AFK, если он не присылал управляющие ввод или они не менялись.; Большое значение (напр. 3600) фактически отключает AFK-кик. (тип: дробное число) |
| `event_invasionWithBeacons` | `0` | Включает событие «Invasion with beacons». (тип: логический); #57052 |
| `sv_owLabelChances` | `"0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"` | Шансы выдачи label-меток кораблям по рангам; строка содержит 18 значений. |
| `ship_ufoRotateX` | `1` | Особый режим поворота UFO-корабля по оси X.; UFO ship controls |
| `sv_frendlyFactionDamageCoef` | `0.25` | Коэффициент урона по дружественным фракционным сущностям. (тип: дробное число; диапазон: 0.0f..1.0f); SC-113076 пиратский евент; коэффициент урона дружественным фракциям в ОМ, данный параметр влияет на урон, остальные только на отношение |
| `sv_enemyMinFactionNPCDamage` | `6` | Игрок становится врагом фракции после такого объёма урона по неигровой фракционной цели. (тип: дробное число); значение счётчика урона, после которого фракция становится врагом игроку |
| `sv_factionBadRelationshipTime` | `45` | Время, на которое у игрока портятся отношения с фракцией после урона по её NPC.; время в секундах, в течение которого фракция будет врагом игроку |
| `sv_enemyMaxFactionNPCDamage` | `100` | Максимальная сумма урона для группы отношений с фракцией; не влияет на фактический урон по сущностям. (тип: дробное число); максимальное значение счётчика урона от игрока |
| `sv_enemyMaxFactionNPCDamagePerSec` | `1` | Максимальный урон в секунду для группы отношений с фракцией; не влияет на фактический урон по сущностям. (тип: дробное число); ограничение счётчика урона, накапливаемого за одну секунду |
| `sv_factionNPCDamageDecay` | `0.2` | Скорость снижения накопленного урона по фракционным NPC для расчёта враждебности.; уменьшение счётчика урона за секунду |
| `sv_autorecordReplaysTo` | `""` | Путь для сохранения replay dedicated-сервера. (тип: строка) |

##### `ConfigureGRD()` — 9 cvar

| Cvar | Значение | Назначение (комментарий из файла) |
|---|---|---|
| `reward_bonusGoldForWinner` | `0` | Если задано, добавляет bonus gold победителям боя. (тип: целое число) |
| `reward_bonusGoldForLooser` | `0` | Если задано, добавляет bonus gold проигравшим боя. (тип: целое число) |
| `reward_eventGoldTimePeriod` | `"2025-09-02T12:00:00Z;2025-09-11T06:00:00Z"` | Период события «gold за первую и пятую победу» в формате 2013-04-12T12:00:00Z;2013-04-13T12:00:00Z. (тип: строка); event 'gold for first and fifth win' |
| `reward_eventGoldTimeValue` | `"0;0;0;0;50;0;0;0;0;100;0;0;0;0;150;0;0;0;0;200"` | Размер награды события «gold за первую и пятую победу» в формате 500;0;0;0;5000. (тип: строка) |
| `cron_enabled` | `1` | Включает планировщик. (тип: целое число) |
| `store_creditsEventStart` | `creditsEventStart` | Время начала события с кредитами. (тип: строка) |
| `store_creditsEventEnd` | `creditsEventEnd` | Время окончания события с кредитами. (тип: строка) |
| `sv_tokenCreditsDailyLimit` | `1000` | Дневной лимит token credits, которые игрок может заработать за день. |
| `reward_leaveCounterMax` | `12` | Максимальное значение leaveCounter. (тип: дробное число; диапазон: 0.0f..FLT_MAX); SC-113769 |

##### `ConfigureLoadBalancer()` — 6 cvar

| Cvar | Значение | Назначение (комментарий из файла) |
|---|---|---|
| `lb_disallowAccess` | `0` | Включение запрещает доступ к серверу. (тип: целое число) |
| `lb_limitPlayersOnShardTo` | `800` | Максимальное количество игроков на каждый shard. (тип: целое число) |
| `lb_avgTimeMinClamp` | `10` | Среднее время постановки в очередь не опускается ниже этого значения. (тип: дробное число) |
| `lb_avgTimeAveragingCf` | `10` | При расчёте среднего времени учитывается столько последних игроков в очереди. (тип: целое число) |
| `lb_minNextPlayerDelay` | `0.05` | Параметр балансировщика нагрузки: ограничивает задержки и длину очерей на shard. |
| `lb_maxTaskQLenOnShard` | `500` | Параметр балансировщика нагрузки: ограничивает задержки и длину очерей на shard. |

##### `ConfigureChatServer()` — 16 cvar

| Cvar | Значение | Назначение (комментарий из файла) |
|---|---|---|
| `antispam_autobanSec` | `60` | Длительность бана нарушителя. (тип: целое число) |
| `antispam_autobanAwareness` | `500` | Порог показателя awareness, при превышении которого игрок автоматически банится в чате.; Awareness - накопительный показатель уровня спама: растёт, если игрок пишет часто и повторяется, и постепенно снижается со временем при перерывах. (тип: целое число) |
| `antispam_notifyAwareness` | `450` | Порог awareness для уведомления пользователя о прекращении спама. (тип: целое число) |
| `antispam_notifyExtended` | `0` | Включает отправку расширенного уведомления. (тип: целое число) |
| `antispam_awarenessDecay` | `10` | Уменьшается на это значение в секунду. (тип: дробное число) |
| `antispam_awarenessIntervalNumerator` | `40` | Числитель A в формуле прироста awareness по частоте сообщений: прирост = A / dt.; dt - время в секундах с прошлого сообщения (минимум 0.5 сек); большее A - быстрее растёт awareness при частых сообщениях. (тип: дробное число) |
| `antispam_awarenessSimilarityMul` | `1` | Коэффициент K в формуле прироста awareness по похожести сообщений: прирост = K * similarity ^ P. (тип: дробное число); Прирост начисляется при каждом новом сообщении.; similarity - доля текста текущего сообщения, совпадающая с предыдущими: сумма длин совпадающих подстрок; (длиннее 2 символов) из предыдущих сообщений, делённая на длину текущего сообщения. |
| `antispam_awarenessSimilarityPow` | `1` | Степень P в формуле прироста awareness по похожести сообщений: прирост = K * similarity ^ P. (тип: дробное число) |
| `antispam_trade_autobanSec` | `60` | Длительность бана нарушителя. (тип: целое число); Trade Chat |
| `antispam_trade_autobanAwareness` | `200` | Awareness - накопительный показатель уровня спама: растёт, если игрок пишет часто и повторяется, и постепенно снижается со временем при перерывах.; Тот же порог автобана, но для trade-канала. (тип: целое число) |
| `antispam_trade_notifyAwareness` | `150` | Порог awareness для уведомления пользователя о прекращении спама. (тип: целое число) |
| `antispam_trade_notifyExtended` | `0` | Включает отправку расширенного уведомления. (тип: целое число) |
| `antispam_trade_awarenessDecay` | `10` | Уменьшается на это значение в секунду. (тип: дробное число) |
| `antispam_trade_awarenessIntervalNumerator` | `100` | Числитель A в формуле прироста awareness: прирост = A / dt (dt в секундах, мин 0.5).; Большее A - быстрее растёт awareness при частых сообщениях; тот же параметр, что и antispam_awarenessIntervalNumerator. (тип: дробное число) |
| `antispam_trade_awarenessSimilarityMul` | `1` | Коэффициент K в формуле прироста awareness по похожести сообщений: прирост = K * similarity ^ P.; Тот же параметр, что и antispam_awarenessSimilarityMul, но для trade chat. (тип: дробное число) |
| `antispam_trade_awarenessSimilarityPow` | `1` | Степень P в формуле прироста awareness по похожести сообщений: прирост = K * similarity ^ P.; Тот же параметр, что и antispam_awarenessSimilarityPow, но для trade chat. (тип: дробное число) |

##### `ConfigureUniverse()` — 22 cvar

| Cvar | Значение | Назначение (комментарий из файла) |
|---|---|---|
| `universe_unid` | `2` | Идентификатор используемой Universe. (тип: целое число; диапазон: 1..65535) |
| `universe_newYearStartTime` | `"2018-12-17T00:00:00Z"` | Время начала новогоднего события. (тип: строка); NY2016 params |
| `universe_empireKillsCF` | `0` | Скорость роста счётчика убийств Empire. (тип: дробное число) |
| `universe_federationKillsCF` | `0` | Скорость роста счётчика убийств Federation. (тип: дробное число) |
| `universe_jerichoKillsCF` | `0` | Скорость роста счётчика убийств Jericho. (тип: дробное число) |
| `universe_factorOwnerInReward` | `0.4` | Доля награды зоны, которая достаётся текущему владельцу; оставшаяся доля распределяется между соперниками. (тип: дробное число 0..1) |
| `universe_decayOwner` | `0.25` | Доля накопленного влияния владельца зоны, которая списывается в начале конфликта. (тип: дробное число 0..1) |
| `universe_decayRival` | `0.1` | Доля накопленного влияния соперников, которая списывается в начале конфликта. (тип: дробное число 0..1) |
| `universe_takeOwnerCoeffA` | `2` | Коэффициент A в формуле штрафа владельца по итогам конфликта: вклад соперника = влияние / (A * место + B), место считается с 0. (тип: дробное число); 1/3, 1/5, 1/7... |
| `universe_takeOwnerCoeffB` | `3` | Коэффициент B в формуле штрафа владельца по итогам конфликта: вклад соперника = влияние / (A * место + B), место считается с 0. (тип: дробное число) |
| `universe_decayIdle` | `0.5` | Доля накопленного влияния, которая списывается после конфликта без нового влияния за время конфликта. (тип: дробное число 0..1); SC-111290 |
| `war_coeffAssist` | `0.2` | Параметры глобальной войны: настраивают формулы начисления военного опыта и урона корпорации.; Базовая формула события: raw = множитель_убийства * множитель_цели; затем raw переводится в опыт и урон отдельными коэффициентами.; Множитель для участников, которые помогли убить цель, но не нанесли финальный удар. Финальный убийца получает множитель 1. (тип: дробное число 0..1) |
| `war_coeffRivalA` | `1` | Коэффициент A для цели-врага в формуле множителя цели: множитель = A * ранг_жертвы + B. (тип: дробное число) |
| `war_coeffRivalB` | `2` | Коэффициент B для цели-врага в формуле множителя цели: множитель = A * ранг_жертвы + B. (тип: дробное число) |
| `war_coeffNeutral` | `0.1` | Множитель цели, если жертва не состоит в войне с корпорацией атакующего. (тип: дробное число) |
| `war_coeffBot` | `0.05` | Множитель цели для bot-заменителя вместо реального игрока. (тип: дробное число) |
| `war_damageRawRateToMilitaryExp` | `10` | Коэффициент пересчёта raw-очков события в прогресс военного звания игрока. (тип: дробное число) |
| `war_damageRawRateToDamage` | `100` | Коэффициент пересчёта raw-очков события в урон корпорации на глобальной карте. (тип: дробное число) |
| `war_decayCostBase` | `0.1` | Доля периодического уменьшения базовой стоимости войны; применяется как множитель 1 - значение. (тип: дробное число 0..1) |
| `universe_allowExternalControl` | `1` | Разрешает внешнему сервису управлять логикой зон: при отключённой логике зоны сервер сам не запускает/завершает конфликты и не принимает вклад. (тип: булево значение); SC-112644 |
| `universe_raceFactorStellar` | `0.1` | Доля бонуса к влиянию клана в зоне, если раса клана совпадает с доминирующей расой звёздной системы; множитель = 1 + значение. (тип: дробное число 0..1) |
| `universe_raceFactorZone` | `0.1` | Доля бонуса к влиянию клана в зоне, если раса клана совпадает с расой самой зоны; множитель = 1 + значение. (тип: дробное число 0..1) |

##### `ConfigureQuestServer()` — 12 cvar

| Cvar | Значение | Назначение (комментарий из файла) |
|---|---|---|
| `quests_enable` | `1` | Включает/выключает квесты. (тип: логический) |
| `event_newYear` | `"2026-10-09T00:00:00Z"` | Время начала новогоднего события. (тип: строка) |
| `quests_readWaveMaxUids` | `100` | Максимальное число UID для загрузки в операции чтения БД. (тип: целое число; диапазон: 1..1024) |
| `quests_dbgLog` | `31` | Битовая маска логирования debug-сообщений квестов: сложением значений включаются нужные категории.; 1 - кэширование; 2 - доступность квестов; 4 - состояние пользователя; 8 - выбор квестов; 16 - прогресс квестов. 31 - все категории. (тип: целое число) |
| `event_summer` | `1` | Включает летнее событие. (тип: целое число) |
| `event_summerShip` | `1` | Включает летнее событие с кораблём. (тип: целое число) |
| `event_halloween` | `1` | Включает событие Halloween. (тип: целое число) |
| `event_custom` | `event_custom` | Время начала кастомного события. (тип: строка); Необходимо изменять время начала и конца кратно часу, иначе квест imaginary может вести себя непредсказуемо. |
| `quests_imaginaryRewardCoeffA` | `25` | Коэффициенты формулы убывающего вознаграждения за imaginary-квесты:; количество = floor((A - 1) * (1 - tanh(B * (прохождений - 1))) + 1), где «прохождения» - сколько раз игрок уже выполнил этот квест.; Коэффициент A: начальная величина награды при первом прохождении; с ростом числа прохождений награда убывает до 1. (SC-109926; тип: дробное число) |
| `quests_imaginaryRewardCoeffB` | `0.17` | Коэффициент B: скорость убывания награды с ростом числа прохождений; большее B - быстрее падает награда. (SC-109926; тип: дробное число) |
| `store_creditsEventStart` | `creditsEventStart` | Время начала события с кредитами. (тип: строка) |
| `store_creditsEventEnd` | `creditsEventEnd` | Время окончания события с кредитами. (тип: строка) |

##### `ConfigureAchievementServer()` — 3 cvar

| Cvar | Значение | Назначение (комментарий из файла) |
|---|---|---|
| `achievements_enable` | `1` | Включает серверную обработку достижений. |
| `achievements_readWaveMaxUids` | `100` | Максимальное число UID для загрузки в операции чтения БД. (тип: целое число; диапазон: 1..256) |
| `achievements_dbgLogEnable` | `0` | Уровень/флаг отладочного логирования. (тип: логический); дополнительное логирование |

##### `ConfigureLobbyServer()` — 6 cvar

| Cvar | Значение | Назначение (комментарий из файла) |
|---|---|---|
| `lobby_enabled` | `1` | Включает сервер пользовательских игр. |
| `lobby_rewardRates` | `1` | Награды за пользовательские игры умножаются на это значение. (тип: дробное число) |
| `lobby_reqPlayersPvEMin` | `3` | Минимум/максимум игроков для запуска PvE-lobby. |
| `lobby_reqPlayersPvEMax` | `4` | Минимум/максимум игроков для запуска PvE-lobby. |
| `store_maxUniqueModules` | `3` | Лимит одинаковых unique-модулей на один корабль; отдельно задаётся для обычных и premium-кораблей.; #85547 |
| `store_maxUniqueModulesOnPremium` | `2` | Лимит одинаковых unique-модулей на один корабль; отдельно задаётся для обычных и premium-кораблей.; #0098493: Сделать возможнсть установки экспериментальных модулей на прем. и ДЛЦ корабли в кол-ве 1 шт |

##### `ConfigureZoneCoordinator()` — 1 cvar

| Cvar | Значение | Назначение (комментарий из файла) |
|---|---|---|
| `zc_enableZoneBlocks` | `0` | Включает блокировку зон по расписанию raid: ZoneCoordinator передаёт флаг в запускаемые ZoneInstance и в уже работающие инстансы.; Внутри FreeSpace по текущему расписанию выбирается raid-зона, и переходы/джампы в эту зону запрещаются. (тип: целое число) |

##### `ConfigureTournament()` — 6 cvar

| Cvar | Значение | Назначение (комментарий из файла) |
|---|---|---|
| `tournament_idOffset` | `0` | Смещение номеров имён турнирных команд в UI: клиент прибавляет это значение к номеру имени и берёт строку single_tournament_name_N.; Позволяет сдвинуть набор отображаемых имён команд без изменения их реальных teamId. (тип: целое число) |
| `tournament_levels` | `"s1338_devilsjaw;s1338_pandora_dreadnwreck;s1340_thar_aliendebris13;s1420_ceres3_asteroidcity;s1420_ceres3_northmsite;s8256_thar_barrierdebris;s8256_thar_lavastone;s8256_thar_threshold;desttown"` | Уровни/карты турнира. (тип: строка); ;s1338_pandora_anomaly глючит |
| `tournament_battleRank` | `17` | Боевой ранг турнира; копируется в sv_mmBattleRank. (тип: целое число; диапазон: 0..ai::MAX_SHIP_RANK) |
| `tournament_gamemode` | `12` | Игровой режим турнира. (тип: целое число; диапазон: ai::GT_SPACE_BATTLE..ai::GT_MISSION_SCRIPT - 1) |
| `tournament_teamSize` | `8` | Максимальный размер команды в турнире. (тип: целое число; диапазон: 1..MAX_TOURNAMENT_TEAM_SIZE) |
| `tournament_gameInterval` | `2000` | Интервал между созданием игр в миллисекундах. (тип: целое число; диапазон: 50..10000) |

##### `ConfigureClanServer()` — 5 cvar

| Cvar | Значение | Назначение (комментарий из файла) |
|---|---|---|
| `clan_shipPartsCanBuild` | `4` | Количество основных частей кланового корабля, доступных для строительства. (тип: целое число); (0,1,2,3,4) этапы строительства дредноута |
| `clan_shipUpgradeCanBuild` | `3` | Максимальное количество апгрейдов модулей кланового корабля, доступных для строительства. (тип: целое число); (0,1,2,3) этапы апгрейдов дредноута (Т3,Т4,Т5) |
| `clan_shipBuildHighRanks` | `3` | Количество высокоранговых участников клана, необходимое для строительства кланового корабля. (тип: целое число); кол-во человек в клане 9 ранга |
| `clans_historyMinResourceAddByZone` | `10` | Минимальное количество ресурса из зоны для записи в историю клана. (тип: целое число); Если с зоны пришло меньше иррисок - не спамить в лог корпы. |
| `clan_warWinRewardAura` | `'Bundle_ClanWar_Win'` | Награда за победу в войне. (тип: строка) |



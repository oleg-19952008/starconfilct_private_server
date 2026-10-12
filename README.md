# Star Conflict — Cloud Server (`/cloud`)

Полное описание структуры игрового сервера («облака» / cloud) игры **Star Conflict** (Targem Games).
Ветка репозитория содержит готовую к запуску сборку серверной части: исполняемые файлы сервисов,
конфигурационные и игровые данные, а также встроенный MongoDB.

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
| `DedicatedServer.exe`     | Выделенный игровой сервер: собственно бой/инстанс зоны (физика, AI, стрельца). Также используется офлайн для подготовки общих данных (`prepare_shared.bat`). Конфиг — `dediserver.cfg`. |
| `MatchMaker.exe`          | Матчмейкер: подбирает игроков/команды в бои по рейтингу и навыкам (`matchmaker.cfg`). |
| `EarlyMatchMaker.exe`     | «Ранний» матчмейкер: предварительный подбор/очереди на этапе лобби (тип 21). |
| `Authenticator.exe`       | Аутентификация и авторизация игроков, проверка лицензии/платформы (Steam и т.п.), микротранзакции (`authenticator.cfg`). |
| `ChatServer.exe`          | Чат: каналы, фильтры. Порт **3815** (`chat_server.cfg`), словари фильтрации — `data/chat/`. |
| `ConfigServer.exe`        | Раздача клиентам конфигов и обновлений настроек (тип 11). |
| `Universe.exe`            | Глобальная вселенная: состояние космических зон, войны фракций, события (`universe.xml`, тип 12). |
| `QuestServer.exe`         | Квестовый сервер: выдача, отслеживание и завершение квестов (`quests.xml`, `ship_quests.xml`, `clan_quests.xml`, `quest_server.cfg`). |
| `ZoneCoordinator.exe`     | Координатор зон: управляет инстансами зон вселенной, запросами DedicatedServer'ов (`zone_coordinator.cfg`). |
| `LobbyServer.exe`         | Лобби: сбор players перед матчем, команды, подготовка боя (`lobby_server.cfg`). |
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

### 3.2 Конфиги сервисов (.cfg)

Все cfg-файлы имеют одинаковый паттерн: базовые настройки + строка
`exec <имя>_local.cfg` — подключение **локального переопределяющего конфига**, которого нет в
репозитории (создаётся администратором на конкретном сервере; там хранятся секреты, реальные
адреса БД Redis/Mongo и т.п.).

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
| `account_auras.xml`                 | Аур аккаунта (бустеры, скидки, множители кредитов) — ~400 шт. |
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
| `default_platform_config.lua`       | **Главный Lua-конфиг платформы**: экономика, события (даты начала/конца, требуют кратности часу), цены извлечения опыта, параметры x3fw и десятки других геймплейных правил. Правится вручную. |
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

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

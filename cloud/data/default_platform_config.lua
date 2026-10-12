-- -*- coding: utf-8 -*-

local x3fw = 3	---- x3 FIRST WI

local store_vesselExpExtractionCost = 0.006666666

local event_custom			= "2026-10-09T00:00:00Z"-- Необходимо изменять время начала и конца кратно часу, иначе квест imaginary может вести себя непредсказуемо.
local creditsEventStart		= "2026-10-09T00:00:00Z"
local creditsEventEnd		= "2027-01-09T00:00:00Z"

-- Активация события BattlePass
	-- battlePassStart - строка, время начала события в формате YYYY-MM-DDThh:mm:ssZ (ISO 8601)
	-- battlePassEndTable - таблица, активные стадии в формате: { {stage, stageEndTime}, {stage, stageEndTime}, ...},
	-- 		где stage - число, номер этапа (отсчет с 1), stageEndTime - строка, время окончания этапа в формате YYYY-MM-DDThh:mm:ssZ (ISO 8601);
	--		stageEndTime может быть пустой строкой, в этом случае считается, что времени окончания у этапа нет, и он будет активен, пока его не уберут из списка
	-- Внимание: данные о прогрессе игрока хранятся только на одно событие, при изменении времени начала события они теряются (считается, что это уже другое событие) (это не касается купленного через dlc премиума, который хранится для всех событий)
	local battlePassStart		= "2026-10-09T00:00:00Z"
	local battlePassEndTable	= { {1,"2027-01-09T00:00:00Z"}, {2,"2027-01-09T00:00:00Z"}, {3,"2027-01-09T00:00:00Z"}} -- Следить, чтобы даты/время окончания 1го и 2го этапа одного БП были одинаковыми !!! Добавлен 3й этап (с лета 2023)

-- список запрещенного оборудования (кораблей и модулей) в лигах
 local leagueForbiddenDefs =
{
	"Weapon_Minigun_NY_T3",
	"Weapon_Minigun_NY_T4",
	"Weapon_Minigun_NY_T5",
	"Weapon_SmartRocketLauncher_NY_T3",
	"Weapon_SmartRocketLauncher_NY_T4",
	"Weapon_SmartRocketLauncher_NY_T5",
	"Weapon_SuppressingGun_NY_T3",
	"Weapon_SuppressingGun_NY_T4",
	"Weapon_SuppressingGun_NY_T5",
	"FireStealingPot",
	"BushidoCall",
	"DronDamageMod",
	"EnemyInfoCheck",
	"CloakingDevice_Uniq_T3",
	"FrigateDrone_T3_LessShldHeal",
	"WolfRun",
	"SaveBack",  
	'Module_Glass_PlasmaWeb',
	'Module_Glass_PhaseShield',
	'Module_Glass_EnergyShieldCommander',
	'Module_Glass_FrigateDrone',
	'Module_Glass_CloakingDevice',
	'Module_Glass_MicroWarp',
	'Module_Glass_TimeBoost',
}

-- список запрещённых дефов для адаптивных пресетов ботов
local botPresetForbiddenDefs =
{
	"Weapon_PlasmaWebLaser_T5_Mk1",
	"Weapon_PlasmaWebLaser_T5_Rare",
	"Weapon_PlasmaWebLaser_T5_Mk3",
	"Weapon_PlasmaWebLaser_T5_Epic",
	"Weapon_PlasmaWebLaser_T5_Rel",
  
	"Ship_Race5_M_T5_Apeiron",
}

local numAdaptivePresets = 32

--
function ConfigureShard()

	-- Разрешает автоматическое создание внутреннего аккаунта при первом входе. (тип: логический)
	cvars.auth_allowInternalAutoCreate	= 1
	
	-- Уровень доступа к sandbox-функциям. (тип: целое число)
	cvars.sm_sandboxAccess				= 4

	-- Минимальное значение антибот-счётчика для отправки почты. (тип: целое число; диапазон: 0..100)
	cvars.shard_minAntibotCounterForMailSending = 50

	-- Список admRole через ;, для которых действует бесконечный premium. (тип: строка)
	cvars.auth_infinitePremiumForRoles	= "gm;support"

	-- Размер отряда, которому не требуется premium для постановки в очередь. (тип: целое число)
	cvars.squad_maxNonPremiumSize		= 12

	
	-- Разрешает покупать предметы магазина, даже если у них стоит флаг cant_be_bought. (тип: логический)
	cvars.store_allowAllItemsForBying	= 0

	-- Включает логирование корабельных квестов. (тип: логический)
	cvars.shipQuests_dbgLog				= 0

	-- Стартовое количество gold для нового аккаунта. (тип: целое число)
	cvars.gold_on_start					= 999999999
	-- Стартовое premium-время/значение для нового аккаунта. (тип: целое число)
	cvars.premium_on_start				= 999
	-- Стартовое количество credits для нового аккаунта. (тип: целое число)
	cvars.credits_on_start				= 999999999

	-- Коэффициент вклада одного обычного корабля в prestige аккаунта. Итоговый prestige считается как: обычные корабли * store_prestigePerVssl + premium-корабли * store_prestigePerPremVssl. (тип: дробное число)
	cvars.store_prestigePerVssl 		= 0.01
	-- Коэффициент вклада одного premium-корабля в prestige аккаунта. Чем выше значение, тем сильнее premium-корабли повышают prestige. (тип: дробное число)
	cvars.store_prestigePerPremVssl 	= 0.01

    -- Стоимость извлечения опыта корабля. (тип: дробное число)
    cvars.store_vesselExpExtractionCost = store_vesselExpExtractionCost
    if cvars.store_vesselExpExtractionCost >= 0.006 then
    	-- Визуальный бонус/индикатор стоимости извлечения опыта корабля. (тип: дробное число)
    	cvars.store_vesselExpExtractionCostVisualBonus = 0
   	else
    	-- Визуальный бонус/индикатор стоимости извлечения опыта корабля. (тип: дробное число)
    	cvars.store_vesselExpExtractionCostVisualBonus = 1
    end

	-- Множитель цен кораблей в магазине. Умножает все типы цены корабля: credits, premium, tokens и event-цену. (тип: дробное число; диапазон: 0.001f..100.0f)
	cvars.store_vesselPriceMod		= 0.1
	-- Множитель цен модулей в магазине. Умножает credits, premium, tokens и event-цену для предметов типа module. (тип: дробное число; диапазон: 0.001f..100.0f)
	cvars.store_modulePriceMod		= 0.1
	-- Множитель цен боеприпасов в магазине. Умножает credits, premium, tokens и event-цену для предметов типа munition. (тип: дробное число; диапазон: 0.001f..100.0f)
	cvars.store_munitionPriceMod	= 0.1

	-- Считать одиночного игрока отрядом из одного человека при подборе боя.
	cvars.mm_squad1AsSquad			= 0

	-- Общий лимит суммарной поправки MMV от эффективности, KPM, побед и других факторов.
	cvars.mm_totalMMVMdCap			= 2

	-- Параметр формулы MMV по рейтингу эффективности: Base - порог, Step - шаг, Cap - максимум.
	cvars.mm_effRatingMMVMdBase 	= 0
	-- Параметр формулы MMV по рейтингу эффективности: Base - порог, Step - шаг, Cap - максимум.
	cvars.mm_effRatingMMVMdStep 	= 25
	-- Параметр формулы MMV по рейтингу эффективности: Base - порог, Step - шаг, Cap - максимум.
	cvars.mm_effRatingMMVMdCap 		= 50
  	-- Параметр формулы MMV по KPM: Base - порог, Step - шаг, Cap - максимум.
  	--
  	cvars.mm_kpmMMVBase 		= 0
	-- Параметр формулы MMV по KPM: Base - порог, Step - шаг, Cap - максимум.
	cvars.mm_kpmMMVStep 		= 0.0325
	-- Параметр формулы MMV по KPM: Base - порог, Step - шаг, Cap - максимум.
	cvars.mm_kpmMMVCap 			= 50

	-- Параметр формулы MMV по соотношению побед и поражений; MinBattles включает поправку только после нужного числа боёв.
	-- Clamp (winLose - mm_winLoseMMVBase)/mm_winLoseMMVStep ; 0 ; mm_winLoseMMVCap )
	cvars.mm_winLoseMMVMinBattles	= 2000
	-- Параметр формулы MMV по соотношению побед и поражений.
	cvars.mm_winLoseMMVBase 		= 0.75
	-- Параметр формулы MMV по соотношению побед и поражений.
	cvars.mm_winLoseMMVStep 		= 0.012
	-- Параметр формулы MMV по соотношению побед и поражений.
	cvars.mm_winLoseMMVCap 			= 50

	-- Таблица MMV-значений по рангам/группам матчмейкинга.
	cvars.mm_mmvMdBattles 		= "200,200,200,200,200,200,200,100,0,0,0,0,0,0,0,0,0,0"
	-- Таблица MMV-значений по рангам/группам матчмейкинга.
	cvars.mm_mmvMdPenalty 		= "30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30"
    -- Нижняя граница итогового MMV по рангам корабля, которая начинает действовать после порога боёв из mm_mmvMdBattles.
    -- Не даёт штрафам и другим отрицательным поправкам опустить MMV ниже указанного значения.
    -- Задаётся списком чисел: первое число для 1-го ранга, второе для 2-го и т. д.; количество значений должно совпадать с mm_mmvMdBattles.
    cvars.mm_mmvMin 			= "30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30"
  	-- Верхняя граница итогового MMV для игроков с уникальным fingerprint ПК, пока у них меньше боёв, чем порог из mm_mmvMdBattles.
  	-- Ограничивает, насколько высоко матчмейкинг может оценить нового игрока по его статистике.
  	-- Задаётся списком чисел по рангам; если список заполнен, его длина должна совпадать с mm_mmvMdBattles.
  	cvars.mm_mmvMdUniqFingerprintClamp = "30,30,30,30,30,30,30,80,80,80,80,80,80,80,80,80,80,80"

	-- Время ожидания keep-alive от клиента после подключения; если ответа нет, клиента отключают.
	cvars.sm_initialKeepAliveTime = 120

	-- Интервал, с которым shard-сервер проверяет в хранилище отложенные административные задачи и берёт их в работу.
	-- Чем меньше значение, тем быстрее задачи начнут выполняться, но тем чаще будут опросы хранилища.
	-- Указывается в секундах; допустимый диапазон: 0.01..5.
	cvars.ctm_taskRecoveryInterval	= 5

	-- WINGS
  	-- Максимальный размер обычного отряда, который ещё не считается wing-группой.
  	-- Если при приглашении игроков этот лимит будет превышен, нужно создавать wing-группу.
  	cvars.squad_maxNonWingSize 		= 4
  	-- Максимальный размер wing-группы при приглашении игроков в отряд.
  	-- После достижения этого лимита новых участников добавить в wing нельзя.
  	cvars.squad_maxWingSize    		= 12
  	-- Минимальный размер wing-группы для входа в sector-очерь матчмейкера.
  	-- Отряды меньше этого размера не будут приняты в режимы, где требуется sector-wing.
  	cvars.mm_sectorMinWingSize 		= 5
  	-- Максимальный размер wing-группы для sector-очерей матчмейкера.
  	-- Отряды больше этого размера не будут приняты в режимы, где требуется sector-wing.
  	cvars.mm_sectorMaxWingSize 		= 8
  	-- Минимальный размер wing-группы для входа в raid-очерь матчмейкера.
  	-- Отряды меньше этого размера не смогут встать в raid-очерь.
  	cvars.mm_raidMinWingSize		= 10

	-- Фильтр состава групп для raid-очередей: задаёт, кто может вставать в рейд — одиночные игроки, обычные отряды и/или wing-группы.
	-- 0 - все типы составов: solo, обычные отряды и wing.
	-- 1 - только solo; любые отряды и wing в raid-очерь не пускаются.
	-- 2 - solo и обычные отряды; wing-группы не пускаются.
	-- 3 - обычные отряды и wing; solo-игроки не пускаются.
	-- 4 - только wing; solo и обычные отряды не пускаются.
	-- Для режимов с wing дополнительно действует минимальный размер из mm_raidMinWingSize.
	cvars.mm_raidSquadFilter = 0

	-- Включает PvE-рейды в матчмейкере.
	cvars.mm_enablePveRaids			= 1
  
  	-- Допустимая разница рангов в отряде для не-arcade режимов.
  	cvars.mm_notArcadeSquadRankDiff = 17

	-- Интервал в днях, через который игроку снова выдаются loot-ауры для raid-миссий.
	-- Проверка и выдача происходят при первом входе игрока в эти сутки.
	-- Значение 1 означает ежедневную выдачу; 3 — раз в три дня.
	cvars.raid_lootAuraInterval 	= 1

	-- Время начала события с кредитами. (тип: строка)
	cvars.store_creditsEventStart		= creditsEventStart
	-- Время окончания события с кредитами. (тип: строка)
	cvars.store_creditsEventEnd			= creditsEventEnd

	-- Trade
  	-- Максимальная сумма одной транзакции/письма. (тип: целое число)	
  	cvars.store_maxTransactionSum 	= 20000
	-- Минимальное значение антибот-счётчика для отправки почты. (тип: целое число; диапазон: 0..100)
	cvars.shard_minAntibotCounterForMailSending = 0

	-- Включает детальный лог решения при попытке игрока или отряда встать в очередь матчмейкера.
	-- 0 - лог выключен, любое число больше 0 - лог включён.
	cvars.mm_decisionLog		= 0
	
  	-- Лимит одинаковых unique-модулей на один корабль; отдельно задаётся для обычных и premium-кораблей.
  	-- Balanse rule
  	cvars.store_maxUniqueModules = 30
  	-- Лимит одинаковых unique-модулей на один корабль; отдельно задаётся для обычных и premium-кораблей.
  	-- #0098493: Сделать возможнсть установки экспериментальных модулей на прем. и ДЛЦ корабли в кол-ве 1 шт
  	cvars.store_maxUniqueModulesOnPremium = 2
	
	-- Список offerId офферов, которые нужно включить на shard-сервере.
	-- Идентификаторы берутся из файла offers.xml в этой же папке: ищите атрибут offerId у нужного оффера.
	-- Формат: числа через запятую, пробел или табуляцию; пустая строка отключает все офферы.
	cvars.sv_offerEnable = "6,7,17,18,19"
	
	-- Максимальная сумма одной транзакции/письма. (тип: целое число)
	cvars.store_maxTransactionSum 	= 20000
	
	-- brawl
	-- SC-112207
	local brawlSchedule =
	{
		-- Расписание задается на 28 дней.
		-- (условной точкой отсчета считается первый понедельник 2018г.)
		-- Гейплеи потасовок: "football", "gtdm", "hunger_games", "one_against_all", "sentinel", "capture_the_base", "atdm", "zombie", "close_distance", "autogen_dm", "three_teams_dm", "april_control"

		-- интервалы не обязательно прописывать в отсортированном порядке
		-- последний интервал дня может быть с переходом на другие сутки - {23,1} ("кроме перехода с воскресенья на понедельник следующей недели" - не актуально-)
		-- интервалы в течение одного дня пересекаться не должны 
		-- дни дублироваться не должны

		--[[{ days = { 1,  8, 15, 22 },	time_intervals = { {2,3}, {10,11}, {14,15}, {17,18}, {21,22} }, gameplay = "football"		},
		{ days = { 2, 7, 9, 16, 23 },	time_intervals = { {2,3}, {10,11}, {14,15}, {17,18}, {21,22} }, gameplay = "one_against_all"	},
		{ days = { 3, 10, 14, 17, 24 },	time_intervals = { {2,3}, {10,11}, {14,15}, {17,18}, {21,22} }, gameplay = "gtdm"	},
		{ days = { 4, 11, 18, 21, 25 },	time_intervals = { {2,3}, {10,11}, {14,15}, {17,18}, {21,22} }, gameplay = "hunger_games"	},
		{ days = { 5, 12, 19, 26, 28 },	time_intervals = { {2,3}, {10,11}, {14,15}, {17,18}, {21,22} }, gameplay = "sentinel"		},
		{ days = { 6, 13, 20, 27 },	time_intervals = { {2,3}, {10,11}, {14,15}, {17,18}, {21,22} }, gameplay = "capture_the_base"	},]]

		{ days = { 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28 },	time_intervals = { {1,2}, {9,10}, {15,16}, {17,18}, {19,20}, {21,22} }, gameplay = "three_teams_dm"	},
		
	}
	_G.BrawlManager_SetupSchedule( brawlSchedule )
	
	-- Максимальный шанс получить бонусный набор при покупке набора; шанс умножается на коэффициент (prestige / maxPrestige). (тип: дробное число; диапазон: 0.0f..1.0f)
	cvars.store_bonusBundleChancePercentageMax = 0.2
  
  	-- Premium-время, выдаваемое за ранг аккаунта. (тип: целое число)
  	-- премиум (в секундах, по умолчанию - день)
  	cvars.premiumTimeForAccountRank = 1 * 24 * 60 * 60
  
	-- Дневной лимит token credits, которые игрок может заработать за день.
	-- #106983
	cvars.sv_tokenCreditsDailyLimit = 1000

	-- список запрещенного оборудования (кораблей и модулей) в лигах
	Shard_SetupLeagueForbiddenEquipment( leagueForbiddenDefs )
	
	_G.Shard_SetupBattlePassActivation( battlePassStart, battlePassEndTable )

	-- Время, с которого появляется кнопка разблокировки уровня battle pass. (тип: строка)
	cvars.store_battlePassUnlockLvlBtnStart = "2026-10-09T00:00:00Z"

	-- Адаптивные пресеты ботов.
	-- Коэффициент увеличения BFL-роли. (тип: дробное число)
	-- bfl - battle time for life time
	-- цвар на увеличение статистики пресетов SC-115316
	cvars.sm_bflRoleInc = 0.5
	-- Коэффициент уменьшения BFL-роли. (тип: дробное число)
	-- цвар на уменьшение статистики пресетов
	cvars.sm_bflRoleDec = 0.05
	-- Количество адаптивных пресетов, сохраняемых в БД. 0 - очищает данные. (тип: целое число; диапазон: 0..1000)
	cvars.sm_numAdaptivePresetsToSaveDB = numAdaptivePresets
	
end


--
function InstantiateQueueTemplate( template, minMMRank, maxMMRank, minMMSquadRank, maxMMSquadRank, minMMValue, maxMMValue, addMods ) --  minDestrRank, maxDestrRank,
	local instance = sys.new( template )

	if ( instance.query.mmRank[ "$gte" ] ~= nil ) then
		instance.query.mmRank[ "$gte" ] = minMMRank
	end

	if ( instance.query.mmRank[ "$lte" ] ~= nil ) then
		instance.query.mmRank[ "$lte" ] = maxMMRank
	end
	
	if ( instance.query.mmSquadRank ~= nil ) then
		if ( instance.query.mmSquadRank[ "$gte" ] ~= nil ) then
			instance.query.mmSquadRank[ "$gte" ] = minMMSquadRank
		end	

		if ( instance.query.mmSquadRank[ "$lte" ] ~= nil ) then
			instance.query.mmSquadRank[ "$lte" ] = maxMMSquadRank
		end
	end

	if ( instance.query.mmValue[ "$gte" ] ~= nil ) then
		instance.query.mmValue[ "$gte" ] = minMMValue
	end

	if ( instance.query.mmValue[ "$lt" ] ~= nil ) then
		instance.query.mmValue[ "$lt" ] = maxMMValue
	end

	if( addMods ~= nil ) then
		sys.mergeTable( instance, addMods )
	end
	
	return instance
end

--
function ConfigureMatchmaker()

	-- Full map list
	-- s1338_pandora_dreadnwreck
	-- s1420_ceres3_northmsite

	-- s1338_devilsjaw
	-- s1340_thar_aliendebris13
	-- s1340_aliendestsatation
	-- s8256_thar_barrierdebris

	-- s1338_pandora_anomaly
	-- s1340_thar_gasgiant
	-- s1420_ceres3_asteroidcity
	-- s8256_thar_barrierdebris

	-- s1340_thar_gasgiant
	-- s8256_thar_barrierdebris
	-- s8256_thar_threshold
	-- s1340_aliendestsatation


	-- Тип адаптивных пресетов ботов.
	local bpt_none = 0
	local bpt_mirror = 1
	local bpt_adaptive = 2
	local bpt_mirror_and_save = 3

	-- MM queue setup
	local queuesConfigLo = {

		-- TRAINING QUEUES
		{
			maxPlayers = 10,
			minPlayers = 1,
			regionLocalizedTimeInQueue = 30,
			maxTimeInQueue = 45,
			levelsDesc = {
				s1338_pandora_dreadnwreck = {},
				s1338_pandora_anomaly = {},
				s1420_ceres3_northmsite = {},
			},
			query = { ["mmParams.practice"] = 1 },
			special = { gameMode = 5, botsCount = 0 },
		},

		-- PVE QUEUE
		{
			maxPlayers = 1,
			minPlayers = 1,
			regionLocalizedTimeInQueue = 10,
			maxTimeInQueue = 10,
			levelsDesc = {},
			query = { ["mmParams.pve"] = 1 },
			special = { pve = 1, gameMode = 7 },
		}
	}

 -- ARCADE & PvE QUEUES

	-- low on-line
	local arcadeQueueTemplate = {
		maxPlayers = 24,
		optimalPlayers = 4,
		minPlayers = 1,
		maxExpandTime = 30,
		regionLocalizedTimeInQueue = 10,
		maxTimeInQueue = 10,
		maxSquadTimeInQueue = 0x7FFFFFFF,
		levelsDesc = {
			s1338_devilsjaw = {4,9,11},
			s1420_ceres3_northmsite = {4,9,11},
			s1420_ceres3_asteroidcity = {4,9,11},
			s8256_thar_barrierdebris = {4,9,11},
			s1338_pandora_dreadnwreck = {4,9,11},
		},
		query = { ["mmParams.arcade"] = 1, mmRank = { ["$gte"] = 1, ["$lte"] = 15 }, mmSquadRank = { ["$gte"] = 1, ["$lte"] = 15 }, mmValue = { ["$gte"] = 0, ["$lt"] = 100 } },
		special = { arcade = 1 },
	}

	--
	--arcadeQueueTemplate.levelsDesc = "s1338_pandora_dreadnwreck:4; s1340_thar_aliendebris13:4; s8256_thar_threshold:4"
	table.insert( queuesConfigLo, InstantiateQueueTemplate( arcadeQueueTemplate, 1, 17, 1, 15, 0, 20, { special = { queueFlags = { newbie = 1, }, }, maxPlayers = 16 } ) )
	--
	--arcadeQueueTemplate.levelsDesc = "s1338_devilsjaw:4,9,10; s1340_aliendestsatation:4,10; s1340_thar_gasgiant:4,9; s1420_ceres3_northmsite:4,9,10"
	table.insert( queuesConfigLo, InstantiateQueueTemplate( arcadeQueueTemplate, 1, 17, 1, 15, 19, 24 ) )
	--
	--arcadeQueueTemplate.levelsDesc = "s1420_ceres3_asteroidcity:4,9,10,11; s1420_ceres3_northmsite:4,11; s8256_thar_barrierdebris:4,9,11; s8256_thar_threshold:4,9,10; s1347_livestation:4,10"
	table.insert( queuesConfigLo, InstantiateQueueTemplate( arcadeQueueTemplate, 1, 17, 1, 15, 24, 31 ) )
	--
	--arcadeQueueTemplate.levelsDesc = "s1338_pandora_anomaly:3,4,9,11; s1338_pandora_dreadnwreck:3,9,10,11; s1420_ceres3_asteroidcity:4,10; s1420_ceres3_northmsite:3,9,11; s8256_thar_lavastone:4,10"
	table.insert( queuesConfigLo, InstantiateQueueTemplate( arcadeQueueTemplate, 1, 17, 1, 15, 31, 39 ) )
	--
	--arcadeQueueTemplate.levelsDesc = "s1338_pandora_anomaly:3,4,10; s1338_pandora_dreadnwreck:3,4,9,11; s1340_aliendestsatation:3; s1340_thar_aliendebris13:3,4,9,10; s8256_thar_threshold:3,4,9"
	table.insert( queuesConfigLo, InstantiateQueueTemplate( arcadeQueueTemplate, 1, 17, 1, 15, 39, 51 ) )
	--
	--arcadeQueueTemplate.levelsDesc = "s1338_devilsjaw:3,4,9; s1340_aliendestsatation:3,4,9,10; s1340_thar_gasgiant:3,4; s1420_ceres3_northmsite:9; s8256_thar_lavastone:3,10,11; s8256_thar_threshold:3,11"
	table.insert( queuesConfigLo, InstantiateQueueTemplate( arcadeQueueTemplate, 1, 17, 1, 15, 51, 99 ) )

	local coopQueueTemplate = {
		maxPlayers = 12,
		optimalPlayers = 4,
		minPlayers = 1,
		regionLocalizedTimeInQueue = 10,
		maxTimeInQueue = 10,
		levelsDesc = {
			s1338_devilsjaw = {4,9,11},
			s1420_ceres3_northmsite = {4,9,11},
			s1420_ceres3_asteroidcity = {4,9,11},
			s8256_thar_barrierdebris = {4,9,11},
			s1338_pandora_dreadnwreck = {4,9,11},
		},
		query = { ["mmParams.coop_vs_ai"] = 1, mmRank = { ["$gte"] = 1, ["$lte"] = 15 }, mmValue = { ["$gte"] = 0, ["$lt"] = 100 } },
		special = { coop_vs_ai = 1 },
	}

	--
	--coopQueueTemplate.levelsDesc = "s1338_pandora_dreadnwreck:4; s1340_thar_aliendebris13:4; s8256_thar_threshold:4"
	table.insert( queuesConfigLo, InstantiateQueueTemplate( coopQueueTemplate, 1, 15, 1, 15, 0, 21, { special = { queueFlags = { newbie = 1, }, coop_vs_ai = 1 }, maxPlayers = 8 } ) )
	--
	--coopQueueTemplate.levelsDesc = "s1338_devilsjaw:4,9,10; s1340_aliendestsatation:4,10; s1340_thar_gasgiant:4,9; s1420_ceres3_northmsite:4,9,10"
	table.insert( queuesConfigLo, InstantiateQueueTemplate( coopQueueTemplate, 1, 15, 1, 15, 19, 24 ) )
	--
	--coopQueueTemplate.levelsDesc = "s1420_ceres3_asteroidcity:4,9,10,11; s1420_ceres3_northmsite:4,11; s8256_thar_barrierdebris:4,9,11; s8256_thar_threshold:4,9,10; s1347_livestation:4,10"
	table.insert( queuesConfigLo, InstantiateQueueTemplate( coopQueueTemplate, 1, 15, 1, 15, 24, 31 ) )
	--
	--coopQueueTemplate.levelsDesc = "s1338_pandora_anomaly:3,4,9,11; s1338_pandora_dreadnwreck:3,9,10,11; s1420_ceres3_asteroidcity:4,10; s1420_ceres3_northmsite:3,9,11; s8256_thar_lavastone:4,10"
	table.insert( queuesConfigLo, InstantiateQueueTemplate( coopQueueTemplate, 1, 15, 1, 15, 31, 39 ) )
	--
	--coopQueueTemplate.levelsDesc = "s1338_pandora_anomaly:3,4,10; s1338_pandora_dreadnwreck:3,4,9,11; s1340_aliendestsatation:3; s1340_thar_aliendebris13:3,4,9,10; s8256_thar_threshold:3,4,9"
	table.insert( queuesConfigLo, InstantiateQueueTemplate( coopQueueTemplate, 1, 15, 1, 15, 39, 51 ) )
	--
	--coopQueueTemplate.levelsDesc = "s1338_devilsjaw:3,4,9; s1340_aliendestsatation:3,4,9,10; s1340_thar_gasgiant:3,4; s1420_ceres3_northmsite:9; s8256_thar_lavastone:3,10,11; s8256_thar_threshold:3,11"
	table.insert( queuesConfigLo, InstantiateQueueTemplate( coopQueueTemplate, 1, 15, 1, 15, 51, 99 ) )


	-- BRAWL--

	local footballQueueTemplate = {
		maxPlayers = 6,
		optimalPlayers = 6,
		minPlayers = 2,
		maxExpandTime = 0,
		regionLocalizedTimeInQueue = 10,
		maxTimeInQueue = 10,
		levelsDesc = {
			football = { 21 },
		},
		query = { ["mmParams.football"] = 1 },
		special = { brawl = 1 },
	}

	table.insert( queuesConfigLo, footballQueueTemplate )

	local gtdmQueueTemplate = {
		maxPlayers = 2,
		optimalPlayers = 2,
		minPlayers = 2,
		maxExpandTime = 0,
		regionLocalizedTimeInQueue = 10,
		maxTimeInQueue = 10,
		levelsDesc = {
			da_prototype = { 13 },
		},
		query = { ["mmParams.gtdm"] = 1 },
		special = { brawl = 1 },
	}

	table.insert( queuesConfigLo, gtdmQueueTemplate )
	
	local atdmQueueTemplate = {
		maxPlayers = 8,
		optimalPlayers = 8,
		minPlayers = 2,
		maxExpandTime = 0,
		regionLocalizedTimeInQueue = 10,
		maxTimeInQueue = 10,
		levelsDesc = {
			paper_airplanes = { 26 },
		},
		query = { ["mmParams.atdm"] = 1 },
		special = { brawl = 1 },
	}

	table.insert( queuesConfigLo, atdmQueueTemplate )


	local sentinelQueueTemplate = {
		maxPlayers = 24,
		optimalPlayers = 8,
		minPlayers = 4,
		maxExpandTime = 0,
		regionLocalizedTimeInQueue = 10,
		maxTimeInQueue = 10,
		levelsDesc = {
			s1420_ceres3_asteroidcity = {9},
		},
		query = { ["mmParams.sentinel"] = 1 },
		special = { brawl = 1 },
	}

	table.insert( queuesConfigLo, sentinelQueueTemplate )

	local captureTheBaseQueueTemplate = {
		maxPlayers = 24,
		optimalPlayers = 8,
		minPlayers = 4,
		maxExpandTime = 0,
		regionLocalizedTimeInQueue = 10,
		maxTimeInQueue = 10,
		levelsDesc = {
			s1338_devilsjaw = { 3 },
		},
		query = { ["mmParams.capture_the_base"] = 1 },
		special = { brawl = 1 },
	}

	table.insert( queuesConfigLo, captureTheBaseQueueTemplate )


	local hangerGamesQueueTemplate = {
		maxPlayers = 24,
		optimalPlayers = 6,
		minPlayers = 2,
		maxExpandTime = 0,
		regionLocalizedTimeInQueue = 10,
		maxTimeInQueue = 10,
		levelsDesc = {
			s1338_hg_pandora_anomaly = { 24 },
		},
		query = { ["mmParams.hunger_games"] = 1 },
		special = { hunger_games = 1 },
	}

	table.insert( queuesConfigLo, hangerGamesQueueTemplate )

	local oneAgainstAllQueueTemplate = {
		maxPlayers = 24,
		optimalPlayers = 3,
		minPlayers = 2,
		maxExpandTime = 0,
		regionLocalizedTimeInQueue = 10,
		maxTimeInQueue = 10,
		levelsDesc = {
			s1338_hg_pandora_anomaly = { 25 },
		},
		query = { ["mmParams.one_against_all"] = 1 },
		special = { one_against_all = 1, botsCount = 7 },
	}

	table.insert( queuesConfigLo, oneAgainstAllQueueTemplate )

	local aprilTeamDeathMatchQueueTemplate = {
		maxPlayers = 24,
		optimalPlayers = 8,
		minPlayers = 2,
		maxExpandTime = 0,
		regionLocalizedTimeInQueue = 10,
		maxTimeInQueue = 10,
		levelsDesc = {
			paper_airplanes = { 26 },
		},
		query = { ["mmParams.atdm"] = 1 },
		special = { brawl = 1 },
	}

	table.insert( queuesConfigLo, aprilTeamDeathMatchQueueTemplate )


	local zombieQueueTemplate = {
		maxPlayers = 24,
		optimalPlayers = 10,
		minPlayers = 5,
		maxExpandTime = 0,
		regionLocalizedTimeInQueue = 10,
		maxTimeInQueue = 10,
		levelsDesc = {
			da_deathstar = { 27 },
		},
		query = { ["mmParams.zombie"] = 1 },
		special = { zombie = 1 },
	}

	table.insert( queuesConfigLo, zombieQueueTemplate )

	local closeDistanceQueueTemplate = {
		maxPlayers = 24,
		optimalPlayers = 8,
		minPlayers = 2,
		maxExpandTime = 0,
		regionLocalizedTimeInQueue = 10,
		maxTimeInQueue = 10,
		levelsDesc = {
			allidium_yard = { 28 },
		},
		query = { ["mmParams.close_distance"] = 1 },
		special = { close_distance = 1 },
	}

	table.insert( queuesConfigLo, closeDistanceQueueTemplate )

	local autogenDmGamesQueueTemplate = {
		maxPlayers = 24,
		optimalPlayers = 6,
		minPlayers = 2,
		maxExpandTime = 0,
		regionLocalizedTimeInQueue = 10,
		maxTimeInQueue = 10,
		levelsDesc = {
			s1338_pandora_anomaly = { 29 },
		},
		query = { ["mmParams.autogen_dm"] = 1 },
		special = { hunger_games = 1 },
	}

	table.insert( queuesConfigLo, autogenDmGamesQueueTemplate )


	local threeTeamsDeathMatchTemplate = {
		maxPlayers = 24,
		optimalPlayers = 6,
		minPlayers = 3,
		maxExpandTime = 0,
		regionLocalizedTimeInQueue = 10,
		maxTimeInQueue = 10,
		levelsDesc = {
			s1340_thar_alienruins = { 30 },
		},
		query = { ["mmParams.three_teams_dm"] = 1 },
		special = { three_teams_dm = 1 },
	}

	table.insert( queuesConfigLo, threeTeamsDeathMatchTemplate )


	local aprilControlQueueTemplate = {
		maxPlayers = 8,
		optimalPlayers = 8,
		minPlayers = 2,
		maxExpandTime = 0,
		regionLocalizedTimeInQueue = 10,
		maxTimeInQueue = 10,
		levelsDesc = {
			paper_airplanes = { 31 },
		},
		query = { ["mmParams.april_control"] = 1 },
		special = { brawl = 1 },
	}

	table.insert( queuesConfigLo, aprilControlQueueTemplate )

	-- high on-line

	-- MM queue setup
	local queuesConfig = {

		-- TRAINING QUEUES
		{
			maxPlayers = 10,
			minPlayers = 1,
			regionLocalizedTimeInQueue = 30,
			maxTimeInQueue = 45,
			levelsDesc = {
				s1338_pandora_dreadnwreck = {},
				s1338_pandora_anomaly = {},
				s1420_ceres3_northmsite = {},
			},
			query = { ["mmParams.practice"] = 1 },
			special = { gameMode = 5, botsCount = 0 },
		},

		-- PVE QUEUE
		{
			maxPlayers = 1,
			minPlayers = 1,
			regionLocalizedTimeInQueue = 10,
			maxTimeInQueue = 10,
			levelsDesc = {},
			query = { ["mmParams.pve"] = 1 },
			special = { pve = 1, gameMode = 7 },
		}
	}

	local arcadeQueueTemplate = {
		maxPlayers = 24,
		optimalPlayers = 4,
		minPlayers = 1,
		maxExpandTime = 30,
		regionLocalizedTimeInQueue = 10,
		maxTimeInQueue = 10,
		maxSquadTimeInQueue = 0x7FFFFFFF,
		levelsDesc = {
			s1338_devilsjaw = {9},
			-- s1420_ceres3_northmsite = {4,9,11},
			-- s1420_ceres3_asteroidcity = {4,9,11},
			-- s8256_thar_barrierdebris = {4,9,11},
			-- s1338_pandora_dreadnwreck = {4,9,11},
		},
		query = { ["mmParams.arcade"] = 1, mmRank = { ["$gte"] = 1, ["$lte"] = 15 }, mmSquadRank = { ["$gte"] = 1, ["$lte"] = 15 }, mmValue = { ["$gte"] = 0, ["$lt"] = 100 } },
		special = { arcade = 1 },
	}

	--
	--arcadeQueueTemplate.levelsDesc = "s1338_pandora_dreadnwreck:4; s1340_thar_aliendebris13:4; s8256_thar_threshold:4"
	table.insert( queuesConfig, InstantiateQueueTemplate( arcadeQueueTemplate, 1, 15, 1, 15, 0, 21, { special = { queueFlags = { newbie = 1, }, }, maxPlayers = 16 } ) )
	--
	--arcadeQueueTemplate.levelsDesc = "s1338_devilsjaw:4,9,10; s1340_aliendestsatation:4,10; s1340_thar_gasgiant:4,9; s1420_ceres3_northmsite:4,9,10"
	table.insert( queuesConfig, InstantiateQueueTemplate( arcadeQueueTemplate, 1, 15, 1, 15, 20, 24 ) )
	--
	--arcadeQueueTemplate.levelsDesc = "s1420_ceres3_asteroidcity:4,9,10,11; s1420_ceres3_northmsite:4,11; s8256_thar_barrierdebris:4,9,11; s8256_thar_threshold:4,9,10; s1347_livestation:4,10"
	table.insert( queuesConfig, InstantiateQueueTemplate( arcadeQueueTemplate, 1, 15, 1, 15, 23, 28 ) )
	--
	--arcadeQueueTemplate.levelsDesc = "s1340_aliendestsatation:9,11; s1340_thar_aliendebris13:3,4,10; s1340_thar_gasgiant:3,9,11; s8256_thar_barrierdebris:4,10; s8256_thar_lavastone:3,4,9,10,11"
	table.insert( queuesConfig, InstantiateQueueTemplate( arcadeQueueTemplate, 1, 15, 1, 15, 26, 31 ) )
	--
	--arcadeQueueTemplate.levelsDesc = "s1338_pandora_anomaly:3,4,9,11; s1338_pandora_dreadnwreck:3,9,10,11; s1420_ceres3_asteroidcity:4,10; s1420_ceres3_northmsite:3,9,11; s8256_thar_lavastone:4,10"
	table.insert( queuesConfig, InstantiateQueueTemplate( arcadeQueueTemplate, 1, 15, 1, 15, 30, 35 ) )
	--
	--arcadeQueueTemplate.levelsDesc = "s1338_devilsjaw:3,10,11; s1338_pandora_anomaly:3,4,9,11; s1420_ceres3_northmsite:3,4,9; s8256_thar_threshold:3,4,9; s1347_livestation:4,10"
	table.insert( queuesConfig, InstantiateQueueTemplate( arcadeQueueTemplate, 1, 15, 1, 15, 33, 38 ) )
	--
	--arcadeQueueTemplate.levelsDesc = "s1338_pandora_dreadnwreck:3,9,10; s1340_thar_gasgiant:3,9,10; s1420_ceres3_asteroidcity:3,4,9; s8256_thar_barrierdebris:3,4,11; s8256_thar_threshold:4,10"
	table.insert( queuesConfig, InstantiateQueueTemplate( arcadeQueueTemplate, 1, 15, 1, 15, 37, 42 ) )
	--
	--arcadeQueueTemplate.levelsDesc = "s1338_pandora_anomaly:3,4,10; s1338_pandora_dreadnwreck:3,4,9,11; s1340_aliendestsatation:3; s1340_thar_aliendebris13:3,4,9,10; s8256_thar_threshold:3,4,9"
	table.insert( queuesConfig, InstantiateQueueTemplate( arcadeQueueTemplate, 1, 15, 1, 15, 40, 45 ) )
	--
	--arcadeQueueTemplate.levelsDesc = "s1338_devilsjaw:3,4,10; s1340_thar_gasgiant:3,9,11; s1420_ceres3_asteroidcity:3,10; s8256_thar_lavastone:3,4,9; s1347_livestation:4"
	table.insert( queuesConfig, InstantiateQueueTemplate( arcadeQueueTemplate, 1, 15, 1, 15, 44, 51 ) )
	--
	--arcadeQueueTemplate.levelsDesc = "s1338_devilsjaw:3,4,9; s1340_aliendestsatation:3,4,9,10; s1340_thar_gasgiant:3,4; s1420_ceres3_northmsite:9; s8256_thar_lavastone:3,10,11; s8256_thar_threshold:3,11"
	table.insert( queuesConfig, InstantiateQueueTemplate( arcadeQueueTemplate, 1, 15, 1, 15, 51, 99 ) )

	local coopQueueTemplate = {
		maxPlayers = 12,
		optimalPlayers = 4,
		minPlayers = 1,
		regionLocalizedTimeInQueue = 10,
		maxTimeInQueue = 10,
		levelsDesc = {
			s1338_devilsjaw = {4,9,11},
			s1420_ceres3_northmsite = {4,9,11},
			s1420_ceres3_asteroidcity = {4,9,11},
			s8256_thar_barrierdebris = {4,9,11},
			s1338_pandora_dreadnwreck = {4,9,11},
		},
		query = { ["mmParams.coop_vs_ai"] = 1, mmRank = { ["$gte"] = 1, ["$lte"] = 15 }, mmValue = { ["$gte"] = 0, ["$lt"] = 100 } },
		special = { coop_vs_ai = 1 },
	}

	--
	--coopQueueTemplate.levelsDesc = "s1338_pandora_dreadnwreck:4; s1340_thar_aliendebris13:4; s8256_thar_threshold:4"
	table.insert( queuesConfig, InstantiateQueueTemplate( coopQueueTemplate, 1, 15, 1, 15, 0, 21, { special = { queueFlags = { newbie = 1, }, }, maxPlayers = 8 } ) )
	--
	--coopQueueTemplate.levelsDesc = "s1338_devilsjaw:4,9,10; s1340_aliendestsatation:4,10; s1340_thar_gasgiant:4,9; s1420_ceres3_northmsite:4,9,10"
	table.insert( queuesConfig, InstantiateQueueTemplate( coopQueueTemplate, 1, 15, 1, 15, 20, 24 ) )
	--
	--coopQueueTemplate.levelsDesc = "s1420_ceres3_asteroidcity:4,9,10,11; s1420_ceres3_northmsite:4,11; s8256_thar_barrierdebris:4,9,11; s8256_thar_threshold:4,9,10; s1347_livestation:4,10"
	table.insert( queuesConfig, InstantiateQueueTemplate( coopQueueTemplate, 1, 15, 1, 15, 23, 28 ) )
	--
	--coopQueueTemplate.levelsDesc = "s1340_aliendestsatation:9,11; s1340_thar_aliendebris13:3,4,10; s1340_thar_gasgiant:3,9,11; s8256_thar_barrierdebris:4,10; s8256_thar_lavastone:3,4,9,10,11"
	table.insert( queuesConfig, InstantiateQueueTemplate( coopQueueTemplate, 1, 15, 1, 15, 26, 31 ) )
	--
	--coopQueueTemplate.levelsDesc = "s1338_pandora_anomaly:3,4,9,11; s1338_pandora_dreadnwreck:3,9,10,11; s1420_ceres3_asteroidcity:4,10; s1420_ceres3_northmsite:3,9,11; s8256_thar_lavastone:4,10"
	table.insert( queuesConfig, InstantiateQueueTemplate( coopQueueTemplate, 1, 15, 1, 15, 30, 35 ) )
	--
	--coopQueueTemplate.levelsDesc = "s1338_devilsjaw:3,10,11; s1338_pandora_anomaly:3,4,9,11; s1420_ceres3_northmsite:3,4,9; s8256_thar_threshold:3,4,9; s1347_livestation:4,10"
	table.insert( queuesConfig, InstantiateQueueTemplate( coopQueueTemplate, 1, 15, 1, 15, 33, 38 ) )
	--
	--coopQueueTemplate.levelsDesc = "s1338_pandora_dreadnwreck:3,9,10; s1340_thar_gasgiant:3,9,10; s1420_ceres3_asteroidcity:3,4,9; s8256_thar_barrierdebris:3,4,11; s8256_thar_threshold:4,10"
	table.insert( queuesConfig, InstantiateQueueTemplate( coopQueueTemplate, 1, 15, 1, 15, 37, 42 ) )
	--
	--coopQueueTemplate.levelsDesc = "s1338_pandora_anomaly:3,4,10; s1338_pandora_dreadnwreck:3,4,9,11; s1340_aliendestsatation:3; s1340_thar_aliendebris13:3,4,9,10; s8256_thar_threshold:3,4,9"
	table.insert( queuesConfig, InstantiateQueueTemplate( coopQueueTemplate, 1, 15, 1, 15, 40, 45 ) )
	--
	--coopQueueTemplate.levelsDesc = "s1338_devilsjaw:3,4,10; s1340_thar_gasgiant:3,9,11; s1420_ceres3_asteroidcity:3,10; s8256_thar_lavastone:3,4,9; s1347_livestation:4"
	table.insert( queuesConfig, InstantiateQueueTemplate( coopQueueTemplate, 1, 15, 1, 15, 44, 51 ) )
	--
	--coopQueueTemplate.levelsDesc = "s1338_devilsjaw:3,4,9; s1340_aliendestsatation:3,4,9,10; s1340_thar_gasgiant:3,4; s1420_ceres3_northmsite:9; s8256_thar_lavastone:3,10,11; s8256_thar_threshold:3,11"
	table.insert( queuesConfig, InstantiateQueueTemplate( coopQueueTemplate, 1, 15, 1, 15, 51, 99 ) )


    -- SECTOR BATTLE QUEUES
    local sectorQueue = {
        maxPlayers = 20,
        regionLocalizedTimeInQueue = 1, -- default value is 120, override it by something small
        special = {
			universe = 1,
			minSizeWing = 5,
			minSizeTeam = 4,
			withBots = true,
			botPresetType = bpt_none,
			botPresetByTier = {"BotsBZS_T3","BotsBZS_T3","BotsBZS_T3","BotsBZS_T4","BotsBZS_T5"},
			queueFlags = { universe = 1, rank = 15, },
		},
        squadFilter = 0,
        qid = 501,
        levelsDesc = { dreadnoughtbattle_map_01 = { 14 }, dreadnoughtbattle_map_02 = { 14 }, dreadnoughtbattle_map_03 = { 14 }, dreadnoughtbattle_map_04 = { 14 }, dreadnoughtbattle_map_05 = { 14 }, dreadnoughtbattle_map_06 = { 14 } },
        query = { ["mmParams.universe"] = 1, ["mmParams.universe_bfs"] = 1},
    }

    table.insert( queuesConfig, sectorQueue )
    table.insert( queuesConfigLo, sectorQueue )

    -- SECTOR BATTLE QUEUES LEAGUES #0108276
    local leagueQueue = {
        maxPlayers = 12,
        regionLocalizedTimeInQueue = 1, -- default value is 120, override it by something small
        special = { universe = 1, minSizeWing = 3, minSizeTeam = 1, withBots = false, botPresetByTier = {"BotsBZS_T3","BotsBZS_T3","BotsBZS_T3","BotsBZS_T4","BotsBZS_T5"}, queueFlags = { universe = 1, rank = 15, }, },
        squadFilter = 0,
        qid = 502,
        levelsDesc = {
            s8256_thar_barrierdebris = {3},
            s1338_devilsjaw = {3},
            s1338_pandora_dreadnwreck = {3},
            s1340_thar_aliendebris13 = {3},
            s1340_thar_gasgiant = {3},
            s1420_ceres3_asteroidcity = {3},
            s1338_pandora_anomaly = {3},
            s8256_thar_concourse = {3},
            s8256_thar_lavastone = {3},
            desttown = {3}
        },
        query = { ["mmParams.universe"] = 1, ["mmParams.universe_arena"] = 1},
    }

    table.insert( queuesConfig, leagueQueue )
    table.insert( queuesConfigLo, leagueQueue )


	-- pve raid #0046436

	local raidQueue = {
		maxPlayers = 12,
		optimalPlayers = 12,
		minPlayers = 1,
		regionLocalizedTimeInQueue = 10,
		maxTimeInQueue = 10,
		levelsDesc = {},
		special = { pve_raid = 1, gameMode = 7 },
		query = { ["mmParams.pve_raid"] = 1 },
		--squadFilter = 4, -- wings only, now use cvar in shard mm_raidSquadFilter
	}

	table.insert( queuesConfig, raidQueue )
	table.insert( queuesConfigLo, raidQueue )

	--
	MatchMaker_ReconfigureQueues( queuesConfig )

	-- low online queues
	MatchMaker_ReconfigureQueues( queuesConfigLo, true )
	-- Переход в режим низкого онлайна, если онлайн меньше этого значения. (тип: целое число)
	cvars.mm_lowOnlineLo = 250
	-- Выход из режима низкого онлайна, если онлайн не меньше этого значения. (тип: целое число)
	cvars.mm_lowOnlineHi = 300

	-- Количество ботов. (тип: целое число; диапазон: 0..31)
	-- Базовое количество ботов; в конкретной очереди может быть переопределено.
	cvars.mm_botsCount = 6

	-- Базовый игровой режим для новой игровой сессии; в конкретной очереди может быть переопределён.
	-- Возможные значения (не все работают):
	-- 0 - none
	-- 1 - space battle
	-- 2 - capture the flag
	-- 3 - capture the base
	-- 4 - control
	-- 5 - practice
	-- 6 - tutorial
	-- 7 - PvE mission
	-- 8 - free space
	-- 9 - sentinel
	-- 10 - king of the hill
	-- 11 - bomb the base
	-- 12 - TDM
	-- 13 - GTDM
	-- 14 - clanship
	-- 15 - capture the frag
	-- 16 - last man standing
	-- 17 - transport escort
	-- 18 - open space
	-- 19 - mission script
	-- 20 - PvP mission
	-- 21 - football
	-- 22 - battle royale
	-- 23 - capture the base 2
	-- 24 - hunger games
	-- 25 - one against all
	-- 26 - ATDM
	-- 27 - zombie
	-- 28 - close distance
	-- 29 - autogen DM
	-- 30 - three teams DM
	-- 31 - april control
	cvars.mm_defaultGameplay		= 3

	-- Чем больше значение, тем плавнее и медленнее меняется среднее время в очереди. (тип: целое число; диапазон: 2..10000)
	-- 10 for dev/test, >100 for live
	cvars.mm_timeInQueueAveragingCf	= 200

	-- Множители выдаваемого опыта по рангам, список через запятую. (тип: строка)
	-- reward multiplication rates
	cvars.rate_exp					= "1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"
	-- Множители выдаваемых кредитов по рангам, список через запятую. (тип: строка)
	cvars.rate_cred					= "1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"

	-- Детальность decision-log внутри матчмейкера. Это битовая маска: чтобы включить несколько категорий, сложите их числа.
	-- 0 - выключено; 1 - базовые PvP-решения; 2 - PvP join-in-progress; 4 - PvP-кандидаты.
	-- 8 - coop; 16 - coop join-in-progress; 32 - PvE; 64 - universe; 128 - brawl; 256 - brawl-кандидаты.
	-- 512 - hunger games; 1024 - one against all; 2048 - zombie; 4096 - three teams; 8192 - close distance; 16384 - общие решения.
	-- Пример: 33 включит базовый PvP-лог и PvE-лог (1 + 32). Все категории: 32767.
	cvars.mm_decisionLog			= 0
	-- Способ вывода decision-log матчмейкера.
	-- 0 - накапливать строки лога и выводить их одним блоком в info-лог после окончания разбора записей.
	-- 1 - писать каждое сообщение сразу в debug-лог; удобно для онлайн-отладки, но может давать много записей.
	cvars.mm_decisionDbg			= 0

	local reward_mult = {
		-- day = 0; понедельник начинается с 0
		[ 0 ] =
		{
			{ hourBegin = 0, hourEnd = 1, rateExp = "1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1", rateCred = "1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1", },
			{ hourBegin = 0, hourEnd = 3, rateExp = "1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1", rateCred = "1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1", },
			{ hourBegin = 2, hourEnd = 5, goldReward = 50 },
		},
		
		[ 6 ] =
		{
			{ hourBegin = 10, hourEnd = 13, goldReward = 100 },
		},
	}

	MatchMaker_SetRewardRates( reward_mult )
	
	
	-- расписание pve-миссий для выбора игроком
	local pveSchedule =
	{
		rotatingLevels =
		{
			"pve_frozen_station",
			--"pve_jericho_base",
			--"pve_wave_nalnifan_gate_lumen",
			--"pve_wave_planet_war",
		--	"s1347_geostation",
		--	"s1515_piratebay",
			"s1550_pve_asteroid_building",
			"s1550_pve_bigship_building",
			"s1550_pve_bigship_building_2",
			"s1550_pve_capture_repairbase",
			"pve_desttown",
			"pve_stealth",
		},
		
		maxRotatingLevels	= 12,
		rotationTime		= 2 * 60 * 60,	--[сек]

		permanentLevels =
		{
			"pve_transit_emp_rock_frontier",
		},
	}
	MatchMaker_SetPveSchedule( pveSchedule )
	
end


function ConfigureAdventureServer()

  -- Включает/выключает сохранение предложений adventure-giver в базу данных. (тип: логический)
  -- при 1 - сохраняются предложения, при 0 - не сохраняются
  cvars.adventure_saveGiverOffers = 0

end


--
function ConfigureScriptsServer()
	-- Должен ли экземпляр зоны обмениваться данными с сервером скриптов. (тип: логический)
	cvars.sv_enableCommunticationWithSS = 1

	-- Отключает проверку формата Lua-данных (например playerLuaData зоны) при их конвертации и сохранении в базу.
	-- 1 - данные записываются без сверки со схемой; работает только на не-live сборках (тест/отладка).
	--cvars.dbg_disableLuaDataFormatChecking = 1
	
	--передаем SS дефолтные настройки, например "идет эвент "зеленая война" уровня "хард" "
	if ScriptsServer and ScriptsServer.ConfigureGlobalEvents then
						-- Зеленые:
						--7 пре евент
						--2 владение
						--1 вторжение
						--6 таймер для вторжение GREEN_PRE_EXPANSION
						--места столиц зеленых
--"ruinsbig_expanse_empty_tube_l_ow"  213 -- Заброшенный комплекс   -- за иерихоном 
--"wreck_emp_rock_02_r_ow" 11 -- Разрушенная лаборатория     -- империя - федерация
--"miners_fed_rock_01_l_ow" 224 --  Северная добывающая станция      федерация иерихон

		ScriptsServer:ConfigureGlobalEvents( 
			{ 
			--Вариант на пре-эвент

--[[ 				forceEvents = { -- 
					{
						-- ai.ZoneInstanceEvents.GREEN_PRE_EVENT
						eventDefName = 7, -- деф эвента -- если нет, будет создан, если есть, то модифицируются упомянутые цифры
						--disableCreate = true,	-- не делаем эвента, если нет его
						--removeEvent 	= true,	-- если эвент есть, надо удалить евент
						eventLocation = 11,	-- в какую локацию  ( 25 водосбор-пвп между федерацией - империей ) 231 - стартовая
						newEventState = 1000,
						--newEventState = -100501, -- TIMEOUT_EVENT		= -100501, 
						--newEventState = 500,
						--eventParams = {	},	-- какие перезаписать параметры
					},
					{
						eventDefName = 7, --
						newEventState = 1000,
						eventLocation = 213,	-- в какую локацию 
					},
					{
						eventDefName = 7, --
						newEventState = 1000,
						eventLocation = 224,	-- в какую локацию 
					},
				}, ]]

--Вариант "на старт"
--[[
				forceEvents = { -- 
					{
						-- ai.ZoneInstanceEvents.GREEN_OWNERSHIP
						eventDefName = 2, -- деф эвента -- если нет, будет создан, если есть, то модифицируются упомянутые цифры
						--disableCreate = true,	-- не делаем эвента, если нет его
						--removeEvent 	= true,	-- если эвент есть, надо удалить евент
						eventLocation = 11,	-- в какую локацию  ( 25 водосбор-пвп между федерацией - империей ) 231 - стартовая
						newEventState = 1000,
						--newEventState = -100501, -- TIMEOUT_EVENT		= -100501, 
						--newEventState = 500,
						--eventParams = {	},	-- какие перезаписать параметры
					},
					{
						eventDefName = 2, --
						newEventState = 1000,
						eventLocation = 213,	-- в какую локацию 
					},
					{
						eventDefName = 2, --
						newEventState = 1000,
						eventLocation = 224,	-- в какую локацию 
					},
				},
]]
--Вариант "на старт" с контрударами (на ноябрь не готово) --!!!
--[[
				forceEvents = { -- 
					{
						-- ai.ZoneInstanceEvents.GREEN_OWNERSHIP
						eventDefName = 2, -- деф эвента -- если нет, будет создан, если есть, то модифицируются упомянутые цифры
						--disableCreate = true,	-- не делаем эвента, если нет его
						--removeEvent 	= true,	-- если эвент есть, надо удалить евент
						eventLocation = 11,	-- в какую локацию  ( 25 водосбор-пвп между федерацией - империей ) 231 - стартовая
						newEventState = 1000,
						--newEventState = -100501, -- TIMEOUT_EVENT		= -100501, 
						--newEventState = 500,
						--eventParams = {	},	-- какие перезаписать параметры
					},
					{
						eventDefName = 2, --
						newEventState = 1000,
						eventLocation = 213,	-- в какую локацию 
					},
					{
						eventDefName = 2, --
						newEventState = 1000,
						eventLocation = 224,	-- в какую локацию 
					},
					
					{
						eventDefName = 8,--8=управление контратакой -- деф эвента -- если нет, будет создан, если есть, то модифицируются упомянутые цифры
						--removeEvent 	= true,
						eventLocation = 1,	-- в какую локацию  ( 25 водосбор-пвп между федерацией - империей ) 231 - стартовая
						eventParams = {		-- какие перезаписать параметры
						},
					},
				},
--]]
			
-- мой дебаг
				--[[
				forceEvents = { -- 
					{
						-- ai.ZoneInstanceEvents.GREEN_PRE_EVENT
						eventDefName = 7, -- деф эвента -- если нет, будет создан, если есть, то модифицируются упомянутые цифры
						--disableCreate = true,	-- не делаем эвента, если нет его
						--removeEvent 	= true,	-- если эвент есть, надо удалить евент
						eventLocation = 11,	-- в какую локацию  ( 25 водосбор-пвп между федерацией - империей ) 231 - стартовая
						--newEventState = -100501, -- TIMEOUT_EVENT		= -100501, 
						--newEventState = 500,
						eventParams = {		-- какие перезаписать параметры
							},
					},
					{
						eventDefName = 2, -- --2 владение Заброшенный комплекс   -- за иерихоном 
						newEventState = 1000,
						eventLocation = 213,	-- в какую локацию  ( 25 водосбор-пвп между федерацией - империей ) 231 - стартовая
					},
					{
						eventDefName = 1, -- 1 вторжение  --  Северная добывающая станция      федерация иерихон
						eventLocation = 224,	-- в какую локацию  ( 25 водосбор-пвп между федерацией - империей ) 231 - стартовая
					},
					 --104        -- Пустошь  -- империя - федерация рядом с 11
					-- готовятся к вторжению 6 GREEN_PRE_EXPANSION  Пустошь 
					{
						eventDefName = 6, -- готовятся к вторжению 6 GREEN_PRE_EXPANSION  --  Северная добывающая станция      федерация иерихон
						eventLocation = 104,	-- в какую локацию  
						newEventState = 60*60*3, -- 3 часа
					},

					{
						eventDefName = 8,--8=управление контратакой -- деф эвента -- если нет, будет создан, если есть, то модифицируются упомянутые цифры
						--removeEvent 	= true,
						eventLocation = 1,	-- в какую локацию  ( 25 водосбор-пвп между федерацией - империей ) 231 - стартовая
						eventParams = {		-- какие перезаписать параметры
						},
					},

					{ --  234
						eventDefName = 9, --  империя готовится к вторжению
						newEventState = 60*60*3, -- 3 часа
						eventLocation = 234,	--
					},
					
					{ --  империя вторгается
						eventDefName = 12, -- --2 владение Заброшенный комплекс   -- за иерихоном 
						newEventState = 400, 
						eventLocation = 212,	-- в какую локацию  ( 25 водосбор-пвп между федерацией - империей ) 231 - стартовая
					},
				},
				]]
			})
		--sys.log("test out2")
		-- ScriptsServer:ConfigureGlobalEvents( { forceEvents = { { eventDefName = 4, eventLocation = 247, newEventState = 998, } } })
		ScriptsServer:SetTimerScale( 1 ) 
		--ScriptsServer:OnSetTimerScale( 60 * 60 )  --60 * 60    1 секунда= 1час   || не все параметры поддерживают ускорение.
	end
end


--
function ConfigureDediServer()
	-- Ограничивает FPS этим значением; 0 — ограничение выключено. (тип: дробное число)
	cvars.cl_maxFps = 18

	-- Отладка подключения к уже идущему бою. (тип: логический)
	cvars.sv_dbgJoinInProgress			= 0
	-- Логирование combat-событий в файл лога; каждый уровень включает все предыдущие.
	-- 0 - отключено; 1 - убийства/смерти/награды; 2 - +использование модулей, ракет и аур.
	-- 3 - +весь урон; 4 - +коэффициенты параметров геймплейных аур.
	cvars.cl_combatLog					= 0
	-- Логирование протокола базы данных: 1 — краткое, 2 — полное. (тип: целое число)
	-- to catch some nasty stuff
	cvars.db_logMessages				= 0
	-- Переопределяет игровую настройку штрафа времени возрождения за смерть. (тип: дробное число)
	-- to use gameplaysettings values
	cvars.sv_respawnTimePenalty			= -1
	-- Время в секундах, через которое игрок кикается за AFK, если он не присылал управляющие ввод или они не менялись.
	-- Большое значение (напр. 3600) фактически отключает AFK-кик. (тип: дробное число)
	cvars.sv_afkCheckDuration			= 120
	-- Включает/выключает послебоевой loot. (тип: логический)
	--
	cvars.sv_lootEnabled				= 1
	-- Шанс ничего не найти. (тип: дробное число; диапазон: 0.0f..1.0f)
	cvars.sv_lootFailChance				= 0
	-- Время сканирования в секундах. (тип: дробное число)
	cvars.sv_lootScanTime				= 1
	-- Длительность стадии сбора loot. (тип: дробное число)
	cvars.sv_lootDuration				= 120

	-- Коэффициент обычной salvage-конвертации найденного loot-предмета в токены.
	-- Возврат считается от tokenPrice предмета: tokensRefund = tokenPrice * sv_salvageTokenConversion. (тип: дробное число)
	cvars.sv_salvageTokenConversion		= 0.2
	-- Коэффициент premium salvage-конвертации найденного loot-предмета в токены.
	-- Premium-вариант требует оплату premium-валютой и возвращает токены по формуле: tokensRefund = tokenPrice * sv_salvagePremiumTokenConversion. (тип: дробное число)
	cvars.sv_salvagePremiumTokenConversion	= 0.6
	-- Коэффициент стоимости premium salvage для найденного loot-предмета.
	-- Цена premium-варианта считается от обычной цены предмета: premiumPrice = price * sv_salvagePremiumPriceConversion. (тип: дробное число)
	cvars.sv_salvagePremiumPriceConversion = 0.0008

	-- Коэффициент награды для BFS-боя wing vs wing. (тип: дробное число; диапазон: 1.0f..10.0f)
	cvars.sv_universeWingVsWingRewardCf = 2.0
	-- Принудительный режим управления кораблём. (тип: целое число; диапазон: -1..5)
	-- Значения: -1 — не форсировать; 0 — FOLLOWING; 1 — COMBINED; 2 — LOCAL_TURRET; 3 — REMOTE_TURRET; 4 — LANDED; 5 — WOW.
	cvars.ship_controlForceMode			= -1
	-- Особый режим поворота UFO-корабля по оси X.
	-- UFO ship controls
	cvars.ship_ufoRotateX = 1
	-- Включает/выключает игровые достижения. (тип: логический)
	cvars.sv_achievementEnabled			= 1
	-- Минимальный интервал отправки прогресса игрока на сервер достижений, в секундах. (тип: дробное число)
	cvars.sv_achievProgressTimer		= 3

	-- Включает событие «День космонавтики». (тип: логический)
	-- EVENTS
	cvars.event_cosmonauticsDay	 		= 0
	-- Включает событие «Годовщина игры». (тип: логический)
	cvars.event_gameAnniversary			= 0
	-- Включает событие «23 февраля». (тип: логический)
	cvars.event_february23				= 0
	-- Включает событие «8 марта». (тип: логический)
	cvars.event_march8					= 0
	-- Включает событие с префиксом ботов. (тип: логический)
	cvars.event_botPrefix				= 0
	-- Включает событие Claws. (тип: логический)
	cvars.event_claws					= 0
	-- Включает событие «День знаний». (тип: логический)
	cvars.event_knowledgeDay			= 0
	-- Включает событие Halloween. (тип: целое число)
	cvars.event_halloween				= 0
    -- Включает событие вторжения в PvP. (тип: логический)
    cvars.event_invasionPVP				= 0
	-- Включает событие «День святого Валентина». (тип: логический)
	cvars.event_valentinesDay 			= 0
	-- Включает AI-логику кораблей. (тип: логический)
	--DEBUG
	cvars.ship_aiThink					= 1
	-- Коэффициент награды свободной синергии. (тип: дробное число)
	cvars.sv_freeSynergyRewardCf		= 0.05
	-- Коэффициент награды свободной синергии для premium-корабля. (тип: дробное число)
	cvars.sv_freeSynergyRewardCfPremiumVessel	= 0.2
	-- Дополнительный коэффициент опыта синергии за убийство/помощь с gold munition. (тип: дробное число)
	cvars.sv_goldMunitionExpRewardCf	= 1.0

	-- Бюджет времени для инкрементальной работы Lua GC, в микросекундах. (тип: целое число)
	cvars.script_gcWorkBudget			= 1

  	-- Множитель опыта за первую PvE-победу дня. (тип: дробное число)
	-- x3 FIRST WIN
  	cvars.sv_dailyWinPveExpRewardCf	 	= x3fw
	-- Множитель опыта за первую PvP-победу дня. (тип: дробное число)
	cvars.sv_dailyWinPvpExpRewardCf		= x3fw
  	-- Множитель опыта за первую coop-победу дня. (тип: дробное число)
  	cvars.sv_dailyWinCoopExpRewardCf	= x3fw
  	-- Множитель опыта за первую brawl-победу дня. (тип: дробное число)
  	cvars.sv_dailyWinBrawlExpRewardCf 	= x3fw

  	-- Шанс выдачи event-label (пометки корабля как агента события для игрока) для PvP-боёв.
  	-- Задаётся по рангам как список из 18 дробных чисел от 0 до 1; первое число для 1-го ранга, второе для 2-го и т. д. (тип: строка)
  	cvars.sv_pvpLabelChances			= "0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"
    -- То же, что и sv_pvpLabelChances, но для PvE-миссий и рейдов. (тип: строка)
    cvars.sv_pveLabelChances			= "0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"

 	-- Количество попыток выбора rare-таблицы loot с плавающими шансами. (тип: целое число)
 	-- rare_limit
 	cvars.sv_rarePicksNumberWithFloatingChances = 100
    -- Количество попыток выбора epic-таблицы loot с плавающими шансами. (тип: целое число)
    -- epic_limit
    cvars.sv_epicPicksNumberWithFloatingChances = 150
    -- Базовый шанс выбрать rare-таблицу loot. (тип: дробное число)
    cvars.sv_overlootedRarePickChance = 0.004
    -- Базовый шанс выбрать epic-таблицу loot. (тип: дробное число)
    cvars.sv_overlootedEpicPickChance = 0
    -- Базовый шанс выбрать common-таблицу loot. (тип: дробное число)
    -- common_default_weight
    cvars.sv_lootCommonPickChance = 0.2
  	-- Ограничивает rare- и epic-таблицы loot только кораблями максимального уровня. (тип: логический)
  	-- max rank ships for loot
  	cvars.sv_lootMaxLevelRestriction = 0

	-- Множитель A в формуле веса выбора rare/epic loot-таблицы. (тип: дробное число)
	cvars.sv_lootRuleCfA = 0.25
	-- Базовый вес B (свободный член) в формуле веса rare/epic loot-таблицы. (тип: дробное число)
	cvars.sv_lootRuleCfB = 0.25
	-- Сдвиг offset: корректирует порог attempts, с которого начинает расти плавающий шанс rare/epic. (тип: дробное число)
	-- Формула: weight = max(0, sv_lootRuleCfA * (attempts - (it + sv_lootRuleCfOffset)) + sv_lootRuleCfB).
	-- attempts - число попыток без rare/epic; it - порог из iter в loot-правиле для текущей по счёту выдачи.
	cvars.sv_lootRuleCfOffset = -1

	-- Путь для сохранения replay dedicated-сервера. (тип: строка)
	cvars.sv_autorecordReplaysTo = ""
	
	-- Время начала кастомного события. (тип: строка)
	-- "Необходимо изменять время начала и конца кратно часу, иначе квест imaginary может вести себя
	cvars.event_custom 			= event_custom
	
	
	DedicatedServcerServices_SetLootRules(
	{
	-- ranks
	[1] = { common = { lt = "CommonRanks_1_3", iter = { 0 } }, rare = { lt = "RareT1", iter = { 3,5,12,12,12,12,12,12,12,30,50 } }, epic = { lt = "RareT1", iter = { 100000, 100000 } } },
	[2] = { common = { lt = "CommonRanks_1_3", iter = { 0 } }, rare = { lt = "RareT1", iter = { 4,3,11,11,11,11,11,11,11,30,50 } }, epic = { lt = "RareT1", iter = { 100000, 100000 } } },
	[3] = { common = { lt = "CommonRanks_1_3", iter = { 0 } }, rare = { lt = "RareT1", iter = { 5,4,10,10,10,10,10,10,10,30,50 } }, epic = { lt = "RareT1", iter = { 100000, 100000 } } },
	[4] = { common = { lt = "CommonRanks_4_6", iter = { 0 } }, rare = { lt = "RareT2", iter = { 6,12,12,14,12,14,12,14,12,30,50 } }, epic = { lt = "RareT2", iter = { 100000, 100000 } } },
	[5] = { common = { lt = "CommonRanks_4_6", iter = { 0 } }, rare = { lt = "RareT2", iter = { 7,11,13,12,15,12,14,12,13,30,50 } }, epic = { lt = "RareT2", iter = { 100000, 100000 } } },
	[6] = { common = { lt = "CommonRanks_4_6", iter = { 0 } }, rare = { lt = "RareT2", iter = { 8,10,12,15,12,12,15,12,12,30,50 } }, epic = { lt = "RareT2", iter = { 100000, 100000 } } },
	[7] = { common = { lt = "CommonRanks_7_8", iter = { 0 } }, rare = { lt = "RareT3Mono", iter = { 9,14,14,15,14,14,14,15,25,40,50 } }, epic = { lt = "RareT3", iter = { 100000, 100000 } } },
	[8] = { common = { lt = "CommonRanks_7_8", iter = { 0 } }, rare = { lt = "RareT3Mono", iter = { 10,15,14,15,15,14,15,15,26,40,50 } }, epic = { lt = "NeodiumDrop", iter = { 5,7,10,12,18,24,36,36,36,36 } } },
	[9] = { common = { lt = "CommonRanks_9_10", iter = { 0 } }, rare = { lt = "RareT3Mono", iter = { 11,14,15,14,14,15,14,18,29,40,50 } }, epic = { lt = "RareT3", iter = { 100000, 100000 } } },
	[10] = { common = { lt = "CommonRanks_9_10", iter = { 0 } }, rare = { lt = "RareT4Mono", iter = { 12,18,16,18,16,18,16,18,20,40,50 } }, epic = { lt = "RareT4", iter = { 100000, 100000 } } },
	[11] = { common = { lt = "CommonRanks_11_12", iter = { 0 } }, rare = { lt = "RareT4Mono", iter = { 13,17,17,18,17,18,17,18,20,40,50 } }, epic = { lt = "LezortiumDrop", iter = { 7,8,11,13,15,28,35,37,37,37 } } },
	[12] = { common = { lt = "CommonRanks_11_12", iter = { 0 } }, rare = { lt = "RareT4Mono", iter = { 14,16,18,16,18,17,18,19,20,40,50 } }, epic = { lt = "RareT4", iter = { 100000, 100000 } } },
	[13] = { common = { lt = "CommonRanks_13_15", iter = { 0 } }, rare = { lt = "RareT5Mono", iter = { 12,19,20,21,20,20,21,20,30,40,50 } }, epic = { lt = "RareT5", iter = { 100000, 100000 } } },
	[14] = { common = { lt = "CommonRanks_13_15", iter = { 0 } }, rare = { lt = "RareT5Mono", iter = { 13,20,21,20,20,22,20,23,32,40,50 } }, epic = { lt = "RareT5", iter = { 100000, 100000 } } },
	[15] = { common = { lt = "CommonRanks_13_15", iter = { 0 } }, rare = { lt = "RareT5Mono", iter = { 14,21,20,20,21,20,21,20,35,40,50 } }, epic = { lt = "RareT5", iter = { 100000, 100000 } } },
	}
	)

	-- список запрещенного оборудования (кораблей и модулей) в лигах; раскомментируйте и заполните, если нужен
	--DedicatedServerServices_SetupLeagueForbiddenEquipment( leagueForbiddenDefs )

	-- список запрещённых дефов для адаптивных пресетов ботов
	_G.DedicatedServerServices_SetupBotPresetForbidden( botPresetForbiddenDefs )

	-- Кикать ли игроков из боя, если ботов стало больше, чем игроков.
	cvars.sv_kickExcessiveBotsEnabled = 1

	-- Количество лучших игроков, чьи корабли сохраняются для адаптивных пресетов; -1 — все игроки и все корабли. (тип: целое число; диапазон: -1..MAX_PLAYERS)
	-- количество сохранения лучших игроков SC-115316
	cvars.sv_numBestPlayerToSave = 2
	-- Минимальная эффективность корабля для сохранения в базу адаптивных пресетов. (тип: целое число)
	-- минимальное количество очков для сохранения пресета корабля лучшего игрока
	cvars.sv_minEfficiencyVesselToSave = 1500
	-- Лимит записей адаптивных пресетов в БД для режима, ранга и роли; 0 очищает базу.
	cvars.sv_numAdaptivePresetsInDB = numAdaptivePresets
	-- Лимит от 0 до 100 на чтение из базы адаптивных пресетов для ранга и роли игрового режима. (тип: целое число; диапазон: 0..100)
	-- сколько уникальных пресетов запрашивает дедик с базы
	cvars.sv_numUniqueAdaptivePresets = 20
	-- Диапазон рангов от 0 до MAX_SHIP_RANK для чтения из базы адаптивных пресетов. (тип: целое число; диапазон: 0..MAX_SHIP_RANK)
	-- разница запрашиваемых рангов пресетов с базы от максимального ранга очереди ( если максимальный ранг 12, то при цваре 3, минимальный ранг будет 9 )
	cvars.sv_rangeRankAdaptivePresets = 3
	
	-- Множитель награды для случая, когда игрок покидал предыдущие игры. (тип: дробное число; диапазон: 0.0f..1.0f)
	-- коэффициент награды. По умолчанию 1(нет штрафа).
	cvars.sv_leaveFineRewardCoef = 0.8
  	-- Максимальное снижение счётчика выходов из боя. (тип: целое число; диапазон: 0..INT_MAX)
  	-- максимальное значение, на которое может уменьшиться счетчик ливов, когда игрок получает штраф(счетчик ливов больше единицы. По умолчанию равен 3. Целое.
  	cvars.sv_leaveCounterMaxDecay = 4
  	-- Снижение leaveCounter, если игрок не получил штраф. (тип: дробное число; диапазон: 0.0f..FLT_MAX)
  	-- значение, на которое уменьшается счетчик, когда игрок не получает штраф(счетчик меньше единицы). По умолчанию 0.1 .
  	cvars.sv_leaveCounterDecayWithoutFine = 0.9
  	-- Добавляет это значение к leaveCounter, если игрок вышел из игры штатно. (тип: дробное число)
  	-- значение, на которое увеличивается счетчик при нормальном выходе из боя(нажал на кнопку "Покинул бой"). По умолчанию 0.5.
  	cvars.sv_normalLeaveCounterAdd = 0
  	-- Добавляет это значение к leaveCounter, если игрок вышел из игры нештатно. (тип: дробное число)
  	-- значение, на которое увеличивается счетчик при ненормальном выходе(упал клиент, пропала сеть). По умолчанию 0.
  	cvars.sv_abnormalLeaveCounterAdd = 0
  
  	-- Добавляет это значение к leaverReputation, если игрок получил leaver-ban. (тип: дробное число; диапазон: 0.0f..100.0f)
  	-- [0, 100], по умолчанию 1. Это значение добавляется к leaverReputation, когда игрок получает бан.
  	cvars.sv_leaverReputationAdd = 1
	-- Минимальное время battle-ban при штрафе за выход, в секундах. (тип: дробное число; диапазон: 0.0f..1800.0f)
	-- [0, 1800], по умолчанию 300. Время, на которое игрок получает бан на вход в бой, в секундах.
	cvars.sv_leaverBanTime = 0
	-- Снижение leaverReputation, если игрок не покидает игру. (тип: дробное число; диапазон: 0.0f..FLT_MAX)
	-- по умолчанию 0.01. На эту величину уменьшается leaverReputation, когда игрок не ливает.
	cvars.sv_leaverReputationDecay = 0.9
end

--
function ConfigureDediServerFlags( queueFlags )

	if queueFlags.newbie ~= nil and queueFlags.newbie then
		-- Переопределяет игровую настройку штрафа времени возрождения за смерть. (тип: дробное число)
		cvars.sv_respawnTimePenalty = 0
	end

	if queueFlags.rank ~= nil then
		-- Боевой ранг матча; передаётся в параметры боя и влияет на ранговые ограничения.
		cvars.sv_mmBattleRank = queueFlags.rank
	end
end


--
function ConfigureZoneInstance()
	-- restart cloud after changing these cvars

	-- Ограничивает FPS этим значением; 0 — ограничение выключено. (тип: дробное число)
	cvars.cl_maxFps = 18
	
	-- Включает AI-логику кораблей. (тип: логический)
	cvars.ship_aiThink					= 1
	-- Логирование combat-событий в файл лога; каждый уровень включает все предыдущие.
	-- 0 - отключено; 1 - убийства/смерти/награды; 2 - +использование модулей, ракет и аур.
	-- 3 - +весь урон; 4 - +коэффициенты параметров геймплейных аур.
	cvars.cl_combatLog					= 0
	-- Коэффициент урона оружия. (тип: дробное число; диапазон: 0.0f..FLT_MAX)
	cvars.sv_shipWeaponDamageCoef		 = 1

	-- Минимальное время respawn event-объекта. (тип: дробное число)
	cvars.sv_eventObjectRespawnTimeMin = 60
	-- Максимальное время respawn event-объекта. (тип: дробное число)
	-- задают диапазон для выбора случайно задержки первого и последующих созданий объекта.
	cvars.sv_eventObjectRespawnTimeMax = 420
	-- Время отключения event-объекта. (тип: строка)
	-- время, после которого ивентовый объект больше не создается.
	cvars.sv_eventObjectEndTime = "2027-01-09T00:00:00Z"

  	-- Включает событие Claws. (тип: логический)
		-- April 1
  	cvars.event_claws 					= 0

	-- Коэффициент конвертации подобранного loot в ресурс клана. (тип: дробное число)
	-- 0.1 курс перевода числа подъемов лута в корпоративный иридиум
	cvars.sv_pickedLootRateToClanResource = 0.1
	-- Время обновления подобранного loot. (тип: дробное число)
	-- интервал отправки иридиума в корпу в секундах.
	cvars.sv_pickedLootUpdateTime 		= 6 * 3600

	-- Отключает проверку формата Lua-данных при конвертации и сохранении в базу. 1 - данные записываются без сверки со схемой; только для не-live сборок.
	--cvars.dbg_disableLuaDataFormatChecking = 1
	
	-- Таймер портала к станции в открытом космосе.
	cvars.sv_spaceStationPortalTimer = 3
	
	-- SC-112454 сид-чипы
	cvars.sv_autogenModulesEnabled 		= 0
	-- Где показывать сид-чипы: 1 - только в игре, 2 - в игре и в ангаре.
	-- 1 — в игре, 2 — в игре и в ангаре. (тип: целое число)
	cvars.sv_dbgAutogenDefs 			= 0
	
	-- Должен ли экземпляр зоны обмениваться данными с сервером скриптов. (тип: логический)
	cvars.sv_enableCommunticationWithSS = 1

	-- Интервалы разницы рангов для масштабирования урона, список через запятую. (тип: строка)
	-- сколько Rplayer - Rmob
	cvars.sv_ranksDiff 		= "-5, -2, 0, 2, 5, 10"
	-- Коэффициенты масштабирования урона в OW по разнице рангов, список через запятую. (тип: строка)
	-- цифры "в диапозонах" предыдущей таблицы
	cvars.sv_ranksDiffCoeff = "-0.5, 0.2, 0.5, 0.6, 0.7, 0.8, 1"

	-- Показывать ли параметры масштабирования. (тип: логический)
	cvars.dbg_logRankDiffScaling = 0

	-- Логировать информацию squad: 1 — spawn, 2 — движение, 3 — бой, 5 — всё. (тип: целое число)
	cvars.ai_logSquads 					= 5
	
	-- Расстояние между игроком и точкой despawn. (тип: дробное число)
	cvars.ai_convoyDefendRadius 		= 300
	-- Время сканирования loot crate в открытом космосе.
	cvars.sv_lootCrateScanTime 			= 1
	-- Максимальная дистанция, на которую AI-отряд может отходить от точки старта при преследовании врага. (тип: дробное число)
	cvars.ai_kiteDistance 				= 5000

  	-- Множитель опыта за первую PvE-победу дня. (тип: дробное число)
	-- x3 FIRST WIN
  	cvars.sv_dailyWinPveExpRewardCf	 	= x3fw
	-- Множитель опыта за первую PvP-победу дня. (тип: дробное число)
	cvars.sv_dailyWinPvpExpRewardCf		= x3fw
  	-- Множитель опыта за первую coop-победу дня. (тип: дробное число)
  	cvars.sv_dailyWinCoopExpRewardCf	= x3fw
    -- Множитель опыта за первую brawl-победу дня. (тип: дробное число)
    cvars.sv_dailyWinBrawlExpRewardCf 	= x3fw

	-- Игрок получает статус агрессора после такого объёма урона по неигровой цели. (тип: дробное число)
	cvars.sv_aggressorMinNPCDamage		= 3000
	-- Максимальное значение таймера флага агрессора. (тип: дробное число)
	cvars.sv_aggressorTimer				= 30

	-- Цена воскрешения игрока в credits.
	cvars.sv_resurrectionCreditsPrice   = 100000

	-- Через это время экземпляр зоны будет закрыт, если в нём нет клиентов, в секундах. (тип: дробное число)
	cvars.sv_instanceLifeTime			= 720
	
	-- Коэффициент награды свободной синергии. (тип: дробное число)
 	-- OW synergy
	cvars.sv_freeSynergyRewardCf					= 0.05
	-- Коэффициент награды свободной синергии для premium-корабля. (тип: дробное число)
	cvars.sv_freeSynergyRewardCfPremiumVessel		= 0.20

	-- Замена mastery корабля для free space, список по рангам через запятую. (тип: строка)
	cvars.sv_freeSpaceExpMastery	= "1.95,1.95,1.95,1.95,1.95,1.95,1.95,2.35,2.575,3.04,3.4,3.64,3.915,4.045,4.1,4.1,4.1,4.1"
    -- Множитель выдаваемого опыта по рангам, список через запятую. (тип: строка)
    cvars.sv_expRate				= "1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"
  	-- Разрешает выдачу опыта кораблю за боевые действия в открытом космосе (Free Space).
  	-- 0 - никому, 1 - только premium-игрокам, 2 - всем игрокам. Дополнительно опыт ограничен рангом зоны и sv_freeSpaceExpCap. (тип: целое число)
  	cvars.sv_freeSpaceExpRewards		= 2

  	-- Выдавать опыт за урон во Free Space. (тип: логический)
	-- Fast Synergy Gain
  	cvars.sv_expForDamageFreeSpace = 0

	-- Def-имя loot crate, который используется системой случайного лута в Free Space.
	-- Указанный def должен быть сущностью типа LootCrate и иметь признак isRare; иначе случайный лут в зоне отключится с ошибкой в логах. (тип: строка)
	cvars.sv_randomLootDef 				= "LootCrate_Craft_paradise_Weapon20"

	-- Время в секундах, через которое игрок кикается за AFK, если он не присылал управляющие ввод или они не менялись.
	-- Большое значение (напр. 3600) фактически отключает AFK-кик. (тип: дробное число)
	cvars.sv_afkCheckDuration			= 3600

	-- Включает событие «Invasion with beacons». (тип: логический)
	-- #57052
	cvars.event_invasionWithBeacons	 	= 0

	-- Шансы выдачи label-меток кораблям по рангам; строка содержит 18 значений.
	cvars.sv_owLabelChances				= "0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"

	-- Особый режим поворота UFO-корабля по оси X.
	-- UFO ship controls
	cvars.ship_ufoRotateX = 1
	
	DedicatedServerServices_SetIterativeLoot({
    [ 'wreck_generic_rock_03_r_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_4_ranks_2_3", dropCounter = 1}, },
    [ 'ruinsdread_emp_rock_captured_e_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_16_ranks_3_4", dropCounter = 1}, },
    [ 'asteroids_wild_rock_02_c_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_28_ranks_4_4", dropCounter = 1}, },
    [ 'wreck_generic_rock_01_u_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_40_ranks_4_5", dropCounter = 1}, },
    [ 'transit_emp_rock_frontier_e_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_52_ranks_5_5", dropCounter = 1}, },
    [ 'shipyard_emp_empty_blackwood_e_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_64_ranks_5_6", dropCounter = 1}, },
    [ 'service_emp_rock_01_u_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_76_ranks_6_6", dropCounter = 1}, },
    [ 'wreck_emp_rock_02_r_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_88_ranks_6_6", dropCounter = 1}, },
    [ 'ruinsbig_emp_rock_wardenhub_e_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_100_ranks_6_7", dropCounter = 1}, },
    [ 'ruinssmall_emp_lava_expedition_r_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_112_ranks_7_7", dropCounter = 1}, },
    [ 'anomalyhot_wild_lava_pandora_l_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_124_ranks_7_7", dropCounter = 1}, },
    [ 'ruinsalien_precursor_stone_devilsjaw_l_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_136_ranks_7_8", dropCounter = 1}, },
    [ 'hub_emp_rock_northstar_l_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_148_ranks_8_8", dropCounter = 1}, },
    [ 'factory_emp_rock_planetwar_l_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_160_ranks_8_8", dropCounter = 1}, },
    [ 'factory_emp_iridium_alpha_l_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_172_ranks_8_8", dropCounter = 1}, },
    [ 'ruinssmall_fed_rock_storage_u_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_184_ranks_8_9", dropCounter = 1}, },
    [ 'miningstation_emp_rock_velorum_l_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_196_ranks_9_9", dropCounter = 1}, },
    [ 'shipyard_fed_rock_waterharvest_e_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_208_ranks_9_9", dropCounter = 1}, },
    [ 'transit_fed_rock_frontier_e_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_220_ranks_9_9", dropCounter = 1}, },
    [ 'asteroids_wild_rock_07_c_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_232_ranks_9_10", dropCounter = 1}, },
    [ 'asteroids_wild_rock_04_c_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_244_ranks_10_10", dropCounter = 1}, },
    [ 'ruinsdread_emp_ice_icebelt_l_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_256_ranks_10_10", dropCounter = 1}, },
    [ 'hangar_fed_rock_colony_e_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_268_ranks_10_11", dropCounter = 1}, },
    [ 'survey_fed_ice_olimp_e_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_280_ranks_11_11", dropCounter = 1}, },
    [ 'miners_fed_rock_01_l_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_292_ranks_11_11", dropCounter = 1}, },
    [ 'ruinssmall_jer_rock_storage_e_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_304_ranks_12_12", dropCounter = 1}, },
    [ 'ruins_jer_rock_station_u_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_316_ranks_12_12", dropCounter = 1}, },
    [ 'hub_jer_rock_terramorph_e_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_328_ranks_12_12", dropCounter = 1}, },
    [ 'asteroids_wild_rock_08_c_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_340_ranks_12_13", dropCounter = 1}, },
    [ 'asteroids_wild_rock_09_c_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_352_ranks_13_13", dropCounter = 1}, },
    [ 'mininggas_jer_rock_01_r_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_364_ranks_13_13", dropCounter = 1}, },
    [ 'survey_jer_rock_pallada_e_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_376_ranks_13_14", dropCounter = 1}, },
    [ 'storage_jer_rock_pallada_e_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_388_ranks_14_14", dropCounter = 1}, },
    [ 'ruinsalien_precursor_iridium_spheres_l_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_400_ranks_14_14", dropCounter = 1}, },
    [ 'ruinsalien_precursor_rock_lavastone_l_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_412_ranks_14_15", dropCounter = 1}, },
    [ 'ruinsalien_precursor_rock_barrier_r_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_424_ranks_15_15", dropCounter = 1}, },
    [ 'ruinsalien_precursor_rock_tower_r_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_436_ranks_15_15", dropCounter = 1}, },
    [ 'ruinsalien_crystal_empty_temple_l_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_448_ranks_15_15", dropCounter = 1}, },
    [ 'mininghub_jer_rock_frontier_e_ow' ] = { [ 1 ] = { lootCrate = "LootCrate_Loot_460_ranks_15_17", dropCounter = 1}, },
    })

  	-- Коэффициент урона по дружественным фракционным сущностям. (тип: дробное число; диапазон: 0.0f..1.0f)
	 ---SC-113076 пиратский евент
  	-- коэффициент урона дружественным фракциям в ОМ, данный параметр влияет на урон, остальные только на отношение
  	cvars.sv_frendlyFactionDamageCoef			= 0.25
	
	-- Игрок становится врагом фракции после такого объёма урона по неигровой фракционной цели. (тип: дробное число)
	-- значение счётчика урона, после которого фракция становится врагом игроку
	cvars.sv_enemyMinFactionNPCDamage			= 6
	-- Время, на которое у игрока портятся отношения с фракцией после урона по её NPC.
	-- время в секундах, в течение которого фракция будет врагом игроку
	cvars.sv_factionBadRelationshipTime			= 45
	
	-- Максимальная сумма урона для группы отношений с фракцией; не влияет на фактический урон по сущностям. (тип: дробное число)
	-- максимальное значение счётчика урона от игрока
	cvars.sv_enemyMaxFactionNPCDamage			= 100
	-- Максимальный урон в секунду для группы отношений с фракцией; не влияет на фактический урон по сущностям. (тип: дробное число)
	-- ограничение счётчика урона, накапливаемого за одну секунду
	cvars.sv_enemyMaxFactionNPCDamagePerSec		= 1
	-- Скорость снижения накопленного урона по фракционным NPC для расчёта враждебности.
	-- уменьшение счётчика урона за секунду
	cvars.sv_factionNPCDamageDecay				= 0.2

	-- Путь для сохранения replay dedicated-сервера. (тип: строка)
	cvars.sv_autorecordReplaysTo = ""
end


--
function ConfigureGRD()
	-- Если задано, добавляет bonus gold победителям боя. (тип: целое число)
	cvars.reward_bonusGoldForWinner		= 0
	-- Если задано, добавляет bonus gold проигравшим боя. (тип: целое число)
	cvars.reward_bonusGoldForLooser		= 0

	-- Период события «gold за первую и пятую победу» в формате 2013-04-12T12:00:00Z;2013-04-13T12:00:00Z. (тип: строка)
	-- event 'gold for first and fifth win'
	cvars.reward_eventGoldTimePeriod = "2025-09-02T12:00:00Z;2025-09-11T06:00:00Z"
	-- Размер награды события «gold за первую и пятую победу» в формате 500;0;0;0;5000. (тип: строка)
	cvars.reward_eventGoldTimeValue	= "0;0;0;0;50;0;0;0;0;100;0;0;0;0;150;0;0;0;0;200"

	-- Включает планировщик. (тип: целое число)
	cvars.cron_enabled					= 1

	-- Время начала события с кредитами. (тип: строка)
	cvars.store_creditsEventStart		= creditsEventStart
	-- Время окончания события с кредитами. (тип: строка)
	cvars.store_creditsEventEnd			= creditsEventEnd
  
	-- Дневной лимит token credits, которые игрок может заработать за день.
	cvars.sv_tokenCreditsDailyLimit = 1000
  
	-- Максимальное значение leaveCounter. (тип: дробное число; диапазон: 0.0f..FLT_MAX)
    -- SC-113769
	cvars.reward_leaveCounterMax = 12
end


--
function ConfigureLoadBalancer()
	-- Включение запрещает доступ к серверу. (тип: целое число)
	cvars.lb_disallowAccess				= 0

	-- Максимальное количество игроков на каждый shard. (тип: целое число)
	cvars.lb_limitPlayersOnShardTo		= 800

	-- Среднее время постановки в очередь не опускается ниже этого значения. (тип: дробное число)
	cvars.lb_avgTimeMinClamp			= 10
	-- При расчёте среднего времени учитывается столько последних игроков в очереди. (тип: целое число)
	cvars.lb_avgTimeAveragingCf			= 10

	-- Параметр балансировщика нагрузки: ограничивает задержки и длину очерей на shard.
	cvars.lb_minNextPlayerDelay			= 0.05
	-- Параметр балансировщика нагрузки: ограничивает задержки и длину очерей на shard.
	cvars.lb_maxTaskQLenOnShard			= 500
  
    -- x3 FIRST WIN
  	LoadBalancer_SetGreetingMessageCVars( { sv_dailyWinPveExpRewardCf = x3fw, sv_dailyWinPvpExpRewardCf = x3fw, sv_dailyWinCoopExpRewardCf = x3fw,
		sv_dailyWinBrawlExpRewardCf = x3fw, mss_playerBoughtVesselAdLoBrace = -4, mss_playerBoughtVesselAdHiBrace = 4, mss_playerBoughtVesselAdCooldown = 20,
		cl_showBiomorphsKilledCounter = 0, clan_shipPartsCanBuild = 4, clan_shipUpgradeCanBuild = 3, clan_shipBuildHighRanks  = 3, event_claws = 0,
		event_halloween = 0, } )
end


--
function ConfigureChatServer()
	-- Длительность бана нарушителя. (тип: целое число)
	cvars.antispam_autobanSec					= 60

	-- Порог показателя awareness, при превышении которого игрок автоматически банится в чате.
	-- Awareness - накопительный показатель уровня спама: растёт, если игрок пишет часто и повторяется, и постепенно снижается со временем при перерывах. (тип: целое число)
	cvars.antispam_autobanAwareness				= 500

	-- Порог awareness для уведомления пользователя о прекращении спама. (тип: целое число)
	cvars.antispam_notifyAwareness				= 450

	-- Включает отправку расширенного уведомления. (тип: целое число)
	cvars.antispam_notifyExtended				= 0

	-- Уменьшается на это значение в секунду. (тип: дробное число)
	cvars.antispam_awarenessDecay				= 10

	-- Числитель A в формуле прироста awareness по частоте сообщений: прирост = A / dt.
	-- dt - время в секундах с прошлого сообщения (минимум 0.5 сек); большее A - быстрее растёт awareness при частых сообщениях. (тип: дробное число)
	cvars.antispam_awarenessIntervalNumerator	= 40

	-- Коэффициент K в формуле прироста awareness по похожести сообщений: прирост = K * similarity ^ P. (тип: дробное число)
	-- Прирост начисляется при каждом новом сообщении.
	-- similarity - доля текста текущего сообщения, совпадающая с предыдущими: сумма длин совпадающих подстрок
	-- (длиннее 2 символов) из предыдущих сообщений, делённая на длину текущего сообщения.
	cvars.antispam_awarenessSimilarityMul		= 1
	-- Степень P в формуле прироста awareness по похожести сообщений: прирост = K * similarity ^ P. (тип: дробное число)
	cvars.antispam_awarenessSimilarityPow		= 1

    -- Длительность бана нарушителя. (тип: целое число)
	-- Trade Chat
    cvars.antispam_trade_autobanSec	= 60
    -- Awareness - накопительный показатель уровня спама: растёт, если игрок пишет часто и повторяется, и постепенно снижается со временем при перерывах.
    -- Тот же порог автобана, но для trade-канала. (тип: целое число)
    cvars.antispam_trade_autobanAwareness	= 200
    -- Порог awareness для уведомления пользователя о прекращении спама. (тип: целое число)
    cvars.antispam_trade_notifyAwareness	= 150
    -- Включает отправку расширенного уведомления. (тип: целое число)
    cvars.antispam_trade_notifyExtended	= 0
    -- Уменьшается на это значение в секунду. (тип: дробное число)
    cvars.antispam_trade_awarenessDecay	= 10
    -- Числитель A в формуле прироста awareness: прирост = A / dt (dt в секундах, мин 0.5).
    -- Большее A - быстрее растёт awareness при частых сообщениях; тот же параметр, что и antispam_awarenessIntervalNumerator. (тип: дробное число)
    cvars.antispam_trade_awarenessIntervalNumerator	= 100
    -- Коэффициент K в формуле прироста awareness по похожести сообщений: прирост = K * similarity ^ P.
    -- Тот же параметр, что и antispam_awarenessSimilarityMul, но для trade chat. (тип: дробное число)
    cvars.antispam_trade_awarenessSimilarityMul	= 1
    -- Степень P в формуле прироста awareness по похожести сообщений: прирост = K * similarity ^ P.
    -- Тот же параметр, что и antispam_awarenessSimilarityPow, но для trade chat. (тип: дробное число)
    cvars.antispam_trade_awarenessSimilarityPow	= 1
end


--
function ConfigureUniverse()

	-- Идентификатор используемой Universe. (тип: целое число; диапазон: 1..65535)
	cvars.universe_unid = 2
  	-- Время начала новогоднего события. (тип: строка)
  	-- NY2016 params
  	cvars.universe_newYearStartTime	= "2018-12-17T00:00:00Z"
  	-- Скорость роста счётчика убийств Empire. (тип: дробное число)
  	cvars.universe_empireKillsCF		= 0
  	-- Скорость роста счётчика убийств Federation. (тип: дробное число)
  	cvars.universe_federationKillsCF	= 0
  	-- Скорость роста счётчика убийств Jericho. (тип: дробное число)
  	cvars.universe_jerichoKillsCF		= 0
	-- Доля награды зоны, которая достаётся текущему владельцу; оставшаяся доля распределяется между соперниками. (тип: дробное число 0..1)
	cvars.universe_factorOwnerInReward = 0.4
  	-- Доля накопленного влияния владельца зоны, которая списывается в начале конфликта. (тип: дробное число 0..1)
  	cvars.universe_decayOwner = 0.25
	-- Доля накопленного влияния соперников, которая списывается в начале конфликта. (тип: дробное число 0..1)
	cvars.universe_decayRival = 0.1
	-- Коэффициент A в формуле штрафа владельца по итогам конфликта: вклад соперника = влияние / (A * место + B), место считается с 0. (тип: дробное число)
	-- 1/3, 1/5, 1/7...
	cvars.universe_takeOwnerCoeffA = 2
	-- Коэффициент B в формуле штрафа владельца по итогам конфликта: вклад соперника = влияние / (A * место + B), место считается с 0. (тип: дробное число)
	cvars.universe_takeOwnerCoeffB = 3
	-- Доля накопленного влияния, которая списывается после конфликта без нового влияния за время конфликта. (тип: дробное число 0..1)
	-- SC-111290
	cvars.universe_decayIdle  = 0.5

	-- Параметры глобальной войны: настраивают формулы начисления военного опыта и урона корпорации.
	-- Базовая формула события: raw = множитель_убийства * множитель_цели; затем raw переводится в опыт и урон отдельными коэффициентами.
  	-- Множитель для участников, которые помогли убить цель, но не нанесли финальный удар. Финальный убийца получает множитель 1. (тип: дробное число 0..1)
	cvars.war_coeffAssist				 = 0.2
	-- Коэффициент A для цели-врага в формуле множителя цели: множитель = A * ранг_жертвы + B. (тип: дробное число)
	cvars.war_coeffRivalA				 = 1
	-- Коэффициент B для цели-врага в формуле множителя цели: множитель = A * ранг_жертвы + B. (тип: дробное число)
	cvars.war_coeffRivalB				 = 2
	-- Множитель цели, если жертва не состоит в войне с корпорацией атакующего. (тип: дробное число)
	cvars.war_coeffNeutral				 = 0.1
	-- Множитель цели для bot-заменителя вместо реального игрока. (тип: дробное число)
	cvars.war_coeffBot					 = 0.05
	-- Коэффициент пересчёта raw-очков события в прогресс военного звания игрока. (тип: дробное число)
	cvars.war_damageRawRateToMilitaryExp = 10
	-- Коэффициент пересчёта raw-очков события в урон корпорации на глобальной карте. (тип: дробное число)
	cvars.war_damageRawRateToDamage		 = 100
  	-- Доля периодического уменьшения базовой стоимости войны; применяется как множитель 1 - значение. (тип: дробное число 0..1)
  	cvars.war_decayCostBase				 = 0.1
	
	-- Разрешает внешнему сервису управлять логикой зон: при отключённой логике зоны сервер сам не запускает/завершает конфликты и не принимает вклад. (тип: булево значение)
	-- SC-112644
	cvars.universe_allowExternalControl  = 1

	-- Доля бонуса к влиянию клана в зоне, если раса клана совпадает с доминирующей расой звёздной системы; множитель = 1 + значение. (тип: дробное число 0..1)
	cvars.universe_raceFactorStellar	= 0.1
	-- Доля бонуса к влиянию клана в зоне, если раса клана совпадает с расой самой зоны; множитель = 1 + значение. (тип: дробное число 0..1)
	cvars.universe_raceFactorZone		= 0.1

end


--
function ConfigureQuestServer()

	-- Включает/выключает квесты. (тип: логический)
	cvars.quests_enable				= 1
  	-- Время начала новогоднего события. (тип: строка)
  	cvars.event_newYear				= "2026-10-09T00:00:00Z"
  	-- Максимальное число UID для загрузки в операции чтения БД. (тип: целое число; диапазон: 1..1024)
  	cvars.quests_readWaveMaxUids 	= 100
    -- Битовая маска логирования debug-сообщений квестов: сложением значений включаются нужные категории.
    -- 1 - кэширование; 2 - доступность квестов; 4 - состояние пользователя; 8 - выбор квестов; 16 - прогресс квестов. 31 - все категории. (тип: целое число)
    cvars.quests_dbgLog				= 31
  	-- Включает летнее событие. (тип: целое число)
  	cvars.event_summer 				= 1
  	-- Включает летнее событие с кораблём. (тип: целое число)
  	cvars.event_summerShip 			= 1
  	-- Включает событие Halloween. (тип: целое число)
  	cvars.event_halloween	 		= 1

  	-- Время начала кастомного события. (тип: строка)
  	-- Необходимо изменять время начала и конца кратно часу, иначе квест imaginary может вести себя непредсказуемо.
  	cvars.event_custom 					= event_custom

	-- Коэффициенты формулы убывающего вознаграждения за imaginary-квесты:
	-- количество = floor((A - 1) * (1 - tanh(B * (прохождений - 1))) + 1), где «прохождения» - сколько раз игрок уже выполнил этот квест.
  	-- Коэффициент A: начальная величина награды при первом прохождении; с ростом числа прохождений награда убывает до 1. (SC-109926; тип: дробное число)
	cvars.quests_imaginaryRewardCoeffA = 25
	-- Коэффициент B: скорость убывания награды с ростом числа прохождений; большее B - быстрее падает награда. (SC-109926; тип: дробное число)
	cvars.quests_imaginaryRewardCoeffB = 0.17

  	-- Время начала события с кредитами. (тип: строка)
  	cvars.store_creditsEventStart 	= creditsEventStart
	-- Время окончания события с кредитами. (тип: строка)
	cvars.store_creditsEventEnd 	= creditsEventEnd

	_G.QuestServer_SetupBattlePassActivation( battlePassStart, battlePassEndTable )

end


--
function ConfigureAchievementServer()

	-- Включает серверную обработку достижений.
	cvars.achievements_enable	= 1
  	-- Максимальное число UID для загрузки в операции чтения БД. (тип: целое число; диапазон: 1..256)
  	cvars.achievements_readWaveMaxUids	= 100
	-- Уровень/флаг отладочного логирования. (тип: логический)
	-- дополнительное логирование
	cvars.achievements_dbgLogEnable = 0

end


--
function ConfigureLobbyServer()

	-- Включает сервер пользовательских игр.
	cvars.lobby_enabled			= 1
	-- Награды за пользовательские игры умножаются на это значение. (тип: дробное число)
	cvars.lobby_rewardRates		= 1
  	-- Минимум/максимум игроков для запуска PvE-lobby.
  	cvars.lobby_reqPlayersPvEMin = 3
	-- Минимум/максимум игроков для запуска PvE-lobby.
	cvars.lobby_reqPlayersPvEMax = 4
    -- Лимит одинаковых unique-модулей на один корабль; отдельно задаётся для обычных и premium-кораблей.
    -- #85547
    cvars.store_maxUniqueModules = 3
  	-- Лимит одинаковых unique-модулей на один корабль; отдельно задаётся для обычных и premium-кораблей.
  	-- #0098493: Сделать возможнсть установки экспериментальных модулей на прем. и ДЛЦ корабли в кол-ве 1 шт
  	cvars.store_maxUniqueModulesOnPremium = 2
	
	-- список запрещенного оборудования (кораблей и модулей) в лигах
	Lobby_SetupLeagueForbiddenEquipment( leagueForbiddenDefs )
	
end

--
function ConfigureLeaderboardServer()

	local LET_PLAYER		= 0
	local LET_CLAN			= 1
	local LET_CLAN_MEMBER	= 2
	local LET_RACE			= 3

	local LEA_RESET			= 0
	local LEA_DELETE		= 1
	local LEA_NOOP			= 2

	local LRT_CREDITS		= 0
	local LRT_LB_EVENT		= 1

	local LUT_INCREMENT			= 0
	local LUT_SET				= 1
	local LUT_SET_IF_GREATER	= 2
	local LUT_SET_IF_LESSER		= 3

	local LET_LEAGUE_TEAM	= 4

	local nov_28_2013		= "1385596800000"
	local feb_18_2016		= "1455753600000"

	local oneWeek			= 60 * 24 * 7
	local threeMonths		= 60 * 24 * 90


	local lbrds = {}
	local routes = {}

    -- REWARDS
    -- local goldCreditsForTop100	= { params = { stringId = "UWinBro", goldCredits = 1000 }, type = LRT_CREDITS, posFilter = 100 }
    -- local clanEffTopEvent = { params = { event = "clan_weekly_top", v = 1 }, type = LRT_LB_EVENT, posFilter = 10 }

    -- ЛИДЕРБОРДЫ ИГРОКОВ ПЕРМАНЕНТНЫЕ
    -- Престиж игрока
    table.insert( lbrds, { name = "player_prestige", entityType = LET_PLAYER } )
    table.insert( routes, { event = "prestige", target = "player_prestige", update = LUT_SET } )
    -- Суммарная пвп эффективность игрока +
    table.insert( lbrds, { name = "player_pvp_effectiveness", entityType = LET_PLAYER, decayInterval = 60 * 24, decayPower = 0.1 } )
    table.insert( routes, { event = "pvp_eff", target = "player_pvp_effectiveness", update = LUT_INCREMENT } )
    -- Суммарная пве эффективность игрока +
    table.insert( lbrds, { name = "player_pve_effectiveness", entityType = LET_PLAYER, decayInterval = 60 * 24, decayPower = 0.1 } )
    table.insert( routes, { event = "pve_eff", target = "player_pve_effectiveness", update = LUT_INCREMENT } )
    -- Суммарное количество вылетов
    table.insert( lbrds, { name = "player_battles", entityType = LET_PLAYER } )
    table.insert( routes, { event = "gover", target = "player_battles" } )
    -- Суммарное количество побед
    table.insert( lbrds, { name = "player_wins", entityType = LET_PLAYER } )
    table.insert( routes, { event = "gwin", target = "player_wins" })
    -- Суммарное количество убийств
    table.insert( lbrds, { name = "player_kills", entityType = LET_PLAYER } )
    table.insert( routes, { event = "kills", target = "player_kills" } )
    -- Количество положительной кармы в открытом мире
    table.insert( lbrds, { name = "player_karma_good", entityType = LET_PLAYER } )
    table.insert( routes, { event = "karma", target = "player_karma_good", update = LUT_SET } )
    -- Количество отрицательной кармы в открытом мире
    table.insert( lbrds, { name = "player_karma_bad", entityType = LET_PLAYER, dir = 1 } )
    table.insert( routes, { event = "karma", target = "player_karma_bad", update = LUT_SET } )
    -- Суммарное количество голов в футболе
    table.insert( lbrds, { name = "player_goals", entityType = LET_PLAYER } )
    table.insert( routes, { event = "goals", target = "player_goals", update = LUT_INCREMENT } )
    -- Суммарное количество убийство в голодных играх
    table.insert( lbrds, { name = "player_hunger", entityType = LET_PLAYER } )
    table.insert( routes, { event = "hunger_games_kills", target = "player_hunger", update = LUT_INCREMENT } )
    -- Суммарное количество очков влияния заработанное игроком
    table.insert( lbrds, { name = "player_pressure", entityType = LET_PLAYER } )
    table.insert( routes, { event = "pressure", target = "player_pressure", update = LUT_INCREMENT } )
    -- Скорость прохождения рейда (time_название_миссии)
    table.insert( lbrds, { name = "player_time_pve_raid", entityType = LET_PLAYER, dir = 1 } )
    table.insert( routes, { event = "time_pve_raid", target = "player_time_pve_raid", update = LUT_SET_IF_LESSER } )
    table.insert( lbrds, { name = "player_time_pve_raid_waterharvest_t3", entityType = LET_PLAYER, dir = 1 } )
    table.insert( routes, { event = "time_pve_raid_waterharvest_t3", target = "player_time_pve_raid_waterharvest_t3", update = LUT_SET_IF_LESSER } )
    table.insert( lbrds, { name = "player_time_pve_raid_waterharvest_t4", entityType = LET_PLAYER, dir = 1 } )
    table.insert( routes, { event = "time_pve_raid_waterharvest_t4", target = "player_time_pve_raid_waterharvest_t4", update = LUT_SET_IF_LESSER } )
    table.insert( lbrds, { name = "player_time_pve_raid_waterharvest_t5", entityType = LET_PLAYER, dir = 1 } )
    table.insert( routes, { event = "time_pve_raid_waterharvest_t5", target = "player_time_pve_raid_waterharvest_t5", update = LUT_SET_IF_LESSER } )
    table.insert( lbrds, { name = "player_time_pve_planetoidraid", entityType = LET_PLAYER, dir = 1 } )
    table.insert( routes, { event = "time_pve_planetoidraid", target = "player_time_pve_planetoidraid", update = LUT_SET_IF_LESSER } )
    -- Прохождения анлимных миссий
    -- table.insert( lbrds, { name = "unlim_pve_time_planet_war_waves_T1_25", expiresAt = "1553472000000", expAction = LEA_NOOP, entityType = LET_PLAYER, dir = 1 } ) -- expires Monday, 25 March 2019 г., 0:00:00 GMT
    -- table.insert( routes, { event = "unlim_pve_time_planet_war_waves_T1_25", target = "unlim_pve_time_planet_war_waves_T1_25", update = LUT_SET_IF_LESSER } )
    table.insert( lbrds, { name = "unlim_pve_level_planet_war_waves_T1", entityType = LET_PLAYER } )
    table.insert( routes, { event = "unlim_pve_level_planet_war_waves_T1", target = "unlim_pve_level_planet_war_waves_T1", update = LUT_SET_IF_GREATER } )
    -- Clan wars: militaryRank
    -- table.insert( lbrds, { name = "player_militaryRank", entityType = LET_PLAYER } )
    -- table.insert( routes, { event = "militaryRank", target = "player_militaryRank", update = LUT_SET } )
    -- Clan wars: урон
    -- table.insert( lbrds, { name = "player_warDamage", entityType = LET_PLAYER } )
    -- table.insert( routes, { event = "warDamage", target = "player_warDamage", update = LUT_INCREMENT } )
    -- Количество убийств за битву +
    -- table.insert( lbrds, { name = "player_kills_per_battle", entityType = LET_PLAYER } )
    -- table.insert( routes, { event = "kills", target = "player_kills_per_battle", update = LUT_SET_IF_GREATER } )
    -- Количество ачивпойнтов
    -- table.insert( lbrds, { name = "player_achievements", entityType = LET_PLAYER } )
    -- table.insert( routes, { event = "achievements", target = "player_achievements", update = LUT_SET } )
    -- Рейтинг убийств
    -- table.insert( lbrds, { name = "player_akari_r", entityType = LET_PLAYER } )
    -- table.insert( routes, { event = "akari_r", target = "player_akari_r", update = LUT_SET } )
	-- Достигнутая волна в волновом пве
	table.insert( lbrds, { name = "player_wavePve_wave", entityType = LET_PLAYER } )
	table.insert( routes, { event = "player_wavePve_wave", target = "player_wavePve_wave", update = LUT_SET_IF_GREATER } )

    -- ЛИДЕРБОРДЫ ИГРОКОВ В НЕДЕЛЮ с наградой
    -- Суммарное количество убийств в неделю
    local r_player_kills_1	= { params = { stringId = "LeaderboardTop1", tokenCredits = 400 }, type = LRT_CREDITS, posMin = 1, posMax = 1 }
    local r_player_kills_2	= { params = { stringId = "LeaderboardTop2", tokenCredits = 200 }, type = LRT_CREDITS, posMin = 2, posMax = 2 }
    local r_player_kills_3	= { params = { stringId = "LeaderboardTop3", tokenCredits = 100 }, type = LRT_CREDITS, posMin = 3, posMax = 3 }
    table.insert( lbrds, { name = "player_kills_weekly", entityType = LET_PLAYER , expiresAt = nov_28_2013, renewalInterval = oneWeek, rewards = { r_player_kills_1, r_player_kills_2, r_player_kills_3 } } )
    table.insert( routes, { event = "kills_ht", target = "player_kills_weekly", update = LUT_INCREMENT } )
    -- Максимальная пвп эффективность игрока в неделю
    local r_player_pvp_eff_max_1	= { params = { stringId = "LeaderboardTop1", tokenCredits = 400 }, type = LRT_CREDITS, posMin = 1, posMax = 1 }
    local r_player_pvp_eff_max_2	= { params = { stringId = "LeaderboardTop2", tokenCredits = 200 }, type = LRT_CREDITS, posMin = 2, posMax = 2 }
    local r_player_pvp_eff_max_3	= { params = { stringId = "LeaderboardTop3", tokenCredits = 100 }, type = LRT_CREDITS, posMin = 3, posMax = 3 }
    table.insert( lbrds, { name = "player_pvp_eff_max_weekly", entityType = LET_PLAYER , expiresAt = nov_28_2013, renewalInterval = oneWeek, rewards = { r_player_pvp_eff_max_1, r_player_pvp_eff_max_2, r_player_pvp_eff_max_3 } } )
    table.insert( routes, { event = "pvp_eff_ht", target = "player_pvp_eff_max_weekly", update = LUT_SET_IF_GREATER } )
    -- Максимальная пве эффективность игрока в неделю
    local r_player_pve_eff_max_1	= { params = { stringId = "LeaderboardTop1", tokenCredits = 400 }, type = LRT_CREDITS, posMin = 1, posMax = 1 }
    local r_player_pve_eff_max_2	= { params = { stringId = "LeaderboardTop2", tokenCredits = 200 }, type = LRT_CREDITS, posMin = 2, posMax = 2 }
    local r_player_pve_eff_max_3	= { params = { stringId = "LeaderboardTop3", tokenCredits = 100 }, type = LRT_CREDITS, posMin = 3, posMax = 3 }
    table.insert( lbrds, { name = "player_pve_eff_max_weekly", entityType = LET_PLAYER , expiresAt = nov_28_2013, renewalInterval = oneWeek, rewards = { r_player_pve_eff_max_1, r_player_pve_eff_max_2, r_player_pve_eff_max_3 } } )
    table.insert( routes, { event = "pve_eff", target = "player_pve_eff_max_weekly", update = LUT_SET_IF_GREATER } )
    -- Количество прохождений PvE в неделю
    local r_player_pve_win_1	= { params = { stringId = "LeaderboardTop1", tokenCredits = 400 }, type = LRT_CREDITS, posMin = 1, posMax = 1 }
    local r_player_pve_win_2	= { params = { stringId = "LeaderboardTop2", tokenCredits = 200 }, type = LRT_CREDITS, posMin = 2, posMax = 2 }
    local r_player_pve_win_3	= { params = { stringId = "LeaderboardTop3", tokenCredits = 100 }, type = LRT_CREDITS, posMin = 3, posMax = 3 }
    table.insert( lbrds, { name = "player_pve_win_weekly", entityType = LET_PLAYER , expiresAt = nov_28_2013, renewalInterval = oneWeek, rewards = { r_player_pve_win_1, r_player_pve_win_2, r_player_pve_win_3 } } )
    table.insert( routes, { event = "pvegwin", target = "player_pve_win_weekly", update = LUT_INCREMENT } )
    -- Новый рейтинг игроков за неделю
    local r_player_eff_win_1	= { params = { stringId = "LeaderboardTop1eff", tid = 31 }, type = LRT_CREDITS, posMin = 1, posMax = 3 }
    local r_player_eff_win_2	= { params = { stringId = "LeaderboardTop2eff", tid = 32 }, type = LRT_CREDITS, posMin = 4, posMax = 20 }
    local r_player_eff_win_3	= { params = { stringId = "LeaderboardTop3eff", tid = 33 }, type = LRT_CREDITS, posMin = 21, posMax = 50 }
    table.insert( lbrds, { name = "player_eff_rating_weekly", entityType = LET_PLAYER , expiresAt = nov_28_2013, renewalInterval = oneWeek, rewards = { r_player_eff_win_1, r_player_eff_win_2, r_player_eff_win_3 } } )
    table.insert( routes, { event = "eff_rating", target = "player_eff_rating_weekly", update = LUT_SET } )

    -- ЛИДЕРБОРДЫ ИГРОКОВ КЛАНОВ
    -- Суммарная пвп эффективность игрока в клане
    table.insert( lbrds, { name = "cm_pvp_effectiveness", entityType = LET_CLAN_MEMBER, decayInterval = 60 * 24, decayPower = 0.1 } )
    table.insert( routes, { event = "pvp_eff", target = "cm_pvp_effectiveness", update = LUT_INCREMENT } )
    -- Суммарная пве эффективность игрока в клане
    table.insert( lbrds, { name = "cm_pve_effectiveness", entityType = LET_CLAN_MEMBER, decayInterval = 60 * 24, decayPower = 0.1 } )
    table.insert( routes, { event = "pve_eff", target = "cm_pve_effectiveness", update = LUT_INCREMENT } )
    -- Суммарное количество очков влияния заработанное членом клана
    table.insert( lbrds, { name = "cm_pressure", entityType = LET_CLAN_MEMBER } )
    table.insert( routes, { event = "pressure", target = "cm_pressure", update = LUT_INCREMENT } )
    -- Clan wars: militaryRank
    table.insert( lbrds, { name = "cm_military_rank", entityType = LET_CLAN_MEMBER } )
    table.insert( routes, { event = "militaryRank", target = "cm_military_rank", update = LUT_SET } )
    -- Clan wars: урон
    table.insert( lbrds, { name = "cm_war_damage", entityType = LET_CLAN_MEMBER } )
    table.insert( routes, { event = "warDamage", target = "cm_war_damage", update = LUT_INCREMENT } )
    -- Clan wars: потери
    table.insert( lbrds, { name = "cm_war_losses", entityType = LET_CLAN_MEMBER } )
    table.insert( routes, { event = "warLosses", target = "cm_war_losses", update = LUT_INCREMENT } )
    -- Количество ачивпойнтов
    -- table.insert( lbrds, { name = "cm_achievements", entityType = LET_CLAN_MEMBER } )
    -- table.insert( routes, { event = "achievements", target = "cm_achievements", update = LUT_SET } )

    -- ЛИДЕРБОРДЫ КЛАНОВ
    -- Суммарное количество очков клана заработанных в пвп уменьшающаяся на 1% каждый час
    table.insert( lbrds, { name = "CLS_PVP_RATING", entityType = LET_CLAN, decayInterval = 60, decayPower = 0.01 } )
    table.insert( routes, { event = "pvp_b", target = "CLS_PVP_RATING", update = LUT_INCREMENT } )
    -- Суммарная пве эффективность клана уменьшающаяся на 1% каждый час
    table.insert( lbrds, { name = "CLS_PVE_RATING", entityType = LET_CLAN, decayInterval = 60, decayPower = 0.01 } )
    table.insert( routes, { event = "pve_eff", target = "CLS_PVE_RATING", update = LUT_INCREMENT } )
    -- Clan wars: урон
    table.insert( lbrds, { name = "CLS_WAR_DAMAGE", entityType = LET_CLAN } )
    table.insert( routes, { event = "warDamage", target = "CLS_WAR_DAMAGE", update = LUT_INCREMENT } )
    -- Суммарное количество захватов локаций
    table.insert( lbrds, { name = "CLS_ZONE_CAPTURE", entityType = LET_CLAN } )
    table.insert( routes, { event = "zoneCapture", target = "CLS_ZONE_CAPTURE", update = LUT_INCREMENT } )
    -- Clan wars: текущей рейтинг
    table.insert( lbrds, { name = "CLS_WAR_RATING", entityType = LET_CLAN } )
    table.insert( routes, { event = "warRating", target = "CLS_WAR_RATING", update = LUT_SET } )
    -- Clan wars: максимальный достигнутый рейтинг
    table.insert( lbrds, { name = "CLS_WAR_RATING_MAX", entityType = LET_CLAN } )
    table.insert( routes, { event = "warRating", target = "CLS_WAR_RATING_MAX", update = LUT_SET_IF_GREATER } )
    -- Суммарное количество очков влияния заработанное кланом
    -- table.insert( lbrds, { name = "CLS_PRESSURE", entityType = LET_CLAN } )
    -- table.insert( routes, { event = "pressure", target = "CLS_PRESSURE", update = LUT_INCREMENT } )
    -- ELO рейтинг корпорации
    -- table.insert( lbrds, { name = "CLS_ELO", entityType = LET_CLAN } )
    -- table.insert( routes, { event = "unWElo", target = "CLS_ELO", update = LUT_SET } )
    -- АРЕНЫ
    -- table.insert( lbrds, { name = "league_rating", entityType = LET_LEAGUE_TEAM } )
    -- table.insert( routes, { event = "league_rating", target = "league_rating", update = LUT_SET } )
    -- Суммарное количество ирридиума когда либо сданное в корпорацию
    -- table.insert( lbrds, { name = "CLS_IRIDIUM", entityType = LET_CLAN } )
    -- table.insert( routes, { event = "cbt_iridium", target = "CLS_IRIDIUM", update = LUT_INCREMENT } )
    -- Суммарное количество очков влияния когда либо полученное кланом
    -- table.insert( lbrds, { name = "CLS_INFLUENCE", entityType = LET_CLAN } )
    -- table.insert( routes, { event = "clanInf", target = "CLS_INFLUENCE", update = LUT_INCREMENT } )
    -- Суммарное количество секторов когда либо контролируемое кланом
    -- table.insert( lbrds, { name = "CLS_GALAXIES", entityType = LET_CLAN } )
    -- table.insert( routes, { event = "gal_cap", target = "CLS_GALAXIES", update = LUT_INCREMENT } )
    -- Количество людей в клане
    -- table.insert( lbrds, { name = "CLS_MEMBERS", entityType = LET_CLAN } )
    -- table.insert( routes, { event = "cSize", target = "CLS_MEMBERS", update = LUT_SET } )

    --local r_leagues_8top_1 = { params = { stringId = "LeaderboardTopLgs1", tid = 201 }, type = LRT_CREDITS, posMin = 1, posMax = 8 }
    --table.insert( lbrds, { name = "league_rating", entityType = LET_LEAGUE_TEAM, expiresAt = feb_18_2016, expAction = LEA_RESET, renewalInterval = threeMonths, rewards = { r_leagues_8top_1, } } )
    --table.insert( routes, { event = "league_rating", target = "league_rating", update = LUT_SET } )
    --table.insert( lbrds, { name = "major_league_rating", entityType = LET_MAJOR_LEAGUE_TEAM, expiresAt = feb_18_2016, expAction = LEA_RESET, renewalInterval = threeMonths, rewards = { r_leagues_8top_1, } } )
    --table.insert( routes, { event = "major_league_rating", target = "major_league_rating", update = LUT_SET } )

    --[[
    table.insert( lbrds, { name = "player_race_influence:0" })
    table.insert( lbrds, { name = "player_race_influence:1" })
    table.insert( lbrds, { name = "player_race_influence:2" })
    table.insert( lbrds, { name = "race_openspace_points", entityType = LET_RACE })
    table.insert( lbrds, { name = "race_arcade_points", entityType = LET_RACE })
    table.insert( lbrds, { name = "race_universe_points", entityType = LET_RACE })

    table.insert( routes, { event = "ri0", target = "player_race_influence:0" })
    table.insert( routes, { event = "ri1", target = "player_race_influence:1" })
    table.insert( routes, { event = "ri2", target = "player_race_influence:2" })
    table.insert( routes, { event = "osP", target = "race_openspace_points" }) -----
    table.insert( routes, { event = "arP", target = "race_arcade_points" })
    table.insert( routes, { event = "unP", target = "race_universe_points" })
    ]]
	table.insert( lbrds, { name = "event_green_war_empire", entityType = LET_PLAYER } )
	table.insert( routes, { event = "green_war_empire", target = "event_green_war_empire", update = LUT_SET } )
	table.insert( lbrds, { name = "event_green_war_federation", entityType = LET_PLAYER } )
	table.insert( routes, { event = "green_war_federation", target = "event_green_war_federation", update = LUT_SET } )
	table.insert( lbrds, { name = "event_green_war_jericho", entityType = LET_PLAYER } )
	table.insert( routes, { event = "green_war_jericho", target = "event_green_war_jericho", update = LUT_SET } )
	table.insert( lbrds, { name = "event_green_war_total", entityType = LET_PLAYER } )
	table.insert( routes, { event = "green_war_total", target = "event_green_war_total", update = LUT_SET } )
	
	-- ВРЕМЕННЫЕ ЛИДЕРБОРДЫ
    -- Рейтинг апрельской потасовки
	table.insert( lbrds, { name = "player_april_win", entityType = LET_PLAYER } )
    table.insert( routes, { event = "atdmgwin", target = "player_april_win", update = LUT_INCREMENT } )
	
	table.insert( lbrds, { name = "player_cd_win", entityType = LET_PLAYER } )
    table.insert( routes, { event = "close_distance_kills", target = "player_cd_win", update = LUT_INCREMENT } )
	
	local marathon_expires = "1652659200000" -- https://www.epochconverter.com/ Timestamp in milliseconds!!
	
	table.insert( lbrds, { name = "player_kills_marathon", entityType = LET_PLAYER, expiresAt = marathon_expires, expAction = LEA_NOOP } )
    table.insert( routes, { event = "kills", target = "player_kills_marathon", update = LUT_INCREMENT } )

    Leaderboards_Configure( lbrds )
    Leaderboards_Routes( routes )

    -- Включает отладочный дамп каждого входящего события лидерборда в лог. (тип: целое число)
    -- cvars.leaderboard_logEvents = 1
end



function ConfigureZoneCoordinator()

	-- Включает блокировку зон по расписанию raid: ZoneCoordinator передаёт флаг в запускаемые ZoneInstance и в уже работающие инстансы.
	-- Внутри FreeSpace по текущему расписанию выбирается raid-зона, и переходы/джампы в эту зону запрещаются. (тип: целое число)
	cvars.zc_enableZoneBlocks	= 0
	
end


function ConfigureTournament()

	-- Смещение номеров имён турнирных команд в UI: клиент прибавляет это значение к номеру имени и берёт строку single_tournament_name_N.
	-- Позволяет сдвинуть набор отображаемых имён команд без изменения их реальных teamId. (тип: целое число)
	cvars.tournament_idOffset	= 0
    -- Уровни/карты турнира. (тип: строка)
    -- ;s1338_pandora_anomaly глючит
    cvars.tournament_levels 	=  "s1338_devilsjaw;s1338_pandora_dreadnwreck;s1340_thar_aliendebris13;s1420_ceres3_asteroidcity;s1420_ceres3_northmsite;s8256_thar_barrierdebris;s8256_thar_lavastone;s8256_thar_threshold;desttown"
  	-- Боевой ранг турнира; копируется в sv_mmBattleRank. (тип: целое число; диапазон: 0..ai::MAX_SHIP_RANK)
  	cvars.tournament_battleRank = 17
    -- Игровой режим турнира. (тип: целое число; диапазон: ai::GT_SPACE_BATTLE..ai::GT_MISSION_SCRIPT - 1)
    cvars.tournament_gamemode 	= 12
    -- Максимальный размер команды в турнире. (тип: целое число; диапазон: 1..MAX_TOURNAMENT_TEAM_SIZE)
    cvars.tournament_teamSize 	= 8
    -- Интервал между созданием игр в миллисекундах. (тип: целое число; диапазон: 50..10000)
    cvars.tournament_gameInterval	= 2000
	
end


function ConfigureClanServer()

	-- Количество основных частей кланового корабля, доступных для строительства. (тип: целое число)
	-- (0,1,2,3,4) этапы строительства дредноута
	cvars.clan_shipPartsCanBuild 	= 4
	-- Максимальное количество апгрейдов модулей кланового корабля, доступных для строительства. (тип: целое число)
	-- (0,1,2,3) этапы апгрейдов дредноута (Т3,Т4,Т5)
	cvars.clan_shipUpgradeCanBuild	= 3
	-- Количество высокоранговых участников клана, необходимое для строительства кланового корабля. (тип: целое число)
	-- кол-во человек в клане 9 ранга
	cvars.clan_shipBuildHighRanks 	= 3
	-- Минимальное количество ресурса из зоны для записи в историю клана. (тип: целое число)
	-- Если с зоны пришло меньше иррисок - не спамить в лог корпы.
	cvars.clans_historyMinResourceAddByZone = 10
    -- Награда за победу в войне. (тип: строка)
    cvars.clan_warWinRewardAura = 'Bundle_ClanWar_Win'
	
end


function ConfigureAdventureServer()


end


function ConfigureHub()

	RegionWeightProportion = {
		ru = { ru = 0.7, eu = 0.2, us = 0.1 },
		eu = { ru = 0.2, eu = 0.7, us = 0.1 },
		us = { ru = 0.1, eu = 0.2, us = 0.7 },
	}
	
end


-- actual configuring
-- CloudService_GetServiceTypeStr is absent on dedicated server-- 'service_type' is now a global set up before config execution
--local service_type =_G.CloudService_GetServiceTypeStr()
if( service_type == "ST_SHARD" ) then
	ConfigureShard()
elseif( service_type == "ST_MATCHMAKER" ) then
	ConfigureMatchmaker()
elseif( service_type == "ST_SCRIPTS_SERVER" ) then
	ConfigureScriptsServer()
elseif( service_type == "ST_DEDICATED_SERVER" ) then
	ConfigureDediServer()
elseif( service_type == "ST_ZONE_INSTANCE" ) then
	ConfigureZoneInstance()
elseif( service_type == "ST_GAME_REWARD_DISPENCER" ) then
	ConfigureGRD()
elseif( service_type == "ST_LOAD_BALANCER" ) then
	ConfigureLoadBalancer()
elseif( service_type == "ST_CHAT_SERVER" ) then
	ConfigureChatServer()
elseif( service_type == "ST_UNIVERSE" ) then
	ConfigureUniverse()
elseif( service_type == "ST_QUEST_SERVER" ) then
	ConfigureQuestServer()
elseif( service_type == "ST_ACHIEVEMENT_SERVER" ) then
	ConfigureAchievementServer()
elseif( service_type == "ST_LOBBY_SERVER" ) then
	ConfigureLobbyServer()
elseif( service_type == "ST_LEADERBOARD_SERVER" ) then
	ConfigureLeaderboardServer()
elseif( service_type == "ST_ZONE_COORDINATOR" ) then
	ConfigureZoneCoordinator()
elseif( service_type == "ST_TOURNAMENT" ) then
	ConfigureTournament()
elseif( service_type == "ST_CLAN_SERVER" ) then
	ConfigureClanServer()
elseif( service_type == "ST_ADVENTURE_SERVER" ) then
	ConfigureAdventureServer()
elseif( service_type == "ST_HUB" ) then
	ConfigureHub()
--else
--	sys.log( "UNKNOWN _G.service_type" )
end
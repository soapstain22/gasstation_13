/datum/job/chief_engineer
	minimal_player_age = 30
	
/datum/job/engineer
	access = list(ACCESS_ENGINE, ACCESS_ENGINE_EQUIP, ACCESS_TECH_STORAGE, ACCESS_MAINT_TUNNELS,
									ACCESS_EXTERNAL_AIRLOCKS, ACCESS_CONSTRUCTION, ACCESS_ATMOSPHERICS, ACCESS_TCOMSAT, ACCESS_MINERAL_STOREROOM)
	minimal_access = list(ACCESS_ENGINE, ACCESS_ENGINE_EQUIP, ACCESS_TECH_STORAGE, ACCESS_MAINT_TUNNELS,
									ACCESS_EXTERNAL_AIRLOCKS, ACCESS_CONSTRUCTION, ACCESS_TCOMSAT, ACCESS_MINERAL_STOREROOM)

/datum/job/atmos
	access = list(ACCESS_ENGINE, ACCESS_ENGINE_EQUIP, ACCESS_TECH_STORAGE, ACCESS_MAINT_TUNNELS,
		ACCESS_EXTERNAL_AIRLOCKS, ACCESS_CONSTRUCTION, ACCESS_ATMOSPHERICS, ACCESS_MINERAL_STOREROOM)
	minimal_access = list(ACCESS_ATMOSPHERICS, ACCESS_MAINT_TUNNELS, ACCESS_EXTERNAL_AIRLOCKS, ACCESS_ENGINE, 
		ACCESS_ENGINE_EQUIP, ACCESS_EMERGENCY_STORAGE, ACCESS_CONSTRUCTION, ACCESS_MINERAL_STOREROOM)

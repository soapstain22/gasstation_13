
#define PUNISHMENT_MURDER "murder"
#define PUNISHMENT_GIB "gib"
#define PUNISHMENT_TELEPORT "teleport"

//very similar to stationloving, but more made for mobs and not objects. used on derelict drones currently
/datum/component/stationstuck
	dupe_mode = COMPONENT_DUPE_UNIQUE_PASSARGS
	var/punishment = PUNISHMENT_GIB //see defines above
	var/stuck_zlevel
	var/message = ""

/datum/component/stationstuck/Initialize(_punishment = PUNISHMENT_GIB, _message = "")
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	var/mob/living/L = parent
	RegisterSignal(L, list(COMSIG_MOVABLE_Z_CHANGED), .proc/punish)
	punishment = _punishment
	message = _message
	stuck_zlevel = L.z

/datum/component/stationstuck/InheritComponent(datum/component/stationstuck/newc, original, _punishment, _message)
	if(newc)
		punishment = newc.punishment
		message = newc.message
	else
		punishment = _punishment
		message = _message

/datum/component/stationstuck/proc/punish()
	var/mob/living/L = parent
	if(message)
		var/span = punishment == PUNISHMENT_TELEPORT ? "danger" : "userdanger"
		to_chat(L, "<span class='[span]'>[message]</span>")
	switch(punishment)
		if(PUNISHMENT_MURDER)
			L.death()
		if(PUNISHMENT_GIB)
			L.gib()
		if(PUNISHMENT_TELEPORT)
			var/targetturf = find_safe_turf(stuck_zlevel)
			if(!targetturf)
				targetturf = locate(world.maxx/2,world.maxy/2,stuck_zlevel)
			L.forceMove(targetturf)

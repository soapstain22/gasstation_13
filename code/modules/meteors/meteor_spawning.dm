#define MAP_EDGE_PAD 5

/proc/spawn_meteors(number = 10, list/meteor_types, direction)
	for(var/i in 1 to number)
		spawn_meteor(meteor_types, direction)

/proc/spawn_meteor(list/meteor_types, direction, atom/target)
	if (SSmapping.is_planetary())
		stack_trace("Tried to spawn meteors in a map which isn't in space.")
		return // We're not going to find any space turfs here
	var/turf/picked_start
	var/turf/picked_goal
	var/max_i = 10//number of tries to spawn meteor.
	while(!isspaceturf(picked_start))
		var/start_side
		if(direction) //If a direction has been specified, we set start_side to it. Otherwise, pick randomly
			start_side = direction
		else
			start_side = pick(GLOB.cardinals)
		var/start_Z = pick(SSmapping.levels_by_trait(ZTRAIT_STATION))
		picked_start = spaceDebrisStartLoc(start_side, start_Z)
		if(target)
			if(!isturf(target))
				target = get_turf(target)
			picked_goal = target
		else
			picked_goal = spaceDebrisFinishLoc(start_side, start_Z)
		max_i--
		if(max_i <= 0)
			return
	var/new_meteor = pick_weight(meteor_types)
	new new_meteor(picked_start, picked_goal)

/proc/spaceDebrisStartLoc(start_side, Z)
	var/starty
	var/startx
	switch(start_side)
		if(NORTH)
			starty = world.maxy-(TRANSITIONEDGE + MAP_EDGE_PAD)
			startx = rand((TRANSITIONEDGE + MAP_EDGE_PAD), world.maxx-(TRANSITIONEDGE + MAP_EDGE_PAD))
		if(EAST)
			starty = rand((TRANSITIONEDGE + MAP_EDGE_PAD),world.maxy-(TRANSITIONEDGE + MAP_EDGE_PAD))
			startx = world.maxx-(TRANSITIONEDGE + MAP_EDGE_PAD)
		if(SOUTH)
			starty = (TRANSITIONEDGE + MAP_EDGE_PAD)
			startx = rand((TRANSITIONEDGE + MAP_EDGE_PAD), world.maxx-(TRANSITIONEDGE + MAP_EDGE_PAD))
		if(WEST)
			starty = rand((TRANSITIONEDGE + MAP_EDGE_PAD), world.maxy-(TRANSITIONEDGE + MAP_EDGE_PAD))
			startx = (TRANSITIONEDGE + MAP_EDGE_PAD)
	. = locate(startx, starty, Z)

/proc/spaceDebrisFinishLoc(startSide, Z)
	var/endy
	var/endx
	switch(startSide)
		if(NORTH)
			endy = (TRANSITIONEDGE + MAP_EDGE_PAD)
			endx = rand((TRANSITIONEDGE + MAP_EDGE_PAD), world.maxx-(TRANSITIONEDGE + MAP_EDGE_PAD))
		if(EAST)
			endy = rand((TRANSITIONEDGE + MAP_EDGE_PAD), world.maxy-(TRANSITIONEDGE + MAP_EDGE_PAD))
			endx = (TRANSITIONEDGE + MAP_EDGE_PAD)
		if(SOUTH)
			endy = world.maxy-(TRANSITIONEDGE + MAP_EDGE_PAD)
			endx = rand((TRANSITIONEDGE + MAP_EDGE_PAD), world.maxx-(TRANSITIONEDGE + MAP_EDGE_PAD))
		if(WEST)
			endy = rand((TRANSITIONEDGE + MAP_EDGE_PAD),world.maxy-(TRANSITIONEDGE + MAP_EDGE_PAD))
			endx = world.maxx-(TRANSITIONEDGE + MAP_EDGE_PAD)
	. = locate(endx, endy, Z)

/**
 * Recieves a mob candidate, transforms them into a changeling, and hurls them at the station inside of a changeling meteor
 *
 * Takes a given candidate and turns them into a changeling, generates a changeling meteor, and throws it at the station.
 * Returns the changeling generated by the event, NOT the meteor. This is so that it plays nicely with the dynamic ruleset
 * while still being usable in the ghost_role event as well.
 *
 * Arguments:
 * * candidate - The mob (player) to be transformed into a changeling and meteored.
 */
/proc/generate_changeling_meteor(mob/dead/selected)
	var/datum/mind/player_mind = new(selected.key)
	player_mind.active = TRUE

	var/turf/picked_start

	if (SSmapping.is_planetary())
		var/list/possible_start = list()
		for(var/obj/effect/landmark/carpspawn/spawn_point in GLOB.landmarks_list)
			possible_start += get_turf(spawn_point)
		picked_start = pick(possible_start)
	else
		var/start_z = pick(SSmapping.levels_by_trait(ZTRAIT_STATION))
		var/start_side = pick(GLOB.cardinals)
		picked_start = spaceDebrisStartLoc(start_side, start_z)

	if (!picked_start)
		stack_trace("No valid spawn location for changeling meteor")

	var/obj/effect/meteor/meaty/changeling/changeling_meteor = new(picked_start, get_random_station_turf())
	var/mob/living/carbon/human/new_changeling = new(picked_start)

	new_changeling.forceMove(changeling_meteor) //Place our payload inside of its vessel

	player_mind.transfer_to(new_changeling)
	player_mind.special_role = ROLE_CHANGELING_MIDROUND
	player_mind.add_antag_datum(/datum/antagonist/changeling/space)
	SEND_SOUND(new_changeling, 'sound/magic/mutate.ogg')
	message_admins("[ADMIN_LOOKUPFLW(new_changeling)] has been made into a space changeling by an event.")
	new_changeling.log_message("was spawned as a midround space changeling by an event.", LOG_GAME)

	var/datum/antagonist/changeling/changeling_datum = locate() in player_mind.antag_datums
	changeling_datum.give_power(/datum/action/changeling/void_adaption)
	changeling_datum.give_power(/datum/action/changeling/weapon/arm_blade)
	new_changeling.equipOutfit(/datum/outfit/changeling_space)

	return new_changeling

#undef MAP_EDGE_PAD

#ifdef REFERENCE_TRACKING

/datum/proc/find_references(skip_alert)
	running_find_references = type
	if(usr?.client)
		if(usr.client.running_find_references)
			log_world("CANCELLED search for references to a [usr.client.running_find_references].")
			usr.client.running_find_references = null
			running_find_references = null
			//restart the garbage collector
			SSgarbage.can_fire = TRUE
			SSgarbage.next_fire = world.time + world.tick_lag
			return

		if(!skip_alert && tgui_alert(usr,"Running this will lock everything up for about 5 minutes.  Would you like to begin the search?", "Find References", list("Yes", "No")) != "Yes")
			running_find_references = null
			return

	//this keeps the garbage collector from failing to collect objects being searched for in here
	SSgarbage.can_fire = FALSE

	if(usr?.client)
		usr.client.running_find_references = type

	log_world("Beginning search for references to a [type].")

	var/starting_time = world.time

	//Time to search the whole game for our ref
	DoSearchVar(GLOB, "GLOB") //globals
	log_world("Finished searching globals")

	for(var/datum/thing in world) //atoms (don't beleive its lies)
		DoSearchVar(thing, "World -> [thing.type]", search_time = starting_time)
	log_world("Finished searching atoms")

	for(var/datum/thing) //datums
		DoSearchVar(thing, "Datums -> [thing.type]", search_time = starting_time)
	log_world("Finished searching datums")

	//Warning, attempting to search clients like this will cause crashes if done on live. Watch yourself
	for(var/client/thing) //clients
		DoSearchVar(thing, "Clients -> [thing.type]", search_time = starting_time)
	log_world("Finished searching clients")

	log_world("Completed search for references to a [type].")

	if(usr?.client)
		usr.client.running_find_references = null
	running_find_references = null

	//restart the garbage collector
	SSgarbage.can_fire = TRUE
	SSgarbage.next_fire = world.time + world.tick_lag

/datum/proc/DoSearchVar(potential_container, container_name, recursive_limit = 64, search_time = world.time)
	#ifdef REFERENCE_TRACKING_DEBUG
	if(!found_refs)
		found_refs = list()
	#endif

	if(usr?.client && !usr.client.running_find_references)
		return

	if(!recursive_limit)
		log_world("Recursion limit reached. [container_name]")
		return

	//Check each time you go down a layer. This makes it a bit slow, but it won't effect the rest of the game at all
	#ifndef FIND_REF_NO_CHECK_TICK
	CHECK_TICK
	#endif

	if(istype(potential_container, /datum))
		var/datum/datum_container = potential_container
		if(datum_container.last_find_references == search_time)
			return

		datum_container.last_find_references = search_time
		var/list/vars_list = datum_container.vars

		for(var/varname in vars_list)
			#ifndef FIND_REF_NO_CHECK_TICK
			CHECK_TICK
			#endif
			if (varname == "vars" || varname == "vis_locs") //Fun fact, vis_locs don't count for references
				continue
			var/variable = vars_list[varname]

			if(variable == src)
				#ifdef REFERENCE_TRACKING_DEBUG
				found_refs[varname] = TRUE
				#endif
				log_world("Found [type] \ref[src] in [datum_container.type]'s \ref[datum_container] [varname] var. [container_name]")
				continue

			if(islist(variable))
				DoSearchVar(variable, "[container_name] \ref[datum_container] -> [varname] (list)", recursive_limit - 1, search_time)

	else if(islist(potential_container))
		var/normal = IS_NORMAL_LIST(potential_container)
		var/list/potential_cache = potential_container
		for(var/element_in_list in potential_cache)
			#ifndef FIND_REF_NO_CHECK_TICK
			CHECK_TICK
			#endif
			//Check normal entrys
			if(element_in_list == src)
				#ifdef REFERENCE_TRACKING_DEBUG
				found_refs[potential_cache] = TRUE
				#endif
				log_world("Found [type] \ref[src] in list [container_name].")
				continue

			var/assoc_val = null
			if(!isnum(element_in_list) && normal)
				assoc_val = potential_cache[element_in_list]
			//Check assoc entrys
			if(assoc_val == src)
				#ifdef REFERENCE_TRACKING_DEBUG
				found_refs[potential_cache] = TRUE
				#endif
				log_world("Found [type] \ref[src] in list [container_name]\[[element_in_list]\]")
				continue
			//We need to run both of these checks, since our object could be hiding in either of them
			//Check normal sublists
			if(islist(element_in_list))
				DoSearchVar(element_in_list, "[container_name] -> [element_in_list] (list)", recursive_limit - 1, search_time)
			//Check assoc sublists
			if(islist(assoc_val))
				DoSearchVar(potential_container[element_in_list], "[container_name]\[[element_in_list]\] -> [assoc_val] (list)", recursive_limit - 1, search_time)

/proc/qdel_and_find_ref_if_fail(datum/thing_to_del, force = FALSE)
	thing_to_del.qdel_and_find_ref_if_fail(force)

/datum/proc/qdel_and_find_ref_if_fail(force = FALSE)
	SSgarbage.reference_find_on_fail["\ref[src]"] = TRUE
	qdel(src, force)

#endif

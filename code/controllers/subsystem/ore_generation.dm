#define MAX_BOULDERS_PER_VENT 10

SUBSYSTEM_DEF(ore_generation)
	name = "Ore_generation"
	wait = 0.1 MINUTES
	init_order = INIT_ORDER_DEFAULT
	runlevels = RUNLEVEL_GAME
	flags = SS_NO_INIT

	/// All ore vents that are currently producing boulders.
	var/list/processed_vents = list()
	/// All the boulders that have been produced by ore vents to be pulled by BRM machines.
	var/list/available_boulders = list()
	/// All the ore vents that are currently in the game, not just the ones that are producing boulders.
	var/list/possible_vents = list()
	/// The quantity of ore vents that mapgen will attempt to spawn.
	var/ore_vent_count = 15
	/**
	 * Associated list of minerals to be associated with our ore vents.
	 * Should be empty by the time initialize ends. Each value by each key is the number of vents that have this ore as a possible choice.
	 */
	var/list/ore_vent_minerals = list(
		/datum/material/iron = 12,
		/datum/material/glass = 12,
		/datum/material/plasma = 8,
		/datum/material/titanium = 5,
		/datum/material/silver = 5,
		/datum/material/gold = 5,
		/datum/material/diamond = 3,
		/datum/material/uranium = 3,
		/datum/material/bluespace = 3,
		/datum/material/plastic = 1,
	)
 	///Associated list of vent sizes that remain. We can't have more than 3 large vents, 5 medium vents, and 7 small vents.
	var/list/ore_vent_sizes = list(
		"large" = 3,
		"medium" = 5,
		"small" = 7,
	)


/datum/controller/subsystem/ore_generation/fire(resumed)

	available_boulders = list() // reset upon new fire.
	for(var/vent in processed_vents)
		var/obj/structure/ore_vent/current_vent = vent

		var/local_vent_count = 0
		for(var/obj/item/old_rock as anything in current_vent.loc) /// This is expensive and bad, I know. Optimize?
			if(!isitem(old_rock))
				continue
			available_boulders += old_rock
			local_vent_count++

		if(local_vent_count >= MAX_BOULDERS_PER_VENT)
			return //We don't want to be accountable for literally hundreds of unprocessed boulders for no reason.
		var/obj/item/boulder/new_rock
		if(current_vent.artifact_chance)
			if(prob(current_vent.artifact_chance))
				new_rock = new /obj/item/boulder/artifact(current_vent.loc)
				available_boulders += new_rock
				return

		new_rock = new (current_vent.loc)
		var/list/mats_list = current_vent.create_mineral_contents()
		current_vent.Shake(duration = 1.5 SECONDS)
		new_rock.set_custom_materials(mats_list)
		available_boulders += new_rock




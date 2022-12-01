GLOBAL_LIST_EMPTY_TYPED(grey_tide_areas, /area)

/datum/round_event_control/grey_tide
	name = "Grey Tide"
	typepath = /datum/round_event/grey_tide
	max_occurrences = 2
	min_players = 5
	category = EVENT_CATEGORY_ENGINEERING
	description = "Bolts open all doors in one or more departments."

/datum/round_event_control/grey_tide/can_spawn_event(players_amt)
	. = ..()

	for(var/datum/round_event/running_event in SSevents.running)
		if(istype(running_event, /datum/round_event/grey_tide)) //Two of these at once messes up the list
			return FALSE

/datum/round_event/grey_tide
	announce_when = 50
	end_when = 20
	var/severity = 1

/datum/round_event/grey_tide/setup()
	announce_when = rand(50, 60)
	end_when = rand(20, 30)
	severity = rand(1,3)

	var/list/potential_areas = list(/area/station/command,
		/area/station/engineering,
		/area/station/medical,
		/area/station/security,
		/area/station/cargo,
		/area/station/science,
	)

	for(var/i in 1 to severity)
		GLOB.grey_tide_areas += pick_n_take(potential_areas)

/datum/round_event/grey_tide/announce(fake)
	priority_announce("Gr3y.T1d3 virus detected in [station_name()] secure locking encryption subroutines. Severity level of [severity]. Recommend station AI involvement.", "Security Alert")

	GLOB.grey_tide_areas.Cut() //As announce always occurs last, we use it to clean up the list of areas to be affected

/datum/round_event/grey_tide/start()
	if(!length(GLOB.grey_tide_areas))
		log_world("ERROR: Could not initiate grey-tide. No areas in the list!")
		kill()

/datum/round_event/grey_tide/tick()
	if(!ISMULTIPLE(activeFor, 12)) return

	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_GREY_TIDE_LIGHT)

// Objects currently impacted by the greytide event:
// /obj/machinery/door/airlock -- Signal bolts open the door
// /obj/machinery/status_display/door_timer -- Signal instantly ends the timer, releasing the occupant
// /obj/structure/closet/secure_closet -- Signal unlocks locked lockers
// /obj/machinery/power/apc -- Signal turns the lighting channel off

/datum/round_event/grey_tide/end()
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_GREY_TIDE)

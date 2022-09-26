#define RANDOM_EVENT_ADMIN_INTERVENTION_TIME (10 SECONDS)

//this singleton datum is used by the events controller to dictate how it selects events
/datum/round_event_control
	var/name //The human-readable name of the event
	var/category //The category of the event
	var/description //The description of the event
	var/typepath //The typepath of the event datum /datum/round_event

	var/weight = 10 //The weight this event has in the random-selection process.
									//Higher weights are more likely to be picked.
									//10 is the default weight. 20 is twice more likely; 5 is half as likely as this default.
									//0 here does NOT disable the event, it just makes it extremely unlikely

	var/earliest_start = 20 MINUTES //The earliest world.time that an event can start (round-duration in deciseconds) default: 20 mins
	var/min_players = 0 //The minimum amount of alive, non-AFK human players on server required to start the event.

	var/occurrences = 0 //How many times this event has occured
	var/max_occurrences = 20 //The maximum number of times this event can occur (naturally), it can still be forced.
									//By setting this to 0 you can effectively disable an event.

	var/holidayID = "" //string which should be in the SSeventss.holidays list if you wish this event to be holiday-specific
									//anything with a (non-null) holidayID which does not match holiday, cannot run.
	var/wizardevent = FALSE
	var/alert_observers = TRUE //should we let the ghosts and admins know this event is firing
									//should be disabled on events that fire a lot

	var/triggering //admin cancellation

	/// Whether or not dynamic should hijack this event
	var/dynamic_should_hijack = FALSE

/datum/round_event_control/New()
	if(config && !wizardevent) // Magic is unaffected by configs
		earliest_start = CEILING(earliest_start * CONFIG_GET(number/events_min_time_mul), 1)
		min_players = CEILING(min_players * CONFIG_GET(number/events_min_players_mul), 1)

/datum/round_event_control/wizard
	category = EVENT_CATEGORY_WIZARD
	wizardevent = TRUE

// Checks if the event can be spawned. Used by event controller and "false alarm" event.
// Admin-created events override this.
/datum/round_event_control/proc/canSpawnEvent(players_amt)
	if(occurrences >= max_occurrences)
		return FALSE
	if(earliest_start >= world.time-SSticker.round_start_time)
		return FALSE
	if(wizardevent != SSevents.wizardmode)
		return FALSE
	if(players_amt < min_players)
		return FALSE
	if(holidayID && (!SSevents.holidays || !SSevents.holidays[holidayID]))
		return FALSE
	if(EMERGENCY_ESCAPED_OR_ENDGAMED)
		return FALSE
	if(ispath(typepath, /datum/round_event/ghost_role) && !(GLOB.ghost_role_flags & GHOSTROLE_MIDROUND_EVENT))
		return FALSE

	var/datum/game_mode/dynamic/dynamic = SSticker.mode
	if (istype(dynamic) && dynamic_should_hijack && dynamic.random_event_hijacked != HIJACKED_NOTHING)
		return FALSE

	return TRUE

/datum/round_event_control/proc/preRunEvent()
	if(!ispath(typepath, /datum/round_event))
		return EVENT_CANT_RUN

	if (SEND_GLOBAL_SIGNAL(COMSIG_GLOB_PRE_RANDOM_EVENT, src) & CANCEL_PRE_RANDOM_EVENT)
		return EVENT_INTERRUPTED

	triggering = TRUE

	var/players_amt = get_active_player_count(alive_check = TRUE, afk_check = TRUE, human_check = TRUE)

	if(!canSpawnEvent(players_amt))
		message_admins("Second pre-condition check for [name] failed, skipping...")
		return EVENT_INTERRUPTED

	if(!triggering)
		return EVENT_CANCELLED //admin cancelled
	triggering = FALSE
	return EVENT_READY

/datum/round_event_control/Topic(href, href_list)
	..()
	if(href_list["cancel"])
		if(!triggering)
			to_chat(usr, span_admin("You are too late to cancel that event"))
			return
		triggering = FALSE
		message_admins("[key_name_admin(usr)] cancelled event [name].")
		log_admin_private("[key_name(usr)] cancelled event [name].")
		SSblackbox.record_feedback("tally", "event_admin_cancelled", 1, typepath)

/*
Runs the event
* Arguments:
* - random: shows if the event was triggered randomly, or by on purpose by an admin or an item
* - announce_chance_override: if the value is not null, overrides the announcement chance when an admin calls an event
*/
/datum/round_event_control/proc/runEvent(random = FALSE, announce_chance_override = null, admin_forced = FALSE)
	/*
	* We clear our signals first so we dont cancel a wanted event by accident,
	* the majority of time the admin will probably want to cancel a single midround spawned random events
	* and not multiple events called by others admins
	* * In the worst case scenario we can still recall a event which we cancelled by accident, which is much better then to have a unwanted event
	*/
	UnregisterSignal(SSdcs, COMSIG_GLOB_RANDOM_EVENT)
	var/datum/round_event/E = new typepath()
	E.current_players = get_active_player_count(alive_check = 1, afk_check = 1, human_check = 1)
	E.control = src
	occurrences++

	if(announce_chance_override != null)
		E.announce_chance = announce_chance_override

	testing("[time2text(world.time, "hh:mm:ss")] [E.type]")
	triggering = TRUE

	// Make sure the other admins know if it's another admin trying to get an event through, or if the game is engaging in chicanery. We sleep here for the given amount of time to make sure they have enough time to cancel it.
	// We do a bit of baby-proofing in case an admin fat-fingers an event and summons a Blob instead of something like an Ion Storm.
	message_admins("[admin_forced ? "Admin Event" : "Random Event"] triggering in [DisplayTimeText(RANDOM_EVENT_ADMIN_INTERVENTION_TIME)]: [name] (<a href='?src=[REF(src)];cancel=1'>CANCEL</a>).")
	sleep(RANDOM_EVENT_ADMIN_INTERVENTION_TIME)

	if(!triggering)
		RegisterSignal(SSdcs, COMSIG_GLOB_RANDOM_EVENT, .proc/stop_random_event)
		E.cancel_event = TRUE
		return E

	triggering = FALSE
	if(random)
		log_game("Random Event triggering: [name] ([typepath]).")

	if(alert_observers)
		deadchat_broadcast(" has just been[random ? " randomly" : ""] triggered!", "<b>[name]</b>", message_type=DEADCHAT_ANNOUNCEMENT) //STOP ASSUMING IT'S BADMINS!

	SSblackbox.record_feedback("tally", "event_ran", 1, "[E]")
	return E

//Returns the component for the listener
/datum/round_event_control/proc/stop_random_event()
	SIGNAL_HANDLER
	return CANCEL_RANDOM_EVENT

/// Any special things admins can do while triggering this event to "improve" it.
/// Return [ADMIN_CANCEL_EVENT] to stop the event from actually happening after all
/datum/round_event_control/proc/admin_setup(mob/admin)
	return

/datum/round_event //NOTE: Times are measured in master controller ticks!
	var/processing = TRUE
	var/datum/round_event_control/control

	/// When in the lifetime to call start().
	var/start_when = 0
	/// When in the lifetime to call announce(). If you don't want it to announce use announce_chance, below.
	var/announce_when = 0
	/// Probability of announcing, used in prob(), 0 to 100, default 100. Called in process, and for a second time in the ion storm event.
	var/announce_chance = 100
	/// When in the lifetime the event should end.
	var/end_when = 0

	/// How long the event has existed. You don't need to change this.
	var/activeFor = 0
	/// Amount of of alive, non-AFK human players on server at the time of event start
	var/current_players = 0
	/// Can be faked by fake news event.
	var/fakeable = TRUE
	/// Whether a admin wants this event to be cancelled
	var/cancel_event = FALSE

//Called first before processing.
//Allows you to setup your event, such as randomly
//setting the start_when and or announce_when variables.
//Only called once.
//EDIT: if there's anything you want to override within the new() call, it will not be overridden by the time this proc is called.
//It will only have been overridden by the time we get to announce() start() tick() or end() (anything but setup basically).
//This is really only for setting defaults which can be overridden later when New() finishes.
/datum/round_event/proc/setup()
	return

//Called when the tick is equal to the start_when variable.
//Allows you to start before announcing or vice versa.
//Only called once.
/datum/round_event/proc/start()
	return

//Called after something followable has been spawned by an event
//Provides ghosts a follow link to an atom if possible
//Only called once.
/datum/round_event/proc/announce_to_ghosts(atom/atom_of_interest)
	if(control.alert_observers)
		if (atom_of_interest)
			notify_ghosts("[control.name] has an object of interest: [atom_of_interest]!", source=atom_of_interest, action=NOTIFY_ORBIT, header="Something's Interesting!")
	return

//Called when the tick is equal to the announce_when variable.
//Allows you to announce before starting or vice versa.
//Only called once.
/datum/round_event/proc/announce(fake)
	return

//Called on or after the tick counter is equal to start_when.
//You can include code related to your event or add your own
//time stamped events.
//Called more than once.
/datum/round_event/proc/tick()
	return

//Called on or after the tick is equal or more than end_when
//You can include code related to the event ending.
//Do not place spawn() in here, instead use tick() to check for
//the activeFor variable.
//For example: if(activeFor == myOwnVariable + 30) doStuff()
//Only called once.
/datum/round_event/proc/end()
	return



//Do not override this proc, instead use the appropiate procs.
//This proc will handle the calls to the appropiate procs.
/datum/round_event/process()
	SHOULD_NOT_OVERRIDE(TRUE)
	if(!processing)
		return

	if(SEND_GLOBAL_SIGNAL(COMSIG_GLOB_RANDOM_EVENT, src) & CANCEL_RANDOM_EVENT)
		processing = FALSE
		kill()
		return

	if(activeFor == start_when)
		processing = FALSE
		start()
		processing = TRUE

	if(activeFor == announce_when && prob(announce_chance))
		processing = FALSE
		announce(FALSE)
		processing = TRUE

	if(start_when < activeFor && activeFor < end_when)
		processing = FALSE
		tick()
		processing = TRUE

	if(activeFor == end_when)
		processing = FALSE
		end()
		processing = TRUE

	// Everything is done, let's clean up.
	if(activeFor >= end_when && activeFor >= announce_when && activeFor >= start_when)
		processing = FALSE
		kill()

	activeFor++


//Garbage collects the event by removing it from the global events list,
//which should be the only place it's referenced.
//Called when start(), announce() and end() has all been called.
/datum/round_event/proc/kill()
	SSevents.running -= src


//Sets up the event then adds the event to the the list of running events
/datum/round_event/New(my_processing = TRUE)
	setup()
	processing = my_processing
	SSevents.running += src
	return ..()

#undef RANDOM_EVENT_ADMIN_INTERVENTION_TIME

/**
 * This section contain all procs that helps building, destroy and control the hfr
 */

/**
 * Called by multitool_act() in hfr_parts.dm, by atmos_process() in hfr_main_processes.dm and by fusion_process() in the same file
 * This proc checks the surrounding of the core to ensure that the machine has been build correctly, returns false if there is a missing piece/wrong placed one
 */
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/check_part_connectivity()
	. = TRUE
	if(!anchored || panel_open)
		return FALSE

	for(var/obj/machinery/hypertorus/object in orange(1,src))
		if(. == FALSE)
			break

		if(object.panel_open)
			. = FALSE

		if(istype(object,/obj/machinery/hypertorus/corner))
			var/dir = get_dir(src,object)
			if(dir in GLOB.cardinals)
				. =  FALSE
			switch(dir)
				if(SOUTHEAST)
					if(object.dir != SOUTH)
						. = FALSE
				if(SOUTHWEST)
					if(object.dir != WEST)
						. =  FALSE
				if(NORTHEAST)
					if(object.dir != EAST)
						. =  FALSE
				if(NORTHWEST)
					if(object.dir != NORTH)
						. =  FALSE
			corners |= object
			continue

		if(get_step(object,turn(object.dir,180)) != loc)
			. =  FALSE

		if(istype(object,/obj/machinery/hypertorus/interface))
			if(linked_interface && linked_interface != object)
				. =  FALSE
			linked_interface = object

	for(var/obj/machinery/atmospherics/components/unary/hypertorus/object in orange(1,src))
		if(. == FALSE)
			break

		if(object.panel_open)
			. = FALSE

		if(get_step(object,turn(object.dir,180)) != loc)
			. =  FALSE

		if(istype(object,/obj/machinery/atmospherics/components/unary/hypertorus/fuel_input))
			if(linked_input && linked_input != object)
				. =  FALSE
			linked_input = object

		if(istype(object,/obj/machinery/atmospherics/components/unary/hypertorus/waste_output))
			if(linked_output && linked_output != object)
				. =  FALSE
			linked_output = object

		if(istype(object,/obj/machinery/atmospherics/components/unary/hypertorus/moderator_input))
			if(linked_moderator && linked_moderator != object)
				. =  FALSE
			linked_moderator = object

	if(!linked_interface || !linked_input || !linked_moderator || !linked_output || corners.len != 4)
		. = FALSE

/**
 * Called by multitool_act() in hfr_parts.dm
 * It sets the pieces to active, allowing the player to start the main reaction
 * Arguments:
 * * -user: the player doing the action
 */
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/activate(mob/living/user)
	if(active)
		to_chat(user, "<span class='notice'>You already activated the machine.</span>")
		return
	to_chat(user, "<span class='notice'>You link all parts toghether.</span>")
	active = TRUE
	update_icon()
	linked_interface.active = TRUE
	linked_interface.update_icon()
	RegisterSignal(linked_interface, COMSIG_PARENT_QDELETING, .proc/unregister_signals)
	linked_input.active = TRUE
	linked_input.update_icon()
	RegisterSignal(linked_input, COMSIG_PARENT_QDELETING, .proc/unregister_signals)
	linked_output.active = TRUE
	linked_output.update_icon()
	RegisterSignal(linked_output, COMSIG_PARENT_QDELETING, .proc/unregister_signals)
	linked_moderator.active = TRUE
	linked_moderator.update_icon()
	RegisterSignal(linked_moderator, COMSIG_PARENT_QDELETING, .proc/unregister_signals)
	for(var/obj/machinery/hypertorus/corner/corner in corners)
		corner.active = TRUE
		corner.update_icon()
		RegisterSignal(corner, COMSIG_PARENT_QDELETING, .proc/unregister_signals)
	soundloop = new(list(src), TRUE)
	soundloop.volume = 5

/**
 * Called when a part gets deleted around the hfr, called on Destroy() of the hfr core in hfr_core.dm
 * Unregister the signals attached to the core from the various machines, if only_signals is false it will also call deactivate()
 * Arguments:
 * * only_signals: default FALSE, if true the proc will not call the deactivate() proc
 */
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/unregister_signals(only_signals = FALSE)
	UnregisterSignal(linked_interface, COMSIG_PARENT_QDELETING)
	UnregisterSignal(linked_input, COMSIG_PARENT_QDELETING)
	UnregisterSignal(linked_output, COMSIG_PARENT_QDELETING)
	UnregisterSignal(linked_moderator, COMSIG_PARENT_QDELETING)
	for(var/obj/machinery/hypertorus/corner/corner in corners)
		UnregisterSignal(corner, COMSIG_PARENT_QDELETING)
	if(!only_signals)
		deactivate()

/**
 * Called by unregister_signals() in this file, called when the main fusion processes check_part_connectivity() returns false
 * Deactivate the various machines by setting the active var to false, updates the machines icon and set the linked machine vars to null
 */
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/deactivate()
	if(!active)
		return
	active = FALSE
	update_icon()
	if(linked_interface)
		linked_interface.active = FALSE
		linked_interface.update_icon()
		linked_interface = null
	if(linked_input)
		linked_input.active = FALSE
		linked_input.update_icon()
		linked_input = null
	if(linked_output)
		linked_output.active = FALSE
		linked_output.update_icon()
		linked_output = null
	if(linked_moderator)
		linked_moderator.active = FALSE
		linked_moderator.update_icon()
		linked_moderator = null
	if(corners.len)
		for(var/obj/machinery/hypertorus/corner/corner in corners)
			corner.active = FALSE
			corner.update_icon()
		corners = list()
	QDEL_NULL(soundloop)

/**
 * Called by the main fusion processes in hfr_main_processes.dm
 * Getter for fusion fuel moles
 */
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/check_fuel()
	return (internal_fusion.gases[/datum/gas/tritium][MOLES] > FUSION_MOLE_THRESHOLD && internal_fusion.gases[/datum/gas/hydrogen][MOLES] > FUSION_MOLE_THRESHOLD)

/**
 * Called by the main fusion processes in hfr_main_processes.dm
 * Check the power use of the machine, return TRUE if there is enough power in the powernet
 */
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/check_power_use()
	if(machine_stat & (NOPOWER|BROKEN))
		return FALSE
	if(use_power == ACTIVE_POWER_USE)
		active_power_usage = ((power_level + 1) * MIN_POWER_USAGE) //Max around 350 KW
	return TRUE

/**
 * Called by alarm() in this file
 * Check the integrity level and returns the status of the machine
 */
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/get_status()
	var/integrity = get_integrity()
	if(integrity < HYPERTORUS_MELTING_PERCENT)
		return HYPERTORUS_MELTING

	if(integrity < HYPERTORUS_EMERGENCY_PERCENT)
		return HYPERTORUS_EMERGENCY

	if(integrity < HYPERTORUS_DANGER_PERCENT)
		return HYPERTORUS_DANGER

	if(integrity < HYPERTORUS_WARNING_PERCENT)
		return HYPERTORUS_WARNING

	if(power_level > 0)
		return HYPERTORUS_NOMINAL
	return HYPERTORUS_INACTIVE

/**
 * Called by check_alert() in this file
 * Play a sound from the machine, the type depends on the status of the hfr
 */
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/alarm()
	switch(get_status())
		if(HYPERTORUS_MELTING)
			playsound(src, 'sound/misc/bloblarm.ogg', 100, FALSE, 40, 30, falloff_distance = 10)
		if(HYPERTORUS_EMERGENCY)
			playsound(src, 'sound/machines/engine_alert1.ogg', 100, FALSE, 30, 30, falloff_distance = 10)
		if(HYPERTORUS_DANGER)
			playsound(src, 'sound/machines/engine_alert2.ogg', 100, FALSE, 30, 30, falloff_distance = 10)
		if(HYPERTORUS_WARNING)
			playsound(src, 'sound/machines/terminal_alert.ogg', 75)

/**
 * Getter for the machine integrity
 */
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/get_integrity()
	var/integrity = critical_threshold_proximity / melting_point
	integrity = round(100 - integrity * 100, 0.01)
	integrity = integrity < 0 ? 0 : integrity
	return integrity

/**
 * Called by process_atmos() in hfr_main_processes.dm
 * Called after checking the damage of the machine, calls alarm() and countdown()
 * Broadcast messages into engi and common radio
 */
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/check_alert()
	if(critical_threshold_proximity < warning_point)
		return
	if((REALTIMEOFDAY - lastwarning) / 10 >= WARNING_TIME_DELAY)
		alarm()

		if(critical_threshold_proximity > emergency_point)
			radio.talk_into(src, "[emergency_alert] Integrity: [get_integrity()]%", common_channel)
			lastwarning = REALTIMEOFDAY
			if(!has_reached_emergency)
				investigate_log("has reached the emergency point for the first time.", INVESTIGATE_HYPERTORUS)
				message_admins("[src] has reached the emergency point [ADMIN_JMP(src)].")
				has_reached_emergency = TRUE
		else if(critical_threshold_proximity >= critical_threshold_proximity_archived) // The damage is still going up
			radio.talk_into(src, "[warning_alert] Integrity: [get_integrity()]%", engineering_channel)
			lastwarning = REALTIMEOFDAY - (WARNING_TIME_DELAY * 5)

		else // Phew, we're safe
			radio.talk_into(src, "[safe_alert] Integrity: [get_integrity()]%", engineering_channel)
			lastwarning = REALTIMEOFDAY

	//Melt
	if(critical_threshold_proximity > melting_point)
		countdown()

/**
 * Called by check_alert() in this file
 * Called when the damage has reached critical levels, start the countdown before the destruction, calls meltdown()
 */
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/countdown()
	set waitfor = FALSE

	if(final_countdown) // We're already doing it go away
		return
	final_countdown = TRUE

	var/speaking = "[emergency_alert] The Hypertorus fusion reactor has reached critical integrity failure. Emergency magnetic dampeners online."
	radio.talk_into(src, speaking, common_channel, language = get_selected_language())
	for(var/i in HYPERTORUS_COUNTDOWN_TIME to 0 step -10)
		if(critical_threshold_proximity < melting_point) // Cutting it a bit close there engineers
			radio.talk_into(src, "[safe_alert] Failsafe has been disengaged.", common_channel)
			final_countdown = FALSE
			return
		else if((i % 50) != 0 && i > 50) // A message once every 5 seconds until the final 5 seconds which count down individualy
			sleep(10)
			continue
		else if(i > 50)
			speaking = "[DisplayTimeText(i, TRUE)] remain before total integrity failure."
		else
			speaking = "[i*0.1]..."
		radio.talk_into(src, speaking, common_channel)
		sleep(10)

	meltdown()

/**
 * Called by countdown() in this file
 * Create the explosion + the gas emission before deleting the machine core.
 */
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/meltdown()
	explosion(loc, 0, 0, power_level * 5, power_level * 6, 1, 1)
	radiation_pulse(loc, power_level * 7000, (1 / (power_level + 5)), TRUE)
	empulse(loc, power_level * 5, power_level * 7)
	var/fusion_moles = internal_fusion.total_moles() ? internal_fusion.total_moles() : 0
	var/moderator_moles = moderator_internal.total_moles() ? moderator_internal.total_moles() : 0
	var/datum/gas_mixture/remove_fusion
	if(internal_fusion.total_moles() > 0)
		remove_fusion = internal_fusion.remove(fusion_moles)
		loc.assume_air(remove_fusion)
	var/datum/gas_mixture/remove_moderator
	if(moderator_internal.total_moles() > 0)
		remove_moderator = moderator_internal.remove(moderator_moles)
		loc.assume_air(remove_moderator)
	air_update_turf(FALSE, FALSE)
	qdel(src)

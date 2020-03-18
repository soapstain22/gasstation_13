/obj/effect/countdown
	name = "countdown"
	desc = "We're leaving together\n\
		But still it's farewell\n\
		And maybe we'll come back\n\
		To Earth, who can tell?"

	invisibility = INVISIBILITY_OBSERVER
	anchored = TRUE
	layer = GHOST_LAYER
	color = "#ff0000" // text color
	var/text_size = 3 // larger values clip when the displayed text is larger than 2 digits.
	var/started = FALSE
	var/displayed_text
	var/atom/attached_to

/obj/effect/countdown/Initialize()
	. = ..()
	attach(loc)

/obj/effect/countdown/examine(mob/user)
	. = ..()
	. += "This countdown is displaying: [displayed_text]."

/obj/effect/countdown/proc/attach(atom/A)
	attached_to = A
	forceMove(get_turf(A))

/obj/effect/countdown/proc/start()
	if(!started)
		START_PROCESSING(SSfastprocess, src)
		started = TRUE

/obj/effect/countdown/proc/stop()
	if(started)
		maptext = null
		STOP_PROCESSING(SSfastprocess, src)
		started = FALSE

/obj/effect/countdown/proc/get_value()
	// Get the value from our atom
	return

/obj/effect/countdown/process()
	if(!attached_to || QDELETED(attached_to))
		qdel(src)
	forceMove(get_turf(attached_to))
	var/new_val = get_value()
	if(new_val == displayed_text)
		return
	displayed_text = new_val

	if(displayed_text)
		maptext = "<font size = [text_size]>[displayed_text]</font>"
	else
		maptext = null

/obj/effect/countdown/Destroy()
	attached_to = null
	STOP_PROCESSING(SSfastprocess, src)
	. = ..()

/obj/effect/countdown/ex_act(severity, target) //immune to explosions
	return

/obj/effect/countdown/singularity_pull()
	return

/obj/effect/countdown/singularity_act()
	return

/obj/effect/countdown/syndicatebomb
	name = "syndicate bomb countdown"

/obj/effect/countdown/syndicatebomb/get_value()
	var/obj/machinery/syndicatebomb/S = attached_to
	if(!istype(S))
		return
	else if(S.active)
		return S.seconds_remaining()

/obj/effect/countdown/nuclearbomb
	name = "nuclear bomb countdown"
	color = "#81FF14"

/obj/effect/countdown/nuclearbomb/get_value()
	var/obj/machinery/nuclearbomb/N = attached_to
	if(!istype(N))
		return
	else if(N.timing)
		return round(N.get_time_left(), 1)

/obj/effect/countdown/supermatter
	name = "supermatter damage"
	text_size = 1
	color = "#00ff80"

/obj/effect/countdown/supermatter/get_value()
	var/obj/machinery/power/supermatter_crystal/S = attached_to
	if(!istype(S))
		return
	return "<div align='center' valign='middle' style='position:relative; top:0px; left:0px'>[round(S.get_integrity(), 1)]%</div>"

/obj/effect/countdown/doomsday
	name = "doomsday countdown"

/obj/effect/countdown/doomsday/get_value()
	var/obj/machinery/doomsday_device/DD = attached_to
	if(!istype(DD))
		return
	else if(DD.timing)
		return "<div align='center' valign='middle' style='position:relative; top:0px; left:0px'>[DD.seconds_remaining()]</div>"

/obj/effect/countdown/anomaly
	name = "anomaly countdown"

/obj/effect/countdown/anomaly/get_value()
	var/obj/effect/anomaly/A = attached_to
	if(!istype(A))
		return
	else
		var/time_left = max(0, (A.death_time - world.time) / 10)
		return round(time_left)

/obj/effect/countdown/hourglass
	name = "hourglass countdown"

/obj/effect/countdown/hourglass/get_value()
	var/obj/item/hourglass/H = attached_to
	if(!istype(H))
		return
	else
		var/time_left = max(0, (H.finish_time - world.time) / 10)
		return round(time_left)

/obj/effect/countdown/arena
	invisibility = 0
	name = "arena countdown"

/obj/effect/countdown/arena/get_value()
	var/obj/machinery/arena_spawn/A = attached_to
	if(!istype(A))
		return
	else
		var/obj/machinery/computer/arena/C = A.get_controller()
		var/time_left = max(0, (C.start_time - world.time) / 10)
		return round(time_left)

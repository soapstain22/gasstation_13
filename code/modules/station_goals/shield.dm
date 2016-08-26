//Station Shield
// A chain of satellites encircles the station
// Satellites be actived to generate a shield that will block unorganic matter from passing it.
/datum/station_goal/station_shield
	name = "Station Shield"

/datum/station_goal/station_shield/get_report()
	return {"The station is located in a zone full of space debris.
			 We have a prototype shielding system you will deploy to reduce collision related accidents.

			 You can order the satellites and control systems through cargo shuttle.
			 "}


/datum/station_goal/station_shield/on_report()
	//Unlock 
	var/datum/supply_pack/P = SSshuttle.supply_packs[/datum/supply_pack/misc/shield_sat]
	P.special_enabled = TRUE

	P = SSshuttle.supply_packs[/datum/supply_pack/misc/shield_sat_control]
	P.special_enabled = TRUE

/datum/station_goal/station_shield/check_completion()
	var/list/coverage = list()
	for(var/obj/machinery/satellite/meteor_shield/A in machines)
		if(!A.active || A.z != ZLEVEL_STATION)
			continue
		coverage |= view(A.kill_range,A)
	if(coverage.len >= 400)
		return TRUE
	return FALSE


/obj/item/weapon/circuitboard/machine/computer/sat_control
	name = "circuit board (Satellite Network Control)"
	build_path = /obj/machinery/computer/sat_control
	origin_tech = "engineering=3"

/obj/machinery/computer/sat_control
	name = "Satellite control"
	desc = "Used to control the satellite network."
	circuit = /obj/item/weapon/circuitboard/machine/computer/sat_control
	var/notice

/obj/machinery/computer/sat_control/ui_interact(mob/user, ui_key = "main", datum/tgui/ui = null, force_open = 0, \
										datum/tgui/master_ui = null, datum/ui_state/state = physical_state)
	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "sat_control", name, 400, 305, master_ui, state)
		ui.open()

/obj/machinery/computer/sat_control/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("toggle")
			toggle(params["id"])
			. = TRUE

/obj/machinery/computer/sat_control/proc/toggle(id)
	for(var/obj/machinery/satellite/S in machines)
		if(S.id == id && S.z == z)
			S.toggle()
	return

/obj/machinery/computer/sat_control/ui_data()
	var/list/data = list()
	
	data["satellites"] = list()
	for(var/obj/machinery/satellite/S in machines)
		data["satellites"] += list(list(
			"id" = S.id,
			"active" = S.active,
			"mode" = S.mode
		))
	data["notice"] = notice
	return data


/obj/machinery/satellite
	name = "Defunct Satellite"
	icon = 'icons/obj/machines/satellite.dmi'
	icon_state = "sat_inactive"
	var/mode = "NTPROBEV0.8"
	var/active = FALSE
	density = 1
	var/static/gid = 0
	var/id = 0

/obj/machinery/satellite/New()
	..()
	id = gid++

/obj/machinery/satellite/interact(mob/user)
	user << "You [active ? "deactivate": "activate"] the [src]"
	toggle()

/obj/machinery/satellite/proc/toggle()
	active = !active
	if(active)
		animate(src, pixel_y = 2, time = 10, loop = -1)
		anchored = 1
	else
		animate(src, pixel_y = 0, time = 10)
		anchored = 0
	update_icon()

/obj/machinery/satellite/update_icon()
	icon_state = active ? "sat_active" : "sat_inactive"

/obj/machinery/satellite/attackby(obj/item/weapon/W, mob/user, params)
	if(istype(W, /obj/item/device/multitool))
		user << "// NTSAT-[id] // Mode : [active ? "PRIMARY" : "STANDBY"] //[emagged ? "DEBUG_MODE //" : ""]"
	else
		..()

/obj/machinery/satellite/meteor_shield
	name = "Meteor Shield Satellite"
	mode = "M-SHIELD"
	var/kill_range = 10

/obj/machinery/satellite/meteor_shield/process()
	if(!active)
		return
	for(var/obj/effect/meteor/M in meteor_list)
		if(M.z != z)
			continue
		if(get_dist(M,src) > kill_range)
			return
		if(!emagged)
			qdel(M)

/obj/machinery/satellite/meteor_shield/emag_act()
	if(!emagged)
		emagged = 1
		var/datum/round_event_control/E = locate(/datum/round_event_control/meteor_wave) in SSevent.control
		if(E)
			E.weight *= 2
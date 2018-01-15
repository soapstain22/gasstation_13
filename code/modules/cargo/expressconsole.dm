#define MAX_EMAG_ROCKETS 8

/obj/machinery/computer/cargo/express
	name = "express supply console"
	desc = "This console allows the user to purchase a package for double the price,\
		with 1/40th of the delivery time: made possible by NanoTrasen's new \"Drop Pod Railgun\".\
		All sales are near instantaneous - please choose carefully"
	icon_screen = "supply_express"
	circuit = /obj/item/circuitboard/computer/cargo/express
	blockade_warning = "Bluespace instability detected. Delivery impossible."
	req_access = list(ACCESS_QM)
	var/message
	var/locked = TRUE
	var/list/meme_pack_data
	
/obj/machinery/computer/cargo/express/Initialize()
	. = ..()
	oh_shit_im_sorry()


/obj/machinery/computer/cargo/express/attackby(obj/item/W, mob/living/user, params)
	..()
	if((istype(W, /obj/item/card/id) || istype(W, /obj/item/device/pda)) && allowed(user))
		locked = !locked
		to_chat(user, "<span class='notice'>You [locked ? "lock" : "unlock"] the interface.</span>")

/obj/machinery/computer/cargo/express/emag_act(mob/living/user)
	if(emagged)
		return
	user.visible_message("<span class='warning'>[user] swipes a suspicious card through [src]!</span>",
	"<span class='notice'>You change the routing protocols, allowing the Drop Pod to land anywhere on the station.</span>")
	emagged = TRUE
	// This also sets this on the circuit board
	var/obj/item/circuitboard/computer/cargo/board = circuit
	board.emagged = TRUE
	oh_shit_im_sorry()
	
/obj/machinery/computer/cargo/express/proc/oh_shit_im_sorry()
	LAZYINITLIST(meme_pack_data)
	LAZYCLEARLIST(meme_pack_data)
	for(var/pack in SSshuttle.supply_packs)
		var/datum/supply_pack/P = SSshuttle.supply_packs[pack]
		if(!meme_pack_data[P.group])
			meme_pack_data[P.group] = list(
				"name" = P.group,
				"packs" = list()
			)
		if((P.hidden) || (P.special))//no fun allowed
			continue
		if(!emagged && P.contraband)
			continue
		meme_pack_data[P.group]["packs"] += list(list(
			"name" = P.name,
			"cost" = P.cost * 2, //displays twice the normal cost
			"id" = pack
		))

/obj/machinery/computer/cargo/express/ui_interact(mob/living/user, ui_key = "main", datum/tgui/ui = null, force_open = 0, datum/tgui/master_ui = null, datum/ui_state/state = GLOB.default_state) // Remember to use the appropriate state.
	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "cargo_express", name, 1000, 800, master_ui, state)
		ui.open()


/obj/machinery/computer/cargo/express/ui_data(mob/user)
	var/list/data = list()
	data["locked"] = locked
	data["siliconUser"] = user.has_unlimited_silicon_privilege
	data["points"] = SSshuttle.points
	data["supplies"] = list()
	message = "For normally priced items, please use the standard Supply or Request Console. \
		Sales are near-instantaneous - please choose carefully."
	if(SSshuttle.supplyBlocked)
		message = blockade_warning
	if(emagged)
		message = "(&!#@ERROR: ROUTING_#PROTOCOL MALF(*CT#ON. $UG%ESTE@ ACT#0N: !^/PULS3-%E)ET CIR*)ITB%ARD."
	
	data["message"] = message
	if(meme_pack_data)
		data["supplies"] = meme_pack_data
	else
		oh_shit_im_sorry()
		data["supplies"] = meme_pack_data
				
	return data

/obj/machinery/computer/cargo/express/ui_act(action, params, datum/tgui/ui)
	switch(action)
		if("add")//Generate Supply Order first
			var/id = text2path(params["id"])
			var/datum/supply_pack/pack = SSshuttle.supply_packs[id]
			if(!istype(pack))
				return
			var/name = "*None Provided*"
			var/rank = "*None Provided*"
			var/ckey = usr.ckey
			if(ishuman(usr))
				var/mob/living/carbon/human/H = usr
				name = H.get_authentification_name()
				rank = H.get_assignment()
			else if(issilicon(usr))
				name = usr.real_name
				rank = "Silicon"
			var/reason = ""
			var/list/empty_turfs
			var/area/landingzone
			var/datum/supply_order/SO = new(pack, name, rank, ckey, reason)
			if(!emagged)
				if(SO.pack.cost * 2 <= SSshuttle.points)
					landingzone = locate(/area/quartermaster/storage) in GLOB.sortedAreas
					for(var/turf/open/floor/T in landingzone.contents)
						if(is_blocked_turf(T))
							continue
						LAZYADD(empty_turfs, T)
						CHECK_TICK
					if(empty_turfs && empty_turfs.len)
						var/LZ = empty_turfs[rand(empty_turfs.len-1)]
						SSshuttle.points -= SO.pack.cost * 2
						new /obj/effect/BDPtarget(LZ, SO)
						. = TRUE
						update_icon()
			else
				if(SO.pack.cost * (1.2*MAX_EMAG_ROCKETS) <= SSshuttle.points) // bulk discount :^)
					landingzone = locate(pick(GLOB.the_station_areas)) in GLOB.sortedAreas
					for(var/turf/open/floor/T in landingzone.contents)
						if(is_blocked_turf(T))
							continue
						LAZYADD(empty_turfs, T)
						CHECK_TICK
					if(empty_turfs && empty_turfs.len)
						SSshuttle.points -= SO.pack.cost * (1.2*MAX_EMAG_ROCKETS)
						SO.generateRequisition(get_turf(src))
						for(var/i in 1 to MAX_EMAG_ROCKETS)
							var/LZ = empty_turfs[rand(empty_turfs.len-1)]
							LAZYREMOVE(empty_turfs, LZ)
							new /obj/effect/BDPtarget(LZ, SO)
							. = TRUE
							update_icon()
							CHECK_TICK

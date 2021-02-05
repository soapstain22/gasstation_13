/obj/machinery/nanite_programmer
	name = "nanite programmer"
	desc = "A device that can edit nanite program disks to adjust their functionality."
	var/obj/item/disk/nanite_program/disk
	var/datum/nanite_program/program
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "nanite_programmer"
	use_power = IDLE_POWER_USE
	anchored = TRUE
	density = TRUE
	flags_1 = HEAR_1
	circuit = /obj/item/circuitboard/machine/nanite_programmer

/obj/machinery/nanite_programmer/update_overlays()
	. = ..()
	SSvis_overlays.remove_vis_overlay(src, managed_vis_overlays)
	if((machine_stat & (NOPOWER|MAINT|BROKEN)) || panel_open)
		return
	SSvis_overlays.add_vis_overlay(src, icon, "nanite_programmer_on", layer, plane)
	SSvis_overlays.add_vis_overlay(src, icon, "nanite_programmer_on", EMISSIVE_LAYER, EMISSIVE_PLANE)

/obj/machinery/nanite_programmer/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/disk/nanite_program))
		var/obj/item/disk/nanite_program/N = I
		if(user.transferItemToLoc(N, src))
			to_chat(user, "<span class='notice'>You insert [N] into [src]</span>")
			playsound(src, 'sound/machines/terminal_insert_disc.ogg', 50, FALSE)
			if(disk)
				eject(user)
			disk = N
			program = N.program
	else
		..()

/obj/machinery/nanite_programmer/screwdriver_act(mob/living/user, obj/item/I)
	if(..())
		return TRUE

	return default_deconstruction_screwdriver(user, "nanite_programmer_t", "nanite_programmer", I)

/obj/machinery/nanite_programmer/crowbar_act(mob/living/user, obj/item/I)
	if(..())
		return TRUE

	return default_deconstruction_crowbar(I)

/obj/machinery/nanite_programmer/proc/eject(mob/living/user)
	if(!disk)
		return
	if(!istype(user) || !Adjacent(user) || !user.put_in_active_hand(disk))
		disk.forceMove(drop_location())
	disk = null
	program = null

/obj/machinery/nanite_programmer/AltClick(mob/user)
	if(disk && user.canUseTopic(src, !issilicon(user)))
		to_chat(user, "<span class='notice'>You take out [disk] from [src].</span>")
		eject(user)
	return

/obj/machinery/nanite_programmer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NaniteProgrammer", name)
		ui.open()

/obj/machinery/nanite_programmer/ui_data()
	var/list/data = list()
	data["has_disk"] = istype(disk)
	data["has_program"] = istype(program)
	if(program)
		data["name"] = program.name
		data["desc"] = program.desc
		data["use_rate"] = program.use_rate
		data["can_trigger"] = program.can_trigger
		data["trigger_cost"] = program.trigger_cost
		data["trigger_cooldown"] = program.trigger_cooldown / 10

		data["activated"] = program.activated
		data["activation_code"] = program.activation_code
		data["deactivation_code"] = program.deactivation_code
		data["kill_code"] = program.kill_code
		data["trigger_code"] = program.trigger_code
		data["timer_restart"] = program.timer_restart / 10
		data["timer_shutdown"] = program.timer_shutdown / 10
		data["timer_trigger"] = program.timer_trigger / 10
		data["timer_trigger_delay"] = program.timer_trigger_delay / 10

		var/list/extra_settings = program.get_extra_settings_frontend()
		data["extra_settings"] = extra_settings
		if(LAZYLEN(extra_settings))
			data["has_extra_settings"] = TRUE

	return data

/obj/machinery/nanite_programmer/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("eject")
			eject(usr)
			. = TRUE
		if("toggle_active")
			playsound(src, "terminal_type", 25, FALSE)
			program.activated = !program.activated //we don't use the activation procs since we aren't in a mob
			investigate_log("[key_name(usr)] edited [program.name]'s initial activation status into [program.activated ? "Activated" : "Deactivated"]", INVESTIGATE_NANITES)
			. = TRUE
		if("set_code")
			var/new_code = text2num(params["code"])
			playsound(src, "terminal_type", 25, FALSE)
			var/target_code = params["target_code"]
			switch(target_code)
				if("activation")
					program.activation_code = clamp(round(new_code, 1),0,9999)
					investigate_log("[key_name(usr)] edited [program.name]'s activation code into [program.activation_code]", INVESTIGATE_NANITES)
				if("deactivation")
					program.deactivation_code = clamp(round(new_code, 1),0,9999)
					investigate_log("[key_name(usr)] edited [program.name]'s deactivation code into [program.deactivation_code]", INVESTIGATE_NANITES)
				if("kill")
					program.kill_code = clamp(round(new_code, 1),0,9999)
					investigate_log("[key_name(usr)] edited [program.name]'s kill code into [program.kill_code]", INVESTIGATE_NANITES)
				if("trigger")
					program.trigger_code = clamp(round(new_code, 1),0,9999)
					investigate_log("[key_name(usr)] edited [program.name]'s trigger code into [program.trigger_code]", INVESTIGATE_NANITES)
			. = TRUE
		if("set_extra_setting")
			program.set_extra_setting(params["target_setting"], params["value"])
			investigate_log("[key_name(usr)] edited [program.name]'s extra setting '[params["target_setting"]]' into [params["value"]]", INVESTIGATE_NANITES)
			playsound(src, "terminal_type", 25, FALSE)
			. = TRUE
		if("set_restart_timer")
			var/timer = text2num(params["delay"])
			if(!isnull(timer))
				playsound(src, "terminal_type", 25, FALSE)
				timer = clamp(round(timer, 1), 0, 3600)
				timer *= 10 //convert to deciseconds
				program.timer_restart = timer
				investigate_log("[key_name(usr)] edited [program.name]'s restart timer into [timer/10] s", INVESTIGATE_NANITES)
			. = TRUE
		if("set_shutdown_timer")
			var/timer = text2num(params["delay"])
			if(!isnull(timer))
				playsound(src, "terminal_type", 25, FALSE)
				timer = clamp(round(timer, 1), 0, 3600)
				timer *= 10 //convert to deciseconds
				program.timer_shutdown = timer
				investigate_log("[key_name(usr)] edited [program.name]'s shutdown timer into [timer/10] s", INVESTIGATE_NANITES)
			. = TRUE
		if("set_trigger_timer")
			var/timer = text2num(params["delay"])
			if(!isnull(timer))
				playsound(src, "terminal_type", 25, FALSE)
				timer = clamp(round(timer, 1), 0, 3600)
				timer *= 10 //convert to deciseconds
				program.timer_trigger = timer
				investigate_log("[key_name(usr)] edited [program.name]'s trigger timer into [timer/10] s", INVESTIGATE_NANITES)
			. = TRUE
		if("set_timer_trigger_delay")
			var/timer = text2num(params["delay"])
			if(!isnull(timer))
				playsound(src, "terminal_type", 25, FALSE)
				timer = clamp(round(timer, 1), 0, 3600)
				timer *= 10 //convert to deciseconds
				program.timer_trigger_delay = timer
				investigate_log("[key_name(usr)] edited [program.name]'s trigger delay timer into [timer/10] s", INVESTIGATE_NANITES)
			. = TRUE

/obj/machinery/nanite_programmer/Hear(message, atom/movable/speaker, message_language, raw_message, radio_freq, list/spans, list/message_mods = list())
	. = ..()
	var/static/regex/when = regex("(?:^\\W*when|when\\W*$)", "i") //starts or ends with when
	if(findtext(raw_message, when) && !istype(speaker, /obj/machinery/nanite_programmer))
		say("When you code it!!")

/obj/item/paicard
	name = "personal AI device"
	icon = 'icons/obj/aicards.dmi'
	icon_state = "pai"
	inhand_icon_state = "electronic"
	worn_icon_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_BELT
	custom_premium_price = PAYCHECK_HARD * 1.25
	var/alert_cooldown ///don't spam alart messages.
	var/mob/living/silicon/pai/pai
	var/emotion_icon = "off" ///what emotion icon we have. handled in /mob/living/silicon/pai/Topic()
	resistance_flags = FIRE_PROOF | ACID_PROOF | INDESTRUCTIBLE

/obj/item/paicard/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] is staring sadly at [src]! [user.p_they()] can't keep living without real human intimacy!"))
	return OXYLOSS

/obj/item/paicard/Initialize(mapload)
	SSpai.pai_card_list += src
	. = ..()
	update_appearance()

/obj/item/paicard/vv_edit_var(vname, vval)
	. = ..()
	if(vname == NAMEOF(src, emotion_icon))
		update_appearance()

/obj/item/paicard/handle_atom_del(atom/A)
	if(A == pai) //double check /mob/living/silicon/pai/Destroy() if you change these.
		pai = null
		emotion_icon = initial(emotion_icon)
		update_appearance()
	return ..()

/obj/item/paicard/update_overlays()
	. = ..()
	. += "pai-[emotion_icon]"
	if(pai?.hacking_cable)
		. += "[initial(icon_state)]-connector"

/obj/item/paicard/Destroy()
	//Will stop people throwing friend pAIs into the singularity so they can respawn
	SSpai.pai_card_list -= src
	if(!QDELETED(pai))
		QDEL_NULL(pai)
	return ..()

/obj/item/paicard/attack_self(mob/user)
	if (!in_range(src, user))
		return
	user.set_machine(src)
	ui_interact()

/obj/item/paicard/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PaiDownload", name)
		ui.open()

/obj/item/paicard/ui_state(mob/user)
	return GLOB.inventory_state

/obj/item/paicard/ui_data(mob/user)
	. = ..()
	var/list/data = list()
	data["can_holo"] = pai.canholo
	data["dna"] = pai.master_dna
	data["emagged"] = pai.emagged
	data["laws"] = pai.laws.supplied
	data["master"] = pai.master
	data["name"] = pai.name
	data["radio"] = list()
	if(pai.radio)
		data["radio"]["transmit"] = pai.can_transmit
		data["radio"]["receive"] = pai.can_receive
	return data

/obj/item/paicard/ui_static_data(mob/user)
	. = ..()
	var/list/data = list()
	if(!pai)
		data["candidates"] = SSpai.candidates
	return data

/obj/item/paicard/ui_act(action, list/params)
	. = ..()
	if(.)
		return FALSE
	if(!usr || usr.stat)
		return FALSE
	if(loc != usr)
		return FALSE
	switch(action)
		if("request")
			if(!pai)
				SSpai.findPAI(src, usr)
		if("set_dna")
			if(pai.master_dna)
				return
			if(!iscarbon(usr))
				to_chat(usr, span_warning("You don't have any DNA, or your DNA is incompatible with this device!"))
			else
				var/mob/living/carbon/master = usr
				pai.master = master.real_name
				pai.master_dna = master.dna.unique_enzymes
				to_chat(pai, span_notice("You have been bound to a new master."))
				pai.emittersemicd = FALSE
		if("wipe_pai")
			var/confirm = tgui_alert(usr, "Are you CERTAIN you wish to delete the current personality? This action cannot be undone.", "Personality Wipe", list("Yes", "No"))
			if(confirm == "Yes")
				if(pai)
					to_chat(pai, span_warning("You feel yourself slipping away from reality."))
					to_chat(pai, span_danger("Byte by byte you lose your sense of self."))
					to_chat(pai, span_userdanger("Your mental faculties leave you."))
					to_chat(pai, span_rose("oblivion... "))
					qdel(pai)
		if("fix_speech")
			pai.stuttering = 0
			pai.slurring = 0
			pai.derpspeech = 0
		if("toggle_radio")
			var/transmitting = params["option"] == "transmit" //it can't be both so if we know it's not transmitting it must be receiving.
			var/transmit_holder = (transmitting ? WIRE_TX : WIRE_RX)
			if(transmitting)
				pai.can_transmit = !pai.can_transmit
			else //receiving
				pai.can_receive = !pai.can_receive
			pai.radio.wires.cut(transmit_holder)//wires.cut toggles cut and uncut states
			transmit_holder = (transmitting ? pai.can_transmit : pai.can_receive) //recycling can be fun!
			to_chat(usr,span_warning("You [transmit_holder ? "enable" : "disable"] your pAI's [transmitting ? "outgoing" : "incoming"] radio transmissions!"))
			to_chat(pai,span_warning("Your owner has [transmit_holder ? "enabled" : "disabled"] your [transmitting ? "outgoing" : "incoming"] radio transmissions!"))
		if("set_laws")
			var/newlaws = stripped_multiline_input(usr, "Enter any additional directives you would like your pAI personality to follow. Note that these directives will not override the personality's allegiance to its imprinted master. Conflicting directives will be ignored.", "pAI Directive Configuration", pai.laws.supplied[1], MAX_MESSAGE_LEN)
			if(newlaws && pai)
				pai.add_supplied_law(0,newlaws)
		if("toggle_holo")
			if(pai.canholo)
				to_chat(pai, span_userdanger("Your owner has disabled your holomatrix projectors!"))
				pai.canholo = FALSE
				to_chat(usr, span_warning("You disable your pAI's holomatrix!"))
			else
				to_chat(pai, span_boldnotice("Your owner has enabled your holomatrix projectors!"))
				pai.canholo = TRUE
				to_chat(usr, span_notice("You enable your pAI's holomatrix!"))
	return

// WIRE_SIGNAL = 1
// WIRE_RECEIVE = 2
// WIRE_TRANSMIT = 4

/obj/item/paicard/proc/setPersonality(mob/living/silicon/pai/personality)
	pai = personality
	emotion_icon = "null"
	update_appearance()

	playsound(loc, 'sound/effects/pai_boot.ogg', 50, TRUE, -1)
	audible_message("\The [src] plays a cheerful startup noise!")

/obj/item/paicard/proc/alertUpdate()
	if(!COOLDOWN_FINISHED(src, alert_cooldown))
		return
	COOLDOWN_START(src, alert_cooldown, 5 SECONDS)
	flick("[initial(icon_state)]-alert", src)
	playsound(src, 'sound/machines/ping.ogg', 30, TRUE)
	loc.visible_message(span_info("[src] flashes a message across its screen, \"Additional personalities available for download.\""), blind_message = span_notice("[src] vibrates with an alert."))

/obj/item/paicard/emp_act(severity)
	. = ..()
	if (. & EMP_PROTECT_SELF)
		return
	if(pai && !pai.holoform)
		pai.emp_act(severity)


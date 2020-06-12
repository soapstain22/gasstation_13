/*
 * Paper
 * also scraps of paper
 *
 * lipstick wiping is in code/game/objects/items/weapons/cosmetics.dm!
 */
/**
 ** Paper is now using markdown (like in github pull notes) for ALL rendering
 ** so we do loose a bit of functionality but we gain in easy of use of
 ** paper and getting rid of that crashing bug
 **/
/obj/item/paper
	var/const/MAX_PAPER_LENGTH = 1000
	var/const/MAX_PAPER_STAMPS = 30		// Too low?
	var/const/MAX_PAPER_STAMPS_OVERLAYS = 4
	var/const/MODE_READING = 0
	var/const/MODE_WRITING = 1
	var/const/MODE_STAMPING = 2

	name = "paper"
	gender = NEUTER
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "paper"
	inhand_icon_state = "paper"
	throwforce = 0
	w_class = WEIGHT_CLASS_TINY
	throw_range = 1
	throw_speed = 1
	pressure_resistance = 0
	slot_flags = ITEM_SLOT_HEAD
	body_parts_covered = HEAD
	resistance_flags = FLAMMABLE
	max_integrity = 50
	dog_fashion = /datum/dog_fashion/head
	drop_sound = 'sound/items/handling/paper_drop.ogg'
	pickup_sound =  'sound/items/handling/paper_pickup.ogg'
	grind_results = list(/datum/reagent/cellulose = 3)
	color = "white"
	/// What's actually written on the paper.
	var/info = ""

	/// The (text for the) stamps on the paper.
	var/list/stamps
	var/list/stamped

	/// This REALLY should be a componenet.  Basicly used during, april fools
	/// to honk at you
	var/rigged = 0
	var/spam_flag = 0
	///
	var/contact_poison // Reagent ID to transfer on contact
	var/contact_poison_volume = 0

	var/ui_x = 600
	var/ui_y = 800
	/// When the sheet can be "filled out"
	var/form_sheet = FALSE
	/// What edit mode we are in and who is
	/// writing on it right now
	var/edit_mode = MODE_READING
	var/mob/living/edit_usr = null
	/// Setup for writing to a sheet
	var/pen_color = "black"
	var/pen_font = ""
	var/is_crayon = FALSE
	/// Setup for stamping a sheet
	var/obj/item/stamp/current_stamp = null
	var/stamp_class = null

/**
 ** This proc copies this sheet of paper to a new
 ** sheet,  Makes it nice and easy for carbon and
 ** the copyer machine
 **/
/obj/item/paper/proc/copy()
	var/obj/item/paper/N = new(arglist(args))
	N.info = info
	N.color = color
	N.update_icon_state()
	N.stamps = stamps
	N.stamped = stamped.Copy()
	copy_overlays(N, TRUE)
	return N

/**
 ** This proc sets the text of the paper and updates the
 ** icons.  You can modify the pen_color after if need
 ** be.
 **/
/obj/item/paper/proc/setText(text)
	info = text
	update_icon_state()

/obj/item/paper/pickup(user)
	if(contact_poison && ishuman(user))
		var/mob/living/carbon/human/H = user
		var/obj/item/clothing/gloves/G = H.gloves
		if(!istype(G) || G.transfer_prints)
			H.reagents.add_reagent(contact_poison,contact_poison_volume)
			contact_poison = null
	. = ..()


/obj/item/paper/Initialize()
	. = ..()
	pixel_y = rand(-8, 8)
	pixel_x = rand(-9, 9)
	update_icon_state()


/obj/item/paper/update_icon_state()
	if(resistance_flags & ON_FIRE)
		icon_state = "paper_onfire"
		return
	if(info)
		icon_state = "paper_words"
		return
	icon_state = "paper"

/obj/item/paper/ui_base_html(html)
	/// This might change in a future PR
	var/datum/asset/spritesheet/assets = get_asset_datum(/datum/asset/spritesheet/simple/paper)
	. = replacetext(html, "<!--customheadhtml-->", assets.css_tag())


/obj/item/paper/verb/rename()
	set name = "Rename paper"
	set category = "Object"
	set src in usr

	if(usr.incapacitated() || !usr.is_literate())
		return
	if(ishuman(usr))
		var/mob/living/carbon/human/H = usr
		if(HAS_TRAIT(H, TRAIT_CLUMSY) && prob(25))
			to_chat(H, "<span class='warning'>You cut yourself on the paper! Ahhhh! Ahhhhh!</span>")
			H.damageoverlaytemp = 9001
			H.update_damage_hud()
			return
	var/n_name = stripped_input(usr, "What would you like to label the paper?", "Paper Labelling", null, MAX_NAME_LEN)
	if((loc == usr && usr.stat == CONSCIOUS))
		name = "paper[(n_name ? text("- '[n_name]'") : null)]"
	add_fingerprint(usr)


/obj/item/paper/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] scratches a grid on [user.p_their()] wrist with the paper! It looks like [user.p_theyre()] trying to commit sudoku...</span>")
	return (BRUTELOSS)

/// ONLY USED FOR APRIL FOOLS

/obj/item/paper/proc/reset_spamflag()
	spam_flag = FALSE

/obj/item/paper/attack_self(mob/user)
	if(edit_mode != MODE_READING)
		log_paper("<span class='warning'>Not sure why, but there is an open ui and its in his hand?</span>")
		edit_mode = MODE_READING
		edit_usr = null
		return
	if(rigged && (SSevents.holidays && SSevents.holidays[APRIL_FOOLS]))
		if(!spam_flag)
			spam_flag = TRUE
			playsound(loc, 'sound/items/bikehorn.ogg', 50, TRUE)
			addtimer(CALLBACK(src, .proc/reset_spamflag), 20)
	. = ..()


/obj/item/paper/proc/clearpaper()
	info = ""
	stamps = null
	LAZYCLEARLIST(stamped)
	cut_overlays()
	update_icon_state()


/obj/item/paper/can_interact(mob/user)
	if(!..())
		return FALSE
	if(resistance_flags & ON_FIRE)		/// Are we on fire?  Hard ot read if so
		return FALSE
	if(user.is_blind())					/// Even harder to read if your blind...braile? humm
		return FALSE
	return user.can_read(src)			// checks if the user can read.


/obj/item/paper/attackby(obj/item/P, mob/living/carbon/human/user, params)
	if(istype(P, /obj/item/pen) || istype(P, /obj/item/toy/crayon))
		if(!form_sheet && length(info) >= 1000) // Sheet must have less than 1000 charaters
			to_chat(user, "<span class='warning'>This sheet of paper is full!</span>")
			return
		if(edit_mode != MODE_READING)
			to_chat(user, "<span class='warning'>[edit_usr.real_name] is already working on this sheet!</span>")
			return

		edit_mode = MODE_WRITING
		edit_usr = user
		/// should a crayon be in the same subtype as a pen?  How about a brush or charcoal?
		/// TODO:  Convert all writing stuff to one type, /obj/item/art_tool maybe?
		is_crayon = istype(P, /obj/item/toy/crayon);
		if(is_crayon)
			var/obj/item/toy/crayon/PEN = P
			pen_font = CRAYON_FONT
			pen_color = PEN.paint_color
		else
			var/obj/item/pen/PEN = P
			pen_font = PEN.font
			pen_color = PEN.colour

		ui_interact(user)
		return
	else if(istype(P, /obj/item/stamp))

		if(edit_mode != MODE_READING)
			to_chat(user, "<span class='warning'>[edit_usr.real_name] is already working on this sheet!</span>")
			return

				/// Assume we are just reading it)
		edit_mode = MODE_STAMPING	// we are read only becausse the sheet is full
		edit_usr = user
		current_stamp = P

		var/datum/asset/spritesheet/sheet = get_asset_datum(/datum/asset/spritesheet/simple/paper)
		stamp_class = sheet.icon_class_name(P.icon_state)

		to_chat(user, "<span class='notice'>You ready your stamp over the paper! </span>")

		ui_interact(user)
		return /// Normaly you just stamp, you don't need to read the thing
	else if(P.get_temperature())
		if(HAS_TRAIT(user, TRAIT_CLUMSY) && prob(10))
			user.visible_message("<span class='warning'>[user] accidentally ignites [user.p_them()]self!</span>", \
								"<span class='userdanger'>You miss the paper and accidentally light yourself on fire!</span>")
			user.dropItemToGround(P)
			user.adjust_fire_stacks(1)
			user.IgniteMob()
			return

		user.dropItemToGround(src)
		user.visible_message("<span class='danger'>[user] lights [src] ablaze with [P]!</span>", "<span class='danger'>You light [src] on fire!</span>")
		fire_act()
	else
		if(edit_mode != MODE_READING)
			to_chat(user, "You look at the sheet while [edit_usr.real_name] edits it")
		else
			edit_mode = MODE_READING
		ui_interact(user)	/// The other ui will be created with just read mode outside of this

	. = ..()

/obj/item/paper/fire_act(exposed_temperature, exposed_volume)
	..()
	if(!(resistance_flags & FIRE_PROOF))
		add_overlay("paper_onfire_overlay")
		info = "[stars(info)]"


/obj/item/paper/extinguish()
	..()
	cut_overlay("paper_onfire_overlay")

/obj/item/paper/ui_interact(mob/user, ui_key = "main", datum/tgui/ui = null, force_open = FALSE, datum/tgui/master_ui = null, datum/ui_state/state = GLOB.default_state)
	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)
	if(!ui)
		var/datum/asset/assets = get_asset_datum(/datum/asset/spritesheet/simple/paper)
		assets.send(user)
		/// The x size is because we double the width for the editor
		ui = new(user, src, ui_key, "PaperSheet", name, ui_x, ui_y, master_ui, state)
		ui.set_autoupdate(FALSE)
		ui.open()

/obj/item/paper/ui_close(mob/user)
	/// close the editing window and change the mode
	if(edit_usr != null && user == edit_usr)
		edit_mode = MODE_READING
		edit_usr = null
		current_stamp = null
		stamp_class = null

	. = ..()

/obj/item/paper/proc/ui_force_close()
	var/datum/tgui/ui = SStgui.try_update_ui(usr, src, "main");
	if(ui)
		ui.close()

/obj/item/paper/proc/ui_update()
	var/datum/tgui/ui = SStgui.try_update_ui(usr, src, "main");
	if(ui)
		ui.update()

/obj/item/paper/ui_data(mob/user)
	var/list/data = list()
	// Should all this go in static data and just do a forced update?
	data["text"] = info
	data["max_length"] = MAX_PAPER_LENGTH
	data["paper_state"] = icon_state	/// TODO: show the sheet will bloodied or crinkling?
	data["paper_color"] = !color || color == "white" ? "#FFFFFF" : color	// color might not be set
	data["stamps"] = stamps

	if(edit_usr != null && user != edit_usr)
		data["edit_mode"] = MODE_READING		/// Eveyone else is just an observer
	else
		data["edit_mode"] = edit_mode

	// pen info for editing
	data["is_crayon"] = is_crayon
	data["pen_font"] = pen_font
	data["pen_color"] = pen_color

	// stamping info for..stamping
	data["stamp_class"] = stamp_class

	return data

/obj/item/paper/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("stamp")
			var/stamp_x = text2num(params["x"])
			var/stamp_y = text2num(params["y"])
			var/stamp_r = text2num(params["r"])	// rotation in degrees

			if (isnull(stamps))
				stamps = new/list()
			if(stamps.len < MAX_PAPER_STAMPS)
				/// I hate byond when dealing with freaking lists
				stamps += list(list(stamp_class, stamp_x,  stamp_y,stamp_r))	/// WHHHHY

				/// This does the overlay stuff
				if (isnull(stamped))
					stamped = new/list()
				if(stamped.len < MAX_PAPER_STAMPS_OVERLAYS)
					var/mutable_appearance/stampoverlay = mutable_appearance('icons/obj/bureaucracy.dmi', "paper_[current_stamp.icon_state]")
					stampoverlay.pixel_x = rand(-2, 2)
					stampoverlay.pixel_y = rand(-3, 2)
					add_overlay(stampoverlay)
					LAZYADD(stamped, current_stamp.icon_state)

				edit_usr.visible_message("<span class='notice'>[edit_usr] stamps [src] with [current_stamp]!</span>", "<span class='notice'>You stamp [src] with [current_stamp]!</span>")
			else
				to_chat(usr, pick("You try to stamp but you miss!", "There is no where else you can stamp!"))

			ui_update()
			. = TRUE

		if("save")
			var/in_paper = params["text"]
			var/paper_len = length(in_paper) + length(info)

			if(paper_len > MAX_PAPER_LENGTH)
				/// Side note, the only way we should get here is if
				/// the javascript was modified, somehow, outside of
				/// byond.
				log_paper("[key_name(edit_usr)] writing to paper [name], and overwrote it by [MAX_PAPER_LENGTH-paper_len], aborting")
				ui_force_close()
			else if(paper_len == 0)
				to_chat(usr, pick("Writing block strikes again!", "You forgot to write anthing!"))
				ui_force_close()
			else
				/// First, fix the fonts depending on the pen used
				if(is_crayon)
					info += "<font face=\"[pen_font]\" color=[pen_color]><b>[in_paper]</b></font>"
				else
					info += "<font face=\"[pen_font]\" color=[pen_color]>[in_paper]</font>"
				/// Next find the sign marker and replace it with somones sig
				info = regex("%s(?:ign)?(?=\\s|$)", "igm").Replace(info, "<font face=\"[SIGNFONT]\"><i>[edit_usr.real_name]</i></font>")
				/// Do the same with form fields
 				info = regex("%f(?:ield)?(?=\\s|$)", "igm").Replace(info, "<span class=\"paper_field\"></span>")
				log_paper("[key_name(edit_usr)] writing to paper [name]")
				to_chat(usr, "You have added to your paper masterpiece!");
				/// Switch ui to reading mode


				ui_update()
				update_icon()
			edit_mode = MODE_READING
			edit_usr = null
			
			. = TRUE



/*
 * Construction paper
 */

/obj/item/paper/construction

/obj/item/paper/construction/Initialize()
	. = ..()
	color = pick("FF0000", "#33cc33", "#ffb366", "#551A8B", "#ff80d5", "#4d94ff")

/*
 * Natural paper
 */

/obj/item/paper/natural/Initialize()
	. = ..()
	color = "#FFF5ED"

/obj/item/paper/crumpled
	name = "paper scrap"
	icon_state = "scrap"
	slot_flags = null

/obj/item/paper/crumpled/update_icon_state()
	return

/obj/item/paper/crumpled/bloody
	icon_state = "scrap_bloodied"

/obj/item/paper/crumpled/muddy
	icon_state = "scrap_mud"

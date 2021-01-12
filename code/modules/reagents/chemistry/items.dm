///if the pHmeter gives a detailed output
#define DETAILED_CHEM_OUTPUT 1 
///if the pH meter gives a shorter output
#define SHORTENED_CHEM_OUTPUT 0 

/*
* a pH booklet that contains pH paper pages that will change color depending on the pH of the reagents datum it's attacked onto
*/
/obj/item/pHbooklet
	name = "pH indicator booklet"
	desc = "A booklet containing paper soaked in universal indicator."
	icon_state = "pHbooklet"
	icon = 'icons/obj/chemical.dmi'
	item_flags = NOBLUDGEON
	resistance_flags = FLAMMABLE
	w_class = WEIGHT_CLASS_TINY
	///How many pages the booklet holds
	var/number_of_pages = 50

//A little janky with pockets
/obj/item/pHbooklet/attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(user.get_held_index_of_item(src))//Does this check pockets too..?
		if(number_of_pages == 50)
			icon_state = "pHbooklet_open"
		if(number_of_pages >= 1)
			var/obj/item/pHpaper/P = new /obj/item/pHpaper
			P.add_fingerprint(user)
			P.forceMove(user.loc)
			user.put_in_active_hand(P)
			to_chat(user, "<span class='notice'>You take [P] out of \the [src].</span>")
			number_of_pages--
			playsound(user.loc, 'sound/items/poster_ripped.ogg', 50, TRUE)
			add_fingerprint(user)
			if(number_of_pages == 0)
				icon_state = "pHbooklet_empty"
			return
		else
			to_chat(user, "<span class='warning'>[src] is empty!</span>")
			add_fingerprint(user)
			return
	. = ..()
	var/I = user.get_active_held_item()
	if(!I)
		user.put_in_active_hand(src)

/obj/item/pHbooklet/MouseDrop()
	var/mob/living/user = usr
	if(number_of_pages >= 1)
		var/obj/item/pHpaper/P = new /obj/item/pHpaper
		P.add_fingerprint(user)
		P.forceMove(user)
		user.put_in_active_hand(P)
		to_chat(user, "<span class='notice'>You take [P] out of \the [src].</span>")
		number_of_pages--
		playsound(user.loc, 'sound/items/poster_ripped.ogg', 50, TRUE)
		add_fingerprint(user)
		if(number_of_pages == 0)
			icon_state = "pHbookletEmpty"
		return
	else
		to_chat(user, "<span class='warning'>[src] is empty!</span>")
		add_fingerprint(user)
		return

/*
* pH paper will change color depending on the pH of the reagents datum it's attacked onto
*/
/obj/item/pHpaper
	name = "pH indicator strip"
	desc = "A piece of paper that will change colour depending on the pH of a solution."
	icon_state = "pHpaper"
	icon = 'icons/obj/chemical.dmi'
	item_flags = NOBLUDGEON
	color = "#f5c352"	
	resistance_flags = FLAMMABLE
	w_class = WEIGHT_CLASS_TINY
	///If the paper was used, and therefore cannot change color again
	var/used = FALSE

/obj/item/pHpaper/afterattack(obj/item/reagent_containers/cont, mob/user, proximity)
	if(!istype(cont))
		return
	if(used == TRUE)
		to_chat(user, "<span class='warning'>[src] has already been used!</span>")
		return
	if(!LAZYLEN(cont.reagents.reagent_list))
		return
	switch(round(cont.reagents.pH, 1))
		if(14 to INFINITY)
			color = "#462c83"
		if(13 to 14)
			color = "#63459b"
		if(12 to 13)
			color = "#5a51a2"
		if(11 to 12)
			color = "#3853a4"
		if(10 to 11)
			color = "#3f93cf"
		if(9 to 10)
			color = "#0bb9b7"
		if(8 to 9)
			color = "#23b36e"
		if(7 to 8)
			color = "#3aa651"
		if(6 to 7)
			color = "#4cb849"
		if(5 to 6)
			color = "#b5d335"
		if(4 to 5)
			color = "#f7ec1e"
		if(3 to 4)
			color = "#fbc314"
		if(2 to 3)
			color = "#f26724"
		if(1 to 2)
			color = "#ef1d26"
		if(-INFINITY to 1)
			color = "#c6040c"
	desc += " The paper looks to be around a pH of [round(cont.reagents.pH, 1)]"
	name = "used [name]"
	used = TRUE

/*
* pH meter that will give a detailed or truncated analysis of all the reagents in of an object with a reagents datum attached to it. Only way of detecting purity for now.
*/
/obj/item/pHmeter
	name = "Chemistry Analyser"
	desc = "A a electrode attached to a small circuit box that will tell you the pH of a solution. The screen currently displays nothing."
	icon_state = "pHmeter"
	icon = 'icons/obj/chemical.dmi'
	resistance_flags = FLAMMABLE
	w_class = WEIGHT_CLASS_TINY
	///level of detail for output for the meter
	var/scanmode = DETAILED_CHEM_OUTPUT 

/obj/item/pHmeter/attack_self(mob/user)
	if(!scanmode)
		to_chat(user, "<span class='notice'>You switch the chemical analyzer to give a detailed report.</span>")
		scanmode = DETAILED_CHEM_OUTPUT
	else
		to_chat(user, "<span class='notice'>You switch the chemical analyzer to give a reduced report.</span>")
		scanmode = SHORTENED_CHEM_OUTPUT

/obj/item/pHmeter/afterattack(atom/A, mob/user, proximity)
	. = ..()
	if(!istype(A, /obj/item/reagent_containers))
		return
	var/obj/item/reagent_containers/cont = A
	if(LAZYLEN(cont.reagents.reagent_list) == null)
		return
	var/out_message
	to_chat(user, "<i>The chemistry meter beeps and displays:</i>")
	out_message += "<span class='notice'><b>Total volume: [round(cont.volume, 0.01)] Total pH: [round(cont.reagents.pH, 0.01)]\n"
	out_message += "Chemicals found in the beaker:</b>\n"
	if(cont.reagents.is_reacting)
		out_message += "<span class='warning'>A reaction appears to be occuring currently.<span class='notice'>\n"
	for(var/datum/reagent/R in cont.reagents.reagent_list)
		out_message += "<b>[round(R.volume, 0.01)]u of [R.name]</b>, <b>Purity:</b> [round(R.purity, 0.01)], [(scanmode?"[(R.overdose_threshold?"<b>Overdose:</b> [R.overdose_threshold]u, ":"")][(R.addiction_threshold?"<b>Addiction:</b> [R.addiction_threshold]u, ":"")]<b>Base pH:</b> [R.pH].":"<b>Base pH:</b> [R.pH].")]\n"
		if(scanmode)
			out_message += "<b>Analysis:</b> [R.description]\n"
	to_chat(user, "[out_message]</span>")
	desc = "An electrode attached to a small circuit box that will analyse a beaker. It can be toggled to give a reduced or extended report. The screen currently displays detected vol: [round(cont.volume, 0.01)] detected pH:[round(cont.reagents.pH, 0.1)]."

/*

Miscellaneous traitor devices

BATTERER

RADIOACTIVE MICROLASER

C-4 DETONATOR

*/

/*

The Batterer, like a flashbang but 50% chance to knock people over. Can be either very
effective or pretty fucking useless.

*/

/obj/item/device/batterer
	name = "mind batterer"
	desc = "A strange device with twin antennas."
	icon_state = "batterer"
	throwforce = 5
	w_class = 1
	throw_speed = 3
	throw_range = 7
	flags = CONDUCT
	item_state = "electronic"
	origin_tech = "magnets=3;combat=3;syndicate=3"

	var/times_used = 0 //Number of times it's been used.
	var/max_uses = 2


/obj/item/device/batterer/attack_self(mob/living/carbon/user, flag = 0, emp = 0)
	if(!user) 	return
	if(times_used >= max_uses)
		user << "<span class='danger'>The mind batterer has been burnt out!</span>"
		return

	add_logs(user, null, "knocked down people in the area", src)

	for(var/mob/living/carbon/human/M in urange(10, user, 1))
		if(prob(50))

			M.Weaken(rand(10,20))
			if(prob(25))
				M.Stun(rand(5,10))
			M << "<span class='userdanger'>You feel a tremendous, paralyzing wave flood your mind.</span>"

		else
			M << "<span class='userdanger'>You feel a sudden, electric jolt travel through your head.</span>"

	playsound(src.loc, 'sound/misc/interference.ogg', 50, 1)
	user << "<span class='notice'>You trigger [src].</span>"
	times_used += 1
	if(times_used >= max_uses)
		icon_state = "battererburnt"

/*
		The radioactive microlaser, a device disguised as a health analyzer used to irradiate people.

		The strength of the radiation is determined by the 'intensity' setting, while the delay between
	the scan and the irradiation kicking in is determined by the wavelength.

		Each scan will cause the microlaser to have a brief cooldown period. Higher intensity will increase
	the cooldown, while higher wavelength will decrease it.

		Wavelength is also slightly increased by the intensity as well.
*/

/obj/item/device/rad_laser
	name = "health analyzer"
	icon_state = "health"
	item_state = "analyzer"
	desc = "A hand-held body scanner able to distinguish vital signs of the subject. A strange microlaser is hooked on to the scanning end."
	flags = CONDUCT
	slot_flags = SLOT_BELT
	throwforce = 3
	w_class = 1
	throw_speed = 3
	throw_range = 7
	materials = list(MAT_METAL=400)
	origin_tech = "magnets=3;biotech=5;syndicate=3"
	var/intensity = 5 // how much damage the radiation does
	var/wavelength = 10 // time it takes for the radiation to kick in, in seconds
	var/used = 0 // is it cooling down?

/obj/item/device/rad_laser/attack(mob/living/M, mob/living/user)
	if(!used)
		add_logs(user, M, "irradiated", src)
		user.visible_message("<span class='notice'>[user] has analyzed [M]'s vitals.</span>")
		var/cooldown = round(max(100,(((intensity*8)-(wavelength/2))+(intensity*2))*10))
		used = 1
		icon_state = "health1"
		handle_cooldown(cooldown) // splits off to handle the cooldown while handling wavelength
		spawn((wavelength+(intensity*4))*10)
			if(M)
				if(intensity >= 5)
					M.apply_effect(round(intensity/1.5), PARALYZE)
				M.rad_act(intensity*10)
	else
		user << "<span class='warning'>The radioactive microlaser is still recharging.</span>"

/obj/item/device/rad_laser/proc/handle_cooldown(cooldown)
	spawn(cooldown)
		used = 0
		icon_state = "health"

/obj/item/device/rad_laser/attack_self(mob/user)
	..()
	interact(user)

/obj/item/device/rad_laser/interact(mob/user)
	user.set_machine(src)

	var/cooldown = round(max(10,((intensity*8)-(wavelength/2))+(intensity*2)))
	var/dat = {"
	Radiation Intensity: <A href='?src=\ref[src];radint=-5'>-</A><A href='?src=\ref[src];radint=-1'>-</A> [intensity] <A href='?src=\ref[src];radint=1'>+</A><A href='?src=\ref[src];radint=5'>+</A><BR>
	Radiation Wavelength: <A href='?src=\ref[src];radwav=-5'>-</A><A href='?src=\ref[src];radwav=-1'>-</A> [(wavelength+(intensity*4))] <A href='?src=\ref[src];radwav=1'>+</A><A href='?src=\ref[src];radwav=5'>+</A><BR>
	Laser Cooldown: [cooldown] Seconds<BR>
	"}

	var/datum/browser/popup = new(user, "radlaser", "Radioactive Microlaser Interface", 400, 240)
	popup.set_content(dat)
	popup.open()

/obj/item/device/rad_laser/Topic(href, href_list)
	if(!usr.canUseTopic(src))
		return 1

	usr.set_machine(src)

	if(href_list["radint"])
		var/amount = text2num(href_list["radint"])
		amount += intensity
		intensity = max(1,(min(10,amount)))

	else if(href_list["radwav"])
		var/amount = text2num(href_list["radwav"])
		amount += wavelength
		wavelength = max(1,(min(120,amount)))

	attack_self(usr)
	add_fingerprint(usr)
	return

/obj/item/device/shadowcloak
	name = "cloaker belt"
	desc = "Makes you invisible for short periods of time. Recharges in darkness."
	icon = 'icons/obj/clothing/belts.dmi'
	icon_state = "utilitybelt"
	item_state = "utility"
	slot_flags = SLOT_BELT
	attack_verb = list("whipped", "lashed", "disciplined")

	var/mob/living/carbon/human/user = null
	var/charge = 300
	var/max_charge = 300
	var/on = 0
	var/old_alpha = 0
	actions_types = list(/datum/action/item_action/toggle)

/obj/item/device/shadowcloak/ui_action_click(mob/user)
	if(user.get_item_by_slot(slot_belt) == src)
		if(!on)
			Activate(usr)
		else
			Deactivate()
	return

/obj/item/device/shadowcloak/item_action_slot_check(slot, mob/user)
	if(slot == slot_belt)
		return 1

/obj/item/device/shadowcloak/proc/Activate(mob/living/carbon/human/user)
	if(!user)
		return
	user << "<span class='notice'>You activate [src].</span>"
	src.user = user
	SSobj.processing |= src
	old_alpha = user.alpha
	on = 1

/obj/item/device/shadowcloak/proc/Deactivate()
	user << "<span class='notice'>You deactivate [src].</span>"
	SSobj.processing.Remove(src)
	if(user)
		user.alpha = old_alpha
	on = 0
	user = null

/obj/item/device/shadowcloak/dropped(mob/user)
	..()
	if(user && user.get_item_by_slot(slot_belt) != src)
		Deactivate()

/obj/item/device/shadowcloak/process()
	if(user.get_item_by_slot(slot_belt) != src)
		Deactivate()
		return
	var/turf/T = get_turf(src)
	if(on)
		var/lumcount = T.get_lumcount()
		if(lumcount > 3)
			charge = max(0,charge - 25)//Quick decrease in light
		else
			charge = min(max_charge,charge + 50) //Charge in the dark
		animate(user,alpha = Clamp(255 - charge,0,255),time = 10)

/*
		The C-4 Remote Detonator. Slap a block of C-4 with it to tag that block. Use it in your hand to trigger that block.
		Once triggered, the block will beep and display a red warning message to people nearby. Two seconds after triggering,
		it will blow up. Tagged C-4 blocks also have a red display, instead of the usual green.
*/

/obj/item/device/c4detonator
	name = "strange remote"
	desc = "A small and intimidating device. It has a button on the center and an antenna on the top."
	icon = 'icons/obj/device.dmi'
	icon_state = "remotedetonator"
	item_state = "radio"
	w_class = 2
	slot_flags = SLOT_BELT
	force = 5
	attack_verb = list("triggered")//tfw cis scum manspreading near you
	origin_tech = "programming=4;materials=4;syndicate=3"
	var/obj/item/weapon/c4/linked_bomb

/obj/item/device/c4detonator/attack_self(mob/user)
	if(!linked_bomb)
		user << "<span class='warning'>The button on [src] won't go down all the way. It needs to be linked to something before it will work.</span>"
		return
	linked_bomb.visible_message("<span class = 'danger'>The [linked_bomb] starts beeping rapidly! It's going to explode!</span>")
	playsound(linked_bomb.loc, 'sound/items/timer.ogg', 30, 0)
	user << "<span class='notice'>You press the button on [src].</span>"
	spawn(20)
		if(!linked_bomb || linked_bomb.exploded)//check for the bomb again incase it was already detonated after being linked. prevents runtimes
			user << "<span class='warning'>[src] buzzes. It seems the linked bomb was already destroyed.</span>"
			linked_bomb = null
			icon_state = "remotedetonator"
			return
		linked_bomb.explode()
		linked_bomb = null
		icon_state = "remotedetonator"
		user << "<span class='notice'>[src] emits a soft beep. Detonation successful.</span>"

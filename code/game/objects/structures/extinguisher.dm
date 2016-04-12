/obj/structure/extinguisher_cabinet
	name = "extinguisher cabinet"
	desc = "A small wall mounted cabinet designed to hold a fire extinguisher."
	icon = 'icons/obj/wallmounts.dmi'
	icon_state = "extinguisher_closed"
	anchored = 1
	density = 0
	var/obj/item/weapon/extinguisher/has_extinguisher = new/obj/item/weapon/extinguisher
	var/opened = 0


/obj/structure/extinguisher_cabinet/ex_act(severity, target)
	switch(severity)
		if(1)
			qdel(src)
			return
		if(2)
			if(prob(50))
				if(has_extinguisher)
					has_extinguisher.loc = src.loc
				qdel(src)
				return
		if(3)
			return


/obj/structure/extinguisher_cabinet/attackby(obj/item/O, mob/user, params)
	if(isrobot(user) || isalien(user))
		return
	if(istype(O, /obj/item/weapon/extinguisher))
		if(!has_extinguisher && opened)
			if(!user.drop_item())
				return
			contents += O
			has_extinguisher = O
			user << "<span class='notice'>You place [O] in [src].</span>"
		else
			opened = !opened
	else
		opened = !opened
	update_icon()


/obj/structure/extinguisher_cabinet/attack_hand(mob/user)
	if(isrobot(user) || isalien(user))
		return
	if(has_extinguisher)
		user.put_in_hands(has_extinguisher)
		user << "<span class='notice'>You take [has_extinguisher] from [src].</span>"
		has_extinguisher = null
		opened = 1
	else
		opened = !opened
	update_icon()

/obj/structure/extinguisher_cabinet/attack_tk(mob/user)
	if(has_extinguisher)
		has_extinguisher.loc = loc
		user << "<span class='notice'>You telekinetically remove [has_extinguisher] from [src].</span>"
		has_extinguisher = null
		opened = 1
	else
		opened = !opened
	update_icon()

/obj/structure/extinguisher_cabinet/attack_paw(mob/user)
	attack_hand(user)
	return

/obj/structure/extinguisher_cabinet/AltClick(mob/living/user)
	if(user.incapacitated() || !Adjacent(user))
		return
	opened = !opened
	update_icon()

/obj/structure/extinguisher_cabinet/update_icon()
	if(!opened)
		icon_state = "extinguisher_closed"
		return
	if(has_extinguisher)
		if(istype(has_extinguisher, /obj/item/weapon/extinguisher/mini))
			icon_state = "extinguisher_mini"
		else
			icon_state = "extinguisher_full"
	else
		icon_state = "extinguisher_empty"

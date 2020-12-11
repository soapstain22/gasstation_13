/obj/structure/headpike
	name = "spooky head on a spear"
	desc = "When you really want to send a message."
	icon = 'icons/obj/structures.dmi'
	icon_state = "headpike"
	density = FALSE
	anchored = TRUE
	var/bonespear = FALSE
	var/obj/item/spear/spear
	var/obj/item/bodypart/head/victim

/obj/structure/headpike/bone //for bone spears
	icon_state = "headpike-bone"
	bonespear = TRUE

/obj/structure/headpike/Initialize(mapload)
	. = ..()
	if(mapload)
		CheckParts()

/obj/structure/headpike/CheckParts(list/parts_list)
	..()
	victim = locate(/obj/item/bodypart/head) in parts_list
	if(!victim) //likely a mapspawned one
		victim = new(src)
		victim.real_name = random_unique_name(prob(50))
	name = "[victim.real_name] on a spear"
	update_appearance()
	spear = locate(bonespear ? /obj/item/spear/bonespear : /obj/item/spear) in parts_list
	if(!spear)
		spear = bonespear ? new/obj/item/spear/bonespear(src) : new/obj/item/spear(src)

/obj/structure/headpike/Destroy()
	QDEL_NULL(victim)
	QDEL_NULL(spear)
	return ..()

/obj/structure/headpike/handle_atom_del(atom/A)
	if(A == victim)
		victim = null
	if(A == spear)
		spear = null
	deconstruct(TRUE)
	return ..()

/obj/structure/headpike/deconstruct(disassembled)
	if(!disassembled)
		return ..()
	if(victim)
		victim.forceMove(drop_location())
		victim = null
	if(spear)
		spear.forceMove(drop_location())
		spear = null
	return ..()

/obj/structure/headpike/Initialize()
	. = ..()
	pixel_x = rand(-8, 8)

/obj/structure/headpike/update_overlays()
	. = ..()
	var/obj/item/bodypart/head/H = locate() in contents
	if(H)
		var/mutable_appearance/MA = new()
		MA.copy_overlays(H)
		MA.pixel_y = 12
		. += H

/obj/structure/headpike/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	to_chat(user, "<span class='notice'>You take down [src].</span>")
	deconstruct(TRUE)

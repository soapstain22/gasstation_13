/obj/item/plate
	name = "plate"
	desc = "Holds food, powerful. Good for morale when you're not eating your spaghetti off of a desk."
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "plate"
	///How many things fit on this plate?
	var/max_items = 8
	var/max_x_offset = 4
	var/max_height_offset = 5
	var/placement_offset = -12


/obj/item/plate/attackby(obj/item/I, mob/user, params)
	if(!IS_EDIBLE(I))
		to_chat(user, "<span class='notice'>[src] is made for food, and food alone!</span>")
		return
	if(contents.len >= max_items)
		to_chat(user, "<span class='notice'>[src] can't fit more items!</span>")
		return
	var/list/modifiers = params2list(params)
	//Center the icon where the user clicked.
	if(!LAZYACCESS(modifiers, ICON_X) || !LAZYACCESS(modifiers, ICON_Y))
		return
	if(user.transferItemToLoc(I, src, silent = FALSE))
		I.pixel_x = clamp(text2num(LAZYACCESS(modifiers, ICON_X)) - 16, -max_x_offset, max_x_offset)
		I.pixel_y = min(text2num(LAZYACCESS(modifiers, ICON_Y)) + placement_offset, max_height_offset)
		to_chat(user, "<span class='notice'>You place [I] on [src].</span>")
		AddToPlate(I, user)
		update_appearance()
	else
		return ..()


/obj/item/plate/proc/AddToPlate(obj/item/item_to_plate, mob/user)
	vis_contents += item_to_plate
	item_to_plate.flags_1 |= IS_ONTOP_1
	RegisterSignal(item_to_plate, COMSIG_MOVABLE_MOVED, .proc/ItemMoved)
	RegisterSignal(item_to_plate, COMSIG_PARENT_QDELETING, .proc/ItemMoved)

/obj/item/plate/proc/ItemRemovedFromPlate(obj/item/removed_item)
	removed_item.flags_1 &= ~IS_ONTOP_1
	vis_contents -= removed_item
	UnregisterSignal(removed_item, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))

/obj/item/plate/proc/ItemMoved(obj/item/moved_item, atom/OldLoc, Dir, Forced)
	SIGNAL_HANDLER
	ItemRemovedFromPlate(moved_item)


/obj/item/plate/pre_attack(atom/A, mob/living/user, params)
	if(!iscarbon(A))
		return
	var/obj/item/object_to_eat = contents[1]
	A.attackby(object_to_eat, user)
	return TRUE //No normal attack

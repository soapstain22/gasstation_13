/obj/item/clothing/mask/bandana
	name = "botany bandana"
	desc = "A fine bandana with nanotech lining and a hydroponics pattern."
	w_class = WEIGHT_CLASS_TINY
	flags_cover = MASKCOVERSMOUTH
	flags_inv = HIDEFACE|HIDEFACIALHAIR|HIDESNOUT
	visor_flags_inv = HIDEFACE|HIDEFACIALHAIR|HIDESNOUT
	visor_flags_cover = MASKCOVERSMOUTH | PEPPERPROOF
	slot_flags = ITEM_SLOT_MASK
	adjusted_flags = ITEM_SLOT_HEAD
	icon_state = "bandbotany"
	species_exception = list(/datum/species/golem)

/obj/item/clothing/mask/bandana/attack_self(mob/user)
	adjustmask(user)

/obj/item/clothing/mask/bandana/AltClick(mob/user)
	. = ..()
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		if((C.get_item_by_slot(ITEM_SLOT_HEAD == src)) || (C.get_item_by_slot(ITEM_SLOT_MASK) == src))
			to_chat(user, span_warning("You can't tie [src] while wearing it!"))
			return
	if(slot_flags & ITEM_SLOT_HEAD)
		to_chat(user, span_warning("You must undo [src] before you can tie it into a neckerchief!"))
	else
		if(user.is_holding(src))
			var/obj/item/clothing/neck/neckerchief/nk = new(src)
			nk.name = "[name] neckerchief"
			nk.desc = "[desc] It's tied up like a neckerchief."
			nk.icon_state = icon_state
			nk.item_flags = item_flags
			nk.worn_icon = 'icons/misc/hidden.dmi' //hide underlying neckerchief object while it applies its own mutable appearance
			nk.sourceBandanaType = src.type
			var/currentHandIndex = user.get_held_index_of_item(src)
			user.transferItemToLoc(src, null)
			user.put_in_hand(nk, currentHandIndex)
			user.visible_message(span_notice("[user] ties [src] up like a neckerchief."), span_notice("You tie [src] up like a neckerchief."))
			qdel(src)
		else
			to_chat(user, span_warning("You must be holding [src] in order to tie it!"))

/obj/item/clothing/mask/bandana/durathread
	name = "durathread bandana"
	desc = "A bandana made from durathread, you wish it would provide some protection to its wearer, but it's far too thin..."
	icon_state = "banddurathread"

/obj/item/clothing/mask/bandana/color
	dying_key = DYE_REGISTRY_BANDANA
	name = "bandana"
	desc = "A fine bandana with nanotech lining."
	icon_state = "bandwhite"
	greyscale_config = /datum/greyscale_config/bandskull
	greyscale_config_worn = /datum/greyscale_config/bandana_worn
	greyscale_colors = "#555555"

/obj/item/clothing/mask/bandana/color/red
	name = "red bandana"
	desc = "A fine red bandana with nanotech lining."
	icon_state = "bandred"

/obj/item/clothing/mask/bandana/color/blue
	name = "blue bandana"
	desc = "A fine blue bandana with nanotech lining."
	icon_state = "bandblue"

/obj/item/clothing/mask/bandana/color/green
	name = "green bandana"
	desc = "A fine green bandana with nanotech lining."
	icon_state = "bandgreen"

/obj/item/clothing/mask/bandana/color/gold
	name = "gold bandana"
	desc = "A fine gold bandana with nanotech lining."
	icon_state = "bandgold"

/obj/item/clothing/mask/bandana/color/black
	name = "black bandana"
	desc = "A fine black bandana with nanotech lining."
	icon_state = "bandblack"

/obj/item/clothing/mask/bandana/color/white
	name = "white bandana"
	desc = "A fine white bandana with nanotech lining."
	icon_state = "bandwhite"

/obj/item/clothing/mask/bandana/color/skull
	name = "skull bandana"
	desc = "A fine bandana with nanotech lining and a skull emblem."
	icon_state = "bandskull"
	greyscale_config = /datum/greyscale_config/bandskull
	greyscale_config_worn = /datum/greyscale_config/bandskull_worn

/obj/item/clothing/mask/bandana/color/skull/black
	desc = "A fine black bandana with nanotech lining and a skull emblem."
	greyscale_colors = "#000000"

/obj/item/clothing/mask/breath
	desc = "A close-fitting mask that can be connected to an air supply."
	name = "breath mask"
	icon_state = "breath"
	inhand_icon_state = "m_mask"
	body_parts_covered = 0
	clothing_flags = MASKINTERNALS
	visor_flags = MASKINTERNALS
	w_class = WEIGHT_CLASS_SMALL
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 50, FIRE = 0, ACID = 0)
	actions_types = list(/datum/action/item_action/adjust)
	flags_cover = MASKCOVERSMOUTH
	visor_flags_cover = MASKCOVERSMOUTH
	resistance_flags = NONE

/obj/item/clothing/mask/breath/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("[user] is wrapping \the [src]'s tube around [user.p_their()] neck! It looks like [user.p_theyre()] trying to commit suicide!"))
	return OXYLOSS

/obj/item/clothing/mask/breath/attack_self(mob/user)
	adjustmask(user)

/obj/item/clothing/mask/breath/AltClick(mob/user)
	..()
	if(user.canUseTopic(src, be_close = TRUE, no_dexterity = TRUE, no_tk = FALSE, need_hands = !iscyborg(user)))
		adjustmask(user)

/obj/item/clothing/mask/breath/examine(mob/user)
	. = ..()
	. += span_notice("Alt-click [src] to adjust it.")

/obj/item/clothing/mask/breath/medical
	desc = "A close-fitting sterile mask that can be connected to an air supply."
	name = "medical mask"
	icon_state = "medical"
	inhand_icon_state = "m_mask"
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 90, FIRE = 0, ACID = 0)
	equip_delay_other = 10

/obj/item/clothing/mask/breath/medical/interdyne
	desc = "A close-fitting metal mask, designed for protection against any number of biochemical, pharmaceutical and biohazardous threats."
	name = "biochemical protection mask"
	worn_icon_state = "medical"
	icon_state = "sechailer"

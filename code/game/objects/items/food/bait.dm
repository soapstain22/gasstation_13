/obj/item/food/bait
	name = "this is bait"
	desc = "you got baited."
	icon = 'icons/obj/fishing.dmi'
	/// Quality trait of this bait
	var/bait_quality = BASIC_QUALITY_BAIT_TRAIT
	/// Icon state added to main fishing rod icon when this bait is equipped
	var/rod_overlay_icon_state

/obj/item/food/bait/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, bait_quality, INNATE_TRAIT)

/obj/item/food/bait/worm
	name = "worm"
	desc = "It's a wriggling worm from a can of fishing bait. You're not going to eat it are you ?"
	icon = 'icons/obj/fishing.dmi'
	icon_state = "worm"
	food_reagents = list(/datum/reagent/consumable/nutriment/protein = 1)
	tastes = list("meat" = 1, "worms" = 1)
	foodtypes = GROSS | MEAT | BUGS
	w_class = WEIGHT_CLASS_TINY
	bait_quality = BASIC_QUALITY_BAIT_TRAIT
	rod_overlay_icon_state = "worm_overlay"

/obj/item/food/bait/worm/premium
	name = "extra slimy worm"
	desc = "This worm looks very sophisticated."
	bait_quality = GOOD_QUALITY_BAIT_TRAIT

/obj/item/food/bait/natural
	name = "natural bait"
	desc = "Fish can't seem to get enough of this!"
	icon = 'icons/obj/medical/chemical.dmi'
	icon_state = "pill9"
	inhand_icon_state = "pill"
	food_reagents = list(/datum/reagent/drug/kronkaine = 1)
	tastes = list("hypocrisy" = 1)
	bait_quality = GREAT_QUALITY_BAIT_TRAIT

/obj/item/food/bait/doughball
	name = "doughball"
	desc = "Small piece of dough. Simple but effective fishing bait."
	icon = 'icons/obj/fishing.dmi'
	icon_state = "doughball"
	food_reagents = list(/datum/reagent/consumable/nutriment/protein = 1)
	tastes = list("dough" = 1)
	foodtypes = GRAIN
	w_class = WEIGHT_CLASS_TINY
	bait_quality = BASIC_QUALITY_BAIT_TRAIT
	rod_overlay_icon_state = "dough_overlay"

/// These are generated by tech fishing rod
/obj/item/food/bait/doughball/synthetic
	name = "synthetic doughball"
	icon_state = "doughball"
	preserved_food = TRUE

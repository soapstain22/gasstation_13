/obj/item/reagent_containers/chem_pack
	name = "intravenous medicine bag"
	desc = "A plastic pressure bag, or 'chem pack', for IV administration of drugs. It is fitted with a thermosealing strip."
	icon = 'icons/obj/medical/bloodpack.dmi'
	icon_state = "chempack"
	volume = 100
	reagent_flags = OPENCONTAINER
	spillable = TRUE
	obj_flags = UNIQUE_RENAME
	resistance_flags = ACID_PROOF
	var/sealed = FALSE
	fill_icon_thresholds = list(10, 20, 30, 40, 50, 60, 70, 80, 90, 100)
	has_variable_transfer_amount = FALSE

/obj/item/reagent_containers/chem_pack/click_alt(mob/living/user)
	if(!user.can_perform_action(src, NEED_DEXTERITY))
		return NONE

	if(sealed)
		balloon_alert(user, "sealed!")
		return CLICK_ACTION_BLOCKING

	if(iscarbon(user) && (HAS_TRAIT(user, TRAIT_CLUMSY) && prob(50)))
		to_chat(user, span_warning("Uh... whoops! You accidentally spill the content of the bag onto yourself."))
		SplashReagents(user)
		return CLICK_ACTION_BLOCKING

	reagents.flags = NONE
	reagent_flags = DRAWABLE | INJECTABLE //To allow for sabotage or ghetto use.
	reagents.flags = reagent_flags
	spillable = FALSE
	sealed = TRUE
	to_chat(user, span_notice("You seal the bag."))
	return CLICK_ACTION_SUCCESS

/obj/item/reagent_containers/chem_pack/examine()
	. = ..()
	if(sealed)
		. += span_notice("The bag is sealed shut.")
	else
		. += span_notice("Alt-click to seal it.")


/obj/item/reagent_containers/chem_pack/attack_self(mob/user)
	if(sealed)
		return
	..()

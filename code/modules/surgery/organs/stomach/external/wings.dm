///Wing base type. doesn't really do anything
/obj/item/organ/external/wings
	zone = BODY_ZONE_CHEST
	slot = ORGAN_SLOT_EXTERNAL_WINGS
	layers = list(EXTERNAL_BEHIND, EXTERNAL_ADJACENT, EXTERNAL_FRONT)

	preference = "wings"

/obj/item/organ/external/wings/can_draw_on_bodypart(mob/living/carbon/human/human)
	return !( (human.wear_suit?.flags_inv & HIDEJUMPSUIT) && !(human.wear_suit.species_exception && is_type_in_list(src, human.wear_suit.species_exception) ) )

///The true wings that you can use to fly and shit (you cant actually shit with them, but it does wing stuff)
/obj/item/organ/external/wings/functional
	///The flight action object
	var/datum/action/innate/flight/fly

	///The preference type for opened wings
	var/wings_open_preference = "wingsopen"
	///The preference type for closed wings
	var/wings_closed_preference = "wings"

	///Are our wings open or closed?
	var/wings_open = FALSE

/obj/item/organ/external/wings/functional/get_global_feature_list()
	if(wings_open)
		return GLOB.wings_open_list
	else
		return GLOB.wings_list

/obj/item/organ/external/wings/functional/Insert(mob/living/carbon/reciever, special, drop_if_replaced)
	. = ..()

	if(isnull(fly))
		fly = new
		fly.Grant(reciever)

/obj/item/organ/external/wings/functional/Remove(mob/living/carbon/organ_owner, special)
	. = ..()

	fly.Remove(organ_owner)

/obj/item/organ/external/wings/functional/on_life(delta_time, times_fired)
	. = ..()

	HandleFlight(owner)

///Mostly as a starter to check if we can still fly
/obj/item/organ/external/wings/functional/proc/HandleFlight(mob/living/carbon/human/H)
	if(H.movement_type & FLYING)
		if(!CanFly(H))
			ToggleFlight(H)
			return FALSE
		return TRUE
	else
		return FALSE

///Check if we can still fly
/obj/item/organ/external/wings/functional/proc/CanFly(mob/living/carbon/human/H)
	if(H.stat || H.body_position == LYING_DOWN)
		return FALSE
	if(H.wear_suit && ((H.wear_suit.flags_inv & HIDEJUMPSUIT) && (!H.wear_suit.species_exception || !is_type_in_list(src, H.wear_suit.species_exception)))) //Jumpsuits have tail holes, so it makes sense they have wing holes too
		to_chat(H, span_warning("Your suit blocks your wings from extending!"))
		return FALSE
	var/turf/T = get_turf(H)
	if(!T)
		return FALSE

	var/datum/gas_mixture/environment = T.return_air()
	if(environment && !(environment.return_pressure() > 30))
		to_chat(H, span_warning("The atmosphere is too thin for you to fly!"))
		return FALSE
	else
		return TRUE

///Slipping but in the air?
/obj/item/organ/external/wings/functional/proc/flyslip(mob/living/carbon/human/H)
	var/obj/buckled_obj
	if(H.buckled)
		buckled_obj = H.buckled

	to_chat(H, span_notice("Your wings spazz out and launch you!"))

	playsound(H.loc, 'sound/misc/slip.ogg', 50, TRUE, -3)

	for(var/obj/item/I in H.held_items)
		H.accident(I)

	var/olddir = H.dir

	H.stop_pulling()
	if(buckled_obj)
		buckled_obj.unbuckle_mob(H)
		step(buckled_obj, olddir)
	else
		new /datum/forced_movement(H, get_ranged_target_turf(H, olddir, 4), 1, FALSE, CALLBACK(H, /mob/living/carbon/.proc/spin, 1, 1))
	return TRUE

///UNSAFE PROC, should only be called through the Activate or other sources that check for CanFly
/obj/item/organ/external/wings/functional/proc/ToggleFlight(mob/living/carbon/human/H)
	if(!HAS_TRAIT_FROM(H, TRAIT_MOVE_FLYING, SPECIES_FLIGHT_TRAIT))
		H.physiology.stun_mod *= 2
		ADD_TRAIT(H, TRAIT_NO_FLOATING_ANIM, SPECIES_FLIGHT_TRAIT)
		ADD_TRAIT(H, TRAIT_MOVE_FLYING, SPECIES_FLIGHT_TRAIT)
		passtable_on(H, SPECIES_TRAIT)
		OpenWings()
	else
		H.physiology.stun_mod *= 0.5
		REMOVE_TRAIT(H, TRAIT_NO_FLOATING_ANIM, SPECIES_FLIGHT_TRAIT)
		REMOVE_TRAIT(H, TRAIT_MOVE_FLYING, SPECIES_FLIGHT_TRAIT)
		passtable_off(H, SPECIES_TRAIT)
		CloseWings()

///SPREAD OUR WINGS AND FLLLLLYYYYYY
/obj/item/organ/external/wings/functional/proc/OpenWings()
	preference = wings_open_preference
	wings_open = TRUE

	generate_icon_cache()
	owner.update_body_parts()

///close our wings
/obj/item/organ/external/wings/functional/proc/CloseWings()
	preference = wings_closed_preference
	wings_open = FALSE

	generate_icon_cache()
	owner.update_body_parts()
	if(isturf(owner?.loc))
		var/turf/T = loc
		T.Entered(src, NONE)

///hud action for starting and stopping flight
/datum/action/innate/flight
	name = "Toggle Flight"
	check_flags = AB_CHECK_CONSCIOUS|AB_CHECK_IMMOBILE
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "flight"

/datum/action/innate/flight/Activate()
	var/mob/living/carbon/human/H = owner
	var/obj/item/organ/external/wings/functional/wings = H.getorganslot(ORGAN_SLOT_EXTERNAL_WINGS)
	if(wings && wings.CanFly(H))
		wings.ToggleFlight(H)
		if(!(H.movement_type & FLYING))
			to_chat(H, span_notice("You settle gently back onto the ground..."))
		else
			to_chat(H, span_notice("You beat your wings and begin to hover gently above the ground..."))
			H.set_resting(FALSE, TRUE)

///Moth wings! They can flutter in low-grav and burn off in heat
/obj/item/organ/external/wings/moth
	preference = "moth_wings"
	layers = list(EXTERNAL_BEHIND, EXTERNAL_FRONT)

	///Are we burned?
	var/burnt = FALSE
	///Store our old sprite here for if our burned wings are healed
	var/original_sprite = ""

/obj/item/organ/external/wings/moth/get_global_feature_list()
	return GLOB.moth_wings_list

/obj/item/organ/external/wings/moth/Insert(mob/living/carbon/reciever, special, drop_if_replaced)
	. = ..()

	RegisterSignal(reciever, COMSIG_HUMAN_BURNING, .proc/try_burn_wings)
	RegisterSignal(reciever, COMSIG_LIVING_POST_FULLY_HEAL, .proc/heal_wings)

/obj/item/organ/external/wings/moth/Remove(mob/living/carbon/organ_owner, special)
	. = ..()

	UnregisterSignal(organ_owner, COMSIG_HUMAN_BURNING)
	UnregisterSignal(organ_owner, COMSIG_LIVING_POST_FULLY_HEAL)

///Check if we can flutter around
/obj/item/organ/external/wings/moth/proc/can_float_move()
	if(!isspaceturf(owner.loc) && !burnt)
		var/datum/gas_mixture/current = owner.loc.return_air()
		if(current && (current.return_pressure() >= ONE_ATMOSPHERE*0.85)) //as long as there's reasonable pressure and no gravity, flight is possible
			return TRUE

///check if our wings can burn off ;_;
/obj/item/organ/external/wings/moth/proc/try_burn_wings(mob/living/carbon/human/human)
	if(!burnt && human.bodytemperature >= 800 && human.fire_stacks > 0) //do not go into the extremely hot light. you will not survive
		to_chat(human, span_danger("Your precious wings burn to a crisp!"))
		SEND_SIGNAL(human, COMSIG_ADD_MOOD_EVENT, "burnt_wings", /datum/mood_event/burnt_wings)

		burn_wings()
		human.update_body_parts()

///burn the wings off
/obj/item/organ/external/wings/moth/proc/burn_wings()
	burnt = TRUE
	var/datum/sprite_accessory/wings = sprite_datums[1]
	original_sprite = wings.name
	add_sprite_datum("Burnt Off", TRUE)

///heal our wings back up!!
/obj/item/organ/external/wings/moth/proc/heal_wings()
	burnt = FALSE
	add_sprite_datum(original_sprite, TRUE)

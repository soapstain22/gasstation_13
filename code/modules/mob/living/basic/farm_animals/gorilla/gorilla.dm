/// Where do we draw gorilla held overlays?
#define GORILLA_HANDS_LAYER 1

/**
 * Like a bigger monkey
 * They make a lot of noise and punch limbs off unconscious folks
 */
/mob/living/basic/gorilla
	name = "Gorilla"
	desc = "A ground-dwelling, predominantly herbivorous ape which usually inhabits the forests of central Africa but today is quite far away from there."
	icon = 'icons/mob/simple/gorilla.dmi'
	icon_state = "crawling"
	icon_living = "crawling"
	icon_dead = "dead"
	health_doll_icon = "crawling"
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	maxHealth = 220
	health = 220
	response_help_continuous = "prods"
	response_help_simple = "prod"
	response_disarm_continuous = "challenges"
	response_disarm_simple = "challenge"
	response_harm_continuous = "thumps"
	response_harm_simple = "thump"
	speed = 0.5
	melee_damage_lower = 15
	melee_damage_upper = 18
	damage_coeff = list(BRUTE = 1, BURN = 1.5, TOX = 1.5, CLONE = 0, STAMINA = 0, OXY = 1.5)
	obj_damage = 20
	attack_verb_continuous = "pummels"
	attack_verb_simple = "pummel"
	attack_sound = 'sound/weapons/punch1.ogg'
	unique_name = TRUE
	ai_controller = /datum/ai_controller/basic_controller/gorilla
	faction = list(FACTION_MONKEY, FACTION_JUNGLE)
	butcher_results = list(/obj/item/food/meat/slab/gorilla = 4, /obj/effect/gibspawner/generic/animal = 1)
	/// How likely our meaty fist is to stun someone
	var/paralyze_chance = 20
	/// A counter for when we can scream again
	var/oogas = 0
	/// Types of things we want to find and eat
	var/static/list/gorilla_food = list(
		/obj/item/food/bread/banana,
		/obj/item/food/breadslice/banana,
		/obj/item/food/cnds/banana_honk,
		/obj/item/food/grown/banana,
		/obj/item/food/popsicle/topsicle/banana,
		/obj/item/food/salad/fruit,
		/obj/item/food/salad/jungle,
		/obj/item/food/sundae,
	)

/mob/living/basic/gorilla/Initialize(mapload)
	. = ..()
	add_traits(list(TRAIT_ADVANCEDTOOLUSER, TRAIT_CAN_STRIP), ROUNDSTART_TRAIT)
	AddElement(/datum/element/wall_smasher)
	AddElement(/datum/element/dextrous)
	AddElement(/datum/element/footstep, FOOTSTEP_MOB_BAREFOOT)
	AddElement(/datum/element/basic_eating, heal_amt = 10, food_types = gorilla_food)
	AddElement(
		/datum/element/amputating_limbs, \
		surgery_time = 0 SECONDS, \
		surgery_verb = "punches",\
	)
	AddComponent(/datum/component/personal_crafting)
	AddComponent(/datum/component/basic_inhands, y_offset = -1)
	ai_controller?.set_blackboard_key(BB_BASIC_FOODS, gorilla_food)

/mob/living/basic/gorilla/update_overlays()
	. = ..()
	if (is_holding_items())
		. += "standing_overlay"

/mob/living/basic/gorilla/update_icon_state()
	. = ..()
	if (stat == DEAD)
		return
	icon_state = is_holding_items() ? "standing" : "crawling"

/mob/living/basic/gorilla/update_held_items()
	. = ..()
	update_appearance(UPDATE_ICON)
	if (is_holding_items())
		add_movespeed_modifier(/datum/movespeed_modifier/gorilla_standing)
	else
		remove_movespeed_modifier(/datum/movespeed_modifier/gorilla_standing)

/mob/living/basic/gorilla/melee_attack(mob/living/target, list/modifiers, ignore_cooldown)
	. = ..()
	if (!. || !isliving(target))
		var/obj/item/can_be_obj = target
		if(istype(can_be_obj, /obj/item))
			SEND_SIGNAL(can_be_obj, COMSIG_ATOM_ATTACK_PAW, src, modifiers, ignore_cooldown)
			if(!src.get_active_held_item() && (can_be_obj.item_flags & IN_STORAGE))
				INVOKE_ASYNC(src, TYPE_PROC_REF(/mob, put_in_hands), can_be_obj, modifiers, ignore_cooldown)
		return
	ooga_ooga()
	if (prob(paralyze_chance))
		target.Paralyze(2 SECONDS)
		visible_message(span_danger("[src] knocks [target] down!"))
	else
		target.throw_at(get_edge_target_turf(target, dir), range = rand(1, 2), speed = 7, thrower = src)

/mob/living/basic/gorilla/gib(drop_bitflags = DROP_BRAIN)
	if(!(drop_bitflags & DROP_BRAIN))
		return ..()
	var/mob/living/brain/gorilla_brain = new(drop_location())
	gorilla_brain.name = real_name
	gorilla_brain.real_name = real_name
	mind?.transfer_to(gorilla_brain)
	return ..()

/mob/living/basic/gorilla/can_use_guns(obj/item/gun)
	to_chat(src, span_warning("Your meaty finger is much too large for the trigger guard!"))
	return FALSE

/// Assert your dominance with audio cues
/mob/living/basic/gorilla/proc/ooga_ooga()
	if (isnull(client))
		return // Sorry NPCs
	oogas -= 1
	if(oogas > 0)
		return
	oogas = rand(2,6)
	emote("ooga")

/// Gorillas are slower when carrying something
/datum/movespeed_modifier/gorilla_standing
	blacklisted_movetypes = (FLYING|FLOATING)
	multiplicative_slowdown = 0.5

/// A smaller gorilla summoned via magic
/mob/living/basic/gorilla/lesser
	name = "lesser Gorilla"
	desc = "An adolescent Gorilla. It may not be fully grown but, much like a banana, that just means it's sturdier and harder to chew!"
	maxHealth = 120
	health = 120
	speed = 0.35
	melee_damage_lower = 10
	melee_damage_upper = 15
	obj_damage = 15
	ai_controller = /datum/ai_controller/basic_controller/gorilla/lesser
	butcher_results = list(/obj/item/food/meat/slab/gorilla = 2)

/mob/living/basic/gorilla/lesser/Initialize(mapload)
	. = ..()
	transform *= 0.75

/// Cargo's wonderful mascot, the tranquil box-carrying ape
/mob/living/basic/gorilla/cargorilla
	name = "Cargorilla" // Overriden, normally
	icon = 'icons/mob/simple/cargorillia.dmi'
	desc = "Cargo's pet gorilla. They seem to have an 'I love Mom' tattoo."
	maxHealth = 200
	health = 200
	faction = list(FACTION_NEUTRAL, FACTION_MONKEY, FACTION_JUNGLE)
	unique_name = FALSE
	ai_controller = null

/mob/living/basic/gorilla/cargorilla/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_PACIFISM, INNATE_TRAIT)
	AddComponent(/datum/component/crate_carrier)

/**
 * Poll ghosts for control of the gorilla. Not added in init because we only want to poll when the round starts.
 * Preferably in future we can replace this with a popup on the lobby to queue to become a gorilla.
 */
/mob/living/basic/gorilla/cargorilla/proc/poll_for_gorilla()
	AddComponent(\
		/datum/component/ghost_direct_control,\
		poll_candidates = TRUE,\
		poll_length = 30 SECONDS,\
		role_name = "Cargorilla",\
		assumed_control_message = "You are Cargorilla, a pacifist friend of the station and carrier of freight.",\
		poll_ignore_key = POLL_IGNORE_CARGORILLA,\
		after_assumed_control = CALLBACK(src, PROC_REF(became_player_controlled)),\
	)

/// Called once a ghost assumes control
/mob/living/basic/gorilla/cargorilla/proc/became_player_controlled()
	mind.set_assigned_role(SSjob.GetJobType(/datum/job/cargo_technician))
	mind.special_role = "Cargorilla"
	to_chat(src, span_notice("You can pick up crates by clicking on them, and drop them by clicking on the ground."))

#undef GORILLA_HANDS_LAYER

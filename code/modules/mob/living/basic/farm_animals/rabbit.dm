/**
 * ## Rabbit
 *
 * A creature that hops around with small tails and long ears.
 *
 * This contains the code for both your standard rabbit as well as the subtypes commonly found during Easter.
 *
 */
/mob/living/basic/rabbit
	name = "rabbit"
	desc = "The hippiest hop around."
	icon = 'icons/mob/simple/rabbit.dmi'
	icon_state = "rabbit_white"
	icon_living = "rabbit_white"
	icon_dead = "rabbit_white_dead"
	gender = PLURAL
	mob_biotypes = MOB_ORGANIC | MOB_BEAST
	health = 15
	maxHealth = 15
	density = FALSE
	gold_core_spawnable = FRIENDLY_SPAWN
	speak_emote = list("sniffles", "twitches")
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"
	attack_sound = 'sound/weapons/punch1.ogg'
	attack_vis_effect = ATTACK_EFFECT_KICK
	response_harm_continuous = "kicks"
	response_harm_simple = "kick"
	attack_verb_continuous = "kicks"
	attack_verb_simple = "kick"
	ai_controller = /datum/ai_controller/basic_controller/rabbit
	/// passed to animal_varity as the prefix icon.
	var/icon_prefix = "rabbit"

/mob/living/basic/rabbit/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/pet_bonus, "hops around happily!")
	AddElement(/datum/element/animal_variety, icon_prefix, pick("brown", "black", "white"), TRUE)
	if(prob(20)) // bunny
		name = "bunny"

/datum/ai_controller/basic_controller/rabbit
	ai_traits = STOP_MOVING_WHEN_PULLED
	ai_movement = /datum/ai_movement/basic_avoidance
	idle_behavior = /datum/idle_behavior/idle_random_walk
	planning_subtrees = list(/datum/ai_planning_subtree/random_speech/rabbit)

/// The easter subtype of rabbits, will lay eggs and say Eastery catchphrases.
/mob/living/basic/rabbit/easter
	icon_state = "easter_rabbit_white"
	icon_living = "easter_rabbit_white"
	icon_dead = "easter_rabbit_white_dead"
	icon_prefix = "easter_rabbit"
	ai_controller = /datum/ai_controller/basic_controller/rabbit/easter
	///passed to the egg_layer component as how many eggs it starts out as able to lay.
	var/initial_egg_amount = 10
	///passed to the egg_layer component as how many eggs it's allowed to hold at most.
	var/max_eggs_held = 8

/mob/living/basic/rabbit/easter/Initialize(mapload)
	. = ..()
	//passed to the egg_layer component as how many eggs it gets when it eats something.
	var/eggs_added_from_eating = rand(1, 4)
	var/list/feed_messages = list("[p_they()] nibbles happily.", "[p_they()] noms happily.")
	AddComponent(/datum/component/egg_layer,\
		/obj/item/surprise_egg,\
		list(/obj/item/food/grown/carrot),\
		feed_messages,\
		list("hides an egg.","scampers around suspiciously.","begins making a huge racket.","begins shuffling."),\
		initial_egg_amount,\
		eggs_added_from_eating,\
		max_eggs_held,\
	)

/datum/ai_controller/basic_controller/rabbit/easter
	planning_subtrees = list(/datum/ai_planning_subtree/random_speech/rabbit/easter)

/// Same deal as the standard easter subtype, but these ones are able to brave the cold of space with their handy gas mask.
/mob/living/basic/rabbit/easter/space
	icon_state = "space_rabbit_white"
	icon_living = "space_rabbit_white"
	icon_dead = "space_rabbit_white_dead"
	icon_prefix = "space_rabbit"
	ai_controller = /datum/ai_controller/basic_controller/rabbit/easter/space
	// Minimum Allowable Body Temp, zero because we are meant to survive in space and we have a fucking RABBIT SPACE MASK.
	var/minimum_survivable_temperature = 0
	// Maximum Allowable Body Temp, 1500 because we might overheat and die in said RABBIT SPACE MASK.
	var/maximum_survivable_temperature = 1500
	/// The amount of damage we incur for being in an unsuitable enviroment (too hot, too cold, not viable atmospherics). Low to account for low health.
	var/unsuitable_environment_damage = 0.5

/mob/living/basic/rabbit/easter/space/Initialize(mapload)
	. = ..()
	// Cached List of suitable atmospherics conditions that we can survive in to pass to atmos_requirements element.
	var/list/habitable_atmos = string_assoc_list(list(
		"min_oxy" = 0,
		"max_oxy" = 0,
		"min_plas" = 0,
		"max_plas" = 0,
		"min_co2" = 0,
		"max_co2" = 0,
		"min_n2" = 0,
		"max_n2" = 0,
	))
	AddElement(/datum/element/atmos_requirements, atmos_requirements = habitable_atmos, unsuitable_atmos_damage = unsuitable_environment_damage)
	AddElement(/datum/element/basic_body_temp_sensitive, min_body_temp = minimum_survivable_temperature, max_body_temp = maximum_survivable_temperature, cold_damage = 0, heat_damage = unsuitable_environment_damage)

/datum/ai_controller/basic_controller/rabbit/easter/space
	planning_subtrees = list(/datum/ai_planning_subtree/random_speech/rabbit/easter/space)

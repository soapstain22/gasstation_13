/mob/living/basic/ghost //PORT OF /mob/living/simple_animal/hostile/retaliate/ghost TO BASIC MOBS
	name = "ghost"
	desc = "A soul of the dead, spooky."
	icon = 'icons/mob/simple/mob.dmi'
	icon_state = "ghost"
	icon_living = "ghost"
	mob_biotypes = MOB_SPIRIT
	speak_emote = list("wails","weeps")
	response_help_continuous = "passes through"
	response_help_simple = "pass through"
	combat_mode = TRUE
	basic_mob_flags = DEL_ON_DEATH
	maxHealth = 40
	health = 40
	melee_damage_lower = 15
	melee_damage_upper = 15
	attack_verb_continuous = "grips"
	attack_verb_simple = "grip"
	unsuitable_atmos_damage = 0
	attack_sound = 'sound/hallucinations/growl1.ogg'
	death_message = "wails, disintegrating into a pile of ectoplasm!"
	gold_core_spawnable = NO_SPAWN //too spooky for science
	light_system = MOVABLE_LIGHT
	light_range = 1 // same glowing as visible player ghosts
	light_power = 2
	ai_controller = /datum/ai_controller/basic_controller/ghost

	///What hairstyle will this ghost have
	var/ghost_hairstyle
	///What color will this ghost's hair be
	var/ghost_hair_color
	///The resulting hair to be displayed on the ghost
	var/mutable_appearance/ghost_hair
	///What facial hairstyle will this ghost have
	var/ghost_facial_hairstyle
	///What color will this ghost's facial hair be
	var/ghost_facial_hair_color
	///The resulting facial hair to be displayed on the ghost
	var/mutable_appearance/ghost_facial_hair
	///Will this ghost spawn with a randomly generated name and hair?
	var/random_identity = TRUE
	///What will this ghost drop on death
	var/list/death_loot = list(/obj/item/ectoplasm)

/mob/living/basic/ghost/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/death_drops, death_loot)
	AddElement(/datum/element/simple_flying)
	AddElement(/datum/element/ai_retaliate)

	if(ghost_hairstyle || ghost_facial_hair) //If we have pre-determined hair, generate it with the values we already have
		give_identity(FALSE) //Option exists so mappers can make ghosts with custom identities.
	else
		give_identity(random_identity)

/**
 * Generates hair, facial hair, and a random name for ghosts.
 *
 * Picks a random hair type, hair color, facial hair type, facial hair color.
 * Adds results as an overlay on the ghost. If random_identity is true, a random identity
 * will be generated (hair/facial/name). If false, it will use
 *
 * * random_identity - Will we only generate hair overlays or will we pick random hair/name
 */

/mob/living/basic/ghost/proc/give_identity(random_identity)
	if(random_identity)
		ghost_hairstyle = random_hairstyle()
		ghost_hair_color = "#[random_color()]"

		if(prob(50)) //Sometimes we have facial hair, sometimes we don't
			ghost_facial_hairstyle = random_facial_hairstyle()
			ghost_facial_hair_color = ghost_hair_color

	if(ghost_hairstyle != null)
		ghost_hair = mutable_appearance('icons/mob/species/human/human_face.dmi', "hair_[ghost_hairstyle]", -HAIR_LAYER)
		ghost_hair.alpha = 200
		ghost_hair.color = ghost_hair_color
		add_overlay(ghost_hair)
	if(ghost_facial_hairstyle != null)
		ghost_facial_hair = mutable_appearance('icons/mob/species/human/human_face.dmi', "facial_[ghost_facial_hairstyle]", -HAIR_LAYER)
		ghost_facial_hair.alpha = 200
		ghost_facial_hair.color = ghost_facial_hair_color
		add_overlay(ghost_facial_hair)

	if(random_identity)
		switch(rand(0,1))
			if(0)
				name = "ghost of [pick(GLOB.first_names_male)] [pick(GLOB.last_names)]"
			if(1)
				name = "ghost of [pick(GLOB.first_names_female)] [pick(GLOB.last_names)]"

/datum/ai_controller/basic_controller/ghost
	blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic(),
	)

	ai_movement = /datum/ai_movement/basic_avoidance
	idle_behavior = /datum/idle_behavior/idle_random_walk

	planning_subtrees = list(
		/datum/ai_planning_subtree/target_retaliate,
		/datum/ai_planning_subtree/basic_melee_attack_subtree/ghost,
	)

/datum/ai_planning_subtree/basic_melee_attack_subtree/ghost
	melee_attack_behavior = /datum/ai_behavior/basic_melee_attack/ghost

/datum/ai_behavior/basic_melee_attack/ghost
	action_cooldown = 2 SECONDS

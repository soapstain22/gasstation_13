#define EGG_INCUBATION_TIME (4 MINUTES)

/mob/living/simple_animal/hostile/headcrab
	name = "headslug"
	desc = "Absolutely not de-beaked or harmless. Keep away from corpses."
	icon_state = "headcrab"
	icon_living = "headcrab"
	icon_dead = "headcrab_dead"
	gender = NEUTER
	health = 50
	maxHealth = 50
	melee_damage_lower = 5
	melee_damage_upper = 5
	attack_verb_continuous = "chomps"
	attack_verb_simple = "chomp"
	attack_sound = 'sound/weapons/bite.ogg'
	attack_vis_effect = ATTACK_EFFECT_BITE
	faction = list(FACTION_CREATURE)
	robust_searching = 1
	stat_attack = DEAD
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	speak_emote = list("squeaks")
	/// The mind to transfer to our egg when it hatches
	var/datum/mind/origin
	/// Set to true once we've implanted our egg
	var/egg_lain = FALSE

/mob/living/simple_animal/hostile/headcrab/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_VENTCRAWLER_ALWAYS, INNATE_TRAIT)

/mob/living/simple_animal/hostile/headcrab/proc/Infect(mob/living/carbon/victim)
	var/obj/item/organ/internal/body_egg/changeling_egg/egg = new(victim)
	egg.Insert(victim)
	if(origin)
		egg.origin = origin
	else if(mind) // Let's make this a feature
		egg.origin = mind
	for(var/obj/item/organ/I in src)
		I.forceMove(egg)
	visible_message(span_warning("[src] plants something in [victim]'s flesh!"), \
					span_danger("We inject our egg into [victim]'s body!"))
	egg_lain = TRUE

/mob/living/simple_animal/hostile/headcrab/AttackingTarget()
	. = ..()
	if (!. || egg_lain || !iscarbon(target) || ismonkey(target))
		return
	var/mob/living/carbon/victim = target
	if(victim.stat != DEAD)
		return
	if(HAS_TRAIT(victim, TRAIT_XENO_HOST))
		target.balloon_alert(src, "already pregnant!") // Maybe the worst balloon alert in the codebase
		return
	Infect(target)
	to_chat(src, span_userdanger("With our egg laid, our death approaches rapidly..."))
	addtimer(CALLBACK(src, PROC_REF(death)), 10 SECONDS)

/obj/item/organ/internal/body_egg/changeling_egg
	name = "changeling egg"
	desc = "Twitching and disgusting."
	var/datum/mind/origin
	var/time = 0

/obj/item/organ/internal/body_egg/changeling_egg/egg_process(seconds_per_tick, times_fired)
	// Changeling eggs grow in dead people
	time += seconds_per_tick * 10
	if(time >= EGG_INCUBATION_TIME)
		Pop()
		Remove(owner)
		qdel(src)

/obj/item/organ/internal/body_egg/changeling_egg/proc/Pop()
	var/mob/living/carbon/human/spawned_monkey = new(owner)
	spawned_monkey.set_species(/datum/species/monkey)

	for(var/obj/item/organ/I in src)
		I.Insert(spawned_monkey, 1)

	if(origin && (origin.current ? (origin.current.stat == DEAD) : origin.get_ghost()))
		origin.transfer_to(spawned_monkey)
		spawned_monkey.key = origin.key
		var/datum/antagonist/changeling/changeling_datum = origin.has_antag_datum(/datum/antagonist/changeling)
		if(!changeling_datum)
			changeling_datum = origin.add_antag_datum(/datum/antagonist/changeling/headslug)
		if(changeling_datum.can_absorb_dna(owner))
			changeling_datum.add_new_profile(owner)

		var/datum/action/changeling/lesserform/transform = new()
		changeling_datum.purchased_powers[transform.type] = transform
		changeling_datum.regain_powers()
	owner.investigate_log("has been gibbed by a changeling egg burst.", INVESTIGATE_DEATHS)
	owner.gib()

#undef EGG_INCUBATION_TIME

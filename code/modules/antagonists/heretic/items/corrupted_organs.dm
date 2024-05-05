/// Renders you unable to see people who were heretics at the time that this organ is gained
/obj/item/organ/internal/eyes/corrupt
	name = "corrupt orbs"
	desc = "These eyes have seen something they shouldn't have."
	/// The override images we are applying
	var/list/hallucinations

/obj/item/organ/internal/eyes/corrupt/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/corrupted_organ)
	AddElement(/datum/element/noticable_organ, "%PRONOUN_Their eyes have wide dilated pupils, and no iris. Something is moving in the darkness.", BODY_ZONE_PRECISE_EYES)

/obj/item/organ/internal/eyes/corrupt/on_mob_insert(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	if (!organ_owner.client)
		return

	var/list/human_mobs = GLOB.human_list.Copy()
	human_mobs -= organ_owner
	for (var/mob/living/check_human as anything in human_mobs)
		if (!IS_HERETIC(check_human))
			continue
		var/image/invisible_man = image('icons/blanks/32x32.dmi', check_human, "nothing")
		invisible_man.override = TRUE
		LAZYADD(hallucinations, invisible_man)

	if (length(hallucinations))
		organ_owner.client.images |= hallucinations

/obj/item/organ/internal/eyes/corrupt/on_mob_remove(mob/living/carbon/organ_owner, special)
	. = ..()
	if (!LAZYLEN(hallucinations))
		return
	organ_owner.client?.images -= hallucinations
	QDEL_NULL(hallucinations)

/// Sometimes speak in incomprehensible tongues
/obj/item/organ/internal/tongue/corrupt
	name = "corrupt tongue"
	desc = "This one tells only lies."

/obj/item/organ/internal/tongue/corrupt/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/corrupted_organ)
	AddElement(/datum/element/noticable_organ, "The inside of %PRONOUN_Their mouth is full of stars.", BODY_ZONE_PRECISE_MOUTH)

/obj/item/organ/internal/tongue/corrupt/on_mob_insert(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	RegisterSignal(organ_owner, COMSIG_MOB_SAY, PROC_REF(on_spoken))

/obj/item/organ/internal/tongue/corrupt/on_mob_remove(mob/living/carbon/organ_owner, special)
	. = ..()
	UnregisterSignal(organ_owner, COMSIG_MOB_SAY)

/// When the mob speaks, sometimes put it in a different language
/obj/item/organ/internal/tongue/corrupt/proc/on_spoken(mob/living/organ_owner, list/speech_args)
	SIGNAL_HANDLER
	if (organ_owner.has_reagent(/datum/reagent/water/holywater) || prob(60))
		return
	speech_args[SPEECH_LANGUAGE] = /datum/language/shadowtongue

/// Randomly secretes alcohol or hallucinogens when you're drinking something
/obj/item/organ/internal/liver/corrupt
	name = "corrupt liver"
	desc = "After what you've seen you could really go for a drink."

/obj/item/organ/internal/liver/corrupt/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/corrupted_organ)

/// Rapidly become hungry if you are not digesting blood
/obj/item/organ/internal/stomach/corrupt
	name = "corrupt stomach"
	desc = "This parasite demands an unwholesome diet in order to be satisfied."
	/// Do we have an unholy thirst?
	var/thirst_satiated = FALSE

/obj/item/organ/internal/stomach/corrupt/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/corrupted_organ)
	AddElement(/datum/element/noticable_organ, "%PRONOUN_They %PRONOUN_have an unhealthy pallor.")

/obj/item/organ/internal/stomach/corrupt/handle_hunger(mob/living/carbon/human/human, seconds_per_tick, times_fired)
	if (thirst_satiated || human.has_reagent(/datum/reagent/water/holywater))
		return ..()

	if (!thirst_satiated && human.has_reagent(/datum/reagent/blood))
		thirst_satiated = TRUE
		addtimer(CALLBACK(src, PROC_REF(start_thirsting)), 3 MINUTES, TIMER_DELETE_ME)
		to_chat(human, span_cult_italic("The thirst is satisfied... for now."))
		return ..()

	human.adjust_nutrition(-1 * seconds_per_tick)

	if (SPT_PROB(98, seconds_per_tick))
		return ..()

	var/static/list/blood_messages = list(
		"Blood...",
		"Everyone suddenly looks so tasty.",
		"The blood...",
		"There's an emptiness in you that only blood can fill.",
		"You could really go for some blood right now.",
		"You feel the blood rushing through your veins.",
		"You think about biting someone's throat.",
		"Your stomach growls and you feel a metallic taste in your mouth.",
	)
	to_chat(human, span_cult_italic(pick(blood_messages)))

	return ..()

/// Me when I don't have enough blood
/obj/item/organ/internal/stomach/corrupt/proc/start_thirsting()
	thirst_satiated = FALSE

/// Occasionally bombards you with spooky hands and lets everyone hear your pulse.
/obj/item/organ/internal/heart/corrupt
	name = "corrupt heart"
	desc = "What corruption is this spreading along with the blood?"
	/// How likely are we to spawn a hand on any particular second?
	var/hand_chance = 33

/obj/item/organ/internal/heart/corrupt/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/corrupted_organ)

/obj/item/organ/internal/heart/corrupt/on_life(seconds_per_tick, times_fired)
	. = ..()
	if (istype(get_area(owner), /area/centcom/heretic_sacrifice) || !owner.needs_heart() || !is_beating() || owner.has_reagent(/datum/reagent/water/holywater) || !SPT_PROB(hand_chance, seconds_per_tick))
		return
	fire_curse_hand(owner)

/// Sometimes cough out some kind of dangerous gas
/obj/item/organ/internal/lungs/corrupt
	name = "corrupt lungs"
	desc = "Some things SHOULD be drowned in tar."
	/// How likely are we not to cough every time we take a breath?
	var/cough_chance = 30
	/// How much gas to emit?
	var/gas_amount = 30
	/// What can we cough up?
	var/list/gas_types = list(
		/datum/gas/bz = 30,
		/datum/gas/miasma = 50,
		/datum/gas/plasma = 20,
	)

/obj/item/organ/internal/lungs/corrupt/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/corrupted_organ)

/obj/item/organ/internal/lungs/corrupt/check_breath(datum/gas_mixture/breath, mob/living/carbon/human/breather)
	. = ..()
	if (!. || breather.has_reagent(/datum/reagent/water/holywater) || !prob(cough_chance))
		return
	breather.emote("cough");
	var/chosen_gas = pick_weight(gas_types)
	var/datum/gas_mixture/mix_to_spawn = new()
	mix_to_spawn.add_gas(pick(chosen_gas))
	mix_to_spawn.gases[chosen_gas][MOLES] = gas_amount
	mix_to_spawn.temperature = breather.bodytemperature
	var/turf/open/our_turf = get_turf(breather)
	our_turf.assume_air(mix_to_spawn)

/// It's full of worms
/obj/item/organ/internal/appendix/corrupt
	name = "corrupt appendix"
	desc = "What kind of dark, cosmic force is even going to bother to corrupt an appendix?"
	/// How likely are we to spawn worms?
	var/worm_chance = 2

/obj/item/organ/internal/appendix/corrupt/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/corrupted_organ)
	AddElement(/datum/element/noticable_organ, "%PRONOUN_Their abdomen is distended... and wiggling.", BODY_ZONE_PRECISE_GROIN)

/obj/item/organ/internal/appendix/corrupt/on_life(seconds_per_tick, times_fired)
	. = ..()
	if (owner.stat != CONSCIOUS || owner.has_reagent(/datum/reagent/water/holywater) || !SPT_PROB(worm_chance, seconds_per_tick))
		return
	owner.vomit(MOB_VOMIT_MESSAGE | MOB_VOMIT_HARM, vomit_type = /obj/effect/decal/cleanable/vomit/nebula/worms, distance = 0)
	owner.Knockdown(0.5 SECONDS)

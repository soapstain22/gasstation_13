/datum/bloodsucker_clan/lasombra
	name = CLAN_LAZOMBRA
	description = "This Clan seems to adore living in the <i>Shadows</i> and worshipping it's secrets.. \n\
		Their vassals adapt to see in darkness, and their favorite vassal turns into a horrific shadow creature."
	join_icon_state = "lasombra"
	join_description = "You live in shadows, light sources damage your eyes and your body, but you gain an ability to vanish in shadows.\
		Your vassals gain nightvision, and your favorite vassal transfroms into a nightmare."
	clan_objective = /datum/objective/bloodsucker/eyethief
	frenzy_stun_immune = TRUE
	blood_drink_type = BLOODSUCKER_DRINK_NORMAL
	var/list/vassal_minds 

/datum/bloodsucker_clan/lasombra/New(mob/living/carbon/user)
	. = ..()
	if(!HAS_TRAIT(user, TRAIT_UNNATURAL_RED_GLOWY_EYES))
		user.AddElement(/datum/element/cult_eyes, initial_delay = 0 SECONDS)
	var/datum/action/cooldown/spell/jaunt/shadow_walk/lasombra/shadow_walk = new()
	shadow_walk.Grant(user)

/datum/bloodsucker_clan/lasombra/Destroy()
	for(var/mind in vassal_minds)
		UnregisterSignal(mind, COMSIG_ANTAGONIST_REMOVED)
	return ..()

/datum/bloodsucker_clan/lasombra/handle_clan_life(atom/source, datum/antagonist/bloodsucker/bloodsuckerdatum)
	. = ..()
	if(!ishuman(bloodsuckerdatum.owner.current) || bloodsuckerdatum.owner.current.stat != CONSCIOUS || HAS_TRAIT(bloodsuckerdatum.owner.current, TRAIT_MASQUERADE))
		return
	var/mob/living/carbon/human/human_owner = bloodsuckerdatum.owner.current
	var/turf/T = get_turf(human_owner)
	var/lums = T.get_lumcount()
	var/obj/item/organ/internal/eyes/eyes = human_owner.getorganslot(ORGAN_SLOT_EYES)
	if(lums > 0.5)
		affected_human.add_mood_event("too_bright", /datum/mood_event/bright_light)
		eyes.applyOrganDamage(2)
		human_owner.adjustBruteLoss(4)
		if(prob(25))
			to_chat(human_owner, span_warning("The light burns you!"))
	else
		affected_carbon.clear_mood_event("too_bright")
		eyes.applyOrganDamage(-1)

/datum/bloodsucker_clan/lasombra/on_favorite_vassal(datum/source, datum/antagonist/vassal/vassaldatum, mob/living/bloodsucker)
	var/mob/living/carbon/human/humanowner = vassaldatum.owner.current
	if(!istype(humanowner)) // :(
		return
	humanowner.set_species(/datum/species/shadow/nightmare)
	to_chat(vassaldatum.owner.current, span_notice("You feel your body has changed... into something greater."))

/datum/bloodsucker_clan/lasombra/on_vassal_made(atom/source, mob/living/user, mob/living/target)
	. = ..()
	if(target.mind)
		RegisterSignal(target.mind, COMSIG_ANTAGONIST_REMOVED, PROC_REF(remove_night_vision))
		vassal_minds += target.mind
	ADD_TRAIT(target, TRAIT_TRUE_NIGHT_VISION, BLOODSUCKER_TRAIT)
	target.update_sight()
	to_chat(vassaldatum.owner.current, span_notice("You feel your eyes adapt to darkness."))

/datum/bloodsucker_clan/lasombra/proc/remove_night_vision(datum/mind/source)
	SIGNAL_HANDLER
	if(HAS_TRAIT_FROM(source.current, TRAIT_TRUE_NIGHT_VISION, BLOODSUCKER_TRAIT))
		REMOVE_TRAIT(source.current, TRAIT_TRUE_NIGHT_VISION, BLOODSUCKER_TRAIT)
	vassal_minds -= source
	UnregisterSignal(source, COMSIG_ANTAGONIST_REMOVED)

/datum/action/cooldown/spell/aoe/moon_ringleader
	name = "Ringleaders Rise"
	desc = "Big AoE spell that more brain damage the lower the sanity of everyone in the AoE and it also causes hallucinations with those who have less sanity getting more. \
			The spell then further lowers sanity with the those with higher sanity being affected most."
	background_icon_state = "bg_heretic"
	overlay_icon_state = "bg_heretic_border"
	button_icon = 'icons/mob/actions/actions_ecult.dmi'
	button_icon_state = "uncuff"
	sound = 'sound/magic/swap.ogg'

	school = SCHOOL_FORBIDDEN
	cooldown_time = 2 MINUTES

	invocation = "R''S 'E"
	invocation_type = INVOCATION_SHOUT
	spell_requirements = NONE

	aoe_radius = 4

// Before the cast, we do some small AOE damage around the caster
/datum/action/cooldown/spell/aoe/wave_of_desperation/before_cast(mob/living/carbon/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return

	if(cast_on.handcuffed)
		cast_on.visible_message(span_danger("[cast_on.handcuffed] on [cast_on] shatter!"))
		QDEL_NULL(cast_on.handcuffed)
	if(cast_on.legcuffed)
		cast_on.visible_message(span_danger("[cast_on.legcuffed] on [cast_on] shatters!"))
		QDEL_NULL(cast_on.legcuffed)

	cast_on.apply_status_effect(/datum/status_effect/heretic_lastresort)
	new /obj/effect/temp_visual/knockblast(get_turf(cast_on))

	for(var/mob/living/victim in get_things_to_cast_on(cast_on, radius_override = 1))
		victim.AdjustKnockdown(3 SECONDS)
		victim.AdjustParalyzed(0.5 SECONDS)

/datum/action/cooldown/spell/aoe/wave_of_desperation/get_things_to_cast_on(atom/center, radius_override)
	. = list()
	for(var/atom/nearby in orange(center, radius_override ? radius_override : aoe_radius))
		if(nearby == owner || nearby == center || isarea(nearby))
			continue
		if(!ismob(nearby))
			. += nearby
			continue
		var/mob/living/nearby_mob = nearby
		if(!isturf(nearby_mob.loc))
			continue
		if(IS_HERETIC_OR_MONSTER(nearby_mob))
			continue
		if(nearby_mob.can_block_magic(antimagic_flags))
			continue

		. += nearby_mob

/datum/action/cooldown/spell/aoe/wave_of_desperation/cast_on_thing_in_aoe(atom/victim, atom/caster)
	if(!ismob(victim))
		SEND_SIGNAL(owner, COMSIG_HERETIC_MANSUS_GRASP_ATTACK_SECONDARY, victim)

	var/atom/movable/mover = victim
	if(!istype(mover))
		return

	if(mover.anchored)
		return
	var/our_turf = get_turf(caster)
	var/throwtarget = get_edge_target_turf(our_turf, get_dir(our_turf, get_step_away(mover, our_turf)))
	mover.safe_throw_at(throwtarget, 3, 1, force = MOVE_FORCE_STRONG)

/obj/effect/temp_visual/knockblast
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield-flash"
	alpha = 180
	duration = 1 SECONDS

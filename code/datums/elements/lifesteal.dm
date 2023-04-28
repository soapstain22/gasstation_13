/**
 * Heals the user (if attached to an item) or the mob itself (if attached to a hostile simple mob)
 * by a flat amount whenever a successful attack is performed against another living mob.
 */
/datum/element/lifesteal
	element_flags = ELEMENT_DETACH_ON_HOST_DESTROY|ELEMENT_BESPOKE
	argument_hash_start_idx = 2
	/// heals a constant amount every time a hit occurs
	var/flat_heal
	var/static/list/damage_heal_order = list(BRUTE, BURN, OXY)

/datum/element/lifesteal/Attach(datum/target, flat_heal)
	. = ..()
	src.flat_heal = flat_heal
	target.AddElement(/datum/element/on_hit_effect, CALLBACK(src, PROC_REF(do_lifesteal)))

/datum/element/lifesteal/Detach(datum/target)
	target.RemoveElement(/datum/element/on_hit_effect)
	return ..()

/datum/element/lifesteal/proc/do_lifesteal(atom/heal_target, atom/damage_target)
	if(isliving(heal_target) && isliving(damage_target))
		var/mob/living/healing = heal_target
		var/mob/living/damaging = damage_target
		if(damaging.stat != DEAD)
			healing.heal_ordered_damage(flat_heal, damage_heal_order)

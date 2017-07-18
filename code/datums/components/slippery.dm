/datum/component/slippery
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/intensity
	var/lube_flags
	var/mob/slip_victim

/datum/component/slippery/New(datum/P, _intensity, _lube_flags = NONE)
	..()
	intensity = max(_intensity, 0)
	lube_flags = _lube_flags
	if(ismovableatom(P))
		RegisterSignal(COMSIG_MOVABLE_CROSSED, .proc/Slip)
	else
		RegisterSignal(COMSIG_ATOM_ENTERED, .proc/Slip)

/datum/component/slippery/Destroy()
	ClearMobRef()
	return ..()

/datum/component/slippery/proc/Slip(atom/movable/AM)
	var/mob/victim = AM
	if(istype(victim) && !victim.is_flying() && victim.slip(intensity, null, parent, lube_flags))
		slip_victim = victim
		addtimer(CALLBACK(src, .proc/ClearMobRef), 0, TIMER_UNIQUE)
		return TRUE

/datum/component/slippery/proc/ClearMobRef()
	slip_victim = null

/datum/component/slippery/InheritComponent(datum/component/slippery/S, i_am_original)
	intensity = max(S.intensity, intensity)
	lube_flags |= S.lube_flags

/datum/component/plumbing/feeder
	demand_connects = SOUTH
	supply_connects = NORTH

/datum/component/plumbing/feeder/Initialize()
	. = ..()

	RegisterSignal(parent, list(COMSIG_MOVABLE_BUCKLE), .proc/update_buckled)
	RegisterSignal(parent, list(COMSIG_MOVABLE_UNBUCKLE), .proc/update_buckled)

	recipient_reagents_holder = null

/datum/component/plumbing/feeder/proc/update_buckled(datum/source, mob/living/bucklee)
	if(bucklee?.reagents)
		recipient_reagents_holder = bucklee.reagents
		START_PROCESSING(SSfluids, src) //Component might've stopped processing if we didn't have a reagent holder before
	else
		recipient_reagents_holder = null

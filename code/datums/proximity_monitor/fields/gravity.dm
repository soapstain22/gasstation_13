/datum/proximity_monitor/advanced/gravity
	// edge_is_a_field = TRUE // This is supposed to have the edges included in the field, but produces some bugs currently.
	var/gravity_value = 0
	var/list/modified_turfs = list()

/datum/proximity_monitor/advanced/gravity/New(atom/_host, range, _ignore_if_not_on_turf = TRUE, gravity)
	. = ..()
	gravity_value = gravity
	recalculate_field()

/datum/proximity_monitor/advanced/gravity/setup_field_turf(turf/T)
	. = ..()

	if (!isnull(modified_turfs[T]))
		T.AddElement(/datum/element/forced_gravity, gravity_value)
		modified_turfs[T] = gravity_value

/datum/proximity_monitor/advanced/gravity/cleanup_field_turf(turf/T)
	. = ..()
	if(isnull(modified_turfs[T]))
		return
	T.RemoveElement(/datum/element/forced_gravity, modified_turfs[T])
	modified_turfs -= T

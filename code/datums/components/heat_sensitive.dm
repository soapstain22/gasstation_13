/datum/component/heat_sensitive
	var/max_heat
	var/min_heat
	var/atom/target
	var/datum/movement_detector/tracker

/datum/component/heat_sensitive/Initialize(max, min)
	if(!isatom(parent)) //How
		return COMPONENT_INCOMPATIBLE
	max_heat = max
	min_heat = min
	target = get_atom_on_turf(parent)
	tracker = new /datum/movement_detector(parent, CALLBACK(src, .proc/reset_register))

/datum/component/heat_sensitive/proc/reset_register()
	UnregisterSignal(get_turf(target), COMSIG_TURF_EXPOSE)
	target = get_atom_on_turf(parent)
	RegisterSignal(get_turf(target), COMSIG_TURF_EXPOSE, .proc/check_requirements)

/datum/component/heat_sensitive/proc/check_requirements(datum/source, datum/gas_mixture/mix, heat, volume)
	if(heat >= max_heat)
		SEND_SIGNAL(parent, COMSIG_HEAT_HOT, mix, heat, volume)
	if(heat <= min_heat)
		SEND_SIGNAL(parent, COMSIG_HEAT_COLD, mix, heat, volume)

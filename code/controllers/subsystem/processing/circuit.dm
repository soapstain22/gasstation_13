PROCESSING_SUBSYSTEM_DEF(circuit)
	name = "Circuit"
	stat_tag = "CIR"
	var/list/all_exonet_connections = list()
	var/list/all_integrated_circuits = list()

/datum/controller/subsystem/processing/circuit/Initialize(start_timeofday)
	initialize_integrated_circuits_list()
	return ..()

/datum/controller/subsystem/processing/circuit/proc/initialize_integrated_circuits_list()
	all_integrated_circuits = list()
	for(var/thing in typesof(/obj/item/integrated_circuit))
		all_integrated_circuits += new thing()
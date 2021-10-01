/datum/circuit_composite_template/list
	datatype = PORT_COMPOSITE_TYPE_LIST
	composite_datatype_path = /datum/circuit_datatype/composite_instance/list
	expected_types = 1

/datum/circuit_composite_template/list/generate_name(list/composite_datatypes)
	return "[composite_datatypes[1]] [datatype]"

/datum/circuit_datatype/composite_instance/list
	color = "white"
	datatype_flags = DATATYPE_FLAG_COMPOSITE

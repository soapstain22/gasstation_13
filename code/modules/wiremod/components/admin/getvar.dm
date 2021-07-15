/**
 * # Get Variable Component
 *
 * A component that gets a variable on an object
 */
/obj/item/circuit_component/get_variable
	display_name = "Get Variable"
	display_desc = "A component that gets a variable on an object."
	circuit_flags = CIRCUIT_FLAG_INPUT_SIGNAL|CIRCUIT_FLAG_OUTPUT_SIGNAL|CIRCUIT_FLAG_ADMIN

	/// Entity to get variable of
	var/datum/port/input/entity

	/// Variable name
	var/datum/port/input/variable_name

	/// Variable value
	var/datum/port/output/output_value


/obj/item/circuit_component/get_variable/Initialize()
	. = ..()
	entity = add_input_port("Target", PORT_TYPE_ATOM)
	variable_name = add_input_port("Variable Name", PORT_TYPE_STRING)

	output_value = add_output_port("Output Value", PORT_TYPE_ANY)

/obj/item/circuit_component/get_variable/Destroy()
	entity = null
	variable_name = null
	output_value = null
	return ..()

/obj/item/circuit_component/get_variable/input_received(datum/port/input/port)
	. = ..()
	if(.)
		return
	var/atom/object = entity.input_value
	var/var_name = variable_name.input_value
	if(!var_name || !object)
		return

	output_value.set_output(object.vv_get_var(var_name))

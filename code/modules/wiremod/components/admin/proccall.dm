/**
 * # Proc Call Component
 *
 * A component that calls a proc on an object and outputs the return value
 */
/obj/item/circuit_component/proccall
	display_name = "Proc Call"
	display_desc = "A component that gets a variable on an object."
	circuit_flags = CIRCUIT_FLAG_INPUT_SIGNAL|CIRCUIT_FLAG_OUTPUT_SIGNAL|CIRCUIT_FLAG_ADMIN

	/// Entity to proccall on
	var/datum/port/input/entity

	/// Proc to call
	var/datum/port/input/proc_name

	/// Arguments
	var/datum/port/input/arguments

	/// Output value
	var/datum/port/output/output_value

/obj/item/circuit_component/proccall/populate_options()
	var/static/component_options = list(
		COMP_PROC_OBJECT,
		COMP_PROC_GLOBAL,
	)

	options = component_options

/obj/item/circuit_component/proccall/Initialize()
	. = ..()
	entity = add_input_port("Target", PORT_TYPE_ATOM)
	proc_name = add_input_port("Proc Name", PORT_TYPE_STRING)
	arguments = add_input_port("Arguments", PORT_TYPE_LIST)

	output_value = add_output_port("Output Value", PORT_TYPE_ANY)

/obj/item/circuit_component/proccall/Destroy()
	entity = null
	proc_name = null
	arguments = null
	output_value = null
	return ..()

/obj/item/circuit_component/proccall/input_received(datum/port/input/port)
	. = ..()
	if(.)
		return

	var/called_on
	if(current_option == COMP_PROC_OBJECT)
		called_on = entity.input_value
	else
		called_on = GLOBAL_PROC

	if(!called_on)
		return

	var/to_invoke = proc_name.input_value
	var/params = arguments.input_value || list()

	if(!to_invoke)
		return

	GLOB.AdminProcCaller = "CHAT_[parent.display_name]" //_ won't show up in ckeys so it'll never match with a real admin
	var/result = WrapAdminProcCall(called_on, to_invoke, params)
	GLOB.AdminProcCaller = null

	output_value.set_output(result)

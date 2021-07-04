/obj/machinery/atmospherics/components/unary/turbine
	icon = 'icons/obj/atmospherics/components/turbine.dmi'
	layer = OBJ_LAYER
	density = TRUE
	pipe_flags = PIPING_ONE_PER_TURF | PIPING_DEFAULT_LAYER_ONLY
	///Check to see if we are connected to the other parts
	var/connected = FALSE
	///volume size of our internal component
	var/initial_volume = 500
	///base icon for appearance changes
	var/base_icon = ""

/obj/machinery/atmospherics/components/unary/turbine/Initialize()
	. = ..()
	airs[1].volume = initial_volume

/obj/machinery/atmospherics/components/unary/turbine/attackby(obj/item/tool, mob/user, params)
	if(!connected)
		if(default_deconstruction_screwdriver(user, "[base_icon]", "[base_icon]", tool))
			update_appearance()
			return
	if(default_change_direction_wrench(user, tool))
		return
	if(default_deconstruction_crowbar(tool))
		return
	return ..()

/obj/machinery/atmospherics/components/unary/turbine/default_change_direction_wrench(mob/user, obj/item/tool)
	if(!..())
		return FALSE
	SetInitDirections()
	var/obj/machinery/atmospherics/node = nodes[1]
	if(node)
		if(src in node.nodes) //Only if it's actually connected. On-pipe version would is one-sided.
			node.disconnect(src)
		nodes[1] = null
	if(parents[1])
		nullifyPipenet(parents[1])

	atmosinit()
	node = nodes[1]
	if(node)
		node.atmosinit()
		node.addMember(src)
	SSair.add_to_rebuild_queue(src)
	return TRUE

/obj/machinery/atmospherics/components/unary/turbine/turbine_inlet/update_appearance()
	. = ..()
	if(connected)
		icon_state = "[base_icon]_conn"
	else
		icon_state = base_icon
	if(on)
		icon_state = "[base_icon]_on"

/obj/machinery/atmospherics/components/unary/turbine/turbine_inlet
	icon_state = "turbine_inlet"
	name = "turbine inlet port"
	desc = "Input port for the turbine."
	circuit = /obj/item/circuitboard/machine/turbine_inlet
	initial_volume = 500
	base_icon = "turbine_inlet"

/obj/machinery/atmospherics/components/unary/turbine/turbine_outlet
	icon_state = "turbine_outlet"
	name = "turbine outlet port"
	desc = "Output port for the turbine."
	circuit = /obj/item/circuitboard/machine/turbine_outlet
	initial_volume = 1000
	base_icon = "turbine_outlet"

/obj/machinery/power/turbine
	icon = 'icons/obj/atmospherics/components/turbine.dmi'
	layer = OBJ_LAYER
	///Check to see if we are connected to the other parts
	var/connected = FALSE
	///base icon for appearance changes
	var/base_icon = ""
	///Check if the machine is turned on
	var/on = FALSE

/obj/machinery/power/turbine/update_appearance()
	. = ..()
	if(connected)
		icon_state = "[base_icon]_conn"
	else
		icon_state = base_icon
	if(on)
		icon_state = "[base_icon]_on"

/obj/machinery/power/turbine/attackby(obj/item/I, mob/user, params)
	if(!connected)
		if(default_deconstruction_screwdriver(user, "[base_icon]_open", "[base_icon]", I))
			update_appearance()
			return
	if(default_change_direction_wrench(user, I))
		return
	if(default_deconstruction_crowbar(I))
		return
	return ..()

/obj/machinery/power/turbine/turbine_shaft
	icon_state = "turbine_shaft"
	name = "turbine shaft"
	desc = "Main body of the turbine multipart."
	circuit = /obj/item/circuitboard/machine/turbine_shaft
	base_icon = "turbine_shaft"
	density = TRUE

/obj/machinery/power/turbine/turbine_controller
	icon_state = "turbine_interface"
	name = "turbine controller"
	desc = "Controller that connects the turbine parts in one and allows control of the machine."
	circuit = /obj/item/circuitboard/machine/turbine_controller
	base_icon = "turbine_interface"
	///Stores all connected parts
	var/list/turbine_parts = list()
	///Stores a reference to the turbine inlet
	var/obj/machinery/atmospherics/components/unary/turbine/turbine_inlet/inlet
	///Stores a reference to the turbine outlet
	var/obj/machinery/atmospherics/components/unary/turbine/turbine_outlet/outlet
	///Stores a reference to the turbine shaft
	var/obj/machinery/power/turbine/turbine_shaft/shaft
	///Gasmix between the inlet and the shaft
	var/datum/gas_mixture/first_point
	///Gasmix between the shaft and the outlet
	var/datum/gas_mixture/second_point
	///How well the machine is working
	var/efficiency = 0.9
	///Volume of the first point
	var/first_volume = 500
	///Volume of the second point
	var/second_volume = 1000
	///Rotation per minute of the turbine
	var/rpm = 0
	///Amount of power generated each tick
	var/generated_power = 0
	///Amount of gas allowed to enter in the inlet
	var/input_ratio = 50
	///Variable determined by the gas passing through, affect the heat movement after the passage
	var/heat_transfer_coefficient = 1
	///Variable determined by the gas passing through, affect the efficiency of the machine
	var/efficiency_coefficient = 1
	///Variable determined by the gas passing through, affect the rotation per minute of the machine
	var/rpm_coefficient = 1

/obj/machinery/power/turbine/turbine_controller/Initialize()
	. = ..()
	SSair.start_processing_machine(src)
	first_point = new
	first_point.volume = first_volume
	second_point = new
	second_point.volume = second_volume

/obj/machinery/power/turbine/turbine_controller/Destroy()
	SSair.stop_processing_machine(src)
	disconnect_parts()
	first_point = null
	second_point = null
	turbine_parts = null
	return ..()

/obj/machinery/power/turbine/turbine_controller/attackby(obj/item/tool, mob/user, params)
	. = ..()
	if(!connected)
		balloon_alert(user, "Connect all parts first by using a multitool on this terminal")

/obj/machinery/power/turbine/turbine_controller/multitool_act(mob/living/user, obj/item/multitool/I)
	if(istype(I))
		if(connect_to_network())
			check_connection(user)
			return TRUE
		balloon_alert(user, "machine lacks a working power cable underneath")
	return TRUE

///Check if all the parts are properly placed and connect them all
/obj/machinery/power/turbine/turbine_controller/proc/check_connection(mob/living/user)
	if(connected)
		return
	var/turf/controller = get_turf(src)
	var/turf/vertical = get_step(controller, turn(dir, 180))
	var/turf/horizontal = get_step(get_step(controller, turn(dir, 90)), turn(dir, 90))
	var/turf/diagonal
	if(dir & NORTH || dir & SOUTH)
		diagonal = locate(horizontal.x, vertical.y, controller.z)
	else
		diagonal = locate(vertical.x, horizontal.y, controller.z)

	for(var/turf/floor in block(vertical, diagonal))
		for(var/obj/machinery/machine in floor.contents)
			if(istype(machine, /obj/machinery/atmospherics/components/unary/turbine/turbine_inlet))
				if(machine.dir == turn(dir, 270))
					turbine_parts |= machine
					inlet = machine
					RegisterSignal(inlet, COMSIG_PARENT_QDELETING, .proc/disconnect_parts)
			if(istype(machine, /obj/machinery/atmospherics/components/unary/turbine/turbine_outlet))
				if(machine.dir == turn(dir, 90))
					turbine_parts |= machine
					outlet = machine
					RegisterSignal(outlet, COMSIG_PARENT_QDELETING, .proc/disconnect_parts)
			if(istype(machine, /obj/machinery/power/turbine/turbine_shaft))
				if(machine.dir == turn(dir, 90))
					turbine_parts |= machine
					shaft = machine
					RegisterSignal(shaft, COMSIG_PARENT_QDELETING, .proc/disconnect_parts)

	if(turbine_parts.len == 3)
		connected = TRUE
		inlet.connected = TRUE
		outlet.connected = TRUE
		shaft.connected = TRUE
		balloon_alert(user, "all parts connected")
	else
		if(!inlet)
			balloon_alert(user, "turbine inlet missing or misplaced")
		if(!outlet)
			balloon_alert(user, "turbine outlet missing or misplaced")
		if(!shaft)
			balloon_alert(user, "turbine shaft missing or misplaced")

	call_update_appearances()

///Disconnect all parts, unregister signals
/obj/machinery/power/turbine/turbine_controller/proc/disconnect_parts()
	SIGNAL_HANDLER
	connected = FALSE
	if(inlet)
		inlet.connected = FALSE
		inlet = null
	if(outlet)
		outlet.connected = FALSE
		outlet = null
	if(shaft)
		shaft.connected = FALSE
		shaft = null
	turbine_parts = list()
	UnregisterSignal(inlet, COMSIG_PARENT_QDELETING)
	UnregisterSignal(outlet, COMSIG_PARENT_QDELETING)
	UnregisterSignal(shaft, COMSIG_PARENT_QDELETING)

/obj/machinery/power/turbine/turbine_controller/process_atmos()
	if(!connected || !on)
		return

	if(!inlet.airs[1].gases)
		return

	var/datum/gas_mixture/input_remove = inlet.airs[1].remove_ratio(input_ratio * 0.01)
	var/datum/gas_mixture/output = outlet.airs[1]

	if(!input_remove.heat_capacity())
		return

	heat_transfer_coefficient = 1
	efficiency_coefficient = 0
	rpm_coefficient = 1

	check_gas_composition(input_remove)

	first_point.merge(input_remove)
	var/first_point_pressure = first_point.return_pressure()
	var/first_point_temperature = first_point.return_temperature()
	var/datum/gas_mixture/first_remove = first_point.remove_ratio(1)

	second_point.merge(first_remove)
	var/second_point_temperature = second_point.temperature
	var/heat_capacity = second_point.heat_capacity()
	var/expansion_work = first_point.total_moles() * R_IDEAL_GAS_EQUATION * first_point_temperature * log(first_point.volume / second_point.volume)
	second_point_temperature = max((second_point_temperature * heat_capacity - expansion_work * second_point.total_moles() * 0.05 * heat_transfer_coefficient) / heat_capacity, TCMB)

	var/second_point_pressure = second_point.return_pressure()

	var/work_done = 0
	var/delta_pressure = - (second_point_pressure - first_point_pressure)
	if(first_point_temperature > 300 || delta_pressure > 500)
		work_done = efficiency * second_point.total_moles() * R_IDEAL_GAS_EQUATION * second_point_temperature * log((first_point_pressure / second_point_pressure)) - rpm

	rpm = (work_done ** 0.6) * 8 * rpm_coefficient

	efficiency = clamp(1 - log(10, max(first_point_temperature, 1e3)) * 0.1 + efficiency_coefficient, 0, 1)

	generated_power = rpm * efficiency * 10

	add_avail(generated_power)

	second_point.temperature = max((second_point.temperature * heat_capacity - work_done * second_point.total_moles() * 0.05 * heat_transfer_coefficient) / heat_capacity, TCMB)

	var/datum/gas_mixture/second_remove = second_point.remove_ratio(1)

	output.merge(second_remove)

	inlet.update_parents()
	outlet.update_parents()

///Check the input mixture for specific gases that will affect the performances of the turbine
/obj/machinery/power/turbine/turbine_controller/proc/check_gas_composition(datum/gas_mixture/mix_to_check)
	if(!mix_to_check)
		return
	for(var/gas_id in mix_to_check.gases)
		switch(gas_id)
			if(/datum/gas/water_vapor)
				heat_transfer_coefficient += 0.2
				efficiency_coefficient -= 0.05
				rpm_coefficient += 0.1
			if(/datum/gas/carbon_dioxide)
				heat_transfer_coefficient -= 0.1
				efficiency_coefficient += 0.1
				rpm_coefficient += 0.03
			if(/datum/gas/freon)
				heat_transfer_coefficient += 0.5
				efficiency_coefficient -= 0.1
				rpm_coefficient += 0.3
			if(/datum/gas/nitrous_oxide)
				heat_transfer_coefficient += 0.05
				efficiency_coefficient += 0.3
				rpm_coefficient += 0.15
			if(/datum/gas/hypernoblium)
				heat_transfer_coefficient += 0.7
				efficiency_coefficient += 0.2
				rpm_coefficient += 0.3

///Call all update_appearance() of the connected machines
/obj/machinery/power/turbine/turbine_controller/proc/call_update_appearances()
	update_appearance()
	if(inlet)
		inlet.update_appearance()
	if(outlet)
		outlet.update_appearance()
	if(shaft)
		shaft.update_appearance()

/obj/machinery/power/turbine/turbine_controller/ui_interact(mob/user, datum/tgui/ui)
	if(panel_open)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TurbineController", name)
		ui.open()

/obj/machinery/power/turbine/turbine_controller/ui_data(mob/user)
	var/list/data = list()
	data["on"] = on
	data["connected"] = connected
	data["input_ratio"] = input_ratio
	data["rpm"] = rpm
	data["powergen"] = generated_power
	data["first_pressure"] = first_point.return_pressure()
	data["first_temperature"] = first_point.temperature
	data["second_pressure"] = second_point.return_pressure()
	data["second_temperature"] = second_point.temperature
	return data

/obj/machinery/power/turbine/turbine_controller/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("on")
			on = !on
			inlet.on = !on
			outlet.on = !on
			shaft.on = !on
			. = TRUE
		if("disconnect")
			if(connected)
				disconnect_parts()
			. = TRUE
		if("target")
			var/target = params["target"]
			input_ratio = clamp(target, 0, 100)
			. = TRUE

	call_update_appearances()

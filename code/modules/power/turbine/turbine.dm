///Multiplier for converting work done into rpm and rpm in energy out
#define TURBINE_RPM_CONVERSION 15
///Efficiency of the turbine to turn work into energy, higher values will yield more power
#define TURBINE_ENERGY_RECTIFICATION_MULTIPLIER 0.25
///Max allowed damage per tick
#define TURBINE_MAX_TAKEN_DAMAGE 10
///Amount of damage healed when under the heat threshold
#define TURBINE_DAMAGE_HEALING 2
///Amount of damage that the machine must have to start launching alarms to the engi comms
#define TURBINE_DAMAGE_ALARM_START 30
///Multiplier when converting the gas energy into gas work
#define TURBINE_WORK_CONVERSION_MULTIPLIER 0.01
///Multiplier when converting gas work back into heat
#define TURBINE_HEAT_CONVERSION_MULTIPLIER 0.005
///Amount of energy removed from the work done by the stator due to the consumption from the compressor working on the gases
#define TURBINE_COMPRESSOR_STATOR_INTERACTION_MULTIPLIER 0.15

/obj/machinery/power/turbine
	density = TRUE
	resistance_flags = FIRE_PROOF
	can_atmos_pass = ATMOS_PASS_DENSITY

	///Theoretical volume of gas that's moving through the turbine, it expands the further it goes
	var/gas_theoretical_volume = 0
	///Stores the turf thermal conductivity to restore it later
	var/our_turf_thermal_conductivity
	///Checks if the machine is processing or not
	var/active = FALSE
	///The parts can be registered on the main one only when their panel is closed
	var/can_connect = TRUE

	///Overlay for panel_open
	var/open_overlay //#TODO: get the overlay done
	///Overlay for machine activation
	var/on_overlay //#TODO: get the overlay done

	///Reference to our turbine part
	var/obj/item/turbine_parts/installed_part
	///Path of the turbine part we can install
	var/part_path

	var/installed_part_efficiency

	var/has_gasmix = FALSE
	var/datum/gas_mixture/machine_gasmix

/obj/machinery/power/turbine/Initialize(mapload)
	. = ..()

	if(has_gasmix)
		machine_gasmix = new
		machine_gasmix.volume = gas_theoretical_volume

	if(part_path)
		installed_part = new part_path(src)
		installed_part_efficiency = installed_part.part_efficiency

	var/turf/our_turf = get_turf(src)
	if(our_turf.thermal_conductivity != 0 && isopenturf(our_turf))
		our_turf_thermal_conductivity = our_turf.thermal_conductivity
		our_turf.thermal_conductivity = 0

/obj/machinery/power/turbine/Destroy()
	var/turf/our_turf = get_turf(src)
	if(our_turf.thermal_conductivity == 0 && isopenturf(our_turf))
		our_turf.thermal_conductivity = our_turf_thermal_conductivity

	if(installed_part)
		QDEL_NULL(installed_part)

	if(machine_gasmix)
		machine_gasmix = null

	return ..()

/obj/machinery/power/turbine/screwdriver_act(mob/living/user, obj/item/tool)
	if(active)
		to_chat(user, "You can't open [src] while it's on!")
		return TOOL_ACT_TOOLTYPE_SUCCESS
	if(!anchored)
		to_chat(user, span_notice("Anchor [src] first!"))
		return TOOL_ACT_TOOLTYPE_SUCCESS

	tool.play_tool_sound(src, 50)
	panel_open = !panel_open
	if(panel_open)
		disable_parts(user)
	else
		enable_parts(user)
	var/descriptor = panel_open ? "open" : "close"
	balloon_alert(user, "you [descriptor] the maintenance hatch of [src]")
	update_appearance()
	return TOOL_ACT_TOOLTYPE_SUCCESS

/obj/machinery/power/turbine/update_overlays()
	. = ..()
	if(panel_open)
		. += open_overlay
	if(active)
		. += on_overlay

/obj/machinery/power/turbine/wrench_act(mob/living/user, obj/item/tool)
	return default_change_direction_wrench(user, tool)

/obj/machinery/power/turbine/crowbar_act(mob/living/user, obj/item/tool)
	return default_deconstruction_crowbar(tool)

/obj/machinery/power/turbine/proc/enable_parts(mob/user)
	can_connect = TRUE

/obj/machinery/power/turbine/proc/disable_parts(mob/user)
	can_connect = FALSE

/obj/machinery/power/turbine/Moved(atom/OldLoc, Dir)
	. = ..()
	var/turf/old_turf = get_turf(OldLoc)
	old_turf.thermal_conductivity = our_turf_thermal_conductivity
	var/turf/new_turf = get_turf(src)
	if(new_turf)
		our_turf_thermal_conductivity = new_turf.thermal_conductivity
		new_turf.thermal_conductivity = 0

/obj/machinery/power/turbine/attackby(obj/item/object, mob/user, params)
	if(!panel_open)
		balloon_alert(user, "open the maintenance hatch first")
		return ..()

	if(!istype(object, part_path))
		return ..()

	install_part(object, user)

/obj/machinery/power/turbine/proc/install_part(obj/item/turbine_parts/part_object, mob/user)
	if(!installed_part)
		if(!do_after(user, 2 SECONDS, src))
			return
		user.transferItemToLoc(part_object, src)
		installed_part = part_object
		installed_part_efficiency = part_object.part_efficiency
		calculate_parts_limits()
		balloon_alert(user, "installed new part")
		return
	if(installed_part.part_efficiency < part_object.part_efficiency)
		if(!do_after(user, 2 SECONDS, src))
			return
		user.transferItemToLoc(part_object, src)
		user.put_in_hands(installed_part)
		installed_part = part_object
		installed_part_efficiency = part_object.part_efficiency
		calculate_parts_limits()
		balloon_alert(user, "replaced part with a better one")
		return

	balloon_alert(user, "a better part is installed")

/obj/machinery/power/turbine/proc/calculate_parts_limits()
	return

/obj/machinery/power/turbine/inlet_compressor
	name = "inlet compressor"
	desc = "The input side of a turbine generator, contains the compressor."
	icon = 'icons/obj/turbine/turbine.dmi'
	icon_state = "inlet_compressor"

	circuit = /obj/item/circuitboard/machine/turbine_compressor

	gas_theoretical_volume = 1000

	part_path = /obj/item/turbine_parts/compressor

	has_gasmix = TRUE

	///Reference to the core part
	var/obj/machinery/power/turbine/core_rotor/core

/obj/machinery/power/turbine/inlet_compressor/Destroy()
	if(core)
		core = null
	return ..()

/obj/machinery/power/turbine/turbine_outlet
	name = "turbine outlet"
	desc = "The output side of a turbine generator, contains the turbine and the stator."
	icon = 'icons/obj/turbine/turbine.dmi'
	icon_state = "turbine_outlet"

	circuit = /obj/item/circuitboard/machine/turbine_stator

	gas_theoretical_volume = 6000

	part_path = /obj/item/turbine_parts/stator

	has_gasmix = TRUE

	///Reference to the core part
	var/obj/machinery/power/turbine/core_rotor/core

/obj/machinery/power/turbine/turbine_outlet/Destroy()
	if(core)
		core = null
	return ..()

/obj/machinery/power/turbine/core_rotor
	name = "core rotor"
	desc = "The middle part of a turbine generator, contains the rotor and the main computer."
	icon = 'icons/obj/turbine/turbine.dmi'
	icon_state = "core_rotor"

	circuit = /obj/item/circuitboard/machine/turbine_rotor

	gas_theoretical_volume = 3000

	part_path = /obj/item/turbine_parts/rotor

	has_gasmix = TRUE

	///ID to easily connect the main part of the turbine to the computer
	var/mapping_id

	///Reference to the compressor
	var/obj/machinery/power/turbine/inlet_compressor/compressor
	///Reference to the turbine
	var/obj/machinery/power/turbine/turbine_outlet/turbine

	///Reference to the input turf
	var/turf/open/input_turf
	///Reference to the output turf
	var/turf/open/output_turf

	///Rotation per minute the machine is doing
	var/rpm
	///Amount of power the machine is producing
	var/produced_energy

	///Check to see if all parts are connected to the core
	var/all_parts_connected = FALSE
	///If the machine was completed before reopening it, try to remake it
	var/was_complete = FALSE

	///Max rmp that the installed parts can handle, limits the rpms
	var/max_allowed_rpm = 0
	///Max temperature that the installed parts can handle, unlimited and causes damage to the machine
	var/max_allowed_temperature = 0

	///Amount of damage the machine has received
	var/damage = 0
	///Used to calculate the max damage received per tick and if the alarm should be called
	var/damage_archived = 0

	///Our internal radio
	var/obj/item/radio/radio
	///The key our internal radio uses
	var/radio_key = /obj/item/encryptionkey/headset_eng
	///The engineering channel
	var/engineering_channel = "Engineering"

	COOLDOWN_DECLARE(turbine_damage_alert)

/obj/machinery/power/turbine/core_rotor/Initialize(mapload)
	. = ..()
	radio = new(src)
	radio.keyslot = new radio_key
	radio.set_listening(FALSE)
	radio.recalculateChannels()

/obj/machinery/power/turbine/core_rotor/LateInitialize()
	. = ..()
	activate_parts()

/obj/machinery/power/turbine/core_rotor/Destroy()
	disable_parts()
	QDEL_NULL(radio)
	return ..()

/obj/machinery/power/turbine/core_rotor/enable_parts(mob/user)
	. = ..()
	if(was_complete)
		was_complete = FALSE
		activate_parts(user)

/obj/machinery/power/turbine/core_rotor/disable_parts(mob/user)
	. = ..()
	if(all_parts_connected)
		was_complete = TRUE
	deactivate_parts()

/obj/machinery/power/turbine/core_rotor/multitool_act(mob/living/user, obj/item/tool)
	if(!all_parts_connected && activate_parts(user))
		balloon_alert(user, "all parts are linked")
	return TOOL_ACT_TOOLTYPE_SUCCESS

/obj/machinery/power/turbine/core_rotor/multitool_act_secondary(mob/living/user, obj/item/tool)
	if(!all_parts_connected)
		return TOOL_ACT_TOOLTYPE_SUCCESS
	var/obj/item/multitool/multitool = tool
	multitool.buffer = src
	to_chat(user, span_notice("You store linkage information in [tool]'s buffer."))
	return TOOL_ACT_TOOLTYPE_SUCCESS

/obj/machinery/power/turbine/core_rotor/proc/activate_parts(mob/user)

	compressor = locate(/obj/machinery/power/turbine/inlet_compressor) in get_step(src, turn(dir, 180))
	turbine = locate(/obj/machinery/power/turbine/turbine_outlet) in get_step(src, dir)

	if(!compressor || !turbine)
		if(user)
			balloon_alert(user, "missing parts detected")
		return FALSE

	var/parts_present = TRUE
	if(compressor.dir != dir || !compressor.can_connect)
		if(user)
			balloon_alert(user, "wrong compressor direction")
		parts_present = FALSE
	if(turbine.dir != dir || !turbine.can_connect)
		if(user)
			balloon_alert(user, "wrong turbine direction")
		parts_present = FALSE

	if(!parts_present)
		all_parts_connected = FALSE
		return FALSE

	compressor.core = src
	turbine.core = src

	input_turf = get_step(compressor.loc, turn(dir, 180))
	output_turf = get_step(turbine.loc, dir)

	all_parts_connected = TRUE

	calculate_parts_limits()

	SSair.start_processing_machine(src)
	return TRUE

/obj/machinery/power/turbine/core_rotor/proc/deactivate_parts()
	compressor?.core = null
	turbine?.core = null
	compressor = null
	turbine = null
	input_turf = null
	output_turf = null
	all_parts_connected = FALSE
	SSair.stop_processing_machine(src)

/obj/machinery/power/turbine/core_rotor/on_deconstruction()
	if(all_parts_connected)
		deactivate_parts()
	return ..()

/obj/machinery/power/turbine/core_rotor/calculate_parts_limits()
	max_allowed_rpm = (compressor.installed_part.max_rpm + turbine.installed_part.max_rpm + installed_part.max_rpm) / 3
	max_allowed_temperature = (compressor.installed_part.max_temperature + turbine.installed_part.max_temperature + installed_part.max_temperature) / 3

/obj/machinery/power/turbine/core_rotor/proc/calculate_damage_done(temperature)
	damage_archived = damage
	var/temperature_difference = temperature - max_allowed_temperature
	var/damage_done = round(log(90, max(temperature_difference, 1)), 0.5)

	damage = max(damage + damage_done * 0.5, 0)
	damage = min(damage_archived + TURBINE_MAX_TAKEN_DAMAGE, damage)
	if(temperature_difference < 0)
		damage = max(damage - TURBINE_DAMAGE_HEALING, 0)

	if((damage - damage_archived >= 2 || damage > TURBINE_DAMAGE_ALARM_START) && COOLDOWN_FINISHED(src, turbine_damage_alert))
		damage_alert(damage_done)

/obj/machinery/power/turbine/core_rotor/proc/damage_alert(damage_done)
	COOLDOWN_START(src, turbine_damage_alert, max(round(TURBINE_DAMAGE_ALARM_START - damage_done), 5) SECONDS)

	var/integrity = get_turbine_integrity()

	if(integrity <= 0)
		failure()
		return

	radio.talk_into(src, "Warning, turbine at [get_area_name(src)] taking damage, current integrity at [integrity]%!", engineering_channel)

/obj/machinery/power/turbine/core_rotor/proc/get_turbine_integrity()
	var/integrity = damage / 500
	integrity = max(round(100 - integrity * 100, 0.01), 0)
	return integrity

/obj/machinery/power/turbine/core_rotor/proc/failure()
	deactivate_parts()
	if(rpm < 35000)
		explosion(src, 0, 1, 4)
		return
	if(rpm < 87500)
		explosion(src, 0, 2, 6)
		return
	if(rpm < 220000)
		explosion(src, 1, 3, 7)
		return
	if(rpm < 550000)
		explosion(src, 2, 5, 7)

/obj/machinery/power/turbine/core_rotor/process_atmos()

	if(!active || !all_parts_connected)
		return

	var/datum/gas_mixture/input_turf_mixture = input_turf.return_air()

	if(!input_turf_mixture)
		return

	calculate_damage_done(input_turf_mixture.temperature)

	var/compressor_work = do_calculations(input_turf_mixture, compressor.machine_gasmix)
	input_turf.air_update_turf(TRUE)
	var/compressor_pressure = max(compressor.machine_gasmix.return_pressure(), 0.01)

	var/rotor_work = do_calculations(compressor.machine_gasmix, machine_gasmix, compressor_work)

	var/turbine_work = do_calculations(machine_gasmix, turbine.machine_gasmix, abs(rotor_work))

	var/turbine_pressure = max(turbine.machine_gasmix.return_pressure(), 0.01)

	var/work_done = turbine.machine_gasmix.total_moles() * R_IDEAL_GAS_EQUATION * turbine.machine_gasmix.temperature * log(compressor_pressure / turbine_pressure)

	work_done = max(work_done - compressor_work * TURBINE_COMPRESSOR_STATOR_INTERACTION_MULTIPLIER - turbine_work, 0)

	rpm = ((work_done * compressor.installed_part_efficiency) ** turbine.installed_part_efficiency) * installed_part_efficiency / TURBINE_RPM_CONVERSION
	rpm = min(rpm, max_allowed_rpm)

	produced_energy = rpm * TURBINE_ENERGY_RECTIFICATION_MULTIPLIER * TURBINE_RPM_CONVERSION

	add_avail(produced_energy)

	turbine.machine_gasmix.pump_gas_to(output_turf.air, turbine.machine_gasmix.return_pressure())
	output_turf.air_update_turf(TRUE)

/obj/machinery/power/turbine/core_rotor/proc/do_calculations(datum/gas_mixture/input_mix, datum/gas_mixture/output_mix, work_amount_to_remove)
	var/work_done = input_mix.total_moles() * R_IDEAL_GAS_EQUATION * input_mix.temperature * log((input_mix.volume * max(input_mix.return_pressure(), 0.01)) / (output_mix.volume * max(output_mix.return_pressure(), 0.01))) * TURBINE_WORK_CONVERSION_MULTIPLIER
	if(work_amount_to_remove)
		work_done = work_done - work_amount_to_remove
	input_mix.pump_gas_to(output_mix, input_mix.return_pressure())
	var/output_mix_heat_capacity = output_mix.heat_capacity()
	if(!output_mix_heat_capacity)
		return 0
	output_mix.temperature = max((output_mix.temperature * output_mix_heat_capacity + work_done * output_mix.total_moles() * TURBINE_HEAT_CONVERSION_MULTIPLIER) / output_mix_heat_capacity, TCMB)
	return work_done

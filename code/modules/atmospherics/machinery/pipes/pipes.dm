/obj/machinery/atmospherics/pipe
	icon = 'icons/obj/atmospherics/pipes/pipes_bitmask.dmi'
	damage_deflection = 12

	use_power = NO_POWER_USE
	can_unwrench = 1

	paintable = TRUE

	//Buckling
	can_buckle = TRUE
	buckle_requires_restraints = TRUE
	buckle_lying = NO_BUCKLE_LYING

	vis_flags = VIS_INHERIT_PLANE

	var/datum/pipeline/parent = null

	///used when reconstructing a pipeline that broke
	var/datum/gas_mixture/air_temporary

	var/volume = 0

/obj/machinery/atmospherics/pipe/New()
	add_atom_colour(pipe_color, FIXED_COLOUR_PRIORITY)
	volume = 35 * device_type
	. = ..()

//I have no idea why there's a new and at this point I'm too afraid to ask
/obj/machinery/atmospherics/pipe/Initialize(mapload)
	. = ..()

	if(hide)
		//var/mutable_appearance/t_ray_overlay = mutable_appearance(icon, icon_state, layer, T_RAY_PLANE, 128)
		//AddElement(/datum/element/undertile, TRAIT_T_RAY_VISIBLE, tile_overlay = t_ray_overlay, nullspace_target = TRUE) //if changing this, change the subtypes RemoveElements too, because thats how bespoke works
		AddComponent(/datum/component/nullspace_undertile, invisibility_trait = TRAIT_T_RAY_VISIBLE, nullspace_when_underfloor_visible = TRUE)

/obj/machinery/atmospherics/pipe/nullify_node(i)
	var/obj/machinery/atmospherics/old_node = nodes[i]
	. = ..()
	if(old_node)
		SSair.add_to_rebuild_queue(old_node)

/obj/machinery/atmospherics/pipe/destroy_network()
	QDEL_NULL(parent)

/obj/machinery/atmospherics/pipe/get_rebuild_targets()
	if(!QDELETED(parent))
		return
	parent = new
	return list(parent)

/obj/machinery/atmospherics/pipe/proc/releaseAirToTurf()
	if(air_temporary)
		associated_loc.assume_air(air_temporary)

/obj/machinery/atmospherics/pipe/return_air()
	if(air_temporary)
		return air_temporary
	return parent.air

/obj/machinery/atmospherics/pipe/return_analyzable_air()
	if(air_temporary)
		return air_temporary
	return parent.air

/obj/machinery/atmospherics/pipe/remove_air(amount)
	if(air_temporary)
		return air_temporary.remove(amount)
	return parent.air.remove(amount)

/obj/machinery/atmospherics/pipe/attackby(obj/item/item, mob/user, params)
	if(istype(item, /obj/item/pipe_meter))
		var/obj/item/pipe_meter/meter = item
		user.dropItemToGround(meter)
		meter.setAttachLayer(piping_layer)
	else
		return ..()

/obj/machinery/atmospherics/pipe/return_pipenet()
	return parent

/obj/machinery/atmospherics/pipe/set_pipenet(datum/pipeline/pipenet_to_set)
	parent = pipenet_to_set

/obj/machinery/atmospherics/pipe/Destroy()
	QDEL_NULL(parent)

	releaseAirToTurf()

	for(var/obj/machinery/meter/meter in associated_loc)
		if(meter.target != src)
			continue
		var/obj/item/pipe_meter/meter_object = new (associated_loc)
		meter.transfer_fingerprints_to(meter_object)
		qdel(meter)
	return ..()

/obj/machinery/atmospherics/pipe/proc/update_pipe_icon()
	icon = 'icons/obj/atmospherics/pipes/pipes_bitmask.dmi'
	var/connections = NONE
	var/bitfield = NONE
	for(var/i in 1 to device_type)
		if(!nodes[i])
			continue
		var/obj/machinery/atmospherics/node = nodes[i]
		var/connected_dir = get_dir(associated_loc, node.associated_loc)
		connections |= connected_dir

	bitfield = CARDINAL_TO_FULLPIPES(connections)
	bitfield |= CARDINAL_TO_SHORTPIPES(initialize_directions & ~connections)
	icon_state = "[bitfield]_[piping_layer]"

/obj/machinery/atmospherics/pipe/update_icon()
	. = ..()
	update_pipe_icon()
	update_layer()

/obj/machinery/atmospherics/proc/update_node_icon()
	for(var/i in 1 to device_type)
		if(!nodes[i])
			continue
		var/obj/machinery/atmospherics/current_node = nodes[i]
		current_node.update_icon()

/obj/machinery/atmospherics/pipe/return_pipenets()
	. = list(parent)

/obj/machinery/atmospherics/pipe/paint(paint_color)
	if(paintable)
		add_atom_colour(paint_color, FIXED_COLOUR_PRIORITY)
		pipe_color = paint_color
		update_node_icon()
	return paintable

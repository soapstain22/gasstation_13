/datum/component/extralasers
	dupe_mode = COMPONENT_DUPE_UNIQUE_PASSARGS
	var/lens

/datum/component/extralasers/Initialize(ammo, _lens)
	if(!istype(parent, /obj/item/gun/energy/laser))
		return COMPONENT_INCOMPATIBLE
	var/obj/item/gun/energy/laser/L = parent
	L.ammo_type  += new ammo (src)
	lens = _lens
	qdel(_lens)
	RegisterSignal(parent, COMSIG_PARENT_ATTACKBY, .proc/detach)

/datum/component/extralasers/proc/detach(datum/source, obj/item/I, mob/user, params)
	if(I.tool_behaviour == TOOL_CROWBAR)
		var/obj/item/gun/energy/laser/L = parent
		L.chambered = null
		var/obj/item/ammo_casing/energy/R = LAZYACCESS(L.ammo_type, L.ammo_type.len)
		LAZYREMOVE(L.ammo_type, R)
		L.select_fire(user)
		L.recharge_newshot()
		L.update_icon(TRUE)
		RemoveComponent()
		var/turf/T = user.loc
		new lens(T)
		return TRUE
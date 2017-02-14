
// Teleporter, Wormhole generator, Gravitational catapult, Armor booster modules,
// Repair droid, Tesla Energy relay, Generators

////////////////////////////////////////////// TELEPORTER ///////////////////////////////////////////////

/obj/item/mecha_parts/mecha_equipment/teleporter
	name = "mounted teleporter"
	desc = "An exosuit module that allows exosuits to teleport to any position in view."
	icon_state = "mecha_teleport"
	origin_tech = "bluespace=7"
	equip_cooldown = 150
	energy_drain = 1000
	range = RANGED

/obj/item/mecha_parts/mecha_equipment/teleporter/action(atom/target)
	if(!action_checks(target) || src.loc.z == ZLEVEL_CENTCOM) return
	var/turf/T = get_turf(target)
	if(T)
		do_teleport(chassis, T, 4)
		return 1



////////////////////////////////////////////// WORMHOLE GENERATOR //////////////////////////////////////////

/obj/item/mecha_parts/mecha_equipment/wormhole_generator
	name = "mounted wormhole generator"
	desc = "An exosuit module that allows generating of small quasi-stable wormholes."
	icon_state = "mecha_wholegen"
	origin_tech = "bluespace=4;magnets=4;plasmatech=2"
	equip_cooldown = 50
	energy_drain = 300
	range = RANGED


/obj/item/mecha_parts/mecha_equipment/wormhole_generator/action(atom/target)
	if(!action_checks(target) || src.loc.z == ZLEVEL_CENTCOM)
		return
	var/list/theareas = get_areas_in_range(100, chassis)
	if(!theareas.len)
		return
	var/area/thearea = pick(theareas)
	var/list/L = list()
	var/turf/pos = get_turf(src)
	for(var/turf/T in get_area_turfs(thearea.type))
		if(!T.density && pos.z == T.z)
			var/clear = 1
			for(var/obj/O in T)
				if(O.density)
					clear = 0
					break
			if(clear)
				L+=T
	if(!L.len)
		return
	var/turf/target_turf = pick(L)
	if(!target_turf)
		return
	var/obj/effect/portal/P = new /obj/effect/portal(get_turf(target))
	P.target = target_turf
	P.creator = null
	P.icon = 'icons/obj/objects.dmi'
	P.icon_state = "anom"
	P.name = "wormhole"
	P.mech_sized = TRUE
	var/turf/T = get_turf(target)
	message_admins("[ADMIN_LOOKUPFLW(chassis.occupant)] used a Wormhole Generator in [ADMIN_COORDJMP(T)]",0,1)
	log_game("[key_name(chassis.occupant)] used a Wormhole Generator in [COORD(T)]")
	src = null
	spawn(rand(150,300))
		qdel(P)
	return 1


/////////////////////////////////////// GRAVITATIONAL CATAPULT ///////////////////////////////////////////

/obj/item/mecha_parts/mecha_equipment/gravcatapult
	name = "mounted gravitational catapult"
	desc = "An exosuit mounted Gravitational Catapult."
	icon_state = "mecha_teleport"
	origin_tech = "bluespace=3;magnets=3;engineering=4"
	equip_cooldown = 10
	energy_drain = 100
	range = MELEE|RANGED
	var/atom/movable/locked
	var/mode = 1 //1 - gravsling 2 - gravpush


/obj/item/mecha_parts/mecha_equipment/gravcatapult/action(atom/movable/target)
	if(!action_checks(target))
		return
	switch(mode)
		if(1)
			if(!locked)
				if(!istype(target) || target.anchored)
					occupant_message("Unable to lock on [target]")
					return
				locked = target
				occupant_message("Locked on [target]")
				send_byjax(chassis.occupant,"exosuit.browser","\ref[src]",src.get_equip_info())
			else if(target!=locked)
				if(locked in view(chassis))
					locked.throw_at(target, 14, 1.5)
					locked = null
					send_byjax(chassis.occupant,"exosuit.browser","\ref[src]",src.get_equip_info())
					return 1
				else
					locked = null
					occupant_message("Lock on [locked] disengaged.")
					send_byjax(chassis.occupant,"exosuit.browser","\ref[src]",src.get_equip_info())
		if(2)
			var/list/atoms = list()
			if(isturf(target))
				atoms = range(3, target)
			else
				atoms = orange(3, target)
			for(var/atom/movable/A in atoms)
				if(A.anchored) continue
				spawn(0)
					var/iter = 5-get_dist(A,target)
					for(var/i=0 to iter)
						step_away(A,target)
						sleep(2)
			var/turf/T = get_turf(target)
			log_game("[chassis.occupant.ckey]([chassis.occupant]) used a Gravitational Catapult in ([T.x],[T.y],[T.z])")
			return 1


/obj/item/mecha_parts/mecha_equipment/gravcatapult/get_equip_info()
	return "[..()] [mode==1?"([locked||"Nothing"])":null] \[<a href='?src=\ref[src];mode=1'>S</a>|<a href='?src=\ref[src];mode=2'>P</a>\]"

/obj/item/mecha_parts/mecha_equipment/gravcatapult/Topic(href, href_list)
	..()
	if(href_list["mode"])
		mode = text2num(href_list["mode"])
		send_byjax(chassis.occupant,"exosuit.browser","\ref[src]",src.get_equip_info())
	return




//////////////////////////// ARMOR BOOSTER MODULES //////////////////////////////////////////////////////////


/obj/item/mecha_parts/mecha_equipment/anticcw_armor_booster //what is that noise? A BAWWW from TK mutants.
	name = "armor booster module (Close Combat Weaponry)"
	desc = "Boosts exosuit armor against armed melee attacks. Requires energy to operate."
	icon_state = "mecha_abooster_ccw"
	origin_tech = "materials=4;combat=4"
	equip_cooldown = 10
	energy_drain = 50
	range = 0
	var/deflect_coeff = 1.15
	var/damage_coeff = 0.8
	selectable = 0

/obj/item/mecha_parts/mecha_equipment/anticcw_armor_booster/proc/attack_react()
	if(action_checks(src))
		start_cooldown()
		return 1



/obj/item/mecha_parts/mecha_equipment/antiproj_armor_booster
	name = "armor booster module (Ranged Weaponry)"
	desc = "Boosts exosuit armor against ranged attacks. Completely blocks taser shots. Requires energy to operate."
	icon_state = "mecha_abooster_proj"
	origin_tech = "materials=4;combat=3;engineering=3"
	equip_cooldown = 10
	energy_drain = 50
	range = 0
	var/deflect_coeff = 1.15
	var/damage_coeff = 0.8
	selectable = 0

/obj/item/mecha_parts/mecha_equipment/antiproj_armor_booster/proc/projectile_react()
	if(action_checks(src))
		start_cooldown()
		return 1


////////////////////////////////// REPAIR DROID //////////////////////////////////////////////////


/obj/item/mecha_parts/mecha_equipment/repair_droid
	name = "exosuit repair droid"
	desc = "An automated repair droid for exosuits. Scans for damage and repairs it. Can fix almost all types of external or internal damage."
	icon_state = "repair_droid"
	origin_tech = "magnets=3;programming=3;engineering=4"
	energy_drain = 50
	range = 0
	var/health_boost = 1
	var/icon/droid_overlay
	var/list/repairable_damage = list(MECHA_INT_TEMP_CONTROL,MECHA_INT_TANK_BREACH)
	selectable = 0

/obj/item/mecha_parts/mecha_equipment/repair_droid/Destroy()
	if(chassis)
		chassis.overlays -= droid_overlay
	return ..()

/obj/item/mecha_parts/mecha_equipment/repair_droid/attach(obj/mecha/M as obj)
	..()
	droid_overlay = new(src.icon, icon_state = "repair_droid")
	M.add_overlay(droid_overlay)

/obj/item/mecha_parts/mecha_equipment/repair_droid/detach()
	chassis.overlays -= droid_overlay
	SSobj.stop_processing(src)
	..()

/obj/item/mecha_parts/mecha_equipment/repair_droid/get_equip_info()
	if(!chassis) return
	return "<span style=\"color:[equip_ready?"#0f0":"#f00"];\">*</span>&nbsp; [src.name] - <a href='?src=\ref[src];toggle_repairs=1'>[equip_ready?"A":"Dea"]ctivate</a>"


/obj/item/mecha_parts/mecha_equipment/repair_droid/Topic(href, href_list)
	..()
	if(href_list["toggle_repairs"])
		chassis.overlays -= droid_overlay
		if(equip_ready)
			SSobj.start_processing(src)
			droid_overlay = new(src.icon, icon_state = "repair_droid_a")
			log_message("Activated.")
			set_ready_state(0)
		else
			SSobj.stop_processing(src)
			droid_overlay = new(src.icon, icon_state = "repair_droid")
			log_message("Deactivated.")
			set_ready_state(1)
		chassis.add_overlay(droid_overlay)
		send_byjax(chassis.occupant,"exosuit.browser","\ref[src]",src.get_equip_info())


/obj/item/mecha_parts/mecha_equipment/repair_droid/process()
	if(!chassis)
		set_ready_state(1)
		return PROCESS_KILL
	var/h_boost = health_boost
	var/repaired = 0
	if(chassis.internal_damage & MECHA_INT_SHORT_CIRCUIT)
		h_boost *= -2
	else if(chassis.internal_damage && prob(15))
		for(var/int_dam_flag in repairable_damage)
			if(chassis.internal_damage & int_dam_flag)
				chassis.clearInternalDamage(int_dam_flag)
				repaired = 1
				break
	if(health_boost<0 || chassis.obj_integrity < chassis.max_integrity)
		chassis.obj_integrity += min(health_boost, chassis.max_integrity-chassis.obj_integrity)
		repaired = 1
	if(repaired)
		if(!chassis.use_power(energy_drain))
			set_ready_state(1)
			return PROCESS_KILL
	else //no repair needed, we turn off
		set_ready_state(1)
		chassis.overlays -= droid_overlay
		droid_overlay = new(src.icon, icon_state = "repair_droid")
		chassis.add_overlay(droid_overlay)
		return PROCESS_KILL




/////////////////////////////////// TESLA ENERGY RELAY ////////////////////////////////////////////////

/obj/item/mecha_parts/mecha_equipment/tesla_energy_relay
	name = "exosuit energy relay"
	desc = "An exosuit module that wirelessly drains energy from any available power channel in area. The performance index is quite low."
	icon_state = "tesla"
	origin_tech = "magnets=4;powerstorage=4;engineering=4"
	energy_drain = 0
	range = 0
	var/coeff = 100
	var/list/use_channels = list(EQUIP,ENVIRON,LIGHT)
	selectable = 0

/obj/item/mecha_parts/mecha_equipment/tesla_energy_relay/detach()
	SSobj.stop_processing(src)
	..()

/obj/item/mecha_parts/mecha_equipment/tesla_energy_relay/proc/get_charge()
	if(equip_ready) //disabled
		return
	var/area/A = get_area(chassis)
	var/pow_chan = get_power_channel(A)
	if(pow_chan)
		return 1000 //making magic


/obj/item/mecha_parts/mecha_equipment/tesla_energy_relay/proc/get_power_channel(var/area/A)
	var/pow_chan
	if(A)
		for(var/c in use_channels)
			if(A.master && A.master.powered(c))
				pow_chan = c
				break
	return pow_chan

/obj/item/mecha_parts/mecha_equipment/tesla_energy_relay/Topic(href, href_list)
	..()
	if(href_list["toggle_relay"])
		if(equip_ready) //inactive
			SSobj.start_processing(src)
			set_ready_state(0)
			log_message("Activated.")
		else
			SSobj.stop_processing(src)
			set_ready_state(1)
			log_message("Deactivated.")

/obj/item/mecha_parts/mecha_equipment/tesla_energy_relay/get_equip_info()
	if(!chassis) return
	return "<span style=\"color:[equip_ready?"#0f0":"#f00"];\">*</span>&nbsp; [src.name] - <a href='?src=\ref[src];toggle_relay=1'>[equip_ready?"A":"Dea"]ctivate</a>"


/obj/item/mecha_parts/mecha_equipment/tesla_energy_relay/process()
	if(!chassis || chassis.internal_damage & MECHA_INT_SHORT_CIRCUIT)
		set_ready_state(1)
		return PROCESS_KILL
	var/cur_charge = chassis.get_charge()
	if(isnull(cur_charge) || !chassis.cell)
		set_ready_state(1)
		occupant_message("No powercell detected.")
		return PROCESS_KILL
	if(cur_charge < chassis.cell.maxcharge)
		var/area/A = get_area(chassis)
		if(A)
			var/pow_chan
			for(var/c in list(EQUIP,ENVIRON,LIGHT))
				if(A.master.powered(c))
					pow_chan = c
					break
			if(pow_chan)
				var/delta = min(20, chassis.cell.maxcharge-cur_charge)
				chassis.give_power(delta)
				A.master.use_power(delta*coeff, pow_chan)




/////////////////////////////////////////// GENERATOR /////////////////////////////////////////////


/obj/item/mecha_parts/mecha_equipment/generator
	name = "exosuit plasma converter"
	desc = "An exosuit module that generates power using solid plasma as fuel. Pollutes the environment."
	icon_state = "tesla"
	origin_tech = "plasmatech=2;powerstorage=2;engineering=2"
	range = MELEE
	var/coeff = 100
	var/obj/item/stack/sheet/fuel
	var/max_fuel = 150000
	var/fuel_per_cycle_idle = 25
	var/fuel_per_cycle_active = 200
	var/power_per_cycle = 20

/obj/item/mecha_parts/mecha_equipment/generator/New()
	..()
	generator_init()

/obj/item/mecha_parts/mecha_equipment/generator/proc/generator_init()
	fuel = new /obj/item/stack/sheet/mineral/plasma(src)
	fuel.amount = 0

/obj/item/mecha_parts/mecha_equipment/generator/detach()
	SSobj.stop_processing(src)
	..()

/obj/item/mecha_parts/mecha_equipment/generator/Topic(href, href_list)
	..()
	if(href_list["toggle"])
		if(equip_ready) //inactive
			set_ready_state(0)
			SSobj.start_processing(src)
			log_message("Activated.")
		else
			set_ready_state(1)
			SSobj.stop_processing(src)
			log_message("Deactivated.")

/obj/item/mecha_parts/mecha_equipment/generator/get_equip_info()
	var/output = ..()
	if(output)
		return "[output] \[[fuel]: [round(fuel.amount*fuel.perunit,0.1)] cm<sup>3</sup>\] - <a href='?src=\ref[src];toggle=1'>[equip_ready?"A":"Dea"]ctivate</a>"

/obj/item/mecha_parts/mecha_equipment/generator/action(target)
	if(chassis)
		var/result = load_fuel(target)
		if(result)
			send_byjax(chassis.occupant,"exosuit.browser","\ref[src]",src.get_equip_info())

/obj/item/mecha_parts/mecha_equipment/generator/proc/load_fuel(var/obj/item/stack/sheet/P)
	if(P.type == fuel.type && P.amount > 0)
		var/to_load = max(max_fuel - fuel.amount*fuel.perunit,0)
		if(to_load)
			var/units = min(max(round(to_load / P.perunit),1),P.amount)
			fuel.amount += units
			P.use(units)
			occupant_message("[units] unit\s of [fuel] successfully loaded.")
			return units
		else
			occupant_message("Unit is full.")
			return 0
	else
		occupant_message("<span class='warning'>[fuel] traces in target minimal! [P] cannot be used as fuel.</span>")
		return

/obj/item/mecha_parts/mecha_equipment/generator/attackby(weapon,mob/user, params)
	load_fuel(weapon)

/obj/item/mecha_parts/mecha_equipment/generator/critfail()
	..()
	var/turf/open/T = get_turf(src)
	if(!istype(T))
		return
	var/datum/gas_mixture/GM = new
	GM.assert_gas("plasma")
	if(prob(10))
		GM.gases["plasma"][MOLES] += 100
		GM.temperature = 1500+T0C //should be enough to start a fire
		T.visible_message("The [src] suddenly disgorges a cloud of heated plasma.")
		qdel(src)
	else
		GM.gases["plasma"][MOLES] += 5
		GM.temperature = istype(T) ? T.air.return_temperature() : T20C
		T.visible_message("The [src] suddenly disgorges a cloud of plasma.")
	T.assume_air(GM)
	return

/obj/item/mecha_parts/mecha_equipment/generator/process()
	if(!chassis)
		set_ready_state(1)
		return PROCESS_KILL
	if(fuel.amount<=0)
		log_message("Deactivated - no fuel.")
		set_ready_state(1)
		return PROCESS_KILL
	var/cur_charge = chassis.get_charge()
	if(isnull(cur_charge))
		set_ready_state(1)
		occupant_message("No powercell detected.")
		log_message("Deactivated.")
		return PROCESS_KILL
	var/use_fuel = fuel_per_cycle_idle
	if(cur_charge < chassis.cell.maxcharge)
		use_fuel = fuel_per_cycle_active
		chassis.give_power(power_per_cycle)
	fuel.amount -= min(use_fuel/fuel.perunit,fuel.amount)
	update_equip_info()
	return 1


/obj/item/mecha_parts/mecha_equipment/generator/nuclear
	name = "exonuclear reactor"
	desc = "An exosuit module that generates power using uranium as fuel. Pollutes the environment."
	icon_state = "tesla"
	origin_tech = "powerstorage=4;engineering=4"
	max_fuel = 50000
	fuel_per_cycle_idle = 10
	fuel_per_cycle_active = 30
	power_per_cycle = 50
	var/rad_per_cycle = 0.3

/obj/item/mecha_parts/mecha_equipment/generator/nuclear/generator_init()
	fuel = new /obj/item/stack/sheet/mineral/uranium(src)
	fuel.amount = 0

/obj/item/mecha_parts/mecha_equipment/generator/nuclear/critfail()
	return

/obj/item/mecha_parts/mecha_equipment/generator/nuclear/process()
	if(..())
		radiation_pulse(get_turf(src), 2, 7, rad_per_cycle, 1)

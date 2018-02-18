/obj/item/device/integrated_circuit_printer
	name = "integrated circuit printer"
	desc = "A portable(ish) machine made to print tiny modular circuitry out of metal."
	icon = 'icons/obj/assemblies/electronic_tools.dmi'
	icon_state = "circuit_printer"
	w_class = WEIGHT_CLASS_BULKY
	var/upgraded = FALSE			// When hit with an upgrade disk, will turn true, allowing it to print the higher tier circuits.
	var/can_clone = FALSE		// Same for above, but will allow the printer to duplicate a specific assembly.
	var/current_category = null
	var/recycling = FALSE		// If an assembly is being emptied into this printer
	var/list/program			// Currently loaded save, in form of list

/obj/item/device/integrated_circuit_printer/proc/check_interactivity(mob/user)
	return user.canUseTopic(src, BE_CLOSE)

/obj/item/device/integrated_circuit_printer/upgraded
	upgraded = TRUE
	can_clone = TRUE

/obj/item/device/integrated_circuit_printer/Initialize()
	. = ..()
	AddComponent(/datum/component/material_container, list(MAT_METAL), MINERAL_MATERIAL_AMOUNT * 25, TRUE, list(/obj/item/stack, /obj/item/integrated_circuit, /obj/item/device/electronic_assembly))

/obj/item/device/integrated_circuit_printer/attackby(obj/item/O, mob/user)
	if(istype(O, /obj/item/disk/integrated_circuit/upgrade/advanced))
		if(upgraded)
			to_chat(user, "<span class='warning'>\The [src] already has this upgrade. </span>")
			return TRUE
		to_chat(user, "<span class='notice'>You install \the [O] into \the [src]. </span>")
		upgraded = TRUE
		qdel(O)
		interact(user)
		return TRUE

	if(istype(O, /obj/item/disk/integrated_circuit/upgrade/clone))
		if(can_clone)
			to_chat(user, "<span class='warning'>\The [src] already has this upgrade. </span>")
			return TRUE
		to_chat(user, "<span class='notice'>You install \the [O] into \the [src]. </span>")
		can_clone = TRUE
		qdel(O)
		interact(user)
		return TRUE

	if(istype(O, /obj/item/device/electronic_assembly))
		var/obj/item/device/electronic_assembly/EA = O //microtransactions not included
		if(EA.assembly_components.len)
			if(recycling)
				return
			if(!EA.opened)
				to_chat(user, "<span class='warning'>You can't reach [EA]'s components to remove them!</span>")
				return
			if(EA.battery)
				to_chat(user, "<span class='warning'>Remove [EA]'s power cell first!</span>")
				return
			for(var/V in EA.assembly_components)
				var/obj/item/integrated_circuit/IC = V
				if(!IC.removable)
					to_chat(user, "<span class='warning'>[EA] has irremovable components in the casing, preventing you from emptying it.</span>")
					return
			to_chat(user, "<span class='notice'>You begin recycling [EA]'s components...</span>")
			playsound(src, 'sound/items/electronic_assembly_emptying.ogg', 50, TRUE)
			if(!do_after(user, 30, target = src)) //short channel so you don't accidentally start emptying out a complex assembly
				return
			recycling = TRUE
			var/datum/component/material_container/mats = GetComponent(/datum/component/material_container)
			for(var/V in EA.assembly_components)
				var/obj/item/integrated_circuit/IC = V
				if(!mats.has_space(mats.get_item_material_amount(IC)))
					to_chat(user, "<span class='notice'>[src] can't hold any more materials!</span>")
					break
				if(!do_after(user, 5, target = user))
					recycling = FALSE
					return
				playsound(src, 'sound/items/crowbar.ogg', 50, TRUE)
				if(EA.try_remove_component(IC, user, TRUE))
					mats.user_insert(IC, user)
			to_chat(user, "<span class='notice'>You recycle all the components[EA.assembly_components.len ? " you could " : " "]from [EA]!</span>")
			playsound(src, 'sound/items/electronic_assembly_empty.ogg', 50, TRUE)
			recycling = FALSE
			return TRUE

	return ..()

/obj/item/device/integrated_circuit_printer/attack_self(mob/user)
	interact(user)

/obj/item/device/integrated_circuit_printer/interact(mob/user)
	if(isnull(current_category))
		current_category = SScircuit.circuit_fabricator_recipe_list[1]

	var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)

	var/HTML = "<center><h2>Integrated Circuit Printer</h2></center><br>"
	HTML += "Metal: [materials.total_amount]/[materials.max_amount].<br><br>"

	if(CONFIG_GET(flag/ic_printing))
		HTML += "Assembly cloning: [can_clone ? "Available": "Unavailable"].<br>"

	HTML += "Circuits available: [upgraded ? "Advanced":"Regular"]."
	if(!upgraded)
		HTML += "<br>Crossed out circuits mean that the printer is not sufficiently upgraded to create that circuit."

	HTML += "<hr>"
	if(can_clone && CONFIG_GET(flag/ic_printing))
		HTML += "Here you can load script for your assembly.<br>"
		HTML += " <A href='?src=[REF(src)];print=load'>{Load Program}</a> "
		if(!program)
			HTML += " {Print Assembly}"
		else
			HTML += " <A href='?src=[REF(src)];print=print'>{Print Assembly}</a>"

		HTML += "<br><hr>"
	HTML += "Categories:"
	for(var/category in SScircuit.circuit_fabricator_recipe_list)
		if(category != current_category)
			HTML += " <a href='?src=[REF(src)];category=[category]'>\[[category]\]</a> "
		else // Bold the button if it's already selected.
			HTML += " <b>\[[category]\]</b> "
	HTML += "<hr>"
	HTML += "<center><h4>[current_category]</h4></center>"

	var/list/current_list = SScircuit.circuit_fabricator_recipe_list[current_category]
	for(var/path in current_list)
		var/obj/O = path
		var/can_build = TRUE
		if(ispath(path, /obj/item/integrated_circuit))
			var/obj/item/integrated_circuit/IC = path
			if((initial(IC.spawn_flags) & IC_SPAWN_RESEARCH) && (!(initial(IC.spawn_flags) & IC_SPAWN_DEFAULT)) && !upgraded)
				can_build = FALSE
		if(can_build)
			HTML += "<A href='?src=[REF(src)];build=[path]'>\[[initial(O.name)]\]</A>: [initial(O.desc)]<br>"
		else
			HTML += "<s>\[[initial(O.name)]\]</s>: [initial(O.desc)]<br>"

	user << browse(HTML, "window=integrated_printer;size=600x500;border=1;can_resize=1;can_close=1;can_minimize=1")

/obj/item/device/integrated_circuit_printer/Topic(href, href_list)
	if(!check_interactivity(usr))
		return
	if(..())
		return TRUE
	add_fingerprint(usr)

	if(href_list["category"])
		current_category = href_list["category"]

	if(href_list["build"])
		var/build_type = text2path(href_list["build"])
		if(!build_type || !ispath(build_type))
			return TRUE

		var/cost = 400
		if(ispath(build_type, /obj/item/device/electronic_assembly))
			var/obj/item/device/electronic_assembly/E = SScircuit.cached_assemblies[build_type]
			cost = E.materials[MAT_METAL]
		else if(ispath(build_type, /obj/item/integrated_circuit))
			var/obj/item/integrated_circuit/IC = SScircuit.cached_components[build_type]
			cost = IC.materials[MAT_METAL]

		var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)

		if(!materials.use_amount_type(cost, MAT_METAL))
			to_chat(usr, "<span class='warning'>You need [cost] metal to build that!</span>")
			return TRUE

		var/obj/item/built = new build_type(drop_location())
		usr.put_in_hands(built)

		if(istype(built, /obj/item/device/electronic_assembly))
			var/obj/item/device/electronic_assembly/E = built
			E.opened = TRUE
			E.update_icon()
			//reupdate diagnostic hud because it was put_in_hands() and not pickup()'ed
			E.diag_hud_set_circuithealth()
			E.diag_hud_set_circuitcell()
			E.diag_hud_set_circuitstat()
			E.diag_hud_set_circuittracking()

		to_chat(usr, "<span class='notice'>[capitalize(built.name)] printed.</span>")
		playsound(src, 'sound/items/jaws_pry.ogg', 50, TRUE)

	if(href_list["print"])
		if(!CONFIG_GET(flag/ic_printing))
			to_chat(usr, "<span class='warning'>CentCom has disabled printing of custom circuitry due to recent allegations of copyright infringement.</span>")
			return
		if(!can_clone) // Copying and printing ICs is cloning
			to_chat(usr, "<span class='warning'>This printer does not have the cloning upgrade.</span>")
			return
		switch(href_list["print"])
			if("load")
				var/input = input("Put your code there:", "loading", null, null) as message | null
				if(!check_interactivity(usr))
					return
				if(!input)
					program = null
					return

				var/validation = SScircuit.validate_electronic_assembly(input)

				// Validation error codes are returned as text.
				if(istext(validation))
					to_chat(usr, "<span class='warning'>Error: [validation]</span>")
					return
				else if(islist(validation))
					program = validation
					to_chat(usr, "<span class='notice'>This is a valid program for [program["assembly"]["type"]].</span>")
					if(program["requires_upgrades"])
						if(upgraded)
							to_chat(usr, "<span class='notice'>It uses advanced component designs.</span>")
						else
							to_chat(usr, "<span class='warning'>It uses unknown component designs. Printer upgrade is required to proceed.</span>")
					if(program["unsupported_circuit"])
						to_chat(usr, "<span class='warning'>This program uses components not supported by the specified assembly. Please change the assembly type in the save file to a supported one.</span>")
					to_chat(usr, "<span class='notice'>Used space: [program["used_space"]]/[program["max_space"]].</span>")
					to_chat(usr, "<span class='notice'>Complexity: [program["complexity"]]/[program["max_complexity"]].</span>")
					to_chat(usr, "<span class='notice'>Metal cost: [program["metal_cost"]].</span>")

			if("print")
				if(!program)
					return

				if(program["requires_upgrades"] && !upgraded)
					to_chat(usr, "<span class='warning'>This program uses unknown component designs. Printer upgrade is required to proceed.</span>")
				if(program["unsupported_circuit"])
					to_chat(usr, "<span class='warning'>This program uses components not supported by the specified assembly. Please change the assembly type in the save file to a supported one.</span>")
				else
					var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)
					if(materials.use_amount_type(program["metal_cost"], MAT_METAL))
						var/obj/item/assembly = SScircuit.load_electronic_assembly(get_turf(src), program)
						to_chat(usr,  "<span class='notice'>[assembly] has been printed from the provided template!</span>")
						playsound(src, 'sound/items/poster_being_created.ogg', 50, TRUE)
					else
						to_chat(usr, "<span class='warning'>You need [program["metal_cost"]] metal to build that!</span>")

	interact(usr)


// FUKKEN UPGRADE DISKS
/obj/item/disk/integrated_circuit/upgrade
	name = "integrated circuit printer upgrade disk"
	desc = "Install this into your integrated circuit printer to enhance it."
	icon = 'icons/obj/assemblies/electronic_tools.dmi'
	icon_state = "upgrade_disk"
	item_state = "card-id"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/disk/integrated_circuit/upgrade/advanced
	name = "integrated circuit printer upgrade disk - advanced designs"
	desc = "Install this into your integrated circuit printer to enhance it.  This one adds new, advanced designs to the printer."

// To be implemented later.
/obj/item/disk/integrated_circuit/upgrade/clone
	name = "integrated circuit printer upgrade disk - circuit cloner"
	desc = "Install this into your integrated circuit printer to enhance it.  This one allows the printer to duplicate assemblies."
	icon_state = "upgrade_disk_clone"



/obj/item/clothing/suit/space/space_ninja/attackby(obj/item/I, mob/U, params)
	if(U!=affecting)//Safety, in case you try doing this without wearing the suit/being the person with the suit.
		return

	if(istype(I, /obj/item/weapon/reagent_containers/glass))//If it's a glass beaker.
		if(I.reagents.has_reagent("radium", a_transfer) && a_boost < a_maxamount)
			I.reagents.remove_reagent("radium", a_transfer)
			a_boost++;
			to_chat(U, "There are now [a_boost] adrenaline boosts remaining.")
			return

	else if(istype(I, /obj/item/weapon/stock_parts/cell))
		var/obj/item/weapon/stock_parts/cell/CELL = I
		if(CELL.maxcharge > cell.maxcharge && n_gloves && n_gloves.candrain)
			to_chat(U, "<span class='notice'>Higher maximum capacity detected.\nUpgrading...</span>")
			if (n_gloves && n_gloves.candrain && do_after(U,s_delay, target = src))
				U.drop_item()
				CELL.loc = src
				CELL.charge = min(CELL.charge+cell.charge, CELL.maxcharge)
				var/obj/item/weapon/stock_parts/cell/old_cell = cell
				old_cell.charge = 0
				U.put_in_hands(old_cell)
				old_cell.add_fingerprint(U)
				old_cell.corrupt()
				old_cell.update_icon()
				cell = CELL
				to_chat(U, "<span class='notice'>Upgrade complete. Maximum capacity: <b>[round(cell.maxcharge/100)]</b>%</span>")
			else
				to_chat(U, "<span class='danger'>Procedure interrupted. Protocol terminated.</span>")
		return

	else if(istype(I, /obj/item/weapon/disk/tech_disk))//If it's a data disk, we want to copy the research on to the suit.
		var/obj/item/weapon/disk/tech_disk/TD = I
		var/has_research = 0
		for(var/V in  TD.tech_stored)
			if(V)
				has_research = 1
				break
		if(has_research)//If it has something on it.
			to_chat(U, "Research information detected, processing...")
			if(do_after(U,s_delay, target = src))
				for(var/V1 in 1 to TD.max_tech_stored)
					var/datum/tech/new_data = TD.tech_stored[V1]
					TD.tech_stored[V1] = null
					if(!new_data)
						continue
					for(var/V2 in stored_research)
						var/datum/tech/current_data = V2
						if(current_data.id == new_data.id)
							current_data.level = max(current_data.level, new_data.level)
							break
				to_chat(U, "<span class='notice'>Data analyzed and updated. Disk erased.</span>")
			else
				to_chat(U, "<span class='userdanger'>ERROR</span>: Procedure interrupted. Process terminated.")
		else
			to_chat(U, "No research information detected.")
		return
	..()
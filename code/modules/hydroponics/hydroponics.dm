#define TRAY_NAME_UPDATE name = myseed ? "[initial(name)] ([myseed.plantname])" : initial(name)

/obj/machinery/hydroponics
	name = "hydroponics tray"
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "hydrotray"
	density = TRUE
	pixel_z = 8
	obj_flags = CAN_BE_HIT | UNIQUE_RENAME
	circuit = /obj/item/circuitboard/machine/hydroponics
	idle_power_usage = 0
	var/waterlevel = 100	//The amount of water in the tray (max 100)
	var/maxwater = 100		//The maximum amount of water in the tray
	var/nutridrain = 1		//How many units of nutrients will be drained in the tray.
	var/maxnutri = 10		//The maximum nutrient of water in the tray
	var/pestlevel = 0		//The amount of pests in the tray (max 10)
	var/weedlevel = 0		//The amount of weeds in the tray (max 10)
	var/yieldmod = 1		//Nutriment's effect on yield
	var/mutmod = 1			//Nutriment's effect on mutations
	var/toxic = 0			//Toxicity in the tray?
	var/age = 0				//Current age
	var/dead = FALSE		//Is it dead?
	var/plant_health		//Its health
	var/lastproduce = 0		//Last time it was harvested
	var/lastcycle = 0		//Used for timing of cycles.
	var/cycledelay = 200	//About 10 seconds / cycle
	var/harvest = FALSE			//Ready to harvest?
	var/obj/item/seeds/myseed = null	//The currently planted seed
	var/rating = 1
	var/unwrenchable = TRUE
	var/recent_bee_visit = FALSE //Have we been visited by a bee recently, so bees dont overpollinate one plant
	var/using_irrigation = FALSE //If the tray is connected to other trays via irrigation hoses
	var/mob/lastuser			//The last user to add a reagent to the tray, mostly for logging purposes.
	var/self_sustaining = FALSE //If the tray generates nutrients and water on its own

/obj/machinery/hydroponics/Initialize()
	//ALRIGHT YOU DEGENERATES. YOU HAD REAGENT HOLDERS FOR AT LEAST 4 YEARS AND NONE OF YOU MADE HYDROPONICS TRAYS HOLD NUTRIENT CHEMS INSTEAD OF USING "Points".
	//SO HERE LIES THE "nutrilevel" VAR. IT'S DEAD AND I PUT IT OUT OF IT'S MISERY. USE "reagents" INSTEAD. ~ArcaneMusic, accept no substitutes.
	create_reagents(10)
	. = ..()


/obj/machinery/hydroponics/constructable
	name = "hydroponics tray"
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "hydrotray3"

/obj/machinery/hydroponics/constructable/RefreshParts()
	var/tmp_capacity = 0
	for (var/obj/item/stock_parts/matter_bin/M in component_parts)
		tmp_capacity += M.rating
	for (var/obj/item/stock_parts/manipulator/M in component_parts)
		rating = M.rating
	maxwater = tmp_capacity * 50 // Up to 300
	maxnutri = tmp_capacity * 5 // Up to 30
	reagents.maximum_volume = maxnutri
	nutridrain = 1/rating

/obj/machinery/hydroponics/constructable/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Use <b>Ctrl-Click</b> to activate autogrow. <b>Alt-Click</b> to empty the tray's nutrients.</span>"
	if(in_range(user, src) || isobserver(user))
		. += "<span class='notice'>The status display reads: Tray efficiency at <b>[rating*100]%</b>.</span>"


/obj/machinery/hydroponics/Destroy()
	if(myseed)
		qdel(myseed)
		myseed = null
	return ..()

/obj/machinery/hydroponics/constructable/attackby(obj/item/I, mob/user, params)
	if (user.a_intent != INTENT_HARM)
		// handle opening the panel
		if(default_deconstruction_screwdriver(user, icon_state, icon_state, I))
			return

		// handle deconstructing the machine, if permissible
		if(I.tool_behaviour == TOOL_CROWBAR && using_irrigation)
			to_chat(user, "<span class='warning'>Disconnect the hoses first!</span>")
			return
		else if(default_deconstruction_crowbar(I))
			return

	return ..()

/obj/machinery/hydroponics/proc/FindConnected()
	var/list/connected = list()
	var/list/processing_atoms = list(src)

	while(processing_atoms.len)
		var/atom/a = processing_atoms[1]
		for(var/step_dir in GLOB.cardinals)
			var/obj/machinery/hydroponics/h = locate() in get_step(a, step_dir)
			// Soil plots aren't dense
			if(h && h.using_irrigation && h.density && !(h in connected) && !(h in processing_atoms))
				processing_atoms += h

		processing_atoms -= a
		connected += a

	return connected

/obj/machinery/hydroponics/bullet_act(obj/projectile/Proj) //Works with the Somatoray to modify plant variables.
	if(!myseed)
		return ..()
	if(istype(Proj , /obj/projectile/energy/floramut))
		mutate()
	else if(istype(Proj , /obj/projectile/energy/florayield))
		return myseed.bullet_act(Proj)
	else
		return ..()

/obj/machinery/hydroponics/process()
	var/needs_update = 0 // Checks if the icon needs updating so we don't redraw empty trays every time

	if(myseed && (myseed.loc != src))
		myseed.forceMove(src)

	if(!powered() && self_sustaining)
		visible_message("<span class='warning'>[name]'s auto-grow functionality shuts off!</span>")
		idle_power_usage = 0
		self_sustaining = FALSE
		update_icon()

	else if(self_sustaining)
		nutridrain = min(0.5, nutridrain) //By just upgrading your trays you will outpace your trays sustainability.
		adjustWater(rand(1,2))
		adjustWeeds(-1)
		adjustPests(-1)

	if(world.time > (lastcycle + cycledelay))
		lastcycle = world.time
		if(myseed && !dead)
			// Advance age
			age++
			if(age < myseed.maturation)
				lastproduce = age

			needs_update = 1


//Nutrients//////////////////////////////////////////////////////////////
			// Nutrients deplete at a constant rate, since new nutrients can boost stats far easier.
			applyChemicals(reagents, lastuser)
			reagents.remove_any(nutridrain)

			// Lack of nutrients hurts non-weeds
			if(reagents.total_volume <= 0 && !myseed.get_gene(/datum/plant_gene/trait/plant_type/weed_hardy))
				adjustHealth(-rand(1,3))

//Photosynthesis/////////////////////////////////////////////////////////
			// Lack of light hurts non-mushrooms
			if(isturf(loc))
				var/turf/currentTurf = loc
				var/lightAmt = currentTurf.get_lumcount()
				if(myseed.get_gene(/datum/plant_gene/trait/plant_type/fungal_metabolism))
					if(lightAmt < 0.2)
						adjustHealth(-1 / rating)
				else // Non-mushroom
					if(lightAmt < 0.4)
						adjustHealth(-2 / rating)

//Water//////////////////////////////////////////////////////////////////
			// Drink random amount of water
			adjustWater(-rand(1,6) / rating)

			// If the plant is dry, it loses health pretty fast, unless mushroom
			if(waterlevel <= 10 && !myseed.get_gene(/datum/plant_gene/trait/plant_type/fungal_metabolism))
				adjustHealth(-rand(0,1) / rating)
				if(waterlevel <= 0)
					adjustHealth(-rand(0,2) / rating)

			// Sufficient water level and nutrient level = plant healthy but also spawns weeds
			else if(waterlevel > 10 && reagents.total_volume > 0)
				adjustHealth(rand(1,2) / rating)
				if(myseed && prob(myseed.weed_chance))
					adjustWeeds(myseed.weed_rate)
				else if(prob(5))  //5 percent chance the weed population will increase
					adjustWeeds(1 / rating)

//Toxins/////////////////////////////////////////////////////////////////

			// Too much toxins cause harm, but when the plant drinks the contaiminated water, the toxins disappear slowly
			if(toxic >= 40 && toxic < 80)
				adjustHealth(-1 / rating)
				adjustToxic(-rand(1,10) / rating)
			else if(toxic >= 80) // I don't think it ever gets here tbh unless above is commented out
				adjustHealth(-3)
				adjustToxic(-rand(1,10) / rating)

//Pests & Weeds//////////////////////////////////////////////////////////

			if(pestlevel >= 8)
				if(!myseed.get_gene(/datum/plant_gene/trait/plant_type/carnivory))
					if(myseed.potency >=30)
						myseed.adjust_potency(-rand(2,6)) //Pests eat leaves and nibble on fruit, lowering potency.
						myseed.potency = min((myseed.potency),30,100)
				else
					adjustHealth(2 / rating)
					adjustPests(-1 / rating)

			else if(pestlevel >= 4)
				if(!myseed.get_gene(/datum/plant_gene/trait/plant_type/carnivory))
					if(myseed.potency >=30)
						myseed.adjust_potency(-rand(1,4))
						myseed.potency = min((myseed.potency),30,100)

				else
					adjustHealth(1 / rating)
					if(prob(50))
						adjustPests(-1 / rating)

			else if(pestlevel < 4 && myseed.get_gene(/datum/plant_gene/trait/plant_type/carnivory))
				if(prob(5))
					adjustPests(-1 / rating)

			// If it's a weed, it doesn't stunt the growth
			if(weedlevel >= 5 && !myseed.get_gene(/datum/plant_gene/trait/plant_type/weed_hardy))
				if(myseed.yield >=3)
					myseed.adjust_yield(-rand(1,2)) //Weeds choke out the plant's ability to bear more fruit.
					myseed.yield = min((myseed.yield),3,10)

//This is the part with pollination
			pollinate()

//This is where stability mutations exist now.
			if(myseed.instability >= 80)
				if(prob(20))
					mutate(0, 0, 0, 0, 0, 0, 0, 10, 0) //Exceedingly low odds of gaining a trait.
			else if(myseed.instability >= 60)
				if(prob((myseed.instability)/2) && !self_sustaining)
					mutatespecie()
					myseed.instability = myseed.instability/2
			else if(myseed.instability >= 40 && myseed.instability < 59)
				if(prob(40))
					hardmutate()
			else if(myseed.instability >= 20 && myseed.instability < 39)
				if(prob(40))
					mutate()

//Health & Age///////////////////////////////////////////////////////////

			// Plant dies if plant_health <= 0
			if(plant_health <= 0)
				plantdies()
				adjustWeeds(1 / rating) // Weeds flourish

			// If the plant is too old, lose health fast
			if(age > myseed.lifespan)
				adjustHealth(-rand(1,5) / rating)

			// Harvest code
				if(myseed && myseed.yield != -1) // Unharvestable shouldn't be harvested
					harvest = TRUE
				else
					lastproduce = age
			if(prob(5))  // On each tick, there's a 5 percent chance the pest population will increase
				adjustPests(1 / rating)
		else
			if(waterlevel > 10 && reagents.total_volume > 0 && prob(10))  // If there's no plant, the percentage chance is 10%
				adjustWeeds(1 / rating)

		// Weeeeeeeeeeeeeeedddssss
		if(weedlevel >= 10 && prob(50) && !self_sustaining) // At this point the plant is kind of fucked. Weeds can overtake the plant spot.
			if(myseed && myseed.yield >= 3)
				myseed.adjust_yield(-rand(1,2)) //Loses even more yield per tick, quickly dropping to 3 minimum.
				myseed.yield = min((myseed.yield),3,10)
			if(!myseed)
				weedinvasion()
			needs_update = 1
		if (needs_update)
			update_icon()

		if(myseed && prob(5 * (11-myseed.production)))
			for(var/g in myseed.genes)
				if(istype(g, /datum/plant_gene/trait))
					var/datum/plant_gene/trait/selectedtrait = g
					selectedtrait.on_grow(src)
	return

/obj/machinery/hydroponics/update_icon()
	//Refreshes the icon and sets the luminosity
	cut_overlays()

	if(self_sustaining)
		if(istype(src, /obj/machinery/hydroponics/soil))
			add_atom_colour(rgb(255, 175, 0), FIXED_COLOUR_PRIORITY)
		else
			add_overlay(mutable_appearance('icons/obj/hydroponics/equipment.dmi', "gaia_blessing"))
		set_light(3)

	update_icon_hoses()

	if(myseed)
		update_icon_plant()
		update_icon_lights()

	if(!self_sustaining)
		if(myseed && myseed.get_gene(/datum/plant_gene/trait/glow))
			var/datum/plant_gene/trait/glow/G = myseed.get_gene(/datum/plant_gene/trait/glow)
			set_light(G.glow_range(myseed), G.glow_power(myseed), G.glow_color)
		else
			set_light(0)

	return

/obj/machinery/hydroponics/proc/update_icon_hoses()
	var/n = 0
	for(var/Dir in GLOB.cardinals)
		var/obj/machinery/hydroponics/t = locate() in get_step(src,Dir)
		if(t && t.using_irrigation && using_irrigation)
			n += Dir

	icon_state = "hoses-[n]"

/obj/machinery/hydroponics/proc/update_icon_plant()
	var/mutable_appearance/plant_overlay = mutable_appearance(myseed.growing_icon, layer = OBJ_LAYER + 0.01)
	if(dead)
		plant_overlay.icon_state = myseed.icon_dead
	else if(harvest)
		if(!myseed.icon_harvest)
			plant_overlay.icon_state = "[myseed.icon_grow][myseed.growthstages]"
		else
			plant_overlay.icon_state = myseed.icon_harvest
	else
		var/t_growthstate = min(round((age / myseed.maturation) * myseed.growthstages), myseed.growthstages)
		plant_overlay.icon_state = "[myseed.icon_grow][t_growthstate]"
	add_overlay(plant_overlay)

/obj/machinery/hydroponics/proc/update_icon_lights()
	if(waterlevel <= 10)
		add_overlay(mutable_appearance('icons/obj/hydroponics/equipment.dmi', "over_lowwater3"))
	if(reagents.total_volume <= 2)
		add_overlay(mutable_appearance('icons/obj/hydroponics/equipment.dmi', "over_lownutri3"))
	if(plant_health <= (myseed.endurance / 2))
		add_overlay(mutable_appearance('icons/obj/hydroponics/equipment.dmi', "over_lowhealth3"))
	if(weedlevel >= 5 || pestlevel >= 5 || toxic >= 40)
		add_overlay(mutable_appearance('icons/obj/hydroponics/equipment.dmi', "over_alert3"))
	if(harvest)
		add_overlay(mutable_appearance('icons/obj/hydroponics/equipment.dmi', "over_harvest3"))


/obj/machinery/hydroponics/examine(user)
	. = ..()
	if(myseed)
		. += "<span class='info'>It has <span class='name'>[myseed.plantname]</span> planted.</span>"
		if (dead)
			. += "<span class='warning'>It's dead!</span>"
		else if (harvest)
			. += "<span class='info'>It's ready to harvest.</span>"
		else if (plant_health <= (myseed.endurance / 2))
			. += "<span class='warning'>It looks unhealthy.</span>"
	else
		. += "<span class='info'>It's empty.</span>"

	if(!self_sustaining)
		. += "<span class='info'>Water: [waterlevel]/[maxwater].</span>\n"+\
		"<span class='info'>Nutrient: [reagents.total_volume]/[maxnutri].</span>"
	else
		. += "<span class='info'>It doesn't require any water or nutrients.</span>"

	if(weedlevel >= 5)
		to_chat(user, "<span class='warning'>It's filled with weeds!</span>")
	if(pestlevel >= 5)
		to_chat(user, "<span class='warning'>It's filled with tiny worms!</span>")
	to_chat(user, "" )


/obj/machinery/hydroponics/proc/weedinvasion() // If a weed growth is sufficient, this happens.
	dead = FALSE
	var/oldPlantName
	if(myseed) // In case there's nothing in the tray beforehand
		oldPlantName = myseed.plantname
		qdel(myseed)
		myseed = null
	else
		oldPlantName = "empty tray"
	switch(rand(1,18))		// randomly pick predominative weed
		if(16 to 18)
			myseed = new /obj/item/seeds/reishi(src)
		if(14 to 15)
			myseed = new /obj/item/seeds/nettle(src)
		if(12 to 13)
			myseed = new /obj/item/seeds/harebell(src)
		if(10 to 11)
			myseed = new /obj/item/seeds/amanita(src)
		if(8 to 9)
			myseed = new /obj/item/seeds/chanter(src)
		if(6 to 7)
			myseed = new /obj/item/seeds/tower(src)
		if(4 to 5)
			myseed = new /obj/item/seeds/plump(src)
		else
			myseed = new /obj/item/seeds/starthistle(src)
	age = 0
	plant_health = myseed.endurance
	lastcycle = world.time
	harvest = FALSE
	weedlevel = 0 // Reset
	pestlevel = 0 // Reset
	update_icon()
	visible_message("<span class='warning'>The [oldPlantName] is overtaken by some [myseed.plantname]!</span>")
	TRAY_NAME_UPDATE

/obj/machinery/hydroponics/proc/mutate(lifemut = 2, endmut = 5, productmut = 1, yieldmut = 2, potmut = 25, wrmut = 2, wcmut = 5, traitmut = 0, stabmut = 3) // Mutates the current seed
	if(!myseed)
		return
	myseed.mutate(lifemut, endmut, productmut, yieldmut, potmut, wrmut, wcmut, traitmut, stabmut)

/obj/machinery/hydroponics/proc/hardmutate()
	mutate(4, 10, 2, 4, 50, 4, 10, 0, 4)


/obj/machinery/hydroponics/proc/mutatespecie() // Mutagent produced a new plant!
	if(!myseed || dead)
		return

	var/oldPlantName = myseed.plantname
	if(myseed.mutatelist.len > 0)
		var/mutantseed = pick(myseed.mutatelist)
		qdel(myseed)
		myseed = null
		myseed = new mutantseed
	else
		return

	hardmutate()
	age = 0
	plant_health = myseed.endurance
	lastcycle = world.time
	harvest = FALSE
	weedlevel = 0 // Reset

	sleep(5) // Wait a while
	update_icon()
	visible_message("<span class='warning'>[oldPlantName] suddenly mutates into [myseed.plantname]!</span>")
	TRAY_NAME_UPDATE

/obj/machinery/hydroponics/proc/mutateweed() // If the weeds gets the mutagent instead. Mind you, this pretty much destroys the old plant
	if( weedlevel > 5 )
		if(myseed)
			qdel(myseed)
			myseed = null
		var/newWeed = pick(/obj/item/seeds/liberty, /obj/item/seeds/angel, /obj/item/seeds/nettle/death, /obj/item/seeds/kudzu)
		myseed = new newWeed
		dead = FALSE
		hardmutate()
		age = 0
		plant_health = myseed.endurance
		lastcycle = world.time
		harvest = FALSE
		weedlevel = 0 // Reset

		sleep(5) // Wait a while
		update_icon()
		visible_message("<span class='warning'>The mutated weeds in [src] spawn some [myseed.plantname]!</span>")
		TRAY_NAME_UPDATE
	else
		to_chat(usr, "<span class='warning'>The few weeds in [src] seem to react, but only for a moment...</span>")


/obj/machinery/hydroponics/proc/plantdies() // OH NOES!!!!! I put this all in one function to make things easier
	plant_health = 0
	harvest = FALSE
	pestlevel = 0 // Pests die
	lastproduce = 0
	if(!dead)
		update_icon()
		dead = TRUE

/obj/machinery/hydroponics/proc/pollinate(var/range = 1)
	for(var/obj/machinery/hydroponics/T in oview(src, range))
		if(T.myseed && !T.dead)
			T.myseed.potency =  round(clamp((T.myseed.potency+(1/10)*(myseed.potency-T.myseed.potency)),0,100))
			T.myseed.instability =  round(clamp((T.myseed.instability+(1/10)*(myseed.instability-T.myseed.instability)),0,100))
			T.myseed.yield =  round(clamp((T.myseed.yield+(1/2)*(myseed.yield-T.myseed.yield)),0,10))
			if(myseed.instability >= 20 && prob(70) && T.myseed.reagents_add)
				var/datum/reagent/picked_reagent = (pick(T.myseed.reagents_add))
				var/datum/plant_gene/reagent/reagent_gene = new /datum/plant_gene/reagent(picked_reagent, 0.05) //I cannot figure out how to copy over the keyed value from the reagents_add list so for now this works, skog you'll want to fix this before merge
				if(reagent_gene.can_add(myseed))
					myseed.genes += reagent_gene
					return


/obj/machinery/hydroponics/proc/mutatepest(mob/user)
	if(pestlevel > 5)
		message_admins("[ADMIN_LOOKUPFLW(user)] last altered a hydro tray's contents which spawned spiderlings")
		log_game("[key_name(user)] last altered a hydro tray, which spiderlings spawned from.")
		visible_message("<span class='warning'>The pests seem to behave oddly...</span>")
		spawn_atom_to_turf(/obj/structure/spider/spiderling/hunter, src, 3, FALSE)
	else if(myseed)
		visible_message("<span class='warning'>The pests seem to behave oddly in [myseed.name] tray, but quickly settle down...</span>")

/obj/machinery/hydroponics/attackby(obj/item/O, mob/user, params)
	//Called when mob user "attacks" it with object O
	if(istype(O, /obj/item/reagent_containers) )  // Syringe stuff (and other reagent containers now too)
		var/obj/item/reagent_containers/reagent_source = O

		if(istype(reagent_source, /obj/item/reagent_containers/syringe))
			var/obj/item/reagent_containers/syringe/syr = reagent_source
			if(syr.mode != 1)
				to_chat(user, "<span class='warning'>You can't get any extract out of this plant.</span>"		)
				return

		if(!reagent_source.reagents.total_volume)
			to_chat(user, "<span class='warning'>[reagent_source] is empty!</span>")
			return 1

		var/list/trays = list(src)//makes the list just this in cases of syringes and compost etc
		var/target = myseed ? myseed.plantname : src
		var/visi_msg = ""
		var/irrigate = 0	//How am I supposed to irrigate pill contents?
		var/transfer_amount

		if(istype(reagent_source, /obj/item/reagent_containers/food/snacks) || istype(reagent_source, /obj/item/reagent_containers/pill))
			if(istype(reagent_source, /obj/item/reagent_containers/food/snacks))
				var/obj/item/reagent_containers/food/snacks/R = reagent_source
				if (R.trash)
					R.generate_trash(get_turf(user))
			visi_msg="[user] composts [reagent_source], spreading it through [target]"
			transfer_amount = reagent_source.reagents.total_volume
		else
			transfer_amount = reagent_source.amount_per_transfer_from_this
			if(istype(reagent_source, /obj/item/reagent_containers/syringe/))
				var/obj/item/reagent_containers/syringe/syr = reagent_source
				visi_msg="[user] injects [target] with [syr]"
				if(syr.reagents.total_volume <= syr.amount_per_transfer_from_this)
					syr.mode = 0
			else if(istype(reagent_source, /obj/item/reagent_containers/spray/))
				visi_msg="[user] sprays [target] with [reagent_source]"
				playsound(loc, 'sound/effects/spray3.ogg', 50, TRUE, -6)
				irrigate = 1
			else if(transfer_amount) // Droppers, cans, beakers, what have you.
				visi_msg="[user] uses [reagent_source] on [target]"
				irrigate = 1
			// Beakers, bottles, buckets, etc.
			if(reagent_source.is_drainable())
				playsound(loc, 'sound/effects/slosh.ogg', 25, TRUE)

		if(irrigate && transfer_amount > 30 && reagent_source.reagents.total_volume >= 30 && using_irrigation)
			trays = FindConnected()
			if (trays.len > 1)
				visi_msg += ", setting off the irrigation system"

		if(visi_msg)
			visible_message("<span class='notice'>[visi_msg].</span>")

		var/split = round(transfer_amount/trays.len)

		for(var/obj/machinery/hydroponics/H in trays)
		//cause I don't want to feel like im juggling 15 tamagotchis and I can get to my real work of ripping flooring apart in hopes of validating my life choices of becoming a space-gardener

			//var/datum/reagents/S = new /datum/reagents() //This is a strange way, but I don't know of a better one so I can't fix it at the moment...
			//S.my_atom = H

			//This was originally in applyChemicals, but due to applyChemicals only holding nutrients, we handle it here now.
			if(reagent_source.reagents.has_reagent(/datum/reagent/water, 1))
				adjustWater(round(reagent_source.reagents.get_reagent_amount(/datum/reagent/water)/trays.len))
				reagent_source.reagents.remove_reagent(/datum/reagent/water, reagent_source.reagents.get_reagent_amount(/datum/reagent/water)/trays.len)
			else
				reagent_source.reagents.trans_to(reagents, split, transfered_by = user)
			if(istype(reagent_source, /obj/item/reagent_containers/food/snacks) || istype(reagent_source, /obj/item/reagent_containers/pill))
				qdel(reagent_source)
				lastuser = user
			//S.clear_reagents()
			//qdel(S)
			H.update_icon()
		if(reagent_source) // If the source wasn't composted and destroyed
			reagent_source.update_icon()
		return 1

	else if(istype(O, /obj/item/seeds) && !istype(O, /obj/item/seeds/sample))
		if(!myseed)
			if(istype(O, /obj/item/seeds/kudzu))
				investigate_log("had Kudzu planted in it by [key_name(user)] at [AREACOORD(src)]","kudzu")
			if(!user.transferItemToLoc(O, src))
				return
			to_chat(user, "<span class='notice'>You plant [O].</span>")
			dead = FALSE
			myseed = O
			TRAY_NAME_UPDATE
			age = 1
			plant_health = myseed.endurance
			lastcycle = world.time
			update_icon()
		else
			to_chat(user, "<span class='warning'>[src] already has seeds in it!</span>")

	else if(istype(O, /obj/item/plant_analyzer))
		if(myseed)
			to_chat(user, "*** <B>[myseed.plantname]</B> ***" )
			to_chat(user, "- Plant Age: <span class='notice'>[age]</span>")
			var/list/text_string = myseed.get_analyzer_text()
			if(text_string)
				to_chat(user, text_string)
		else
			to_chat(user, "<B>No plant found.</B>")
		to_chat(user, "- Weed level: <span class='notice'>[weedlevel] / 10</span>")
		to_chat(user, "- Pest level: <span class='notice'>[pestlevel] / 10</span>")
		to_chat(user, "- Toxicity level: <span class='notice'>[toxic] / 100</span>")
		to_chat(user, "- Water level: <span class='notice'>[waterlevel] / [maxwater]</span>")
		to_chat(user, "- Nutrition level: <span class='notice'>[reagents.total_volume] / [maxnutri]</span>")
		to_chat(user, "")

	else if(istype(O, /obj/item/cultivator))
		if(weedlevel > 0)
			user.visible_message("<span class='notice'>[user] uproots the weeds.</span>", "<span class='notice'>You remove the weeds from [src].</span>")
			weedlevel = 0
			update_icon()
		else
			to_chat(user, "<span class='warning'>This plot is completely devoid of weeds! It doesn't need uprooting.</span>")

	else if(istype(O, /obj/item/secateurs))
		if(!myseed)
			to_chat(user, "<span class='notice'>This plot is empty.</span>")
			return
		else if(harvest == FALSE)
			to_chat(user, "<span class='notice'>This plant must be harvestable in order to be grafted.</span>")
			return
		else if(myseed && myseed.grafted == TRUE)
			to_chat(user, "<span class='notice'>This plant has already been grafted.</span>")
			return
		else if(myseed && myseed.grafted == FALSE)
			user.visible_message("<span class='notice'>[user] grafts off a limb from [src].</span>", "<span class='notice'>You carefully graft off a portion of [src].</span>")
			var/obj/item/graft/snip = new /obj/item/graft(loc)
			if(myseed.graft_gene)
				snip.stored_trait = new myseed.graft_gene
			snip.parent_seed = myseed
			myseed.grafted = TRUE
			adjustHealth(-5)

	else if(istype(O, /obj/item/graft))
		var/obj/item/graft/snip = O
		var/datum/plant_gene/trait/new_trait = snip.stored_trait
		if(!myseed)
			to_chat(user, "<span class='notice'>The tray is empty.</span>")
			return
		if(new_trait.can_add(myseed))
			myseed.genes += snip.stored_trait
		//Alright this one's a mess, but it's either 2/3rds of the difference of the two seed's respective stats, and the higher of the two is taken. Min 0, max 100.
		myseed.lifespan =  round(clamp(max(myseed.lifespan,(myseed.lifespan+(2/3)*(snip.parent_seed.lifespan-myseed.lifespan))),0,100))
		myseed.endurance =  round(clamp(max(myseed.endurance,(myseed.endurance+(2/3)*(snip.parent_seed.endurance-myseed.endurance))),0,100))
		myseed.production = round(clamp(max(myseed.production,(myseed.production+(2/3)*(snip.parent_seed.production-myseed.production))),0,100))
		myseed.weed_rate = round(clamp(max(myseed.weed_rate,(myseed.weed_rate+(2/3)*(snip.parent_seed.weed_rate-myseed.weed_rate))),0,100))
		myseed.weed_chance = round(clamp(max(myseed.weed_chance,(myseed.weed_chance+(2/3)*(snip.parent_seed.weed_chance-myseed.weed_chance))),0,100))
		myseed.yield = round(clamp(max(myseed.yield,(myseed.yield+(2/3)*(snip.parent_seed.yield-myseed.yield))),0,10))
		qdel(snip)
		to_chat(user, "<span class='notice'>You carefully integrate the grafted plant limb onto [myseed.plantname].</span>")
		return

	else if(istype(O, /obj/item/storage/bag/plants))
		attack_hand(user)
		for(var/obj/item/reagent_containers/food/snacks/grown/G in locate(user.x,user.y,user.z))
			SEND_SIGNAL(O, COMSIG_TRY_STORAGE_INSERT, G, user, TRUE)

	else if(default_unfasten_wrench(user, O))
		return

	else if((O.tool_behaviour == TOOL_WIRECUTTER) && unwrenchable)
		if (!anchored)
			to_chat(user, "<span class='warning'>Anchor the tray first!</span>")
			return
		using_irrigation = !using_irrigation
		O.play_tool_sound(src)
		user.visible_message("<span class='notice'>[user] [using_irrigation ? "" : "dis"]connects [src]'s irrigation hoses.</span>", \
		"<span class='notice'>You [using_irrigation ? "" : "dis"]connect [src]'s irrigation hoses.</span>")
		for(var/obj/machinery/hydroponics/h in range(1,src))
			h.update_icon()

	else if(istype(O, /obj/item/shovel/spade))
		if(!myseed && !weedlevel)
			to_chat(user, "<span class='warning'>[src] doesn't have any plants or weeds!</span>")
			return
		user.visible_message("<span class='notice'>[user] starts digging out [src]'s plants...</span>",
			"<span class='notice'>You start digging out [src]'s plants...</span>")
		if(O.use_tool(src, user, 50, volume=50) || (!myseed && !weedlevel))
			user.visible_message("<span class='notice'>[user] digs out the plants in [src]!</span>", "<span class='notice'>You dig out all of [src]'s plants!</span>")
			if(myseed) //Could be that they're just using it as a de-weeder
				age = 0
				plant_health = 0
				lastproduce = 0
				if(harvest)
					harvest = FALSE //To make sure they can't just put in another seed and insta-harvest it
				qdel(myseed)
				myseed = null
				name = initial(name)
				desc = initial(desc)
			weedlevel = 0 //Has a side effect of cleaning up those nasty weeds
			update_icon()


	else
		return ..()

/obj/machinery/hydroponics/can_be_unfasten_wrench(mob/user, silent)
	if (!unwrenchable)  // case also covered by NODECONSTRUCT checks in default_unfasten_wrench
		return CANT_UNFASTEN

	if (using_irrigation)
		if (!silent)
			to_chat(user, "<span class='warning'>Disconnect the hoses first!</span>")
		return FAILED_UNFASTEN

	return ..()

/obj/machinery/hydroponics/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	if(issilicon(user)) //How does AI know what plant is?
		return
	if(harvest)
		return myseed.harvest(user)

	else if(dead)
		dead = FALSE
		to_chat(user, "<span class='notice'>You remove the dead plant from [src].</span>")
		qdel(myseed)
		myseed = null
		update_icon()
		TRAY_NAME_UPDATE
	else
		if(user)
			examine(user)

/obj/machinery/hydroponics/CtrlClick(mob/user)
	. = ..()
	if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return
	if(!powered())
		to_chat(user, "<span class='warning'>[name] has no power.</span>")
	self_sustaining = !self_sustaining
	if(self_sustaining)
		idle_power_usage = 5000
		to_chat(user, "<span class='notice'>You activate [src]'s autogrow function, maintaining the tray's health while using high amounts of power.</span>")
	else
		idle_power_usage = 0
		to_chat(user, "<span class='notice'>You deactivated [src]'s autogrow function.</span>")
	update_icon()

/obj/machinery/hydroponics/AltClick(mob/user)
	. = ..()
	var/warning = alert(user, "Are you sure you wish to empty the tray's nutrient beaker?","Empty Tray Nutrients?", "Yes", "No")
	if(warning == "Yes" && user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		reagents.clear_reagents()
		to_chat(user, "<span class='warning'>You empty [src]'s nutrient tank.</span>")

/obj/machinery/hydroponics/proc/update_tray(mob/user)
	harvest = FALSE
	lastproduce = age
	if(istype(myseed, /obj/item/seeds/replicapod))
		to_chat(user, "<span class='notice'>You harvest from the [myseed.plantname].</span>")
	else if(myseed.getYield() <= 0)
		to_chat(user, "<span class='warning'>You fail to harvest anything useful!</span>")
	else
		to_chat(user, "<span class='notice'>You harvest [myseed.getYield()] items from the [myseed.plantname].</span>")
	if(!myseed.get_gene(/datum/plant_gene/trait/repeated_harvest))
		qdel(myseed)
		myseed = null
		dead = FALSE
		name = initial(name)
		desc = initial(desc)
		TRAY_NAME_UPDATE
		if(self_sustaining) //No reason to pay for an empty tray.
			idle_power_usage = 0
			self_sustaining = FALSE
	update_icon()

/// Tray Setters - The following procs adjust the tray or plants variables, and make sure that the stat doesn't go out of bounds.///
/obj/machinery/hydroponics/proc/adjustWater(adjustamt)
	waterlevel = clamp(waterlevel + adjustamt, 0, maxwater)

	if(adjustamt>0)
		adjustToxic(-round(adjustamt/4))//Toxicity dilutation code. The more water you put in, the lesser the toxin concentration.

/obj/machinery/hydroponics/proc/adjustHealth(adjustamt)
	if(myseed && !dead)
		plant_health = clamp(plant_health + adjustamt, 0, myseed.endurance)

/obj/machinery/hydroponics/proc/adjustToxic(adjustamt)
	toxic = clamp(toxic + adjustamt, 0, 100)

/obj/machinery/hydroponics/proc/adjustPests(adjustamt)
	pestlevel = clamp(pestlevel + adjustamt, 0, 10)

/obj/machinery/hydroponics/proc/adjustWeeds(adjustamt)
	weedlevel = clamp(weedlevel + adjustamt, 0, 10)

/obj/machinery/hydroponics/proc/spawnplant() // why would you put strange reagent in a hydro tray you monster I bet you also feed them blood
	var/list/livingplants = list(/mob/living/simple_animal/hostile/tree, /mob/living/simple_animal/hostile/killertomato)
	var/chosen = pick(livingplants)
	var/mob/living/simple_animal/hostile/C = new chosen
	C.faction = list("plants")

/obj/machinery/hydroponics/proc/become_self_sufficient() // Ambrosia Gaia effect
	visible_message("<span class='boldnotice'>[src] begins to glow with a beautiful light!</span>")
	self_sustaining = TRUE
	update_icon()

//////////////////////////////////////////////////////////////////////////////////
/obj/machinery/hydroponics/irrigated	//Pre-Irrigated trays! Maybe map a couple on each map, just so they get used?
	using_irrigation = TRUE

/obj/machinery/hydroponics/irrigated/Initialize()
	. = ..()
	update_icon() //Visually hooks up all the pipes.

///////////////////////////////////////////////////////////////////////////////
/obj/machinery/hydroponics/soil //Not actually hydroponics at all! Honk!
	name = "soil"
	desc = "A patch of dirt."
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "soil"
	gender = PLURAL
	circuit = null
	density = FALSE
	use_power = NO_POWER_USE
	flags_1 = NODECONSTRUCT_1
	unwrenchable = FALSE

/obj/machinery/hydroponics/soil/update_icon_hoses()
	return // Has no hoses

/obj/machinery/hydroponics/soil/update_icon_lights()
	return // Has no lights

/obj/machinery/hydroponics/soil/attackby(obj/item/O, mob/user, params)
	if(O.tool_behaviour == TOOL_SHOVEL && !istype(O, /obj/item/shovel/spade)) //Doesn't include spades because of uprooting plants
		to_chat(user, "<span class='notice'>You clear up [src]!</span>")
		qdel(src)
	else
		return ..()

/obj/machinery/hydroponics/soil/CtrlClick(mob/user)
	return //Soil has no electricity.

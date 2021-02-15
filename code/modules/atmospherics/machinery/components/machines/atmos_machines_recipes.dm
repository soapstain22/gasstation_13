GLOBAL_LIST_INIT(gas_recipe_meta, gas_recipes_list())
#define META_RECIPE_ID 1
#define META_RECIPE_MACHINE_TYPE 2
#define META_RECIPE_NAME 3
#define META_RECIPE_MIN_TEMP 4
#define META_RECIPE_MAX_TEMP 5
#define META_RECIPE_REACTION_TYPE 6
#define META_RECIPE_ENERGY_RELEASE 7
#define META_RECIPE_REQUIREMENTS 8
#define META_RECIPE_PRODUCTS 9

/proc/gas_recipes_list()
	. = subtypesof(/datum/gas_recipe)
	for(var/recipe_path in .)
		var/list/recipe_info = new(9)
		var/datum/gas_recipe/recipe = new recipe_path()

		recipe_info[META_RECIPE_ID] = initial(recipe.id)
		recipe_info[META_RECIPE_MACHINE_TYPE] = initial(recipe.machine_type)
		recipe_info[META_RECIPE_NAME] = initial(recipe.name)
		recipe_info[META_RECIPE_MIN_TEMP] = initial(recipe.min_temp)
		recipe_info[META_RECIPE_MAX_TEMP] = initial(recipe.max_temp)
		recipe_info[META_RECIPE_REACTION_TYPE] = initial(recipe.reaction_type)
		recipe_info[META_RECIPE_ENERGY_RELEASE] = initial(recipe.energy_release)
		recipe_info[META_RECIPE_REQUIREMENTS] = recipe.requirements
		recipe_info[META_RECIPE_PRODUCTS] = recipe.products

		.[recipe_path] = recipe_info

/proc/recipe_id2path(id)
	var/list/meta_recipe = GLOB.gas_recipe_meta
	if(id in meta_recipe)
		return id
	for(var/path in meta_recipe)
		if(meta_recipe[path][META_RECIPE_ID] == id)
			return path
	return ""

/datum/gas_recipe
	///Id of the recipe for easy identification in the code
	var/id = ""
	///What machine the recipe is for
	var/machine_type = ""
	///Displayed name of the recipe
	var/name = ""
	///Minimum temperature for the recipe
	var/min_temp = TCMB
	///Maximum temperature for the recipe
	var/max_temp = INFINITY
	///Type of reaction (either endothermic or exothermic)
	var/reaction_type = ""
	///Amount of energy released/consumed by the reaction (always positive)
	var/energy_release = 0
	///Gas required for the recipe to work
	var/list/requirements = list()
	///Products made from the machine
	var/list/products = list()

/datum/gas_recipe/crystallizer
	machine_type = "Crystallizer"

/datum/gas_recipe/crystallizer/metallic_hydrogen
	id = "metal_h"
	name = "Metallic hydrogen"
	min_temp = 50000
	max_temp = 150000
	reaction_type = "endothermic"
	energy_release = 250000
	requirements = list(/datum/gas/hydrogen = 600, /datum/gas/bz = 200)
	products = list(/obj/item/stack/sheet/mineral/metal_hydrogen = 2)

/datum/gas_recipe/crystallizer/healium_grenade
	id = "healium_g"
	name = "Healium crystal"
	min_temp = 200
	max_temp = 400
	reaction_type = "endothermic"
	energy_release = 100000
	requirements = list(/datum/gas/healium = 400, /datum/gas/freon = 800, /datum/gas/plasma = 50)
	products = list(/obj/item/grenade/gas_crystal/healium_crystal = 1)

/datum/gas_recipe/crystallizer/proto_nitrate_grenade
	id = "proto_nitrate_g"
	name = "Proto nitrate crystal"
	min_temp = 200
	max_temp = 400
	reaction_type = "exothermic"
	energy_release = 150000
	requirements = list(/datum/gas/proto_nitrate = 400, /datum/gas/nitrogen = 800, /datum/gas/oxygen = 800)
	products = list(/obj/item/grenade/gas_crystal/proto_nitrate_crystal = 1)

/datum/gas_recipe/crystallizer/hot_ice
	id = "hot_ice"
	name = "Hot ice"
	min_temp = 15
	max_temp = 35
	reaction_type = "endothermic"
	energy_release = 300000
	requirements = list(/datum/gas/freon = 500, /datum/gas/plasma = 400, /datum/gas/oxygen = 300)
	products = list(/obj/item/stack/sheet/hot_ice = 3)

/datum/gas_recipe/crystallizer/ammonia_crystal
	id = "ammonia_crystal"
	name = "Ammonia crystal"
	min_temp = 200
	max_temp = 240
	reaction_type = "exothermic"
	energy_release = 15000
	requirements = list(/datum/gas/hydrogen = 500, /datum/gas/nitrogen = 400)
	products = list(/obj/item/stack/ammonia_crystals = 4)

/datum/gas_recipe/crystallizer/shard
	id = "crystal_shard"
	name = "Supermatter crystal shard"
	min_temp = TCMB
	max_temp = 5
	reaction_type = "exothermic"
	energy_release = 1500000
	requirements = list(/datum/gas/hypernoblium = 1500, /datum/gas/antinoblium = 1500, /datum/gas/bz = 2000, /datum/gas/plasma = 5000, /datum/gas/oxygen = 4500)
	products = list(/obj/machinery/power/supermatter_crystal/shard = 1)

/datum/gas_recipe/crystallizer/n2o_crystal
	id = "n2o_crystal"
	name = "Nitrous oxide crystal"
	min_temp = 50
	max_temp = 350
	reaction_type = "exothermic"
	energy_release = 350000
	requirements = list(/datum/gas/nitrous_oxide = 1000, /datum/gas/bz = 50)
	products = list(/obj/item/grenade/gas_crystal/nitrous_oxide_crystal = 1)

/datum/gas_recipe/crystallizer/diamond
	id = "diamond"
	name = "Diamond"
	min_temp = 10000
	max_temp = 30000
	reaction_type = "endothermic"
	energy_release = 650000
	requirements = list(/datum/gas/carbon_dioxide = 10000)
	products = list(/obj/item/stack/sheet/mineral/diamond = 1)

/datum/gas_recipe/crystallizer/plasma_sheet
	id = "plasma_sheet"
	name = "Plasma sheet"
	min_temp = 100
	max_temp = 140
	reaction_type = "endothermic"
	energy_release = 15000
	requirements = list(/datum/gas/plasma = 25)
	products = list(/obj/item/stack/sheet/mineral/plasma = 1)

/datum/gas_recipe/crystallizer/crystal_cell
	id = "crystal_cell"
	name = "Crystal Cell"
	min_temp = 50
	max_temp = 90
	reaction_type = "endothermic"
	energy_release = 80000
	requirements = list(/datum/gas/plasma = 4000, /datum/gas/helium = 1000, /datum/gas/bz = 50)
	products = list(/obj/item/stock_parts/cell/crystal_cell = 1)

/datum/gas_recipe/crystallizer/zaukerite
	id = "zaukerite"
	name = "Zaukerite sheet"
	min_temp = 5
	max_temp = 20
	reaction_type = "exothermic"
	energy_release = 29000
	requirements = list(/datum/gas/antinoblium = 100, /datum/gas/zauker = 500, /datum/gas/bz = 75)
	products = list(/obj/item/stack/sheet/mineral/zaukerite = 2)

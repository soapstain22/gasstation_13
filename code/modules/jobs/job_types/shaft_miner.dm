/datum/job/shaft_miner
	title = JOB_SHAFT_MINER
	description = "Travel to strange lands. Mine ores. \
		Meet strange creatures. Kill them for their gold."
	department_head = list(JOB_QUARTERMASTER)
	faction = FACTION_STATION
	total_positions = 3
	spawn_positions = 3
	supervisors = SUPERVISOR_QM
	selection_color = "#dcba97"
	exp_granted_type = EXP_TYPE_CREW
	config_tag = "SHAFT_MINER"

	outfit = /datum/outfit/job/miner
	plasmaman_outfit = /datum/outfit/plasmaman/mining

	paycheck = PAYCHECK_CREW
	paycheck_department = ACCOUNT_CAR

	mind_traits = list(TRAIT_DETECT_STORM)

	display_order = JOB_DISPLAY_ORDER_SHAFT_MINER
	bounty_types = CIV_JOB_MINE
	departments_list = list(
		/datum/job_department/cargo,
		)

	family_heirlooms = list(/obj/item/pickaxe/mini, /obj/item/shovel)
	rpg_title = "Adventurer"
	job_flags = JOB_ANNOUNCE_ARRIVAL | JOB_CREW_MANIFEST | JOB_EQUIP_RANK | JOB_CREW_MEMBER | JOB_NEW_PLAYER_JOINABLE | JOB_REOPEN_ON_ROUNDSTART_LOSS | JOB_ASSIGN_QUIRKS | JOB_CAN_BE_INTERN


/datum/outfit/job/miner
	name = "Shaft Miner"
	jobtype = /datum/job/shaft_miner

	id_trim = /datum/id_trim/job/shaft_miner
	uniform = /obj/item/clothing/under/rank/cargo/miner/lavaland
	backpack_contents = list(
		/obj/item/flashlight/seclite = 1,
		/obj/item/knife/combat/survival = 1,
		/obj/item/mining_voucher = 1,
		/obj/item/stack/marker_beacon/ten = 1,
	)
	belt = /obj/item/modular_computer/pda/shaftminer
	ears = /obj/item/radio/headset/headset_cargo/mining
	gloves = /obj/item/clothing/gloves/color/black
	shoes = /obj/item/clothing/shoes/workboots/mining
	l_pocket = /obj/item/reagent_containers/hypospray/medipen/survival
	r_pocket = /obj/item/storage/bag/ore //causes issues if spawned in backpack

	backpack = /obj/item/storage/backpack/explorer
	satchel = /obj/item/storage/backpack/satchel/explorer
	duffelbag = /obj/item/storage/backpack/duffelbag/explorer

	box = /obj/item/storage/box/survival/mining
	chameleon_extras = /obj/item/gun/energy/recharge/kinetic_accelerator

/datum/outfit/job/miner/equipped
	name = "Shaft Miner (Equipment)"

	suit = /obj/item/clothing/suit/hooded/explorer
	suit_store = /obj/item/tank/internals/oxygen
	backpack_contents = list(
		/obj/item/flashlight/seclite = 1,
		/obj/item/gun/energy/recharge/kinetic_accelerator = 1,
		/obj/item/knife/combat/survival = 1,
		/obj/item/mining_voucher = 1,
		/obj/item/stack/marker_beacon/ten = 1,
		/obj/item/t_scanner/adv_mining_scanner/lesser = 1,
	)
	glasses = /obj/item/clothing/glasses/meson
	mask = /obj/item/clothing/mask/gas/explorer
	internals_slot = ITEM_SLOT_SUITSTORE

/datum/outfit/job/miner/equipped/post_equip(mob/living/carbon/human/miner, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	if(istype(miner.wear_suit, /obj/item/clothing/suit/hooded))
		var/obj/item/clothing/suit/hooded/explorer_suit = miner.wear_suit
		explorer_suit.ToggleHood()

/datum/outfit/job/miner/equipped/mod
	name = "Shaft Miner (Equipment + MODsuit)"
	back = /obj/item/mod/control/pre_equipped/mining
	suit = null
	mask = /obj/item/clothing/mask/gas/explorer

/datum/outfit/job/miner/equipped/combat
	name = "Shaft Miner (Combat-Ready)"
	glasses = /obj/item/clothing/glasses/hud/health/night/meson
	gloves = /obj/item/clothing/gloves/bracer
	accessory = /obj/item/clothing/accessory/talisman
	backpack_contents = list(
		/obj/item/t_scanner/adv_mining_scanner = 1,
		/obj/item/gps/mining = 1,
		/obj/item/gun/energy/recharge/kinetic_accelerator = 1,
		/obj/item/kinetic_crusher/compact = 1,
	)
	l_pocket = /obj/item/modular_computer/pda/shaftminer
	belt = /obj/item/storage/belt/mining/healing

/datum/outfit/job/miner/equipped/combat/post_equip(mob/living/carbon/human/miner, visualsOnly = FALSE)
	. = ..()
	if(visualsOnly)
		return
	var/list/miner_contents = miner.get_all_contents()
	var/obj/item/clothing/suit/hooded/explorer/explorer_suit = locate() in miner_contents
	if(explorer_suit)
		for(var/i in 1 to 3)
			var/obj/item/stack/sheet/animalhide/goliath_hide/plating = new()
			explorer_suit.attackby(plating)
		for(var/i in 1 to 3)
			var/obj/item/stack/sheet/animalhide/goliath_hide/plating = new()
			explorer_suit.hood.attackby(plating)
	var/obj/item/gun/energy/recharge/kinetic_accelerator/accelerator = locate() in miner_contents
	if(accelerator)
		var/obj/item/knife/combat/survival/knife = new(accelerator)
		accelerator.bayonet = knife
		var/obj/item/flashlight/seclite/flashlight = new()
		var/datum/component/seclite_attachable/light_component = accelerator.GetComponent(/datum/component/seclite_attachable)
		light_component.add_light(flashlight)

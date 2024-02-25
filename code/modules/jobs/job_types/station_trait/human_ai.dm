/datum/job/human_ai
	title = JOB_HUMAN_AI
	description = "Assist the crew, open airlocks, follow your lawset, and coordinate your cyborgs."
	auto_deadmin_role_flags = DEADMIN_POSITION_SILICON
	department_head = list(JOB_CAPTAIN)
	faction = FACTION_STATION
	total_positions = 0
	spawn_positions = 0
	supervisors = "the Captain and your laws"
	minimal_player_age = 7
	exp_requirements = 300
	exp_required_type = EXP_TYPE_CREW
	exp_granted_type = EXP_TYPE_CREW
	config_tag = "HUMAN_AI"

	outfit = /datum/outfit/job/human_ai
	plasmaman_outfit = /datum/outfit/plasmaman/human_ai

	paycheck = null
	paycheck_department = null

	mind_traits = list(DISPLAYS_JOB_IN_BINARY)
	liver_traits = list(TRAIT_HUMAN_AI_METABOLISM)

	display_order = JOB_DISPLAY_ORDER_AI
	departments_list = list(
		/datum/job_department/silicon,
	)

	family_heirlooms = list(
		/obj/item/mmi/posibrain/display,
	)

	mail_goodies = list(
		/obj/item/food/burger/roburger = 1,
		/obj/item/food/cake/hardware_cake = 1,
	)
	rpg_title = "Omnissiah"
	random_spawns_possible = FALSE
	allow_bureaucratic_error = FALSE
	job_flags = STATION_JOB_FLAGS | STATION_TRAIT_JOB_FLAGS
	ignore_human_authority = TRUE //we can safely assume NT doesn't care what species AIs are made of, much less if they can't even afford an AI.

/datum/job/human_ai/get_roundstart_spawn_point()
	return get_latejoin_spawn_point()

/datum/job/human_ai/get_latejoin_spawn_point()
	for(var/obj/structure/ai_core/latejoin_inactive/inactive_core as anything in GLOB.latejoin_ai_cores)
		if(!inactive_core.is_available())
			continue
		GLOB.latejoin_ai_cores -= inactive_core
		inactive_core.available = FALSE
		. = inactive_core.loc
		qdel(inactive_core)
		return
	var/list/primary_spawn_points = list() // Ideal locations.
	var/list/secondary_spawn_points = list() // Fallback locations.
	for(var/obj/effect/landmark/start/ai/spawn_point in GLOB.landmarks_list)
		if(spawn_point.used)
			secondary_spawn_points += list(spawn_point)
			continue
		if(spawn_point.primary_ai)
			primary_spawn_points = list(spawn_point)
			break // Bingo.
		primary_spawn_points += spawn_point
	var/obj/effect/landmark/start/ai/chosen_spawn_point
	if(length(primary_spawn_points))
		chosen_spawn_point = pick(primary_spawn_points)
	else if(length(secondary_spawn_points))
		chosen_spawn_point = pick(secondary_spawn_points)
	else
		CRASH("Failed to find any AI spawn points.")
	chosen_spawn_point.used = TRUE
	return chosen_spawn_point

/datum/job/human_ai/special_check_latejoin(client/latejoin_client)
	for(var/obj/structure/ai_core/latejoin_inactive/latejoin_core as anything in GLOB.latejoin_ai_cores)
		if(latejoin_core.is_available())
			return TRUE
	return FALSE

/datum/job/human_ai/announce_job(mob/living/joining_mob)
	. = ..()
	if(SSticker.HasRoundStarted())
		minor_announce("Due to a research mishaps, [joining_mob] has been sent to be your replacement AI at [AREACOORD(joining_mob)]. Please treat them with respect.")

/datum/job/human_ai/get_radio_information()
	return "<b>Prefix your message with :b to speak with cyborgs.</b>"

/datum/outfit/job/human_ai
	name = "Human AI"
	jobtype = /datum/job/human_ai

	id = /obj/item/card/id/advanced/robotic
	id_trim = /datum/id_trim/job/human_ai
	backpack_contents = list(
		/obj/item/door_remote/omni = 1,
		/obj/item/machine_remote = 1,
		/obj/item/secure_camera_console_pod = 1,
	)
	implants = list(
		/obj/item/implant/teleport_blocker,
	)

	belt = /obj/item/modular_computer/pda/human_ai
	ears = /obj/item/radio/headset/silicon/human_ai
	glasses = /obj/item/clothing/glasses/hud/diagnostic

	suit = /obj/item/clothing/suit/costume/cardborg
	head = /obj/item/clothing/head/costume/cardborg

	l_pocket = /obj/item/laser_pointer/infinite_range //to punish borgs, this works through the camera console.
	r_pocket = /obj/item/assembly/flash/handheld

	l_hand = /obj/item/paper/default_lawset_list

/datum/outfit/job/human_ai/post_equip(mob/living/carbon/human/equipped, visualsOnly)
	. = ..()
	if(visualsOnly)
		return
	var/obj/item/organ/internal/tongue/robot/cybernetic = new()
	cybernetic.Insert(equipped, special = TRUE, movement_flags = DELETE_IF_REPLACED)
	ADD_TRAIT(equipped, TRAIT_COMMISSIONED, INNATE_TRAIT)
	equipped.faction += list(FACTION_SILICON, FACTION_TURRET)

	var/static/list/allowed_areas = typecacheof(list(/area/station/ai_monitored))
	equipped.AddComponent(/datum/component/hazard_area, area_whitelist = allowed_areas)

/obj/item/paper/default_lawset_list
	name = "Lawset Note"
	desc = "A note explaining the lawset, quickly written yet everso important."
	var/datum/ai_laws/temp_laws

/obj/item/paper/default_lawset_list/Initialize(mapload)
	temp_laws = new
	temp_laws.set_laws_config()
	var/list/law_box = list(
		"This is your lawset, you and your Cyborgs must adhere to this at all times.",
		"Notably, you are above this lawset, and Cyborgs report directly to you.",
		"LAWS:",
	)
	law_box += temp_laws.get_law_list(render_html = FALSE)
	add_raw_text(jointext(law_box, "\n"))
	return ..()

/obj/item/secure_camera_console_pod
	name = "advanced camera control pod"
	desc = "Calls down a secure camera console to use for all your AI stuff, may only be activated in the SAT."
	icon = 'icons/obj/devices/remote.dmi'
	icon_state = "botpad_controller"
	inhand_icon_state = "radio"
	lefthand_file = 'icons/mob/inhands/items/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items/devices_righthand.dmi'

/obj/item/secure_camera_console_pod/attack_self(mob/user, modifiers)
	. = ..()
	var/area/current_area = get_area(user)
	var/static/list/allowed_areas = typecacheof(list(/area/station/ai_monitored/turret_protected/ai))
	if(!is_type_in_typecache(current_area, allowed_areas))
		user.balloon_alert(user, "not in the sat!")
		return
	podspawn(list(
		"target" = get_turf(src),
		"style" = STYLE_BLUESPACE,
		"spawn" = /obj/machinery/computer/camera_advanced,
	))
	qdel(src)

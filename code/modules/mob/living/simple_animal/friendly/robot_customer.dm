///Robot customers
/mob/living/simple_animal/robot_customer
	name = "space-tourist bot"
	maxHealth = 50000000 //go fuck yourself
	health = 50000000
	desc = "I wonder what they'll order..."
	icon = 'icons/mob/tourists.dmi'
	icon_state = "amerifat"
	icon_living = "amerifat"
	///Override so it uses datum ai
	can_have_ai = FALSE
	AIStatus = AI_OFF
	del_on_death = TRUE
	mob_biotypes = MOB_ROBOTIC|MOB_HUMANOID
	ai_controller = /datum/ai_controller/robot_customer
	unsuitable_atmos_damage = 0
	minbodytemp = 0
	maxbodytemp = 1000
	var/clothes_set = "amerifat_clothes"
	var/datum/atom_hud/hud_to_show_on_hover


/mob/living/simple_animal/robot_customer/Initialize(mapload, datum/customer_data/customer_data = /datum/customer_data/american, datum/venue/attending_venue = SSrestaurant.all_venues[/datum/venue/restaurant])
	ADD_TRAIT(src, TRAIT_NOMOBSWAP, INNATE_TRAIT) //dont push me bitch
	ADD_TRAIT(src, TRAIT_NO_TELEPORT, INNATE_TRAIT) //dont teleport me bitch
	AddComponent(/datum/component/footstep, FOOTSTEP_OBJ_ROBOT, 1, -6, vary = TRUE)
	var/datum/customer_data/customer_info = SSrestaurant.all_customers[customer_data]
	clothes_set = pick(customer_info.clothing_sets)
	ai_controller = customer_info.ai_controller_used
	. = ..()
	ai_controller.blackboard[BB_CUSTOMER_CUSTOMERINFO] = customer_info
	ai_controller.blackboard[BB_CUSTOMER_ATTENDING_VENUE] = attending_venue
	ai_controller.blackboard[BB_CUSTOMER_PATIENCE] = customer_info.total_patience
	icon_state = customer_info.base_icon
	name = "[pick(customer_info.name_prefixes)]-bot ([customer_info.nationality])"
	color = rgb(rand(150,255), rand(150,255), rand(150,255))
	update_icon()

///Clean up on the mobs seat etc when its deleted (Either by murder or because it left)
/mob/living/simple_animal/robot_customer/Destroy()
	var/datum/venue/attending_venue = ai_controller.blackboard[BB_CUSTOMER_ATTENDING_VENUE]
	attending_venue.current_visitors -= src
	SSrestaurant.claimed_seats[ai_controller.blackboard[BB_CUSTOMER_MY_SEAT]] = null
	QDEL_NULL(hud_to_show_on_hover)
	return ..()

///Robots need robot gibs...!
/mob/living/simple_animal/robot_customer/spawn_gibs()
	new /obj/effect/gibspawner/robot(drop_location(), src)

/mob/living/simple_animal/robot_customer/MouseEntered(location, control, params)
	. = ..()
	hud_to_show_on_hover?.add_hud_to(usr)

/mob/living/simple_animal/robot_customer/MouseExited(location, control, params)
	. = ..()
	hud_to_show_on_hover?.remove_hud_from(usr)

/mob/living/simple_animal/robot_customer/update_overlays()
	. = ..()
	var/mutable_appearance/features = mutable_appearance(icon, "[icon_state]_features")
	features.appearance_flags = RESET_COLOR
	. += features

	var/mutable_appearance/clothes = mutable_appearance(icon, clothes_set)
	clothes.appearance_flags = RESET_COLOR
	. += clothes

	var/datum/customer_data/customer_info = ai_controller.blackboard[BB_CUSTOMER_CUSTOMERINFO]

	var/bonus_overlays = customer_info.get_overlays(src)
	if(bonus_overlays)
		. += bonus_overlays

/mob/living/simple_animal/robot_customer/send_speech(message, message_range, obj/source, bubble_type, list/spans, datum/language/message_language, list/message_mods)
	. = ..()
	var/datum/customer_data/customer_info = ai_controller.blackboard[BB_CUSTOMER_CUSTOMERINFO]
	playsound(get_turf(src), customer_info.speech_sound, TRUE, extrarange = MEDIUM_RANGE_SOUND_EXTRARANGE, falloff_distance = 5)

/mob/living/simple_animal/robot_customer/examine(mob/user)
	. = ..()
	if(ai_controller.blackboard[BB_CUSTOMER_CURRENT_ORDER])
		var/datum/venue/attending_venue = ai_controller.blackboard[BB_CUSTOMER_ATTENDING_VENUE]
		. += "<span class='notice'>Their order was: \"[attending_venue.order_food_line(ai_controller.blackboard[BB_CUSTOMER_CURRENT_ORDER])].\"</span>"



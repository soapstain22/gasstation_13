/datum/round_event_control/heart_attack
	name = "Random Heart Attack"
	typepath = /datum/round_event/heart_attack
	weight = 20
	max_occurrences = 2
	earliest_start = 12000
	min_players = 40 // To avoid shafting lowpop

/datum/round_event/heart_attack/start()
	var/list/heart_attack_contestants = list()
	for(var/mob/living/carbon/H in shuffle(GLOB.player_list))
		if(!H.client || H.stat == DEAD || H.InCritical() || !H.can_heartattack() || H.has_status_effect(STATUS_EFFECT_EXERCISED) || (/datum/disease/heart_failure in H.viruses) || H.undergoing_cardiac_arrest())
			continue
		if(H.satiety <= -100)
			heart_attack_contestants[H] = 1.15
		else
			heart_attack_contestants[H] = 1

	if(LAZYLEN(heart_attack_contestants))
		var/mob/living/carbon/C = pickweight(heart_attack_contestants)
		var/datum/disease/D = new /datum/disease/heart_failure
		C.ForceContractDisease(D)
		notify_ghosts("[C] is beginning to have a heart attack!",
			enter_link="<a href=?src=[REF(C)];orbit=1>(Click to orbit)</a>",
			source=C, action=NOTIFY_ORBIT)

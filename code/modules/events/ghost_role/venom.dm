/datum/round_event_control/venom
	name = "Spawn Venom"
	typepath = /datum/round_event/ghost_role/venom
	weight = 50
	max_occurrences = 1
	min_players = 10
	category = EVENT_CATEGORY_ENTITIES
	description = "Spawns venom."

/datum/round_event/ghost_role/venom
	minimum_required = 1
	role_name = "Venom"
	announce_when = 10

/datum/round_event/ghost_role/venom/spawn_role()
	var/list/candidates = get_candidates(ROLE_PAI, ROLE_PAI)
	if(!length(candidates))
		return NOT_ENOUGH_PLAYERS
	var/mob/dead/selected = pick(candidates)
	var/key = selected.key
	var/spawning_z = pick(SSmapping.levels_by_trait(ZTRAIT_STATION))
	var/spawning_turf
	var/tries = 10
	while(!isspaceturf(spawning_turf))
		spawning_turf = spaceDebrisStartLoc(pick(GLOB.cardinals), spawning_z)
		tries--
		if(tries < 0)
			return MAP_ERROR
	var/obj/effect/meteor/venom/meteor = new(spawning_turf, locate(round(world.maxx/2), round(world.maxy/2), spawning_z))
	var/mob/living/simple_animal/hostile/venom/venom = new(meteor)
	venom.key = key
	venom.mind.set_assigned_role(SSjob.GetJobType(/datum/job/venom))
	venom.mind.special_role = ROLE_VENOM
	venom.mind.add_antag_datum(/datum/antagonist/venom)
	message_admins("[ADMIN_LOOKUPFLW(venom)] has been made into Venom by an event.")
	venom.log_message("was spawned as Venom by an event.", LOG_GAME)
	spawned_mobs += venom
	return SUCCESSFUL_SPAWN

/obj/effect/meteor/venom
	name = "weird meteor"
	icon = 'icons/mob/nonhuman-player/venom.dmi'
	icon_state = "meteor"
	hits = 5
	heavy = TRUE
	dropamt = 0
	threat = 100

/obj/effect/meteor/venom/meteor_effect()
	. = ..()
	for(var/atom/movable/atom as anything in src)
		atom.forceMove(loc)

/datum/job/venom
	title = ROLE_VENOM

/datum/antagonist/venom
	name = "\improper Venom"
	antagpanel_category = "Venom"
	job_rank = ROLE_VENOM
	show_in_antagpanel = FALSE
	show_name_in_check_antagonists = TRUE
	show_to_ghosts = TRUE
	suicide_cry = "VENOM- VENOM VEN VENOM!!"

/datum/antagonist/venom/on_gain()
	forge_objectives()
	. = ..()

/datum/antagonist/venom/greet()
	. = ..()
	owner.announce_objectives()
	to_chat(owner.current, span_danger("You are Venom! You need to find a suitable host to start your spree. They need to be wearing a MODsuit."))
	to_chat(owner.current, span_danger("By using your piercer on dead bodies with souls, your power grows. Power is used for the strength of your abilities."))

/datum/antagonist/venom/proc/forge_objectives()
	var/datum/objective/new_objective = new /datum/objective
	new_objective.owner = owner
	new_objective.explanation_text = "Kill everyone, though you may spare your host, as you need them."
	objectives += new_objective

/datum/antagonist/venom/get_preview_icon()
	return icon('icons/mob/nonhuman-player/venom.dmi', "venom")

/mob/living/simple_animal/hostile/venom
	name = "weird mass"
	desc = "What the hell is this!!"
	icon = 'icons/mob/nonhuman-player/venom.dmi'
	icon_state = "venom"
	ranged = TRUE
	ranged_message = "throws itself"
	ranged_cooldown_time = 5 SECONDS
	pass_flags = PASSTABLE|PASSGRILLE|PASSMOB
	mob_size = MOB_SIZE_TINY
	mob_biotypes = MOB_EPIC
	see_in_dark = 8
	sight = SEE_MOBS
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_plas" = 0, "max_plas" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	del_on_death = TRUE
	var/obj/song_player
	var/charging = FALSE
	var/power = 0
	var/datum/song/song
	var/obj/item/mod/control/mod

/mob/living/simple_animal/hostile/venom/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_VENTCRAWLER_ALWAYS, INNATE_TRAIT)
	song_player = new(src)
	song = new(src, "meowsynth", 0)
	song.max_repeats = INFINITY
	song.repeat = INFINITY
	song.volume = 50
	song.ParseSong(VENOM_SONG)
	INVOKE_ASYNC(song, TYPE_PROC_REF(/datum/song, start_playing), song_player)
	var/datum/action/cooldown/telepathy/telepathy = new(src)
	telepathy.Grant(src)
	var/datum/action/cooldown/mind_control/control = new(src)
	control.Grant(src)

/mob/living/simple_animal/hostile/venom/death()
	if(!QDELETED(mod))
		qdel(mod)
	return ..()

/mob/living/simple_animal/hostile/venom/Destroy()
	QDEL_NULL(song)
	QDEL_NULL(song_player)
	return ..()

/mob/living/simple_animal/hostile/venom/get_status_tab_items()
	. = ..()
	. += "Power: [power]"

/mob/living/simple_animal/hostile/venom/UnarmedAttack(atom/attack_target, proximity_flag, list/modifiers)
	OpenFire(attack_target)

/mob/living/simple_animal/hostile/venom/OpenFire(atom/target)
	if(charging || mod)
		return
	visible_message(span_danger("<b>[src]</b> [ranged_message] at [target]!"))
	COOLDOWN_START(src, ranged_cooldown, ranged_cooldown_time)
	Shoot(target)

/mob/living/simple_animal/hostile/venom/Shoot(atom/targeted_atom)
	charging = TRUE
	throw_at(targeted_atom, range = 5, speed = 1.5, thrower = src, callback = CALLBACK(src, PROC_REF(charging_end)))

/mob/living/simple_animal/hostile/venom/ex_act(severity, target, origin)
	return

/mob/living/simple_animal/hostile/venom/proc/charging_end()
	charging = FALSE

/mob/living/simple_animal/hostile/venom/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(!charging)
		return ..()
	if(!ishuman(hit_atom))
		return
	var/mob/living/carbon/human/hit_mob = hit_atom
	var/obj/item/mod/control/venom_target = locate() in hit_mob
	if(!venom_target || !venom_target.active || venom_target.activating)
		return
	hit_mob.visible_message(span_danger("<b>[src]</b> jumps onto [hit_mob]!"), span_userdanger("<b>[src]</b> jumps onto you!"))
	to_chat(hit_mob, span_hypnophrase("You feel like listening to it..."))
	shake_camera(hit_mob, 4, 3)
	shake_camera(src, 2, 3)
	venomify_mod(venom_target)

/mob/living/simple_animal/hostile/venom/proc/venomify_mod(obj/item/mod/control/mod_target)
	mod = mod_target
	RegisterSignal(mod, COMSIG_MOD_ACTIVATE, PROC_REF(block_mod_activation))
	RegisterSignal(mod, COMSIG_PARENT_QDELETING, PROC_REF(death))
	ADD_TRAIT(mod, TRAIT_NODROP, REF(src))
	ADD_TRAIT(mod.wearer, TRAIT_NOHUNGER, REF(src))
	ADD_TRAIT(mod.wearer, TRAIT_NODISMEMBER, REF(src))
	ADD_TRAIT(mod.wearer, TRAIT_NEVER_WOUNDED, REF(src))
	mod.wearer.AddComponent(/datum/component/tackler, stamina_cost = 35, base_knockdown = 3 SECONDS, range = 4, speed = 1.5, skill_mod = 5, min_distance = 2)
	qdel(mod.core)
	var/obj/item/mod/core/infinite/venom/core = new()
	core.install(mod)
	mod.slowdown_inactive = 0
	mod.slowdown_active = 0
	mod.update_speed()
	mod.set_mod_color(COLOR_BLACK)
	var/static/list/venom_modules = list(
		/obj/item/mod/module/venom_holder,
		/obj/item/mod/module/venom_tentacle,
		/obj/item/mod/module/venom_piercer,
		/obj/item/mod/module/venom_restorer,
	)
	for(var/obj/item/mod/module/venom_module as anything in venom_modules)
		venom_module = new venom_module(null, src)
		for(var/obj/item/mod/module/mod_module as anything in mod.modules)
			if(is_type_in_list(mod_module, venom_module.incompatible_modules))
				qdel(mod_module)
		mod.install(venom_module)
	mod.wearer.update_clothing(mod.slot_flags)

/mob/living/simple_animal/hostile/venom/proc/block_mod_activation(datum/source)
	SIGNAL_HANDLER
	return MOD_CANCEL_ACTIVATE

/obj/item/mod/core/infinite/venom
	name = "venom core"
	desc = "A MOD core infected by venom. Can last indefinitely."

/mob/living/passenger
	name = "control victim"
	real_name = "unknown conscience"

/mob/living/passenger/Initialize(mapload, mob/living/original)
	. = ..()
	if(!original)
		return
	name = original.real_name
	real_name = original.real_name
	original.mind?.transfer_to(src, force_key_move = TRUE)

/mob/living/passenger/UnarmedAttack(atom/attack_target, proximity_flag, list/modifiers)
	return

/mob/living/passenger/say(message, bubble_type, list/spans, sanitize, datum/language/language, ignore_spam, forced, filterproof, message_range, datum/saymode/saymode)
	to_chat(src, span_warning("You find yourself unable to speak, you aren't in control of your body!"))

/mob/living/passenger/emote(act, m_type, message, intentional, force_silence)
	to_chat(src, span_warning("You find yourself unable to emote, you aren't in control of your body!"))

/datum/action/cooldown/mind_control
	name = "Mind Control"
	desc = "Control a host's mind. Length grows exponentially with your power."
	background_icon_state = "bg_alien"
	overlay_icon_state = "bg_alien_border"
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "mindswap"
	check_flags = AB_CHECK_CONSCIOUS
	cooldown_time = 5 MINUTES
	var/controlling = FALSE
	var/timerid
	var/max_health = 0
	var/start_time
	var/mob/living/passenger/backseat
	var/mob/living/controller

/datum/action/cooldown/mind_control/Grant(mob/granted_to)
	. = ..()
	if(!controller)
		controller = granted_to

/datum/action/cooldown/mind_control/Activate(atom/target)
	if(controlling)
		stop_control()
		return
	var/mob/living/simple_animal/hostile/venom/venom = owner
	if(!istype(venom))
		return
	var/mob/living/carbon/human/host = venom.mod.wearer
	if(!host)
		to_chat(venom, span_warning("You have no host!"))
		return
	if(!host.mind)
		to_chat(venom, span_warning("Your host has no mind!"))
		return
	if(venom.power <= 1)
		to_chat(venom, span_warning("You need at least 1 power!"))
		return
	start_time = world.time
	var/control_time = (2 ** venom.power) SECONDS
	timerid = addtimer(CALLBACK(src, PROC_REF(stop_control)), control_time, TIMER_UNIQUE | TIMER_STOPPABLE)
	to_chat(venom, span_danger("We can sustain control for [DisplayTimeText(control_time)]."))
	to_chat(host, span_userdanger("Your body has been hijacked!"))
	backseat = new(host, host)
	venom.mind?.transfer_to(host, force_key_move = TRUE)
	Grant(host)
	controlling = TRUE
	max_health = host.health
	RegisterSignal(host, COMSIG_LIVING_HEALTH_UPDATE, PROC_REF(check_damage))

/datum/action/cooldown/mind_control/Destroy()
	if(controlling)
		stop_control()
	return ..()

/datum/action/cooldown/mind_control/proc/stop_control()
	if(timerid)
		deltimer(timerid)
	controlling = FALSE
	max_health = 0
	var/mob/living/carbon/human/current_body = owner
	if(QDELETED(current_body))
		backseat.ghostize(FALSE)
		return
	UnregisterSignal(current_body, COMSIG_LIVING_HEALTH_UPDATE)
	to_chat(current_body, span_userdanger("Your control ends!"))
	to_chat(backseat, span_userdanger("You return to your body!"))
	Grant(controller)
	current_body.mind?.transfer_to(controller, force_key_move = TRUE)
	backseat.mind?.transfer_to(current_body, force_key_move = TRUE)
	QDEL_NULL(backseat)
	StartCooldown(max(cooldown_time - (world.time - start_time), 0))

/datum/action/cooldown/mind_control/proc/check_damage(mob/living/host)
	SIGNAL_HANDLER

	if(host.health > max_health)
		max_health = host.health
		return
	if(host.health >= max_health - 50)
		return
	to_chat(host, span_userdanger("You've sustained too much damage!"))
	stop_control()

/datum/action/cooldown/telepathy
	name = "Telepathy"
	desc = "Talk to your host."
	background_icon_state = "bg_alien"
	overlay_icon_state = "bg_alien_border"
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "telepathy"
	check_flags = AB_CHECK_CONSCIOUS
	cooldown_time = 0 SECONDS

/datum/action/cooldown/telepathy/IsAvailable(feedback = FALSE)
	. = ..()
	if(!.)
		return FALSE
	return istype(owner, /mob/living/simple_animal/hostile/venom)

/datum/action/cooldown/telepathy/Activate(atom/target)
	var/mob/living/simple_animal/hostile/venom/venom = owner
	if(!venom.mod.wearer)
		to_chat(venom, span_warning("You have no host!"))
		return
	var/message = span_notice(tgui_input_text(venom, "What do you wish to whisper to your host?", "[src]"))
	to_chat(venom, "[span_boldnotice("You transmit to [venom.mod.wearer]:")] [message]")
	to_chat(venom.mod.wearer, "[span_boldnotice("You hear something behind you talking...")] [message]")

/obj/item/mod/module/venom_holder
	name = "MOD Venom infusion module"
	desc = "An infusion of Venom infection into the suit. This holds the venom itself."
	icon = 'icons/mob/nonhuman-player/venom.dmi'
	icon_state = "venom_holder"
	overlay_icon_file = 'icons/mob/nonhuman-player/venom.dmi'
	overlay_state_inactive = "venom_module_mob"
	incompatible_modules = list(/obj/item/mod/module/venom_holder)
	resistance_flags = INDESTRUCTIBLE
	removable = FALSE
	var/mob/living/simple_animal/hostile/venom/venom

/obj/item/mod/module/venom_holder/Initialize(mapload, mob/living/simple_animal/hostile/venom/venom)
	. = ..()
	if(!venom)
		return
	src.venom = venom
	venom.forceMove(src)
	RegisterSignal(venom, COMSIG_PARENT_QDELETING, PROC_REF(on_venom_deletion))

/obj/item/mod/module/venom_holder/on_suit_activation()
	RegisterSignal(mod.wearer, COMSIG_MOB_GET_STATUS_TAB_ITEMS, PROC_REF(get_status_tab_item))

/obj/item/mod/module/venom_holder/on_suit_deactivation(deleting = FALSE)
	UnregisterSignal(mod.wearer, COMSIG_MOB_GET_STATUS_TAB_ITEMS)

/obj/item/mod/module/venom_holder/proc/get_status_tab_item(mob/living/carbon/human/source, list/items)
	SIGNAL_HANDLER
	if(venom)
		items += "Power: [venom.power]"

/obj/item/mod/module/venom_holder/proc/on_venom_deletion(datum/source)
	SIGNAL_HANDLER
	venom = null

/obj/item/mod/module/venom_tentacle
	name = "MOD Venom tentacle module"
	desc = "A weird tentacle."
	icon = 'icons/mob/nonhuman-player/venom.dmi'
	icon_state = "venom_tentacle"
	module_type = MODULE_ACTIVE
	incompatible_modules = list(/obj/item/mod/module/venom_tentacle, /obj/item/mod/module/tether)
	cooldown_time = 1.5 SECONDS
	var/mob/living/simple_animal/hostile/venom/venom

/obj/item/mod/module/venom_tentacle/Initialize(mapload, mob/living/simple_animal/hostile/venom/venom)
	. = ..()
	if(!venom)
		return
	src.venom = venom

/obj/item/mod/module/venom_tentacle/on_select_use(atom/target)
	. = ..()
	if(!.)
		return
	var/obj/projectile/tentacle = new /obj/projectile/tentacle(mod.wearer.loc)
	tentacle.color = COLOR_BLACK
	tentacle.range = 4 + venom.power
	tentacle.preparePixelProjectile(target, mod.wearer)
	tentacle.firer = mod.wearer
	playsound(src, 'sound/effects/splat.ogg', 50, TRUE)
	INVOKE_ASYNC(tentacle, TYPE_PROC_REF(/obj/projectile, fire))

/obj/item/mod/module/venom_piercer
	name = "MOD Venom piercer module"
	desc = "A weird sharp thing."
	icon = 'icons/mob/nonhuman-player/venom.dmi'
	icon_state = "venom_piercer"
	module_type = MODULE_ACTIVE
	incompatible_modules = list(/obj/item/mod/module/venom_piercer)
	device = /obj/item/melee/venom_piercer
	cooldown_time = 1 SECONDS

/obj/item/mod/module/venom_piercer/Initialize(mapload, mob/living/simple_animal/hostile/venom/venom)
	. = ..()
	if(!venom)
		return
	var/obj/item/melee/venom_piercer/piercer = device
	piercer.venom = venom

/obj/item/mod/module/venom_piercer/on_activation()
	. = ..()
	var/obj/item/melee/venom_piercer/piercer = device
	piercer.update_power()

/obj/item/melee/venom_piercer
	name = "piercer"
	desc = "A weird fleshy mass."
	icon = 'icons/mob/nonhuman-player/venom.dmi'
	icon_state = "venom_piercer"
	inhand_icon_state = "arm_blade"
	lefthand_file = 'icons/mob/inhands/antag/changeling_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/antag/changeling_righthand.dmi'
	slot_flags = null
	w_class = WEIGHT_CLASS_HUGE
	sharpness = SHARP_EDGED
	force = 15
	wound_bonus = 5
	bare_wound_bonus = 15
	color = COLOR_BLACK
	var/mob/living/simple_animal/hostile/venom/venom

/obj/item/melee/venom_piercer/proc/update_power()
	if(!venom)
		return
	force = 15 + round(venom.power*1.5)

/obj/item/melee/venom_piercer/attack(mob/living/carbon/human/target_mob, mob/living/user, params)
	. = ..()
	if(!istype(target_mob) || !target_mob.mind || target_mob.stat != DEAD || HAS_TRAIT(target_mob, TRAIT_HUSK))
		return
	to_chat(user, span_warning("Draining their strength..."))
	if(!do_after(user, 10 SECONDS, target_mob))
		return
	target_mob.become_husk("venom")
	to_chat(user, span_warning("Their strength has been drained."))
	to_chat(venom, span_danger("You have gained power."))
	venom.power++
	update_power()

/obj/item/mod/module/venom_restorer
	name = "MOD Venom restorer module"
	desc = "A weird healy thing."
	icon = 'icons/mob/nonhuman-player/venom.dmi'
	icon_state = "venom_restorer"
	incompatible_modules = list(/obj/item/mod/module/venom_restorer)
	var/mob/living/simple_animal/hostile/venom/venom

/obj/item/mod/module/venom_restorer/Initialize(mapload, mob/living/simple_animal/hostile/venom/venom)
	. = ..()
	if(!venom)
		return
	src.venom = venom

/obj/item/mod/module/venom_restorer/on_active_process(delta_time)
	var/heal_amount = venom.power
	var/status_reduction = (-venom.power) SECONDS
	mod.wearer.heal_overall_damage(heal_amount * delta_time, heal_amount * delta_time)
	mod.wearer.adjustToxLoss(-heal_amount * delta_time)
	mod.wearer.adjustStaminaLoss(-heal_amount * 5 * delta_time)
	mod.wearer.remove_status_effect(/datum/status_effect/jitter)
	mod.wearer.AdjustStun(status_reduction * delta_time)
	mod.wearer.AdjustKnockdown(status_reduction * delta_time)
	mod.wearer.AdjustUnconscious(status_reduction * delta_time)
	mod.wearer.AdjustParalyzed(status_reduction * delta_time)
	mod.wearer.AdjustImmobilized(status_reduction * delta_time)

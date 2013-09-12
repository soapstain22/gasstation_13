
/*
	run_armor_check(a,b)
	args
	a:def_zone - What part is getting hit, if null will check entire body
	b:attack_flag - What type of attack, bullet, laser, energy, melee

	Returns
	0 - no block
	1 - halfblock
	2 - fullblock
*/
/mob/living/proc/run_armor_check(def_zone = null, attack_flag = "melee", absorb_text = null, soften_text = null)
	var/armor = getarmor(def_zone, attack_flag)
	var/absorb = 0
	if(prob(armor))
		absorb += 1
	if(prob(armor))
		absorb += 1
	if(absorb >= 2)
		if(absorb_text)
			src << "<span class='userdanger'>[absorb_text]</span>"
		else
			src << "<span class='userdanger'>Your armor absorbs the blow!</span>"
		return 2
	if(absorb == 1)
		if(absorb_text)
			show_message("[soften_text]",4)
		else
			src << "<span class='userdanger'>Your armor softens the blow!</span>"
		return 1
	return 0


/mob/living/proc/getarmor(var/def_zone, var/type)
	return 0


/mob/living/bullet_act(obj/item/projectile/P, def_zone)
	var/obj/item/weapon/cloaking_device/C = locate((/obj/item/weapon/cloaking_device) in src)
	if(C && C.active)
		C.attack_self(src)//Should shut it off
		update_icons()
		src << "<span class='notice'>Your [C] was disrupted!</span>"
		Stun(2)

	var/absorb = run_armor_check(def_zone, P.flag)
	if(absorb >= 2)
		P.on_hit(src,2)
		return 2
	if(!P.nodamage)
		apply_damage((P.damage/(absorb+1)), P.damage_type, def_zone)
	P.on_hit(src, absorb)
	return absorb

/mob/living/hitby(atom/movable/AM)//Standardization and logging -Sieve
	if(istype(AM, /obj/))
		var/obj/O = AM
		var/zone = ran_zone("chest", 65)//Hits a random part of the body, geared towards the chest
		var/dtype = BRUTE
		if(istype(O,/obj/item/weapon))
			var/obj/item/weapon/W = O
			dtype = W.damtype
		visible_message("<span class='danger'>[src] has been hit by [O].</span>", \
						"<span class='userdanger'>[src] has been hit by [O].</span>")
		var/armor = run_armor_check(zone, "melee", "Your armor has protected your [zone].", "Your armor has softened hit to your [zone].")
		if(armor < 2)
			apply_damage(O.throwforce, dtype, zone, armor, O)
		if(!O.fingerprintslast)
			return
		var/client/assailant = directory[ckey(O.fingerprintslast)]
		if(assailant && assailant.mob && istype(assailant.mob,/mob))
			var/mob/M = assailant.mob
			src.attack_log += text("\[[time_stamp()]\] <font color='orange'>Has been hit with [O], last touched by [M.name] ([assailant.ckey])</font>")
			M.attack_log += text("\[[time_stamp()]\] <font color='red'>Hit [src.name] ([src.ckey]) with [O]</font>")
			log_attack("<font color='red'>[src.name] ([src.ckey]) was hit by [O], last touched by [M.name] ([assailant.ckey])</font>")

//Mobs on Fire
/mob/living/proc/IgniteMob()
		on_fire = 1
		fire_stacks = 0

/mob/living/proc/ExtinguishMob()
	if(on_fire)
		on_fire = 0
//Mobs on Fire end
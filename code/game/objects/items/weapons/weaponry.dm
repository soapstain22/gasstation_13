/obj/item/weapon/banhammer
	desc = "A banhammer"
	name = "banhammer"
	icon = 'icons/obj/items.dmi'
	icon_state = "toyhammer"
	slot_flags = SLOT_BELT
	throwforce = 0
	w_class = 1
	throw_speed = 3
	throw_range = 7
	attack_verb = list("banned")

/obj/item/weapon/banhammer/suicide_act(mob/user)
		user.visible_message("<span class='suicide'>[user] is hitting \himself with the [src.name]! It looks like \he's trying to ban \himself from life.</span>")
		return (BRUTELOSS|FIRELOSS|TOXLOSS|OXYLOSS)

/obj/item/weapon/banhammer/attack(mob/M, mob/user)
	M << "<font color='red'><b> You have been banned FOR NO REISIN by [user]<b></font>"
	user << "<font color='red'>You have <b>BANNED</b> [M]</font>"
	playsound(loc, 'sound/effects/adminhelp.ogg', 15) //keep it at 15% volume so people don't jump out of their skin too much

/obj/item/weapon/sord
	name = "\improper SORD"
	desc = "This thing is so unspeakably shitty you are having a hard time even holding it."
	icon_state = "sord"
	item_state = "sord"
	slot_flags = SLOT_BELT
	force = 2
	throwforce = 1
	w_class = 3
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("attacked", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")

/obj/item/weapon/sord/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] is trying to impale \himself with \the [name]! It might be a suicide attempt if it weren't so shitty.</span>", "<span class='suicide'>You try to impale yourself with \the [name], but it's USELESS...</span>")
	return(SHAME)

/obj/item/weapon/claymore
	name = "claymore"
	desc = "What are you standing around staring at this for? Get to killing!"
	icon_state = "claymore"
	item_state = "claymore"
	hitsound = 'sound/weapons/bladeslice.ogg'
	flags = CONDUCT
	slot_flags = SLOT_BELT | SLOT_BACK
	force = 40
	throwforce = 10
	w_class = 3
	attack_verb = list("attacked", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	block_chance = 50
	sharpness = IS_SHARP

/obj/item/weapon/claymore/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] is falling on the [src.name]! It looks like \he's trying to commit suicide.</span>")
	return(BRUTELOSS)

var/highlander_claymores = 0
/obj/item/weapon/claymore/highlander //ALL COMMENTS MADE REGARDING THIS SWORD MUST BE MADE IN ALL CAPS
	desc = "<b><i>THERE CAN BE ONLY ONE, AND IT WILL BE YOU!!!</i></b>\nActivate it in your hand to point to the nearest victim."
	flags = CONDUCT | NODROP
	slot_flags = null
	block_chance = 0 //RNG WON'T HELP YOU NOW, PANSY
	attack_verb = list("brutalized", "eviscerated", "disemboweled", "hacked", "carved", "cleaved") //ONLY THE MOST VISCERAL ATTACK VERBS
	var/notches = 0 //HOW MANY PEOPLE HAVE BEEN SLAIN WITH THIS BLADE
	var/announced = FALSE //IF WE ARE THE ONLY ONE LEFT STANDING
	var/bloodthirst_level = 0 //HOW THIRSTY WE ARE FOR BLOOD

/obj/item/weapon/claymore/highlander/New()
	..()
	START_PROCESSING(SSobj, src)
	highlander_claymores++

/obj/item/weapon/claymore/highlander/Destroy()
	STOP_PROCESSING(SSobj, src)
	highlander_claymores--
	return ..()

/obj/item/weapon/claymore/highlander/process()
	if(isliving(loc))
		var/mob/living/L = loc
		if(L.stat != DEAD)
			if(!announced)
				handle_bloodthirst(L)
			if(announced || admin_spawned || highlander_claymores > 1)
				return
			announced = TRUE
			L.fully_heal()
			world << "<span class='userdanger'>[L.real_name] IS THE ONLY ONE LEFT STANDING!</span>"
			world << sound('sound/misc/highlander_only_one.ogg')
			L << "<span class='notice'>YOU ARE THE ONLY ONE LEFT STANDING!</span>"
			for(var/obj/item/weapon/bloodcrawl/B in L)
				qdel(B)

/obj/item/weapon/claymore/highlander/pickup(mob/living/user)
	user << "<span class='notice'>The power of Scotland protects you! You are shielded from all stuns and knockdowns.</span>"
	user.add_stun_absorption("highlander", INFINITY, 1, "is protected by the power of Scotland!", "The power of Scotland absorbs the stun!", " is protected by the power of Scotland!")

/obj/item/weapon/claymore/highlander/dropped(mob/living/user)
	user << "<span class='danger'>The power of Scotland fades away! You are no longer shielded from stuns.</span>"
	user.add_stun_absorption("highlander", 0.1, 1, "is protected by the power of Scotland!", "The power of Scotland absorbs the stun!", " is protected by the power of Scotland!")

/obj/item/weapon/claymore/highlander/examine(mob/user)
	..()
	user << "It has [!notches ? "nothing" : "[notches] notches"] scratched into the blade."

/obj/item/weapon/claymore/highlander/attack(mob/living/target, mob/living/user)
	var/old_target_stat = target.stat
	. = ..()
	bloodthirst_level = max(bloodthirst_level - (target.mind && target.mind.special_role == "highlander" ? 15 : 5), 0)
	if(target && target.stat == DEAD && old_target_stat != DEAD && target.mind && target.mind.special_role == "highlander")
		user.fully_heal() //STEAL THE LIFE OF OUR FALLEN FOES
		bloodthirst_level = 0
		if(bloodthirst_level >= 30)
			user << "<span class='notice'>[src] shakes greedily as it devours [target]'s soul. Its bloodthirst is quenched for the moment...</span>"
		add_notch(user)
		target.visible_message("<span class='warning'>[target] crumbles to dust beneath [user]'s blows!</span>", "<span class='userdanger'>As you fall, your body crumbles to dust!</span>")
		target.dust()

/obj/item/weapon/claymore/highlander/attack_self(mob/living/user)
	var/closest_victim
	var/closest_distance = 255
	for(var/mob/living/carbon/human/H in player_list - user)
		if(H.client && H.mind.special_role == "highlander" && (!closest_victim || get_dist(user, closest_victim) < closest_distance))
			closest_victim = H
	if(!closest_victim)
		user << "<span class='warning'>[src] thrums for a moment and falls dark. Perhaps there's nobody nearby.</span>"
		return
	user << "<span class='danger'>[src] thrums and points to the [dir2text(get_dir(user, closest_victim))].</span>"

/obj/item/weapon/claymore/highlander/IsReflect()
	return 1 //YOU THINK YOUR PUNY LASERS CAN STOP ME?

/obj/item/weapon/claymore/highlander/proc/add_notch(mob/living/user) //DYNAMIC CLAYMORE PROGRESSION SYSTEM - THIS IS THE FUTURE
	notches++
	force++
	var/new_name = name
	switch(notches)
		if(1)
			user << "<span class='notice'>Your first kill - hopefully one of many. You scratch a notch into [src]'s blade.</span>"
			user << "<span class='warning'>You feel your fallen foe's soul entering your blade, restoring your wounds!</span>"
			new_name = "notched claymore"
		if(2)
			user << "<span class='notice'>Another falls before you. Another soul fuses with your own. Another notch in the blade.</span>"
			new_name = "double-notched claymore"
			color = rgb(255, 235, 235)
		if(3)
			user << "<span class='notice'>You're beginning to</span> <span class='danger'><b>relish</b> the <b>thrill</b> of <b>battle.</b></span>"
			new_name = "triple-notched claymore"
			color = rgb(255, 215, 215)
		if(4)
			user << "<span class='notice'>You've lost count of</span> <span class='boldannounce'>how many you've killed.</span>"
			new_name = "many-notched claymore"
			color = rgb(255, 195, 195)
		if(5)
			user << "<span class='boldannounce'>Five voices now echo in your mind, cheering the slaughter.</span>"
			new_name = "battle-tested claymore"
			color = rgb(255, 175, 175)
		if(6)
			user << "<span class='boldannounce'>Is this what the vikings felt like? Visions of glory fill your head as you slay your sixth foe.</span>"
			new_name = "battle-scarred claymore"
			color = rgb(255, 155, 155)
		if(7)
			user << "<span class='boldannounce'>Kill. Butcher. <i>Conquer.</i></span>"
			new_name = "vicious claymore"
			color = rgb(255, 135, 135)
		if(8)
			user << "<span class='userdanger'>IT NEVER GETS OLD. THE <i>SCREAMING</i>. THE <i>BLOOD</i> AS IT <i>SPRAYS</i> ACROSS YOUR <i>FACE.</i></span>"
			new_name = "bloodthirsty claymore"
			color = rgb(255, 115, 115)
		if(9)
			user << "<span class='userdanger'>ANOTHER ONE FALLS TO YOUR BLOWS. ANOTHER WEAKLING UNFIT TO LIVE.</span>"
			new_name = "gore-stained claymore"
			color = rgb(255, 95, 95)
		if(10)
			user.visible_message("<span class='warning'>[user]'s eyes light up with a vengeful fire!</span>", \
			"<span class='userdanger'>YOU FEEL THE POWER OF VALHALLA FLOWING THROUGH YOU! <i>THERE CAN BE ONLY ONE!!!</i></span>")
			user.update_icons()
			new_name = "GORE-DRENCHED CLAYMORE OF [pick("THE WHIMSICAL SLAUGHTER", "A THOUSAND SLAUGHTERED CATTLE", "GLORY AND VALHALLA", "ANNIHILATION", "OBLITERATION")]"
			icon_state = "claymore_valhalla"
			item_state = "cultblade"
			color = initial(color)

	name = new_name
	playsound(user, 'sound/items/Screwdriver2.ogg', 50, 1)

/obj/item/weapon/claymore/highlander/proc/handle_bloodthirst(mob/living/S) //THE BLADE THIRSTS FOR BLOOD AND WILL PUNISH THE WEAK OR PACIFISTIC
	bloodthirst_level += (1 + min(notches, 10))
	if(bloodthirst_level == 30)
		S << "<span class='warning'>[src] shudders in your hand. It hungers for battle...</span>"
	if(bloodthirst_level == 60)
		S << "<span class='boldwarning'>[src] trembles violently. You feel your own life force draining. Kill someone already!</span>"
	if(bloodthirst_level == 90)
		S << "<span class='userdanger'>[src] starts feeding off of your body! Kill someone or it will kill <i>you!</i></span>"
	if(bloodthirst_level >= 120)
		S.visible_message("<span class='warning'>[S]'s [name] devours their soul!</span>", "<span class='userdanger'>Your [name] devours your soul!</span>")
		S.dust() //YOU SHOULD'VE KILLED SOMEONE.

/obj/item/weapon/katana
	name = "katana"
	desc = "Woefully underpowered in D20"
	icon_state = "katana"
	item_state = "katana"
	flags = CONDUCT
	slot_flags = SLOT_BELT | SLOT_BACK
	force = 40
	throwforce = 10
	w_class = 3
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("attacked", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	block_chance = 50
	sharpness = IS_SHARP

/obj/item/weapon/katana/cursed
	slot_flags = null

/obj/item/weapon/katana/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] is slitting \his stomach open with the [src.name]! It looks like \he's trying to commit seppuku.</span>")
	return(BRUTELOSS)

/obj/item/weapon/wirerod
	name = "wired rod"
	desc = "A rod with some wire wrapped around the top. It'd be easy to attach something to the top bit."
	icon_state = "wiredrod"
	item_state = "rods"
	flags = CONDUCT
	force = 9
	throwforce = 10
	w_class = 3
	materials = list(MAT_METAL=1150, MAT_GLASS=75)
	attack_verb = list("hit", "bludgeoned", "whacked", "bonked")

/obj/item/weapon/wirerod/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/weapon/shard))
		var/obj/item/weapon/twohanded/spear/S = new /obj/item/weapon/twohanded/spear

		if(!remove_item_from_storage(user))
			user.unEquip(src)
		user.unEquip(I)

		user.put_in_hands(S)
		user << "<span class='notice'>You fasten the glass shard to the top of the rod with the cable.</span>"
		qdel(I)
		qdel(src)

	else if(istype(I, /obj/item/device/assembly/igniter) && !(I.flags & NODROP))
		var/obj/item/weapon/melee/baton/cattleprod/P = new /obj/item/weapon/melee/baton/cattleprod

		if(!remove_item_from_storage(user))
			user.unEquip(src)
		user.unEquip(I)

		user.put_in_hands(P)
		user << "<span class='notice'>You fasten [I] to the top of the rod with the cable.</span>"
		qdel(I)
		qdel(src)
	else
		return ..()


/obj/item/weapon/throwing_star
	name = "throwing star"
	desc = "An ancient weapon still used to this day due to it's ease of lodging itself into victim's body parts"
	icon_state = "throwingstar"
	item_state = "eshield0"
	force = 2
	throwforce = 20 //This is never used on mobs since this has a 100% embed chance.
	throw_speed = 4
	embedded_pain_multiplier = 4
	w_class = 2
	embed_chance = 100
	embedded_fall_chance = 0 //Hahaha!
	sharpness = IS_SHARP
	materials = list(MAT_METAL=500, MAT_GLASS=500)


/obj/item/weapon/switchblade
	name = "switchblade"
	icon_state = "switchblade"
	desc = "A sharp, concealable, spring-loaded knife."
	flags = CONDUCT
	force = 3
	w_class = 2
	throwforce = 5
	throw_speed = 3
	throw_range = 6
	materials = list(MAT_METAL=12000)
	origin_tech = "engineering=3;combat=2"
	hitsound = 'sound/weapons/Genhit.ogg'
	attack_verb = list("stubbed", "poked")
	var/extended = 0

/obj/item/weapon/switchblade/attack_self(mob/user)
	extended = !extended
	playsound(src.loc, 'sound/weapons/batonextend.ogg', 50, 1)
	if(extended)
		force = 20
		w_class = 3
		throwforce = 23
		icon_state = "switchblade_ext"
		attack_verb = list("slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
		hitsound = 'sound/weapons/bladeslice.ogg'
		sharpness = IS_SHARP
	else
		force = 3
		w_class = 2
		throwforce = 5
		icon_state = "switchblade"
		attack_verb = list("stubbed", "poked")
		hitsound = 'sound/weapons/Genhit.ogg'
		sharpness = IS_BLUNT

/obj/item/weapon/switchblade/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] is slitting \his own throat with the [src.name]! It looks like \he's trying to commit suicide.</span>")
	return (BRUTELOSS)

/obj/item/weapon/phone
	name = "red phone"
	desc = "Should anything ever go wrong..."
	icon = 'icons/obj/items.dmi'
	icon_state = "red_phone"
	force = 3
	throwforce = 2
	throw_speed = 3
	throw_range = 4
	w_class = 2
	attack_verb = list("called", "rang")
	hitsound = 'sound/weapons/ring.ogg'

/obj/item/weapon/phone/suicide_act(mob/user)
	if(locate(/obj/structure/chair/stool) in user.loc)
		user.visible_message("<span class='suicide'>[user] begins to tie a noose with the [src.name]'s cord! It looks like \he's trying to commit suicide.</span>")
	else
		user.visible_message("<span class='suicide'>[user] is strangling \himself with the [src.name]'s cord! It looks like \he's trying to commit suicide.</span>")
	return(OXYLOSS)

/obj/item/weapon/cane
	name = "cane"
	desc = "A cane used by a true gentleman. Or a clown."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "cane"
	item_state = "stick"
	force = 5
	throwforce = 5
	w_class = 2
	materials = list(MAT_METAL=50)
	attack_verb = list("bludgeoned", "whacked", "disciplined", "thrashed")

/obj/item/weapon/staff
	name = "wizard staff"
	desc = "Apparently a staff used by the wizard."
	icon = 'icons/obj/wizard.dmi'
	icon_state = "staff"
	force = 3
	throwforce = 5
	throw_speed = 2
	throw_range = 5
	w_class = 2
	armour_penetration = 100
	attack_verb = list("bludgeoned", "whacked", "disciplined")
	burn_state = FLAMMABLE

/obj/item/weapon/staff/broom
	name = "broom"
	desc = "Used for sweeping, and flying into the night while cackling. Black cat not included."
	icon = 'icons/obj/wizard.dmi'
	icon_state = "broom"
	burn_state = FLAMMABLE

/obj/item/weapon/staff/stick
	name = "stick"
	desc = "A great tool to drag someone else's drinks across the bar."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "stick"
	item_state = "stick"
	force = 3
	throwforce = 5
	throw_speed = 2
	throw_range = 5
	w_class = 2

/obj/item/weapon/ectoplasm
	name = "ectoplasm"
	desc = "spooky"
	gender = PLURAL
	icon = 'icons/obj/wizard.dmi'
	icon_state = "ectoplasm"

/obj/item/weapon/ectoplasm/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] is inhaling the [src.name]! It looks like \he's trying to visit the astral plane.</span>")
	return (OXYLOSS)

/obj/item/weapon/mounted_chainsaw
	name = "mounted chainsaw"
	desc = "A chainsaw that has replaced your arm."
	icon_state = "chainsaw_on"
	item_state = "mounted_chainsaw"
	flags = NODROP | ABSTRACT
	w_class = 5.0
	force = 21
	throwforce = 0
	throw_range = 0
	throw_speed = 0
	sharpness = IS_SHARP
	attack_verb = list("sawed", "torn", "cut", "chopped", "diced")
	hitsound = "sound/weapons/chainsawhit.ogg"

/obj/item/weapon/mounted_chainsaw/dropped()
	..()
	new /obj/item/weapon/twohanded/required/chainsaw(get_turf(src))
	qdel(src)

/obj/item/weapon/statuebust
	name = "bust"
	desc = "A priceless ancient marble bust, the kind that belongs in a museum." //or you can hit people with it
	icon = 'icons/obj/statue.dmi'
	icon_state = "bust"
	force = 15
	throwforce = 10
	throw_speed = 5
	throw_range = 2
	attack_verb = list("busted")

/obj/item/weapon/tailclub
	name = "tail club"
	desc = "For the beating to death of lizards with their own tails."
	icon_state = "tailclub"
	force = 14
	throwforce = 1 // why are you throwing a club do you even weapon
	throw_speed = 1
	throw_range = 1
	attack_verb = list("clubbed", "bludgeoned")

/obj/item/weapon/melee/chainofcommand/tailwhip
	name = "liz o' nine tails"
	desc = "A whip fashioned from the severed tails of lizards."
	icon_state = "tailwhip"
	origin_tech = "engineering=3;combat=3;biotech=3"
	needs_permit = 0

/obj/item/weapon/melee/skateboard
	name = "skateboard"
	desc = "A skateboard. It can be placed on its wheels and ridden, or used as a strong weapon."
	icon_state = "skateboard"
	item_state = "skateboard"
	force = 12
	throwforce = 4
	w_class = 5.0
	attack_verb = list("smacked", "whacked", "slammed", "smashed")

/obj/item/weapon/melee/skateboard/attack_self(mob/user)
	new /obj/vehicle/scooter/skateboard(get_turf(user))
	qdel(src)

/obj/item/weapon/melee/baseball_bat
	name = "baseball bat"
	desc = "There ain't a skull in the league that can withstand a swatter."
	icon = 'icons/obj/items.dmi'
	icon_state = "baseball_bat"
	item_state = "baseball_bat"
	force = 10
	throwforce = 12
	attack_verb = list("beat", "smacked")
	w_class = 5
	var/homerun_ready = 0
	var/homerun_able = 0

/obj/item/weapon/melee/baseball_bat/homerun
	name = "home run bat"
	desc = "This thing looks dangerous... Dangerously good at baseball, that is."
	homerun_able = 1

/obj/item/weapon/melee/baseball_bat/attack_self(mob/user)
	if(!homerun_able)
		..()
		return
	if(homerun_ready)
		user << "<span class='notice'>You're already ready to do a home run!</span>"
		..()
		return
	user << "<span class='warning'>You begin gathering strength...</span>"
	playsound(get_turf(src), 'sound/magic/lightning_chargeup.ogg', 65, 1)
	if(do_after(user, 90, target = src))
		user << "<span class='userdanger'>You gather power! Time for a home run!</span>"
		homerun_ready = 1
	..()

/obj/item/weapon/melee/baseball_bat/attack(mob/living/target, mob/living/user)
	. = ..()
	var/atom/throw_target = get_edge_target_turf(target, user.dir)
	if(homerun_ready)
		user.visible_message("<span class='userdanger'>It's a home run!</span>")
		target.throw_at(throw_target, rand(8,10), 14, user)
		target.ex_act(2)
		playsound(get_turf(src), 'sound/weapons/HOMERUN.ogg', 100, 1)
		homerun_ready = 0
		return
	else
		target.throw_at(throw_target, rand(1,2), 7, user)

/obj/item/weapon/melee/baseball_bat/ablative
	name = "metal baseball bat"
	desc = "This bat is made of highly reflective, highly armored material."
	icon_state = "baseball_bat_metal"
	item_state = "baseball_bat_metal"
	force = 12
	throwforce = 15

/obj/item/weapon/melee/baseball_bat/ablative/IsReflect()//some day this will reflect thrown items instead of lasers
	var/picksound = rand(1,2)
	var/turf = get_turf(src)
	if(picksound == 1)
		playsound(turf, 'sound/weapons/effects/batreflect1.ogg', 50, 1)
	if(picksound == 2)
		playsound(turf, 'sound/weapons/effects/batreflect2.ogg', 50, 1)
	return 1

/obj/item/weapon/melee/flyswatter
	name = "Flyswatter"
	desc = "Useful for killing insects of all sizes."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "flyswatter"
	item_state = "flyswatter"
	force = 1
	throwforce = 1
	attack_verb = list("swatted", "smacked")
	hitsound = 'sound/effects/snap.ogg'
	w_class = 2
	//Things in this list will be instantly splatted.  Flyman weakness is handled in the flyman species weakness proc.
	var/list/strong_against

/obj/item/weapon/melee/flyswatter/New()
	strong_against = typecacheof(list(
					/mob/living/simple_animal/hostile/poison/bees/,
					/mob/living/simple_animal/butterfly,
					/mob/living/simple_animal/cockroach,
					/obj/item/queen_bee/
	))

/obj/item/weapon/melee/flyswatter/afterattack(atom/target, mob/user, proximity_flag)
	if(proximity_flag)
		if(is_type_in_typecache(target, strong_against))
			new /obj/effect/decal/cleanable/deadcockroach(get_turf(target))
			user << "<span class='warning'>You easily splat the [target].</span>"
			if(istype(target, /mob/living/))
				var/mob/living/bug = target
				bug.death(1)
			else
				qdel(target)
//Originally coded by ISaidNo, later modified by Kelenius. Ported from Baystation12.

/obj/structure/closet/crate/secure/loot
	name = "abandoned crate"
	desc = "What could be inside?"
	icon_state = "securecrate"
	var/code = null
	var/lastattempt = null
	var/attempts = 10
	var/codelen = 4

/obj/structure/closet/crate/secure/loot/New()
	..()
	var/list/digits = list("1", "2", "3", "4", "5", "6", "7", "8", "9", "z")
	code = ""
	for(var/i = 0, i < codelen, i++)
		var/dig = pick(digits)
		code += dig
		digits -= dig  //Player can enter codes with matching digits, but there are never matching digits in the answer

	var/loot = rand(1,100) //100 different crates with varying chances of spawning
	switch(loot)
		if(1 to 5) //5% chance
			new /obj/item/weapon/reagent_containers/food/drinks/bottle/rum(src)
			new /obj/item/weapon/reagent_containers/food/snacks/grown/ambrosia/deus(src)
			new /obj/item/weapon/reagent_containers/food/drinks/bottle/whiskey(src)
			new /obj/item/weapon/lighter(src)
		if(6 to 10)
			new /obj/item/weapon/bedsheet(src)
			new /obj/item/weapon/kitchen/knife(src)
			new /obj/item/weapon/wirecutters(src)
			new /obj/item/weapon/screwdriver(src)
			new /obj/item/weapon/weldingtool(src)
			new /obj/item/weapon/hatchet(src)
			new /obj/item/weapon/crowbar(src)
		if(11 to 15)
			new /obj/item/weapon/reagent_containers/glass/beaker/bluespace(src)
		if(16 to 20)
			for(var/i in 1 to 10)
				new /obj/item/weapon/ore/diamond(src)
		if(21 to 25)
			for(var/i in 1 to 5)
				new /obj/item/weapon/poster/contraband(src)
		if(26 to 30)
			for(var/i in 1 to 3)
				new /obj/item/weapon/reagent_containers/glass/beaker/noreact(src)
		if(31 to 35)
			new /obj/item/seeds/cash(src)
		if(36 to 40)
			new /obj/item/weapon/melee/baton(src)
		if(41 to 45)
			new /obj/item/clothing/under/shorts/red(src)
			new /obj/item/clothing/under/shorts/blue(src)
		if(46 to 50)
			new /obj/item/clothing/under/chameleon(src)
			for(var/i in 1 to 7)
				new /obj/item/clothing/tie/horrible(src)
		if(51 to 52) // 2% chance
			new /obj/item/weapon/melee/classic_baton(src)
		if(53 to 54)
			new /obj/item/toy/balloon(src)
		if(55 to 56)
			var/newitem = pick(subtypesof(/obj/item/toy/prize))
			new newitem(src)
		if(57 to 58)
			new /obj/item/toy/syndicateballoon(src)
		if(59 to 60)
			new /obj/item/weapon/gun/energy/kinetic_accelerator/hyper(src)
			new /obj/item/clothing/suit/space(src)
			new /obj/item/clothing/head/helmet/space(src)
		if(61 to 62)
			for(var/i in 1 to 5)
				new /obj/item/clothing/head/kitty(src)
				new /obj/item/clothing/tie/petcollar(src)
		if(63 to 64)
			for(var/i in 1 to rand(4, 7))
				var/newcoin = pick(/obj/item/weapon/coin/silver, /obj/item/weapon/coin/silver, /obj/item/weapon/coin/silver, /obj/item/weapon/coin/iron, /obj/item/weapon/coin/iron, /obj/item/weapon/coin/iron, /obj/item/weapon/coin/gold, /obj/item/weapon/coin/diamond, /obj/item/weapon/coin/plasma, /obj/item/weapon/coin/uranium)
				new newcoin(src)
		if(65 to 66)
			new /obj/item/clothing/suit/ianshirt(src)
			new /obj/item/clothing/suit/hooded/ian_costume(src)
		if(67 to 68)
			for(var/i in 1 to rand(4, 7))
				var /newitem = pick(subtypesof(/obj/item/weapon/stock_parts) - /obj/item/weapon/stock_parts/subspace)
				new newitem(src)
		if(69 to 70)
			for(var/i in 1 to 5)
				new /obj/item/weapon/ore/bluespace_crystal(src)
		if(71 to 72)
			new /obj/item/weapon/pickaxe/drill(src)
		if(73 to 74)
			new /obj/item/weapon/pickaxe/drill/jackhammer(src)
		if(75 to 76)
			new /obj/item/weapon/pickaxe/diamond(src)
		if(77 to 78)
			new /obj/item/weapon/pickaxe/drill/diamonddrill(src)
		if(79 to 80)
			new /obj/item/weapon/cane(src)
			new /obj/item/clothing/head/collectable/tophat(src)
		if(81 to 82)
			new /obj/item/weapon/gun/energy/plasmacutter(src)
		if(83 to 84)
			new /obj/item/toy/katana(src)
		if(85 to 86)
			new /obj/item/weapon/defibrillator/compact(src)
		if(87) //1% chance
			new /obj/item/weed_extract(src)
		if(88)
			new /obj/item/organ/internal/brain(src)
		if(89)
			new /obj/item/organ/internal/brain/alien(src)
		if(90)
			new /obj/item/organ/internal/heart(src)
		if(91)
			new /obj/item/device/soulstone/anybody(src)
		if(92)
			new /obj/item/weapon/katana(src)
		if(93)
			new /obj/item/weapon/dnainjector/xraymut(src)
		if(94)
			new /obj/item/weapon/storage/backpack/clown(src)
			new /obj/item/clothing/under/rank/clown(src)
			new /obj/item/clothing/shoes/clown_shoes(src)
			new /obj/item/device/pda/clown(src)
			new /obj/item/clothing/mask/gas/clown_hat(src)
			new /obj/item/weapon/bikehorn(src)
			new /obj/item/toy/crayon/rainbow(src)
			new /obj/item/weapon/reagent_containers/spray/waterflower(src)
		if(95)
			new /obj/item/clothing/under/rank/mime(src)
			new /obj/item/clothing/shoes/sneakers/black(src)
			new /obj/item/device/pda/mime(src)
			new /obj/item/clothing/gloves/color/white(src)
			new /obj/item/clothing/mask/gas/mime(src)
			new /obj/item/clothing/head/beret(src)
			new /obj/item/clothing/suit/suspenders(src)
			new /obj/item/toy/crayon/mime(src)
			new /obj/item/weapon/reagent_containers/food/drinks/bottle/bottleofnothing(src)
		if(96)
			new /obj/item/weapon/hand_tele(src)
		if(97)
			new /obj/item/clothing/mask/balaclava
			new /obj/item/weapon/gun/projectile/automatic/pistol(src)
			new /obj/item/ammo_box/magazine/m10mm(src)
		if(98)
			new /obj/item/weapon/katana/cursed(src)
		if(99)
			new /obj/item/weapon/storage/belt/champion(src)
			new /obj/item/clothing/mask/luchador(src)
		if(100)
			new /obj/item/clothing/head/bearpelt(src)

/obj/structure/closet/crate/secure/loot/attack_hand(mob/user)
	if(locked)
		user << "<span class='notice'>The crate is locked with a Deca-code lock.</span>"
		var/input = input(usr, "Enter [codelen] digits.", "Deca-Code Lock", "") as text
		if(user.canUseTopic(src, 1))
			if (input == code)
				user << "<span class='notice'>The crate unlocks!</span>"
				locked = 0
				overlays.Cut()
				overlays += "securecrateg"
			else if (input == null || length(input) != codelen)
				user << "<span class='notice'>You leave the crate alone.</span>"
			else
				user << "<span class='warning'>A red light flashes.</span>"
				lastattempt = replacetext(input, 0, "z")
				attempts--
				if(attempts == 0)
					boom(user)
	else
		return ..()

/obj/structure/closet/crate/secure/loot/attack_animal(mob/user)
	boom(user)

/obj/structure/closet/crate/secure/loot/attackby(obj/item/weapon/W, mob/user)
	if(locked)
		if(istype(W, /obj/item/weapon/card/emag))
			boom(user)
		if(istype(W, /obj/item/device/multitool))
			user << "<span class='notice'>DECA-CODE LOCK REPORT:</span>"
			if(attempts == 1)
				user << "<span class='warning'>* Anti-Tamper Bomb will activate on next failed access attempt.</span>"
			else
				user << "<span class='notice'>* Anti-Tamper Bomb will activate after [src.attempts] failed access attempts.</span>"
			if(lastattempt != null)
				var/list/guess = list()
				var/bulls = 0
				var/cows = 0
				for(var/i = 1, i < codelen + 1, i++)
					var/a = copytext(lastattempt, i, i+1) //Stuff the code into the list
					guess += a
					guess[a] = i
				for(var/i in guess) //Go through list and count matches
					var/a = findtext(code, i)
					if(a == guess[i])
						++bulls
					else if(a)
						++cows
				user << "<span class='notice'>Last code attempt had [bulls] correct digits at correct positions and [cows] correct digits at incorrect positions.</span>"
		else ..()
	else ..()

/obj/structure/closet/crate/secure/loot/togglelock(mob/user)
	if(locked)
		boom(user)
	else
		..()

/obj/structure/closet/crate/secure/loot/proc/boom(mob/user)
	user << "<span class='danger'>The crate's anti-tamper system activates!</span>"
	for(var/atom/movable/AM in src)
		qdel(AM)
	var/turf/T = get_turf(src)
	explosion(T, -1, -1, 1, 1)
	qdel(src)

/obj/structure/closet/crate/necropolis
	name = "necropolis chest"
	desc = "It's watching you closely."
	icon_state = "necrocrate"

/obj/structure/closet/crate/necropolis/tendril
	desc = "It's watching you suspiciously."

/obj/structure/closet/crate/necropolis/tendril/New()
	..()
	var/loot = rand(1,25) //100 different crates with varying chances of spawning
	switch(loot)
		if(1)
			new /obj/item/weapon/bedsheet/cult(src)
		if(2)
			new /obj/item/clothing/suit/space/cult(src)
			new /obj/item/clothing/head/helmet/space/cult(src)
		if(3)
			new /obj/item/device/soulstone/anybody(src)
		if(4)
			new /obj/item/weapon/katana/cursed(src)
		if(5)
			new /obj/item/weapon/dnainjector/xraymut(src)
		if(6)
			new /obj/item/seeds/kudzu(src)
		if(7)
			new /obj/item/weapon/pickaxe/diamond(src)
		if(8)
			new /obj/item/clothing/head/culthood(src)
			new /obj/item/clothing/suit/cultrobes(src)
		if(9)
			new /obj/item/organ/internal/brain/alien(src)
		if(10)
			new /obj/item/organ/internal/heart/cursed(src)
		if(11)
			new /obj/item/weapon/reagent_containers/food/drinks/bottle/rum(src)
			new /obj/item/weapon/reagent_containers/food/snacks/grown/ambrosia/deus(src)
			new /obj/item/weapon/reagent_containers/food/drinks/bottle/whiskey(src)
			new /obj/item/weapon/lighter(src)
		if(12)
			new /obj/item/weapon/bedsheet/cult(src)
			new /obj/item/clothing/head/culthood(src)
			new /obj/item/clothing/suit/cultrobes(src)
		if(13)
			new /obj/item/weapon/sord(src)
		if(14)
			new /obj/item/weapon/nullrod/claymore/darkblade
		if(15)
			new /obj/item/weapon/nullrod/armblade(src)
		if(16)
			new /obj/item/weapon/guardiancreator(src)
		if(17)
			new /obj/item/stack/sheet/runed_metal/fifty(src)
		if(18)
			new /obj/item/weapon/kitchen/knife/ritual(src)
		if(19)
			new /obj/item/device/wisp_lantern(src)
		if(20)
			new /obj/item/weapon/reagent_containers/food/snacks/burger/spell(src)
		if(21)
			new /obj/item/weapon/gun/magic/wand(src)
		if(22)
			new /obj/item/voodoo(src)
		if(23)
			new /obj/item/weapon/grenade/clusterbuster/inferno(src)
		if(24)
			new /obj/item/weapon/reagent_containers/food/drinks/bottle/holywater/hell(src)
			new /obj/item/clothing/suit/space/hardsuit/ert/paranormal/inquisitor(src)
		if(25)
			new /obj/item/weapon/spellbook/oneuse/smoke(src)


//Spooky special loot

/obj/item/device/wisp_lantern
	name = "spooky lantern"
	desc = "This lantern gives off no light, but is home to a friendly wisp."
	icon = 'icons/obj/lighting.dmi'
	icon_state = "lantern-blue"
	var/obj/effect/wisp/wisp

/obj/item/device/wisp_lantern/attack_self(mob/user)
	if(!wisp)
		user << "The wisp has gone missing!"
		return
	if(wisp.loc == src)
		user << "You release the wisp. It begins to bob around your head."
		spawn()
			wisp.orbit(user, 20)
		user.sight |= SEE_MOBS
		icon_state = "lantern"
	else
		if(wisp.orbiting)
			var/atom/A = wisp.orbiting
			if(istype(A, /mob/living))
				var/mob/living/M = A
				M.sight &= ~SEE_MOBS
				M << "The wisp has returned to it's latern. Your vision returns to normal." //This works

			wisp.stop_orbit()
			wisp.loc = src
			user << "You return the wisp to the latern."
			icon_state = "lantern-blue"

/obj/item/device/wisp_lantern/New()
	..()
	var/obj/effect/wisp/W = new(src)
	wisp = W
	W.home = src

/obj/item/device/wisp_lantern/Destroy()
	if(wisp)
		if(wisp.loc == src)
			qdel(wisp)
		else
			wisp.home = null //stuck orbiting your head now
	..()


/obj/effect/wisp
	name = "friendly wisp"
	desc = "Happy to light your way."
	icon = 'icons/obj/lighting.dmi'
	icon_state = "orb"
	var/obj/item/device/wisp_lantern/home
	luminosity = 7
	FLY_LAYER - 0.3
/* Gifts and wrapping paper
 * Contains:
 *		Gifts
 *		Wrapping Paper
 */

////WRAPPED GIFTS////

/obj/item/weapon/gift
	name = "gift"
	desc = "A wrapped item."
	icon = 'icons/obj/items.dmi'
	icon_state = "gift3"
	item_state = "gift3"
	var/size = 3.0
	var/obj/item/gift = null
	w_class = 3.0

/obj/item/weapon/gift/small
	icon_state = "gift2"
	item_state = "gift2"
	w_class = 2.0

/obj/item/weapon/gift/large
	icon_state = "gift4"
	item_state = "gift4"
	w_class = 4.0

/obj/item/weapon/gift/attack_self(mob/user as mob)
	user.drop_item()
	if(gift)
		user.put_in_active_hand(gift)
		gift.add_fingerprint(user)
		user << "<span class='notice'>You unwrapped \a [gift]!</span>"
	else
		user << "<span class='notice'>The gift was empty!</span>"
	del(src)
	return

////WINTER GIFTS////

/obj/item/weapon/winter_gift
	name = "gift"
	desc = ""
	icon = 'icons/obj/items.dmi'
	icon_state = "gift3"
	item_state = "gift3"
	w_class = 4.0

/obj/item/weapon/winter_gift/New()
	..()
	pixel_x = rand(-10,10)
	pixel_y = rand(-10,10)

/obj/item/weapon/winter_gift/ex_act()
	qdel(src)
	return

/obj/item/weapon/winter_gift/regular
	desc = "What are you waiting for? Tear that paper apart!"
	icon_state = "gift_winter-1"
	item_state = "gift_winter-1"

/obj/item/weapon/winter_gift/food
	desc = "That one smells really good!"
	icon_state = "gift_winter-2"
	item_state = "gift_winter-2"

/obj/item/weapon/winter_gift/cloth
	desc = "That one feels warm to the touch!"
	icon_state = "gift_winter-3"
	item_state = "gift_winter-3"

/obj/item/weapon/winter_gift/special
	desc = "There is something eerie about that one...opening it might or might not be a good idea."
	icon_state = "gift_winter-4"
	item_state = "gift_winter-4"


/obj/item/weapon/winter_gift/attack_self(mob/M as mob)
	M << "<span class='notice'>The gift was empty!</span>"
	M.u_equip(src)
	qdel(src)
	return

/obj/item/weapon/winter_gift/regular/attack_self(mob/M as mob)
	var/gift_type = pick(
		/obj/item/weapon/sord,
		/obj/item/weapon/storage/wallet,
		/obj/item/device/camera,
		/obj/item/device/camera/sepia,
		/obj/item/weapon/storage/photo_album,
		/obj/item/weapon/storage/box/snappops,
		/obj/item/weapon/storage/fancy/crayons,
		/obj/item/weapon/storage/backpack/holding,
		/obj/item/weapon/storage/belt/champion,
		/obj/item/weapon/soap/deluxe,
		/obj/item/weapon/pickaxe/silver,
		/obj/item/weapon/pen/invisible,
		/obj/item/weapon/lipstick/random,
		/obj/item/weapon/grenade/smokebomb,
//		/obj/item/weapon/corncob,
		/obj/item/weapon/contraband/poster,
//		/obj/item/weapon/book/manual/barman_recipes,	//we're in December 2014 and those books are still empty
//		/obj/item/weapon/book/manual/chef_recipes,
		/obj/item/weapon/bikehorn,
		/obj/item/weapon/beach_ball,
//		/obj/item/weapon/beach_ball/holoball,
		/obj/item/weapon/banhammer,
		/obj/item/toy/balloon,
//		/obj/item/toy/blink,	//this one reaaally needs a revamp. there's a limit to how lame a toy can be.
		/obj/item/toy/crossbow,
		/obj/item/toy/gun,
		/obj/item/toy/katana,
		/obj/item/toy/prize/deathripley,
		/obj/item/toy/prize/durand,
		/obj/item/toy/prize/fireripley,
		/obj/item/toy/prize/gygax,
		/obj/item/toy/prize/honk,
		/obj/item/toy/prize/marauder,
		/obj/item/toy/prize/mauler,
		/obj/item/toy/prize/odysseus,
		/obj/item/toy/prize/phazon,
		/obj/item/toy/prize/ripley,
		/obj/item/toy/prize/seraph,
		/obj/item/toy/spinningtoy,
		/obj/item/toy/sword,
		/obj/item/clothing/mask/cigarette/blunt/deus,
		/obj/item/clothing/mask/cigarette/blunt/cruciatus,
		/obj/item/device/paicard,
		/obj/item/device/violin,
		/obj/item/weapon/storage/belt/utility/complete,
		/obj/item/clothing/tie/horrible,
		/obj/item/device/maracas,
		/obj/item/weapon/gun/energy/temperature,
		)

	var/obj/item/I = new gift_type(M)
	M.u_equip(src)
	M.put_in_hands(I)
	I.add_fingerprint(M)
	M << "<span class='notice'>You unwrapped \a [I]!</span>"
	qdel(src)
	return

/obj/item/weapon/winter_gift/food/attack_self(mob/M as mob)
	var/gift_type = pick(
		/obj/item/weapon/reagent_containers/food/snacks/sliceable/birthdaycake,
		/obj/item/weapon/reagent_containers/food/snacks/sliceable/buchedenoel,
		/obj/item/weapon/reagent_containers/food/snacks/sliceable/turkey,
		)

	var/obj/item/I = new gift_type(M)
	M.u_equip(src)
	M.put_in_hands(I)
	I.add_fingerprint(M)
	M << "<span class='notice'>You unwrapped \a [I]! Tasty!</span>"
	qdel(src)
	return

/obj/item/weapon/winter_gift/cloth/attack_self(mob/M as mob)
	var/gift_type = pick(
		/obj/item/clothing/gloves/black,
		/obj/item/clothing/head/ushanka,
		)

	var/obj/item/I = new gift_type(M)
	M.u_equip(src)
	M.put_in_hands(I)
	I.add_fingerprint(M)
	M << "<span class='notice'>You unwrapped \a [I]! Looks comfy!</span>"
	qdel(src)
	return

/obj/item/weapon/winter_gift/special/attack_self(mob/M as mob)
	var/gift_type = pick(
		/obj/item/device/fuse_bomb,
		/obj/item/weapon/card/emag,
		/obj/item/weapon/reagent_containers/food/snacks/grown/apple/poisoned,
		)

	var/obj/item/I = new gift_type(M)
	M.u_equip(src)
	M.put_in_hands(I)
	I.add_fingerprint(M)

	var/additional_info = ""
	if(istype(I,/obj/item/device/fuse_bomb))
		var/obj/item/device/fuse_bomb/B = I
		B.fuse_lit = 1
		B.update_icon()
		B.fuse_burn()
		additional_info = ", OH SHIT its fuse is lit!"

	var/log_str = "[M.name]([M.ckey]) openned <A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[I.x];Y=[I.y];Z=[I.z]'>a black gift</a> and found [I.name] inside[additional_info]."

	if(M)
		log_str += "(<A HREF='?_src_=holder;adminmoreinfo=\ref[M]'>?</A>)"

	message_admins(log_str, 0, 1)
	log_game(log_str)

	M << "<span class='notice'>You unwrapped \a [I][additional_info]!</span>"

	qdel(src)
	return

////STRANGE PRESENTS(wrapped people)////

/obj/effect/spresent
	name = "strange present"
	desc = "It's a ... present?"
	icon = 'icons/obj/items.dmi'
	icon_state = "strangepresent"
	density = 1
	anchored = 0
	w_type=NOT_RECYCLABLE

/obj/effect/spresent/relaymove(mob/user as mob)
	if (user.stat)
		return
	user << "<span class='notice'>You can't move.</span>"

/obj/effect/spresent/attackby(obj/item/weapon/W as obj, mob/user as mob)
	..()

	if (!istype(W, /obj/item/weapon/wirecutters))
		user << "<span class='notice'>I need wirecutters for that.</span>"
		return

	user << "<span class='notice'>You cut open the present.</span>"

	for(var/mob/M in src) //Should only be one but whatever.
		M.loc = src.loc
		if (M.client)
			M.client.eye = M.client.mob
			M.client.perspective = MOB_PERSPECTIVE

	del(src)

/*
 * Wrapping Paper
 */
/obj/item/weapon/wrapping_paper
	name = "wrapping paper"
	desc = "You can use this to wrap items in."
	icon = 'icons/obj/items.dmi'
	icon_state = "wrap_paper"
	var/amount = 20.0


//old way to wrap an item.
///obj/item/weapon/wrapping_paper/attackby(obj/item/weapon/W as obj, mob/user as mob)
//	if(isMoMMI(user))
//		user << "<span class='warning'>You need two hands for this.</span>"
//		return
//	..()
//	if (!( locate(/obj/structure/table, src.loc) ))
//		user << "<span class='notice'>You MUST put the paper on a table!</span>"
//	if (W.w_class < 4)
//		if (istype(user.get_inactive_hand(), /obj/item/weapon/wirecutters))
//			var/obj/item/weapon/wirecutters/C = user.get_inactive_hand()
//			if(W==C)
//				return
//			var/a_used = 2 ** (src.w_class - 1)
//			if (src.amount < a_used)
//				user << "<span class='notice'>You need more paper!</span>"
//				return
//			else
//				if(istype(W, /obj/item/smallDelivery) || istype(W, /obj/item/weapon/gift)) //No gift wrapping gifts!
//					return
//
//				src.amount -= a_used
//				user.drop_item()
//				var/obj/item/weapon/gift/G = new /obj/item/weapon/gift( src.loc )
//				G.size = W.w_class
//				G.w_class = G.size + 1
//				G.icon_state = text("gift[]", G.size)
//				G.gift = W
//				W.loc = G
//				G.add_fingerprint(user)
//				W.add_fingerprint(user)
//				src.add_fingerprint(user)
//			if (src.amount <= 0)
//				new /obj/item/weapon/c_tube( src.loc )
//				del(src)
//				return
//		else
//			user << "<span class='notice'>You need wirecutters in your other hand!</span>"
//	else
//		user << "<span class='notice'>The object is FAR too large!</span>"
//	return


/obj/item/weapon/wrapping_paper/examine()
	set src in oview(1)

	..()
	usr << "There is about [amount] square units of paper left!"
	return

/obj/item/weapon/wrapping_paper/attack(mob/target as mob, mob/user as mob)
	if (!istype(target, /mob/living/carbon/human)) return
	var/mob/living/carbon/human/H = target

	if (istype(H.wear_suit, /obj/item/clothing/suit/straight_jacket) || H.stat)
		if (src.amount > 2)
			var/obj/effect/spresent/present = new /obj/effect/spresent (H.loc)
			src.amount -= 2

			if (H.client)
				H.client.perspective = EYE_PERSPECTIVE
				H.client.eye = present

			H.loc = present
			H.attack_log += text("\[[time_stamp()]\] <font color='orange'>Has been wrapped with [src.name]  by [user.name] ([user.ckey])</font>")
			user.attack_log += text("\[[time_stamp()]\] <font color='red'>Used the [src.name] to wrap [H.name] ([H.ckey])</font>")
			if(!iscarbon(user))
				H.LAssailant = null
			else
				H.LAssailant = user

			log_attack("<font color='red'>[user.name] ([user.ckey]) used the [src.name] to wrap [H.name] ([H.ckey])</font>")

		else
			user << "<span class='notice'>You need more paper.</span>"
	else
		user << "They are moving around too much. A straightjacket would help."

	if (src.amount <= 0)
		new /obj/item/weapon/c_tube( src.loc )
		del(src)
	return

/obj/item/weapon/wrapping_paper/afterattack(var/obj/target as obj, mob/user as mob)
	if(!istype(target))	//this really shouldn't be necessary (but it is).	-Pete
		return
	if(istype(target, /obj/structure/table) || istype(target, /obj/structure/rack) \
	|| istype(target, /obj/item/smallDelivery) || istype(target,/obj/structure/bigDelivery) \
	|| istype(target, /obj/item/weapon/gift) || istype(target, /obj/item/weapon/winter_gift) || istype(target, /obj/item/weapon/evidencebag))
		return
	if(target.anchored)
		return
	if(target in user)
		return

	user.attack_log += text("\[[time_stamp()]\] <font color='blue'>Has used [src.name] on \ref[target]</font>")

	if (istype(target, /obj/item))
		var/obj/item/O = target
		if (src.amount > 1)
			var/obj/item/weapon/gift/G = new /obj/item/weapon/gift(get_turf(O.loc))	//Aaannd wrap it up!
			if(!istype(O.loc, /turf))
				if(user.client)
					user.client.screen -= O
			G.gift = O
			O.loc = G
			var/i = round(O.w_class)
			if(i in list(1,2,3,4,5))
				G.icon_state = "gift[i]"
			G.add_fingerprint(usr)
			O.add_fingerprint(usr)
			src.add_fingerprint(usr)
			src.amount -= 1
	else
		user << "<span class='notice'>You can't wrap that up!</span>"

	if (src.amount <= 0)
		new /obj/item/weapon/c_tube( src.loc )
		del(src)
		return
	return


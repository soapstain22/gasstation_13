///List of all things that can be dispensed by an arcade cabinet and the weight of them being picked.
GLOBAL_LIST_INIT(arcade_prize_pool, list(
	/obj/item/storage/box/snappops = 2,
	/obj/item/toy/talking/ai = 2,
	/obj/item/toy/talking/codex_gigas = 2,
	/obj/item/clothing/under/syndicate/tacticool = 2,
	/obj/item/toy/sword = 2,
	/obj/item/toy/gun = 2,
	/obj/item/gun/ballistic/shotgun/toy/crossbow = 2,
	/obj/item/storage/box/fakesyndiesuit = 2,
	/obj/item/storage/crayons = 2,
	/obj/item/toy/spinningtoy = 2,
	/obj/item/toy/spinningtoy/dark_matter = 1,
	/obj/item/toy/balloon/arrest = 2,
	/obj/item/toy/mecha/ripley = 1,
	/obj/item/toy/mecha/ripleymkii = 1,
	/obj/item/toy/mecha/hauler = 1,
	/obj/item/toy/mecha/clarke = 1,
	/obj/item/toy/mecha/odysseus = 1,
	/obj/item/toy/mecha/gygax = 1,
	/obj/item/toy/mecha/durand = 1,
	/obj/item/toy/mecha/savannahivanov = 1,
	/obj/item/toy/mecha/phazon = 1,
	/obj/item/toy/mecha/honk = 1,
	/obj/item/toy/mecha/darkgygax = 1,
	/obj/item/toy/mecha/mauler = 1,
	/obj/item/toy/mecha/darkhonk = 1,
	/obj/item/toy/mecha/deathripley = 1,
	/obj/item/toy/mecha/reticence = 1,
	/obj/item/toy/mecha/marauder = 1,
	/obj/item/toy/mecha/seraph = 1,
	/obj/item/toy/mecha/firefighter = 1,
	/obj/item/toy/cards/deck = 2,
	/obj/item/toy/nuke = 2,
	/obj/item/toy/minimeteor = 2,
	/obj/item/toy/redbutton = 2,
	/obj/item/toy/talking/owl = 2,
	/obj/item/toy/talking/griffin = 2,
	/obj/item/coin/antagtoken = 2,
	/obj/item/stack/tile/fakepit/loaded = 2,
	/obj/item/stack/tile/eighties/loaded = 2,
	/obj/item/toy/toy_xeno = 2,
	/obj/item/storage/box/actionfigure = 1,
	/obj/item/restraints/handcuffs/fake = 2,
	/obj/item/grenade/chem_grenade/glitter/pink = 1,
	/obj/item/grenade/chem_grenade/glitter/blue = 1,
	/obj/item/grenade/chem_grenade/glitter/white = 1,
	/obj/item/toy/eightball = 2,
	/obj/item/toy/windup_toolbox = 2,
	/obj/item/toy/clockwork_watch = 2,
	/obj/item/toy/toy_dagger = 2,
	/obj/item/extendohand/acme = 1,
	/obj/item/hot_potato/harmless/toy = 1,
	/obj/item/card/emagfake = 1,
	/obj/item/clothing/shoes/wheelys = 2,
	/obj/item/clothing/shoes/kindle_kicks = 2,
	/obj/item/toy/plush/goatplushie = 2,
	/obj/item/toy/plush/moth = 2,
	/obj/item/toy/plush/pkplush = 2,
	/obj/item/toy/plush/rouny = 2,
	/obj/item/toy/plush/abductor = 2,
	/obj/item/toy/plush/abductor/agent = 2,
	/obj/item/toy/plush/shark = 2,
	/obj/item/storage/belt/military/snack/full = 2,
	/obj/item/toy/brokenradio = 2,
	/obj/item/toy/braintoy = 2,
	/obj/item/toy/eldritch_book = 2,
	/obj/item/storage/box/heretic_box = 1,
	/obj/item/toy/foamfinger = 2,
	/obj/item/clothing/glasses/trickblindfold = 2,
	/obj/item/clothing/mask/party_horn = 2,
	/obj/item/storage/box/party_poppers = 2,
))

///assoc list, ([datum singleton] = weight), of events that can run during orion trail.
GLOBAL_LIST_INIT(orion_events, generate_orion_events())

/proc/generate_orion_events()
	var/list/events = list()
	for(var/path in subtypesof(/datum/orion_event))
		var/datum/orion_event/new_event = new path(src)
		events[new_event] = new_event.weight
	return events

///asoc list ([gear name] = gear datum) of all equipment that can be bought in battle arcade.
GLOBAL_LIST_INIT(battle_arcade_gear_list, generate_battle_arcade_gear_list())

/proc/generate_battle_arcade_gear_list()
	var/list/gear = list()
	for(var/datum/battle_arcade_gear/template as anything in subtypesof(/datum/battle_arcade_gear))
		gear[template::name] = new template
	return gear

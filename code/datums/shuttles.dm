#define EMAG_LOCKED_SHUTTLE_COST (CARGO_CRATE_VALUE * 50)

/datum/map_template/shuttle
	name = "Base Shuttle Template"
	var/prefix = "_maps/shuttles/"
	var/suffix
	/**
	 * Port ID is the place this template should be docking at, set on '/obj/docking_port/stationary'
	 * Because getShuttle() compares port_id to shuttle_id to find an already existing shuttle,
	 * you should set shuttle_id to be the same as port_id if you want them to be replacable.
	 */
	var/port_id
	///ID of the shuttle, make sure it matches port_id if necessary.
	var/shuttle_id

	var/description
	var/prerequisites
	var/admin_notes
	/// How much does this shuttle cost the cargo budget to purchase? Put in terms of CARGO_CRATE_VALUE to properly scale the cost with the current balance of cargo's income.
	var/credit_cost = INFINITY
	/// What job accesses can buy this shuttle? If null, this shuttle cannot be bought.
	var/list/who_can_purchase = list(ACCESS_CAPTAIN)
	/// Whether or not this shuttle is locked to emags only.
	var/emag_only = FALSE
	/// If set, overrides default movement_force on shuttle
	var/list/movement_force

	var/port_x_offset
	var/port_y_offset
	var/extra_desc = ""

/datum/map_template/shuttle/proc/prerequisites_met()
	return TRUE

/datum/map_template/shuttle/New()
	shuttle_id = "[port_id]_[suffix]"
	mappath = "[prefix][shuttle_id].dmm"
	. = ..()

/datum/map_template/shuttle/preload_size(path, cache)
	. = ..(path, TRUE) // Done this way because we still want to know if someone actualy wanted to cache the map
	if(!cached_map)
		return

	var/offset = discover_offset(/obj/docking_port/mobile)

	port_x_offset = offset[1]
	port_y_offset = offset[2]

	if(!cache)
		cached_map = null

/datum/map_template/shuttle/load(turf/T, centered, register=TRUE)
	. = ..()
	if(!.)
		return
	var/list/turfs = block( locate(.[MAP_MINX], .[MAP_MINY], .[MAP_MINZ]),
							locate(.[MAP_MAXX], .[MAP_MAXY], .[MAP_MAXZ]))
	for(var/i in 1 to turfs.len)
		var/turf/place = turfs[i]
		if(isspaceturf(place)) // This assumes all shuttles are loaded in a single spot then moved to their real destination.
			continue

		if (place.count_baseturfs() < 2) // Some snowflake shuttle shit
			continue

		place.insert_baseturf(3, /turf/baseturf_skipover/shuttle)

		for(var/obj/docking_port/mobile/port in place)
			port.calculate_docking_port_information(src)
			// initTemplateBounds explicitly ignores the shuttle's docking port, to ensure that it calculates the bounds of the shuttle correctly
			// so we need to manually initialize it here
			SSatoms.InitializeAtoms(list(port))
			if(register)
				port.register()

//Whatever special stuff you want
/datum/map_template/shuttle/post_load(obj/docking_port/mobile/M)
	if(movement_force)
		M.movement_force = movement_force.Copy()
	M.linkup()

/datum/map_template/shuttle/emergency
	port_id = "emergency"
	name = "Base Shuttle Template (Emergency)"

/datum/map_template/shuttle/cargo
	port_id = "cargo"
	name = "Base Shuttle Template (Cargo)"
	who_can_purchase = null

/datum/map_template/shuttle/ferry
	port_id = "ferry"
	name = "Base Shuttle Template (Ferry)"

/datum/map_template/shuttle/whiteship
	port_id = "whiteship"

/datum/map_template/shuttle/labour
	port_id = "labour"
	who_can_purchase = null

/datum/map_template/shuttle/mining
	port_id = "mining"
	who_can_purchase = null

/datum/map_template/shuttle/mining_common
	port_id = "mining_common"
	who_can_purchase = null

/datum/map_template/shuttle/arrival
	port_id = "arrival"
	who_can_purchase = null

/datum/map_template/shuttle/infiltrator
	port_id = "infiltrator"
	who_can_purchase = null

/datum/map_template/shuttle/aux_base
	port_id = "aux_base"
	who_can_purchase = null

/datum/map_template/shuttle/escape_pod
	port_id = "escape_pod"
	who_can_purchase = null

/datum/map_template/shuttle/assault_pod
	port_id = "assault_pod"
	who_can_purchase = null

/datum/map_template/shuttle/pirate
	port_id = "pirate"
	who_can_purchase = null

/datum/map_template/shuttle/hunter
	port_id = "hunter"
	who_can_purchase = null

/datum/map_template/shuttle/ruin //For random shuttles in ruins
	port_id = "ruin"
	who_can_purchase = null

/datum/map_template/shuttle/snowdin
	port_id = "snowdin"
	who_can_purchase = null

/datum/map_template/shuttle/ert
	port_id = "ert"
	who_can_purchase = null

// Shuttles start here:

/datum/map_template/shuttle/emergency/backup
	suffix = "backup"
	name = "Backup Shuttle"
	who_can_purchase = null

/datum/map_template/shuttle/emergency/construction
	suffix = "construction"
	name = "Build your own shuttle kit"
	description = "For the enterprising shuttle engineer! The chassis will dock upon purchase, but launch will have to be authorized as usual via shuttle call. Comes stocked with construction materials. Unlocks the ability to buy shuttle engine crates from cargo, which allow you to speed up shuttle transit time."
	admin_notes = "No brig, no medical facilities."
	credit_cost = CARGO_CRATE_VALUE * 5
	who_can_purchase = list(ACCESS_CAPTAIN, ACCESS_CE)

/datum/map_template/shuttle/emergency/construction/post_load()
	. = ..()
	//enable buying engines from cargo
	var/datum/supply_pack/P = SSshuttle.supply_packs[/datum/supply_pack/engineering/shuttle_engine]
	P.special_enabled = TRUE


/datum/map_template/shuttle/emergency/asteroid
	suffix = "asteroid"
	name = "Asteroid Station Emergency Shuttle"
	description = "A respectable mid-sized shuttle that first saw service shuttling Nanotrasen crew to and from their asteroid belt embedded facilities."
	credit_cost = CARGO_CRATE_VALUE * 6

/datum/map_template/shuttle/emergency/venture
	suffix = "venture"
	name = "Venture Emergency Shuttle"
	description = "A mid-sized shuttle for those who like a lot of space for their legs."
	credit_cost = CARGO_CRATE_VALUE * 10

/datum/map_template/shuttle/emergency/bar
	suffix = "bar"
	name = "The Emergency Escape Bar"
	description = "Features include sentient bar staff (a Bardrone and a Barmaid), bathroom, a quality lounge for the heads, and a large gathering table."
	admin_notes = "Bardrone and Barmaid are GODMODE, will be automatically sentienced by the fun balloon at 60 seconds before arrival. \
	Has medical facilities."
	credit_cost = CARGO_CRATE_VALUE * 10

/datum/map_template/shuttle/emergency/pod
	suffix = "pod"
	name = "Emergency Pods"
	description = "We did not expect an evacuation this quickly. All we have available is two escape pods."
	admin_notes = "For player punishment."
	who_can_purchase = null

/datum/map_template/shuttle/emergency/russiafightpit
	suffix = "russiafightpit"
	name = "Mother Russia Bleeds"
	description = "Dis is a high-quality shuttle, da. Many seats, lots of space, all equipment! Even includes entertainment! Such as lots to drink, and a fighting arena for drunk crew to have fun! If arena not fun enough, simply press button of releasing bears. Do not worry, bears trained not to break out of fighting pit, so totally safe so long as nobody stupid or drunk enough to leave door open. Try not to let asimov babycons ruin fun!"
	admin_notes = "Includes a small variety of weapons. And bears. Only captain-access can release the bears. Bears won't smash the windows themselves, but they can escape if someone lets them."
	credit_cost = CARGO_CRATE_VALUE * 10 // While the shuttle is rusted and poorly maintained, trained bears are costly.

/datum/map_template/shuttle/emergency/meteor
	suffix = "meteor"
	name = "Asteroid With Engines Strapped To It"
	description = "A hollowed out asteroid with engines strapped to it, the hollowing procedure makes it very difficult to hijack but is very expensive. Due to its size and difficulty in steering it, this shuttle may damage the docking area."
	admin_notes = "This shuttle will likely crush escape, killing anyone there."
	credit_cost = CARGO_CRATE_VALUE * 30
	movement_force = list("KNOCKDOWN" = 3, "THROW" = 2)

/datum/map_template/shuttle/emergency/monastery
	suffix = "monastery"
	name = "Grand Corporate Monastery"
	description = "Originally built for a public station, this grand edifice to religion, due to budget cuts, is now available as an escape shuttle for the right... donation. Due to its large size and callous owners, this shuttle may cause collateral damage."
	admin_notes = "WARNING: This shuttle WILL destroy a fourth of the station, likely picking up a lot of objects with it."
	emag_only = TRUE
	credit_cost = EMAG_LOCKED_SHUTTLE_COST * 1.8
	movement_force = list("KNOCKDOWN" = 3, "THROW" = 5)

/datum/map_template/shuttle/emergency/luxury
	suffix = "luxury"
	name = "Luxury Shuttle"
	description = "A luxurious golden shuttle complete with an indoor swimming pool. Each crewmember wishing to board must bring 500 credits, payable in cash and mineral coin."
	extra_desc = "This shuttle costs 500 credits to board."
	admin_notes = "Due to the limited space for non paying crew, this shuttle may cause a riot."
	emag_only = TRUE
	credit_cost = EMAG_LOCKED_SHUTTLE_COST

/datum/map_template/shuttle/emergency/medisim
	suffix = "medisim"
	name = "Medieval Reality Simulation Dome"
	description = "A state of the art simulation dome, loaded onto your shuttle! Watch and laugh at how petty humanity used to be before it reached the stars. Guaranteed to be at least 40% historically accurate."
	admin_notes = "Ghosts can spawn in and fight as knights or archers. The CTF auto restarts, so no admin intervention necessary."
	credit_cost = 20000

/datum/map_template/shuttle/emergency/medisim/prerequisites_met()
	return SSshuttle.shuttle_purchase_requirements_met[SHUTTLE_UNLOCK_MEDISIM]

/datum/map_template/shuttle/emergency/discoinferno
	suffix = "discoinferno"
	name = "Disco Inferno"
	description = "The glorious results of centuries of plasma research done by Nanotrasen employees. This is the reason why you are here. Get on and dance like you're on fire, burn baby burn!"
	admin_notes = "Flaming hot. The main area has a dance machine as well as plasma floor tiles that will be ignited by players every single time."
	emag_only = TRUE
	credit_cost = EMAG_LOCKED_SHUTTLE_COST

/datum/map_template/shuttle/emergency/arena
	suffix = "arena"
	name = "The Arena"
	description = "The crew must pass through an otherworldy arena to board this shuttle. Expect massive casualties. The source of the Bloody Signal must be tracked down and eliminated to unlock this shuttle."
	admin_notes = "RIP AND TEAR."
	credit_cost = CARGO_CRATE_VALUE * 20
	/// Whether the arena z-level has been created
	var/arena_loaded = FALSE

/datum/map_template/shuttle/emergency/arena/prerequisites_met()
	return SSshuttle.shuttle_purchase_requirements_met[SHUTTLE_UNLOCK_BUBBLEGUM]

/datum/map_template/shuttle/emergency/arena/post_load(obj/docking_port/mobile/M)
	. = ..()
	if(!arena_loaded)
		arena_loaded = TRUE
		var/datum/map_template/arena/arena_template = new()
		arena_template.load_new_z()

/datum/map_template/arena
	name = "The Arena"
	mappath = "_maps/templates/the_arena.dmm"

/datum/map_template/shuttle/emergency/birdboat
	suffix = "birdboat"
	name = "Birdboat Station Emergency Shuttle"
	description = "Though a little on the small side, this shuttle is feature complete, which is more than can be said for the pattern of station it was commissioned for."
	credit_cost = CARGO_CRATE_VALUE * 2

/datum/map_template/shuttle/emergency/box
	suffix = "box"
	name = "Box Station Emergency Shuttle"
	credit_cost = CARGO_CRATE_VALUE * 4
	description = "The gold standard in emergency exfiltration, this tried and true design is equipped with everything the crew needs for a safe flight home."

/datum/map_template/shuttle/emergency/donut
	suffix = "donut"
	name = "Donutstation Emergency Shuttle"
	description = "The perfect spearhead for any crude joke involving the station's shape, this shuttle supports a separate containment cell for prisoners and a compact medical wing."
	admin_notes = "Has airlocks on both sides of the shuttle and will probably intersect near the front on some stations that build past departures."
	credit_cost = CARGO_CRATE_VALUE * 5

/datum/map_template/shuttle/emergency/clown
	suffix = "clown"
	name = "Snappop(tm)!"
	description = "Hey kids and grownups! \
	Are you bored of DULL and TEDIOUS shuttle journeys after you're evacuating for probably BORING reasons. Well then order the Snappop(tm) today! \
	We've got fun activities for everyone, an all access cockpit, and no boring security brig! Boo! Play dress up with your friends! \
	Collect all the bedsheets before your neighbour does! Check if the AI is watching you with our patent pending \"Peeping Tom AI Multitool Detector\" or PEEEEEETUR for short. \
	Have a fun ride!"
	admin_notes = "Brig is replaced by anchored greentext book surrounded by lavaland chasms, stationside door has been removed to prevent accidental dropping. No brig."
	credit_cost = CARGO_CRATE_VALUE * 16

/datum/map_template/shuttle/emergency/cramped
	suffix = "cramped"
	name = "Secure Transport Vessel 5 (STV5)"
	description = "Well, looks like CentCom only had this ship in the area, they probably weren't expecting you to need evac for a while. \
	Probably best if you don't rifle around in whatever equipment they were transporting. I hope you're friendly with your coworkers, because there is very little space in this thing.\n\
	\n\
	Contains contraband armory guns, maintenance loot, and abandoned crates!"
	admin_notes = "Due to origin as a solo piloted secure vessel, has an active GPS onboard labeled STV5. Has roughly as much space as Hi Daniel, except with explosive crates."

/datum/map_template/shuttle/emergency/meta
	suffix = "meta"
	name = "Meta Station Emergency Shuttle"
	credit_cost = CARGO_CRATE_VALUE * 8
	description = "A fairly standard shuttle, though larger and slightly better equipped than the Box Station variant."

/datum/map_template/shuttle/emergency/kilo
	suffix = "kilo"
	name = "Kilo Station Emergency Shuttle"
	credit_cost = CARGO_CRATE_VALUE * 10
	description = "A fully functional shuttle including a complete infirmary, storage facilties and regular amenities."

/datum/map_template/shuttle/emergency/mini
	suffix = "mini"
	name = "Ministation emergency shuttle"
	credit_cost = CARGO_CRATE_VALUE * 2
	description = "Despite its namesake, this shuttle is actually only slightly smaller than standard, and still complete with a brig and medbay."

/datum/map_template/shuttle/emergency/tram
	suffix = "tram"
	name = "Tram Station Emergency Shuttle"
	credit_cost = CARGO_CRATE_VALUE * 4
	description = "A train but in space, choo choo!"

/datum/map_template/shuttle/emergency/scrapheap
	suffix = "scrapheap"
	name = "Standby Evacuation Vessel \"Scrapheap Challenge\""
	credit_cost = CARGO_CRATE_VALUE * -2
	description = "Due to a lack of functional emergency shuttles, we bought this second hand from a scrapyard and pressed it into service. Please do not lean too heavily on the exterior windows, they are fragile."
	admin_notes = "An abomination with no functional medbay, sections missing, and some very fragile windows. Surprisingly airtight."
	movement_force = list("KNOCKDOWN" = 3, "THROW" = 2)

/datum/map_template/shuttle/emergency/narnar
	suffix = "narnar"
	name = "Shuttle 667"
	description = "Looks like this shuttle may have wandered into the darkness between the stars on route to the station. Let's not think too hard about where all the bodies came from."
	admin_notes = "Contains real cult ruins, mob eyeballs, and inactive constructs. Cult mobs will automatically be sentienced by fun balloon. \
	Cloning pods in 'medbay' area are showcases and nonfunctional."
	credit_cost = 6667 ///The joke is the number so no defines

/datum/map_template/shuttle/emergency/narnar/prerequisites_met()
	return SSshuttle.shuttle_purchase_requirements_met[SHUTTLE_UNLOCK_NARNAR]

/datum/map_template/shuttle/emergency/pubby
	suffix = "pubby"
	name = "Pubby Station Emergency Shuttle"
	description = "A train but in space! Complete with a first, second class, brig and storage area."
	admin_notes = "Choo choo motherfucker!"
	credit_cost = CARGO_CRATE_VALUE * 2

/datum/map_template/shuttle/emergency/cere
	suffix = "cere"
	name = "Cere Station Emergency Shuttle"
	description = "The large, beefed-up version of the box-standard shuttle. Includes an expanded brig, fully stocked medbay, enhanced cargo storage with mech chargers, \
	an engine room stocked with various supplies, and a crew capacity of 80+ to top it all off. Live large, live Cere."
	admin_notes = "Seriously big, even larger than the Delta shuttle."
	credit_cost = CARGO_CRATE_VALUE * 20

/datum/map_template/shuttle/emergency/supermatter
	suffix = "supermatter"
	name = "Hyperfractal Gigashuttle"
	description = "\"I dunno, this seems kinda needlessly complicated.\"\n\
	\"This shuttle has very a very high safety record, according to CentCom Officer Cadet Yins.\"\n\
	\"Are you sure?\"\n\
	\"Yes, it has a safety record of N-A-N, which is apparently larger than 100%.\""
	admin_notes = "Supermatter that spawns on shuttle is special anchored 'hugbox' supermatter that cannot take damage and does not take in or emit gas. \
	Outside of admin intervention, it cannot explode. \
	It does, however, still dust anything on contact, emits high levels of radiation, and induce hallucinations in anyone looking at it without protective goggles. \
	Emitters spawn powered on, expect admin notices, they are harmless."
	emag_only = TRUE
	credit_cost = EMAG_LOCKED_SHUTTLE_COST
	movement_force = list("KNOCKDOWN" = 3, "THROW" = 2)

/datum/map_template/shuttle/emergency/imfedupwiththisworld
	suffix = "imfedupwiththisworld"
	name = "Oh, Hi Daniel"
	description = "How was space work today? Oh, pretty good. We got a new space station and the company will make a lot of money. What space station? I cannot tell you; it's space confidential. \
	Aw, come space on. Why not? No, I can't. Anyway, how is your space roleplay life?"
	admin_notes = "Tiny, with a single airlock and wooden walls. What could go wrong?"
	emag_only = TRUE
	credit_cost = EMAG_LOCKED_SHUTTLE_COST
	movement_force = list("KNOCKDOWN" = 3, "THROW" = 2)

/datum/map_template/shuttle/emergency/goon
	suffix = "goon"
	name = "NES Port"
	description = "The Nanotrasen Emergency Shuttle Port(NES Port for short) is a shuttle used at other less known Nanotrasen facilities and has a more open inside for larger crowds, but fewer onboard shuttle facilities."
	credit_cost = CARGO_CRATE_VALUE

/datum/map_template/shuttle/emergency/rollerdome
	suffix = "rollerdome"
	name = "Uncle Pete's Rollerdome"
	description = "Developed by a member of Nanotrasen's R&D crew that claims to have travelled from the year 2028. \
	He says this shuttle is based off an old entertainment complex from the 1990s, though our database has no records on anything pertaining to that decade."
	admin_notes = "ONLY NINETIES KIDS REMEMBER. Uses the fun balloon and drone from the Emergency Bar."
	credit_cost = CARGO_CRATE_VALUE * 5

/datum/map_template/shuttle/emergency/basketball
	suffix = "bballhooper"
	name = "Basketballer's Stadium"
	description = "Hoop, man, hoop! Get your shooting game on with this sleek new basketball stadium! Do keep in mind that several other features \
	that you may expect to find common-place on other shuttles aren't present to give you this sleek stadium at an affordable cost. \
	It also wasn't manufactured to deal with the form-factor of some of your stations... good luck with that."
	admin_notes = "A larger shuttle built around a basketball stadium: entirely impractical but just a complete blast!"
	credit_cost = CARGO_CRATE_VALUE * 10

/datum/map_template/shuttle/emergency/wabbajack
	suffix = "wabbajack"
	name = "NT Lepton Violet"
	description = "The research team based on this vessel went missing one day, and no amount of investigation could discover what happened to them. \
	The only occupants were a number of dead rodents, who appeared to have clawed each other to death. \
	Needless to say, no engineering team wanted to go near the thing, and it's only being used as an Emergency Escape Shuttle because there is literally nothing else available."
	admin_notes = "If the crew can solve the puzzle, they will wake the wabbajack statue. It will likely not end well. There's a reason it's boarded up. Maybe they should have just left it alone."
	credit_cost = CARGO_CRATE_VALUE * 30

/datum/map_template/shuttle/emergency/omega
	suffix = "omega"
	name = "Omegastation Emergency Shuttle"
	description = "On the smaller size with a modern design, this shuttle is for the crew who like the cosier things, while still being able to stretch their legs."
	credit_cost = CARGO_CRATE_VALUE * 2

/datum/map_template/shuttle/emergency/cruise
	suffix = "cruise"
	name = "The NTSS Independence"
	description = "Ordinarily reserved for special functions and events, the Cruise Shuttle Independence can bring a summery cheer to your next station evacuation for a 'modest' fee!"
	admin_notes = "This motherfucker is BIG. You might need to force dock it."
	credit_cost = CARGO_CRATE_VALUE * 100

/datum/map_template/shuttle/emergency/monkey
	suffix = "nature"
	name = "Dynamic Environmental Interaction Shuttle"
	description = "A large shuttle with a center biodome that is flourishing with life. Frolick with the monkeys! (Extra monkeys are stored on the bridge.)"
	admin_notes = "Pretty freakin' large, almost as big as Raven or Cere. Excercise caution with it."
	credit_cost = CARGO_CRATE_VALUE * 16

/datum/map_template/shuttle/emergency/casino
	suffix = "casino"
	name = "Lucky Jackpot Casino Shuttle"
	description = "A luxurious casino packed to the brim with everything you need to start new gambling addicitions!"
	admin_notes = "The ship is a bit chunky, so watch where you park it."
	credit_cost = 7777

/datum/map_template/shuttle/emergency/shadow
	suffix = "shadow"
	name = "The NTSS Shadow"
	description = "Guaranteed to get you somewhere FAST. With a custom-built plasma engine, this bad boy will put more distance between you and certain danger than any other!"
	admin_notes = "The aft of the ship has a plasma tank that starts ignited. May get released by crew. The plasma windows next to the engine heaters will also erupt into flame, and also risk getting released by crew."
	credit_cost = CARGO_CRATE_VALUE * 50

/datum/map_template/shuttle/emergency/fish
	suffix = "fish"
	name = "Angler's Choice Emergency Shuttle"
	description = "Trades such amenities as 'storage space' and 'sufficient seating' for an artifical environment ideal for fishing, plus ample supplies (also for fishing)."
	admin_notes = "There's a chasm in it, it has railings but that won't stop determined players."
	credit_cost = CARGO_CRATE_VALUE * 10

/datum/map_template/shuttle/emergency/lance
	suffix = "lance"
	name = "The Lance Crew Evacuation System"
	description = "A brand new shuttle by Nanotrasen's finest in shuttle-engineering, it's designed to tactically slam into a destroyed station, dispatching threats and saving crew at the same time! Be careful to stay out of it's path."
	admin_notes = "WARNING: This shuttle is designed to crash into the station. It has turrets, similar to the raven."
	credit_cost = CARGO_CRATE_VALUE * 70

/datum/map_template/shuttle/emergency/tranquility
	suffix = "tranquility"
	name = "The Tranquility Relocation Shuttle"
	description = "A large shuttle, covered in flora and comfortable resting areas. The perfect way to end a peaceful shift"
	admin_notes = "it's pretty big, and comfy. Be careful when placing it down!"
	credit_cost = CARGO_CRATE_VALUE * 25

/datum/map_template/shuttle/emergency/hugcage
	suffix = "hugcage"
	name = "Hug Relaxation Shuttle"
	description = "A small cozy shuttle with plenty of beds for tired or sensitive spacemen, and a box for pillow-fights."
	admin_notes = "Has a sentience fun balloon for pets."
	credit_cost = CARGO_CRATE_VALUE * 16

/datum/map_template/shuttle/ferry/base
	suffix = "base"
	name = "transport ferry"
	description = "Standard issue Box/Metastation CentCom ferry."

/datum/map_template/shuttle/ferry/meat
	suffix = "meat"
	name = "\"meat\" ferry"
	description = "Ahoy! We got all kinds o' meat aft here. Meat from plant people, people who be dark, not in a racist way, just they're dark black. \
	Oh and lizard meat too,mighty popular that is. Definitely 100% fresh, just ask this guy here. *person on meatspike moans* See? \
	Definitely high quality meat, nothin' wrong with it, nothin' added, definitely no zombifyin' reagents!"
	admin_notes = "Meat currently contains no zombifying reagents, lizard on meatspike must be spawned in."

/datum/map_template/shuttle/ferry/lighthouse
	suffix = "lighthouse"
	name = "The Lighthouse(?)"
	description = "*static*... part of a much larger vessel, possibly military in origin. \
	The weapon markings aren't anything we've seen ...static... by almost never the same person twice, possible use of unknown storage ...static... \
	seeing ERT officers onboard, but no missions are on file for ...static...static...annoying jingle... only at The LIGHTHOUSE! \
	Fulfilling needs you didn't even know you had. We've got EVERYTHING, and something else!"
	admin_notes = "Currently larger than ferry docking port on Box, will not hit anything, but must be force docked. Trader and ERT bodyguards are not included."

/datum/map_template/shuttle/ferry/fancy
	suffix = "fancy"
	name = "fancy transport ferry"
	description = "At some point, someone upgraded the ferry to have fancier flooring... and fewer seats."

/datum/map_template/shuttle/ferry/kilo
	suffix = "kilo"
	name = "kilo transport ferry"
	description = "Standard issue CentCom Ferry for Kilo pattern stations. Includes additional equipment and rechargers."

/datum/map_template/shuttle/ferry/northstar
	suffix = "northstar"
	name = "north star transport ferry"
	description = "In the very depths of the frontier, you'll need a rugged shuttle capable of delivering crew, this is that."

/datum/map_template/shuttle/whiteship/box
	suffix = "box"
	name = "Hospital Ship"
	description = "Whiteship with medical supplies. Zombies do not currently spawn corpses, and are not infectious."

/datum/map_template/shuttle/whiteship/meta
	suffix = "meta"
	name = "Salvage Ship"
	description = "Whiteship that focuses on a large cargo bay that players can build in. Spawns with Syndicate mobs who do not drop corpses and are highly aggressive."

/datum/map_template/shuttle/whiteship/pubby
	suffix = "pubby"
	name = "NT Science Vessel"
	description = "A small science vessel that uses just one area and is full of angry ants."

/datum/map_template/shuttle/whiteship/cere
	suffix = "cere"
	name = "NT Heavy Salvage Vessel"
	description = "A beefy, well-rounded salvage vessel with a pair of corpses (miner and engineer) and a Captain's hat. Equipped with solar sails and a PACMAN generator."

/datum/map_template/shuttle/whiteship/kilo
	suffix = "kilo"
	name = "NT Mining Shuttle"
	description = "A mining vessel with a curious shape starting with a few angry netherworld mobs."

/datum/map_template/shuttle/whiteship/donut
	suffix = "donut"
	name = "NT Long-Distance Bluespace Jumper"
	description = "A ship hit with an engine blowout, leaving it as a depressurised husk. Has infinite power, although likely to bait people into removing that property. Also the most open out of all the whiteships, and starts with a 25% ripley chance."

/datum/map_template/shuttle/whiteship/tram
	suffix = "tram"
	name = "NT Long-Distance Bluespace Freighter"
	description = "A long shuttle that starts with Nanotrasen private security corpses. DOES NOT FIT IN THE BASE DOCKS! Does fit in Deep Space's dock though."

/datum/map_template/shuttle/whiteship/delta
	suffix = "delta"
	name = "NT Frigate"
	description = "A standard whiteship with big spiders onboard. PACMAN generator is not wired and next to main grid cabling, so it requires some work."

/datum/map_template/shuttle/whiteship/pod
	suffix = "whiteship_pod"
	name = "Salvage Pod"
	description = "There is no map for this vessel and it was supposed to be used with the Meta-class. Do not try to spawn it!"

/datum/map_template/shuttle/whiteship/personalshuttle
	suffix = "personalshuttle"
	name = "Personal Travel Shuttle"
	description = "A small vessel with a few zombies and an engineer's corpse that can be looted."

/datum/map_template/shuttle/whiteship/obelisk
	suffix = "obelisk"
	name = "Obelisk"
	description = "A large research vessel affected by the Cult of Nar'Sie. PACMAN generator is not wired and next to main grid cabling, so it requires some work."
	admin_notes = "Not actually an obelisk, has nonsentient cult constructs."

/datum/map_template/shuttle/cargo/kilo
	suffix = "kilo"
	name = "supply shuttle (Kilo)"

/datum/map_template/shuttle/cargo/birdboat
	suffix = "birdboat"
	name = "supply shuttle (Birdboat)"

/datum/map_template/shuttle/cargo/donut
	suffix = "donut"
	name = "supply shuttle (Donut)"

/datum/map_template/shuttle/cargo/pubby
	suffix = "pubby"
	name = "supply shuttle (Pubby)"

/datum/map_template/shuttle/emergency/delta
	suffix = "delta"
	name = "Delta Station Emergency Shuttle"
	description = "A large shuttle for a large station, this shuttle can comfortably fit all your overpopulation and crowding needs. Complete with all facilities plus additional equipment."
	admin_notes = "Go big or go home."
	credit_cost = CARGO_CRATE_VALUE * 15

/datum/map_template/shuttle/emergency/northstar
	suffix = "northstar"
	name = "North Star Emergency Shuttle"
	description = "A rugged shuttle meant for long-distance transit from the tips of the frontier to Central Command and back. \
	moderately comfortable and large, but cramped."
	credit_cost = CARGO_CRATE_VALUE * 14

/datum/map_template/shuttle/emergency/raven
	suffix = "raven"
	name = "CentCom Raven Cruiser"
	description = "The CentCom Raven Cruiser is a former high-risk salvage vessel, now repurposed into an emergency escape shuttle. \
	Once first to the scene to pick through warzones for valuable remains, it now serves as an excellent escape option for stations under heavy fire from outside forces. \
	This escape shuttle boasts shields and numerous anti-personnel turrets guarding its perimeter to fend off meteors and enemy boarding attempts."
	admin_notes = "Comes with turrets that will target anything without the neutral faction (nuke ops, xenos etc, but not pets)."
	credit_cost = CARGO_CRATE_VALUE * 60

/datum/map_template/shuttle/emergency/zeta
	suffix = "zeta"
	name = "Tr%nPo2r& Z3TA"
	description = "A glitch appears on your monitor, flickering in and out of the options laid before you. \
	It seems strange and alien, you may need a special technology to access the signal.."
	admin_notes = "Has alien surgery tools, and a void core that provides unlimited power."
	credit_cost = CARGO_CRATE_VALUE * 16

/datum/map_template/shuttle/emergency/zeta/prerequisites_met()
	return SSshuttle.shuttle_purchase_requirements_met[SHUTTLE_UNLOCK_ALIENTECH]

/datum/map_template/shuttle/arrival/box
	suffix = "box"
	name = "arrival shuttle (Box)"

/datum/map_template/shuttle/cargo/box
	suffix = "box"
	name = "cargo ferry (Box)"

/datum/map_template/shuttle/mining/box
	suffix = "box"
	name = "mining shuttle (Box)"

/datum/map_template/shuttle/labour/box
	suffix = "box"
	name = "labour shuttle (Box)"

/datum/map_template/shuttle/labour/generic
	suffix = "generic"
	name = "labour shuttle (Generic)"

/datum/map_template/shuttle/arrival/donut
	suffix = "donut"
	name = "arrival shuttle (Donut)"

/datum/map_template/shuttle/infiltrator/basic
	suffix = "basic"
	name = "basic syndicate infiltrator"
	description = "Base Syndicate infiltrator, spawned by default for nukeops to use."

/datum/map_template/shuttle/infiltrator/advanced
	suffix = "advanced"
	name = "advanced syndicate infiltrator"
	description = "A much larger version of the standard Syndicate infiltrator that feels more like Kilostation. Has APCs, but power is not a concern for nuclear operatives. Also comes with atmos!"

/datum/map_template/shuttle/cargo/delta
	suffix = "delta"
	name = "cargo ferry (Delta)"

/datum/map_template/shuttle/mining/delta
	suffix = "delta"
	name = "mining shuttle (Delta)"

/datum/map_template/shuttle/mining/kilo
	suffix = "kilo"
	name = "mining shuttle (Kilo)"

/datum/map_template/shuttle/mining/large
	suffix = "large"
	name = "mining shuttle (Large)"

/datum/map_template/shuttle/mining/northstar
	suffix = "northstar"
	name = "mining shuttle (North Star)"

/datum/map_template/shuttle/labour/delta
	suffix = "delta"
	name = "labour shuttle (Delta)"

/datum/map_template/shuttle/labour/kilo
	suffix = "kilo"
	name = "labour shuttle (Kilo)"

/datum/map_template/shuttle/mining_common/meta
	suffix = "meta"
	name = "lavaland shuttle (Meta)"

/datum/map_template/shuttle/mining_common/kilo
	suffix = "kilo"
	name = "lavaland shuttle (Kilo)"

/datum/map_template/shuttle/mining_common/northstar
	suffix = "northstar"
	name = "lavaland shuttle (North Star)"

/datum/map_template/shuttle/arrival/delta
	suffix = "delta"
	name = "arrival shuttle (Delta)"

/datum/map_template/shuttle/arrival/kilo
	suffix = "kilo"
	name = "arrival shuttle (Kilo)"

/datum/map_template/shuttle/arrival/pubby
	suffix = "pubby"
	name = "arrival shuttle (Pubby)"

/datum/map_template/shuttle/arrival/omega
	suffix = "omega"
	name = "arrival shuttle (Omega)"

/datum/map_template/shuttle/aux_base/default
	suffix = "default"
	name = "auxilliary base (Default)"

/datum/map_template/shuttle/aux_base/small
	suffix = "small"
	name = "auxilliary base (Small)"

/datum/map_template/shuttle/escape_pod/default
	suffix = "default"
	name = "escape pod (Default)"
	description = "Base escape pod with 2 tiles of interior space."

/datum/map_template/shuttle/escape_pod/large
	suffix = "large"
	name = "escape pod (Large)"
	description = "Actually the old Pubbystation monastery shuttle."

/datum/map_template/shuttle/escape_pod/luxury
	suffix = "luxury"
	name = "escape pod (Luxury)"
	description = "Upgraded escape pod with 3 tiles of interior space."

/datum/map_template/shuttle/escape_pod/cramped
	suffix = "cramped"
	name = "escape pod (Cramped)"
	description = "Downgraded escape pod that lacks a window and only has one seat, alongside lacking an emergency safe."

/datum/map_template/shuttle/assault_pod/default
	suffix = "default"
	name = "assault pod (Default)"

/datum/map_template/shuttle/pirate/default
	suffix = "default"
	name = "pirate ship (Default)"

/datum/map_template/shuttle/pirate/silverscale
	suffix = "silverscale"
	name = "pirate ship (Silver Scales)"

/datum/map_template/shuttle/pirate/dutchman
	suffix = "dutchman"
	name = "pirate ship (Flying Dutchman)"

/datum/map_template/shuttle/pirate/psykers
	suffix = "psyker"
	name = "pirate ship (Psyker-gang)"

/datum/map_template/shuttle/hunter/space_cop
	suffix = "space_cop"
	name = "Police Spacevan"

/datum/map_template/shuttle/hunter/russian
	suffix = "russian"
	name = "Russian Cargo Ship"

/datum/map_template/shuttle/hunter/bounty
	suffix = "bounty"
	name = "Bounty Hunter Ship"

/datum/map_template/shuttle/starfury
	port_id = "starfury"
	who_can_purchase = null

/datum/map_template/shuttle/starfury/fighter_one
	suffix = "fighter1"
	name = "SBC Starfury Fighter (1)"

/datum/map_template/shuttle/starfury/fighter_two
	suffix = "fighter2"
	name = "SBC Starfury Fighter (2)"

/datum/map_template/shuttle/starfury/fighter_three
	suffix = "fighter3"
	name = "SBC Starfury Fighter (3)"

/datum/map_template/shuttle/starfury/corvette
	suffix = "corvette"
	name = "SBC Starfury Corvette"

/datum/map_template/shuttle/ruin/cyborg_mothership
	suffix = "cyborg_mothership"
	name = "Cyborg Mothership"
	description = "A highly industrialised vessel designed for silicon operation infested with hivebots and space vines."

/datum/map_template/shuttle/ruin/caravan_victim
	suffix = "caravan_victim"
	name = "Small Freighter"
	description = "Small freight vessel, starts near blacked-out with 3 Syndicate Commandos and 1 Syndicate Stormtrooper, alongside a large hull breach."

/datum/map_template/shuttle/ruin/pirate_cutter
	suffix = "pirate_cutter"
	name = "Pirate Cutter"
	description = "Small pirate vessel with ballistic turrets. Spawns with 3 pirate mobs, one of which drops an energy cutlass."

/datum/map_template/shuttle/ruin/syndicate_dropship
	suffix = "syndicate_dropship"
	name = "Syndicate Dropship"
	description = "Light Syndicate vessel with laser turrets. Spawns with a Syndicate mob in the bridge."

/datum/map_template/shuttle/ruin/syndicate_fighter_shiv
	suffix = "syndicate_fighter_shiv"
	name = "Syndicate Fighter"
	description = "A small Syndicate vessel with exactly one tile of useful interior space and 4 laser turrets. Starts with a Syndicate mob in the pilot's seat, and extremely cramped."

/datum/map_template/shuttle/snowdin/mining
	suffix = "mining"
	name = "Snowdin Mining Elevator"

/datum/map_template/shuttle/snowdin/excavation
	suffix = "excavation"
	name = "Snowdin Excavation Elevator"

/datum/map_template/shuttle/arrival/northstar
	suffix = "northstar"
	name = "arrival shuttle (North Star)"

/datum/map_template/shuttle/cargo/northstar
	suffix = "northstar"
	name = "cargo ferry (North Star)"

// Custom ERT shuttles
/datum/map_template/shuttle/ert/bounty
	suffix = "bounty"
	name = "Bounty Hunter ERT Shuttle"

#undef EMAG_LOCKED_SHUTTLE_COST

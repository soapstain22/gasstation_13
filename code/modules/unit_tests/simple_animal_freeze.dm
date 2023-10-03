/// Tests that no new simple_animal subtypes are added.
/datum/unit_test/simple_animal_freeze
	// !!! DO NOT ADD NEW ENTRIES TO THIS LIST !!!
	// NO new simple animals are allowed.
	// Use the new basic mobs system instead.
	// If you are refactoring a simple_animal, REMOVE it from this list
	var/list/allowed_types = list(
		/mob/living/simple_animal/bot,
		/mob/living/simple_animal/bot/cleanbot,
		/mob/living/simple_animal/bot/cleanbot/autopatrol,
		/mob/living/simple_animal/bot/cleanbot/medbay,
		/mob/living/simple_animal/bot/firebot,
		/mob/living/simple_animal/bot/floorbot,
		/mob/living/simple_animal/bot/hygienebot,
		/mob/living/simple_animal/bot/medbot,
		/mob/living/simple_animal/bot/medbot/autopatrol,
		/mob/living/simple_animal/bot/medbot/derelict,
		/mob/living/simple_animal/bot/medbot/mysterious,
		/mob/living/simple_animal/bot/medbot/nukie,
		/mob/living/simple_animal/bot/medbot/stationary,
		/mob/living/simple_animal/bot/mulebot,
		/mob/living/simple_animal/bot/mulebot/paranormal,
		/mob/living/simple_animal/bot/secbot,
		/mob/living/simple_animal/bot/secbot/beepsky,
		/mob/living/simple_animal/bot/secbot/beepsky/armsky,
		/mob/living/simple_animal/bot/secbot/beepsky/jr,
		/mob/living/simple_animal/bot/secbot/beepsky/officer,
		/mob/living/simple_animal/bot/secbot/beepsky/ofitser,
		/mob/living/simple_animal/bot/secbot/ed209,
		/mob/living/simple_animal/bot/secbot/genesky,
		/mob/living/simple_animal/bot/secbot/grievous,
		/mob/living/simple_animal/bot/secbot/grievous/toy,
		/mob/living/simple_animal/bot/secbot/honkbot,
		/mob/living/simple_animal/bot/secbot/pingsky,
		/mob/living/simple_animal/bot/vibebot,
		/mob/living/simple_animal/drone,
		/mob/living/simple_animal/drone/classic,
		/mob/living/simple_animal/drone/derelict,
		/mob/living/simple_animal/drone/polymorphed,
		/mob/living/simple_animal/drone/snowflake,
		/mob/living/simple_animal/drone/snowflake/bardrone,
		/mob/living/simple_animal/drone/syndrone,
		/mob/living/simple_animal/drone/syndrone/badass,
		/mob/living/simple_animal/holodeck_monkey,
		/mob/living/simple_animal/hostile,
		/mob/living/simple_animal/hostile/alien,
		/mob/living/simple_animal/hostile/alien/drone,
		/mob/living/simple_animal/hostile/alien/maid,
		/mob/living/simple_animal/hostile/alien/maid/barmaid,
		/mob/living/simple_animal/hostile/alien/queen,
		/mob/living/simple_animal/hostile/alien/queen/large,
		/mob/living/simple_animal/hostile/alien/sentinel,
		/mob/living/simple_animal/hostile/asteroid,
		/mob/living/simple_animal/hostile/asteroid/curseblob,
		/mob/living/simple_animal/hostile/asteroid/elite,
		/mob/living/simple_animal/hostile/asteroid/elite/broodmother,
		/mob/living/simple_animal/hostile/asteroid/elite/broodmother_child,
		/mob/living/simple_animal/hostile/asteroid/elite/herald,
		/mob/living/simple_animal/hostile/asteroid/elite/herald/mirror,
		/mob/living/simple_animal/hostile/asteroid/elite/legionnaire,
		/mob/living/simple_animal/hostile/asteroid/elite/legionnairehead,
		/mob/living/simple_animal/hostile/asteroid/elite/pandora,
		/mob/living/simple_animal/hostile/asteroid/gutlunch,
		/mob/living/simple_animal/hostile/asteroid/gutlunch/grublunch,
		/mob/living/simple_animal/hostile/asteroid/gutlunch/gubbuck,
		/mob/living/simple_animal/hostile/asteroid/gutlunch/guthen,
		/mob/living/simple_animal/hostile/asteroid/ice_demon,
		/mob/living/simple_animal/hostile/asteroid/polarbear,
		/mob/living/simple_animal/hostile/asteroid/polarbear/lesser,
		/mob/living/simple_animal/hostile/asteroid/wolf,
		/mob/living/simple_animal/hostile/construct,
		/mob/living/simple_animal/hostile/construct/artificer,
		/mob/living/simple_animal/hostile/construct/artificer/angelic,
		/mob/living/simple_animal/hostile/construct/artificer/hostile,
		/mob/living/simple_animal/hostile/construct/artificer/mystic,
		/mob/living/simple_animal/hostile/construct/artificer/noncult,
		/mob/living/simple_animal/hostile/construct/harvester,
		/mob/living/simple_animal/hostile/construct/juggernaut,
		/mob/living/simple_animal/hostile/construct/juggernaut/angelic,
		/mob/living/simple_animal/hostile/construct/juggernaut/hostile,
		/mob/living/simple_animal/hostile/construct/juggernaut/mystic,
		/mob/living/simple_animal/hostile/construct/juggernaut/noncult,
		/mob/living/simple_animal/hostile/construct/proteon,
		/mob/living/simple_animal/hostile/construct/proteon/hostile,
		/mob/living/simple_animal/hostile/construct/wraith,
		/mob/living/simple_animal/hostile/construct/wraith/angelic,
		/mob/living/simple_animal/hostile/construct/wraith/hostile,
		/mob/living/simple_animal/hostile/construct/wraith/mystic,
		/mob/living/simple_animal/hostile/construct/wraith/noncult,
		/mob/living/simple_animal/hostile/dark_wizard,
		/mob/living/simple_animal/hostile/gorilla,
		/mob/living/simple_animal/hostile/gorilla/lesser,
		/mob/living/simple_animal/hostile/gorilla/cargo_domestic,
		/mob/living/simple_animal/hostile/guardian,
		/mob/living/simple_animal/hostile/guardian/assassin,
		/mob/living/simple_animal/hostile/guardian/charger,
		/mob/living/simple_animal/hostile/guardian/dextrous,
		/mob/living/simple_animal/hostile/guardian/explosive,
		/mob/living/simple_animal/hostile/guardian/gaseous,
		/mob/living/simple_animal/hostile/guardian/gravitokinetic,
		/mob/living/simple_animal/hostile/guardian/lightning,
		/mob/living/simple_animal/hostile/guardian/protector,
		/mob/living/simple_animal/hostile/guardian/ranged,
		/mob/living/simple_animal/hostile/guardian/standard,
		/mob/living/simple_animal/hostile/guardian/support,
		/mob/living/simple_animal/hostile/heretic_summon,
		/mob/living/simple_animal/hostile/heretic_summon/armsy,
		/mob/living/simple_animal/hostile/heretic_summon/armsy/prime,
		/mob/living/simple_animal/hostile/heretic_summon/ash_spirit,
		/mob/living/simple_animal/hostile/heretic_summon/maid_in_the_mirror,
		/mob/living/simple_animal/hostile/heretic_summon/rust_spirit,
		/mob/living/simple_animal/hostile/heretic_summon/stalker,
		/mob/living/simple_animal/hostile/illusion,
		/mob/living/simple_animal/hostile/illusion/escape,
		/mob/living/simple_animal/hostile/illusion/mirage,
		/mob/living/simple_animal/hostile/jungle,
		/mob/living/simple_animal/hostile/jungle/leaper,
		/mob/living/simple_animal/hostile/jungle/mook,
		/mob/living/simple_animal/hostile/megafauna,
		/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner,
		/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner/doom,
		/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner/guidance,
		/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner/hunter,
		/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner/virtual_domain,
		/mob/living/simple_animal/hostile/megafauna/bubblegum,
		/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination,
		/mob/living/simple_animal/hostile/megafauna/bubblegum/virtual_domain,
		/mob/living/simple_animal/hostile/megafauna/clockwork_defender,
		/mob/living/simple_animal/hostile/megafauna/colossus,
		/mob/living/simple_animal/hostile/megafauna/colossus/virtual_domain,
		/mob/living/simple_animal/hostile/megafauna/demonic_frost_miner,
		/mob/living/simple_animal/hostile/megafauna/dragon,
		/mob/living/simple_animal/hostile/megafauna/dragon/lesser,
		/mob/living/simple_animal/hostile/megafauna/dragon/virtual_domain,
		/mob/living/simple_animal/hostile/megafauna/hierophant,
		/mob/living/simple_animal/hostile/megafauna/hierophant/virtual_domain,
		/mob/living/simple_animal/hostile/megafauna/legion,
		/mob/living/simple_animal/hostile/megafauna/legion/virtual_domain,
		/mob/living/simple_animal/hostile/megafauna/legion/medium,
		/mob/living/simple_animal/hostile/megafauna/legion/medium/eye,
		/mob/living/simple_animal/hostile/megafauna/legion/medium/left,
		/mob/living/simple_animal/hostile/megafauna/legion/medium/right,
		/mob/living/simple_animal/hostile/megafauna/legion/small,
		/mob/living/simple_animal/hostile/megafauna/wendigo,
		/mob/living/simple_animal/hostile/megafauna/wendigo/virtual_domain,
		/mob/living/simple_animal/hostile/mimic,
		/mob/living/simple_animal/hostile/mimic/copy,
		/mob/living/simple_animal/hostile/mimic/copy/machine,
		/mob/living/simple_animal/hostile/mimic/copy/ranged,
		/mob/living/simple_animal/hostile/mimic/crate,
		/mob/living/simple_animal/hostile/mimic/xenobio,
		/mob/living/simple_animal/hostile/nanotrasen,
		/mob/living/simple_animal/hostile/nanotrasen/elite,
		/mob/living/simple_animal/hostile/nanotrasen/ranged,
		/mob/living/simple_animal/hostile/nanotrasen/ranged/assault,
		/mob/living/simple_animal/hostile/nanotrasen/ranged/smg,
		/mob/living/simple_animal/hostile/nanotrasen/screaming,
		/mob/living/simple_animal/hostile/ooze,
		/mob/living/simple_animal/hostile/ooze/gelatinous,
		/mob/living/simple_animal/hostile/ooze/grapes,
		/mob/living/simple_animal/hostile/pirate,
		/mob/living/simple_animal/hostile/pirate/melee,
		/mob/living/simple_animal/hostile/pirate/melee/space,
		/mob/living/simple_animal/hostile/pirate/ranged,
		/mob/living/simple_animal/hostile/pirate/ranged/space,
		/mob/living/simple_animal/hostile/retaliate,
		/mob/living/simple_animal/hostile/retaliate/goose,
		/mob/living/simple_animal/hostile/retaliate/goose/vomit,
		/mob/living/simple_animal/hostile/retaliate/nanotrasenpeace,
		/mob/living/simple_animal/hostile/retaliate/nanotrasenpeace/ranged,
		/mob/living/simple_animal/hostile/retaliate/trader,
		/mob/living/simple_animal/hostile/retaliate/trader/mrbones,
		/mob/living/simple_animal/hostile/skeleton,
		/mob/living/simple_animal/hostile/skeleton/eskimo,
		/mob/living/simple_animal/hostile/skeleton/ice,
		/mob/living/simple_animal/hostile/skeleton/plasmaminer,
		/mob/living/simple_animal/hostile/skeleton/plasmaminer/jackhammer,
		/mob/living/simple_animal/hostile/skeleton/templar,
		/mob/living/simple_animal/hostile/space_dragon,
		/mob/living/simple_animal/hostile/space_dragon/spawn_with_antag,
		/mob/living/simple_animal/hostile/vatbeast,
		/mob/living/simple_animal/hostile/venus_human_trap,
		/mob/living/simple_animal/hostile/wizard,
		/mob/living/simple_animal/hostile/zombie,
		/mob/living/simple_animal/parrot,
		/mob/living/simple_animal/parrot/natural,
		/mob/living/simple_animal/parrot/poly,
		/mob/living/simple_animal/parrot/poly/ghost,
		/mob/living/simple_animal/pet,
		/mob/living/simple_animal/pet/cat,
		/mob/living/simple_animal/pet/cat/_proc,
		/mob/living/simple_animal/pet/cat/breadcat,
		/mob/living/simple_animal/pet/cat/cak,
		/mob/living/simple_animal/pet/cat/jerry,
		/mob/living/simple_animal/pet/cat/kitten,
		/mob/living/simple_animal/pet/cat/original,
		/mob/living/simple_animal/pet/cat/runtime,
		/mob/living/simple_animal/pet/cat/space,
		/mob/living/simple_animal/pet/gondola,
		/mob/living/simple_animal/pet/gondola/gondolapod,
		/mob/living/simple_animal/pet/gondola/virtual_domain,
		/mob/living/simple_animal/revenant,
		/mob/living/simple_animal/shade,
		/mob/living/simple_animal/slime,
		/mob/living/simple_animal/slime/pet,
		/mob/living/simple_animal/slime/random,
		/mob/living/simple_animal/slime/transformed_slime,
		/mob/living/simple_animal/sloth,
		/mob/living/simple_animal/sloth/citrus,
		/mob/living/simple_animal/sloth/paperwork,
		/mob/living/simple_animal/soulscythe,
		// DO NOT ADD NEW ENTRIES TO THIS LIST
		// READ THE COMMENT ABOVE
	)

/datum/unit_test/simple_animal_freeze/Run()
	var/list/seen = list()

	// Sanity check, to prevent people from just doing a mass find and replace
	for (var/allowed_type in allowed_types)
		if (allowed_type in seen)
			TEST_FAIL("[allowed_type] is in the allowlist more than once")
		else
			seen[allowed_type] = TRUE

		TEST_ASSERT(ispath(allowed_type, /mob/living/simple_animal), "[allowed_type] is not a simple_animal. Remove it from the list.")

	for (var/subtype in subtypesof(/mob/living/simple_animal))
		if (!(subtype in allowed_types))
			TEST_FAIL("No new simple_animal subtypes are allowed. Please refactor [subtype] into a basic mob.")

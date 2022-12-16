/// A list of all infuser entries
GLOBAL_LIST_INIT(infuser_entries, prepare_entries())

/// just clarifying that no threshold does some special stuff, since only meme mutants have it
#define NO_THRESHOLD ""

/proc/prepare_entries()
	var/list/entries = list()
	//regardless of names we want the failed mutant case to show first
	var/prepended
	for(var/datum/infuser_entry/entry_type as anything in typesof(/datum/infuser_entry))
		var/datum/infuser_entry/entry = new entry_type()
		if(entry.type == /datum/infuser_entry)
			prepended = entry
			continue
		entries += entry
	var/list/sorted = sort_names(entries)
	sorted.Insert(1, prepended)
	return sorted

/datum/infuser_entry
	//info for the book

	/// name of the mutant you become
	var/name = "Rejected"
	/// what you have to infuse to become it
	var/infuse_mob_name = "rejected creature"
	/// general desc
	var/desc = "For whatever reason, when the body rejects DNA, the DNA goes sour, ending up as some kind of fly-like DNA jumble."
	/// desc of what passing the threshold gets you. if this is empty, there is no threshold, so this is also really a tally of whether this is a "meme" mutant or not
	var/threshold_desc = "the DNA mess takes over, and you become a full-fledged flyperson."
	/// various little bits
	var/list/qualities = list(
		"buzzy-like speech",
		"vomit drinking",
		"unidentifiable organs",
		"this is a bad idea",
	)

	//info for the machine

	/// ...THINGS, mobs or items, the machine will infuse to make output organs
	var/list/input_obj_or_mob = list(
		///rejected creatures, of course, are anything not covered by other recipes. This is a special case
	)
	/// organs that the machine could spit out in relation
	var/list/output_organs = list(
		/obj/item/organ/internal/eyes/fly,
		/obj/item/organ/internal/tongue/fly,
		/obj/item/organ/internal/heart/fly,
		/obj/item/organ/internal/lungs/fly,
		/obj/item/organ/internal/stomach/fly,
		/obj/item/organ/internal/appendix/fly,
	)
	///message the target gets while being infused
	var/infusion_desc = "fly-like"

/datum/infuser_entry/rat
	name = "Rat"
	infuse_mob_name = "rodent"
	desc = "Frail, small, positively cheesed to face the world. Easy to stuff yourself full of rat DNA, but perhaps not the best choice?"
	threshold_desc = "you become lithe enough to crawl through ventilation."
	qualities = list(
		"cheesy lines",
		"will eat anything",
		"wants to eat anything, constantly",
		"frail but quick",
	)
	input_obj_or_mob = list(
		/obj/item/food/deadmouse,
	)
	output_organs = list(
		/obj/item/organ/internal/eyes/night_vision/rat,
		/obj/item/organ/internal/stomach/rat,
		/obj/item/organ/internal/heart/rat,
		/obj/item/organ/internal/tongue/rat,
	)
	infusion_desc = "skittish"

/datum/infuser_entry/carp
	name = "Carp"
	infuse_mob_name = "space-cyprinidae"
	desc = "Carp-mutants are very well-prepared for long term deep space exploration. In fact, they can't stand not doing it!"
	threshold_desc = "you learn how to propel yourself through space. Like a fish!"
	qualities = list(
		"big jaws, big teeth",
		"swim through space, no problem",
		"face every problem when you go back on station",
		"always wants to travel",
	)
	input_obj_or_mob = list(
		/mob/living/simple_animal/hostile/carp,
	)
	output_organs = list(
		/obj/item/organ/internal/lungs/carp,
		/obj/item/organ/internal/tongue/carp,
		/obj/item/organ/internal/brain/carp,
		/obj/item/organ/internal/heart/carp,
	)
	infusion_desc = "nomadic"

// just some meme entries, these basically encourage killing staff pets but do not play with the organ bonus system

/datum/infuser_entry/felinid
	name = "Cat"
	infuse_mob_name = "feline"
	desc = "EVERYONE CALM DOWN! I'm not implying anything with this entry. Are we really so surprised that felinids are humans with mixed feline DNA?"
	threshold_desc = NO_THRESHOLD
	qualities = list(
		"oh, let me guess, you're a big fan of those japanese tourist bots",
	)
	input_obj_or_mob = list(
		/mob/living/simple_animal/pet/cat,
	)
	output_organs = list(
		/obj/item/organ/internal/ears/cat,
		/obj/item/organ/external/tail/cat,
	)
	infusion_desc = "domestic"

/datum/infuser_entry/vulpini
	name = "Fox"
	infuse_mob_name = "vulpini"
	desc = "Foxes are now quite rare because of the \"fox ears\" craze back in 2555. I mean, also because we're spacefarers who destroyed foxes' natural habitats ages ago, but that applies to most animals."
	threshold_desc = NO_THRESHOLD
	qualities = list(
		"oh come on really",
		"you bring SHAME to all geneticists",
		"i hope it was worth it",
	)
	input_obj_or_mob = list(
		/mob/living/simple_animal/pet/fox,
	)
	output_organs = list(
		/obj/item/organ/internal/ears/fox,
	)
	infusion_desc = "inexcusable"

/datum/infuser_entry/roach
	name = "Roach"
	infuse_mob_name = "cockroach"
	desc = "It seems as if you're a fan of ancient literate by your interest in this. Assuredly, merging cockroach DNA into your genome \
		will not cause you to become incapable of leaving your bed. These creatures are incredibly resilient to many things \
		humans weak to, and we can use that! Who wouldn't like to survive a nuclear blast? \
		NOTE: Squished roaches will not work for the infuser, if that wasn't obvious. Try spraying them with some pestkiller from botany!"
	threshold_desc = "you will no longer be gibbed by explosions, and gain incredible resistance to viruses."
	qualities = list(
		"resilience to attacks from behind",
		"healthier organs",
		"get over disgust very quickly",
		"the ability to survive a nuclear apocalypse",
		"harder to pick yourself up from falling over",
		"avoid toxins at all costs",
	)
	input_obj_or_mob = list(
		/mob/living/basic/cockroach,
	)
	output_organs = list(
		/obj/item/organ/internal/heart/roach,
		/obj/item/organ/internal/stomach/roach,
		/obj/item/organ/internal/liver/roach,
		/obj/item/organ/internal/appendix/roach,
	)
	infusion_desc = "kafkaesque" // Gregor Samsa !!

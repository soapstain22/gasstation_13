/datum/round_event_control/dark_matteor
	name = "Dark Matt-eor"
	typepath = /datum/round_event/dark_matteor
	weight = 0
	max_occurrences = 0
	category = EVENT_CATEGORY_SPACE
	description = "Throw a dark matt-eor somewhere near the station."
	admin_setup = list(/datum/event_admin_setup/warn_admin/dark_matteor)
	map_flags = EVENT_SPACE_ONLY

/datum/round_event/dark_matteor
	fakeable = FALSE //Already faked by meteors that miss. Please, god, please miss

/datum/round_event/stray_meteor/start()
	spawn_meteor(list(/obj/effect/meteor/dark_matteor))

/datum/round_event/stray_meteor/announce(fake)
	SSsecurity_level.set_level(SEC_LEVEL_RED)
	priority_announce("Warning. Excessive tampering of meteor satellites has attracted a dark matt-eor. Signature approaching [GLOB.station_name]. Please brace for impact.", "Meteor Alert", 'sound/effects/curse1.ogg')

/datum/event_admin_setup/warn_admin/dark_matteor
	warning_text = "Dark Matt-eors spawn singularities. The round is ending once a dark matt-eor hits the station. Proceed anyways?"
	snitch_text = null //since this is not a conditional alert, there is nothing to snitch on. announcing a triggered event is enough.

/datum/event_admin_setup/warn_admin/dark_matteor/should_warn()
	return TRUE

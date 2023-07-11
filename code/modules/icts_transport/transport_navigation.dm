/obj/effect/landmark/icts/nav_beacon/tram
	name = "tram destination" //the tram buttons will mention this.
	icon_state = "tram"

	///the id of the tram we're linked to.
	var/specific_transport_id = TRAMSTATION_LINE_1
	/// The ID of that particular destination.
	var/platform_code = null
	/// Icons for the tgui console to list out for what is at this location
	var/list/tgui_icons = list()

/obj/effect/landmark/icts/nav_beacon/tram/Initialize(mapload)
	. = ..()
	LAZYADDASSOCLIST(SSicts_transport.nav_beacons, specific_transport_id, src)

/obj/effect/landmark/icts/nav_beacon/tram/Destroy()
	LAZYREMOVEASSOC(SSicts_transport.nav_beacons, specific_transport_id, src)
	return ..()

//tramstation

/obj/effect/landmark/icts/nav_beacon/tram/tramstation/west
	name = "West Wing"
	platform_code = TRAMSTATION_WEST
	tgui_icons = list("Arrivals" = "plane-arrival", "Command" = "bullhorn", "Security" = "gavel")

/obj/effect/landmark/icts/nav_beacon/tram/tramstation/central
	name = "Central Wing"
	platform_code = TRAMSTATION_CENTRAL
	tgui_icons = list("Service" = "cocktail", "Medical" = "plus", "Engineering" = "wrench")

/obj/effect/landmark/icts/nav_beacon/tram/tramstation/east
	name = "East Wing"
	platform_code = TRAMSTATION_EAST
	tgui_icons = list("Departures" = "plane-departure", "Cargo" = "box", "Science" = "flask")

//birdshot

/obj/effect/landmark/icts/nav_beacon/tram/birdshot/sec_wing
	name = "Security Wing"
	platform_code = BIRDSHOT_SECURITY_WING
	tgui_icons = list("Security" = "gavel")

/obj/effect/landmark/icts/nav_beacon/tram/birdshot/prison_wing
	name = "Prison Wing"
	platform_code = BIRDSHOT_PRISON_WING
	tgui_icons = list("Prison" = "box")

/obj/effect/landmark/icts/nav_beacon/tram/birdshot/maint_left
	name = "Port Platform"
	platform_code = BIRDSHOT_MAINTENANCE_LEFT
	tgui_icons = list("Port Platform" = "plane-departure")

/obj/effect/landmark/icts/nav_beacon/tram/birdshot/maint_right
	name = "Starboard Platform"
	platform_code = BRIDSHOT_MAINTENANCE_RIGHT
	tgui_icons = list("Starboard Platform" = "plane-arrival")

/**
 * lift_id landmarks. used to map in specific_transport_id to trams. when the trams lift_master encounters one on a trams tile
 * it sets its specific_transport_id to that landmark. allows you to have multiple trams and multiple controls linking to their specific tram
 */
/obj/effect/landmark/icts/transport_id
	name = "transport init landmark"
	icon_state = "lift_id"
	///what specific id we give to the tram we're placed on, should explicitely set this if its a subtype, or weird things might happen
	var/specific_transport_id

/obj/effect/landmark/icts/transport_id/birdshot/line_1
	specific_transport_id = BIRDSHOT_LINE_1

/obj/effect/landmark/icts/transport_id/birdshot/line_2
	specific_transport_id = BIRDSHOT_LINE_2

/obj/effect/landmark/icts/transport_id/hilbert/line_1
	specific_transport_id = HILBERT_LINE_1

/obj/effect/landmark/icts/transport_id/tramstation/line_1
	specific_transport_id = TRAMSTATION_LINE_1

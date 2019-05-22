/datum/weather/snow_storm
	name = "snow storm"
	desc = "Harsh snowstorms roam the topside of this arctic planet, burying any area unfortunate enough to be in its path."
	probability = 90

	telegraph_message = "<span class='warning'>Drifting particles of snow begin to dust the surrounding area..</span>"
	telegraph_duration = 300
	telegraph_overlay = "light_snow"

	weather_message = "<span class='userdanger'><i>Harsh winds pick up as dense snow begins to fall from the sky! Seek shelter!</i></span>"
	weather_overlay = "snow_storm"
	weather_duration_lower = 600
	weather_duration_upper = 1500

	end_duration = 100
	end_message = "<span class='boldannounce'>The snowfall dies down, it should be safe to go outside again.</span>"

	area_type = /area/awaymission/snowdin/outside
	target_trait = ZTRAIT_AWAY

	immunity_type = "snow"

	barometer_predictable = TRUE


/datum/weather/snow_storm/weather_act(mob/living/L)
	L.adjust_bodytemperature(-rand(5,15))

/datum/weather/snow_storm/freeze
	target_trait = ZTRAIT_STATION
	probability = 0
	barometer_predictable = FALSE
	area_type = /area
	protected_areas = list(/area/shuttle)
	weather_message = "<span class='userdanger'><i>Harsh winds pick up as dense snow begins to fall around you!</i></span>"
	end_message = "<span class='boldannounce'>The snowfall dies down.</span>"


/datum/weather/snow_storm/freeze/telegraph()
	..()
	priority_announce("Incoming frozen vapors", "Anomaly Alert")

/datum/weather/acid_rain/cloud/end()
	..()
	priority_announce("The frozen vapors have passed", "Anomaly Alert")

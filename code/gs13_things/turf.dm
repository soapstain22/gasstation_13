/turf/open/misc/asteroid/gssurface
	name = "sand"
	baseturfs = /turf/open/openspace
	icon = 'icons/turf/floors.dmi'
	planetary_atmos = TRUE
	floor_variance = 40
	dig_result = /obj/item/stack/ore/glass/basalt
	initial_gas_mix =OPENTURF_DEFAULT_ATMOS
/turf/open/misc/asteroid/gs
	name = "sand"
	baseturfs = /turf/open/openspace
	icon = 'icons/turf/floors.dmi'
	planetary_atmos = FALSE
	floor_variance = 40
	dig_result = /obj/item/stack/ore/glass/basalt
	initial_gas_mix =OPENTURF_DEFAULT_ATMOS
/turf/open/misc/asteroid/bottom
	name = "sand"
	baseturfs = /turf/open/misc/asteroid/bottom
	icon = 'icons/turf/floors.dmi'
	planetary_atmos = FALSE
	floor_variance = 40
	dig_result = /obj/item/stack/ore/glass/basalt
	initial_gas_mix =OPENTURF_DEFAULT_ATMOS
/turf/closed/mineral/gs/bottom
	turf_type = /turf/open/misc/asteroid/bottom
	baseturfs = /turf/open/misc/asteroid/gs

/turf/closed/mineral/gs
	temperature=T20C
	turf_type = /turf/open/misc/asteroid/gs
	baseturfs = /turf/open/misc/asteroid/gs

/turf/closed/mineral/random/low_chance/gs
	temperature=T20C
	turf_type = /turf/open/misc/asteroid/gs
	baseturfs = /turf/open/misc/asteroid/gs

/turf/closed/mineral/random/gs
	temperature=T20C
	turf_type = /turf/open/misc/asteroid/gs
	baseturfs = /turf/open/misc/asteroid/gs
/turf/closed/mineral/random/high_chance/gs
	temperature=T20C
	turf_type = /turf/open/misc/asteroid/bottom
	baseturfs = /turf/open/misc/asteroid/bottom


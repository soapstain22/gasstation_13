//Colored pipes, use these for mapping

#define HELPER_PARTIAL(Fulltype, Iconbase, Color) \
	##Fulltype { \
		pipe_color = Color; \
		color = Color; \
	} \
	##Fulltype/visible { \
		hide = FALSE; \
		layer = GAS_PIPE_VISIBLE_LAYER; \
	} \
	##Fulltype/visible/layer2 { \
		piping_layer = 2; \
		icon_state = Iconbase + "-2"; \
	} \
	##Fulltype/visible/layer4 { \
		piping_layer = 4; \
		icon_state = Iconbase + "-4"; \
	} \
	##Fulltype/visible/layer1 { \
		piping_layer = 1; \
		icon_state = Iconbase + "-1"; \
	} \
	##Fulltype/visible/layer5 { \
		piping_layer = 5; \
		icon_state = Iconbase + "-5"; \
	} \
	##Fulltype/hidden { \
		hide = TRUE; \
	} \
	##Fulltype/hidden/layer2 { \
		piping_layer = 2; \
		icon_state = Iconbase + "-2"; \
	} \
	##Fulltype/hidden/layer4 { \
		piping_layer = 4; \
		icon_state = Iconbase + "-4"; \
	} \
	##Fulltype/hidden/layer1 { \
		piping_layer = 1; \
		icon_state = Iconbase + "-1"; \
	} \
	##Fulltype/hidden/layer5 { \
		piping_layer = 5; \
		icon_state = Iconbase + "-5"; \
	}

#define HELPER_PARTIAL_NAMED(Fulltype, Iconbase, Name, Color) \
	HELPER_PARTIAL(Fulltype, Iconbase, Color) \
	##Fulltype { \
		name = Name; \
	}

#define HELPER(Type, Color) \
	HELPER_PARTIAL(/obj/machinery/atmospherics/pipe/simple/##Type, "pipe11", Color) \
	HELPER_PARTIAL(/obj/machinery/atmospherics/pipe/manifold/##Type, "manifold", Color) \
	HELPER_PARTIAL(/obj/machinery/atmospherics/pipe/manifold4w/##Type, "manifold4w", Color) \
	HELPER_PARTIAL(/obj/machinery/atmospherics/pipe/smart/##Type, "manifold4w", Color) \
	HELPER_PARTIAL(/obj/machinery/atmospherics/pipe/layer_manifold/##Type, "manifoldlayer", Color) \
	HELPER_PARTIAL(/obj/effect/mapping_helpers/simple_pipes/##Type,"pipe",Color)

#define HELPER_NAMED(Type, Name, Color) \
	HELPER_PARTIAL_NAMED(/obj/machinery/atmospherics/pipe/simple/##Type, "pipe11", Name, Color) \
	HELPER_PARTIAL_NAMED(/obj/machinery/atmospherics/pipe/manifold/##Type, "manifold", Name, Color) \
	HELPER_PARTIAL_NAMED(/obj/machinery/atmospherics/pipe/manifold4w/##Type, "manifold4w", Name, Color) \
	HELPER_PARTIAL_NAMED(/obj/machinery/atmospherics/pipe/smart/##Type, "manifold4w", Name, Color) \
	HELPER_PARTIAL_NAMED(/obj/effect/mapping_helpers/simple_pipes/##Type,"pipe", Name, Color)

HELPER(general, rgb(254,254,254))
HELPER(cyan, rgb(0, 255, 249))
HELPER(green, rgb(30, 255, 0))
HELPER(orange, rgb(255, 129, 25))

HELPER_NAMED(scrubbers, "scrubbers pipe", rgb(255, 0, 0))
HELPER_NAMED(supply, "air supply pipe", rgb(0, 0, 255))

#undef HELPER_NAMED
#undef HELPER
#undef HELPER_PARTIAL_NAMED
#undef HELPER_PARTIAL

/obj/machinery/atmospherics/pipe/multiz/layer1
	piping_layer = 1
	icon_state = "adapter-1"
/obj/machinery/atmospherics/pipe/multiz/layer2
	piping_layer = 2
	icon_state = "adapter-2"
/obj/machinery/atmospherics/pipe/multiz/layer4
	piping_layer = 4
	icon_state = "adapter-4"
/obj/machinery/atmospherics/pipe/multiz/layer5
	piping_layer = 5
	icon_state = "adapter-5"

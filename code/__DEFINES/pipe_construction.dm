/*
PIPE CONSTRUCTION DEFINES
Update these any time a path is changed
Construction breaks otherwise
*/
/*
//Pipes
#define PIPE_SIMPLE				/obj/machinery/atmospherics/pipe/simple
#define PIPE_MANIFOLD			/obj/machinery/atmospherics/pipe/manifold
#define PIPE_4WAYMANIFOLD		/obj/machinery/atmospherics/pipe/manifold4w
#define PIPE_HE					/obj/machinery/atmospherics/pipe/heat_exchanging/simple
#define PIPE_HE_MANIFOLD		/obj/machinery/atmospherics/pipe/heat_exchanging/manifold
#define PIPE_HE_4WAYMANIFOLD	/obj/machinery/atmospherics/pipe/heat_exchanging/manifold4w
#define PIPE_JUNCTION			/obj/machinery/atmospherics/pipe/heat_exchanging/junction
#define PIPE_LAYER_MANIFOLD		/obj/machinery/atmospherics/pipe/layer_manifold
//Unary
#define PIPE_CONNECTOR			/obj/machinery/atmospherics/components/unary/portables_connector
#define PIPE_UVENT				/obj/machinery/atmospherics/components/unary/vent_pump
#define PIPE_SCRUBBER			/obj/machinery/atmospherics/components/unary/vent_scrubber
#define PIPE_INJECTOR			/obj/machinery/atmospherics/components/unary/outlet_injector
#define PIPE_HEAT_EXCHANGE		/obj/machinery/atmospherics/components/unary/heat_exchanger
//Binary
#define PIPE_PUMP				/obj/machinery/atmospherics/components/binary/pump
#define PIPE_PASSIVE_GATE		/obj/machinery/atmospherics/components/binary/passive_gate
#define PIPE_VOLUME_PUMP		/obj/machinery/atmospherics/components/binary/volume_pump
#define PIPE_MVALVE				/obj/machinery/atmospherics/components/binary/valve
#define PIPE_DVALVE				/obj/machinery/atmospherics/components/binary/valve/digital
//Trinary
#define PIPE_GAS_FILTER			/obj/machinery/atmospherics/components/trinary/filter
#define PIPE_GAS_MIXER			/obj/machinery/atmospherics/components/trinary/mixer
*/
//Construction Categories
#define PIPE_BINARY			0 //2 directions: N/S, E/W
#define PIPE_BENDABLE		1 //6 directions: N/S, E/W, N/E, N/W, S/E, S/W
#define PIPE_TRINARY		2 //4 directions: N/E/S, E/S/W, S/W/N, W/N/E
#define PIPE_TRIN_F			3 //8 directions: N->S+E, S->N+E, N->S+W, S->N+W, E->W+S, W->E+S, E->W+N, W->E+N
#define PIPE_DIRECTIONAL	4 //4 directions: N, S, E, W
#define PIPE_QUAD			5 //1 directions: N/S/E/W

#define SUBCAT_PIPE		"Pipes"
#define SUBCAT_DEVICE	"Devices"
#define SUBCAT_HEATEXCH	"Heat Exchange"

//Disposal piping numbers - do NOT hardcode these, use the defines
#define DISP_PIPE_STRAIGHT		0
#define DISP_PIPE_BENT			1
#define DISP_JUNCTION			2
#define DISP_JUNCTION_FLIP		3
#define DISP_YJUNCTION			4
#define DISP_END_TRUNK			5
#define DISP_END_BIN			6
#define DISP_END_OUTLET			7
#define DISP_END_CHUTE			8
#define DISP_SORTJUNCTION		9
#define DISP_SORTJUNCTION_FLIP	10

//Transit tubes
#define TRANSIT_TUBE_STRAIGHT			0
#define TRANSIT_TUBE_STRAIGHT_CROSSING	1
#define TRANSIT_TUBE_CURVED				2
#define TRANSIT_TUBE_DIAGONAL			3
#define TRANSIT_TUBE_DIAGONAL_CROSSING	4
#define TRANSIT_TUBE_JUNCTION			5
#define TRANSIT_TUBE_STATION			6
#define TRANSIT_TUBE_TERMINUS			7
#define TRANSIT_TUBE_POD				8

//the open status of the transit tube station
#define STATION_TUBE_OPEN		0
#define STATION_TUBE_OPENING	1
#define STATION_TUBE_CLOSED		2
#define STATION_TUBE_CLOSING	3

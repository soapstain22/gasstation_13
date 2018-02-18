/*
	Used with the various stat variables (mob, machines)
*/

//mob/var/stat things
#define CONSCIOUS	0
#define PRE_CRIT	1
#define SOFT_CRIT	2
#define UNCONSCIOUS	3
#define DEAD		4

// bitflags for machine stat variable
#define BROKEN		1
#define NOPOWER		2
#define MAINT		4			// under maintaince
#define EMPED		8		// temporary broken by EMP pulse

//ai power requirement defines
#define POWER_REQ_NONE 0
#define POWER_REQ_ALL 1
#define POWER_REQ_CLOCKCULT 2

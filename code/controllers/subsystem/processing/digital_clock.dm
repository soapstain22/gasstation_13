/// The subsystem used to tick digital clocks
PROCESSING_SUBSYSTEM_DEF(digital_clock)
	name = "digital_clock"
	flags = SS_NO_INIT|SS_BACKGROUND|SS_KEEP_TIMING
	wait = 1 SECONDS

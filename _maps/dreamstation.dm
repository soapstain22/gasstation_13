/*
The /tg/ codebase currently requires you to have 7 z-levels of the same size dimensions.
z-level order is important, the order you put them in inside this file will determine what z level number they are assigned ingame.
Names of z-level do not matter, but order does greatly, for instances such as checking alive status of revheads on z1

current as of 2014/11/24
z1 = station
z2 = centcomm
z3 = derelict telecomms satellite
z4 = derelict station
z5 = mining
z6 = empty space
z7 = empty space
*/

#if !defined(MAP_FILE)

        #include "map_files\DreamStation\dreamstation02.dmm"
        #include "map_files\DreamStation\z2.dmm"
        /*z2 is literally only edited because converyor belts don't play nice with shuttles TODO: fix that*/
        #include "map_files\generic\z3.dmm"
        #include "map_files\generic\z4.dmm"
        #include "map_files\DreamStation\z5.dmm"
        #include "map_files\generic\z6.dmm"
        #include "map_files\generic\z7.dmm"

        #define MAP_FILE "dreamstation02.dmm"
        #define MAP_NAME "DreamStation"

#elif !defined(MAP_OVERRIDE)

	#warn a map has already been included, ignoring DreamStation.

#endif

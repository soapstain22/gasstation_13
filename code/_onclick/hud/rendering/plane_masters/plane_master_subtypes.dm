/atom/movable/screen/plane_master/field_of_vision_blocker
	name = "Field of vision blocker"
	documentation = "This is one of those planes that's only used as a filter. It cuts out a portion of the game plate and does effects to it."
	plane = FIELD_OF_VISION_BLOCKER_PLANE
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	render_target = FIELD_OF_VISION_BLOCKER_RENDER_TARGET
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_relay_planes = list()
	// We do NOT allow offsetting, because there's no case where you would want to block only one layer, at least currently
	allows_offsetting = FALSE
	allow_rendering_in_place = FALSE
	// We mark as multiz_scaled FALSE so transforms don't effect us, and we draw to the planes below us as if they were us.
	// This is safe because we will ALWAYS be on the top z layer, so it DON'T MATTER
	multiz_scaled = FALSE

/atom/movable/screen/plane_master/field_of_vision_blocker/show_to(mob/mymob)
	. = ..()
	if(!. || !mymob)
		return .
	RegisterSignal(mymob, SIGNAL_ADDTRAIT(TRAIT_FOV_APPLIED), PROC_REF(fov_enabled), override = TRUE)
	RegisterSignal(mymob, SIGNAL_REMOVETRAIT(TRAIT_FOV_APPLIED), PROC_REF(fov_disabled), override = TRUE)
	if(HAS_TRAIT(mymob, TRAIT_FOV_APPLIED))
		fov_enabled(mymob)
	else
		fov_disabled(mymob)

/atom/movable/screen/plane_master/field_of_vision_blocker/proc/fov_enabled(mob/source)
	SIGNAL_HANDLER
	if(force_hidden == FALSE)
		return
	unhide_plane(source)

/atom/movable/screen/plane_master/field_of_vision_blocker/proc/fov_disabled(mob/source)
	SIGNAL_HANDLER
	hide_plane(source)

/atom/movable/screen/plane_master/clickcatcher
	name = "Click Catcher"
	documentation = "Contains the screen object we use as a backdrop to catch clicks on portions of the screen that would otherwise contain nothing else. \
		<br>Will always be below almost everything else"
	plane = CLICKCATCHER_PLANE
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	multiz_scaled = FALSE
	critical = PLANE_CRITICAL_DISPLAY

/atom/movable/screen/plane_master/clickcatcher/Initialize(mapload, datum/hud/hud_owner, datum/plane_master_group/home, offset)
	. = ..()
	RegisterSignal(SSmapping, COMSIG_PLANE_OFFSET_INCREASE, PROC_REF(offset_increased))
	offset_increased(SSmapping, 0, SSmapping.max_plane_offset)

/atom/movable/screen/plane_master/clickcatcher/proc/offset_increased(datum/source, old_off, new_off)
	SIGNAL_HANDLER
	// We only want need the lowest level
	// If my system better supported changing PM plane values mid op I'd do that, but I do NOT so
	if(new_off > offset)
		hide_plane(home?.our_hud?.mymob)

/atom/movable/screen/plane_master/parallax_white
	name = "Parallax whitifier"
	documentation = "Essentially a backdrop for the parallax plane. We're rendered just below it, so we'll be multiplied by its well, parallax.\
		<br>If you want something to look as if it has parallax on it, draw it to this plane."
	plane = PLANE_SPACE
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	render_relay_planes = list(RENDER_PLANE_GAME, LIGHT_MASK_PLANE)
	// We NEED to render this or emissives go fucky
	critical = PLANE_CRITICAL_DISPLAY

/atom/movable/screen/plane_master/parallax_white/Initialize(mapload, datum/hud/hud_owner, datum/plane_master_group/home, offset)
	. = ..()
	add_relay_to(GET_NEW_PLANE(EMISSIVE_RENDER_PLATE, offset), relay_layer = EMISSIVE_SPACE_LAYER, relay_color = GLOB.emissive_color)

/atom/movable/screen/plane_master/parallax_white/show_to(mob/mymob)
	. = ..()
	if(!.)
		return

	update_color()
	var/datum/hud/our_hud = home.our_hud
	if(isnull(our_hud))
		return
	RegisterSignals(our_hud, list(SIGNAL_ADDTRAIT(TRAIT_PARALLAX_ENABLED), SIGNAL_REMOVETRAIT(TRAIT_PARALLAX_ENABLED)), PROC_REF(update_color), override = TRUE)

// This is a bit hacky. We know parallax will always have something to render onto (cause emissives always render)
// But we want it to render in place if it's being masked regardless, so we gotta do this. :3
/atom/movable/screen/plane_master/parallax_white/retain_hidden_plane(mob/relevant)
	set_render_in_place(TRUE)
	update_color()
	return ..()

/atom/movable/screen/plane_master/parallax_white/restore_hidden_plane(mob/relevant)
	set_render_in_place(FALSE)
	update_color()
	return ..()

/atom/movable/screen/plane_master/parallax_white/proc/update_color()
	var/datum/hud/our_hud = home.our_hud
	if(isnull(our_hud))
		return

	var/turf/viewing_turf = get_turf(our_hud.mymob)	
	var/list/bottom_offsets = home.get_bottom_offsets()

	// We could do not do parallax for anything except the main plane group
	// This could be changed, but it would require refactoring parallax code
	if(HAS_TRAIT(our_hud, TRAIT_PARALLAX_ENABLED) && \
		home.key == PLANE_GROUP_MAIN && \
		viewing_turf && (hidden_by_distance == NOT_HIDDEN || bottom_offsets[offset + 1]))
		color = list(
			0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0,
			1, 1, 1, 1,
			0, 0, 0, 0
		)
	else
		color = initial(color)

///Contains space parallax
/atom/movable/screen/plane_master/parallax
	name = "Parallax"
	documentation = "Contains parallax, or to be more exact the screen objects that hold parallax.\
		<br>Note the BLEND_MULTIPLY. The trick here is how low our plane value is. Because of that, we draw below almost everything in the game.\
		<br>We abuse this to ensure we multiply against the Parallax whitifier plane, or space's plane. It's set to full white, so when you do the multiply you just get parallax out where it well, makes sense to be.\
		<br>Also notice that the parent parallax plane is mirrored down to all children. We want to support viewing parallax across all z levels at once."
	plane = PLANE_SPACE_PARALLAX
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	blend_mode = BLEND_MULTIPLY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	multiz_scaled = FALSE

/atom/movable/screen/plane_master/parallax/Initialize(mapload, datum/hud/hud_owner, datum/plane_master_group/home, offset)
	. = ..()
	if(offset != 0)
		// You aren't the source? don't change yourself
		return
	// The "home" parallax plate ALWAYS displays. ALWAYS
	critical = PLANE_CRITICAL_ALWAYS_DISPLAY
	RegisterSignal(SSmapping, COMSIG_PLANE_OFFSET_INCREASE, PROC_REF(on_offset_increase))
	RegisterSignal(SSdcs, COMSIG_NARSIE_SUMMON_UPDATE, PROC_REF(narsie_modified))
	if(GLOB.narsie_summon_count >= 1)
		narsie_start_midway(GLOB.narsie_effect_last_modified) // We assume we're on the start, so we can use this number
	offset_increase(0, SSmapping.max_plane_offset)

/atom/movable/screen/plane_master/parallax/show_to(mob/mymob)
	. = ..()
	if(!.)
		return

	var/datum/hud/our_hud = home.our_hud
	if(isnull(our_hud))
		return
	update_visibility()
	RegisterSignals(our_hud, list(SIGNAL_ADDTRAIT(TRAIT_PARALLAX_ENABLED), SIGNAL_REMOVETRAIT(TRAIT_PARALLAX_ENABLED)), PROC_REF(update_visibility), override = TRUE)

/atom/movable/screen/plane_master/parallax/proc/update_visibility()
	var/datum/hud/our_hud = home.our_hud
	var/mob/our_mob = our_hud?.mymob
	if(isnull(our_hud) || isnull(our_mob))
		return

	// We could do not do parallax for anything except the main plane group
	// This could be changed, but it would require refactoring this whole thing
	// And adding non client particular hooks for all the inputs, and I do not have the time I'm sorry :(
	if(HAS_TRAIT(our_hud, TRAIT_PARALLAX_ENABLED) && home.key == PLANE_GROUP_MAIN)
		if(!force_hidden)
			return
		unhide_plane(our_mob)
	else
		if(force_hidden)
			return
		hide_plane(our_mob)

/atom/movable/screen/plane_master/parallax/proc/on_offset_increase(datum/source, old_offset, new_offset)
	SIGNAL_HANDLER
	offset_increase(old_offset, new_offset)

/atom/movable/screen/plane_master/parallax/proc/offset_increase(old_offset, new_offset)
	// Parallax will be mirrored down to any new planes that are added, so it will properly render across mirage borders
	for(var/offset in old_offset to new_offset)
		if(offset != 0)
			// Overlay so we don't multiply twice, and thus fuck up our rendering
			add_relay_to(GET_NEW_PLANE(plane, offset), BLEND_OVERLAY)

/atom/movable/screen/plane_master/parallax/set_distance_from_owner(mob/relevant, new_distance, multiz_boundary, list/blocks)
	var/old_hidden = hidden_by_distance
	. = ..()
	if(.)
		// Don't draw to yourself bro
		if(offset == 0)
			return
		if(old_hidden == NOT_HIDDEN)
			return
		var/atom/movable/screen/plane_master/parent_parallax = home.get_plane(PLANE_SPACE_PARALLAX)
		// Clear away the blend multiply
		parent_parallax.remove_relay_from(plane)
		parent_parallax.add_relay_to(plane, BLEND_OVERLAY)
		return

	// If we can't render, and we aren't the bottom layer, don't render us
	// This way we only multiply against stuff that's fullwhite space
	var/list/bottom_offsets = home.get_bottom_offsets()
	var/atom/movable/screen/plane_master/parent_parallax = home.get_plane(PLANE_SPACE_PARALLAX)
	var/turf/viewing_turf = get_turf(relevant)
	if(!viewing_turf || !bottom_offsets[offset + 1])
		parent_parallax.remove_relay_from(plane)
	else
		parent_parallax.add_relay_to(plane, BLEND_MULTIPLY)

/atom/movable/screen/plane_master/parallax/retain_hidden_plane(mob/relevant)
	// The 0'th prallax plane always wants to render, but we do want to avoid drawing to our parent so let's yeet that
	if(offset != 0)
		return ..()
	remove_relay_from(GET_NEW_PLANE(RENDER_PLANE_GAME, 0))

/atom/movable/screen/plane_master/parallax/restore_hidden_plane(mob/relevant)
	if(offset != 0)
		return ..()
	add_relay_to(GET_NEW_PLANE(RENDER_PLANE_GAME, 0))

// This really only applies to the origional parallax and other parallax sources
// When we render at them and they're hidden, what we want is to render "as if" we were them
// So we want the relay to draw you feel me?
/atom/movable/screen/plane_master/parallax/should_hide_relay(target_plane)
	if(offset == 0 && PLANE_TO_TRUE(target_plane) == PLANE_SPACE_PARALLAX)
		return FALSE
	return TRUE

/// Starts the narsie animation midway, so we can catch up to everyone else quickly
/atom/movable/screen/plane_master/parallax/proc/narsie_start_midway(start_time)
	var/time_elapsed = world.time - start_time
	narsie_summoned_effect(max(16 SECONDS - time_elapsed, 0))

/// Starts the narsie animation, make us grey, then red
/atom/movable/screen/plane_master/parallax/proc/narsie_modified(datum/source, new_count)
	SIGNAL_HANDLER
	if(new_count >= 1)
		narsie_summoned_effect(16 SECONDS)
	else
		narsie_unsummoned()

/atom/movable/screen/plane_master/parallax/proc/narsie_summoned_effect(animate_time)
	if(GLOB.narsie_summon_count >= 2)
		var/static/list/nightmare_parallax = list(255,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,1, -130,0,0,0)
		animate(src, color = nightmare_parallax, time = animate_time)
		return

	var/static/list/grey_parallax = list(0.4,0.4,0.4,0, 0.4,0.4,0.4,0, 0.4,0.4,0.4,0, 0,0,0,1, -0.1,-0.1,-0.1,0)
	// We're gonna animate ourselves grey
	// Then, once it's done, about 40 seconds into the event itself, we're gonna start doin some shit. see below
	animate(src, color = grey_parallax, time = animate_time)

/atom/movable/screen/plane_master/parallax/proc/narsie_unsummoned()
	animate(src, color = null, time = 8 SECONDS)

/atom/movable/screen/plane_master/gravpulse
	name = "Gravpulse"
	documentation = "Ok so this one's fun. Basically, we want to be able to distort the game plane when a grav annom is around.\
		<br>So we draw the pattern we want to use to this plane, and it's then used as a render target by a distortion filter on the game plane.\
		<br>Note the blend mode and lack of relay targets. This plane exists only to distort, it's never rendered anywhere."
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = GRAVITY_PULSE_PLANE
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	blend_mode = BLEND_ADD
	render_target = GRAVITY_PULSE_RENDER_TARGET
	render_relay_planes = list()
	critical = PLANE_CRITICAL_DISPLAY
	// We start out hidden
	start_hidden = TRUE
	allow_rendering_in_place = FALSE

/atom/movable/screen/plane_master/gravpulse/Initialize(mapload, datum/hud/hud_owner, datum/plane_master_group/home, offset)
	. = ..()
	RegisterSignal(GLOB, SIGNAL_ADDTRAIT(TRAIT_DISTORTION_IN_USE(offset)), PROC_REF(distortion_enabled))
	RegisterSignal(GLOB, SIGNAL_REMOVETRAIT(TRAIT_DISTORTION_IN_USE(offset)), PROC_REF(distortion_disabled))
	if(HAS_TRAIT(GLOB, TRAIT_DISTORTION_IN_USE(offset)))
		distortion_enabled()

/atom/movable/screen/plane_master/gravpulse/proc/distortion_enabled(datum/source)
	SIGNAL_HANDLER
	var/mob/our_mob = home?.our_hud?.mymob
	unhide_plane(our_mob)

/atom/movable/screen/plane_master/gravpulse/proc/distortion_disabled(datum/source)
	SIGNAL_HANDLER
	var/mob/our_mob = home?.our_hud?.mymob
	hide_plane(our_mob)

///Contains just the floor
/atom/movable/screen/plane_master/floor
	name = "Floor"
	documentation = "The well, floor. This is mostly used as a sorting mechanism, but it also lets us create a \"border\" around the game world plane, so its drop shadow will actually work."
	plane = FLOOR_PLANE
	render_relay_planes = list(RENDER_PLANE_GAME, LIGHT_MASK_PLANE)

/atom/movable/screen/plane_master/transparent_floor
	name = "Transparent Floor"
	documentation = "Really just openspace, stuff that is a turf but has no color or alpha whatsoever.\
		<br>We use this to draw to just the light mask plane, cause if it's not there we get holes of blackness over openspace"
	plane = TRANSPARENT_FLOOR_PLANE
	render_relay_planes = list(LIGHT_MASK_PLANE)
	// Needs to be critical or it uh, it'll look white
	critical = PLANE_CRITICAL_DISPLAY
	allow_rendering_in_place = FALSE

/atom/movable/screen/plane_master/floor/Initialize(mapload, datum/hud/hud_owner, datum/plane_master_group/home, offset)
	. = ..()
	add_relay_to(GET_NEW_PLANE(EMISSIVE_RENDER_PLATE, offset), relay_layer = EMISSIVE_FLOOR_LAYER, relay_color = GLOB.em_block_color)

/atom/movable/screen/plane_master/wall
	name = "Wall"
	documentation = "Holds all walls. We render this onto the game world. Separate so we can use this + space and floor planes as a guide for where byond blackness is NOT."
	plane = WALL_PLANE
	render_relay_planes = list(RENDER_PLANE_GAME_WORLD, LIGHT_MASK_PLANE)

/atom/movable/screen/plane_master/wall/Initialize(mapload, datum/hud/hud_owner, datum/plane_master_group/home, offset)
	. = ..()
	add_relay_to(GET_NEW_PLANE(EMISSIVE_RENDER_PLATE, offset), relay_layer = EMISSIVE_WALL_LAYER, relay_color = GLOB.em_block_color)

/atom/movable/screen/plane_master/game
	name = "Game"
	documentation = "Holds most non floor/wall things. Anything on this plane \"wants\" to interlayer depending on position."
	plane = GAME_PLANE
	render_relay_planes = list(RENDER_PLANE_GAME_WORLD)

/atom/movable/screen/plane_master/game_world_above
	name = "Upper Game"
	documentation = "For stuff you want to draw like the game plane, but not ever below its contents"
	plane = ABOVE_GAME_PLANE
	render_relay_planes = list(RENDER_PLANE_GAME_WORLD)

/atom/movable/screen/plane_master/seethrough
	name = "Seethrough"
	documentation = "Holds the seethrough versions (done using image overrides) of large objects. Mouse transparent, so you can click through them."
	plane = SEETHROUGH_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_relay_planes = list(RENDER_PLANE_GAME_WORLD)
	start_hidden = TRUE

/**
 * Plane master that byond will by default draw to
 * Shouldn't be used, exists to prevent people using plane 0
 * NOTE: If we used SEE_BLACKNESS on a map format that wasn't SIDE_MAP, this is where its darkness would land
 * This would allow us to control it and do fun things. But we can't because side map doesn't support it, so this is just a stub
 */
/atom/movable/screen/plane_master/default
	name = "Default"
	documentation = "This is quite fiddly, so bear with me. By default (in byond) everything in the game is rendered onto plane 0. It's the default plane. \
		<br>But, because we've moved everything we control off plane 0, all that's left is stuff byond internally renders. \
		<br>What I'd like to do with this is capture byond blackness by giving mobs the SEE_BLACKNESS sight flag. \
		<br>But we CAN'T because SEE_BLACKNESS does not work with our rendering format. So I just eat it I guess"
	plane = DEFAULT_PLANE
	multiz_scaled = FALSE
	start_hidden = TRUE // Doesn't DO anything, exists to hold this place

/atom/movable/screen/plane_master/area
	name = "Area"
	documentation = "Holds the areas themselves, which ends up meaning it holds any overlays/effects we apply to areas. NOT snow or rad storms, those go on above lighting"
	plane = AREA_PLANE

/atom/movable/screen/plane_master/massive_obj
	name = "Massive object"
	documentation = "Huge objects need to render above everything else on the game plane, otherwise they'd well, get clipped and look not that huge. This does that."
	plane = MASSIVE_OBJ_PLANE

/atom/movable/screen/plane_master/point
	name = "Point"
	documentation = "I mean like, what do you want me to say? Points draw over pretty much everything else, so they get their own plane. Remember we layer render relays to draw planes in their proper order on render plates."
	plane = POINT_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

///Contains all turf lighting
/atom/movable/screen/plane_master/turf_lighting
	name = "Turf Lighting"
	documentation = "Contains all lighting drawn to turfs. Not so complex, draws directly onto the lighting plate."
	plane = LIGHTING_PLANE
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	render_relay_planes = list(RENDER_PLANE_LIGHTING)
	blend_mode = BLEND_ADD
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	// Space draws onto the lighting plane on all z layers for... reasons
	// So we need to always catch it, and just not display if we're above
	critical = PLANE_CRITICAL_ALWAYS_DISPLAY
	// Then we'll just prevent it from rendering, and we vibe
	allow_rendering_in_place = FALSE

/// This will not work through multiz, because of a byond bug with BLEND_MULTIPLY
/// Bug report is up, waiting on a fix
/atom/movable/screen/plane_master/o_light_visual
	name = "Overlight light visual"
	documentation = "Holds overlay lighting objects, or the sort of lighting that's a well, overlay stuck to something.\
		<br>Exists because lighting updating is really slow, and movement needs to feel smooth.\
		<br>We draw to the game plane, and mask out space for ourselves on the lighting plane so any color we have has the chance to display."
	plane = O_LIGHTING_VISUAL_PLANE
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	render_target = O_LIGHTING_VISUAL_RENDER_TARGET
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	blend_mode = BLEND_MULTIPLY
	critical = PLANE_CRITICAL_DISPLAY

/atom/movable/screen/plane_master/above_lighting
	name = "Above lighting"
	plane = ABOVE_LIGHTING_PLANE
	documentation = "Anything on the game plane that needs a space to draw on that will be above the lighting plane.\
		<br>Mostly little alerts and effects, also sometimes contains things that are meant to look as if they glow."

/**
 * Handles emissive overlays and emissive blockers.
 */
/atom/movable/screen/plane_master/emissive
	name = "Emissive"
	documentation = "Holds things that will be used to mask the lighting plane later on. Masked by the Emissive Mask plane to ensure we don't emiss out under a wall.\
		<br>Relayed onto the Emissive render plane to do the actual masking of lighting, since we need to be transformed and other emissive stuff needs to be transformed too.\
		<br>Don't want to double scale now."
	plane = EMISSIVE_PLANE
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_relay_planes = list(EMISSIVE_RENDER_PLATE)
	critical = PLANE_CRITICAL_DISPLAY

/atom/movable/screen/plane_master/pipecrawl
	name = "Pipecrawl"
	documentation = "Holds pipecrawl images generated during well, pipecrawling.\
		<br>Has a few effects and a funky color matrix designed to make things a bit more visually readable."
	plane = PIPECRAWL_IMAGES_PLANE
	start_hidden = TRUE

/atom/movable/screen/plane_master/pipecrawl/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	// Makes everything on this plane slightly brighter
	// Has a nice effect, makes thing stand out
	color = list(1.2,0,0,0, 0,1.2,0,0, 0,0,1.2,0, 0,0,0,1, 0,0,0,0)
	// This serves a similar purpose, I want the pipes to pop
	add_filter("pipe_dropshadow", 1, drop_shadow_filter(x = -1, y= -1, size = 1, color = COLOR_HALF_TRANSPARENT_BLACK))
	mirror_parent_hidden()

/atom/movable/screen/plane_master/camera_static
	name = "Camera static"
	documentation = "Holds camera static images. Usually only visible to people who can well, see static.\
		<br>We use images rather then vis contents because they're lighter on maptick, and maptick sucks butt."
	plane = CAMERA_STATIC_PLANE

/atom/movable/screen/plane_master/camera_static/show_to(mob/mymob)
	. = ..()
	if(!.)
		return
	var/datum/hud/our_hud = home.our_hud
	if(isnull(our_hud))
		return

	// We'll hide the slate if we're not seeing through a camera eye
	// This can call on a cycle cause we don't clear in hide_from
	// Yes this is the best way of hooking into the hud, I hate myself too
	RegisterSignal(our_hud, COMSIG_HUD_EYE_CHANGED, PROC_REF(eye_changed), override = TRUE)
	eye_changed(our_hud, null, our_hud.mymob?.canon_client?.eye)

/atom/movable/screen/plane_master/camera_static/proc/eye_changed(datum/hud/source, atom/old_eye, atom/new_eye)
	SIGNAL_HANDLER

	if(!isaicamera(new_eye))
		if(!force_hidden)
			hide_plane(source.mymob)
		return

	if(force_hidden)
		unhide_plane(source.mymob)

/atom/movable/screen/plane_master/high_game
	name = "High Game"
	documentation = "Holds anything that wants to be displayed above the rest of the game plane, and doesn't want to be clickable. \
		<br>This includes atmos debug overlays, blind sound images, and mining scanners. \
		<br>Really only exists for its layering potential, we don't use this for any vfx"
	plane = HIGH_GAME_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/plane_master/ghost
	name = "Ghost"
	documentation = "Ghosts draw here, so they don't get mixed up in the visuals of the game world. Note, this is not not how we HIDE ghosts from people, that's done with invisible and see_invisible."
	plane = GHOST_PLANE
	render_relay_planes = list(RENDER_PLANE_NON_GAME)

/atom/movable/screen/plane_master/fullscreen
	name = "Fullscreen"
	documentation = "Holds anything that applies to or above the full screen. \
		<br>Note, it's still rendered underneath hud objects, but this lets us control the order that things like death/damage effects render in."
	plane = FULLSCREEN_PLANE
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	render_relay_planes = list(RENDER_PLANE_NON_GAME)
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	allows_offsetting = FALSE

/atom/movable/screen/plane_master/runechat
	name = "Runechat"
	documentation = "Holds runechat images, that text that pops up when someone say something. Uses a dropshadow to well, look nice."
	plane = RUNECHAT_PLANE
	render_target = RUNECHAT_RENDER_TARGET
	render_relay_planes = list(RENDER_PLANE_NON_GAME)


/atom/movable/screen/plane_master/balloon_chat
	name = "Balloon chat"
	documentation = "Holds ballon chat images, those little text bars that pop up for a second when you do some things. NOT runechat."
	plane = BALLOON_CHAT_PLANE
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	render_relay_planes = list(RENDER_PLANE_NON_GAME)

/atom/movable/screen/plane_master/hud
	name = "HUD"
	documentation = "Contains anything that want to be rendered on the hud. Typically is just screen elements."
	plane = HUD_PLANE
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	render_relay_planes = list(RENDER_PLANE_NON_GAME)
	allows_offsetting = FALSE

/atom/movable/screen/plane_master/above_hud
	name = "Above HUD"
	documentation = "Anything that wants to be drawn ABOVE the rest of the hud. Typically close buttons and other elements that need to be always visible. Think preventing draggable action button memes."
	plane = ABOVE_HUD_PLANE
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	render_relay_planes = list(RENDER_PLANE_NON_GAME)
	allows_offsetting = FALSE

/atom/movable/screen/plane_master/splashscreen
	name = "Splashscreen"
	documentation = "Cinematics and the splash screen."
	plane = SPLASHSCREEN_PLANE
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	render_relay_planes = list(RENDER_PLANE_NON_GAME)
	allows_offsetting = FALSE

/atom/movable/screen/plane_master/escape_menu
	name = "Escape Menu"
	documentation = "Anything relating to the escape menu."
	plane = ESCAPE_MENU_PLANE
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	render_relay_planes = list(RENDER_PLANE_MASTER)
	allows_offsetting = FALSE

/atom/movable/screen/plane_master/escape_menu/show_to(mob/mymob)
	. = ..()
	if(!.)
		return
	var/datum/hud/our_hud = home.our_hud
	if(!our_hud)
		return
	RegisterSignal(our_hud, SIGNAL_ADDTRAIT(TRAIT_ESCAPE_MENU_OPEN), PROC_REF(escape_opened), override = TRUE)
	RegisterSignal(our_hud, SIGNAL_REMOVETRAIT(TRAIT_ESCAPE_MENU_OPEN), PROC_REF(escape_closed), override = TRUE)
	if(!HAS_TRAIT(our_hud, TRAIT_ESCAPE_MENU_OPEN))
		escape_closed()

/atom/movable/screen/plane_master/escape_menu/proc/escape_opened(datum/source)
	SIGNAL_HANDLER
	var/mob/our_mob = home?.our_hud?.mymob
	unhide_plane(our_mob)

/atom/movable/screen/plane_master/escape_menu/proc/escape_closed(datum/source)
	SIGNAL_HANDLER
	var/mob/our_mob = home?.our_hud?.mymob
	hide_plane(our_mob)

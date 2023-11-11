/// Creates a digital effect around the target
/datum/element/digital_aura
	/// The effect around the target
	var/mutable_appearance/glitch_effect
	/// Red effect
	var/mutable_appearance/redshift

/datum/element/digital_aura/Attach(datum/target)
	. = ..()
	if(!isatom(target))
		return ELEMENT_INCOMPATIBLE

	var/atom/thing = target
	var/base_icon
	var/dimensions = get_icon_dimensions(thing.icon)
	if(!length(dimensions))
		return ELEMENT_INCOMPATIBLE

	switch(dimensions["width"])
		if(32)
			base_icon = 'icons/effects/bitrunning.dmi'
		if(48)
			base_icon = 'icons/effects/bitrunning_48.dmi'
		if(64)
			base_icon = 'icons/effects/bitrunning_64.dmi'

	redshift = mutable_appearance(base_icon, "redshift")
	redshift.blend_mode = BLEND_MULTIPLY

	glitch_effect = mutable_appearance(base_icon, "glitch", MUTATIONS_LAYER, alpha = 150)

	thing.add_overlay(list(glitch_effect, redshift))
	thing.alpha = 210
	thing.set_light(2, l_color = LIGHT_COLOR_BUBBLEGUM, l_on = TRUE)
	thing.update_appearance()

/datum/element/digital_aura/Detach(datum/source)
	. = ..()
	var/atom/thing = source

	thing.cut_overlay(glitch_effect, redshift)
	thing.alpha = 255
	thing.set_light_on(FALSE)
	thing.update_appearance()


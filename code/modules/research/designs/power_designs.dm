////////////////////////////////////////
//////////////////Power/////////////////
////////////////////////////////////////

datum/design/basic_cell
	name = "Basic Power Cell"
	desc = "A basic power cell that holds 1000 units of energy."
	id = "basic_cell"
	req_tech = list("powerstorage" = 1)
	build_type = PROTOLATHE | AUTOLATHE |MECHFAB
	materials = list("$iron" = 700, "$glass" = 50)
	build_path = /obj/item/weapon/stock_parts/cell
	category = "Misc"

datum/design/high_cell
	name = "High-Capacity Power Cell"
	desc = "A power cell that holds 10000 units of energy."
	id = "high_cell"
	req_tech = list("powerstorage" = 2)
	build_type = PROTOLATHE | AUTOLATHE | MECHFAB
	materials = list("$iron" = 700, "$glass" = 60)
	build_path = /obj/item/weapon/stock_parts/cell/high
	category = "Misc"

datum/design/super_cell
	name = "Super-Capacity Power Cell"
	desc = "A power cell that holds 20000 units of energy."
	id = "super_cell"
	req_tech = list("powerstorage" = 3, "materials" = 2)
	reliability = 75
	build_type = PROTOLATHE | MECHFAB
	materials = list("$iron" = 700, "$glass" = 70)
	build_path = /obj/item/weapon/stock_parts/cell/super
	category = "Misc"

datum/design/hyper_cell
	name = "Hyper-Capacity Power Cell"
	desc = "A power cell that holds 30000 units of energy."
	id = "hyper_cell"
	req_tech = list("powerstorage" = 5, "materials" = 4)
	reliability = 70
	build_type = PROTOLATHE | MECHFAB
	materials = list("$iron" = 400, "$gold" = 150, "$silver" = 150, "$glass" = 70)
	build_path = /obj/item/weapon/stock_parts/cell/hyper
	category = "Misc"

datum/design/light_replacer
	name = "Light Replacer"
	desc = "A device to automatically replace lights. Refill with working lightbulbs."
	id = "light_replacer"
	req_tech = list("magnets" = 3, "materials" = 4)
	build_type = PROTOLATHE
	materials = list("$iron" = 1500, "$silver" = 150, "$glass" = 3000)
	build_path = /obj/item/device/lightreplacer

datum/design/pacman
	name = "Machine Design (PACMAN-type Generator Board)"
	desc = "The circuit board that for a PACMAN-type portable generator."
	id = "pacman"
	req_tech = list("programming" = 3, "plasmatech" = 3, "powerstorage" = 3, "engineering" = 3)
	build_type = IMPRINTER
	reliability = 79
	materials = list("$glass" = 1000, "sacid" = 20)
	build_path = /obj/item/weapon/circuitboard/pacman

datum/design/superpacman
	name = "Machine Design (SUPERPACMAN-type Generator Board)"
	desc = "The circuit board that for a SUPERPACMAN-type portable generator."
	id = "superpacman"
	req_tech = list("programming" = 3, "powerstorage" = 4, "engineering" = 4)
	build_type = IMPRINTER
	reliability = 76
	materials = list("$glass" = 1000, "sacid" = 20)
	build_path = /obj/item/weapon/circuitboard/pacman/super

datum/design/mrspacman
	name = "Machine Design (MRSPACMAN-type Generator Board)"
	desc = "The circuit board that for a MRSPACMAN-type portable generator."
	id = "mrspacman"
	req_tech = list("programming" = 3, "powerstorage" = 5, "engineering" = 5)
	build_type = IMPRINTER
	reliability = 74
	materials = list("$glass" = 1000, "sacid" = 20)
	build_path = /obj/item/weapon/circuitboard/pacman/mrs
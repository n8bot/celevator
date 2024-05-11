minetest.register_craft({
	output = "celevator:buffer_oil",
	recipe = {
		{"","basic_materials:steel_bar",""},
		{"default:steel_ingot","bucket:bucket_empty","default:steel_ingot"},
		{"default:steel_ingot","default:steel_ingot","default:steel_ingot"},
	},
})

minetest.register_craft({
	output = "celevator:buffer_rubber",
	recipe = {
		{"basic_materials:plastic_sheet","dye:black","basic_materials:plastic_sheet"},
		{"","default:steel_ingot",""},
		{"default:steel_ingot","default:steel_ingot","default:steel_ingot"},
	},
})

minetest.register_craft({
	output = "celevator:callbutton_both",
	recipe = {
		{"basic_materials:steel_strip","mesecons_lightstone:lightstone_blue_off","mesecons_button:button_off"},
		{"basic_materials:steel_strip","",""},
		{"basic_materials:steel_strip","mesecons_lightstone:lightstone_blue_off","mesecons_button:button_off"},
	},
})

minetest.register_craft({
	output = "celevator:callbutton_up",
	recipe = {
		{"basic_materials:steel_strip","mesecons_lightstone:lightstone_blue_off","mesecons_button:button_off"},
		{"basic_materials:steel_strip","",""},
		{"basic_materials:steel_strip","",""},
	},
})

minetest.register_craft({
	output = "celevator:callbutton_down",
	recipe = {
		{"basic_materials:steel_strip","",""},
		{"basic_materials:steel_strip","",""},
		{"basic_materials:steel_strip","mesecons_lightstone:lightstone_blue_off","mesecons_button:button_off"},
	},
})

minetest.register_craft({
	output = "celevator:car",
	recipe = {
		{"default:steel_ingot","default:steel_ingot","default:steel_ingot"},
		{"mesecons_button:button_off","celevator:hwdoor_glass","default:steel_ingot"},
		{"mesecons_switch:mesecon_switch_off","default:steel_ingot","default:steel_ingot"},
	},
})

minetest.register_craft({
	output = "celevator:controller",
	recipe = {
		{"basic_materials:steel_strip","basic_materials:ic","basic_materials:steel_strip"},
		{"basic_materials:steel_strip","basic_materials:ic","basic_materials:steel_strip"},
		{"basic_materials:steel_strip","default:steel_ingot","basic_materials:steel_strip"},
	},
})

minetest.register_craft({
	output = "celevator:dispatcher",
	recipe = {
		{"basic_materials:steel_strip","basic_materials:ic","basic_materials:steel_strip"},
		{"basic_materials:steel_strip","basic_materials:ic","basic_materials:steel_strip"},
		{"basic_materials:steel_strip","basic_materials:steel_strip","basic_materials:steel_strip"},
	},
})

minetest.register_craft({
	output = "celevator:drive",
	recipe = {
		{"basic_materials:silicon","basic_materials:steel_strip","basic_materials:silicon"},
		{"basic_materials:silicon","basic_materials:ic","basic_materials:silicon"},
		{"basic_materials:silicon","basic_materials:steel_strip","basic_materials:silicon"},
	},
})

minetest.register_craft({
	output = "celevator:digilines_io",
	recipe = {
		{"","",""},
		{"","basic_materials:ic",""},
		{"digilines:wire_std_00000000","basic_materials:steel_strip","digilines:wire_std_00000000"},
	},
})

minetest.register_craft({
	output = "celevator:mesecons_input_off",
	recipe = {
		{"","",""},
		{"","basic_materials:ic",""},
		{"mesecons:wire_00000000_off","basic_materials:steel_strip","basic_materials:steel_strip"},
	},
})

minetest.register_craft({
	output = "celevator:mesecons_output_off",
	recipe = {
		{"","",""},
		{"","basic_materials:ic",""},
		{"basic_materials:steel_strip","basic_materials:steel_strip","mesecons:wire_00000000_off"},
	},
})

minetest.register_craft({
	output = "celevator:fs1switch_off",
	recipe = {
		{"basic_materials:steel_strip","mesecons_lightstone:lightstone_red_off",""},
		{"basic_materials:steel_strip","mesecons_switch:mesecon_switch_off","dye:red"},
		{"basic_materials:steel_strip","",""},
	},
})

minetest.register_craft({
	output = "celevator:guide_rail 10",
	recipe = {
		{"basic_materials:steel_strip","default:steel_ingot","basic_materials:steel_strip"},
		{"basic_materials:steel_strip","default:steel_ingot","basic_materials:steel_strip"},
		{"basic_materials:steel_strip","default:steel_ingot","basic_materials:steel_strip"},
	},
})

minetest.register_craft({
	output = "celevator:guide_rail_bracket",
	recipe = {
		{"basic_materials:steel_strip","celevator:guide_rail","basic_materials:steel_strip"},
	},
})

minetest.register_craft({
	output = "celevator:hwdoor_glass",
	recipe = {
		{"basic_materials:steel_bar","basic_materials:steel_bar","basic_materials:steel_bar"},
		{"default:glass","basic_materials:steel_bar","default:glass"},
		{"basic_materials:steel_bar","basic_materials:steel_bar","basic_materials:steel_bar"},
	},
})

minetest.register_craft({
	output = "celevator:lantern_up",
	recipe = {
		{"basic_materials:steel_strip",""},
		{"basic_materials:steel_strip","mesecons_lightstone:lightstone_green_off"},
		{"basic_materials:steel_strip",""},
	},
})

minetest.register_craft({
	output = "celevator:lantern_down",
	recipe = {
		{"basic_materials:steel_strip",""},
		{"basic_materials:steel_strip","mesecons_lightstone:lightstone_red_off"},
		{"basic_materials:steel_strip",""},
	},
})

minetest.register_craft({
	output = "celevator:lantern_both",
	recipe = {
		{"basic_materials:steel_strip","mesecons_lightstone:lightstone_green_off"},
		{"basic_materials:steel_strip",""},
		{"basic_materials:steel_strip","mesecons_lightstone:lightstone_red_off"},
	},
})

minetest.register_craft({
	output = "celevator:lantern_vertical_up",
	type = "shapeless",
	recipe = {
		"celevator:lantern_up",
	},
})

minetest.register_craft({
	output = "celevator:lantern_vertical_down",
	type = "shapeless",
	recipe = {
		"celevator:lantern_down",
	},
})

minetest.register_craft({
	output = "celevator:lantern_vertical_both",
	type = "shapeless",
	recipe = {
		"celevator:lantern_both",
	},
})

minetest.register_craft({
	output = "celevator:lantern_up",
	type = "shapeless",
	recipe = {
		"celevator:lantern_vertical_up",
	},
})

minetest.register_craft({
	output = "celevator:lantern_down",
	type = "shapeless",
	recipe = {
		"celevator:lantern_vertical_down",
	},
})

minetest.register_craft({
	output = "celevator:lantern_both",
	type = "shapeless",
	recipe = {
		"celevator:lantern_vertical_both",
	},
})

minetest.register_craft({
	output = "celevator:machine",
	recipe = {
		{"basic_materials:gear_steel","basic_materials:copper_wire",""},
		{"basic_materials:steel_bar","basic_materials:steel_bar","basic_materials:motor"},
		{"default:steel_ingot","default:steel_ingot","default:steel_ingot"},
	},
})

minetest.register_craft({
	output = "celevator:pi",
	recipe = {
		{"basic_materials:steel_strip",""},
		{"mesecons_lightstone:lightstone_red_off","digilines:lcd"},
		{"basic_materials:steel_strip",""},
	},
})

minetest.register_craft({
	output = "celevator:pilantern_up",
	type = "shapeless",
	recipe = {
		"celevator:lantern_up",
		"celevator:pi",
	},
})

minetest.register_craft({
	output = "celevator:pilantern_down",
	type = "shapeless",
	recipe = {
		"celevator:lantern_down",
		"celevator:pi",
	},
})

minetest.register_craft({
	output = "celevator:pilantern_both",
	type = "shapeless",
	recipe = {
		"celevator:lantern_both",
		"celevator:pi",
	},
})

minetest.register_craft({
	output = "celevator:tape 15",
	recipe = {
		{"basic_materials:steel_strip","","basic_materials:steel_strip"},
		{"basic_materials:steel_strip","basic_materials:steel_strip","basic_materials:steel_strip"},
		{"basic_materials:steel_strip","","basic_materials:steel_strip"},
	},
})

minetest.register_craft({
	output = "celevator:tape_magnets",
	type = "shapeless",
	recipe = {
		"celevator:tape",
		"default:iron_lump",
		"basic_materials:plastic_sheet",
	},
})

minetest.register_craft({
	output = "celevator:tape_bracket",
	type = "shapeless",
	recipe = {
		"celevator:tape",
		"basic_materials:steel_strip",
	},
})

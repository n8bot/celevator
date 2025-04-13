local xcompat_available = minetest.global_exists("xcompat")
local m = xcompat_available and table.copy(xcompat.materials) or {}

-- provide required materials if xcompat is missing
if not xcompat_available then
	if minetest.get_modpath("default") then
		m.empty_bucket = "bucket:bucket_empty"
		m.iron_lump = "default:iron_lump"
		m.steel_ingot = "default:steel_ingot"
		m.glass = "default:glass"
		m.sandstone = "default:sandstone"
		m.copper_ingot = "default:copper_ingot"
		m.copper_block = "default:copperblock"
		m.gold_block = "default:goldblock"
		m.tin_block = "default:tinblock"
		m.mese = "default:mese"
		m.pick_steel = "default:pick_steel"
		m.torch = "default:torch"
	elseif minetest.get_modpath("mcl_core") then
		m.empty_bucket = "mcl_buckets:bucket_empty"
		m.iron_lump = "mcl_raw_ores:raw_iron"
		m.steel_ingot = "mcl_core:iron_ingot"
		m.glass = "mcl_core:glass"
		m.sandstone = "mcl_core:sandstone"
		m.copper_ingot = "mcl_copper:copper_ingot"
		m.copper_block = "mcl_copper:block"
		m.gold_block = "mcl_core:goldblock"
		m.tin_block = "mcl_core:ironblock"
		m.mese = "mesecons_torch:redstoneblock" -- mcla still carries this as an alias
		m.pick_steel = "mcl_core:pick_steel"
		m.torch = "mcl_torches:torch"
	else
		minetest.log("warning","[celevator] Unsupported game and xcompat not found, not registering craft recipes")
		return
	end
	if minetest.get_modpath("dye") then
		m.dye_black = "dye:black"
		m.dye_blue = "dye:blue"
		m.dye_red = "dye:red"
		m.dye_green = "dye:green"
	elseif minetest.get_modpath("mcl_dyes") then
		m.dye_black = "mcl_dyes:black"
		m.dye_blue = "mcl_dyes:blue"
		m.dye_red = "mcl_dyes:red"
		m.dye_green = "mcl_dyes:green"
	elseif minetest.get_modpath("mcl_dye") then
		m.dye_black = "mcl_dye:black"
		m.dye_blue = "mcl_dye:blue"
		m.dye_red = "mcl_dye:red"
		m.dye_green = "mcl_dye:green"
	end
end

if minetest.get_modpath("basic_materials") then
	m.steel_bar = "basic_materials:steel_bar"
	m.steel_strip = "basic_materials:steel_strip"
	m.steel_gear = "basic_materials:gear_steel"
	m.plastic_sheet = "basic_materials:plastic_sheet"
	m.silicon = "basic_materials:silicon"
	m.copper_wire = "basic_materials:copper_wire"
	m.ic = "basic_materials:ic"
	m.motor = "basic_materials:motor"
else
	m.steel_bar = m.gold_block
	m.steel_strip = m.gold_block
	m.steel_gear = m.gold_block
	m.plastic_sheet = m.tin_block
	m.silicon = m.sandstone
	m.copper_wire = m.copper_ingot
	m.ic = m.copper_block
	m.motor = m.pick_steel
end

-- vl mesecons has colored lightstone with different naming scheme
local mc_lightstone = minetest.registered_nodes["mesecons_lightstone:lightstone_blue_off"]
local vl_lightstone = minetest.registered_nodes["mesecons_lightstone:lightstone_off_blue"]
if mc_lightstone then
	-- real mesecons_lightstone
	m.lightstone_blue = "mesecons_lightstone:lightstone_blue_off"
	m.lightstone_green = "mesecons_lightstone:lightstone_green_off"
	m.lightstone_red = "mesecons_lightstone:lightstone_red_off"
	m.lightstone_white = "mesecons_lightstone:lightstone_white_off"
	m.lightstone_extra = ""
elseif vl_lightstone then
	-- vl mesecons_lightstone
	m.lightstone_blue = "mesecons_lightstone:lightstone_off_blue"
	m.lightstone_green = "mesecons_lightstone:lightstone_off_green"
	m.lightstone_red = "mesecons_lightstone:lightstone_off_red"
	m.lightstone_white = "mesecons_lightstone:lightstone_off_white"
	m.lightstone_extra = ""
else
	m.lightstone_blue = m.dye_blue
	m.lightstone_green = m.dye_green
	m.lightstone_red = m.dye_red
	m.lightstone_white = m.torch
	m.lightstone_extra = m.torch
end

local mesecons_button = minetest.registered_nodes["mesecons_button:button_off"]
if mesecons_button then
	-- real mesecons
	m.button = mesecons_button.name
elseif minetest.get_modpath("mcl_core") then
	m.button = "group:button"
else
	m.button = m.mese
end

if minetest.get_modpath("mesecons_switch") then
	-- real mesecons
	m.switch = "mesecons_switch:mesecon_switch_off"
elseif minetest.get_modpath("mcl_lever") then
	-- mcla
	m.switch = "mcl_lever:lever_off"
elseif minetest.get_modpath("mesecons_walllever") then
	-- other mcl
	m.switch = "mesecons_walllever:wall_lever_off"
else
	m.switch = m.mese
end

if minetest.get_modpath("digilines") then
	m.lcd = "digilines:lcd"
else
	m.lcd = m.mese
end

minetest.register_craft({
	output = "celevator:buffer_oil",
	recipe = {
		{"",m.steel_bar,""},
		{m.steel_ingot,m.empty_bucket,m.steel_ingot},
		{m.steel_ingot,m.steel_ingot,m.steel_ingot},
	},
})

minetest.register_craft({
	output = "celevator:buffer_rubber",
	recipe = {
		{m.plastic_sheet,m.dye_black,m.plastic_sheet},
		{"",m.steel_ingot,""},
		{m.steel_ingot,m.steel_ingot,m.steel_ingot},
	},
})

minetest.register_craft({
	output = "celevator:callbutton_both",
	recipe = {
		{m.steel_strip,m.lightstone_blue,m.button},
		{m.steel_strip,m.lightstone_extra,""},
		{m.steel_strip,m.lightstone_blue,m.button},
	},
})

minetest.register_craft({
	output = "celevator:callbutton_up",
	recipe = {
		{m.steel_strip,m.lightstone_blue,m.button},
		{m.steel_strip,m.lightstone_extra,""},
		{m.steel_strip,"",""},
	},
})

minetest.register_craft({
	output = "celevator:callbutton_down",
	recipe = {
		{m.steel_strip,"",""},
		{m.steel_strip,m.lightstone_extra,""},
		{m.steel_strip,m.lightstone_blue,m.button},
	},
})

minetest.register_craft({
	output = "celevator:car_standard",
	recipe = {
		{m.steel_ingot,m.steel_ingot,m.steel_ingot},
		{m.button,"celevator:hwdoor_glass",m.steel_ingot},
		{m.switch,m.steel_ingot,m.steel_ingot},
	},
})

minetest.register_craft({
	output = "celevator:car_glassback",
	recipe = {
		{m.steel_ingot,m.steel_ingot,m.steel_ingot},
		{m.button,"celevator:hwdoor_glass",m.glass},
		{m.switch,m.steel_ingot,m.steel_ingot},
	},
})

minetest.register_craft({
	output = "celevator:car_metal",
	recipe = {
		{"",m.steel_strip,""},
		{m.steel_strip,"celevator:car_standard",m.steel_strip},
		{"",m.steel_strip,""},
	},
})

minetest.register_craft({
	output = "celevator:car_metal_glassback",
	recipe = {
		{"",m.steel_strip,""},
		{m.steel_strip,"celevator:car_glassback",m.steel_strip},
		{"",m.steel_strip,""},
	},
})

minetest.register_craft({
	output = "celevator:controller",
	recipe = {
		{m.steel_strip,m.ic,m.steel_strip},
		{m.steel_strip,m.ic,m.steel_strip},
		{m.steel_strip,m.steel_ingot,m.steel_strip},
	},
})

minetest.register_craft({
	output = "celevator:dispatcher",
	recipe = {
		{m.steel_strip,m.ic,m.steel_strip},
		{m.steel_strip,m.ic,m.steel_strip},
		{m.steel_strip,m.steel_strip,m.steel_strip},
	},
})

minetest.register_craft({
	output = "celevator:drive",
	recipe = {
		{m.silicon,m.steel_strip,m.silicon},
		{m.silicon,m.ic,m.silicon},
		{m.silicon,m.steel_strip,m.silicon},
	},
})

minetest.register_craft({
	output = "celevator:digilines_io",
	recipe = {
		{"","",""},
		{"",m.ic,""},
		{"digilines:wire_std_00000000",m.steel_strip,"digilines:wire_std_00000000"},
	},
})

minetest.register_craft({
	output = "celevator:mesecons_input_off",
	recipe = {
		{"","",""},
		{"",m.ic,""},
		{"mesecons:wire_00000000_off",m.steel_strip,m.steel_strip},
	},
})

minetest.register_craft({
	output = "celevator:mesecons_output_off",
	recipe = {
		{"","",""},
		{"",m.ic,""},
		{m.steel_strip,m.steel_strip,"mesecons:wire_00000000_off"},
	},
})

minetest.register_craft({
	output = "celevator:fs1switch_off",
	recipe = {
		{m.steel_strip,m.lightstone_red,m.lightstone_extra},
		{m.steel_strip,m.switch,m.dye_red},
		{m.steel_strip,"",""},
	},
})

minetest.register_craft({
	output = "celevator:guide_rail 10",
	recipe = {
		{m.steel_strip,m.steel_ingot,m.steel_strip},
		{m.steel_strip,m.steel_ingot,m.steel_strip},
		{m.steel_strip,m.steel_ingot,m.steel_strip},
	},
})

minetest.register_craft({
	output = "celevator:guide_rail_bracket",
	recipe = {
		{m.steel_strip,"celevator:guide_rail",m.steel_strip},
	},
})

minetest.register_craft({
	output = "celevator:hwdoor_glass",
	recipe = {
		{m.steel_bar,m.steel_bar,m.steel_bar},
		{m.glass,m.steel_bar,m.glass},
		{m.steel_bar,m.steel_bar,m.steel_bar},
	},
})

minetest.register_craft({
	output = "celevator:hwdoor_steel",
	recipe = {
		{m.steel_bar,m.steel_bar,m.steel_bar},
		{m.steel_strip,m.steel_bar,m.steel_strip},
		{m.steel_bar,m.steel_bar,m.steel_bar},
	},
})

minetest.register_craft({
	output = "celevator:lantern_up",
	recipe = {
		{m.steel_strip,m.lightstone_green},
		{m.steel_strip,m.lightstone_extra},
		{m.steel_strip,""},
	},
})

minetest.register_craft({
	output = "celevator:lantern_down",
	recipe = {
		{m.steel_strip,""},
		{m.steel_strip,m.lightstone_extra},
		{m.steel_strip,m.lightstone_red},
	},
})

minetest.register_craft({
	output = "celevator:lantern_both",
	recipe = {
		{m.steel_strip,m.lightstone_green},
		{m.steel_strip,m.lightstone_extra},
		{m.steel_strip,m.lightstone_red},
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
		{m.steel_gear,m.copper_wire,""},
		{m.steel_bar,m.steel_bar,m.motor},
		{m.steel_ingot,m.steel_ingot,m.steel_ingot},
	},
})

minetest.register_craft({
	output = "celevator:pi",
	recipe = {
		{m.steel_strip,m.lightstone_extra},
		{m.lightstone_red,m.lcd},
		{m.steel_strip,m.lightstone_extra},
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
		{m.steel_strip,"",m.steel_strip},
		{m.steel_strip,m.steel_strip,m.steel_strip},
		{m.steel_strip,"",m.steel_strip},
	},
})

minetest.register_craft({
	output = "celevator:tape_magnets",
	type = "shapeless",
	recipe = {
		"celevator:tape",
		m.iron_lump,
		m.plastic_sheet,
	},
})

minetest.register_craft({
	output = "celevator:tape_bracket",
	type = "shapeless",
	recipe = {
		"celevator:tape",
		m.steel_strip,
	},
})

minetest.register_craft({
	output = "celevator:dbdkiosk",
	recipe = {
		{m.steel_strip,m.ic,m.glass},
		{m.steel_strip,m.lightstone_white,m.glass},
		{m.steel_strip,"",m.glass},
	},
})

minetest.register_craft({
	output = "celevator:genericswitch",
	recipe = {
		{m.steel_strip,"",""},
		{m.steel_strip,m.switch,m.dye_black},
		{m.steel_strip,"",""},
	},
})

minetest.register_craft({
	output = "celevator:governor",
	recipe = {
		{m.steel_strip,m.steel_bar,m.button},
		{m.steel_strip,m.steel_gear,m.steel_strip},
	},
})

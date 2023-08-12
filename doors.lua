minetest.register_node("celevator:hwdoor_fast_glass_bottom",{
	description = "Glass Hoistway Door (fast, bottom)",
	tiles = {
		"celevator_transparent.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_topbottom.png^[transformFY",
		"celevator_door_glass_topbottom.png^[transformFY",
	},
	groups = {
		dig_immediate = 2,
	},
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	use_texture_alpha = "clip",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0.4,0.5,0.5,0.5},
		},
	},
})

minetest.register_node("celevator:hwdoor_fast_glass_middle",{
	description = "Glass Hoistway Door (fast, middle)",
	tiles = {
		"celevator_transparent.png",
		"celevator_transparent.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_middle.png",
		"celevator_door_glass_middle.png",
	},
	groups = {
		dig_immediate = 2,
	},
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	use_texture_alpha = "clip",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0.4,0.5,0.5,0.5},
		},
	},
})

minetest.register_node("celevator:hwdoor_fast_glass_top",{
	description = "Glass Hoistway Door (fast, top)",
	tiles = {
		"celevator_door_glass_edge.png",
		"celevator_transparent.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_topbottom.png",
		"celevator_door_glass_topbottom.png",
	},
	groups = {
		dig_immediate = 2,
	},
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	use_texture_alpha = "clip",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0.4,0.5,0.5,0.5},
		},
	},
})

minetest.register_node("celevator:hwdoor_slow_glass_bottom",{
	description = "Glass Hoistway Door (slow, bottom)",
	tiles = {
		"celevator_transparent.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_topbottom.png^[transformFY",
		"celevator_door_glass_topbottom.png^[transformFY",
	},
	groups = {
		dig_immediate = 2,
	},
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	use_texture_alpha = "clip",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0.3,0.5,0.5,0.4},
		},
	},
})

minetest.register_node("celevator:hwdoor_slow_glass_middle",{
	description = "Glass Hoistway Door (slow, middle)",
	tiles = {
		"celevator_transparent.png",
		"celevator_transparent.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_middle.png",
		"celevator_door_glass_middle.png",
	},
	groups = {
		dig_immediate = 2,
	},
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	use_texture_alpha = "clip",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0.3,0.5,0.5,0.4},
		},
	},
})

minetest.register_node("celevator:hwdoor_slow_glass_top",{
	description = "Glass Hoistway Door (slow, top)",
	tiles = {
		"celevator_door_glass_edge.png",
		"celevator_transparent.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_topbottom.png",
		"celevator_door_glass_topbottom.png",
	},
	groups = {
		dig_immediate = 2,
	},
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	use_texture_alpha = "clip",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0.3,0.5,0.5,0.4},
		},
	},
})

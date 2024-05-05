minetest.register_node("celevator:buffer_rubber",{
	description = "Elevator Elastomeric Buffer",
	groups = {
		choppy = 1,
		bouncy = 60,
	},
	paramtype = "light",
	tiles = {
		"celevator_buffer_rubber_top.png",
		"celevator_cabinet_sides.png",
		"celevator_buffer_rubber_sides.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.2,-0.5,-0.2,0.2,-0.45,0.2},
			{-0.0625,-0.43,-0.0625,0.0625,0.1875,0.0625},
			{-0.125,0.1875,-0.125,-0.0625,0.35,0.125},
			{0.0625,0.1875,-0.125,0.125,0.35,0.125},
			{-0.0625,0.1875,-0.125,0.0625,0.35,-0.0625,},
			{-0.0625,0.1875,0.0625,0.0625,0.35,0.125,},
			{-0.125,-0.45,-0.125,0.125,-0.43,0.125},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.25,-0.5,-0.25,0.25,-0.4,0.25},
			{-0.15,-0.4,-0.15,0.15,0.4,0.15},
		},
	},
	collision_box = {
		type = "fixed",
		fixed = {
			{-0.25,-0.5,-0.25,0.25,-0.4,0.25},
			{-0.15,-0.4,-0.15,0.15,0.4,0.15},
		},
	},
})

minetest.register_node("celevator:buffer_oil",{
	description = "Elevator Oil-Filled Buffer",
	groups = {
		choppy = 1,
	},
	paramtype = "light",
	tiles = {
		"celevator_buffer_oil_lower_top.png",
		"celevator_cabinet_sides.png",
		"celevator_buffer_oil_lower_sides.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.2,-0.5,-0.2,0.2,-0.4375,0.2},
			{-0.094,-0.4375,-0.094,0.094,0.5,0.094},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.25,-0.5,-0.25,0.25,1.35,0.25},
		},
	},
	after_place_node = function(pos,placer)
		local node = minetest.get_node(pos)
		local toppos = {x=pos.x,y=pos.y + 1,z=pos.z}
		local topnode = minetest.get_node(toppos)
		local placername = placer:get_player_name()
		if topnode.name ~= "air" then
			if placer:is_player() then
				minetest.chat_send_player(placername,"Can't place buffer - no room for the top half!")
			end
			minetest.set_node(pos,{name="air"})
			return true
		end
		if minetest.is_protected(toppos,placername) and not minetest.check_player_privs(placername,{protection_bypass=true}) then
			if placer:is_player() then
				minetest.chat_send_player(placername,"Can't place buffer - top half is protected!")
				minetest.record_protection_violation(toppos,placername)
			end
			minetest.set_node(pos,{name="air"})
			return true
		end
		node.name = "celevator:buffer_oil_top"
		minetest.set_node(toppos,node)
	end,
	on_destruct = function(pos)
		pos.y = pos.y + 1
		local topnode = minetest.get_node(pos)
		if topnode.name == "celevator:buffer_oil_top" then
			minetest.set_node(pos,{name="air"})
		end
	end,
})

minetest.register_node("celevator:buffer_oil_top",{
	description = "Elevator Oil-Filled Buffer (top half - you hacker you!)",
	groups = {
		choppy = 1,
		not_in_creative_inventory = 1,
	},
	drop = "",
	paramtype = "light",
	tiles = {
		"celevator_buffer_oil_upper.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.063,-0.5,-0.063,0.063,0.3,0.063},
		},
	},
})

minetest.register_node("celevator:guide_rail",{
	description = "Elevator Guide Rail",
	groups = {
		choppy = 1,
	},
	paramtype = "light",
	paramtype2 = "4dir",
	tiles = {
		"celevator_guide_rail.png",
		"celevator_guide_rail.png",
		"celevator_guide_rail_edge.png^[transformFX",
		"celevator_guide_rail_edge.png",
		"celevator_guide_rail.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.015,-0.5,-0.48,0.015,0.5,-0.39},
			{-0.09,-0.5,-0.39,0.09,0.5,-0.38},
		},
	},
})

minetest.register_node("celevator:guide_rail_bracket",{
	description = "Elevator Guide Rail with Bracket",
	groups = {
		choppy = 1,
	},
	paramtype = "light",
	paramtype2 = "4dir",
	tiles = {
		"celevator_guide_rail.png",
		"celevator_guide_rail.png",
		"celevator_guide_rail_edge.png^[transformFX",
		"celevator_guide_rail_edge.png",
		"celevator_guide_rail.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.015,-0.5,-0.48,0.015,0.5,-0.39},
			{-0.09,-0.5,-0.39,0.09,0.5,-0.38},
			{-0.25,-0.1,-0.38,0.25,0.1,-0.35},
			{-0.28,-0.1,-0.38,-0.25,0.1,0.5},
			{0.25,-0.1,-0.38,0.28,0.1,0.5},
			{-0.5,-0.1,0.47,-0.28,0.1,0.5},
			{0.28,-0.1,0.47,0.5,0.1,0.5},
		},
	},
})

minetest.register_node("celevator:tape",{
	description = "Elevator Positioning System Tape",
	groups = {
		choppy = 1,
	},
	paramtype = "light",
	paramtype2 = "4dir",
	tiles = {
		"celevator_guide_rail.png",
		"celevator_guide_rail.png",
		"celevator_guide_rail.png",
		"celevator_guide_rail.png",
		"celevator_positioning_tape.png",
		"celevator_positioning_tape.png",
	},
	drawtype = "nodebox",
	use_texture_alpha = "clip",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.09,-0.5,-0.3,0.09,0.5,-0.299},
		},
	},
})

minetest.register_node("celevator:tape_magnets",{
	description = "Elevator Positioning System Tape with Magnets",
	groups = {
		choppy = 1,
	},
	paramtype = "light",
	paramtype2 = "4dir",
	tiles = {
		"celevator_guide_rail.png",
		"celevator_guide_rail.png",
		"celevator_guide_rail.png",
		"celevator_guide_rail.png",
		"celevator_positioning_tape.png",
		"celevator_positioning_tape_magnets.png",
	},
	drawtype = "nodebox",
	use_texture_alpha = "clip",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.09,-0.5,-0.3,0.09,0.5,-0.299},
		},
	},
})

minetest.register_node("celevator:tape_bracket",{
	description = "Elevator Positioning System Tape with Bracket",
	groups = {
		choppy = 1,
	},
	paramtype = "light",
	paramtype2 = "4dir",
	tiles = {
		"celevator_guide_rail.png",
		"celevator_guide_rail.png",
		"celevator_guide_rail.png",
		"celevator_guide_rail.png",
		"celevator_positioning_tape_bracket_back.png",
		"celevator_positioning_tape_bracket.png",
	},
	drawtype = "nodebox",
	use_texture_alpha = "clip",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.09,-0.5,-0.3,0.09,0.5,-0.299},
			{-0.5,-0.05,-0.3,0.12,0.08,-0.25},
			{-0.5,-0.05,-0.25,-0.45,0.08,0},
		},
	},
})

local pieces = {
	{
		_position = "000",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5,-0.6,-0.5,0.5,-0.5,0.5},
				{-0.5,-0.5,-0.5,-0.45,0.5,0.5},
				{-0.5,-1.5,-0.5,0.5,-0.6,-0.45},
			},
		},
		tiles = {
			"celevator_car_floor.png^celevator_door_sill_single.png",
			"celevator_car_bottom.png",
			"celevator_car_wallpaper.png^celevator_car_wall_bottom.png^celevator_car_switch_panel.png",
			"celevator_cabinet_sides.png^celevator_car_side_overlay.png^[transformR90",
			"celevator_cabinet_sides.png",
		},
		_keyswitches = true,
	},
	{
		_position = "001",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5,-0.6,-0.5,0.5,-0.5,0.5},
				{-0.5,-0.5,-0.5,-0.45,0.5,0.5},
			},
		},
		tiles = {
			"celevator_car_floor.png",
			"celevator_car_bottom_center.png",
			"celevator_car_wallpaper.png^celevator_car_wall_bottom.png^celevator_car_wall_vent.png",
			"celevator_cabinet_sides.png^celevator_car_side_center_overlay.png",
			"celevator_cabinet_sides.png",
		},
	},
	{
		_position = "002",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5,-0.6,-0.5,0.5,-0.5,0.5},
				{-0.5,-0.5,-0.5,-0.45,0.5,0.5},
				{-0.45,-0.5,0.45,0.5,0.5,0.5},
			},
		},
		use_texture_alpha = "clip",
		tiles = {
			"celevator_car_floor.png",
			"celevator_car_bottom.png",
			"celevator_car_wallpaper.png^celevator_car_wall_bottom.png",
			"celevator_cabinet_sides.png^celevator_car_side_overlay.png",
			"celevator_car_glass.png",
			"celevator_car_glass.png^celevator_car_wall_bottom.png",
		},
	},
	{
		_position = "100",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5,-0.6,-0.5,0.5,-0.5,0.5},
				{0.45,-0.5,-0.5,0.5,0.5,0.5},
				{-0.5,-1.5,-0.5,0.5,-0.6,-0.45},
			},
		},
		tiles = {
			"celevator_car_floor.png^celevator_door_sill_double.png",
			"celevator_car_bottom.png",
			"celevator_cabinet_sides.png^celevator_car_side_overlay.png",
			"celevator_car_wallpaper.png^celevator_car_wall_bottom.png",
			"celevator_cabinet_sides.png",
		},
	},
	{
		_position = "101",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5,-0.6,-0.5,0.5,-0.5,0.5},
				{0.45,-0.5,-0.5,0.5,0.5,0.5},
			},
		},
		tiles = {
			"celevator_car_floor.png",
			"celevator_car_bottom_center.png^[transformFX",
			"celevator_cabinet_sides.png^celevator_car_side_center_overlay.png",
			"celevator_car_wallpaper.png^celevator_car_wall_bottom.png^celevator_car_wall_vent.png",
			"celevator_cabinet_sides.png",
		},
	},
	{
		_position = "102",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5,-0.6,-0.5,0.5,-0.5,0.5},
				{0.45,-0.5,-0.5,0.5,0.5,0.5},
				{-0.5,-0.5,0.45,0.45,0.5,0.5},
			},
		},
		use_texture_alpha = "clip",
		tiles = {
			"celevator_car_floor.png",
			"celevator_car_bottom.png",
			"celevator_cabinet_sides.png^celevator_car_side_overlay.png^[transformR90",
			"celevator_car_wallpaper.png^celevator_car_wall_bottom.png",
			"celevator_car_glass.png",
			"celevator_car_glass.png^celevator_car_wall_bottom.png",
		},
	},
	{
		_position = "010",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5,-0.5,-0.5,-0.45,0.5,0.5},
			},
		},
		tiles = {
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
			"celevator_car_wallpaper_2x.png^celevator_cop.png",
			"celevator_cabinet_sides.png",
		},
		_cop = true,
	},
	{
		_position = "011",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5,-0.5,-0.5,-0.45,0.5,0.5},
			},
		},
		tiles = {
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
			"celevator_car_wallpaper.png^celevator_car_handrail_end.png",
			"celevator_cabinet_sides.png^celevator_car_side_center2_overlay.png",
			"celevator_cabinet_sides.png",
		},
	},
	{
		_position = "012",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5,-0.5,-0.5,-0.45,0.5,0.5},
				{-0.45,-0.5,0.45,0.5,0.5,0.5},
			},
		},
		use_texture_alpha = "clip",
		tiles = {
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
			"celevator_car_wallpaper.png^(celevator_car_handrail_end.png^[transformFX)",
			"celevator_cabinet_sides.png",
			"celevator_car_glass.png",
			"celevator_car_glass.png",
		},
	},
	{
		_position = "110",
		node_box = {
			type = "fixed",
			fixed = {
				{0.45,-0.5,-0.5,0.5,0.5,0.5},
			},
		},
		tiles = {
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
			"celevator_car_wallpaper.png^(celevator_car_handrail_end.png^[transformFX)",
			"celevator_cabinet_sides.png",
		},
	},
	{
		_position = "111",
		node_box = {
			type = "fixed",
			fixed = {
				{0.45,-0.5,-0.5,0.5,0.5,0.5},
			},
		},
		tiles = {
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png^celevator_car_side_center2_overlay.png",
			"celevator_car_wallpaper.png^celevator_car_handrail_center.png",
			"celevator_cabinet_sides.png",
		},
	},
	{
		_position = "112",
		node_box = {
			type = "fixed",
			fixed = {
				{0.45,-0.5,-0.5,0.5,0.5,0.5},
				{-0.5,-0.5,0.45,0.45,0.5,0.5},
			},
		},
		use_texture_alpha = "clip",
		tiles = {
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
			"celevator_car_wallpaper.png^celevator_car_handrail_end.png",
			"celevator_car_glass.png",
			"celevator_car_glass.png",
		},
	},
	{
		_position = "020",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5,0.5,-0.5,0.5,0.6,0.5},
				{-0.5,-0.5,-0.5,-0.45,0.5,0.5},
				{-0.5,0.6,-0.4,0.5,1,-0.1},
			},
		},
		tiles = {
			"celevator_cabinet_sides.png",
			"celevator_car_ceiling.png",
			"celevator_car_wallpaper.png",
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
			"celevator_dooroperator_left.png",
		},
		_pi = true,
	},
	{
		_position = "021",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5,0.5,-0.5,0.5,0.6,0.5},
				{-0.5,-0.5,-0.5,-0.45,0.5,0.5},
			},
		},
		tiles = {
			"celevator_cabinet_sides.png^celevator_car_top_center_overlay.png",
			"celevator_car_ceiling.png",
			"celevator_car_wallpaper.png",
			"celevator_cabinet_sides.png^celevator_car_side_center_overlay.png",
			"celevator_cabinet_sides.png",
		},
		_cartopbox = true,
	},
	{
		_position = "022",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5,0.5,-0.5,0.5,0.6,0.5},
				{-0.5,-0.5,-0.5,-0.45,0.5,0.5},
				{-0.45,-0.5,0.45,0.5,0.5,0.5},
			},
		},
		use_texture_alpha = "clip",
		tiles = {
			"celevator_cabinet_sides.png^celevator_car_top_hatch.png",
			"celevator_car_ceiling.png",
			"celevator_car_wallpaper.png",
			"celevator_cabinet_sides.png",
			"celevator_car_glass.png",
			"celevator_car_glass.png",
		},
	},
	{
		_position = "120",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5,0.5,-0.5,0.5,0.6,0.5},
				{0.45,-0.5,-0.5,0.5,0.5,0.5},
				{-0.5,0.6,-0.4,0.5,1,-0.1},
			},
		},
		tiles = {
			"celevator_cabinet_sides.png",
			"celevator_car_ceiling.png",
			"celevator_cabinet_sides.png",
			"celevator_car_wallpaper.png",
			"celevator_cabinet_sides.png",
			"celevator_dooroperator_right.png",
		},
	},
	{
		_position = "121",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5,0.5,-0.5,0.5,0.6,0.5},
				{0.45,-0.5,-0.5,0.5,0.5,0.5},
			},
		},
		tiles = {
			"celevator_cabinet_sides.png^celevator_car_top_center_overlay.png^[transformFX",
			"celevator_car_ceiling.png",
			"celevator_cabinet_sides.png^celevator_car_side_center_overlay.png",
			"celevator_car_wallpaper.png",
			"celevator_cabinet_sides.png",
		},
	},
	{
		_position = "122",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5,0.5,-0.5,0.5,0.6,0.5},
				{0.45,-0.5,-0.5,0.5,0.5,0.5},
				{-0.5,-0.5,0.45,0.45,0.5,0.5},
			},
		},
		use_texture_alpha = "clip",
		tiles = {
			"celevator_cabinet_sides.png^celevator_car_top_misc.png",
			"celevator_car_ceiling.png",
			"celevator_cabinet_sides.png",
			"celevator_car_wallpaper.png",
			"celevator_car_glass.png",
			"celevator_car_glass.png",
		},
		_tapehead = true,
	},
}

celevator.car.register("glassback",pieces,vector.new(2,3,3))


minetest.register_node("celevator:car_glassback",{
	description = "Glass-Back Elevator Car",
	paramtype2 = "4dir",
	buildable_to = true,
	inventory_image = "celevator_car_glassback_inventory.png",
	wield_image = "celevator_car_glassback_wield.png",
	wield_scale = vector.new(1,1,10),
	tiles = {"celevator_transparent.png"},
	after_place_node = function(pos,player)
		if not player:is_player() then
			minetest.remove_node(pos)
			return true
		end
		local name = player:get_player_name()
		local newnode = minetest.get_node(pos)
		local facedir = minetest.dir_to_yaw(minetest.fourdir_to_dir(newnode.param2))
		for x=0,1,1 do
			for y=0,2,1 do
				for z=0,2,1 do
					local offsetdesc = string.format("%dm to the right, %dm up, and %dm back",x,y,z)
					local placeoffset = vector.new(x,y,z)
					local placepos = vector.add(pos,vector.rotate_around_axis(placeoffset,vector.new(0,1,0),facedir))
					local replaces = minetest.get_node(placepos).name
					if not (minetest.registered_nodes[replaces] and minetest.registered_nodes[replaces].buildable_to) then
						minetest.chat_send_player(name,string.format("Can't place car here - position %s is blocked!",offsetdesc))
						minetest.remove_node(pos)
						return true
					end
					if minetest.is_protected(placepos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
						minetest.chat_send_player(name,string.format("Can't place car here - position %s is protected!",offsetdesc))
						minetest.record_protection_violation(placepos,name)
						minetest.remove_node(pos)
						return true
					end
				end
			end
		end
		for x=0,1,1 do
			for y=0,2,1 do
				for z=0,2,1 do
					local piecename = string.format("celevator:car_glassback_%d%d%d",x,y,z)
					local placeoffset = vector.new(x,y,z)
					local placepos = vector.add(pos,vector.rotate_around_axis(placeoffset,vector.new(0,1,0),facedir))
					minetest.set_node(placepos,{name=piecename,param2=newnode.param2})
				end
			end
		end
	end,
})

celevator.car.types.glassback.remove = function(rootpos,rootdir)
	local toberemoved = {
		["celevator:car_top_box"] = true,
		["celevator:incar_pi_entity"] = true,
		["celevator:car_door"] = true,
	}
	for x=0,1,1 do
		for y=0,2,1 do
			for z=0,2,1 do
				local piecename = string.format("celevator:car_glassback_%d%d%d",x,y,z)
				local pieceoffset = vector.new(x,y,z)
				local piecepos = vector.add(rootpos,vector.rotate_around_axis(pieceoffset,vector.new(0,1,0),rootdir))
				if minetest.get_node(piecepos).name == piecename then
					minetest.remove_node(piecepos)
					local erefs = minetest.get_objects_inside_radius(piecepos,0.5)
					for _,ref in pairs(erefs) do
						if ref:get_luaentity() and toberemoved[ref:get_luaentity().name] then
							ref:remove()
						end
					end
				end
			end
		end
	end
	local cartopboxpos = vector.add(rootpos,vector.rotate_around_axis(vector.new(0,3,1),vector.new(0,1,0),rootdir))
	local erefs = minetest.get_objects_inside_radius(cartopboxpos,0.5)
	for _,ref in pairs(erefs) do
		if ref:get_luaentity() and toberemoved[ref:get_luaentity().name] then
			ref:remove()
		end
	end
end

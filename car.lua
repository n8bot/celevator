celevator.car = {}

local function disambiguatebutton(pos,facedir,player)
	if player and not player.is_fake_player then
		local eyepos = vector.add(player:get_pos(),vector.add(player:get_eye_offset(),vector.new(0,1.5,0)))
		local lookdir = player:get_look_dir()
		local distance = vector.distance(eyepos,pos)
		local endpos = vector.add(eyepos,vector.multiply(lookdir,distance+1))
		local ray = minetest.raycast(eyepos,endpos,true,false)
		local pointed,button,hitpos
		repeat
			pointed = ray:next()
			if pointed and pointed.type == "node" then
				local node = minetest.get_node(pointed.under)
				if node.name == "celevator:car_021" then
					button = pointed.under
					hitpos = vector.subtract(pointed.intersection_point,button)
				end
			end
		until button or not pointed
		if not hitpos then return end
		hitpos = vector.rotate_around_axis(hitpos,vector.new(0,-1,0),minetest.dir_to_yaw(facedir)+(math.pi/2))
		if hitpos.y < 0.55 then return end
		if hitpos.z > 0.36 or hitpos.z < 0.09 then return end
		if hitpos.x >= -0.36 and hitpos.x <= -0.16 then
			return "inspectswitch"
		elseif hitpos.x > -0.16 and hitpos.x <= 0.03 then
			return "up"
		elseif hitpos.x > 0.03 and hitpos.x <= 0.2 then
			return "down"
		end
	end
end

local function updatecartopbox(pos)
	local toppos = vector.add(pos,vector.new(0,1.1,0))
	local entitiesnearby = minetest.get_objects_inside_radius(toppos,0.5)
	for _,i in pairs(entitiesnearby) do
		if i:get_luaentity() and i:get_luaentity().name == "celevator:car_top_box" then
			i:remove()
		end
	end
	local carmeta = minetest.get_meta(pos)
	local carid = carmeta:get_int("carid")
	if carid == 0 then return end
	local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
	if not carinfo then return end
	local entity = minetest.add_entity(pos,"celevator:car_top_box")
	local inspon = carinfo.cartopinspect
	entity:set_properties({
		wield_item = inspon and "celevator:car_top_box_on" or "celevator:car_top_box_off",
	})
	local fdir = minetest.fourdir_to_dir(minetest.get_node(pos).param2)
	fdir = vector.rotate_around_axis(fdir,vector.new(0,1,0),math.pi/2)
	entity:set_yaw(minetest.dir_to_yaw(fdir))
	entity:set_pos(toppos)
end

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
			"celevator_car_floor.png",
			"celevator_cabinet_sides.png",
			"celevator_car_wallpaper.png^celevator_car_wall_bottom.png^celevator_car_switch_panel.png",
			"celevator_cabinet_sides.png",
		},
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
			"celevator_cabinet_sides.png",
			"celevator_car_wallpaper.png^celevator_car_wall_bottom.png^celevator_car_wall_vent.png",
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
		tiles = {
			"celevator_car_floor.png",
			"celevator_cabinet_sides.png",
			"celevator_car_wallpaper.png^celevator_car_wall_bottom.png",
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
			"celevator_car_wallpaper.png^celevator_car_wall_bottom.png",
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
			"celevator_car_floor.png",
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
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
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
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
		tiles = {
			"celevator_car_floor.png",
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
			"celevator_car_wallpaper.png^celevator_car_wall_bottom.png",
			"celevator_cabinet_sides.png",
			"celevator_car_wallpaper.png^celevator_car_wall_bottom.png",
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
		tiles = {
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
			"celevator_car_wallpaper.png^(celevator_car_handrail_end.png^[transformFX)",
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
			"celevator_car_wallpaper.png^celevator_car_handrail_end.png",
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
			"celevator_cabinet_sides.png",
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
		tiles = {
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
			"celevator_car_wallpaper.png^celevator_car_handrail_end.png",
			"celevator_cabinet_sides.png",
			"celevator_car_wallpaper.png^(celevator_car_handrail_end.png^[transformFX)",
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
			"celevator_cabinet_sides.png",
			"celevator_car_ceiling.png",
			"celevator_car_wallpaper.png",
			"celevator_cabinet_sides.png",
		},
		on_rightclick = function(pos,node,clicker)
			local fdir = minetest.fourdir_to_dir(node.param2)
			local control = disambiguatebutton(pos,fdir,clicker)
			local meta = minetest.get_meta(pos)
			local carid = meta:get_int("carid")
			if carid == 0 then return end
			local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
			if not (carinfo and carinfo.controllerpos) then return end
			if control == "inspectswitch" then
				local boxpos = vector.add(pos,vector.new(0,1,0))
				local erefs = minetest.get_objects_inside_radius(boxpos,0.5)
				for _,ref in pairs(erefs) do
					if ref:get_luaentity().name == "celevator:car_top_box" then
						local state = ref:get_properties().wield_item
						if state == "celevator:car_top_box_off" then
							state = "celevator:car_top_box_on"
						elseif state == "celevator:car_top_box_on" then
							state = "celevator:car_top_box_off"
						end
						ref:set_properties({wield_item = state})
					end
				end
			end
			celevator.controller.handlecartopbox(carinfo.controllerpos,control)
		end,
		after_dig_node = function(pos)
			local toppos = vector.add(pos,vector.new(0,1.1,0))
			local entitiesnearby = minetest.get_objects_inside_radius(toppos,0.5)
			for _,i in pairs(entitiesnearby) do
				if i:get_luaentity() and i:get_luaentity().name == "celevator:car_top_box" then
					i:remove()
				end
			end
		end,
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
		tiles = {
			"celevator_cabinet_sides.png",
			"celevator_car_ceiling.png",
			"celevator_car_wallpaper.png",
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
			"celevator_car_wallpaper.png",
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
			"celevator_cabinet_sides.png",
			"celevator_car_ceiling.png",
			"celevator_cabinet_sides.png",
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
		tiles = {
			"celevator_cabinet_sides.png",
			"celevator_car_ceiling.png",
			"celevator_cabinet_sides.png",
			"celevator_car_wallpaper.png",
			"celevator_cabinet_sides.png",
			"celevator_car_wallpaper.png",
		},
	},
}

for _,def in ipairs(pieces) do
	def.groups = {
		not_in_creative_inventory = 1,
		_celevator_car = 1,
	}
	local xp = tonumber(string.sub(def._position,1,1))
	local yp = tonumber(string.sub(def._position,2,2))
	local zp = tonumber(string.sub(def._position,3,3))
	if xp > 0 then
		def.groups._connects_xm = 1
	end
	if xp < 1 then
		def.groups._connects_xp = 1
	end
	if yp > 0 then
		def.groups._connects_ym = 1
	end
	if yp < 2 then
		def.groups._connects_yp = 1
	end
	if zp > 0 then
		def.groups._connects_zm = 1
	end
	if zp < 2 then
		def.groups._connects_zp = 1
	end
	def.paramtype = "light"
	def.paramtype2 = "4dir"
	def.drawtype = "nodebox"
	def.description = "Car "..def._position.." (you hacker you!)"
	def.light_source = 9
	def.drop = ""
	def.on_receive_fields = function(pos,_,fields,player)
		local meta = minetest.get_meta(pos)
		local carid = meta:get_int("carid")
		if carid == 0 then return end
		local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
		if not carinfo then return end
		local nname = minetest.get_node(pos).name
		if nname == "celevator:car_010" then
			local event = {
				type = "cop",
				fields = fields,
				player = player:get_player_name(),
			}
			celevator.controller.run(carinfo.controllerpos,event)
		elseif nname == "celevator:car_000" then
			if fields.quit then return end
			local name = player:get_player_name()
			if minetest.is_protected(pos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
				minetest.chat_send_player(name,"You don't have access to these switches.")
				minetest.record_protection_violation(pos,name)
				return
			end
			local event = {
				type = "copswitches",
				fields = fields,
				player = name,
			}
			celevator.controller.run(carinfo.controllerpos,event)
		end
	end
	if def._position == "000" then
		def.on_construct = function(pos)
			minetest.get_meta(pos):set_string("doorstate","closed")
		end
		def.on_punch = function(pos,_,player)
			if player.is_fake_player then return end
			local name = player:get_player_name()
			local sneak = player:get_player_control().sneak
			if not sneak then return end
			if minetest.is_protected(pos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
				minetest.record_protection_violation(pos,name)
				return
			end
			local hash = minetest.hash_node_position(pos)
			local fs = "formspec_version[7]size[6,4]"
			fs = fs.."label[0.5,1;Really remove this car?]"
			fs = fs.."button_exit[0.5,2;2,1;yes;Yes]"
			fs = fs.."button_exit[3,2;2,1;no;No]"
			minetest.show_formspec(name,string.format("celevator:remove_car_%d",hash),fs)
		end
	end
	minetest.register_node("celevator:car_"..def._position,def)
end

function celevator.car.spawncar(origin,yaw,carid)
	local right = vector.rotate_around_axis(vector.new(1,0,0),vector.new(0,1,0),yaw)
	local back = vector.rotate_around_axis(vector.new(0,0,1),vector.new(0,1,0),yaw)
	local up = vector.new(0,1,0)
	for x=0,1,1 do
		for y=0,2,1 do
			for z=0,2,1 do
				local pos = vector.copy(origin)
				pos = vector.add(pos,vector.multiply(right,x))
				pos = vector.add(pos,vector.multiply(back,z))
				pos = vector.add(pos,vector.multiply(up,y))
				local node = {
					name = string.format("celevator:car_%d%d%d",x,y,z),
					param2 = minetest.dir_to_fourdir(minetest.yaw_to_dir(yaw)),
				}
				minetest.set_node(pos,node)
				if carid then minetest.get_meta(pos):set_int("carid",carid) end
			end
		end
	end
end

minetest.register_abm({
	label = "Respawn in-car PI displays",
	nodenames = {"celevator:car_020"},
	interval = 1,
	chance = 1,
	action = function(pos)
		local entitiesnearby = minetest.get_objects_inside_radius(pos,0.5)
		for _,i in pairs(entitiesnearby) do
			if i:get_luaentity() and i:get_luaentity().name == "celevator:incar_pi_entity" then
				return
			end
		end
		local entity = minetest.add_entity(pos,"celevator:incar_pi_entity")
		local fdir = vector.rotate_around_axis(minetest.facedir_to_dir(minetest.get_node(pos).param2),vector.new(0,1,0),math.pi/2)
		local etex = celevator.pi.generatetexture(" --",false,false,false,true)
		entity:set_properties({
			textures = {etex},
		})
		entity:set_yaw(minetest.dir_to_yaw(fdir))
		entity:set_pos(vector.add(pos,vector.multiply(fdir,0.44)))
	end,
})

minetest.register_node("celevator:car_top_box_off",{
	description = "Car-top Inspection Box, Off State (you hacker you!)",
	drop = "",
	groups = {
		not_in_creative_inventory = 1,
	},
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.422,-0.5,0.086,0.414,-0.45,0.359},
		},
	},
	tiles = {
		"celevator_cartopinsp_off.png",
		"celevator_cabinet_sides.png",
	},
})

minetest.register_node("celevator:car_top_box_on",{
	description = "Car-top Inspection Box, On State (you hacker you!)",
	drop = "",
	groups = {
		not_in_creative_inventory = 1,
	},
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.422,-0.5,0.086,0.414,-0.45,0.359},
		},
	},
	tiles = {
		"celevator_cartopinsp_on.png",
		"celevator_cabinet_sides.png",
	},
})

minetest.register_entity("celevator:car_top_box",{
	initial_properties = {
		visual = "wielditem",
		visual_size = vector.new(0.667,0.667,0.667),
		wield_item = "celevator:car_top_box_off",
		static_save = false,
		pointable = false,
	},
})

minetest.register_abm({
	label = "Respawn car-top inspection boxes",
	nodenames = {"celevator:car_021"},
	interval = 1,
	chance = 1,
	action = updatecartopbox,
})

minetest.register_node("celevator:car",{
	description = "Elevator Car",
	paramtype2 = "4dir",
	buildable_to = true,
	inventory_image = "celevator_car_inventory.png",
	wield_image = "celevator_car_wield.png",
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
					local piecename = string.format("celevator:car_%d%d%d",x,y,z)
					local placeoffset = vector.new(x,y,z)
					local placepos = vector.add(pos,vector.rotate_around_axis(placeoffset,vector.new(0,1,0),facedir))
					minetest.set_node(placepos,{name=piecename,param2=newnode.param2})
				end
			end
		end
	end,
})

minetest.register_on_player_receive_fields(function(_,formname,fields)
	if string.sub(formname,1,21) ~= "celevator:remove_car_" then return false end
	if not fields.yes then return true end
	local hash = tonumber(string.sub(formname,22,-1))
	if not hash then return true end
	local rootpos = minetest.get_position_from_hash(hash)
	local rootdir = minetest.dir_to_yaw(minetest.fourdir_to_dir(minetest.get_node(rootpos).param2))
	local toberemoved = {
		["celevator:car_top_box"] = true,
		["celevator:incar_pi_entity"] = true,
		["celevator:car_door"] = true,
	}
	for x=0,1,1 do
		for y=0,2,1 do
			for z=0,2,1 do
				local piecename = string.format("celevator:car_%d%d%d",x,y,z)
				local pieceoffset = vector.new(x,y,z)
				local piecepos = vector.add(rootpos,vector.rotate_around_axis(pieceoffset,vector.new(0,1,0),rootdir))
				if minetest.get_node(piecepos).name == piecename then
					minetest.remove_node(piecepos)
					local erefs = minetest.get_objects_inside_radius(piecepos,0.5)
					for _,ref in pairs(erefs) do
						if toberemoved[ref:get_luaentity().name] then
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
		if toberemoved[ref:get_luaentity().name] then
			ref:remove()
		end
	end
end)

celevator.car = {}

local function disambiguatecartopbutton(pos,facedir,player)
	if player and not player.is_fake_player then
		local eyepos = vector.add(player:get_pos(),vector.add(player:get_eye_offset(),vector.new(0,1.5,0)))
		local lookdir = player:get_look_dir()
		local distance = vector.distance(eyepos,pos)
		local endpos = vector.add(eyepos,vector.multiply(lookdir,distance+1))
		local ray = core.raycast(eyepos,endpos,true,false)
		local pointed,button,hitpos
		repeat
			pointed = ray:next()
			if pointed and pointed.type == "node" then
				local node = core.get_node(pointed.under)
				local ndef = core.registered_nodes[node.name] or {}
				if ndef._cartopbox then
					button = pointed.under
					hitpos = vector.subtract(pointed.intersection_point,button)
				end
			end
		until button or not pointed
		if not hitpos then return end
		hitpos = vector.rotate_around_axis(hitpos,vector.new(0,-1,0),core.dir_to_yaw(facedir)+(math.pi/2))
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
	local entitiesnearby = core.get_objects_inside_radius(toppos,0.5)
	for _,i in pairs(entitiesnearby) do
		if i:get_luaentity() and i:get_luaentity().name == "celevator:car_top_box" then
			i:remove()
		end
	end
	local carmeta = core.get_meta(pos)
	local carid = carmeta:get_int("carid")
	if carid == 0 then return end
	local carinfo = core.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
	if not carinfo then return end
	local entity = core.add_entity(pos,"celevator:car_top_box")
	local inspon = carinfo.cartopinspect
	entity:set_properties({
		wield_item = inspon and "celevator:car_top_box_on" or "celevator:car_top_box_off",
	})
	local fdir = core.fourdir_to_dir(core.get_node(pos).param2)
	fdir = vector.rotate_around_axis(fdir,vector.new(0,1,0),math.pi/2)
	entity:set_yaw(core.dir_to_yaw(fdir))
	entity:set_pos(toppos)
end

local held = {}

core.register_globalstep(function()
	for k,v in ipairs(held) do
		local player = core.get_player_by_name(v.name)
		if not (player and player:get_player_control()[v.button]) then
			table.remove(held,k)
			celevator.controller.handlecartopbox(v.pos,v.control.."_release")
		end
	end
end)

celevator.car.types = {}

function celevator.car.register(name,defs,size)
	celevator.car.types[name] = {
		size = size,
	}
	for _,def in ipairs(defs) do
		def._celevator_car_type = name
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
		if xp < size.x-1 then
			def.groups._connects_xp = 1
		end
		if yp > 0 then
			def.groups._connects_ym = 1
		end
		if yp < size.y-1 then
			def.groups._connects_yp = 1
		end
		if zp > 0 then
			def.groups._connects_zm = 1
		end
		if zp < size.z-1 then
			def.groups._connects_zp = 1
		end
		def.paramtype = "light"
		def.paramtype2 = "4dir"
		def.drawtype = "nodebox"
		def.description = "Car "..def._position.." (you hacker you!)"
		def.light_source = 9
		def.drop = ""
		if def._cop then
			def.on_receive_fields = function(pos,_,fields,player)
				local meta = core.get_meta(pos)
				local carid = meta:get_int("carid")
				if carid == 0 then return end
				local carinfo = core.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
				if not carinfo then return end
				local playername = player:get_player_name()
				local protected = core.is_protected(pos,playername) and not core.check_player_privs(playername,{protection_bypass=true})
				local event = {
					type = "cop",
					fields = fields,
					player = playername,
					protected = protected,
				}
				celevator.controller.run(carinfo.controllerpos,event)
			end
		elseif def._keyswitches then
			def.on_receive_fields = function(pos,_,fields,player)
				if fields.quit then return end
				local meta = core.get_meta(pos)
				local carid = meta:get_int("carid")
				if carid == 0 then return end
				local carinfo = core.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
				if not carinfo then return end
				local playername = player:get_player_name()
				if core.is_protected(pos,playername) and not core.check_player_privs(playername,{protection_bypass=true}) then
					core.chat_send_player(playername,"You don't have access to these switches.")
					core.record_protection_violation(pos,playername)
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
		if def._cartopbox then
			def.groups._celevator_car_spawnstopbox = 1
			def.on_rightclick = function(pos,node,clicker)
				local playername = clicker:get_player_name()
				for _,v in ipairs(held) do
					if playername == v.name then return end
				end
				local fdir = core.fourdir_to_dir(node.param2)
				local control = disambiguatecartopbutton(pos,fdir,clicker)
				if not control then return end
				local meta = core.get_meta(pos)
				local carid = meta:get_int("carid")
				if carid == 0 then return end
				local carinfo = core.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
				if not (carinfo and carinfo.controllerpos) then return end
				if control == "inspectswitch" then
					local boxpos = vector.add(pos,vector.new(0,1,0))
					local erefs = core.get_objects_inside_radius(boxpos,0.5)
					for _,ref in pairs(erefs) do
						if ref:get_luaentity() and ref:get_luaentity().name == "celevator:car_top_box" then
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
				table.insert(held,{
					pos = carinfo.controllerpos,
					name = playername,
					button = "place",
					control = control,
				})
			end
			def.after_dig_node = function(pos)
				local toppos = vector.add(pos,vector.new(0,1.1,0))
				local entitiesnearby = core.get_objects_inside_radius(toppos,0.5)
				for _,i in pairs(entitiesnearby) do
					if i:get_luaentity() and i:get_luaentity().name == "celevator:car_top_box" then
						i:remove()
					end
				end
			end
		end
		if def._pi then
			def.groups._celevator_car_spawnspi = 1
		end
		if def._tapehead then
			def.groups._celevator_car_spawnstapehead = 1
		end
		if def._position == "000" then
			def.groups._celevator_car_root = 1
			def._root = true
			def.on_construct = function(pos)
				core.get_meta(pos):set_string("doorstate","closed")
			end
			def.on_punch = function(pos,_,player)
				if player.is_fake_player then return end
				local playername = player:get_player_name()
				local sneak = player:get_player_control().sneak
				if not sneak then return end
				if core.is_protected(pos,playername) and not core.check_player_privs(playername,{protection_bypass=true}) then
					core.record_protection_violation(pos,playername)
					return
				end
				local hash = core.hash_node_position(pos)
				local fs = "formspec_version[7]size[6,4]"
				fs = fs.."label[0.5,1;Really remove this car?]"
				fs = fs.."button_exit[0.5,2;2,1;yes;Yes]"
				fs = fs.."button_exit[3,2;2,1;no;No]"
				core.show_formspec(playername,string.format("celevator:remove_car_%d",hash),fs)
			end
			def.on_timer = function(pos)
				local carid = core.get_meta(pos):get_int("carid")
				local carinfo = core.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
				if not (carinfo and carinfo.controllerpos) then return end
				local yaw = core.dir_to_yaw(core.fourdir_to_dir(core.get_node(pos).param2))
				local positions = {
					vector.new(-0.25,-0.1,-0.5),
					vector.new(0.25,-0.1,-0.5),
					vector.new(0.75,-0.1,-0.5),
					vector.new(1.25,-0.1,-0.5),
				}
				local playerseen = false
				for _,searchpos in ipairs(positions) do
					local rotatedpos = vector.rotate_around_axis(searchpos,vector.new(0,1,0),yaw)
					local erefs = core.get_objects_inside_radius(vector.add(pos,rotatedpos),0.5)
					for _,ref in pairs(erefs) do
						if ref:is_player() then
							playerseen = true
							break
						end
					end
					if playerseen then break end
				end
				if playerseen then
					celevator.controller.run(carinfo.controllerpos,{
						type = "lightcurtain",
					})
				end
				return true
			end
		end
		core.register_node("celevator:car_"..name.."_"..def._position,def)
	end
end

function celevator.car.spawncar(origin,yaw,carid,name,doortype)
	if (not name) or name == "" then name = "standard" end
	local size = celevator.car.types[name].size
	local right = vector.rotate_around_axis(vector.new(1,0,0),vector.new(0,1,0),yaw)
	local back = vector.rotate_around_axis(vector.new(0,0,1),vector.new(0,1,0),yaw)
	local up = vector.new(0,1,0)
	for x=0,(size.x-1),1 do
		for y=0,(size.y-1),1 do
			for z=0,(size.z-1),1 do
				local pos = vector.copy(origin)
				pos = vector.add(pos,vector.multiply(right,x))
				pos = vector.add(pos,vector.multiply(back,z))
				pos = vector.add(pos,vector.multiply(up,y))
				local node = {
					name = string.format("celevator:car_%s_%d%d%d",name,x,y,z),
					param2 = core.dir_to_fourdir(core.yaw_to_dir(yaw)),
				}
				core.set_node(pos,node)
				local meta = core.get_meta(pos)
				if carid then meta:set_int("carid",carid) end
				meta:set_string("doortype",doortype or "glass")
			end
		end
	end
end

core.register_abm({
	label = "Respawn in-car PI displays",
	nodenames = {"group:_celevator_car_spawnspi"},
	interval = 1,
	chance = 1,
	action = function(pos)
		local entitiesnearby = core.get_objects_inside_radius(pos,0.5)
		for _,i in pairs(entitiesnearby) do
			if i:get_luaentity() and i:get_luaentity().name == "celevator:incar_pi_entity" then
				return
			end
		end
		local entity = core.add_entity(pos,"celevator:incar_pi_entity")
		local fdir = vector.rotate_around_axis(core.facedir_to_dir(core.get_node(pos).param2),vector.new(0,1,0),math.pi/2)
		local etex = celevator.pi.generatetexture(" --",false,false,false,true)
		entity:set_properties({
			textures = {etex},
		})
		entity:set_yaw(core.dir_to_yaw(fdir))
		entity:set_pos(vector.add(pos,vector.multiply(fdir,0.44)))
	end,
})

core.register_node("celevator:car_top_box_off",{
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

core.register_node("celevator:car_top_box_on",{
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

core.register_entity("celevator:car_top_box",{
	initial_properties = {
		visual = "wielditem",
		visual_size = vector.new(0.667,0.667,0.667),
		wield_item = "celevator:car_top_box_off",
		static_save = false,
		pointable = false,
		glow = core.LIGHT_MAX,
	},
})

core.register_abm({
	label = "Respawn car-top inspection boxes",
	nodenames = {"group:_celevator_car_spawnstopbox"},
	interval = 1,
	chance = 1,
	action = updatecartopbox,
})

core.register_on_player_receive_fields(function(_,formname,fields)
	if string.sub(formname,1,21) ~= "celevator:remove_car_" then return false end
	if not fields.yes then return true end
	local hash = tonumber(string.sub(formname,22,-1))
	if not hash then return true end
	local rootpos = core.get_position_from_hash(hash)
	local rootdef = core.registered_nodes[celevator.get_node(rootpos).name] or {}
	local cartype = rootdef._celevator_car_type
	if cartype and celevator.car.types[cartype] then
		local rootdir = core.dir_to_yaw(core.fourdir_to_dir(core.get_node(rootpos).param2))
		celevator.car.types[cartype].remove(rootpos,rootdir)
	end
end)

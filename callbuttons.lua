celevator.callbutton = {}

local function makebuttontex(dir,upon,downon)
	local tex = "[combine:64x64:0,0=celevator_cabinet_sides.png:32,0=celevator_cabinet_sides.png:0,32=celevator_cabinet_sides.png:32,32=celevator_cabinet_sides.png:22,24=celevator_callbutton_panel.png"
	if dir == "up" then
		tex = tex..":24,35=celevator_callbutton_up.png"
		if upon then
			tex = tex..":33,36=celevator_callbutton_light.png"
		end
	elseif dir == "down" then
		tex = tex..":24,35=celevator_callbutton_down.png"
		if downon then
			tex = tex..":33,36=celevator_callbutton_light.png"
		end
	elseif dir == "both" then
		tex = tex..":24,28=celevator_callbutton_up.png:24,43=celevator_callbutton_down.png"
		if upon then
			tex = tex..":33,29=celevator_callbutton_light.png"
		end
		if downon then
			tex = tex..":33,44=celevator_callbutton_light.png"
		end
	end
	return(tex)
end

local validstates = {
	{"up",false,false,"Up"},
	{"up",true,false,"Up"},
	{"down",false,false,"Down"},
	{"down",false,true,"Down"},
	{"both",false,false,"Up and Down"},
	{"both",true,false,"Up and Down"},
	{"both",false,true,"Up and Down"},
	{"both",true,true,"Up and Down"},
}

function celevator.callbutton.setlight(pos,dir,newstate)
	local node = celevator.get_node(pos)
	if minetest.get_item_group(node.name,"_celevator_callbutton") ~= 1 then return end
	if dir == "up" then
		if minetest.get_item_group(node.name,"_celevator_callbutton_has_up") ~= 1 then return end
		local lit = minetest.get_item_group(node.name,"_celevator_callbutton_up_lit") == 1
		if lit == newstate then return end
		local newname = "celevator:callbutton_"
		if minetest.get_item_group(node.name,"_celevator_callbutton_has_down") == 1 then
			newname = newname.."both"
		else
			newname = newname.."up"
		end
		if newstate then newname = newname.."_upon" end
		if minetest.get_item_group(node.name,"_celevator_callbutton_down_lit") == 1 then
			newname = newname.."_downon"
		end
		node.name = newname
		minetest.swap_node(pos,node)
	elseif dir == "down" then
		if minetest.get_item_group(node.name,"_celevator_callbutton_has_down") ~= 1 then return end
		local lit = minetest.get_item_group(node.name,"_celevator_callbutton_down_lit") == 1
		if lit == newstate then return end
		local newname = "celevator:callbutton_"
		if minetest.get_item_group(node.name,"_celevator_callbutton_has_up") == 1 then
			newname = newname.."both"
		else
			newname = newname.."down"
		end
		if minetest.get_item_group(node.name,"_celevator_callbutton_up_lit") == 1 then
			newname = newname.."_upon"
		end
		if newstate then newname = newname.."_downon" end
		node.name = newname
		minetest.swap_node(pos,node)
	end
end

local function disambiguatedir(pos,player)
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
				if node.name and (minetest.get_item_group(node.name,"_celevator_callbutton") == 1) then
					button = pointed.under
					hitpos = vector.subtract(pointed.intersection_point,button)
				end
			end
		until button or not pointed
		if not hitpos then return end
		hitpos.y = -1*hitpos.y
		hitpos.y = math.floor((hitpos.y+0.5)*64+0.5)+1
		return hitpos.y >= 40 and "down" or "up"
	end
end

for _,state in ipairs(validstates) do
	local boringside = "[combine:64x64:0,0=celevator_cabinet_sides.png:32,0=celevator_cabinet_sides.png:0,32=celevator_cabinet_sides.png:32,32=celevator_cabinet_sides.png"
	local nname = "celevator:callbutton_"..state[1]
	local dropname = nname
	if state[2] then nname = nname.."_upon" end
	if state[3] then nname = nname.."_downon" end
	local idle = not (state[2] or state[3])
	local description = string.format("%s Call Button%s",state[4],(idle and "" or " (on state, you hacker you!)"))
	minetest.register_node(nname,{
		description = description,
		groups = {
			dig_immediate = 2,
			not_in_creative_inventory = (idle and 0 or 1),
			_celevator_callbutton = 1,
			_celevator_callbutton_has_up = (state[1] == "down" and 0 or 1),
			_celevator_callbutton_has_down = (state[1] == "up" and 0 or 1),
			_celevator_callbutton_up_lit = (state[2] and 1 or 0),
			_celevator_callbutton_down_lit = (state[3] and 1 or 0),
		},
		drop = dropname,
		tiles = {
			boringside,
			boringside,
			boringside,
			boringside,
			boringside,
			makebuttontex(state[1],state[2],state[3])
		},
		paramtype = "light",
		paramtype2 = "facedir",
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.16,-0.37,0.475,0.17,0.13,0.5},
			},
		},
		after_place_node = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("formspec","formspec_version[7]size[8,5]field[0.5,0.5;7,1;carid;Car ID;]field[0.5,2;7,1;landing;Landing Number;]button[3,3.5;2,1;save;Save]")
		end,
		on_receive_fields = function(pos,_,fields)
			if tonumber(fields.carid) and tonumber(fields.landing) then
				local carid = tonumber(fields.carid)
				local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
				if not carinfo then return end
				table.insert(carinfo.callbuttons,{pos=pos,landing=tonumber(fields.landing)})
				celevator.storage:set_string(string.format("car%d",carid),minetest.serialize(carinfo))
				local meta = minetest.get_meta(pos)
				meta:set_int("carid",carid)
				meta:set_int("landing",tonumber(fields.landing))
				meta:set_string("formspec","")
			end
		end,
		on_destruct = function(pos)
			local meta = minetest.get_meta(pos)
			local carid = meta:get_int("carid")
			if carid == 0 then return end
			local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
			if not carinfo then return end
			for i,button in pairs(carinfo.callbuttons) do
				if vector.equals(pos,button.pos) then
					table.remove(carinfo.callbuttons,i)
					celevator.storage:set_string(string.format("car%d",carid),minetest.serialize(carinfo))
				end
			end
		end,
		on_rightclick = function(pos,_,clicker)
			local meta = minetest.get_meta(pos)
			local carid = meta:get_int("carid")
			if carid == 0 then return end
			local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
			if not carinfo then return end
			local controllerpos = carinfo.controllerpos
			local controllermeta = minetest.get_meta(controllerpos)
			if controllermeta:get_int("carid") ~= carid then return end
			local landing = meta:get_int("landing")
			if state[1] == "up" then
				celevator.controller.handlecallbutton(controllerpos,landing,"up")
			elseif state[1] == "down" then
				celevator.controller.handlecallbutton(controllerpos,landing,"down")
			elseif state[1] == "both" then
				local dir = disambiguatedir(pos,clicker)
				if dir == "up" then
					celevator.controller.handlecallbutton(controllerpos,landing,"up")
				elseif dir == "down" then
					celevator.controller.handlecallbutton(controllerpos,landing,"down")
				end
			end
		end,
	})
end

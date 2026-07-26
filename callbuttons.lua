celevator.callbutton = {}

local fscontext = {}

local S = core.get_translator("celevator")

local function showfs(pos,name)
	local nname = celevator.get_node(pos).name
	fscontext[name] = pos

	local fs = "formspec_version[10]size[4,6]"
	fs = fs.."background[0,0;4,6;celevator_callbutton_panel.png;true]"

	local uplit = core.get_item_group(nname,"_celevator_callbutton_up_lit") == 1
	local uptex = "celevator_callbutton_up.png"
	local uplittex = "[combine:17x9:0,0="..uptex..":9,1=celevator_callbutton_light.png"
	if uplit then uptex = uplittex end
	fs = fs.."image_button[0.75,1;2.5,1.25;"..uptex..";up;;false;false;"..uplittex.."]"

	local downlit = core.get_item_group(nname,"_celevator_callbutton_down_lit") == 1
	local downtex = "celevator_callbutton_down.png"
	local downlittex = "[combine:17x9:0,0="..downtex..":9,1=celevator_callbutton_light.png"
	if downlit then downtex = downlittex end
	fs = fs.."image_button[0.75,3.5;2.5,1.25;"..downtex..";down;;false;false;"..downlittex.."]"

	core.show_formspec(name,"celevator:call_button",fs)
end

core.register_on_player_receive_fields(function(player,formname,fields)
	if formname ~= "celevator:call_button" then
		return false
	end
	local name = player:get_player_name()
	local pos = fscontext[name]
	if not pos then return true end
	if fields.quit then
		fscontext[name] = nil
	elseif fields.up then
		local nname = celevator.get_node(pos).name
		if core.get_item_group(nname,"_celevator_callbutton_has_up") == 1 then
			core.registered_nodes["celevator:callbutton_up"].on_rightclick(pos)
		end
	elseif fields.down then
		local nname = celevator.get_node(pos).name
		if core.get_item_group(nname,"_celevator_callbutton_has_down") == 1 then
			core.registered_nodes["celevator:callbutton_down"].on_rightclick(pos)
		end
	end
	return true
end)

local function makebuttontex(dir,upon,downon,inventory)
	local tex = "[combine:64x64"..
	            ":0,0=celevator_cabinet_sides.png"..
	            ":32,0=celevator_cabinet_sides.png"..
	            ":0,32=celevator_cabinet_sides.png"..
	            ":32,32=celevator_cabinet_sides.png"..
	            ":22,24=celevator_callbutton_panel.png"
	if inventory then tex = "[combine:32x32:5,0=celevator_callbutton_panel.png" end
	if dir == "up" then
		if inventory then
			tex = tex..":7,11=celevator_callbutton_up.png"
		else
			tex = tex..":24,35=celevator_callbutton_up.png"
		end
		if upon then
			tex = tex..":33,36=celevator_callbutton_light.png"
		end
	elseif dir == "down" then
		if inventory then
			tex = tex..":7,11=celevator_callbutton_down.png"
		else
			tex = tex..":24,35=celevator_callbutton_down.png"
		end
		if downon then
			tex = tex..":33,36=celevator_callbutton_light.png"
		end
	elseif dir == "both" then
		if inventory then
			tex = tex..":7,4=celevator_callbutton_up.png:7,19=celevator_callbutton_down.png"
		else
			tex = tex..":24,28=celevator_callbutton_up.png:24,43=celevator_callbutton_down.png"
		end
		if upon then
			tex = tex..":33,29=celevator_callbutton_light.png"
		end
		if downon then
			tex = tex..":33,44=celevator_callbutton_light.png"
		end
	end
	return(tex)
end

local upname = S("Elevator Up Call Button")
local dnname = S("Elevator Down Call Button")
local bothname = S("Elevator Up and Down Call Buttons")
local onname = S("Elevator Call Button (on state - you hacker you!)")

local validstates = {
	{"up",false,false,upname},
	{"up",true,false,onname},
	{"down",false,false,dnname},
	{"down",false,true,onname},
	{"both",false,false,bothname},
	{"both",true,false,onname},
	{"both",false,true,onname},
	{"both",true,true,onname},
}

function celevator.callbutton.setlight(pos,dir,newstate)
	local node = celevator.get_node(pos)
	if core.get_item_group(node.name,"_celevator_callbutton") ~= 1 then return end
	if dir == "up" then
		if core.get_item_group(node.name,"_celevator_callbutton_has_up") ~= 1 then return end
		local lit = core.get_item_group(node.name,"_celevator_callbutton_up_lit") == 1
		if lit == newstate then return end
		local newname = "celevator:callbutton_"
		if core.get_item_group(node.name,"_celevator_callbutton_has_down") == 1 then
			newname = newname.."both"
		else
			newname = newname.."up"
		end
		if newstate then newname = newname.."_upon" end
		if core.get_item_group(node.name,"_celevator_callbutton_down_lit") == 1 then
			newname = newname.."_downon"
		end
		node.name = newname
		core.swap_node(pos,node)
	elseif dir == "down" then
		if core.get_item_group(node.name,"_celevator_callbutton_has_down") ~= 1 then return end
		local lit = core.get_item_group(node.name,"_celevator_callbutton_down_lit") == 1
		if lit == newstate then return end
		local newname = "celevator:callbutton_"
		if core.get_item_group(node.name,"_celevator_callbutton_has_up") == 1 then
			newname = newname.."both"
		else
			newname = newname.."down"
		end
		if core.get_item_group(node.name,"_celevator_callbutton_up_lit") == 1 then
			newname = newname.."_upon"
		end
		if newstate then newname = newname.."_downon" end
		node.name = newname
		core.swap_node(pos,node)
	end
	for name,contextpos in pairs(fscontext) do
		if vector.equals(pos,contextpos) then
			showfs(pos,name)
		end
	end
end

local function disambiguatedir(pos,player)
	if player and not player.is_fake_player then
		local name = player:get_player_name()
		local windowinfo = core.get_player_window_information(name)
		if windowinfo and windowinfo.touch_controls then
			showfs(pos,name)
		else
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
					if node.name and (core.get_item_group(node.name,"_celevator_callbutton") == 1) then
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
end

for _,state in ipairs(validstates) do
	local boringside = "[combine:64x64"..
	                   ":0,0=celevator_cabinet_sides.png"..
	                   ":32,0=celevator_cabinet_sides.png"..
	                   ":0,32=celevator_cabinet_sides.png"..
	                   ":32,32=celevator_cabinet_sides.png"
	local nname = "celevator:callbutton_"..state[1]
	local dropname = nname
	local light = 0
	if state[2] then
		nname = nname.."_upon"
		light = light + 5
	end
	if state[3] then
		nname = nname.."_downon"
		light = light + 5
	end
	local idle = not (state[2] or state[3])
	local description = state[4]
	core.register_node(nname,{
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
		inventory_image = makebuttontex(state[1],state[2],state[3],true),
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
		light_source = light,
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.16,-0.37,0.475,0.17,0.13,0.5},
			},
		},
		after_place_node = function(pos)
			local meta = core.get_meta(pos)
			local idmsg = S("Car ID")
			local landingmsg = S("Landing Number")
			local savemsg = S("Save")
			local fs = "formspec_version[7]size[8,5]"
			fs = fs.."field[0.5,0.5;7,1;carid;"..idmsg..";]"
			fs = fs.."field[0.5,2;7,1;landing;"..landingmsg..";]"
			fs = fs.."button[3,3.5;2,1;save;"..savemsg.."]"
			meta:set_string("formspec",fs)
		end,
		on_receive_fields = function(pos,_,fields,player)
			if tonumber(fields.carid) and tonumber(fields.landing) then
				local carid = tonumber(fields.carid)
				local carinfo = core.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
				if not carinfo then return end
				local controllerpos = carinfo.controllerpos or carinfo.dispatcherpos
				local playername = player and player:get_player_name() or ""
				if core.is_protected(controllerpos,playername) and not core.check_player_privs(playername,{protection_bypass=true}) then
					core.record_protection_violation(controllerpos,playername)
					if carinfo.controllerpos then
						core.chat_send_player(playername,S("Can't connect to a controller you don't have access to."))
					else
						core.chat_send_player(playername,S("Can't connect to a dispatcher you don't have access to."))
					end
					return
				end
				table.insert(carinfo.callbuttons,{pos=pos,landing=tonumber(fields.landing)})
				celevator.storage:set_string(string.format("car%d",carid),core.serialize(carinfo))
				local meta = core.get_meta(pos)
				meta:set_int("carid",carid)
				meta:set_int("landing",tonumber(fields.landing))
				meta:set_string("formspec","")
			end
		end,
		on_destruct = function(pos)
			local meta = core.get_meta(pos)
			local carid = meta:get_int("carid")
			if carid == 0 then return end
			local carinfo = core.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
			if not carinfo then return end
			for i,button in pairs(carinfo.callbuttons) do
				if vector.equals(pos,button.pos) then
					table.remove(carinfo.callbuttons,i)
					celevator.storage:set_string(string.format("car%d",carid),core.serialize(carinfo))
				end
			end
		end,
		on_rightclick = function(pos,_,clicker)
			local meta = core.get_meta(pos)
			local carid = meta:get_int("carid")
			if carid == 0 then return end
			local carinfo = core.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
			if not carinfo then return end
			local controllerpos = carinfo.controllerpos or carinfo.dispatcherpos
			local isdispatcher = carinfo.dispatcherpos
			if not controllerpos then return end
			local controllermeta = core.get_meta(controllerpos)
			if controllermeta:get_int("carid") ~= carid then return end
			local landing = meta:get_int("landing")
			if state[1] == "up" then
				if isdispatcher then
					celevator.dispatcher.handlecallbutton(controllerpos,landing,"up")
				else
					celevator.controller.handlecallbutton(controllerpos,landing,"up")
				end
			elseif state[1] == "down" then
				if isdispatcher then
					celevator.dispatcher.handlecallbutton(controllerpos,landing,"down")
				else
					celevator.controller.handlecallbutton(controllerpos,landing,"down")
				end
			elseif state[1] == "both" then
				local dir = disambiguatedir(pos,clicker)
				if dir == "up" then
					if isdispatcher then
						celevator.dispatcher.handlecallbutton(controllerpos,landing,"up")
					else
						celevator.controller.handlecallbutton(controllerpos,landing,"up")
					end
				elseif dir == "down" then
					if isdispatcher then
						celevator.dispatcher.handlecallbutton(controllerpos,landing,"down")
					else
						celevator.controller.handlecallbutton(controllerpos,landing,"down")
					end
				end
			end
		end,
	})
end

core.register_abm({
	label = "Check call buttons for missing/replaced controllers",
	nodenames = {"group:_celevator_callbutton",},
	interval = 15,
	chance = 1,
	action = function(pos)
		local meta = core.get_meta(pos)
		local carid = meta:get_int("carid")
		if not (carid and carid > 0) then return end --Not set up yet
		local carinfo = core.deserialize(celevator.storage:get_string("car"..carid))
		if not carinfo then
			meta:set_string("infotext",S("Error reading car information!\nPlease remove and replace this node."))
			return
		end
		local iscontroller = (carinfo.controllerpos and celevator.controller.iscontroller(carinfo.controllerpos))
		local isdispatcher = (carinfo.dispatcherpos and celevator.dispatcher.isdispatcher(carinfo.dispatcherpos))
		if not (iscontroller or isdispatcher) then
			meta:set_string("infotext",S("Controller/dispatcher is missing!\nPlease remove and replace this node."))
			return
		end
		local metacarid = 0
		if iscontroller then
			metacarid = celevator.get_meta(carinfo.controllerpos):get_int("carid")
		elseif isdispatcher then
			metacarid = celevator.get_meta(carinfo.dispatcherpos):get_int("carid")
		end
		if metacarid ~= carid then
			meta:set_string("infotext",S("Controller/dispatcher found but with incorrect ID!\nPlease remove and replace this node."))
		end
	end,
})

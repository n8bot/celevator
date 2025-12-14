celevator.fs1switch = {}

local S = core.get_translator("celevator")

local function maketex(switchpos,lit)
	local tex = "celevator_fs1switch_"..switchpos..".png"
	if lit then tex = tex.."^celevator_fs1switch_led.png" end
	return tex
end

local nodebox = {
	{-0.219,-0.198,0.475,0.214,0.464,0.5},
	{-0.188,-0.349,0.49,0.182,-0.229,0.5},
}

local function resetspring(pos)
	local node = core.get_node(pos)
	local offstates = {
		["celevator:fs1switch_reset"] = "celevator:fs1switch_off",
		["celevator:fs1switch_reset_lit"] = "celevator:fs1switch_off_lit",
	}
	if offstates[node.name] then
		node.name = offstates[node.name]
		core.swap_node(pos,node)
	end
end

local function rightclick(pos,node,player)
	if not (player and player:is_player()) then return end
	local meta = core.get_meta(pos)
	if meta:get_string("formspec") ~= "" then return end
	local name = player:get_player_name()
	if core.is_protected(pos,name) and not core.check_player_privs(name,{protection_bypass=true}) then
		core.chat_send_player(name,S("You don't have a key for this switch."))
		core.record_protection_violation(pos,name)
		return
	end
	if node.name == "celevator:fs1switch_off" then
		node.name = "celevator:fs1switch_on"
		core.swap_node(pos,node)
	elseif node.name == "celevator:fs1switch_on" then
		node.name = "celevator:fs1switch_reset"
		core.swap_node(pos,node)
		core.after(0.5,resetspring,pos)
	elseif node.name == "celevator:fs1switch_off_lit" or node.name == "celevator:fs1switch_on_lit" then
		node.name = "celevator:fs1switch_reset_lit"
		core.swap_node(pos,node)
		core.after(0.5,resetspring,pos)
	end
	local carid = meta:get_int("carid")
	if carid == 0 then return end
	local carinfo = core.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
	if not carinfo then return end
	local controllerpos = carinfo.controllerpos
	local dispatcher = false
	if not controllerpos then
		controllerpos = carinfo.dispatcherpos
		dispatcher = true
	end
	if not controllerpos then return end
	local controllermeta = core.get_meta(controllerpos)
	if controllermeta:get_int("carid") ~= carid then return end
	if node.name == "celevator:fs1switch_reset" or node.name == "celevator:fs1switch_reset_lit" then
		if dispatcher then
			celevator.dispatcher.handlefs1switch(controllerpos,false)
		else
			celevator.controller.handlefs1switch(controllerpos,false)
		end
	elseif node.name == "celevator:fs1switch_on" or node.name == "celevator:fs1switch_on_lit" then
		if dispatcher then
			celevator.dispatcher.handlefs1switch(controllerpos,true)
		else
			celevator.controller.handlefs1switch(controllerpos,true)
		end
	end
end

function celevator.fs1switch.setled(pos,on)
	local offstates = {
		["celevator:fs1switch_on_lit"] = "celevator:fs1switch_on",
		["celevator:fs1switch_off_lit"] = "celevator:fs1switch_off",
		["celevator:fs1switch_reset_lit"] = "celevator:fs1switch_reset",
	}
	local onstates = {
		["celevator:fs1switch_on"] = "celevator:fs1switch_on_lit",
		["celevator:fs1switch_off"] = "celevator:fs1switch_off_lit",
		["celevator:fs1switch_reset"] = "celevator:fs1switch_reset_lit",
	}
	local node = celevator.get_node(pos)
	if on and onstates[node.name] then
		node.name = onstates[node.name]
		core.swap_node(pos,node)
	elseif (not on) and offstates[node.name] then
		node.name = offstates[node.name]
		core.swap_node(pos,node)
	end
end

local function unpair(pos)
	local meta = core.get_meta(pos)
	local carid = meta:get_int("carid")
	if carid == 0 then return end
	local carinfo = core.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
	if not (carinfo and carinfo.fs1switches) then return end
	for i,fs1switch in pairs(carinfo.fs1switches) do
		if vector.equals(pos,fs1switch.pos) then
			table.remove(carinfo.fs1switches,i)
			celevator.storage:set_string(string.format("car%d",carid),core.serialize(carinfo))
		end
	end
end

local switchstates = {"off","on","reset"}

local descriptions = {
		off = S("Elevator Fire Service Phase 1 Keyswitch"),
		on = S("Elevator Fire Service Phase 1 Keyswitch (on state - you hacker you!)"),
		reset = S("Elevator Fire Service Phase 1 Keyswitch (reset state - you hacker you!)"),
		offlit = S("Elevator Fire Service Phase 1 Keyswitch (lit - you hacker you!)"),
		onlit = S("Elevator Fire Service Phase 1 Keyswitch (on state, lit - you hacker you!)"),
		resetlit = S("Elevator Fire Service Phase 1 Keyswitch (reset state, lit - you hacker you!)"),
}

for _,switchpos in ipairs(switchstates) do
	core.register_node("celevator:fs1switch_"..switchpos,{
		description = descriptions[switchpos],
		groups = {
			dig_immediate = 2,
			not_in_creative_inventory = (switchpos == "off" and 0 or 1),
			_celevator_fs1switch = 1,
		},
		inventory_image = "celevator_fs1switch_off.png",
		drop = "celevator:fs1switch_off",
		tiles = {
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
			maketex(switchpos,false),
		},
		paramtype = "light",
		paramtype2 = "facedir",
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = nodebox,
		},
		after_place_node = function(pos)
			local meta = core.get_meta(pos)
			meta:set_string("formspec","formspec_version[7]size[8,5]field[0.5,0.5;7,1;carid;"..S("Car ID")..";]button[3,3.5;2,1;save;"..S("Save").."]")
		end,
		on_receive_fields = function(pos,_,fields,player)
			local carid = tonumber(fields.carid or 0)
			if not (carid and carid >= 1 and carid == math.floor(carid)) then return end
			local carinfo = core.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
			if not carinfo then return end
			local controllerpos = carinfo.controllerpos or carinfo.dispatcherpos
			if not controllerpos then return end
			local name = player:get_player_name()
			if core.is_protected(controllerpos,name) and not core.check_player_privs(name,{protection_bypass=true}) then
				if player:is_player() then
					core.chat_send_player(name,S("Can't connect to a controller/dispatcher you don't have access to."))
					core.record_protection_violation(controllerpos,name)
				end
				return
			end
			if not carinfo.fs1switches then carinfo.fs1switches = {} end
			table.insert(carinfo.fs1switches,{pos=pos})
			celevator.storage:set_string(string.format("car%d",carid),core.serialize(carinfo))
			local meta = core.get_meta(pos)
			meta:set_int("carid",carid)
			meta:set_string("formspec","")
		end,
		on_rightclick = rightclick,
		on_destruct = unpair,
	})
	core.register_node("celevator:fs1switch_"..switchpos.."_lit",{
		description = descriptions[switchpos.."lit"],
		groups = {
			dig_immediate = 2,
			not_in_creative_inventory = 1,
			_celevator_fs1switch = 1,
		},
		drop = "celevator:fs1switch_off",
		tiles = {
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
			"celevator_cabinet_sides.png",
			maketex(switchpos,true),
		},
		paramtype = "light",
		paramtype2 = "facedir",
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = nodebox,
		},
		on_rightclick = rightclick,
		on_destruct = unpair,
	})
end

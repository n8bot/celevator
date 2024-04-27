local iorules = {
	vector.new(-1,0,0),
	vector.new(1,0,0),
	vector.new(0,0,-1),
	vector.new(0,0,1),
}

local function getpos(mem,searchpos,pioffset)
	local carpos = 0
	if not searchpos then searchpos = mem.drive.status.apos end
	if pioffset then searchpos = searchpos+0.5 end
	for k,v in ipairs(mem.params.floorheights) do
		carpos = carpos+v
		if carpos > searchpos then
			return k
		end
	end
end

local outputoptions = {
	{
		id = "normal",
		desc = "Normal Operation",
		func = function(mem)
			return (mem.carstate == "normal")
		end,
		needsfloor = false,
	},
	{
		id = "fault",
		desc = "Fault",
		func = function(mem)
			return (mem.carstate == "fault")
		end,
		needsfloor = false,
	},
	{
		id = "estop",
		desc = "Emergency Stop",
		func = function(mem)
			return (mem.carstate == "stop")
		end,
		needsfloor = false,
	},
	{
		id = "inspect",
		desc = "Inspection (Any)",
		func = function(mem)
			return (mem.carstate == "mrinspect" or mem.carstate == "inspconflict" or mem.carstate == "carinspect")
		end,
		needsfloor = false,
	},
	{
		id = "fire",
		desc = "Fire Service",
		func = function(mem)
			return (mem.carstate == "fs1" or mem.carstate == "fs2" or mem.carstate == "fs2hold")
		end,
		needsfloor = false,
	},
	{
		id = "fire1",
		desc = "Fire Service Phase 1",
		func = function(mem)
			return (mem.carstate == "fs1")
		end,
		needsfloor = false,
	},
	{
		id = "fire2",
		desc = "Fire Service Phase 2",
		func = function(mem)
			return (mem.carstate == "fs2" or mem.carstate == "fs2hold")
		end,
		needsfloor = false,
	},
	{
		id = "independent",
		desc = "Independent Service",
		func = function(mem)
			return (mem.carstate == "indep")
		end,
		needsfloor = false,
	},
	{
		id = "opening",
		desc = "Doors Opening",
		func = function(mem)
			return (mem.doorstate == "opening")
		end,
		needsfloor = false,
	},
	{
		id = "open",
		desc = "Doors Open",
		func = function(mem)
			return (mem.doorstate == "open")
		end,
		needsfloor = false,
	},
	{
		id = "closing",
		desc = "Doors Closing",
		func = function(mem)
			return (mem.doorstate == "closing")
		end,
		needsfloor = false,
	},
	{
		id = "closed",
		desc = "Doors Closed",
		func = function(mem)
			return (mem.doorstate == "closed")
		end,
		needsfloor = false,
	},
	{
		id = "moveup",
		desc = "Moving Up",
		func = function(mem)
			return (mem.drive.status and mem.drive.status.vel > 0)
		end,
		needsfloor = false,
	},
	{
		id = "movedown",
		desc = "Moving Down",
		func = function(mem)
			return (mem.drive.status and mem.drive.status.vel < 0)
		end,
		needsfloor = false,
	},
	{
		id = "moving",
		desc = "Moving (Any Direction)",
		func = function(mem)
			return (mem.drive.status and mem.drive.status.vel ~= 0)
		end,
		needsfloor = false,
	},
	{
		id = "lightsw",
		desc = "Car Light Switch",
		func = function(mem)
			return mem.lightsw
		end,
		needsfloor = false,
	},
	{
		id = "fansw",
		desc = "Car Fan Switch",
		func = function(mem)
			return mem.fansw
		end,
		needsfloor = false,
	},
	{
		id = "upcall",
		desc = "Up Call Exists at Landing:",
		func = function(mem,floor)
			return mem.upcalls[floor]
		end,
		needsfloor = true,
	},
	{
		id = "downcall",
		desc = "Down Call Exists at Landing:",
		func = function(mem,floor)
			return mem.dncalls[floor]
		end,
		needsfloor = true,
	},
	{
		id = "carcall",
		desc = "Car Call Exists at Landing:",
		func = function(mem,floor)
			return mem.carcalls[floor]
		end,
		needsfloor = true,
	},
	{
		id = "apos",
		desc = "Car at Landing:",
		func = function(mem,floor)
			if mem.drive.status then
				return (getpos(mem,nil,true) == floor)
			end
		end,
		needsfloor = true,
	},
	{
		id = "dpos",
		desc = "Moving to Landing:",
		func = function(mem,floor)
			if mem.drive.status then
				return (getpos(mem,mem.drive.status.dpos) == floor)
			end
		end,
		needsfloor = true,
	},
}

local function updateoutputform(pos)
	local meta = minetest.get_meta(pos)
	local fs = "formspec_version[7]size[8,6.5]"
	fs = fs.."dropdown[1,0.5;6,1;signal;"
	local selected = 1
	local currentid = meta:get_string("signal")
	for k,v in ipairs(outputoptions) do
		fs = fs..minetest.formspec_escape(v.desc)..","
		if v.id == currentid then selected = k end
	end
	fs = string.sub(fs,1,-2)
	fs = fs..";"..selected..";false]"
	fs = fs.."field[0.5,2.5;3,1;carid;Car ID;${carid}]"
	fs = fs.."field[4.5,2.5;3,1;floor;Landing Number;${floor}]"
	fs = fs.."label[1.5,4;Not all signal options require a landing number.]"
	fs = fs.."button_exit[2.5,5;3,1;save;Save]"
	meta:set_string("formspec",fs)
end

local function handleoutputfields(pos,_,fields,player)
	local meta = minetest.get_meta(pos)
	if not fields.save then return end
	local name = player:get_player_name()
	if minetest.is_protected(pos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
		if player:is_player() then
			minetest.record_protection_violation(pos,name)
		end
		return
	end
	if not tonumber(fields.carid) then return end
	meta:set_int("carid",fields.carid)
	local carid = tonumber(fields.carid)
	local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid))) or {}
	if not carinfo.controllerpos then return end
	if not celevator.controller.iscontroller(carinfo.controllerpos) then return end
	if minetest.is_protected(carinfo.controllerpos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
		if player:is_player() then
			minetest.chat_send_player(name,"Can't connect to a controller you don't have access to.")
			minetest.record_protection_violation(carinfo.controllerpos,name)
		end
		return
	end
	local floor = tonumber(fields.floor)
	if floor then meta:set_int("floor",floor) end
	local def
	for _,v in ipairs(outputoptions) do
		if v.desc == fields.signal then
			def = v
		end
	end
	if not def then return end
	if def.needsfloor and not floor then return end
	meta:set_string("signal",def.id)
	updateoutputform(pos)
	local infotext = "Car: "..carid.." - "..def.desc..(def.needsfloor and " "..floor or "")
	meta:set_string("infotext",infotext)
end

minetest.register_node("celevator:mesecons_output_off",{
	description = "Elevator Mesecons Output",
	tiles = {
		"celevator_meseconsoutput_top_off.png",
		"celevator_cabinet_sides.png",
	},
	groups = {
		dig_immediate = 2,
	},
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,-0.5,0.5,-0.47,0.5},
			{-0.438,-0.47,-0.438,0.438,-0.42,0.438},
		},
	},
	mesecons = {
		receptor = {
			state = mesecon.state.off,
			rules = iorules,
		},
	},
	after_place_node = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("floor",1)
		updateoutputform(pos)
	end,
	on_receive_fields = handleoutputfields,
})

minetest.register_node("celevator:mesecons_output_on",{
	description = "Elevator Mesecons Output (on state - you hacker you!)",
	tiles = {
		"celevator_meseconsoutput_top_on.png",
		"celevator_cabinet_sides.png",
	},
	drop = "celevator:mesecons_output_off",
	groups = {
		dig_immediate = 2,
		not_in_creative_inventory = 1,
	},
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,-0.5,0.5,-0.47,0.5},
			{-0.438,-0.47,-0.438,0.438,-0.42,0.438},
		},
	},
	mesecons = {
		receptor = {
			state = mesecon.state.on,
			rules = iorules,
		},
	},
	after_place_node = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("floor",1)
		updateoutputform(pos)
	end,
	on_receive_fields = handleoutputfields,
})

minetest.register_abm({
	label = "Update mesecons output",
	nodenames = {"celevator:mesecons_output_off","celevator:mesecons_output_on",},
	interval = 1,
	chance = 1,
	action = function(pos,node)
		local meta = minetest.get_meta(pos)
		local oldstate = (node.name == "celevator:mesecons_output_on")
		local carid = meta:get_int("carid")
		if carid == 0 then return end
		local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid))) or {}
		if not carinfo.controllerpos then return end
		if not celevator.controller.iscontroller(carinfo.controllerpos) then return end
		local floor = meta:get_int("floor")
		local mem = minetest.deserialize(minetest.get_meta(carinfo.controllerpos):get_string("mem")) or {}
		local signal = meta:get_string("signal")
		local def
		for _,v in ipairs(outputoptions) do
			if v.id == signal then
				def = v
				break
			end
		end
		if not def then return end
		local newstate = def.func(mem,floor)
		if newstate ~= oldstate then
			node.name = (newstate and "celevator:mesecons_output_on" or "celevator:mesecons_output_off")
			minetest.swap_node(pos,node)
			if newstate then
				mesecon.receptor_on(pos,iorules)
			else
				mesecon.receptor_off(pos,iorules)
			end
		end
	end,
})

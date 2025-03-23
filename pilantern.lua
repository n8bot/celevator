celevator.pi = {}
celevator.lantern = {}

local boringside = "[combine:64x64"..
                   ":0,0=celevator_cabinet_sides.png"..
                   ":32,0=celevator_cabinet_sides.png"..
                   ":0,32=celevator_cabinet_sides.png"..
                   ":32,32=celevator_cabinet_sides.png"
local displaytex = boringside..":16,40=celevator_pi_background.png"

minetest.register_entity("celevator:pi_entity",{
	initial_properties = {
		visual = "upright_sprite",
		physical = false,
		collisionbox = {0,0,0,0,0,0,},
		textures = {"celevator_transparent.png",},
		static_save = false,
		glow = minetest.LIGHT_MAX,
	},
})

minetest.register_entity("celevator:incar_pi_entity",{
	initial_properties = {
		visual = "upright_sprite",
		physical = false,
		collisionbox = {0,0,0,0,0,0,},
		textures = {"celevator_transparent.png",},
		static_save = false,
		glow = minetest.LIGHT_MAX,
	},
	on_step = function(self)
		local pos = self.object:get_pos()
		local props = self.object:get_properties()
		if props.breath_max and props.breath_max ~= 0 then
			local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",props.breath_max)))
			if not carinfo then return end
			local text = carinfo.pitext or "--"
			if string.len(text) < 3 then text = string.rep(" ",3-string.len(text))..text end
			text = string.sub(text,1,3)
			if carinfo.flash_is and os.time()%2 == 0 then
				text = " IS"
			elseif carinfo.flash_fs and os.time()%2 == 0 then
				text = " FS"
			elseif carinfo.flash_blank and os.time()%2 == 0 then
				text = "   "
			end
			local etex = celevator.pi.generatetexture(text,carinfo.piuparrow,carinfo.pidownarrow,false,true)
			self.object:set_properties({textures = {etex}})
		else
			local carpos = vector.round(pos)
			local carmeta = minetest.get_meta(carpos)
			local carid = carmeta:get_int("carid")
			if carid > 0 then self.object:set_properties({breath_max=carid}) end
		end
	end,
})

function celevator.pi.removeentity(pos)
	local entitiesnearby = minetest.get_objects_inside_radius(pos,0.5)
	for _,i in pairs(entitiesnearby) do
		if i:get_luaentity() and (i:get_luaentity().name == "celevator:pi_entity" or i:get_luaentity().name == "celevator:incar_pi_entity") then
			i:remove()
		end
	end
end

function celevator.pi.generatetexture(text,uparrow,downarrow,lanternoffset,carbg)
	local out = "[combine:600x600:0,0=celevator_transparent.png"
	if carbg then out = out..":0,0=celevator_pi_background_incar.png" end
	local yp = 440
	if lanternoffset then yp = 290 end
	for i=1,string.len(text),1 do
		local char = string.byte(string.sub(text,i,i))
		if char ~= " " then out = out..string.format(":%d,%d=celevator_pi_%02X.png",(i-1)*50+260,yp,(char >= 0x20 and char < 0x7F and char or 0x2A)) end
	end
	if uparrow then out = out..string.format(":200,%d=celevator_pi_arrow.png",yp)
	elseif downarrow then out = out..string.format(":200,%d=(celevator_pi_arrow.png^[transformFY)",yp) end
	return out
end

function celevator.pi.updatedisplay(pos)
	celevator.pi.removeentity(pos)
	local meta = minetest.get_meta(pos)
	local text = meta:get_string("text")
	local entity = minetest.add_entity(pos,"celevator:pi_entity")
	local fdir = minetest.facedir_to_dir(celevator.get_node(pos).param2)
	local uparrow = meta:get_int("uparrow") > 0
	local downarrow = meta:get_int("downarrow") > 0
	local flash_fs = meta:get_int("flash_fs") > 0
	local flash_is = meta:get_int("flash_is") > 0
	local flashtimer = meta:get_int("flashtimer") > 0
	local islantern = minetest.get_item_group(celevator.get_node(pos).name,"_celevator_lantern") == 1
	local etex = celevator.pi.generatetexture(text,uparrow,downarrow,islantern)
	if flash_fs then
		if flashtimer then etex = celevator.pi.generatetexture(" FS",uparrow,downarrow,islantern) end
		entity:set_properties({_flash_fs = true,_flash_is = false,})
	elseif flash_is then
		if flashtimer then etex = celevator.pi.generatetexture(" IS",uparrow,downarrow,islantern) end
		entity:set_properties({_flash_fs = false,_flash_is = true,})
	else
		entity:set_properties({_flash_fs = false,_flash_is = false,})
	end
	entity:set_properties({textures={etex}})
	entity:set_yaw((fdir.x ~= 0) and math.pi/2 or 0)
	entity:set_pos(vector.add(pos,vector.multiply(fdir,0.47)))
end

function celevator.pi.flash(pos,what)
	if minetest.get_item_group(celevator.get_node(pos).name,"_celevator_pi") ~= 1 then return end
	local meta = minetest.get_meta(pos)
	if what == "FS" then
		meta:set_int("flash_is",0)
		meta:set_int("flash_fs",1)
	elseif what == "IS" then
		meta:set_int("flash_is",1)
		meta:set_int("flash_fs",0)
	else
		meta:set_int("flash_is",0)
		meta:set_int("flash_fs",0)
	end
	celevator.pi.updatedisplay(pos)
end

function celevator.pi.settext(pos,text)
	if not text then text = " --" end
	if minetest.get_item_group(celevator.get_node(pos).name,"_celevator_pi") ~= 1 then return end
	local meta = minetest.get_meta(pos)
	if string.len(text) < 3 then
		text = string.rep(" ",3-string.len(text))..text
	end
	meta:set_string("text",string.sub(text,1,3))
	celevator.pi.updatedisplay(pos)
end

function celevator.pi.setarrow(pos,which,active)
	if minetest.get_item_group(celevator.get_node(pos).name,"_celevator_pi") ~= 1 then return end
	local meta = minetest.get_meta(pos)
	if which == "up" then
		meta:set_int("uparrow",active and 1 or 0)
	elseif which == "down" then
		meta:set_int("downarrow",active and 1 or 0)
	end
	celevator.pi.updatedisplay(pos)
end

minetest.register_node("celevator:pi",{
	description = "Elevator Position Indicator",
	groups = {
		dig_immediate = 2,
		_celevator_pi = 1,
	},
	tiles = {
		boringside,
		boringside,
		boringside,
		boringside,
		boringside,
		displaytex,
	},
	inventory_image = "[combine:32x32:0,5=celevator_pi_background.png",
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	light_source = 3,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.25,-0.453,0.475,0.25,-0.125,0.5},
		},
	},
	after_place_node = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec","formspec_version[7]size[8,5]field[0.5,0.5;7,1;carid;Car ID;]button[3,3.5;2,1;save;Save]")
	end,
	on_receive_fields = function(pos,_,fields)
		if tonumber(fields.carid) then
			local carid = tonumber(fields.carid)
			local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
			if not (carinfo and carinfo.pis) then return end
			table.insert(carinfo.pis,{pos=pos})
			celevator.storage:set_string(string.format("car%d",carid),minetest.serialize(carinfo))
			local meta = minetest.get_meta(pos)
			meta:set_int("carid",carid)
			meta:set_string("formspec","")
			celevator.pi.settext(pos,carinfo.pitext)
		end
	end,
	on_destruct = function(pos)
		celevator.pi.removeentity(pos)
		local meta = minetest.get_meta(pos)
		local carid = meta:get_int("carid")
		if carid == 0 then return end
		local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
		if not (carinfo and carinfo.pis) then return end
		for i,pi in pairs(carinfo.pis) do
			if vector.equals(pos,pi.pos) then
				table.remove(carinfo.pis,i)
				celevator.storage:set_string(string.format("car%d",carid),minetest.serialize(carinfo))
			end
		end
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("text","--")
		celevator.pi.updatedisplay(pos)
	end,
})

function celevator.lantern.setlight(pos,dir,newstate)
	local node = celevator.get_node(pos)
	if minetest.get_item_group(node.name,"_celevator_lantern") ~= 1 then return end
	if dir == "up" then
		if minetest.get_item_group(node.name,"_celevator_lantern_has_up") ~= 1 then return end
		local lit = minetest.get_item_group(node.name,"_celevator_lantern_up_lit") == 1
		if lit == newstate then return end
		local newname = "celevator:lantern_"
		if minetest.get_item_group(node.name,"_celevator_pi") == 1 then newname = "celevator:pilantern_" end
		if minetest.get_item_group(node.name,"_celevator_lantern_vertical") == 1 then newname = "celevator:lantern_vertical_" end
		if minetest.get_item_group(node.name,"_celevator_lantern_has_down") == 1 then
			newname = newname.."both"
		else
			newname = newname.."up"
		end
		if newstate then
			newname = newname.."_upon"
			minetest.sound_play("celevator_chime_up",{pos = pos},true)
		end
		if minetest.get_item_group(node.name,"_celevator_lantern_down_lit") == 1 then
			newname = newname.."_downon"
		end
		node.name = newname
		minetest.swap_node(pos,node)
	elseif dir == "down" then
		if minetest.get_item_group(node.name,"_celevator_lantern_has_down") ~= 1 then return end
		local lit = minetest.get_item_group(node.name,"_celevator_lantern_down_lit") == 1
		if lit == newstate then return end
		local newname = "celevator:lantern_"
		if minetest.get_item_group(node.name,"_celevator_pi") == 1 then newname = "celevator:pilantern_" end
		if minetest.get_item_group(node.name,"_celevator_lantern_vertical") == 1 then newname = "celevator:lantern_vertical_" end
		if minetest.get_item_group(node.name,"_celevator_lantern_has_up") == 1 then
			newname = newname.."both"
		else
			newname = newname.."down"
		end
		if minetest.get_item_group(node.name,"_celevator_lantern_up_lit") == 1 then
			newname = newname.."_upon"
		end
		if newstate then
			newname = newname.."_downon"
			minetest.sound_play("celevator_chime_down",{pos = pos},true)
		end
		node.name = newname
		minetest.swap_node(pos,node)
	end
end

local function makepilanterntex(dir,upon,downon)
	local tex = boringside
	if dir == "up" then
		tex = tex..":16,24=celevator_pi_lantern_background_up.png"
		if upon then
			tex = tex..":26,49=celevator_lantern_up.png"
		end
	elseif dir == "down" then
		tex = tex..":16,24=celevator_pi_lantern_background_down.png"
		if downon then
			tex = tex..":27,49=celevator_lantern_down.png"
		end
	elseif dir == "both" then
		tex = tex..":16,24=celevator_pi_lantern_background_updown.png"
		if upon then
			tex = tex..":20,49=celevator_lantern_up.png"
		end
		if downon then
			tex = tex..":33,49=celevator_lantern_down.png"
		end
	end
	return(tex)
end

local function makelanterntex(dir,upon,downon)
	local tex = boringside
	if dir == "up" then
		tex = tex..":16,32=celevator_lantern_background_up.png"
		if upon then
			tex = tex..":26,36=celevator_lantern_up.png"
		end
	elseif dir == "down" then
		tex = tex..":16,32=celevator_lantern_background_down.png"
		if downon then
			tex = tex..":27,36=celevator_lantern_down.png"
		end
	elseif dir == "both" then
		tex = tex..":16,32=celevator_lantern_background_updown.png"
		if upon then
			tex = tex..":20,36=celevator_lantern_up.png"
		end
		if downon then
			tex = tex..":33,36=celevator_lantern_down.png"
		end
	end
	return(tex)
end

local function makeverticallanterntex(dir,upon,downon)
	local tex = boringside
	if dir == "up" then
		tex = tex..":22,12=celevator_lantern_vertical_background_up.png"
		if upon then
			tex = tex..":27,25=celevator_lantern_up.png"
		end
	elseif dir == "down" then
		tex = tex..":22,12=celevator_lantern_vertical_background_down.png"
		if downon then
			tex = tex..":27,26=celevator_lantern_down.png"
		end
	elseif dir == "both" then
		tex = tex..":22,12=celevator_lantern_vertical_background_updown.png"
		if upon then
			tex = tex..":27,18=celevator_lantern_up.png"
		end
		if downon then
			tex = tex..":27,34=celevator_lantern_down.png"
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

for _,state in ipairs(validstates) do
	local nname = "celevator:pilantern_"..state[1]
	local dropname = nname
	local light = 0
	if state[2] then
		nname = nname.."_upon"
		light = light + 4
	end
	if state[3] then
		nname = nname.."_downon"
		light = light + 4
	end
	local idle = not (state[2] or state[3])
	local description = string.format("Elevator %s Position Indicator/Lantern Combo%s",state[4],(idle and "" or " (on state, you hacker you!)"))
	minetest.register_node(nname,{
		description = description,
		groups = {
			dig_immediate = 2,
			not_in_creative_inventory = (idle and 0 or 1),
			_celevator_lantern = 1,
			_celevator_lantern_has_up = (state[1] == "down" and 0 or 1),
			_celevator_lantern_has_down = (state[1] == "up" and 0 or 1),
			_celevator_lantern_up_lit = (state[2] and 1 or 0),
			_celevator_lantern_down_lit = (state[3] and 1 or 0),
			_celevator_pi = 1,
		},
		drop = dropname,
		tiles = {
			boringside,
			boringside,
			boringside,
			boringside,
			boringside,
			makepilanterntex(state[1],state[2],state[3])
		},
		inventory_image = string.format("[combine:42x42:5,0=celevator_pi_lantern_background_%s.png",(state[1] == "both" and "updown" or state[1])),
		paramtype = "light",
		paramtype2 = "facedir",
		drawtype = "nodebox",
		light_source = light + 3,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.25,-0.5,0.475,0.25,0.125,0.5},
			},
		},
		after_place_node = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("formspec","formspec_version[7]size[8,5]field[0.5,0.5;7,1;carid;Car ID;]field[0.5,2;7,1;landing;Landing Number;]button[3,3.5;2,1;save;Save]")
		end,
		on_receive_fields = function(pos,_,fields)
			if tonumber(fields.carid) and tonumber(fields.landing) then
				local carid = tonumber(fields.carid)
				local landing = tonumber(fields.landing)
				local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
				if not (carinfo and carinfo.pis and carinfo.lanterns) then return end
				table.insert(carinfo.pis,{pos=pos})
				table.insert(carinfo.lanterns,{pos=pos,landing=landing})
				celevator.storage:set_string(string.format("car%d",carid),minetest.serialize(carinfo))
				local meta = minetest.get_meta(pos)
				meta:set_int("carid",carid)
				meta:set_string("formspec","")
				celevator.pi.settext(pos,carinfo.pitext)
			end
		end,
		on_destruct = function(pos)
			celevator.pi.removeentity(pos)
			local meta = minetest.get_meta(pos)
			local carid = meta:get_int("carid")
			if carid == 0 then return end
			local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
			if not (carinfo and carinfo.pis and carinfo.lanterns) then return end
			for i,pi in pairs(carinfo.pis) do
				if vector.equals(pos,pi.pos) then
					table.remove(carinfo.pis,i)
					celevator.storage:set_string(string.format("car%d",carid),minetest.serialize(carinfo))
				end
			end
			for i,lantern in pairs(carinfo.lanterns) do
				if vector.equals(pos,lantern.pos) then
					table.remove(carinfo.lanterns,i)
					celevator.storage:set_string(string.format("car%d",carid),minetest.serialize(carinfo))
				end
			end
		end,
		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("text","--")
			celevator.pi.updatedisplay(pos)
		end,
	})
	nname = "celevator:lantern_"..state[1]
	dropname = nname
	if state[2] then nname = nname.."_upon" end
	if state[3] then nname = nname.."_downon" end
	idle = not (state[2] or state[3])
	description = string.format("Elevator %s Lantern%s",state[4],(idle and "" or " (on state, you hacker you!)"))
	minetest.register_node(nname,{
		description = description,
		inventory_image = string.format("[combine:32x32:0,5=celevator_lantern_background_%s.png",(state[1] == "both" and "updown" or state[1])),
		groups = {
			dig_immediate = 2,
			not_in_creative_inventory = (idle and 0 or 1),
			_celevator_lantern = 1,
			_celevator_lantern_has_up = (state[1] == "down" and 0 or 1),
			_celevator_lantern_has_down = (state[1] == "up" and 0 or 1),
			_celevator_lantern_up_lit = (state[2] and 1 or 0),
			_celevator_lantern_down_lit = (state[3] and 1 or 0),
		},
		drop = dropname,
		tiles = {
			boringside,
			boringside,
			boringside,
			boringside,
			boringside,
			makelanterntex(state[1],state[2],state[3])
		},
		after_place_node = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("formspec","formspec_version[7]size[8,5]field[0.5,0.5;7,1;carid;Car ID;]field[0.5,2;7,1;landing;Landing Number;]button[3,3.5;2,1;save;Save]")
		end,
		on_receive_fields = function(pos,_,fields)
			if tonumber(fields.carid) and tonumber(fields.landing) then
				local carid = tonumber(fields.carid)
				local landing = tonumber(fields.landing)
				local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
				if not (carinfo and carinfo.lanterns) then return end
				table.insert(carinfo.lanterns,{pos=pos,landing=landing})
				celevator.storage:set_string(string.format("car%d",carid),minetest.serialize(carinfo))
				local meta = minetest.get_meta(pos)
				meta:set_int("carid",carid)
				meta:set_string("formspec","")
			end
		end,
		on_destruct = function(pos)
			local meta = minetest.get_meta(pos)
			local carid = meta:get_int("carid")
			if carid == 0 then return end
			local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
			if not (carinfo and carinfo.lanterns) then return end
			for i,lantern in pairs(carinfo.lanterns) do
				if vector.equals(pos,lantern.pos) then
					table.remove(carinfo.lanterns,i)
					celevator.storage:set_string(string.format("car%d",carid),minetest.serialize(carinfo))
				end
			end
		end,
		paramtype = "light",
		paramtype2 = "facedir",
		light_source = light,
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.25,-0.328,0.475,0.25,0,0.5},
			},
		},
	})
	nname = "celevator:lantern_vertical_"..state[1]
	dropname = nname
	if state[2] then nname = nname.."_upon" end
	if state[3] then nname = nname.."_downon" end
	description = string.format("Elevator %s Lantern (vertical)%s",state[4],(idle and "" or " (on state, you hacker you!)"))
	minetest.register_node(nname,{
		description = description,
		inventory_image = string.format("[combine:40x40:10,0=celevator_lantern_vertical_background_%s.png",(state[1] == "both" and "updown" or state[1])),
		groups = {
			dig_immediate = 2,
			not_in_creative_inventory = (idle and 0 or 1),
			_celevator_lantern = 1,
			_celevator_lantern_has_up = (state[1] == "down" and 0 or 1),
			_celevator_lantern_has_down = (state[1] == "up" and 0 or 1),
			_celevator_lantern_up_lit = (state[2] and 1 or 0),
			_celevator_lantern_down_lit = (state[3] and 1 or 0),
			_celevator_lantern_vertical = 1,
		},
		drop = dropname,
		tiles = {
			boringside,
			boringside,
			boringside,
			boringside,
			boringside,
			makeverticallanterntex(state[1],state[2],state[3])
		},
		after_place_node = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("formspec","formspec_version[7]size[8,5]field[0.5,0.5;7,1;carid;Car ID;]field[0.5,2;7,1;landing;Landing Number;]button[3,3.5;2,1;save;Save]")
		end,
		on_receive_fields = function(pos,_,fields)
			if tonumber(fields.carid) and tonumber(fields.landing) then
				local carid = tonumber(fields.carid)
				local landing = tonumber(fields.landing)
				local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
				if not (carinfo and carinfo.lanterns) then return end
				table.insert(carinfo.lanterns,{pos=pos,landing=landing})
				celevator.storage:set_string(string.format("car%d",carid),minetest.serialize(carinfo))
				local meta = minetest.get_meta(pos)
				meta:set_int("carid",carid)
				meta:set_string("formspec","")
			end
		end,
		on_destruct = function(pos)
			local meta = minetest.get_meta(pos)
			local carid = meta:get_int("carid")
			if carid == 0 then return end
			local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
			if not (carinfo and carinfo.lanterns) then return end
			for i,lantern in pairs(carinfo.lanterns) do
				if vector.equals(pos,lantern.pos) then
					table.remove(carinfo.lanterns,i)
					celevator.storage:set_string(string.format("car%d",carid),minetest.serialize(carinfo))
				end
			end
		end,
		paramtype = "light",
		paramtype2 = "facedir",
		light_source = light,
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.14,-0.313,0.475,0.156,0.313,0.5},
			},
		},
	})
end

minetest.register_abm({
	label = "Respawn / Flash PI displays",
	nodenames = {"group:_celevator_pi"},
	interval = 1,
	chance = 1,
	action = function(pos)
		local meta = minetest.get_meta(pos)
		local flashtimer = meta:get_int("flashtimer") > 0
		meta:set_int("flashtimer",flashtimer and 0 or 1)
		celevator.pi.updatedisplay(pos)
	end,
})

minetest.register_abm({
	label = "Check PIs/lanterns for missing/replaced controllers",
	nodenames = {"group:_celevator_pi","group:_celevator_lantern"},
	interval = 15,
	chance = 1,
	action = function(pos)
		local meta = minetest.get_meta(pos)
		local carid = meta:get_int("carid")
		if not (carid and carid > 0) then return end --Not set up yet
		local carinfo = minetest.deserialize(celevator.storage:get_string("car"..carid))
		if not carinfo then
			celevator.pi.settext(pos," --")
			meta:set_string("infotext","Error reading car information!\nPlease remove and replace this node.")
			return
		end
		if not (carinfo.controllerpos and celevator.controller.iscontroller(carinfo.controllerpos)) then
			celevator.pi.settext(pos," --")
			meta:set_string("infotext","Controller is missing!\nPlease remove and replace this node.")
			return
		end
		if celevator.get_meta(carinfo.controllerpos):get_int("carid") ~= carid then
			celevator.pi.settext(pos," --")
			meta:set_string("infotext","Controller found but with incorrect ID!\nPlease remove and replace this node.")
		end
	end,
})

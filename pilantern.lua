celevator.pi = {}

local boringside = "[combine:64x64:0,0=celevator_cabinet_sides.png:32,0=celevator_cabinet_sides.png:0,32=celevator_cabinet_sides.png:32,32=celevator_cabinet_sides.png"
local displaytex = boringside..":16,40=celevator_pi_background.png"

minetest.register_entity("celevator:pi_entity",{
	initial_properties = {
		visual = "upright_sprite",
		physical = false,
		collisionbox = {0,0,0,0,0,0,},
		textures = {"celevator_transparent.png",},
	},
})

local function removeentity(pos)
	local entitiesnearby = minetest.get_objects_inside_radius(pos,1.5)
	for _,i in pairs(entitiesnearby) do
		if i:get_luaentity() and i:get_luaentity().name == "celevator:pi_entity" then
			i:remove()
		end
	end
end

local function generatetexture(text,uparrow,downarrow)
	local out = "[combine:600x600:0,0=celevator_transparent.png"
	for i=1,string.len(text),1 do
		local char = string.byte(string.sub(text,i,i))
		if char ~= " " then out = out..string.format(":%d,%d=celevator_pi_%02X.png",(i-1)*50+260,440,(char >= 0x20 and char < 0x7F and char or 0x2A)) end
	end
	if uparrow then out = out..":200,440=celevator_pi_arrow.png"
	elseif downarrow then out = out..":200,440=(celevator_pi_arrow.png^[transformFY)" end
	return out
end

function celevator.pi.updatedisplay(pos)
	removeentity(pos)
	local meta = minetest.get_meta(pos)
	local text = meta:get_string("text")
	local entity = minetest.add_entity(pos,"celevator:pi_entity")
	local fdir = minetest.facedir_to_dir(minetest.get_node(pos).param2)
	local uparrow = meta:get_int("uparrow") > 0
	local downarrow = meta:get_int("downarrow") > 0
	local flash_fs = meta:get_int("flash_fs") > 0
	local flash_is = meta:get_int("flash_is") > 0
	local flashtimer = meta:get_int("flashtimer") > 0
	local etex = generatetexture(text,uparrow,downarrow)
	if flash_fs then
		if flashtimer then etex = generatetexture(" FS",uparrow,downarrow) end
		entity:set_properties({_flash_fs = true,_flash_is = false,})
	elseif flash_is then
		if flashtimer then etex = generatetexture(" IS",uparrow,downarrow) end
		entity:set_properties({_flash_fs = false,_flash_is = true,})
	else
		entity:set_properties({_flash_fs = false,_flash_is = false,})
	end
	entity:set_properties({textures={etex}})
	entity:set_yaw((fdir.x ~= 0) and math.pi/2 or 0)
	entity:setpos(vector.add(pos,vector.multiply(fdir,-0.61)))
end

function celevator.pi.flash(pos,what)
	if minetest.get_item_group(minetest.get_node(pos).name,"_celevator_pi") ~= 1 then return end
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
	if minetest.get_item_group(minetest.get_node(pos).name,"_celevator_pi") ~= 1 then return end
	local meta = minetest.get_meta(pos)
	if string.len(text) < 3 then
		text = string.rep(" ",3-string.len(text))..text
	end
	meta:set_string("text",string.sub(text,1,3))
	celevator.pi.updatedisplay(pos)
end

function celevator.pi.setarrow(pos,which,active)
	if minetest.get_item_group(minetest.get_node(pos).name,"_celevator_pi") ~= 1 then return end
	local meta = minetest.get_meta(pos)
	if which == "up" then
		meta:set_int("uparrow",active and 1 or 0)
	elseif which == "down" then
		meta:set_int("downarrow",active and 1 or 0)
	end
	celevator.pi.updatedisplay(pos)
end

minetest.register_node("celevator:pi",{
	description = "Position Indicator",
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
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -0.5,  -0.5,  -0.5, 0.5,   0.5,  0.5 },
			{-0.25,-0.453,  -0.6,0.25,-0.125, -0.5 },
		},
	},
	on_destruct = removeentity,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("text","621")
		celevator.pi.updatedisplay(pos)
	end,
})

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

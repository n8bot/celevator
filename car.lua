celevator.car = {}

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
			"celevator_car_wallpaper.png^celevator_car_wall_bottom.png",
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
		dig_immediate = 2,
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
	def.description = "Car "..def._position
	def.light_source = 9
	def.on_receive_fields = function(pos,_,fields,player)
		local meta = minetest.get_meta(pos)
		local carid = meta:get_int("carid")
		if carid == 0 then return end
		local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
		if not carinfo then return end
		local event = {
			type = "cop",
			fields = fields,
			player = player:get_player_name(),
		}
		celevator.controller.run(carinfo.controllerpos,event)
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

function celevator.car.updatecop(pos)
	local copmeta = minetest.get_meta(pos)
	local carid = copmeta:get_int("carid")
	if carid == 0 then return end
	local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
	if not carinfo then return end
	local controllermeta = minetest.get_meta(carinfo.controllerpos)
	copmeta:set_string("formspec",controllermeta:get_string("copformspec"))
end

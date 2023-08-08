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
			"celevator_car_wallpaper.png",
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
	}
	def.paramtype = "light"
	def.paramtype2 = "4dir"
	def.drawtype = "nodebox"
	def.description = "Car "..def._position
	def.light_source = minetest.LIGHT_MAX
	minetest.register_node("celevator:car_"..def._position,def)
end

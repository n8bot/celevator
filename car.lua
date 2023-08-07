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
	},
	{
		_position = "010",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5,-0.5,-0.5,-0.45,0.5,0.5},
			},
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
	},
	{
		_position = "110",
		node_box = {
			type = "fixed",
			fixed = {
				{0.45,-0.5,-0.5,0.5,0.5,0.5},
			},
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
	},
}

for _,def in ipairs(pieces) do
	def.groups = {
		dig_immediate = 2,
	}
	def.tiles = {
		"celevator_cabinet_sides.png",
	}
	def.paramtype = "light"
	def.paramtype2 = "4dir"
	def.drawtype = "nodebox"
	def.description = "Car "..def._position
	minetest.register_node("celevator:car_"..def._position,def)
end

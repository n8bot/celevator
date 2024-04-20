celevator = {
	drives = {},
	storage = minetest.get_mod_storage(),
}

function celevator.get_node(pos)
	local node = minetest.get_node_or_nil(pos)
	if node then return node end
	VoxelManip(pos,pos)
	return minetest.get_node(pos)
end

function celevator.get_meta(pos)
	if minetest.get_node_or_nil(pos) then
		return minetest.get_meta(pos)
	else
		VoxelManip(pos,pos)
		return minetest.get_meta(pos)
	end
end

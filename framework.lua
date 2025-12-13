celevator = {
	drives = {},
	storage = core.get_mod_storage(),
}

function celevator.get_node(pos)
	local node = core.get_node_or_nil(pos)
	if node then return node end
	VoxelManip(pos,pos)
	return core.get_node(pos)
end

function celevator.get_meta(pos)
	if core.get_node_or_nil(pos) then
		return core.get_meta(pos)
	else
		VoxelManip(pos,pos)
		return core.get_meta(pos)
	end
end

celevator.pairing = {
	playerstate = {}
}

minetest.register_on_player_receive_fields(function (player,formname,fields)
	if formname ~= "celevator:pairing_floornum" then return end
	if not celevator.pairing.playerstate[player:get_player_name()] then return end
	if not tonumber(fields.floornum) then return end
	local targetpos = celevator.pairing.playerstate[player:get_player_name()].pos
	local controllerpos = celevator.pairing.playerstate[player:get_player_name()].controllerpos
	if minetest.get_item_group(minetest.get_node(targetpos).name,"_celevator_callbutton") == 1 then
		local nodemeta = minetest.get_meta(targetpos)
		nodemeta:set_string("controllerpos",minetest.pos_to_string(controllerpos))
		local controllermeta = minetest.get_meta(controllerpos)
		local pairings = minetest.deserialize(controllermeta:get_string("callbuttons")) or {}
		local hash = minetest.hash_node_position(targetpos)
		pairings[hash] = math.floor(tonumber(fields.floornum))
		controllermeta:set_string("callbuttons",minetest.serialize(pairings))
		minetest.chat_send_player(player:get_player_name(),"Paired to "..minetest.pos_to_string(controllerpos).." as landing "..pairings[hash])
		celevator.pairing.playerstate[player:get_player_name()] = nil
	end
end)

minetest.register_tool("celevator:pairingtool",{
	description = "Pairing Tool",
	inventory_image = "celevator_pairingtool.png",
	on_use = function(itemstack,player,pointed)
		if not (pointed and pointed.under) then return itemstack end
		if not (player and player:get_player_name()) then return end
		local pos = pointed.under
		local name = player:get_player_name()
		local node = minetest.get_node(pos)
		if not node then return itemstack end
		if celevator.controller.iscontroller(pos) then
			local stackmeta = itemstack:get_meta()
			stackmeta:set_string("controllerpos",minetest.pos_to_string(pos))
			minetest.chat_send_player(name,"Now pairing with controller at "..minetest.pos_to_string(pos))
		elseif minetest.get_item_group(node.name,"_celevator_callbutton") == 1 then
			local stackmeta = itemstack:get_meta()
			local nodemeta = minetest.get_meta(pos)
			local oldpairing = minetest.string_to_pos(nodemeta:get_string("controllerpos"))
			local controllerpos = minetest.string_to_pos(stackmeta:get_string("controllerpos"))
			if not controllerpos then
				minetest.chat_send_player(name,"Nothing has been selected to pair with! Punch a controller or dispatcher first.")
			elseif oldpairing then
				local controllermeta = minetest.get_meta(oldpairing)
				local pairings = minetest.deserialize(controllermeta:get_string("callbuttons"))
				if pairings then
					local hash = minetest.hash_node_position(pos)
					pairings[hash] = nil
					controllermeta:set_string("callbuttons",minetest.serialize(pairings))
				end
				nodemeta:set_string("controllerpos","")
				minetest.chat_send_player(player:get_player_name(),"Unpaired from "..minetest.pos_to_string(oldpairing))
			elseif celevator.controller.iscontroller(controllerpos) then
				if minetest.is_protected(controllerpos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
					minetest.chat_send_player(name,"Unable to pair - controller at "..minetest.pos_to_string(controllerpos).." is protected!")
					minetest.record_protection_violation(controllerpos,name)
				elseif minetest.is_protected(pos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
					minetest.chat_send_player(name,"Unable to pair - item to be paired is protected!")
					minetest.record_protection_violation(pos,name)
				else
					celevator.pairing.playerstate[name] = {
						pos = pos,
						controllerpos = controllerpos,
					}
					minetest.show_formspec(name,"celevator:pairing_floornum","field[floornum;Landing Number;1]")
				end
			else
				minetest.chat_send_player(name,"Controller or dispatcher has been removed. Punch a new controller or dispatcher to pair to that one.")
			end
		end
		return itemstack
	end,
})


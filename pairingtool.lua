celevator.pairing = {
	playerstate = {}
}

minetest.register_on_player_receive_fields(function (player,formname,fields)
	if not celevator.pairing.playerstate[player:get_player_name()] then return end
	if not tonumber(fields.floornum) then return end
	if formname == "celevator:pairing_callbutton_floornum" then
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
			minetest.chat_send_player(player:get_player_name(),"Call button paired to "..minetest.pos_to_string(controllerpos).." as landing "..pairings[hash])
			celevator.pairing.playerstate[player:get_player_name()] = nil
		end
	elseif formname == "celevator:pairing_lantern_floornum" then
		local targetpos = celevator.pairing.playerstate[player:get_player_name()].pos
		local controllerpos = celevator.pairing.playerstate[player:get_player_name()].controllerpos
		if minetest.get_item_group(minetest.get_node(targetpos).name,"_celevator_lantern") == 1 then
			local nodemeta = minetest.get_meta(targetpos)
			nodemeta:set_string("controllerpos",minetest.pos_to_string(controllerpos))
			local controllermeta = minetest.get_meta(controllerpos)
			local pairings = minetest.deserialize(controllermeta:get_string("lanterns")) or {}
			local hash = minetest.hash_node_position(targetpos)
			pairings[hash] = math.floor(tonumber(fields.floornum))
			controllermeta:set_string("lanterns",minetest.serialize(pairings))
			minetest.chat_send_player(player:get_player_name(),"Lantern paired to "..minetest.pos_to_string(controllerpos).." as landing "..pairings[hash])
			celevator.pairing.playerstate[player:get_player_name()] = nil
		end
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
		elseif minetest.get_item_group(node.name,"_celevator_drive") == 1 then
			local stackmeta = itemstack:get_meta()
			stackmeta:set_string("drivepos",minetest.pos_to_string(pos))
			minetest.chat_send_player(name,"Now pairing with drive at "..minetest.pos_to_string(pos))
		elseif minetest.get_item_group(node.name,"_celevator_machine") == 1 then
			local stackmeta = itemstack:get_meta()
			local nodemeta = minetest.get_meta(pos)
			local oldpairing = minetest.string_to_pos(nodemeta:get_string("drivepos"))
			local drivepos = minetest.string_to_pos(stackmeta:get_string("drivepos"))
			local origin = minetest.string_to_pos(nodemeta:get_string("origin"))
			if not origin then
				minetest.chat_send_player(name,"Car has not been located! Try punching the machine to search for one.")
			elseif not drivepos then
				minetest.chat_send_player(name,"Nothing has been selected to pair with! Punch a drive first.")
			elseif oldpairing then
				local drivemeta = minetest.get_meta(oldpairing)
				drivemeta:set_string("machinepos","")
				drivemeta:set_string("apos","0")
				drivemeta:set_string("dpos","0")
				drivemeta:set_string("vel","0")
				drivemeta:set_string("maxvel","0.2")
				drivemeta:set_string("state","uninit")
				drivemeta:set_string("startpos","0")
				drivemeta:set_string("origin",minetest.pos_to_string(origin))
				nodemeta:set_string("drivepos","")
				minetest.chat_send_player(player:get_player_name(),"Unpaired from "..minetest.pos_to_string(oldpairing))
			elseif minetest.get_item_group(minetest.get_node(drivepos).name,"_celevator_drive") ~= 1 then
				minetest.chat_send_player(name,"Drive has been removed. Punch a new drive to pair to that one.")
			else
				if minetest.is_protected(drivepos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
					minetest.chat_send_player(name,"Unable to pair - drive at "..minetest.pos_to_string(drivepos).." is protected!")
					minetest.record_protection_violation(drivepos,name)
				elseif minetest.is_protected(pos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
					minetest.chat_send_player(name,"Unable to pair - item to be paired is protected!")
					minetest.record_protection_violation(pos,name)
				else
					local drivemeta = minetest.get_meta(drivepos)
					nodemeta:set_string("drivepos",minetest.pos_to_string(drivepos))
					drivemeta:set_string("machinepos",minetest.pos_to_string(pos))
					drivemeta:set_string("state","stopped")
					minetest.chat_send_player(player:get_player_name(),"Machine paired to "..minetest.pos_to_string(drivepos))
				end
			end
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
					minetest.show_formspec(name,"celevator:pairing_callbutton_floornum","field[floornum;Landing Number;1]")
				end
			else
				minetest.chat_send_player(name,"Controller or dispatcher has been removed. Punch a new controller or dispatcher to pair to that one.")
			end
		elseif minetest.get_item_group(node.name,"_celevator_pi") or minetest.get_item_group(node.name,"_celevator_lantern") == 1 then
			local stackmeta = itemstack:get_meta()
			local nodemeta = minetest.get_meta(pos)
			local oldpairing = minetest.string_to_pos(nodemeta:get_string("controllerpos"))
			local controllerpos = minetest.string_to_pos(stackmeta:get_string("controllerpos"))
			if not controllerpos then
				minetest.chat_send_player(name,"Nothing has been selected to pair with! Punch a controller or dispatcher first.")
			elseif oldpairing then
				local controllermeta = minetest.get_meta(oldpairing)
				local pairings = minetest.deserialize(controllermeta:get_string("pis"))
				if pairings then
					local hash = minetest.hash_node_position(pos)
					pairings[hash] = nil
					controllermeta:set_string("pis",minetest.serialize(pairings))
				end
				nodemeta:set_string("controllerpos","")
				nodemeta:set_int("uparrow",0)
				nodemeta:set_int("downarrow",0)
				nodemeta:set_int("flash_fs",0)
				nodemeta:set_int("flash_is",0)
				nodemeta:set_string("text","")
				celevator.pi.updatedisplay(pos)
				minetest.chat_send_player(player:get_player_name(),"Unpaired from "..minetest.pos_to_string(oldpairing))
			elseif celevator.controller.iscontroller(controllerpos) then
				if minetest.is_protected(controllerpos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
					minetest.chat_send_player(name,"Unable to pair - controller at "..minetest.pos_to_string(controllerpos).." is protected!")
					minetest.record_protection_violation(controllerpos,name)
				elseif minetest.is_protected(pos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
					minetest.chat_send_player(name,"Unable to pair - item to be paired is protected!")
					minetest.record_protection_violation(pos,name)
				else
					if minetest.get_item_group(node.name,"_celevator_pi") == 1 then
						local controllermeta = minetest.get_meta(controllerpos)
						nodemeta:set_string("controllerpos",minetest.pos_to_string(controllerpos))
						local pairings = minetest.deserialize(controllermeta:get_string("pis")) or {}
						local hash = minetest.hash_node_position(pos)
						pairings[hash] = true
						controllermeta:set_string("pis",minetest.serialize(pairings))
						minetest.chat_send_player(player:get_player_name(),"PI paired to "..minetest.pos_to_string(controllerpos))
					end
					if minetest.get_item_group(node.name,"_celevator_lantern") == 1 then
						celevator.pairing.playerstate[name] = {
							pos = pos,
							controllerpos = controllerpos,
						}
						minetest.show_formspec(name,"celevator:pairing_lantern_floornum","field[floornum;Landing Number;1]")
					end
				end
			else
				minetest.chat_send_player(name,"Controller or dispatcher has been removed. Punch a new controller or dispatcher to pair to that one.")
			end
		end
		return itemstack
	end,
})

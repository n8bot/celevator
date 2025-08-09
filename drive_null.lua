celevator.drives.null = {
	name = "Null Drive",
	description = "Simulation only, no movement, for testing and demonstration",
	nname = "celevator:drive_null",
	soundhandles = {},
	step_enabled = true, --Not a setting, is overwritten on globalstep, true here to check for running drives on startup
}

local function update_ui(pos)
	local meta = minetest.get_meta(pos)
	local apos = tonumber(meta:get_string("apos")) or 0
	local status = "Idle"
	local vel = tonumber(meta:get_string("vel")) or 0
	if vel > 0 then
		status = string.format("Running: Up, %0.02f m/s",vel)
	elseif vel < 0 then
		status = string.format("Running: Down, %0.02f m/s",math.abs(vel))
	end
	meta:set_string("infotext",string.format("Null Drive - %s - Position: %0.02f m",status,apos))
end

local function playbuzz(pos)
	local hash = minetest.hash_node_position(pos)
	if celevator.drives.null.soundhandles[hash] == "cancel" then return end
	celevator.drives.null.soundhandles[hash] = minetest.sound_play("celevator_drive_run",{
		pos = pos,
		loop = true,
		gain = 0.4,
	})
end

local function startbuzz(pos)
	local hash = minetest.hash_node_position(pos)
	if celevator.drives.null.soundhandles[hash] == "cancel" then
		celevator.drives.null.soundhandles[hash] = nil
		return
	end
	if celevator.drives.null.soundhandles[hash] then return end
	celevator.drives.null.soundhandles[hash] = "pending"
	minetest.after(0.5,playbuzz,pos)
end

local function stopbuzz(pos)
	local hash = minetest.hash_node_position(pos)
	if not celevator.drives.null.soundhandles[hash] then return end
	if celevator.drives.null.soundhandles[hash] == "pending" then
		celevator.drives.null.soundhandles[hash] = "cancel"
	end
	if type(celevator.drives.null.soundhandles[hash]) ~= "string" then
		minetest.sound_stop(celevator.drives.null.soundhandles[hash])
		celevator.drives.null.soundhandles[hash] = nil
	end
end

minetest.register_node("celevator:drive_null",{
	description = celevator.drives.null.name,
	groups = {
		cracky = 1,
		not_in_creative_inventory = 1,
	},
	tiles = {
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_drive_front.png",
	},
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.4,-0.4,-0.1,0.4,0.4,0.5},
			{-0.5,-0.3,0.4,-0.4,-0.22,0.32},
			{-0.5,0.22,0.4,-0.4,0.3,0.32},
		},
	},
	_celevator_drive_type = "null",
	after_place_node = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("apos","0")
		meta:set_string("dpos","0")
		meta:set_string("vel","0")
		meta:set_string("maxvel","0.2")
		meta:set_string("doorstate","closed")
		update_ui(pos)
	end,
	on_destruct = stopbuzz,
})

function celevator.drives.null.step(dtime)
	if not celevator.drives.null.step_enabled then return end
	local nulldrives_running = minetest.deserialize(celevator.storage:get_string("nulldrives_running")) or {}
	local save = false
	for i,hash in ipairs(nulldrives_running) do
		save = true
		local pos = minetest.get_position_from_hash(hash)
		local node = celevator.get_node(pos)
		local sound = false
		if node.name == "ignore" then
			minetest.forceload_block(pos,true)
		elseif node.name ~= "celevator:drive_null" then
			table.remove(nulldrives_running,i)
		else
			local meta = minetest.get_meta(pos)
			local apos = tonumber(meta:get_string("apos")) or 0
			local dpos = tonumber(meta:get_string("dpos")) or 0
			local maxvel = tonumber(meta:get_string("maxvel")) or 0.2
			local dremain = math.abs(dpos-apos)
			local vel = maxvel
			if dremain < 0.5 then vel = math.min(0.2,vel) end
			local stepdist = vel*dtime
			if dpos > apos then
				local newpos = apos + stepdist
				if newpos < dpos then
					meta:set_string("apos",tostring(newpos))
					meta:set_string("vel",vel)
					sound = true
				else
					meta:set_string("apos",tostring(dpos))
					meta:set_string("vel",0)
					sound = false
				end
			elseif dpos < apos then
				local newpos = apos - stepdist
				if newpos > dpos then
					meta:set_string("apos",tostring(newpos))
						meta:set_string("vel",0-vel)
					sound = true
				else
					meta:set_string("apos",tostring(dpos))
					meta:set_string("vel",0)
					sound = false
				end
			else
				table.remove(nulldrives_running,i)
			end
		end
		update_ui(pos)
		if sound then
			startbuzz(pos)
		else
			stopbuzz(pos)
		end
	end
	if save then
		celevator.storage:set_string("nulldrives_running",minetest.serialize(nulldrives_running))
	end
	celevator.drives.null.step_enabled = save
end

minetest.register_globalstep(celevator.drives.null.step)

function celevator.drives.null.moveto(pos,target)
	local meta = minetest.get_meta(pos)
	meta:set_string("dpos",tostring(target))
	local hash = minetest.hash_node_position(pos)
	local nulldrives_running = minetest.deserialize(celevator.storage:get_string("nulldrives_running")) or {}
	local running = false
	for _,dhash in ipairs(nulldrives_running) do
		if hash == dhash then
			running = true
			break
		end
	end
	if not running then
		celevator.drives.null.step_enabled = true
		table.insert(nulldrives_running,hash)
		celevator.storage:set_string("nulldrives_running",minetest.serialize(nulldrives_running))
	end
end

function celevator.drives.null.resetpos(pos)
	celevator.drives.null.moveto(pos,0)
end

function celevator.drives.null.estop(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("dpos",meta:get_string("apos"))
	meta:set_string("vel","0")
end

function celevator.drives.null.setmaxvel(pos,maxvel)
	local meta = minetest.get_meta(pos)
	meta:set_string("maxvel",tostring(maxvel))
end

function celevator.drives.null.rezero(pos)
	celevator.drives.null.moveto(pos,0)
end

function celevator.drives.null.movedoors(drivepos,direction)
	local drivehash = minetest.hash_node_position(drivepos)
	local nulldrives_running = minetest.deserialize(celevator.storage:get_string("nulldrives_running")) or {}
	for _,hash in pairs(nulldrives_running) do
		if drivehash == hash then return end
	end
	local drivemeta = minetest.get_meta(drivepos)
	if direction == "open" then
		drivemeta:set_string("doorstate","opening")
		minetest.after(math.pi+0.5,function()
			minetest.get_meta(drivepos):set_string("doorstate","open")
		end)
	elseif direction == "close" then
		drivemeta:set_string("doorstate","closing")
		minetest.after((math.pi/0.66)+0.5,function()
			minetest.get_meta(drivepos):set_string("doorstate","closed")
		end)
	end
end

function celevator.drives.null.getstatus(pos,call2)
	local node = minetest.get_node(pos)
	if node.name == "ignore" and not call2 then
		minetest.forceload_block(pos,true)
		return celevator.drives.null.get_status(pos,true)
	elseif node.name ~= "celevator:drive_null" then
		minetest.log("error","[celevator] [null drive] Could not load drive status at "..minetest.pos_to_string(pos))
		return
	else
		local meta = minetest.get_meta(pos)
		local ret = {}
		ret.apos = tonumber(meta:get_string("apos")) or 0
		ret.dpos = tonumber(meta:get_string("dpos")) or 0
		ret.vel = tonumber(meta:get_string("vel")) or 0
		ret.maxvel = tonumber(meta:get_string("maxvel")) or 0.2
		ret.doorstate = meta:get_string("doorstate")
		ret.neareststop = ret.apos+(ret.vel*2)
		return ret
	end
end

function celevator.drives.null.resetfault(pos)
	--This drive has no possible faults at this time
	--(drive communication faults are generated by the controller),
	--but the controller expects to be able to call this
	minetest.get_meta(pos):set_string("fault","")
end

function celevator.drives.null.updatecopformspec()
	--No car means no COP
end

function celevator.drives.null.pibeep()
	--No car means no PI, no PI means no beep
end

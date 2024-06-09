---@meta _
-- globals we define are private to our plugin!
---@diagnostic disable: lowercase-global

-- here is where your mod sets up all the things it will do.
-- this file will not be reloaded if it changes during gameplay
-- 	so you will most likely want to have it reference
--	values and functions later defined in `reload.lua`.

-- Dictates how many loot choices game should try to show
modutil.mod.Path.Wrap("ChooseNextRoomData", function(base, ...)
	local room = base(...)
	local walk_room = get_next_room_on_walk()
	if walk_room ~= nil then
		print("Game wanted to go to " .. tostring(room.Name) .. " but we are walking to " .. walk_room.Name)
		return walk_room
	end
	return room
end)

modutil.mod.Path.Wrap("StartNewRun", function(base, ...)
	local return_val = base(...)
	if config.mode == Mode.TOUR then
		populate_walk_rooms()
	end
	return return_val
end)

modutil.mod.Path.Wrap("LeaveRoom", function ( base, ... )
	if config.mode == Mode.TOUR then
		if #walk_rooms > 0 then
			local removed_room = table.remove(walk_rooms, 1)
			print("Removed room " .. removed_room.Name)
		else
			print("No more rooms to walk to")
			modutil.mod.Hades.PrintOverhead("Tour concluded")
		end
	end

	return base(...)
end)

modutil.mod.Path.Wrap("AdjustZoom", function(base, args)
	args = args or {}
	prev_zoom_fraction = args.Fraction
	base(args)
end)

modutil.mod.Path.Override("CheckCancelSpawns", function(...)
	if game.CurrentRun.Encounter == nil then
		local encounter = game.DeepCopyTable(game.EncounterData["Empty"])
		encounter.ExitsDontRequireCompleted = true
		game.CurrentRun.ForceNextEncounterData = game.EncounterData["Empty"]
	end
	return true
end)

-- When cerby isn't there, the post kill function doesn't run and fix the camera and remove the ghost walls
modutil.mod.Path.Wrap("RoomEntranceBossFields", function(base, ...)
	base(...)
	thread(function ()
		wait(1)
		LockCamera({ Id = CurrentRun.Hero.ObjectId, Duration = 0.02, Retarget = true })
		Destroy({ Ids = GetIds({ Name = "Phase1Obstacles" }) })
	end)
end)

-- Prevent exceptions from boos not existing due to encounter override
modutil.mod.Path.Wrap("SetupBoss", function(base, ...)
	if not config.enabled then
		return base(...)
	end
end)

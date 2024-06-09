---@meta _
-- globals we define are private to our plugin!
---@diagnostic disable: lowercase-global

-- this file will be reloaded if it changes during gameplay,
-- so only assign to values or define things here.

walk_rooms = {}

local function get_room_data_for_name(room_name_to_find)
	return game.RoomSetData[room_name_to_find:sub(1, 1)][room_name_to_find]
end

function get_next_room_on_walk()
	if config.mode == Mode.FLASHCARD then
		local room_data = get_room_data_for_name("H_Combat05")--get_room_data_for_name("H_Combat" .. string.format("%02d", math.random(1,15)))
		room_data.Flipped = (math.random() < 0.5)
		return room_data
	end

	if #walk_rooms > 0 then
		return walk_rooms[1]
	end

	return nil
end

function populate_walk_rooms()
	local walk_room_names = {}
	for _, biome in ipairs({"F", "G", "H", "I"}) do
	-- for _, biome in ipairs({"H"}) do
			for room_name, room_data in pairs(game.RoomSetData[biome]) do
			if not room_data.DebugOnly then -- and room_name ~= "G_MiniBoss02" and room_name ~= "I_PostBoss01" then
				table.insert(walk_room_names, room_data.Name)
			end
		end
	end
	table.sort(walk_room_names)
	for _, room_name in ipairs(walk_room_names) do
		table.insert(walk_rooms, get_room_data_for_name(room_name))
	end
	print("Populated a walk of " .. tostring(#walk_room_names) .. " rooms: ".. sjson.encode(walk_room_names))
end

function cycle_zoom_level()
	local previousFraction = prev_zoom_fraction
	if previousFraction > 0.5 then
		AdjustZoom({ Fraction = 0.5, LerpTime = 0.5})
		HideCombatUI("ZenMode")
	elseif previousFraction > 0.25 then
		AdjustZoom({ Fraction = 0.25, LerpTime = 0.5})
		HideCombatUI("ZenMode")
	elseif previousFraction > 0.18 then
		AdjustZoom({ Fraction = 0.18, LerpTime = 0.5})
		HideCombatUI("ZenMode")
	elseif previousFraction > 0.1 then
		AdjustZoom({ Fraction = 0.1, LerpTime = 0.5})
		HideCombatUI("ZenMode")
	elseif CurrentRun and CurrentRun.CurrentRoom.ZoomFraction then
		AdjustZoom({ Fraction = CurrentRun.CurrentRoom.ZoomFraction, LerpTime = 0.75 })
		ShowCombatUI("ZenMode")
	else
		AdjustZoom({ Fraction = 1.0, LerpTime = 0.75 })
		ShowCombatUI("ZenMode")
	end
end

local function create_many_copies_of_obstacle(obstacle_name, destination_id, color, scale, spawn_record, times)
	for i=1,times do
		local spawn_id = SpawnObstacle({ Name = obstacle_name, Group = "New_group", DestinationId = destination_id, Attach = true, TriggerOnSpawn = false })
		table.insert(spawn_record, spawn_id)
		SetColor({ Id = spawn_id, Color = color, Duration = 0 })
		SetScale({ Id = spawn_id, Fraction = scale })
	end

end

local show_spawn_points = false
local spawn_points_to_destroy = {}
function toggle_spawn_points()
	show_spawn_points = not show_spawn_points
	if not show_spawn_points then
		for _, spawn_point in ipairs(spawn_points_to_destroy) do
			Destroy({Id = spawn_point})
		end
		return
	end

	-- spawn points
	for spawn_index, spawn_point in ipairs(game.MapState.SpawnPoints) do
		-- Green = in range, red = too close or too far (based on fields config)
		local dist = GetDistance({ Id = CurrentRun.Hero.ObjectId, DestinationId = spawn_point })
		local in_range = dist >= 600 and dist <= 2200
		local color = Color.Red
		if in_range then
			color = Color.Green
		end

		create_many_copies_of_obstacle("LightCircle", spawn_point, color, 0.5, spawn_points_to_destroy, 2)
	end

	-- Indicators for mel proximity
	-- RequireMinPlayerDistance = 600,
	-- RequireNearPlayerDistance = 2200,
	-- table.insert(spawn_points_to_destroy, SpawnObstacle({ Name = "CapturePointSwitch", Group = "New_group", DestinationId = CurrentRun.Hero.ObjectId, OffsetX = 600, Attach = true, TriggerOnSpawn = false }))
	-- table.insert(spawn_points_to_destroy, SpawnObstacle({ Name = "CapturePointSwitch", Group = "New_group", DestinationId = CurrentRun.Hero.ObjectId, OffsetX = 2200, Attach = true, TriggerOnSpawn = false }))
	-- table.insert(spawn_points_to_destroy, SpawnObstacle({ Name = "CapturePointSwitch", Group = "New_group", DestinationId = CurrentRun.Hero.ObjectId, OffsetY = 600, Attach = true, TriggerOnSpawn = false }))
	-- table.insert(spawn_points_to_destroy, SpawnObstacle({ Name = "CapturePointSwitch", Group = "New_group", DestinationId = CurrentRun.Hero.ObjectId, OffsetY = 2200, Attach = true, TriggerOnSpawn = false }))
	-- table.insert(spawn_points_to_destroy, SpawnObstacle({ Name = "CapturePointSwitch", Group = "New_group", DestinationId = CurrentRun.Hero.ObjectId, OffsetX = -600, Attach = true, TriggerOnSpawn = false }))
	-- table.insert(spawn_points_to_destroy, SpawnObstacle({ Name = "CapturePointSwitch", Group = "New_group", DestinationId = CurrentRun.Hero.ObjectId, OffsetX = -2200, Attach = true, TriggerOnSpawn = false }))
	-- table.insert(spawn_points_to_destroy, SpawnObstacle({ Name = "CapturePointSwitch", Group = "New_group", DestinationId = CurrentRun.Hero.ObjectId, OffsetY = -600, Attach = true, TriggerOnSpawn = false }))
	-- table.insert(spawn_points_to_destroy, SpawnObstacle({ Name = "CapturePointSwitch", Group = "New_group", DestinationId = CurrentRun.Hero.ObjectId, OffsetY = -2200, Attach = true, TriggerOnSpawn = false }))
end

local show_field_points = false
local field_points_to_destroy = {}
function toggle_fields_indicators()
	show_field_points = not show_field_points
	if not show_field_points then
		for _, spawn_point in ipairs(field_points_to_destroy) do
			Destroy({Id = spawn_point})
		end
		return
	end

	-- Minor rewards
	-- Create copies to make circle more solid
	for _, spawn_point in ipairs(GetIds({ Name = "BonusRewardSpawnPoints" })) do
		create_many_copies_of_obstacle("LightCircle", spawn_point, Color.Maroon, 1, field_points_to_destroy, 10)
	end

	-- Major rewards
	for _, spawn_point in ipairs(GetIdsByType({ Name = "LootPoint" })) do
		create_many_copies_of_obstacle("LightCircle", spawn_point, Color.Aqua, 1, field_points_to_destroy, 10)
	end

	-- Golden Bough
	for _, spawn_point in ipairs(GetIdsByType{Name="FieldsRewardFinder"}) do
		create_many_copies_of_obstacle("LightCircle", spawn_point, Color.Gold, 1, field_points_to_destroy, 10)
	end

	-- Hero entrances - HeroStart and HeroEnd are the start and end of the automated walk as you enter the room
	-- Could use GetAngleBetween({ Id = startId, DestinationId = entranceEndId }) to draw fancy arrow
	for spawn_index, spawn_point in ipairs(game.GetIdsByType{Name="HeroEnd"}) do
		create_many_copies_of_obstacle("LightCircle", spawn_point, Color.White, 1, field_points_to_destroy, 10)
	end
end

local show_harvest_points = false
local harvest_points_to_destroy = {}
local harvest_spawn_points_to_hide = {}
function toggle_harvest_points()
	show_harvest_points = not show_harvest_points
	if not show_harvest_points then
		Destroy({Ids = harvest_points_to_destroy})
		SetAlpha({ Ids = harvest_spawn_points_to_hide, Fraction = 0 })
		return
	end

	local harvest_types = {"ShovelPoint", "PickaxePoint", "ExorcismPoint", "HarvestPoint", "FishingPoint"}
	local harvest_type_colors = {
		ShovelPoint = Color.Brown,
		PickaxePoint = Color.White,
		ExorcismPoint = Color.Cyan,
		HarvestPoint = Color.Yellow,
		FishingPoint = Color.Blue
	}

	for _, harvest_type in ipairs(harvest_types) do
		for spawn_index, spawn_point in ipairs(GetInactiveIdsByType({ Name = harvest_type })) do
			Activate({ Ids = {spawn_point} })
			SetAlpha({ Ids = harvest_spawn_points_to_hide, Fraction = 1 })
			table.insert(harvest_spawn_points_to_hide, spawn_point)

			local spawn_id = SpawnObstacle({ Name = "LightCircle", Group = "New_group", DestinationId = spawn_point, Attach = true, TriggerOnSpawn = false })
			print("Spawning inactive " .. harvest_type .. " harvest point at " .. tostring(spawn_point))
			table.insert(harvest_points_to_destroy, spawn_id)
			SetColor({ Id = spawn_id, Color = harvest_type_colors[harvest_type], Duration = 0 })
			SetScale({ Id = spawn_id, Fraction = 0.5 })
		end
		for spawn_index, spawn_point in ipairs(GetIdsByType({ Name = harvest_type })) do
			SetAlpha({ Ids = harvest_spawn_points_to_hide, Fraction = 1 })
			table.insert(harvest_spawn_points_to_hide, spawn_point)

			local spawn_id = SpawnObstacle({ Name = "LightCircle", Group = "New_group", DestinationId = spawn_point, Attach = true, TriggerOnSpawn = false })
			print("Spawning " .. harvest_type .. " harvest point at " .. tostring(spawn_point))
			table.insert(harvest_points_to_destroy, spawn_id)
			SetColor({ Id = spawn_id, Color = harvest_type_colors[harvest_type], Duration = 0 })
			SetScale({ Id = spawn_id, Fraction = 0.5 })
		end
	end
end

OnAnyLoad{ function()
	local room_name = rom.mods['SGG_Modding-ModUtil'].mod.Path.Get("CurrentRun.CurrentRoom.Name")
	local is_flipped = rom.mods['SGG_Modding-ModUtil'].mod.Path.Get("CurrentRun.CurrentRoom.Flipped") or false
	local flip_text = ""
	if is_flipped then flip_text = " - Flip" end
	create_room_name_display(room_name .. flip_text)
	if config.mode == Mode.FLASHCARD then
		show_room_text(false)
	end
end}



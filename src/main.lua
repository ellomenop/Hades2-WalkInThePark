---@meta _
-- grabbing our dependencies,
-- these funky (---@) comments are just there
--	 to help VS Code find the definitions of things

---@diagnostic disable-next-line: undefined-global
local mods = rom.mods

---@module 'SGG_Modding-ENVY-auto'
mods['SGG_Modding-ENVY'].auto()
-- ^ this gives us `public` and `import`, among others
--	and makes all globals we define private to this plugin.
---@diagnostic disable: lowercase-global

---@diagnostic disable-next-line: undefined-global
rom = rom
---@diagnostic disable-next-line: undefined-global
_PLUGIN = PLUGIN

---@module 'SGG_Modding-Hades2GameDef-Globals'
game = rom.game
import_as_fallback(game)

---@module 'SGG_Modding-SJSON'
sjson = mods['SGG_Modding-SJSON']
---@module 'SGG_Modding-ModUtil'
modutil = mods['SGG_Modding-ModUtil']

---@module 'SGG_Modding-Chalk'
chalk = mods["SGG_Modding-Chalk"]
---@module 'SGG_Modding-ReLoad'
reload = mods['SGG_Modding-ReLoad']

---@module 'config'
config = chalk.auto 'config.lua'
-- ^ this updates our `.cfg` file in the config folder!
public.config = config -- so other mods can access our config

---@enum Mode
Mode = {
	FLASHCARD = "Flashcard",
	TOUR = "Tour",
--	ROOM = "Room"
}

---Creates imGui to toggle all filter values via checkboxes
local function setup_imGui_Config()
	rom.gui.add_imgui(function()
		if rom.ImGui.Begin("WalkInThePark Config") then
			for _, mode_name in pairs(Mode) do
				selected = rom.ImGui.RadioButton(mode_name, config.mode == mode_name)
				if selected then
					config.mode = mode_name
				end
			end
			rom.ImGui.End()
		end
	end)
end

local function on_ready()
	-- what to do when we are ready, but not re-do on reload.
	if config.enabled == false then return end

	import 'roomdisplay.lua'
	import 'ready.lua'
end

local function on_reload()
	-- what to do when we are ready, but also again on every reload.
	-- only do things that are safe to run over and over.
	prev_zoom_fraction = 0
	setup_imGui_Config()

	import 'reload.lua'

	rom.inputs.on_key_pressed{"Control Z", Name = "Cycle through zoom levels", cycle_zoom_level}
	rom.inputs.on_key_pressed{"Control X", Name = "Toggle enemy spawn points", toggle_spawn_points}
	-- rom.inputs.on_key_pressed{"Shift C", Name = "ToggleHarvestPoints", toggle_harvest_points}
	rom.inputs.on_key_pressed{"Control C", Name = "Toggle fields indicators", toggle_fields_indicators}

	-- rom.inputs.on_key_pressed{"Control V", Name = "UnlockExitDoors", function ()
	-- 	game.DoUnlockRoomExits(game.CurrentRun, game.CurrentRun.CurrentRoom)
	-- end}

end

-- this allows us to limit certain functions to not be reloaded.
local loader = reload.auto_single()

-- this runs only when modutil and the game's lua is ready
modutil.once_loaded.game(function()
	loader.load(on_ready, on_reload)
end)
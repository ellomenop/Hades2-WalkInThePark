---@diagnostic disable: lowercase-global

-- Use Chamber Number as default font style
local text_config_table = game.DeepCopyTable(UIData.CurrentRunDepth.TextFormat)
text_config_table.Justification = "left"
text_config_table.ShadowColor = {0, 0, 0, 0}
local x_pos = 1340
local y_pos = 30
local room_name_obstacle_name = "ellomenop-WalkInThePark_room_name"
local last_text = ""

function create_room_name_display(text)
    if game.ScreenAnchors[room_name_obstacle_name] ~= nil then
        game.Destroy({Id = game.ScreenAnchors[room_name_obstacle_name]})
    end
    game.ScreenAnchors[room_name_obstacle_name] = game.CreateScreenObstacle({
        Name = "BlankInteractableObstacle",
        X = x_pos,
        Y = y_pos,
        Group = "Combat_Menu_Overlay"
    })

    local obstacle_data = {Id = game.ScreenAnchors[room_name_obstacle_name]}
    obstacle_data.MouseOverSound = "/SFX/Menu Sounds/DialoguePanelOutMenu"
    obstacle_data.OnMouseOverFunctionName = "ellomenopRoomDisplayMouseOver"
    obstacle_data.OnMouseOffFunctionName = "ellomenopRoomDisplayMouseOff"
    game.AttachLua({ Id = obstacle_data.Id, Table = obstacle_data })

    last_text = text
    game.CreateTextBox(
        game.MergeTables(
            text_config_table,
            {
                Id = game.ScreenAnchors[room_name_obstacle_name],
                Text = "                   " .. text .. "                   " -- make big so you can hover larger area
            }
        )
    )

    game.ModifyTextBox({
        Id = game.ScreenAnchors[room_name_obstacle_name],
        FadeTarget = 1,
        FadeDuration = 0.0
    })
end

function game.ellomenopRoomDisplayMouseOver(moused_over_element)
    if config.mode == Mode.FLASHCARD then
        show_room_text(true)
    end
end

function game.ellomenopRoomDisplayMouseOff(moused_over_element)
    if config.mode == Mode.FLASHCARD then
        show_room_text(false)
    end
end

function show_room_text(visible)
    if not visible then
        game.ModifyTextBox({
            Id = game.ScreenAnchors[room_name_obstacle_name],
            Text = "                   Hover for room name", -- make big so you can hover larger area
        })
    elseif visible then
        game.ModifyTextBox({
            Id = game.ScreenAnchors[room_name_obstacle_name],
            Text = "                   " .. last_text .. "                   ",
        })
    end
end

function update_room_name_display(text)
    if text == nil then
        return
    end

    last_text = text
    game.ModifyTextBox({
        Id = game.ScreenAnchors[room_name_obstacle_name],
        Text = "                   " .. text .. "                   ", -- make big so you can hover larger area
    })
end
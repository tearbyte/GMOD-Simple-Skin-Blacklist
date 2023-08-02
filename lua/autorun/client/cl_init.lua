SSB = SSB or {}
TeraLib = TeraLib or {}

local function switch_keys_and_values(table)
    local new_table = {}
    for k, v in pairs(table) do
        new_table[v] = k
    end
    return new_table
end

function SSB.table_contains(tbl, x)
    found = false
    for _, v in pairs(tbl) do
        if v == x then 
            found = true 
        end
    end
    return found
end

function SSB.Init()
    -- We need both...
    SSB.models = player_manager.AllValidModels()
    SSB.inv_models = switch_keys_and_values(player_manager.AllValidModels())
end

function SSB:Error( error )
    chat.AddText(Color(255,0,0), error)
    surface.PlaySound("buttons/button8.wav")
end

net.Receive('ssb_refresh', function()
    SSB.data = net.ReadTable()
    local cur_model = GetConVar('cl_playermodel'):GetString()
    if SSB.data.disallowed_skins[cur_model] then
        RunConsoleCommand("cl_playermodel", SSB.data.alternative_skins[1])
    end

end)

concommand.Add('simple_skin_blacklist_menu', function()

	if !LocalPlayer():IsSuperAdmin() then SSB:Error(language.GetPhrase('#SSB.no_access')) return end

    SSB.panel = vgui.Create("DFrame")
    SSB:make_main_panel(SSB.panel)

    net.Start('ssb_refresh')
    net.WriteBit(0)
    net.SendToServer()
    
end)

net.Receive('ssb_death', function()
    local cur_model = GetConVar('cl_playermodel'):GetString()
    if !SSB.data.disallowed_skins[cur_model] then return end


    rand = math.Round(math.Rand(1, #SSB.data.alternative_skins))
    new_model = SSB.data.alternative_skins[rand]

    SSB:Error(language.GetPhrase('SSB.disallowed_skin'))

    RunConsoleCommand("cl_playermodel", new_model)

    net.Start('ssb_death')
    net.SendToServer()
end)

hook.Add('PlayerAuthed', 'SSB_Auto_Update', function()
    net.Start('ssb_refresh')
    net.SendToServer()
end)

SSB.Init()
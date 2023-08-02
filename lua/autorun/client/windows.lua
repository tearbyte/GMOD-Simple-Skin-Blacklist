local function create_skins_panel( panel, list_, alt )

    -- Панелька альтернативных/запрещённых скинов
    local list = vgui.Create("DListView", panel)
    list:SetMultiSelect(false)
    list:SetSize(260, 600)
    list:AddColumn('#modeln')
    list:AddColumn('#modelp')

    if !alt then
        for k, v in pairs(SSB.data.alternative_skins) do
            list:AddLine(v, SSB.models[v] or "[MISSING]")
        end
    else
        for k, v in pairs(list_) do
            list:AddLine(k, SSB.models[k] or "[MISSING]")
        end
    end

    return list

end

function SSB:make_main_panel( panel )
    panel:SetSize(1000, 630)
    panel:MakePopup()
    panel:SetTitle("#SSB")
   -- panel:SetDraggable(false)
    panel:Center()

    local main_model_panel = vgui.Create("DModelPanel", panel)
    main_model_panel:SetSize(170, 450)
    main_model_panel:Dock(LEFT)--SetPos(240, 0)
    main_model_panel:SetModel(LocalPlayer():GetModel())
    main_model_panel:SetFOV(30)
    main_model_panel:SetAnimated(0)

    -- Список моделек
    local modellist = create_skins_panel( panel )
    modellist:Dock(LEFT)

    for k, v in pairs(SSB.models) do
        modellist:AddLine(k, v)
    end

    modellist:SortByColumn(1)
    function modellist:OnRowSelected(rowIndex, row)
        main_model_panel:SetModel(row:GetColumnText(2))
    end

    SSB.panel.second_panel = vgui.Create("DPropertySheet", panel)
    SSB.panel.second_panel:SetSize(460, 400)
    SSB.panel.second_panel:Dock(RIGHT)

    local allowed_list_panel = vgui.Create("DPanel")
    local allowed_list = create_skins_panel( allowed_list_panel )

    function allowed_list:OnRowSelected(rowIndex, row)
        SSB.panel.model_panel:SetModel(row:GetColumnText(2))
    end

    SSB.panel.model_panel = vgui.Create("DModelPanel", allowed_list_panel)
    SSB.panel.model_panel:Dock(RIGHT)
    SSB.panel.model_panel:SetSize(190, 450)
    SSB.panel.model_panel:SetFOV(30)

    SSB.panel.model_panel:SetModel(allowed_list:GetLine(1):GetColumnText(2) or 'models/player/kleiner.mdl')

    local disallowed_list_panel = vgui.Create("DPanel")
    local disallowed_list = create_skins_panel(disallowed_list_panel, SSB.data.disallowed_skins, true)

    function disallowed_list:OnRowSelected(rowIndex, row)
        SSB.panel.model_panel_:SetModel(row:GetColumnText(2))
    end

    SSB.panel.model_panel_ = vgui.Create("DModelPanel", disallowed_list_panel)
    SSB.panel.model_panel_:Dock(RIGHT)
    SSB.panel.model_panel_:SetSize(190, 450)
    SSB.panel.model_panel_:SetFOV(30)
    SSB.panel.model_panel_:SetModel(disallowed_list:GetLine(1):GetColumnText(2))

    SSB.panel.second_panel:AddSheet( "#SSB.allowed_panel", allowed_list_panel, "icon16/accept.png" )
    SSB.panel.second_panel:AddSheet( "#SSB.disallowed_panel", disallowed_list_panel, "icon16/cancel.png" )

    -- Кнопочка добавления в список
    SSB.panel.add_button = vgui.Create('DButton', panel)
    SSB.panel.add_button:SetText('>>')
    SSB.panel.add_button:SetPos(450, 300)
    function SSB.panel.add_button:DoClick()
        skin = modellist:GetLine(modellist:GetSelectedLine())
        if !skin then return end
        skin_name, skin_path = skin:GetColumnText(1), skin:GetColumnText(2)

        if SSB.table_contains(SSB.data.alternative_skins, skin_name) then SSB:Error(language.GetPhrase('SSB.already_whitelisted')) return end
        if SSB.data.disallowed_skins[skin_name] then SSB:Error(language.GetPhrase('SSB.already_blacklisted')) return end

        if SSB.panel.second_panel:GetActiveTab():GetText() == language.GetPhrase("SSB.allowed_panel") then
            SSB.data.alternative_skins[#SSB.data.alternative_skins + 1] = skin_name
            allowed_list:Remove()
            allowed_list = create_skins_panel( allowed_list_panel )
            function allowed_list:OnRowSelected(rowIndex, row)
                SSB.panel.model_panel:SetModel(row:GetColumnText(2))
            end
        else
            SSB.data.disallowed_skins[skin_name] = true
            disallowed_list:Remove()
            disallowed_list = create_skins_panel(disallowed_list_panel, SSB.data.disallowed_skins, true)
            function disallowed_list:OnRowSelected(rowIndex, row)
                SSB.panel.model_panel_:SetModel(row:GetColumnText(2))
            end
        end

        net.Start('ssb_refresh')
        net.WriteBit(1)
        net.WriteTable(SSB.data)
        net.SendToServer()
    end

    -- Кнопочка удаления из списка
    SSB.panel.remove_button = vgui.Create('DButton', panel)
    SSB.panel.remove_button:SetText('X')
    SSB.panel.remove_button:SetPos(450, 330)
    function SSB.panel.remove_button:DoClick()

        if SSB.panel.second_panel:GetActiveTab():GetText() == language.GetPhrase("SSB.allowed_panel") then
            skin_path = allowed_list:GetSelectedLine()
            if !skin_path then return end
            SSB.data.alternative_skins[skin_path] = nil
            allowed_list:Remove()
            allowed_list = create_skins_panel( allowed_list_panel )
            function allowed_list:OnRowSelected(rowIndex, row)
                SSB.panel.model_panel:SetModel(row:GetColumnText(2))
            end
        else
            skin = disallowed_list:GetLine(disallowed_list:GetSelectedLine())
            if !skin then return end
            skin_path = skin:GetColumnText(1)
            SSB.data.disallowed_skins[skin_path] = nil
            disallowed_list:Remove()
            disallowed_list = create_skins_panel(disallowed_list_panel, SSB.data.disallowed_skins, true)
            function disallowed_list:OnRowSelected(rowIndex, row)
                SSB.panel.model_panel_:SetModel(row:GetColumnText(2))
            end
        end

        net.Start('ssb_refresh')
        net.WriteBit(1)
        net.WriteTable(SSB.data)
        net.SendToServer()
    end

    local settings = vgui.Create('SSB_Settings_Panel')
    SSB.panel.second_panel:AddSheet( "#SSB.settings_panel", settings, "icon16/cog.png" )

    local about = vgui.Create('SSB_About_Panel')
    SSB.panel.second_panel:AddSheet( "#SSB.about_panel", about, "icon16/monitor.png" )

end

local SETTINGS_PANEL = {}

function SETTINGS_PANEL:Init()
    local BLACK = Color(0, 0, 0)

    local enable = vgui.Create('DCheckBoxLabel', self)
    enable:SetText('#SSB.settings_panel.enable')
    enable:SetConVar('simple_skin_blacklist_enable')
    enable:Dock(LEFT)
    enable:Dock(TOP)
    enable:DockMargin(10, 10, 0, 0)
    enable:SetTextColor(BLACK)

    local supress_admins = vgui.Create('DCheckBoxLabel', self)
    supress_admins:SetText('#SSB.settings_panel.supress_admins')
    supress_admins:SetConVar('simple_skin_blacklist_supress_admin')
    supress_admins:Dock(LEFT)
    supress_admins:Dock(TOP)
    supress_admins:DockMargin(10, 5, 0, 0)
    supress_admins:SetTextColor(BLACK)

    local supress_superadmins = vgui.Create('DCheckBoxLabel', self)
    supress_superadmins:SetText('#SSB.settings_panel.supress_superadmins')
    supress_superadmins:SetConVar('simple_skin_blacklist_supress_superadmin')
    supress_superadmins:Dock(LEFT)
    supress_superadmins:Dock(TOP)
    supress_superadmins:DockMargin(10, 5, 0, 0)
    supress_superadmins:SetTextColor(BLACK)
end

vgui.Register('SSB_Settings_Panel', SETTINGS_PANEL, 'DPanel')

local ABOUT_PANEL = {}

function ABOUT_PANEL:Init()
    local text = vgui.Create('DLabel', self)
    text:SetTextColor(Color(0, 0, 0))
    text:SetText('#SSB.about')
    text:SetPos(5, 5)
    text:SetSize(460, 90)

    local people = vgui.Create('DPanel', self)
    people:Dock(BOTTOM)
    people:SetBackgroundColor(Color(100, 100, 100))
    people:SetSize(200, 230)

    local ply = LocalPlayer()

    best_people = {
        {
            Nickname = '_Terabyte_',
            ID = "76561198185782857",
            Why = language.GetPhrase("SSB.creator")
        },
        {
            Nickname = 'NFS-NIK',
            ID = "76561198251326850",
            Why = language.GetPhrase("SSB.mentor")
        },
        {
            Nickname = ply:Nick(),
            ID = tostring(ply:SteamID64()),
            Why = language.GetPhrase("SSB.player")
        }
    }


    for _, v in pairs(best_people) do
        local human = vgui.Create('DPanel', people)
        human:SetSize(195, 70)
        human:Dock(BOTTOM)
        human:DockMargin(5, 0, 5, 5)

        local avatar = vgui.Create('AvatarImage', human)
        avatar:Dock(LEFT)
        avatar:DockMargin(3, 3, 3, 3)
        avatar:SetSteamID(v.ID, 64)
        avatar:SetSize(64, 64)
        avatar:SetCursor("hand")
        avatar:SetMouseInputEnabled(true)
        function avatar:OnMousePressed()
            gui.OpenURL('https://steamcommunity.com/profiles/' .. v.ID)
        end

        local nick = vgui.Create('DLabel', human)
        nick:Dock(RIGHT)
        nick:Dock(TOP)
        nick:DockMargin(3, 1, 0, 0)
        nick:SetTextColor(Color(0, 0, 0))
        nick:SetText(v.Nickname)

        local dsc = vgui.Create('DLabel', human)
        dsc:Dock(RIGHT)
        dsc:Dock(TOP)
        dsc:DockMargin(3, 0, 0, 0)
        dsc:SetTextColor(Color(0, 0, 0))
        dsc:SetSize(100, 15)
        dsc:SetText(v.Why)
    end
end

vgui.Register('SSB_About_Panel', ABOUT_PANEL, 'DPanel')
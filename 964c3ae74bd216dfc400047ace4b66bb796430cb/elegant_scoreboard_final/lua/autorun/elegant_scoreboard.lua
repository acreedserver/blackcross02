--[[
     _____ _                        _     _____ _____ ___________ ___________  _____  ___  ____________
    |  ___| |                      | |   /  ___/  __ \  _  | ___ \  ___| ___ \|  _  |/ _ \ | ___ \  _  \
    | |__ | | ___  __ _  __ _ _ __ | |_  \ `--.| /  \/ | | | |_/ / |__ | |_/ /| | | / /_\ \| |_/ / | | |
    |  __|| |/ _ \/ _` |/ _` | '_ \| __|  `--. \ |   | | | |    /|  __|| ___ \| | | |  _  ||    /| | | |
    | |___| |  __/ (_| | (_| | | | | |_  /\__/ / \__/\ \_/ / |\ \| |___| |_/ /\ \_/ / | | || |\ \| |/ /
    \____/|_|\___|\__, |\__,_|_| |_|\__| \____/ \____/\___/\_| \_\____/\____/  \___/\_| |_/\_| \_|___/
                  __/ |
                 |___/

    Coded by: ted.lua (http://steamcommunity.com/id/tedlua/)
--]]
if SERVER then AddCSLuaFile( 'scoreboard_config.lua' ) end
include( 'scoreboard_config.lua' )

if !CLIENT then return end

local Elegant = nil
--local x, y = ScrW(), ScrH()

surface.CreateFont( "ElegantScoreFont", { font = "Montserrat", size = 35, weight = 800, antialias = true, bold = true } )
surface.CreateFont( "ElegantScoreFontSmall", { font = "Tahoma", size = 25, weight = 0, antialias = true, bold = true } )
surface.CreateFont( "ElegantScoreFontUnder", { font = "Montserrat", size = 17, weight = 0, antialias = true, bold = true } )
surface.CreateFont( "ElegantScoreFontTiny", { font = "Montserrat", size = 20, weight = 700, antialias = true, bold = true } )
surface.CreateFont( "ElegantScoreFontMedium", { font = "Montserrat", size = 30, weight = 700, antialias = true, bold = true } )
surface.CreateFont( "ElegantScoreFontHeader", { font = "Montserrat", size = 20, weight = 700, antialias = true, bold = true } )

-- Because it's being a pain in the ass, force set spacing if needed.
local text = {
    { tag = 'Name', spacing = 0 },
    { tag = 'Job', spacing = 10 },
    { tag = 'Rank', spacing = 145 },
    { tag = 'Kills', spacing = 240 },
    { tag = 'Deaths', spacing = 260 },
    { tag = 'Ping', spacing = 280 }
}

local function CanSee()
    if !Elegant_Score_Config.StaffGroups[ LocalPlayer():GetUserGroup() ] then
        return false
    end
    return true
end

local function GetNewX( self, x )
    if IsValid( self ) then
        if self.VBar.Enabled then x = x + 9 end
        return x
    end
end

local function DrawTextHeaders()
    for k, v in pairs( text ) do
        if k == 1 then
            ElegantDrawing.DrawText( v.tag, "ElegantScoreFontHeader", 70, 77, Color( 255, 255, 255 ) )
        else
            ElegantDrawing.DrawText( v.tag, "ElegantScoreFontHeader", 250 + ( 60 * k ) + v.spacing, 77, Color( 255, 255, 255 ) )
        end
    end
end

local function CreateSimpleButton( parent, x, y, txt, font, col, target, click, cusFunc )
    local self = vgui.Create( 'DButton', parent )
    self:SetPos( x, y )
    self:SetSize( 120, 40 )
    self:SetFont( font )
    self:SetText( txt )
    self:SetTextColor( col )
    --if click then self.DoClick = click end
    if !cusFunc then
        self.DoClick = function()
            -- Check the target is still on the server when executing
            if !IsValid( target ) then return end
            LocalPlayer():ConCommand( click )
        end
    else
        self.DoClick = cusFunc
    end
    self.OnCursorEntered = function( me, w, h ) self.Hover = true end
    self.OnCursorExited = function( me, w, h ) self.Hover = false end
    self.Paint = function( me, w, h )
        if self.Hover then
            ElegantDrawing.DrawRect( 0, 0, w, h, Color( 12, 12, 12, 100 ) )
        else
            ElegantDrawing.DrawRect( 0, 0, w, h, Color( 32, 32, 32, 200 ) )
        end
    end
    return self
end

local function TranslateGroup( x, c )
    if not c then
        if Elegant_Score_Config.Groups[ x ] then
            return Elegant_Score_Config.Groups[ x ].name
        else
            return 'User'
        end
    else
        if Elegant_Score_Config.Groups[ x ] then
            return Elegant_Score_Config.Groups[ x ].color
        else
            return Color( 255, 255, 255 )
        end
    end
end

local function ElegantCreateInspect( x )
    Inspect = vgui.Create( 'DFrame' )
    Inspect:SetSize( 400, 610 )
    Inspect:SetTitle( '' )
    Inspect:SetDraggable( false )
    Inspect:SetVisible( true )
    Inspect:ShowCloseButton( false )
    Inspect:Center()
    Inspect.Paint = function( me, w, h )
        if !IsValid( x ) then Inspect:Remove() return end
        ElegantDrawing.DrawRect( 0, 0, w, h, Color( 22, 22, 22 ) )
        ElegantDrawing.DrawRect( 5, 50, w - 10, 3, Color( 3,169,244, 255 ) ) -- Blue line
        ElegantDrawing.DrawRect( 5, 5, w - 10, 3, Color( 3,169,244, 255 ) ) -- Blue line

        ElegantDrawing.DrawRect( 5, 12, w - 10, 37, Color( 36, 36, 36, 230 ) )
        ElegantDrawing.DrawOutlinedRect( 0, 0, w, h, 4, Color( 0, 0, 0 ) )

        ElegantDrawing.DrawRect( 5, h / 2 + 110, w - 10, 3, Color( 178, 34, 34 ) )
        ElegantDrawing.DrawRect( 5, h / 2 + 50, w - 10, 3, Color( 178, 34, 34 ) )

        ElegantDrawing.DrawText( x:Nick(), "ElegantScoreFontMedium", w / 2, 15, Color( 255, 255, 255 ) )
        ElegantDrawing.DrawText( TranslateGroup( x:GetUserGroup(), false ), "ElegantScoreFontMedium", w / 2 - 5, 70, TranslateGroup( x:GetUserGroup(), true ) )
        ElegantDrawing.DrawText( x:SteamID(), "ElegantScoreFontMedium", w / 2, h / 2 + 65, Color( 255, 255, 255 ) )
        ElegantDrawing.DrawText( 'Basic Commands', "ElegantScoreFontMedium", w / 2, h / 2 + 125, Color( 255, 255, 255 ) )
    end

    local model = vgui.Create( 'DModelPanel', Inspect )
    model:SetSize( 210, 225 )
    model:SetPos( 90, 115 )
    model:SetModel( x:GetModel() )
    --model:SetAnimated(true)
    model:SetMouseInputEnabled( true )
    model:SetCamPos( Vector( 50, 0, 60 ) )
    function model:LayoutEntity( Entity ) return end
    local obj = baseclass.Get( 'DModelPanel' )
    model.Paint = function( me, w, h )
        ElegantDrawing.DrawRect( 0, 0, w, h, Color( 28, 28, 28, 200 ) )
        obj.Paint( me, w, h )
    end

    local steam_copy = vgui.Create( 'DImageButton', Inspect )
    steam_copy:SetPos( Inspect:GetWide() / 2 + 150, Inspect:GetTall() / 2 + 73 )
    steam_copy:SetSize( 16, 16 )
    steam_copy:SetIcon( 'icon16/paste_plain.png' )
    steam_copy.DoClick = function()
        if !IsValid( x ) then return end
        SetClipboardText( x:SteamID() )
        LocalPlayer():ChatPrint( x:Nick() .. "'s SteamID has been copied to your clipboard." )
    end

    CreateSimpleButton( Inspect, 15, Inspect:GetTall() / 2 + 175, 'Teleport To', 'ElegantScoreFontTiny', Color( 255, 255, 255 ), x, 'ulx goto ' .. x:Nick() )
    CreateSimpleButton( Inspect, 140, Inspect:GetTall() / 2 + 175, 'Bring', 'ElegantScoreFontTiny', Color( 255, 255, 255 ), x, 'ulx bring ' .. x:Nick() )
    CreateSimpleButton( Inspect, Inspect:GetWide() / 2 + 65, Inspect:GetTall() / 2 + 175, x.FreezeState and x.FreezeState or 'Freeze', 'ElegantScoreFontTiny', Color( 255, 255, 255 ), x, nil, function( self )
        -- This way it saves their previous state, even if closed. I could make a table, but it's a waste of time.
        -- Concommands have their own checks server-side, so no issues with running these.
        if !x.Is_Frozen then
            x.FreezeState = 'Unfreeze'
            self:SetText( x.FreezeState )
            LocalPlayer():ConCommand( 'ulx freeze ' .. x:Nick() )
            x.Is_Frozen = true
        else
            x.FreezeState = 'Freeze'
            self:SetText( x.FreezeState )
            LocalPlayer():ConCommand( 'ulx unfreeze ' .. x:Nick() )
            x.Is_Frozen = false
        end
    end )
    CreateSimpleButton( Inspect, 80, Inspect:GetTall() / 2 + 225, x.JailState and x.JailState or 'Jail', 'ElegantScoreFontTiny', Color( 255, 255, 255 ), x, nil, function( self )
        -- This way it saves their previous state, even if closed. I could make a table, but it's a waste of time.
        -- Concommands have their own checks server-side, so no issues with running these.
        if !x.Is_Jailed then
            x.JailState = 'Unjail'
            self:SetText( x.JailState )
            LocalPlayer():ConCommand( 'ulx jail ' .. x:Nick() )
            x.Is_Jailed = true
        else
            x.JailState = 'Jail'
            self:SetText( x.JailState )
            LocalPlayer():ConCommand( 'ulx unjail ' .. x:Nick() )
            x.Is_Jailed = false
        end
    end )
    CreateSimpleButton( Inspect, 210, Inspect:GetTall() / 2 + 225, 'Spectate', 'ElegantScoreFontTiny', Color( 255, 255, 255 ), x, 'fspectate ' .. x:Nick() )
end

local function ElegantCreateBase()
    Elegant = vgui.Create( 'DFrame' )
    Elegant:SetSize( 1000, 700 )
    Elegant:SetTitle( '' )
    Elegant:SetDraggable( false )
    Elegant:SetVisible( true )
    Elegant:ShowCloseButton( false )
    Elegant:Center()
    gui.EnableScreenClicker( true )
    Elegant.Paint = function( me, w, h )
        ElegantDrawing.BlurMenu( me, 13, 20, 200 )
        ElegantDrawing.DrawRect( 0, 0, w, h, Color( 8, 8, 8, 253 ) )
        ElegantDrawing.DrawRect( 0, 0, w, h / 2, Color( 14, 14, 14, 100 ) )
        ElegantDrawing.DrawRect( 10, 73, w - 20, 30, Color( 34, 34, 34, 150 ) )
        DrawTextHeaders()
        ElegantDrawing.DrawText( Elegant_Score_Config.ServerName, "ElegantScoreFont", w / 2, 5, Color( 255, 255, 255 ) )
        ElegantDrawing.DrawText( #player.GetAll() == 1 and 'There is currently 1 person online.' or 'There are currently ' .. #player.GetAll() .. " players online.", "ElegantScoreFontUnder", w / 2, h - 19, Color( 3,169,244, 255 ) )
    end

    local website = vgui.Create( 'DLabel', Elegant )
    website:SetPos( Elegant:GetWide() / 2 - 90, -22 )
    website:SetSize( 200, 150 )
    website:SetFont( "ElegantScoreFontSmall" )
    website:SetTextColor( Color( 3,169,244, 255 ) )
    website:SetText( Elegant_Score_Config.WebsiteLink )
    website:SetCursor( "hand" )
    website:SetMouseInputEnabled( true )
    website.OnMousePressed = function()
        gui.OpenURL( 'http://' .. Elegant_Score_Config.WebsiteLink )
    end

    Elegant.PlayerList = vgui.Create( "DPanelList", Elegant )
    Elegant.PlayerList:SetSize( Elegant:GetWide() - 20, Elegant:GetTall() - 130 )
    Elegant.PlayerList:SetPos( 10, 110 )
    Elegant.PlayerList:SetSpacing( 2 )
    Elegant.PlayerList:EnableVerticalScrollbar( true )
    --Elegant.PlayerList:SetStretchHorizontally( false )

    Elegant.PlayerList.Paint = function( me, w, h )
        ElegantDrawing.DrawRect( 0, 0, w, h, Color( 26, 26, 26, 200 ) )
    end

    local sbar = Elegant.PlayerList.VBar
    function sbar:Paint( w, h )
        ElegantDrawing.DrawRect( 0, 0, w, h, Color( 0, 0, 0, 100 ) )
    end
    function sbar.btnUp:Paint( w, h )
        ElegantDrawing.DrawRect( 0, 0, w, h, Color( 44, 44, 44 ) )
    end
    function sbar.btnDown:Paint( w, h )
        ElegantDrawing.DrawRect( 0, 0, w, h, Color( 44, 44, 44 ) )
    end
    function sbar.btnGrip:Paint( w, h )
        ElegantDrawing.DrawRect( 0, 0, w, h, Color( 56, 56, 56 ) )
    end

    for _, x in pairs( player.GetAll() ) do
        local item = vgui.Create( 'DPanel', Elegant.PlayerList )
        item:SetSize( Elegant.PlayerList:GetWide() - 70, 30 )
        local teamCol = team.GetColor( x:Team() )

        local self = Elegant.PlayerList
        local _y = 7

        item.Paint = function( me, w, h )
            if !IsValid( x ) then item:Remove() return end
            if _ % 2 == 0 then
                ElegantDrawing.DrawRect( 0, 0, w, h, Color( 44, 44, 44, 200 ) )
            else
                ElegantDrawing.DrawRect( 0, 0, w, h, Color( 32, 32, 32, 200 ) )
            end


            ElegantDrawing.DrawText( x:Nick(), "ElegantScoreFontTiny", 40, 4, TranslateGroup( x:GetUserGroup(), true ), TEXT_ALIGN_LEFT )
            ElegantDrawing.DrawText( team.GetName( x:Team() ), "ElegantScoreFontTiny", GetNewX( self, w / 2 - 148 ), 4, team.GetColor( x:Team() ), TEXT_ALIGN_LEFT )
            ElegantDrawing.DrawText( TranslateGroup( x:GetUserGroup(), false ), "ElegantScoreFontTiny", GetNewX( self, w / 2 + 75 ), 3, TranslateGroup( x:GetUserGroup(), true ) )
            ElegantDrawing.DrawText( x:Frags() < 0 and 0 or x:Frags(), "ElegantScoreFontTiny", GetNewX( self, w / 2 + 220 ), 4, Color( 255, 255, 255 ), TEXT_ALIGN_LEFT )
            ElegantDrawing.DrawText( x:Deaths(), "ElegantScoreFontTiny", GetNewX( self, w / 2 + 300 ), 4, Color( 255, 255, 255 ), TEXT_ALIGN_LEFT )
            ElegantDrawing.DrawText( x:Ping(), "ElegantScoreFontTiny", GetNewX( self, w - 100 ), 4, Color( 255, 255, 255 ) )

        end

        local bounds = vgui.Create( "DLabel", item )
        bounds:SetSize( item:GetWide() - 5, item:GetTall() )
        bounds:SetPos( 0, 0 )
        bounds:SetText( "" )
        bounds:SetMouseInputEnabled( true )

        bounds.DoDoubleClick = function()
            if !CanSee() then return end
            if IsValid( Inspect ) then
                Inspect:Remove()
            end
            ElegantCreateInspect( x )
        end

        local image = vgui.Create( "AvatarImage", item )
        image:SetSize( 28, 28 )
        image:SetPos( 1, 1 )
        image:SetPlayer( x, 32 )

        local mute = vgui.Create( "DImageButton", item )
        mute:SetSize( 16, 16 )
        mute:SetPos( GetNewX( self, item:GetWide() + 35 ), 7 )
        mute:SetImage( x:IsMuted() and 'icon16/sound_mute.png' or 'icon16/sound.png' )

        mute.DoClick = function()
            if !x:IsMuted() then x:SetMuted( true ) else x:SetMuted( false ) end
            mute:SetImage( x:IsMuted() and 'icon16/sound_mute.png' or 'icon16/sound.png' )
        end

        Elegant.PlayerList:AddItem( item )
    end
end

local function ElegantHide()
    Elegant:SetVisible( false )
    gui.EnableScreenClicker( false )
end

hook.Add( 'ScoreboardShow', 'ELEGANT_CREATE_BOARD', function()
    ElegantCreateBase()
    return true
end )

hook.Add( 'ScoreboardHide', 'ELEGANT_REMOVE_BOARD', function()
    if IsValid( Elegant ) then ElegantHide() end
    if IsValid( Inspect ) then Inspect:Remove() end
    return true
end )

if SERVER then

    util.AddNetworkString( "SendScreen" )
    --util.AddNetworkString( "SendScreenCallback" )
    util.AddNetworkString( "SendScreenInteractive" )
    util.AddNetworkString( "SendScreenInteractiveCallback" )
    util.AddNetworkString( "EndScreen" )
    --util.AddNetworkString( "EndScreenCallback" )

    CreateConVar( "LFG_EnableIceOverlay", 1, { FCVAR_ARCHIVE }, "If set to 1, enables the interactive ice-over overlay" )
    CreateConVar( "LFG_EnableOSUpdateOverlay", 1, { FCVAR_ARCHIVE }, "If set to 1, enables the interactive OS update overlay" )
    CreateConVar( "LFG_EnableOSCrashOverlay", 1, { FCVAR_ARCHIVE }, "If set to 1, enables the interactive OS crash overlay" )
    CreateConVar( "LFG_EnableGameCrashOverlay", 1, { FCVAR_ARCHIVE }, "If set to 1, enables the interactive game crash overlay" )
    CreateConVar( "LFG_EnableDynamicFreezing", 0, { FCVAR_ARCHIVE }, "If set to 1, enables the interactive freezing,"
        .. " interactive freezing allows the victim to interact with some puzzle in order to escape being frozen sooner" )
    CreateConVar( "LFG_FreezeGunTime", 6, { FCVAR_ARCHIVE }, "How long the frozen player remains unable to move" )

    hook.Add( "DoPlayerDeath", "KilledWhileFrozen", function( vic )
        if vic:IsFlagSet( FL_FROZEN ) then
            vic:Freeze( false )
            vic:SetDSP( 0, false )
            vic:EmitSound( "effects/UnfreezeKilled.wav")
            vic:SetMaterial( "" ) --Leave blank to reset the material

            net.Start( "EndScreen" )
            net.Send( vic )

            local data = EffectData()
            data:SetOrigin( vic:GetPos() + Vector( 0, 0, 40 ) )
            local scale = 4 + math.Rand( -0.25, 1.25 )
            local phys = vic:GetPhysicsObject()
            if IsValid( phys ) then
                scale = scale + phys:GetMass() * 0.001
            end
            data:SetScale( scale )
            data:SetMagnitude( 10 )
            util.Effect( "GlassImpact", data, true, true )

            local toDelete = vic:GetRagdollEntity()
            if toDelete then toDelete:Remove() end
        end
    end )

end

if CLIENT then
    local Screen, savedInt

    surface.CreateFont( "Windows10Font", {
        font = "Segoe UI",
        extended = true, --dunno
        size = 13, --default
        weight = 500, --default
        antialias = true --default
    } )

    net.Receive( "SendScreenInteractive", function()
        savedInt = net.ReadInt( 9 )
        local overlayType = net.ReadString()

        --Ugly-ass if statement, but necessary since I have additional functionality dependent on the option
        if system.IsLinux or system.IsOSX then
            --say something here about being lame
            DefaultOverlay()
        elseif overlayType == "LFG_EnableIceOverlay" then --Ice overlay
            IceInteractiveOverlay()
        elseif overlayType == "LFG_EnableOSUpdateOverlay" then
            OSUpdateInteractiveOverlay()
        elseif overlayType == "LFG_EnableOSCrashOverlay" then
            OSCrashInteractiveOverlay()
        elseif overlayType == "LFG_EnableGameCrashOverlay" then
            CaptureScreenForGameCrashOverlay() --Runs a bit unique here
        else
            DefaultOverlay()
        end

    end )

    net.Receive( "SendScreen", DefaultOverlay )

    net.Receive( "EndScreen", function() --All this should do is close the screen, everything else should be done for us
        CloseOverlay()
    end  )

    function MuteThem()
        for k, v in pairs( player.GetAll() ) do
            v:SetMuted( true )
        end
    end

    function UnMuteThem()
        for k, v in pairs( player.GetAll() ) do
            if v:Alive() then
                v:SetMuted( false )
            end
        end
    end

    function DefaultOverlay()
        if IsValid( Screen ) and ispanel( Screen ) then return end
        timer.Simple( 2, function() LocalPlayer():SetDSP( 14, false ) end )

        Screen = vgui.Create( "DFrame" )
        Screen:SetSize( ScrW(), ScrH() )
        Screen:SetPos( 0, 0 )
        Screen:SetTitle( "" )
        Screen:SetVisible( true )
        Screen:SetDraggable( false )
        Screen:ShowCloseButton( false )
        Screen.Paint = function()
        end

        local IceOverlay = Material( "ui/frosted.png" ) --Smooth 1
        overlayPanel = vgui.Create( "DPanel", Screen )
        overlayPanel:SetSize( Screen:GetWide(), Screen:GetTall() )
        overlayPanel:SetPos( 0, 0 )
        overlayPanel.Paint = function()
            overlayPanel.alphaCounter = overlayPanel.alphaCounter or 0
            if overlayPanel.alphaCounter <= 254 then overlayPanel.alphaCounter = overlayPanel.alphaCounter + 0.5 end
            surface.SetDrawColor( 255, 255, 255, overlayPanel.alphaCounter )
            surface.SetMaterial( IceOverlay )
            surface.DrawTexturedRect( 0, 0, overlayPanel:GetWide(), overlayPanel:GetTall() )
        end
    end

    function CloseOverlay()
        if Screen and ispanel( Screen ) then Screen:Remove() end
        UnMuteThem()
    end

    function CompletedMinigame()
        net.Start( "SendScreenInteractiveCallback" ) --To be called only when the player SUCCESSFULLY completes the minigame
            net.WriteInt( savedInt, 9 )
        net.SendToServer()
    end

    function IceInteractiveOverlay()
        if IsValid( Screen ) and ispanel( Screen ) then return end
        timer.Simple( 2, function() LocalPlayer():SetDSP( 14, false ) end )

        Screen = vgui.Create( "DFrame" )
        Screen:SetSize( ScrW(), ScrH() )
        Screen:SetPos( 0, 0 )
        Screen:SetTitle( "" )
        Screen:SetVisible( true )
        Screen:SetDraggable( false )
        Screen:ShowCloseButton( false )
        Screen:MakePopup()
        Screen.Paint = function()
        end

        local IceOverlay = Material( "ui/frosted.png" ) --Smooth 1
        overlayPanel = vgui.Create( "DPanel", Screen )
        overlayPanel:SetSize( Screen:GetWide(), Screen:GetTall() )
        overlayPanel:SetPos( 0, 0 )
        overlayPanel.Paint = function()
            overlayPanel.alphaCounter = overlayPanel.alphaCounter or 0
            if overlayPanel.alphaCounter <= 254 then overlayPanel.alphaCounter = overlayPanel.alphaCounter + 1 end
            surface.SetDrawColor( 255, 255, 255, overlayPanel.alphaCounter )
            surface.SetMaterial( IceOverlay )
            surface.DrawTexturedRect( 0, 0, overlayPanel:GetWide(), overlayPanel:GetTall() )
        end
    end

    function OSUpdateInteractiveOverlay()
        Screen = vgui.Create( "DFrame" )
        Screen:SetSize( ScrW(), ScrH() )
        Screen:SetPos( 0, 0 )
        Screen:SetTitle( "" )
        Screen:SetVisible( true )
        Screen:SetDraggable( false )
        Screen:ShowCloseButton( false )
        Screen:MakePopup()
        
        local UpdateImage, FooledYou = Material( "ui/windows10update.png" ), false
        overlayPanel = vgui.Create( "DPanel", Screen )
        overlayPanel:SetSize( Screen:GetWide(), Screen:GetTall() )
        overlayPanel:SetPos( 0, 0 )
        overlayPanel.Paint = function()
            surface.SetDrawColor( 255, 255, 255 )
            surface.SetMaterial( UpdateImage )
            surface.DrawTexturedRect( 0, 0, overlayPanel:GetWide(), overlayPanel:GetTall() )
        end

        local function FooledYou()
            local failedImage = Material( "" )
            local failedPanel = vgui.Create( "DPanel", overlayPanel )
            failedPanel:SetPos( 0, 0 )
            failedPanel:SetSize( overlayPanel:GetWide(), overlayPanel:GetTall() )
            failedPanel.Paint = function()
                surface.SetDrawColor( 255, 255, 255 )
                --surface.SetMaterial( failedImage )
                --surface.DrawTexturedRect( 0, 0, failedPanel:GetWide(), failedPanel:GetTall() )
                surface.SetDrawColor( ) --Need the windows 10 blue RGB
                surface.DrawRect( 0, 0, failedPanel:GetWide(), failedPanel:GetTall() )
                draw.DrawText( "Fooled you.", "Windows10Font", failedPanel:GetWide() / 2, failedPanel:GetTall() / 2, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
            end
        end

        local buttonImage1 = Material( "" )
        fakeButton1 = vgui.Create( "DButton", overlayPanel )
        fakeButton1:SetPos()
        fakeButton1:SetSize()
        fakeButton1:SetText( "" )
        fakeButton1.Paint = function()
            surface.SetDrawColor( 255, 255, 255 )
            surface.SetMaterial( buttonImage1 )
            surface.DrawTexturedRect( 0, 0, fakeButton1:GetWide(), fakeButton1:GetTall() )
        end
        fakeButton1.DoClick = function()
            FooledYou()
        end

        local buttonImage2 = Material( "" )
        fakeButton2 = vgui.Create( "DButton", overlayPanel )
        fakeButton2:SetPos()
        fakeButton2:SetSize()
        fakeButton2:SetText( "" )
        fakeButton2.Paint = function()
            surface.SetDrawColor( 255, 255, 255 )
            surface.SetMaterial( buttonImage2 )
            surface.DrawTexturedRect( 0, 0, fakeButton2:GetWide(), fakeButton2:GetTall() )
        end
        fakeButton2.DoClick = function()
            FooledYou()
        end

        local buttonImage3 = Material( "" )
        realButton = vgui.Create( "DButton", overlayPanel )
        realButton:SetPos()
        realButton:SetSize()
        realButton:SetText( "" )
        realButton.Paint = function()
            surface.SetDrawColor( 255, 255, 255 )
            surface.SetMaterial( buttonImage3 )
            surface.DrawTexturedRect( 0, 0, realButton:GetWide(), realButton:GetTall() )
        end
        realButton.DoClick = function()

        end
    end

    function OSCrashInteractiveOverlay()
        if IsValid( Screen ) and ispanel( Screen ) then return end
        MuteThem()
        --Blue screen text-based minigame
    end

    function CaptureScreenForGameCrashOverlay()
        if IsValid( Screen ) and ispanel( Screen ) then return end
        RequestedScreenshot = true
    end

    function GameCrashInteractiveOverlay()
        --if IsValid( Screen ) and ispanel( Screen ) then return end --Called in CaptureScreenForGameCrashOverlay function
        MuteThem()

        Screen = vgui.Create( "DFrame" )
        Screen:SetSize( ScrW(), ScrH() )
        Screen:SetPos( 0, 0 )
        Screen:SetTitle( "" )
        Screen:SetVisible( true )
        Screen:SetDraggable( false )
        Screen:ShowCloseButton( false )
        
        local Screenshot = Material( "LoganTempPic.jpg" ) --Should exist at this point
        overlayPanel = vgui.Create( "DPanel", Screen )
        overlayPanel:SetSize( Screen:GetWide(), Screen:GetTall() )
        overlayPanel:SetPos( 0, 0 )
        overlayPanel.Paint = function()
            surface.SetDrawColor( 255, 255, 255 )
            surface.SetMaterial( Screenshot )
            surface.DrawTexturedRect( 0, 0, overlayPanel:GetWide(), overlayPanel:GetTall() )
        end

        local CrashImage = Material( "" )
        crashPanel = vgui.Create( "DPanel", overlayPanel ) --Do we want to be using overlayPanel here? Or Screen? We need the background blur
        crashPanel:SetSize()
        crashPanel:Center()
        crashPanel.Paint = function()
            surface.SetDrawColor( 255, 255, 255 )
            surface.SetMaterial( CrashImage )
            surface.DrawTexturedRect( 0, 0, crashPanel:GetWide(), crashPanel:GetTall() )
        end
        Derma_DrawBackgroundBlur( crashPanel, CurTime() ) --Is this desired? Might work better around Screen
    end

    hook.Add( "PostRender", "CaptureScreenshot", function() --Nabbed from the wiki
        if RequestedScreenshot != true then return end
        RequestedScreenshot = false

        local data = render.Capture( {
            format = "jpeg",
            quality = 100, --Max is 100
            h = ScrH(),
            w = ScrW(),
            x = 0,
            y = 0,
        } )
        local tempPic = file.Open( "materials/LoganTempPic.jpg", "wb", "GAME" )
        tempPic:Write( data )
        tempPic:Close()

        timer.Simple( 0, function()
            if file.Exists( "materials/LoganTempPic.jpg", "GAME" ) then
                GameCrashInteractiveOverlay()
            end
        end )
    end )
end
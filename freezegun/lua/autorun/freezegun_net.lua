if SERVER then
    if engine.ActiveGamemode != null and engine.ActiveGamemode != terrortown then return end

    util.AddNetworkString( "SendScreen" )
    util.AddNetworkString( "EndScreen" )

    CreateConVar( "LFG_EnableIceOverlay", 1, { FCVAR_ARCHIVE }, "If set to 1, enables the ice-over overlay" )
    CreateConVar( "LFG_EnableOSUpdateOverlay", 1, { FCVAR_ARCHIVE }, "If set to 1, enables the OS update overlay" )
    CreateConVar( "LFG_EnableOSCrashOverlay", 1, { FCVAR_ARCHIVE }, "If set to 1, enables the OS crash overlay" )
    CreateConVar( "LFG_EnableGameCrashOverlay", 1, { FCVAR_ARCHIVE }, "If set to 1, enables the game crash overlay" )
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
    local Screen, savedInt, RequestedScreenshot, PreventSounds

    surface.CreateFont( "Windows10Font", {
        font = "Segoe UI",
        extended = true, --dunno
        size = 13, --default
        weight = 500, --default
        antialias = true --default
    } )

    net.Receive( "SendScreen", function()
        local overlayType = net.ReadString()

        --Ugly-ass if statement, but necessary since I have additional functionality dependent on the option
        if system.IsLinux or system.IsOSX then
            --say something here about being lame
            DefaultOverlay()
        elseif overlayType == "LFG_EnableIceOverlay" then 
            DefaultOverlay()
        elseif overlayType == "LFG_EnableOSUpdateOverlay" then
            OSUpdateOverlay()
        elseif overlayType == "LFG_EnableOSCrashOverlay" then
            OSCrashOverlay()
        elseif overlayType == "LFG_EnableGameCrashOverlay" then
            CaptureScreenForGameCrashOverlay() --Runs a bit unique here
        else
            DefaultOverlay()
        end

    end )

    net.Receive( "EndScreen", function() --All this should do is close the screen, everything else should be done for us
        CloseOverlay()
    end  )

    function MuteThem()
        for k, v in pairs( player.GetAll() ) do
            v:SetMuted( true )
        end
    end

    function UnMuteEverything()
        for k, v in pairs( player.GetAll() ) do
            if v:Alive() then
                v:SetMuted( false )
            end
        end
        PreventSounds = false
    end

    function MuteEverything()
        MuteThem()
        PreventSounds = true
    end

    function CloseOverlay()
        if Screen and ispanel( Screen ) then Screen:Remove() end
        UnMuteEverything()
    end

    function DefaultOverlay()
        if IsValid( Screen ) and ispanel( Screen ) then return end
        timer.Simple( 2, function() LocalPlayer():SetDSP( 14, false ) end ) --We're assuming the player is emitting the ice-over sound

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

    function OSUpdateOverlay()
        Screen = vgui.Create( "DFrame" )
        Screen:SetSize( ScrW(), ScrH() )
        Screen:SetPos( 0, 0 )
        Screen:SetTitle( "" )
        Screen:SetVisible( true )
        Screen:SetDraggable( false )
        Screen:ShowCloseButton( false )
        Screen:MakePopup()
        
        local UpdateImage = Material( "ui/windows10update.png" )
        overlayPanel = vgui.Create( "DPanel", Screen )
        overlayPanel:SetSize( Screen:GetWide(), Screen:GetTall() )
        overlayPanel:SetPos( 0, 0 )
        overlayPanel.Paint = function()
            surface.SetDrawColor( 255, 255, 255 )
            surface.SetMaterial( UpdateImage )
            surface.DrawTexturedRect( 0, 0, overlayPanel:GetWide(), overlayPanel:GetTall() )
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
            
        end
        fakeButton1.Hover = function()

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
            
        end
        fakeButton2.Hover = function()

        end

        local buttonImage3 = Material( "" )
        fakebutton3 = vgui.Create( "DButton", overlayPanel )
        fakebutton3:SetPos()
        fakebutton3:SetSize()
        fakebutton3:SetText( "" )
        fakebutton3.Paint = function()
            surface.SetDrawColor( 255, 255, 255 )
            surface.SetMaterial( buttonImage3 )
            surface.DrawTexturedRect( 0, 0, fakebutton3:GetWide(), fakebutton3:GetTall() )
        end
        fakebutton3.DoClick = function()

        end
        fakeButton3.Hover = function()

        end
    end

    function OSCrashOverlay()
        if IsValid( Screen ) and ispanel( Screen ) then return end
        MuteEverything()
        
        Screen = vgui.Create( "DFrame" )
        Screen:SetSize( ScrW(), ScrH() )
        Screen:SetPos( 0, 0 )
        Screen:SetTitle( "" )
        Screen:SetVisible( true )
        Screen:SetDraggable( false )
        Screen:ShowCloseButton( false )
        Screen.Paint = function()
        end
        
        local CrashImage = Material( "" )
        overlayPanel = vgui.Create( "DPanel", Screen )
        overlayPanel:SetSize( Screen:GetWide(), Screen:GetTall() )
        overlayPanel:SetPos( 0, 0 )
        overlayPanel.Paint = function()
            surface.SetDrawColor( 255, 255, 255 )
            surface.SetMaterial( CrashImage )
            surface.DrawTexturedRect( 0, 0, overlayPanel:GetWide(), overlayPanel:GetTall() )
        end
    end

    function CaptureScreenForGameCrashOverlay()
        if IsValid( Screen ) and ispanel( Screen ) then return end
        RequestedScreenshot = true
    end

    function GameCrashOverlay()
        if IsValid( Screen ) and ispanel( Screen ) then return end --Called in CaptureScreenForGameCrashOverlay function
        MuteEverything()

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
        crashPanel:SetSize( 400, 400 )
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

        timer.Simple( 0, function() --May need to adjust, 1 tick may not be enough time for the game to recognize the file
            if file.Exists( "materials/LoganTempPic.jpg", "GAME" ) then
                GameCrashOverlay()
            end
        end )
    end )

    hook.Add( "EntityEmitSound", "PreventSounds", function( info )
        if PreventSounds then return false end
    end )
end
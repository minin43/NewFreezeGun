if SERVER then
    if engine.ActiveGamemode != null and engine.ActiveGamemode != terrortown then return end

    util.AddNetworkString( "SendScreen" )
    util.AddNetworkString( "EndScreen" )

    CreateConVar( "LFG_EnableIceOverlay", 1, { FCVAR_ARCHIVE }, "If set to 1, enables the ice-over overlay - this is the default overlay if all others are disabled" )
    CreateConVar( "LFG_EnableOSUpdateOverlay", 1, { FCVAR_ARCHIVE }, "If set to 1, enables the OS update overlay" )
    CreateConVar( "LFG_EnableOSCrashOverlay", 1, { FCVAR_ARCHIVE }, "If set to 1, enables the OS crash overlay" )
    CreateConVar( "LFG_EnableGameCrashOverlay", 1, { FCVAR_ARCHIVE }, "If set to 1, enables the game crash overlay" )
    CreateConVar( "LFG_FreezeGunTime", 6, { FCVAR_ARCHIVE }, "How long the frozen player remains frozen, keep above 2 seconds" )
    CreateConVar( "LFG_DamageScaling", 40, { FCVAR_ARCHIVE }, "What % of damage players should take while frozen - defaults to 60% reduced: 40%")

    hook.Add( "DoPlayerDeath", "KilledWhileFrozen", function( vic )
        if vic:IsFlagSet( FL_FROZEN ) then
            vic:Freeze( false )
            vic:SetDSP( 0, false )
            vic:EmitSound( "effects/UnfreezeKilled.wav")
            vic:SetMaterial( "" ) --Leave blank to reset the material

            net.Start( "EndScreen" )
            net.Send( vic )

            local data = EffectData() --Not my original effect data, small edits were made to SetOrigin
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

    hook.Add( "EntityTakeDamage", "FrozenDamage", function( vic, dmginfo )
        local att = dmginfo:GetAttacker()
        local toScale = math.Clamp( GetConVar( "LFG_DamageScaling" ):GetInt(), 1, 100 )

        if vic and vic:IsPlayer() and vic:IsFlagSet( FL_FROZEN ) and !dmginfo:IsFallDamage() then --Frozen players take full fall damage
            dmginfo:ScaleDamage( toScale )
        end
    
    end )

    hook.Add( "Initialize", "CheckConVars", function()
        if GetConVar( "LFG_FreezeGunTime" ):GetInt() < 3 then
            GetConVar( "LFG_FreezeGunTime" ):SetInt( 3 )
        end
    end )
end

if CLIENT then
    local Screen, savedInt, RequestedScreenshot, PreventSounds
    local ScreenshotTable, ScreenshotCounter = {}, 0

    surface.CreateFont( "Windows10Font", { --Remains unused
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

    function DefaultOverlay() --Done, needs testing
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
            if overlayPanel.alphaCounter <= 200 then overlayPanel.alphaCounter = overlayPanel.alphaCounter + 0.5 end
            surface.SetDrawColor( 255, 255, 255, overlayPanel.alphaCounter )
            surface.SetMaterial( IceOverlay )
            surface.DrawTexturedRect( 0, 0, overlayPanel:GetWide(), overlayPanel:GetTall() )
        end
    end

    function OSUpdateOverlay() --Done, need click/hover effects added and testing
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

        timer.Simple( 2, function()        
            local UpdateImage = Material( "ui/windows10updateclean.png" )--, "noclamp smooth" )
            overlayPanel = vgui.Create( "DPanel", Screen )
            overlayPanel:SetSize( 900, 280 )
            overlayPanel:Center()
            overlayPanel.Paint = function()
                surface.SetDrawColor( 255, 255, 255 )
                surface.SetMaterial( UpdateImage )
                surface.DrawTexturedRect( 0, 0, overlayPanel:GetWide(), overlayPanel:GetTall() )
            end

            local buttonImage1 = Material( "ui/windows10updatebutton1.png" )
            fakeButton1 = vgui.Create( "DButton", overlayPanel )
            fakeButton1:SetPos( 413, 203 )
            fakeButton1:SetSize( 150, 45 )
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

            local buttonImage2 = Material( "ui/windows10updatebutton2.png" )
            fakeButton2 = vgui.Create( "DButton", overlayPanel )
            fakeButton2:SetPos( 595, 203 )
            fakeButton2:SetSize( 150, 45 )
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

            local buttonImage3 = Material( "ui/windows10updatebutton3.png" )
            fakebutton3 = vgui.Create( "DButton", overlayPanel )
            fakebutton3:SetPos( 768, 203 )
            fakebutton3:SetSize( 125, 45 )
            fakebutton3:SetText( "" )
            fakebutton3.Paint = function()
                surface.SetDrawColor( 255, 255, 255 )
                surface.SetMaterial( buttonImage3 )
                surface.DrawTexturedRect( 0, 0, fakebutton3:GetWide(), fakebutton3:GetTall() )
            end
            fakebutton3.DoClick = function()

            end
            fakebutton3.Hover = function()

            end
        end )
    end

    function OSCrashOverlay() --Done, needs testing
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
        
        overlayPanel = vgui.Create( "DPanel", Screen )
        overlayPanel:SetSize( Screen:GetWide(), Screen:GetTall() )
        overlayPanel:SetPos( 0, 0 )
        overlayPanel.Paint = function()
            surface.SetDrawColor( 0, 0, 0 )
            surface.DrawRect( 0, 0, overlayPanel:GetWide(), overlayPanel:GetTall() )
        end

        local CrashImage = Material( "ui/windows10crash.png" )
        timer.Simple( 2, function()
            crashScreen = vgui.Create( "DPanel", overlayPanel )
            crashScreen:SetPos( 0, 0 )
            crashScreen:SetSize( overlayPanel:GetWide(), overlayPanel:GetTall() )
            crashScreen.Paint = function()
                surface.SetDrawColor( 255, 255, 255 )
                surface.SetMaterial( CrashImage )
                surface.DrawTexturedRect( 0, 0, overlayPanel:GetWide(), overlayPanel:GetTall() )
            end
        end )
    end

    function CaptureScreenForGameCrashOverlay()
        if IsValid( Screen ) and ispanel( Screen ) then return end
        RequestedScreenshot = true
    end

    function GameCrashOverlay() --Done, need W10 application crash image
        if IsValid( Screen ) and ispanel( Screen ) then return end --Called in CaptureScreenForGameCrashOverlay function
        MuteEverything()

        Screen = vgui.Create( "DFrame" )
        Screen:SetSize( ScrW(), ScrH() )
        Screen:SetPos( 0, 0 )
        Screen:SetTitle( "" )
        Screen:SetVisible( true )
        Screen:SetDraggable( false )
        Screen:ShowCloseButton( false )
        timer.Simple( 4, function() Screen:MakePopup() end )
        
        local Screenshot = Material( "DATA/crashimage" .. ScreenshotCounter .. ".jpg" ) --Should exist at this point
        ScreenshotCounter = ScreenshotCounter + 1
        overlayPanel = vgui.Create( "DPanel", Screen )
        overlayPanel:SetSize( Screen:GetWide(), Screen:GetTall() )
        overlayPanel:SetPos( 0, 0 )
        overlayPanel.Paint = function()
            surface.SetDrawColor( 255, 255, 255 )
            surface.SetMaterial( Screenshot )
            surface.DrawTexturedRect( 0, 0, overlayPanel:GetWide(), overlayPanel:GetTall() )
        end

        local CrashImage = Material( "" )
        crashPanel = vgui.Create( "DPanel", overlayPanel )
        crashPanel:SetSize( 600, 400 )
        crashPanel:Center()
        crashPanel.Paint = function()
            surface.SetDrawColor( 255, 255, 255 )
            --surface.SetMaterial( CrashImage )
            --surface.DrawTexturedRect( 0, 0, crashPanel:GetWide(), crashPanel:GetTall() )
        end
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
        if file.Exists( "crashimage" .. ScreenshotCounter .. ".jpg", "DATA" ) then
            file.Delete( "crashimage" .. ScreenshotCounter .. ".jpg" )
        end
        local tempPic = file.Open( "crashimage" .. ScreenshotCounter .. ".jpg", "wb", "DATA" )
        tempPic:Write( data )
        tempPic:Close()

        timer.Simple( 0, function() --May need to adjust, 1 tick may not be enough time for the game to recognize the file
            if file.Exists( "crashimage" .. ScreenshotCounter .. ".jpg", "DATA" ) then
                GameCrashOverlay()
            end
        end )
    end )

    hook.Add( "Think", "PreventAllSounds", function() --This shit is hella unoptimized, but I'm offered no other solution
        if PreventSounds then LocalPlayer():ConCommand("stopsound") end
    end )
end
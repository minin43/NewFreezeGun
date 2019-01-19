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
    CreateConVar( "LFG_FreezeGunTime", 5, { FCVAR_ARCHIVE }, "How long the frozen player remains unable to move" )

end

if CLIENT then
    local Screen, savedInt

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
            GameCrashInteractiveOverlay()
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
        if ispanel( Screen ) and IsValid( Screen ) then return end
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
            if overlayPanel.alphaCounter <= 254 then overlayPanel.alphaCounter = overlayPanel.alphaCounter + 1 end
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
        LocalPlayer():SetDSP( 4, false )

        Screen = vgui.Create( "DFrame" )
        Screen:SetSize( ScrW(), ScrH() )
        Screen:SetPos( 0, 0 )
        Screen:SetTitle( "" )
        Screen:SetVisible( true )
        Screen:SetDraggable( false )
        Screen:ShowCloseButton( false )
        Screen:MakePopup()
        Derma_DrawBackgroundBlur( Screen, CurTime() ) --Is this desired?

        local IceOverlay = Material( "ui/frosted.png" ) --Smooth 1
        overlayPanel = vgui.Create( "DPanel", Screen )
        overlayPanel:SetSize( Screen:GetWide(), Screen:GetTall() )
        overlayPanel:SetPos( 0, 0 )
        overlayPanel.Paint = function()
            --Draw icy screen overlay here
            surface.SetMaterial( IceOverlay )
            surface.DrawTexturedRect( 0, 0, overlayPanel:GetWide(), overlayPanel:GetTall() )
        end
    end

    function OSUpdateInteractiveOverlay()
        --No screen effect except a small window at the bottom of the screen asking for windows to update to, must click through multiple windows
        Screen = vgui.Create( "DFrame" )
        Screen:SetSize( ScrW(), ScrH() )
        Screen:SetPos( 0, 0 )
        Screen:SetTitle( "" )
        Screen:SetVisible( true )
        Screen:SetDraggable( false )
        Screen:ShowCloseButton( false )
        Screen:MakePopup()
        Derma_DrawBackgroundBlur( Screen, CurTime() ) --Is this desired?
        
        overlayPanel = vgui.Create( "DPanel", Screen )
        overlayPanel:SetSize( Screen:GetWide(), Screen:GetTall() )
        overlayPanel:SetPos( 0, 0 )
        overlayPanel.Paint = function()
            --Make a Windows update screen here
        end
    end

    function OSCrashInteractiveOverlay()
        MuteThem()
        --Blue screen text-based minigame
    end

    function GameCrashInteractiveOverlay()
        MuteThem()
        --Game freezes, have to time space bar presses with the green bar crossing a line, gets continually harder as you succeed
    end
end
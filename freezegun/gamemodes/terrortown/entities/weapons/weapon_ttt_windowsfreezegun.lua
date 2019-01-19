--// A lot of the gun shit I ripped right from the flare gun, since it suited my purposes quite nicely
AddCSLuaFile()

SWEP.HoldType              = "pistol"

if CLIENT then
   SWEP.PrintName          = "Logan's Freeze Gun"
   SWEP.Slot               = 6

   SWEP.ViewModelFOV       = 54
   SWEP.ViewModelFlip      = false

   SWEP.EquipMenuData = {
      type = "Weapon",
      desc = "Shoot a terrorist to freeze their movement.\nRandomly plays one of four overlays,\nif any are enabled."
   };

   SWEP.Icon               = "vgui/ttt/" --vgui/ttt/icon_flare
end

SWEP.Base                  = "weapon_tttbase"

SWEP.Primary.Ammo          = "AR2AltFire"
SWEP.Primary.Recoil        = 2
SWEP.Primary.Damage        = 5
SWEP.Primary.Delay         = 1.0
SWEP.Primary.Cone          = 0.01
SWEP.Primary.ClipSize      = 3
SWEP.Primary.Automatic     = false
SWEP.Primary.DefaultClip   = 3
SWEP.Primary.ClipMax       = 3
SWEP.Primary.Sound         = Sound( "Weapon_USP.SilencedShot" )

SWEP.Kind                  = WEAPON_EQUIP
SWEP.CanBuy                = {ROLE_TRAITOR, ROLE_DETECTIVE}
SWEP.LimitedStock          = false

SWEP.Tracer                = "AR2Tracer"

SWEP.UseHands              = true
SWEP.ViewModel             = Model("models/weapons/c_357.mdl")
SWEP.WorldModel            = Model("models/weapons/w_357.mdl")

function FreezeTarget( att, path, dmginfo )
    if SERVER then
        local ent = path.Entity
        if not IsValid(ent) then return end

        -- disallow if prep or post round
        if not GAMEMODE:AllowPVP() then return end 

        if ent:IsPlayer() then
            local savedRandomNumber
            ent:Freeze( true )

            local function UnFreeze( ply )
                print("Fuction UnFreeze called")
                ply:Freeze( false )
                ply:SetDSP( 0, false )
                net.Start( "EndScreen" )
                net.Send( ply )
                ply:EmitSound( "effects/IceShatter.ogg")
            end

            timer.Simple( GetConVar( "LFG_FreezeGunTime" ):GetInt(), function()
                print("End of Freeze Timer called for ", ent)
                UnFreeze( ent ) 
            end )

            if GetConVar( "LFG_EnableDynamicFreezing" ):GetInt() == 1 then
                local ConVarTable = {}
                if GetConVar( "LFG_EnableIceOverlay" ):GetInt() == 1 then
                    ConVarTable[ #ConVarTable + 1 ] = "LFG_EnableIceOverlay"
                end
                if GetConVar( "LFG_EnableOSUpdateOverlay" ):GetInt() == 1 then
                    ConVarTable[ #ConVarTable + 1 ] = "LFG_EnableOSUpdateOverlay"
                end
                if GetConVar( "LFG_EnableOSCrashOverlay" ):GetInt() == 1 then
                    ConVarTable[ #ConVarTable + 1 ] = "LFG_EnableOSCrashOverlay"
                end
                if GetConVar( "LFG_EnableGameCrashOverlay" ):GetInt() == 1 then
                    ConVarTable[ #ConVarTable + 1 ] = "LFG_EnableGameCrashOverlay"
                end

                net.Start( "SendScreenInteractive" )
                savedRandomNumber = math.random( -254, 254 )
                net.WriteInt( savedRandomNumber, 9 ) --Used as verification
                net.WriteString( ConVarTable[ math.random( #ConVarTable ) ] ) --Random overlay to use
            else
                net.Start( "SendScreen" )
                ent:SetDSP( 4, false )
            end
            net.Send( ent )
            ent:EmitSound( "effects/IceOver.ogg" )

            net.Receive( "SendScreenInteractiveCallback", function( len, ply )
                local test = net.ReadInt( 9 )
                if test != savedRandomNumber then return end --Never trust the client

                UnFreeze( ply )
            end )
        end
    end
end

function SWEP:ShootFreeze()
   local cone = self.Primary.Cone
   local bullet = {}
   bullet.Num       = 1
   bullet.Src       = self:GetOwner():GetShootPos()
   bullet.Dir       = self:GetOwner():GetAimVector()
   bullet.Spread    = Vector( cone, cone, 0 )
   bullet.Tracer    = 1
   bullet.Force     = 2
   bullet.Damage    = self.Primary.Damage
   bullet.TracerName = self.Tracer
   bullet.Callback = FreezeTarget

   self:GetOwner():FireBullets( bullet )
end

function SWEP:PrimaryAttack()
   self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
   if not self:CanPrimaryAttack() then return end

   self:EmitSound( self.Primary.Sound )
   self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
   self:TakePrimaryAmmo( 1 )

   if IsValid(self:GetOwner()) then
      self:GetOwner():SetAnimation( PLAYER_ATTACK1 )

      self:GetOwner():ViewPunch( Angle( math.Rand(-0.2,-0.1) * self.Primary.Recoil, math.Rand(-0.1,0.1) *self.Primary.Recoil, 0 ) )
   end

   if ( (game.SinglePlayer() && SERVER) || CLIENT ) then
      self:SetNWFloat( "LastShootTime", CurTime() )
   end

   self:ShootFreeze()
end

function SWEP:SecondaryAttack()
end
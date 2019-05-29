--DO NOT EDIT OR REUPLOAD THIS FILE

AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:SpawnFunction( ply, tr, ClassName )

	if not tr.Hit then return end

	local ent = ents.Create( ClassName )
	ent.dOwnerEntLFS = ply
	ent:SetPos( tr.HitPos + tr.HitNormal * 5 )
	ent:Spawn()
	ent:Activate()

	return ent

end


function ENT:RunOnSpawn()
end

function ENT:SetNextAltPrimary( delay )
	self.NextAltPrimary = CurTime() + delay
end

function ENT:CanAltPrimaryAttack()
	self.NextAltPrimary = self.NextAltPrimary or 0.15
	return self.NextAltPrimary < CurTime()
end

function ENT:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end
	
	if not IsValid( Pod ) then Pod = self:GetDriverSeat() end
	if not IsValid( Driver ) then Driver = Pod:GetDriver() end
	
	if not IsValid( Pod ) then return end
	if not IsValid( Driver ) then return end
	
	local EyeAngles = Pod:WorldToLocalAngles( Driver:EyeAngles() )
	local Forward = self:GetForward()
	
	local AimDirToForwardDir = math.deg( math.acos( math.Clamp( Forward:Dot( EyeAngles:Forward() ) ,-1,1) ) )
	if AimDirToForwardDir > 180 then return end
	
	self:EmitSound( "AA_FIRE" )
	
	self:SetNextPrimary( 0.12 )
	
	local startpos =  self:GetRotorPos()
	local TracePlane = util.TraceHull( {
		start = startpos,
		endpos = (startpos + EyeAngles:Forward() * 50000),
		mins = Vector( -10, -10, -10 ),
		maxs = Vector( 10, 10, 10 ),
		filter = self
	} )
	
	local fP = { Vector(10,-40,50), Vector(10,-40,65), }

	self.NumPrim = self.NumPrim and self.NumPrim + 1 or 1
	if self.NumPrim > 2 then self.NumPrim = 1 end
	
	local MuzzlePos = self:LocalToWorld( fP[self.NumPrim] )

	local bullet = {}
	bullet.Num 	= 1
	bullet.Src 	= MuzzlePos
	bullet.Dir 	= (TracePlane.HitPos - bullet.Src):GetNormalized()
	bullet.Spread 	= Vector( 0.02,  0.02, 0 )
	bullet.Tracer	= 1
	bullet.TracerName	= "lfs_laser_green"
	bullet.Force	= 300
	bullet.HullSize 	= 80
	bullet.Damage	= 70
	bullet.Attacker 	= Driver
	bullet.AmmoType = "Pistol"
	bullet.Callback = function(att, tr, dmginfo)
		dmginfo:SetDamageType(DMG_AIRBOAT)
	end
	self:FireBullets( bullet )
		
	self:TakePrimaryAmmo()
end

function ENT:OnKeyThrottle( bPressed )
	if bPressed then
		if self:CanSound() then
			self:EmitSound( "" )
			self:DelayNextSound( 1 )
		end
	else
		if (self:GetRPM() + 1) > self:GetMaxRPM() then
			if self:CanSound() then
				self:EmitSound( "" )
				self:DelayNextSound( 0.5 )
			end
		end
	end
end

function ENT:CreateAI()
end

function ENT:RemoveAI()
end

function ENT:ToggleLandingGear()
end

function ENT:RaiseLandingGear()
end

function ENT:HandleWeapons(Fire1, Fire2)
	local Driver = self:GetDriver()
	local Gunner = self:GetGunner()
	local HasGunner = IsValid( Gunner )
	
	local FireTurret = false
	
	if IsValid( Driver ) then
		if self:GetAmmoPrimary() > 0 then
			Fire1 = Driver:KeyDown( IN_ATTACK )
		end
		
		if self:GetAmmoSecondary() > 0 then
			Fire2 = Driver:KeyDown( IN_ATTACK2 )
		end
	end
	
	if Fire1 then
		if FireTurret and not HasGunner then
			self:AltPrimaryAttack()
		else
			self:PrimaryAttack()
		end
	end
	
	if HasGunner then
		if Gunner:KeyDown( IN_ATTACK ) then
			self:AltPrimaryAttack( Gunner, self:GetGunnerSeat() )
			
		end
	end
	
	if Fire2 then
		self:SecondaryAttack()
	end
end


function ENT:OnEngineStarted()
end

function ENT:OnEngineStopped()
end

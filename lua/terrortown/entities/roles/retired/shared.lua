if engine.ActiveGamemode() ~= "terrortown" then return end
if SERVER then
	AddCSLuaFile()
	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_retired.vmt")
	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_retired.vtf")
end

function ROLE:PreInitialize()
	self.index = ROLE_RETIRED
	self.color = Color(75, 75, 75, 255)
	self.abbr = "retired"

	self.score.surviveBonusMultiplier = 0
	self.score.aliveTeammatesBonusMultiplier = 0
	self.score.killsMultiplier = 0
	self.score.teamKillsMultiplier = -16
	self.score.bodyFoundMuliplier = 0
	self.notSelectable = true
	self.unknownTeam = true

	self.defaultTeam = TEAM_JESTER

	self.preventWin = true
	self.isPublicRole = true
	self.isPolicingRole = false

	self.defaultTeam = TEAM_NONE
	self.conVarData = {
		credits = 0,
		creditsAwardDeadEnable = 0,
		creditsAwardKillEnable = 0
	}
end

if SERVER then

	hook.Add("PlayerTakeDamage", "RetiredNoDamage", function(ply, inflictor, attacker, amount, dmginfo)
		if not IsValid(ply) or not IsValid(attacker) then return end
		if SpecDM and (ply.IsGhost and ply:IsGhost() or (attacker.IsGhost and attacker:IsGhost())) then return end

		if attacker:IsPlayer() and attacker:GetSubRole() == ROLE_RETIRED then
			print("Blocking " .. ROLE_RETIRED .. " damaging others")
			dmginfo:ScaleDamage(0)
			dmginfo:SetDamage(0)
		end
	end)
end
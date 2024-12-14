if engine.ActiveGamemode() ~= "terrortown" then return end
if SERVER then
	AddCSLuaFile()
	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_butler.vmt")
	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_butler.vtf")
end

function ROLE:PreInitialize()
	self.index = ROLE_BUTLER
	self.color = Color(58, 68, 85, 255)
	self.abbr = "butler"

	self.preventFindCredits = true
	self.preventKillCredits = true
	self.preventTraitorAloneCredits = true
	self.unknownTeam = true // player does not know their teammates
	self.preventWin = true

	self.score.killsMultiplier = 2
	self.score.teamKillsMultiplier = -4

	roles.InitCustomTeam(self.name, {
		icon = "vgui/ttt/dynamic/roles/icon_butler",
		color = self.color
	})

	self.defaultTeam = TEAM_INNOCENT
	self.conVarData = {
		pct = 0.15, // necessary: percentage of getting this role selected (per player)
		maximum = 1, // maximum amount of roles in a round
		minPlayers = 8, // minimum amount of players until this role is able to get selected
		credits = 0, // the starting credits of a specific role
		shopFallback = SHOP_DISABLED,
		togglable = true, // option to toggle a role for a client if possible (F1 menu)
		random = 33
	}
end

if SERVER then
	local function InitRoleButler(ply)
		BUTLER_DATA:FindNewGuardingPlayer(ply, 0.05)
	end

	hook.Add("TTT2UpdateSubrole", "TTT2ButlerGiveStrip", function(ply, old, new)
		// called on normal role set
		if new == ROLE_BUTLER then
			InitRoleButler(ply)
		elseif old == ROLE_BUTLER then
			ply:SetNWEntity("guarding_player", nil)
		end
	end)

	hook.Add("TTT2UpdateTeam", "TTT2ButlerTeamChanged", function(ply, oldTeam, team)
		if ply:GetSubRole() == ROLE_BUTLER or GetRoundState() ~= ROUND_ACTIVE then return end
		if not BUTLER_DATA:HasGuards(ply) then return end
		for k, v in ipairs(BUTLER_DATA:GetGuards(ply)) do
			v:UpdateTeam(team)
		end

		SendFullStateUpdate()
	end)

	hook.Add("PlayerSpawn", "TTT2GuardSpawn", function(ply)
		// called on player respawn
		if ply:GetSubRole() ~= ROLE_BUTLER or GetRoundState() ~= ROUND_ACTIVE then return end
		if ply:IsTerror() and not ply:IsSpec() then InitRoleButler(ply) end
	end)

	hook.Add("TTT2SpecialRoleSyncing", "TTT2RoleBodyGuardMod", function(ply, tbl)
		if ply and ply:GetSubRole() ~= ROLE_BUTLER or GetRoundState() == ROUND_POST then return end
		local guardedPlayer = BUTLER_DATA:GetGuardedPlayer(ply)
		if IsValid(guardedPlayer) and not table.HasValue(tbl, guardedPlayer) then
			tbl[guardedPlayer] = {guardedPlayer:GetSubRole() or ROLE_NONE, guardedPlayer:GetTeam() or TEAM_INNOCENT}
		end
		for teamRole in pairs(tbl) do
			if teamRole:IsInTeam(ply) and teamRole ~= ply and teamRole ~= guardedPlayer and not teamRole:GetSubRoleData().isPublicRole and not teamRole:GetNWBool("role_found", false) then
				tbl[teamRole] = {ROLE_NONE, TEAM_NONE}
			end
		end
	end)

	hook.Add("TTT2SpecialRoleSyncing", "TTT2RoleBodyGuardMod2", function(ply, tbl)
		if ply and ply:GetSubRole() == ROLE_BUTLER or GetRoundState() == ROUND_POST then return end
		if not BUTLER_DATA:HasGuards(ply) then return end
		local guards = BUTLER_DATA:GetGuards(ply)
		for k, p in ipairs(guards) do
			if not table.HasValue(tbl, p) then tbl[p] = {p:GetSubRole() or ROLE_NONE, p:GetTeam() or TEAM_NONE} end
		end
	end)

	hook.Add("TTT2ModifyRadarRole", "TTT2RadarBodyguardFix", function(ply, scan)
		if ply:GetSubRole() ~= ROLE_BUTLER or GetRoundState() ~= ROUND_ACTIVE then return end
		if BUTLER_DATA:IsGuardOf(ply, scan) then return end
		if not scan:IsInTeam(ply) then return end
		return ROLE_INNOCENT, TEAM_INNOCENT
	end)

	hook.Add("TTT2TellTraitors", "TTT2HideTraitorMessageBodyGuard", function(tmp, ply)
		if ply:GetSubRole() ~= ROLE_BUTLER then return end
		return false
	end)

	hook.Add("TTT2AvoidTeamChat", "TTT2AvoidBodyGuardChat", function(sender, team, msg)
		if sender:GetSubRole() ~= ROLE_BUTLER or (sender:GetSubRole() == ROLE_BUTLER and team == TEAM_INNOCENT) or GetRoundState() ~= ROUND_ACTIVE then return end
		return false
	end)

	hook.Add("TTT2OverrideDisabledSync", "TTT2BodyGuardBypassDisSync", function(ply, p)
		if not IsValid(p) or not IsValid(ply) or ply:GetSubRole() ~= ROLE_BUTLER then return end
		if not BUTLER_DATA:IsGuardOf(ply, p) then return end
		return true
	end)
end

if CLIENT then
	function ROLE:AddToSettingsMenu(parent)
		// local form = vgui.CreateTTT2Form(parent, "header_roles_additional")
	end
end
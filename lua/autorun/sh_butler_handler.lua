if engine.ActiveGamemode() ~= "terrortown" then return end
BUTLER_DATA = {}
if CLIENT then
	net.Receive("TTT2ButlerNewGuardMessage", function()
		local name = net.ReadString()
		chat.AddText(Color(0, 255, 50), "[Butler] " .. name .. " is now your Butler.")
		chat.PlaySound()
		STATUS:AddStatus("ttt2_role_butler_guarding")
	end)

	net.Receive("TTT2ButlerNewGuardingMessage", function()
		local name = net.ReadString()
		local role = net.ReadString()
		local roleColor = net.ReadColor()
		chat.AddText("[Butler] You are guarding " .. name .. ". Their Role: ", roleColor, role)
		chat.PlaySound()
	end)

	net.Receive("TTT2ButlerGuardDeathMessage", function()
		chat.AddText(Color(255, 0, 0), "[Butler] Your Butler has died!")
		chat.PlaySound()
		STATUS:RemoveStatus("ttt2_role_butler_guarding")
	end)

	hook.Add("TTTPrepareRound", "TTT2ResetButlerValues", function()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		ply:SetNWEntity("guarding_player", nil)
	end)

	hook.Add("TTT2UpdateSubrole", "TTT2ButlerSubChange", function(ply, old, new)
		-- called on normal role set
		if old == ROLE_BUTLER then ply:SetNWEntity("guarding_player", nil) end
	end)
end

if SERVER then
	util.AddNetworkString("TTT2ButlerNewGuardMessage")
	util.AddNetworkString("TTT2ButlerNewGuardingMessage")
	util.AddNetworkString("TTT2ButlerGuardDeathMessage")
	function BUTLER_DATA:SetNewGuard(guard, toGuard)
		guard:SetNWEntity("guarding_player", toGuard)
		if IsValid(toGuard) then
			guard:UpdateTeam(toGuard:GetTeam())
			local roleData = roles.GetByIndex(toGuard:GetSubRole())
			net.Start("TTT2ButlerNewGuardingMessage")
			net.WriteString(toGuard:Nick())
			net.WriteString(roleData.name)
			net.WriteColor(roleData.color)
			net.Send(guard)
			net.Start("TTT2ButlerNewGuardMessage")
			net.WriteString(guard:Nick())
			net.Send(toGuard)
			SendFullStateUpdate()
		end
	end

	function BUTLER_DATA:FindNewGuardingPlayer(ply, delay)
		if delay then
			timer.Simple(delay, function() BUTLER_DATA:FindNewGuardingPlayer(ply) end)
			return
		end

		if not ply or not IsValid(ply) then return end
		if not ply:IsTerror() or ply:IsSpec() or ply:GetSubRole() ~= ROLE_BODYGUARD then return end
		local alivePlayers = {}
		for k, v in ipairs(player.GetAll()) do
			if v:IsTerror() and v:Alive() and not v:IsSpec() and v:GetSubRole() ~= ROLE_BODYGUARD and v ~= ply then table.insert(alivePlayers, v) end
		end

		local tmp = table.Copy(alivePlayers)
		for k, v in ipairs(alivePlayers) do
			if BUTLER_DATA:HasGuards(v) then table.RemoveByValue(tmp, v) end
		end

		local playerAvailable = #tmp > 0
		if playerAvailable then
			local newToGuard = table.Random(tmp)
			BUTLER_DATA:SetNewGuard(ply, newToGuard)
			return
		end

		local newToGuard = table.Random(alivePlayers)
		BUTLER_DATA:SetNewGuard(ply, newToGuard)
	end

	function BUTLER_DATA:GetGuards(ply)
		local guards = {}
		for k, v in ipairs(player.GetAll()) do
			if v:IsTerror() and v:Alive() and not v:IsSpec() and v:GetSubRole() == ROLE_BUTLER then
				local nwGuard = v:GetNWEntity("guarding_player")
				if IsValid(nwGuard) and nwGuard == ply then table.insert(guards, v) end
			end
		end

		if #guards == 0 then return nil end
		return guards
	end

	function BUTLER_DATA:HasGuards(ply)
		local guards = BUTLER_DATA:GetGuards(ply)
		if not guards then return false end
		if #guards <= 0 then return false end
		return true
	end

	function BUTLER_DATA:IsGuardOf(guard, check)
		if not BUTLER_DATA:HasGuards(check) then return false end
		local guards = BUTLER_DATA:GetGuards(check)
		return table.HasValue(guards, guard)
	end

	function BUTLER_DATA:GetGuardedPlayer(ply)
		local toGuard = ply:GetNWEntity("guarding_player")
		if not IsValid(toGuard) then return nil end
		return toGuard
	end

	hook.Add("PlayerDeath", "TTT2ButlerDeathHandler", function(ply, infl, attacker)
		if ply:GetSubRole() ~= ROLE_BUTLER or GetRoundState() ~= ROUND_ACTIVE then return end
		local toGuard = BUTLER_DATA:GetGuardedPlayer(ply)
		if not IsValid(toGuard) then return end
		BUTLER_DATA:SetNewGuard(ply, nil)
		net.Start("TTT2ButlerGuardDeathMessage")
		net.Send(toGuard)
		SendFullStateUpdate()
	end)

	hook.Add("PlayerDeath", "TTT2ButlerTargetDeathHandler", function(ply, infl, attacker)
		if ply:GetSubRole() == ROLE_BUTLER or GetRoundState() ~= ROUND_ACTIVE then return end
		local guards = BUTLER_DATA:GetGuards(ply)
		if not BUTLER_DATA:HasGuards(ply) then return end
		for k, v in ipairs(guards) do
			if v == attacker then
				v:Kill()
				BUTLER_DATA:SetNewGuard(v, nil)
			end
		end
	end)

	hook.Add("PostPlayerDeath", "TTT2ButlerTargetPostDeathHandler", function(ply)
		if ply:GetSubRole() == ROLE_BUTLER or GetRoundState() ~= ROUND_ACTIVE then return end
		local guards = BUTLER_DATA:GetGuards(ply)
		if not BUTLER_DATA:HasGuards(ply) then return end
		for k, v in ipairs(guards) do
			v:SetRole(ROLE_RETIRED)
			SendFullStateUpdate()
			local health = ply:Health()
			if health > 20 then ply:SetHealth(20) end
			events.Trigger(EVENT_BUTLER_FAIL, v, ply)
		end
	end)

	hook.Add("PlayerDisconnected", "TTT2GuardedDisconnectHandler", function(ply)
		if ply:GetSubRole() == ROLE_BUTLER or GetRoundState() ~= ROUND_ACTIVE then return end
		local guards = BUTLER_DATA:GetGuards(ply)
		if not BUTLER_DATA:HasGuards(ply) then return end
		for k, v in ipairs(guards) do
			v:SetRole(ply:GetSubRole())
			SendFullStateUpdate()
			v:PrintMessage(HUD_PRINTCENTER, "Your target has disconnected, so you are granted their role.")
		end
	end)

	hook.Add("PlayerDisconnected", "TTT2GuardDisconnectHandler", function(ply)
		if ply:GetSubRole() ~= ROLE_BUTLER or GetRoundState() ~= ROUND_ACTIVE then return end
		local toGuard = BUTLER_DATA:GetGuardedPlayer(ply)
		if not IsValid(toGuard) then return end
		net.Start("TTT2ButlerGuardDeathMessage")
		net.Send(toGuard)
		SendFullStateUpdate()
	end)

	-- Don't set a Butler as a target of a Hitman at any chance.
	hook.Add("TTT2CanBeHitmanTarget", "TTT2GuardHitmanNoTarget", function(ply, target)
		if target:GetSubRole() ~= ROLE_BUTLER then return end
		return false
	end)
end
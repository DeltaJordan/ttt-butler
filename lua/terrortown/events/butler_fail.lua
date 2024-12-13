if CLIENT then
	EVENT.icon = Material("vgui/ttt/dynamic/roles/icon_butler")
	EVENT.title = "title_event_butler_fail"

	function EVENT:GetText()
		return {
			{
				string = "desc_event_butler_fail",
				params = {
					butler = self.event.butler.nick,
					target = self.event.target.nick,
				},
				translateParams = true
			}
		}
	end
end

if SERVER then
	function EVENT:Trigger(butler, target)
		self:AddAffectedPlayers(
			{butler:SteamID64(), target:SteamID64()},
			{butler:Nick(), target:Nick()}
		)

		return self:Add({
			butler = {
				nick = butler:Nick(),
				sid64 = butler:SteamID64()
			},
			target = {
				nick = target:Nick(),
				sid64 = target:SteamID64(),
			}
		})
	end

	function EVENT:CalculateScore()
		local event = self.event

		self:SetPlayerScore(event.butler.sid64, {
			score = -2
		})
	end
end

function EVENT:Serialize()
	return self.event.butler.nick .. " has failed to protect " .. self.event.target.nick .. "."
end

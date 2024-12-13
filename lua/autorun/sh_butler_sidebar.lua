if engine.ActiveGamemode() ~= "terrortown" then return end
if SERVER then
	resource.AddFile("materials/vgui/ttt/icon_butler_guarding.vmt")
	resource.AddFile("materials/vgui/ttt/hud_icon_guarded.png")
end

if CLIENT then
	hook.Add("Initialize", "ttt2_role_butler_init", function()
		STATUS:RegisterStatus("ttt2_role_butler_guarding", {
			hud = Material("vgui/ttt/hud_icon_guarded.png"),
			type = "good"
		})
	end)
end
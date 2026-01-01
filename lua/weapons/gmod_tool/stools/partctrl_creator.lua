TOOL.AddToMenu = false

TOOL.ClientConVar.pcf = "particles/fire_01.pcf"
TOOL.ClientConVar.name = "env_fire_large"
TOOL.ClientConVar.path = ""

TOOL.Information = {{name = "left"}}

//If we really wanted to pretend this was the same tool as the standard creator, I guess we could try to copy its strings, but that's not worth the trouble and this is funnier
if CLIENT then
	language.Add("tool.partctrl_creator.name", "Particle Creator")
	language.Add("tool.partctrl_creator.desc", "A particle creator. It makes particles. That's all your need to know.")
	language.Add("tool.partctrl_creator.left", "Create the particle")
end

function TOOL:LeftClick()

	if SERVER then
		local pcf = self:GetClientInfo("pcf")
		local name = self:GetClientInfo("name")
		local path = self:GetClientInfo("path")
		if path == "" then path = nil end

		PartCtrl_SpawnParticle(self:GetOwner(), nil, name, pcf, path)
	end

	return true

end

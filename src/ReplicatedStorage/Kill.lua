local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local isServer = RunService:IsServer()

function register(instance)
	instance.Touched:Connect(function(part)
		local model = part:FindFirstAncestorWhichIsA("Model")
		local humanoid = model and model:FindFirstChild("Humanoid")
		if humanoid and (isServer or Players:GetPlayerFromCharacter(model) == localPlayer) then
			humanoid.Health = 0
		end
	end)
end

for _, instance in ipairs(CollectionService:GetTagged("Kill")) do
	register(instance)
end
CollectionService:GetInstanceAddedSignal("Kill"):Connect(register)

return nil
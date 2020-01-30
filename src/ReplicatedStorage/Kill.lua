local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

function register(instance)
	instance.Touched:Connect(function(part)
		local model = part:FindFirstAncestorWhichIsA("Model")
		local humanoid = model and model:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end)
end

for _, instance in ipairs(CollectionService:GetTagged("Kill")) do
	register(instance)
end
CollectionService:GetInstanceAddedSignal("Kill"):Connect(register)

-- Set player Humanoid properties:
local function onHumanoidAdded(character, humanoid)
	humanoid.Touched:Connect(function(touchingPart, humanoidPart)
		if CollectionService:HasTag(touchingPart, "Kill") then
			humanoid.Health = 0
		end
	end)
end

-- Track existing and new player Humanoids:
local function onCharacterAdded(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		onHumanoidAdded(character, humanoid)
	else
		character.ChildAdded:Connect(
			function(child)
				if child:IsA("Humanoid") then
					onHumanoidAdded(character, child)
				end
			end
		)
	end
end

-- Track existing and new player characters:
local function onPlayerAdded(player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

local player = Players.LocalPlayer
if player then
	onPlayerAdded(player)
else
	Players.PlayerAdded:Connect(onPlayerAdded)
end

return nil
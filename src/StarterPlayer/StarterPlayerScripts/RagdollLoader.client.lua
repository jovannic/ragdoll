local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Set up client-side too for remote communication: (replace (...))
require(ReplicatedStorage:WaitForChild("Ragdoll", 60))

local function onKeyPress(inputObject, gameProcessedEvent)
	if inputObject.KeyCode == Enum.KeyCode.LeftControl then
		game:GetService("Players").LocalPlayer.Character.Humanoid.Health = 0
	end
end
game:GetService("UserInputService").InputBegan:Connect(onKeyPress)

require(ReplicatedStorage:WaitForChild("Kill"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function onKeyPress(inputObject, _gameProcessedEvent)
	if inputObject.KeyCode == Enum.KeyCode.LeftControl then
		game:GetService("Players").LocalPlayer.Character.Humanoid.Health = 0
	end
end
game:GetService("UserInputService").InputBegan:Connect(onKeyPress)

require(ReplicatedStorage:WaitForChild("Kill"))
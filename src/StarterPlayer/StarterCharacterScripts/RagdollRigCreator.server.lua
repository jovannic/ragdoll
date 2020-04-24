local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DefaultRagdoll = ReplicatedStorage:FindFirstChild("DefaultRagdoll")
local Rigging = require(DefaultRagdoll:FindFirstChild("Rigging"))

 -- wait for the first of the passed signals to fire
 local function waitForFirst(...)
	local shunt = Instance.new("BindableEvent")
	local slots = {...}

	local function fire(...)
		for i = 1, #slots do
			slots[i]:Disconnect()
		end

		return shunt:Fire(...)
	end

	for i = 1, #slots do
		slots[i] = slots[i]:Connect(fire)
	end

	return shunt.Event:Wait()
end

local character = script.Parent

local humanoid = character:FindFirstChildOfClass("Humanoid")
while character:IsDescendantOf(game) and not humanoid do
	waitForFirst(character.ChildAdded, character.AncestryChanged)
	humanoid = character:FindFirstChildOfClass("Humanoid")
end

-- We will only disable specific joints
humanoid.BreakJointsOnDeath = false

-- Create remote event for the client to notify the server that it went ragdoll. The server
-- never disables joints authoritatively until the client acknowledges that it has already
-- broken it's own joints non-authoritatively, started simulating the ragdoll locally, and
-- should already be sending physics data.
local remote = humanoid:FindFirstChild("OnRagdoll")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "OnRagdoll"
	remote.Parent = humanoid
end
remote.OnServerEvent:Connect(function(remotePlayer, isRagdoll)
	if isRagdoll and remotePlayer == Players:GetPlayerFromCharacter(character) then
		Rigging.disableMotors(character, humanoid.RigType)
	end
end)

-- Server creates ragdoll joints on spawn to allow for seamless transition even if death is
-- initiated on the client. The Motor6Ds keep them inactive until they are disabled.
Rigging.createRagdollJoints(character, humanoid.RigType)
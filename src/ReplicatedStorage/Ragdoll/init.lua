local Ragdoll = {}

--[[
	Module that can be used to ragdoll arbitrary R6/R15 rigs or set whether players ragdoll or fall to pieces by default
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Rigging = require(script:WaitForChild("Rigging"))

if RunService:IsServer() then

	-- Whether players ragdoll by default: (true = ragdoll, false = fall into pieces)
	local playerDefault = false

	-- Set player Humanoid properties:
	local function onHumanoidAdded(character, humanoid)
		Rigging.createJoints(character, humanoid.RigType)
		humanoid.BreakJointsOnDeath = not playerDefault
		humanoid.Died:Connect(
			function()
				if playerDefault then
					-- Ragdoll them:
					humanoid.BreakJointsOnDeath = false
					Rigging.breakMotors(character, humanoid.RigType)
				end
			end
		)
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
		player.CharacterAppearanceLoaded:Connect(onCharacterAdded)
		if player.Character then
			onCharacterAdded(player.Character)
		end
	end

	-- Track all players:
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in pairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	-- Setting whether players ragdoll when dying by default: (true = ragdoll, false = fall into pieces)
	function Ragdoll:SetPlayerDefault(enabled)
		if enabled ~= nil and typeof(enabled) ~= "boolean" then
			error("bad argument #1 to 'SetPlayerDefault' (boolean expected, got " .. typeof(enabled) .. ")", 2)
		end

		playerDefault = enabled

		-- Update BreakJointsOnDeath for all alive characters:
		for _, player in pairs(Players:GetPlayers()) do
			if player.Character then
				local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.BreakJointsOnDeath = not playerDefault
				end
			end
		end
	end

else -- Client

	-- Set player Humanoid properties:
	local function onHumanoidAdded(character, humanoid)
		humanoid.Died:Connect(
			function()
				Rigging.breakMotors(character, humanoid.RigType)
			end
		)
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

	onPlayerAdded(Players.LocalPlayer)

	-- Other API not available from client-side:

	function Ragdoll:SetPlayerDefault()
		error("Ragdoll::SetPlayerDefault cannot be used from the client", 2)
	end

end

return Ragdoll

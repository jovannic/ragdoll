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
				local motors = Rigging.breakMotors(character, humanoid.RigType)

				local animator = character:FindFirstChildWhichIsA("Animator", true)
				if animator then
					animator:ApplyVelocities(motors)
				end

				wait(0.9)
				local gravityScale = workspace.Gravity / 196.2
				-- TODO: friction lerp
				local frictionJoints = {}
				for _, v in pairs(character:GetDescendants()) do
					if v:IsA("BallSocketConstraint") and v.Name == "RagdollBallSocket" then
						local scale = (v.Parent.Name == "UpperTorso" or v.Parent.Name == "Head") and 0.5 or 0.05
						local current = v.MaxFrictionTorque
						local next = current * scale * gravityScale
						frictionJoints[v] = { current, next }
					end
				end
				spawn(function()
					local tscale = 1 / 0.4
					local t = 0
					while t < 1 do
						local dt = RunService.Heartbeat:Wait()
						t = math.min(t + dt * tscale, 1)
						for k, v in pairs(frictionJoints) do
							local a, b = unpack(v)
							k.MaxFrictionTorque = (1 - t) * a + t * b
						end
					end
				end)

				wait(1)
				local parts = {}
				for _, instance in pairs(character:GetDescendants()) do
					if instance:IsA("BasePart") or instance:IsA("Decal") then
						table.insert(parts, instance)
					end
				end
				local fadeTime = 0.3
				local t = 0
				while t < fadeTime do
					local dt = RunService.Heartbeat:Wait()
					for _, p in pairs(parts) do
						p.Transparency = p.Transparency * 1.02 + dt / fadeTime
					end
					t = t + dt
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

	onPlayerAdded(Players.LocalPlayer)

	-- Other API not available from client-side:

	function Ragdoll:SetPlayerDefault()
		error("Ragdoll::SetPlayerDefault cannot be used from the client", 2)
	end

end

return Ragdoll

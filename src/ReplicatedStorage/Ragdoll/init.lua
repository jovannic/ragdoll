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
		-- In the case of CharacterApperanceLoaded, we need to re-rig.
		Rigging.removeRagdollJoints(character)
		Rigging.createRagdollJoints(character, humanoid.RigType)
		humanoid.BreakJointsOnDeath = not playerDefault
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

	local function disableParticleEmittersAndFadeOut(descendants, duration)
		local transparencies = {}
		for _, instance in pairs(descendants) do
			if instance:IsA("BasePart") or instance:IsA("Decal") then
				table.insert(transparencies, { instance, instance.Transparency })
			end
			if instance:IsA("ParticleEmitter") then
				instance.Enabled = false
			end
		end
		local t = 0
		while t < duration do
			-- Using heartbeat because we want to update just before rendering next frame, and not
			-- block the render thread kicking off (as RenderStepped does)
			local dt = RunService.Heartbeat:Wait()
			t = t + dt
			local alpha = math.min(t / duration, 1)
			for _, pair in pairs(transparencies) do
				local p, a = unpack(pair)
				p.Transparency = (1 - alpha) * a + alpha * 1
			end
		end
	end

	local function easeJointFriction(descendants, duration)
		local gravityScale = workspace.Gravity / 196.2
			local frictionJoints = {}
			for _, v in pairs(descendants) do
				if v:IsA("BallSocketConstraint") and v.Name == "RagdollBallSocket" then
					local current = v.MaxFrictionTorque
					-- Keep the torso and neck a little stiffer...
					local scale = (v.Parent.Name == "UpperTorso" or v.Parent.Name == "Head") and 0.5 or 0.05
					local next = current * scale * gravityScale
					frictionJoints[v] = { v, current, next }
				end
			end
			local t = 0
			while t < duration do
				-- Using stepped because we want to update just before physics sim
				local _, dt = RunService.Stepped:Wait()
				t = t + dt
				local alpha = math.min(t / duration, 1)
				for _, tuple in pairs(frictionJoints) do
					local bsc, a, b = unpack(tuple)
					bsc.MaxFrictionTorque = (1 - alpha) * a + alpha * b
				end
			end
	end

	-- Set player Humanoid properties:
	local function onHumanoidAdded(character, humanoid)
		humanoid.Died:Connect(function()
			-- We first break the motors on the network owner (character's player in this case). If
			-- we initiated ragdoll by breaking joints on the server there's a visible hitch while
			-- the server waits, a full round trip latency delay at least, for the network owner to
			-- recieve the joint removal, start simulating the ragdoll, and replicating physics
			-- state. so that there is no visible round trip hitch while the server is waiting for
			-- physics replication data for the child body parts that the owner (client) hasn't
			-- simulated yet. This way by the time the server recieves the joint break physics data
			-- for the child parts should already be available.
			local motors = Rigging.breakMotors(character, humanoid.RigType)

			-- Apply velocities from animation to the child parts to mantain visual momentum.
			--
			-- This should be done on the network owner's side just after disabling the kinematic
			-- joint so the child parts are split off as seperate dynamic bodies.
			--
			-- It's also important that this is called *before* any animations are canceled or
			-- changed after death! Otherwise there will be no animations to get velocities from or
			-- the velocities won't be consistent!
			local animator = humanoid:FindFirstChildWhichIsA("Animator")
			if animator then
				animator:ApplyJointVelocities(motors)
			end

			-- stiff shock phase...
			wait(0.1)

			-- gradually give up...
			easeJointFriction(character:GetDescendants(), 0.5)

			-- time to settle...
			wait(0.6)

			-- fade into the mist...
			disableParticleEmittersAndFadeOut(character:GetDescendants(), 0.6)
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

local Ragdoll = {}

--[[
	Module that can be used to ragdoll arbitrary R6/R15 rigs or set whether players ragdoll or fall to pieces by default
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Rigging = require(script:WaitForChild("Rigging"))

local localPlayer = Players.LocalPlayer
local isServer = RunService:IsServer()

local function disableParticleEmittersAndFadeOut(descendants, duration)
	local transparencies = {}
	for _, instance in pairs(descendants) do
		if instance:IsA("BasePart") or instance:IsA("Decal") then
			table.insert(transparencies, { instance, instance.LocalTransparencyModifier })
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
			p.LocalTransparencyModifier = (1 - alpha) * a + alpha * 1
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

local function onOwnedHumanoidDeath(character, humanoid)
	-- We first break the motors on the network owner (the player that owns this character).
	--
	-- This way there is no visible round trip hitch. By the time the server receives the joint
	-- break physics data for the child parts should already be available. Seamless transition.
	--
	-- If we initiated ragdoll by breaking joints on the server there's a visible hitch while the
	-- server waits at least a full round trip time for the network owner to receive the joint
	-- removal, start simulating the ragdoll, and replicate physics data. Meanwhile the other body
	-- parts would be frozen in air on the server and other clients until physics data arives from
	-- the owner. The ragdolled player wouldn't see it, but other players would.
	--
	-- We also specifically do not break the root joint on the client so we can maintain a
	-- consistent mechanism and network ownership unit root. If we did break the root joint we'd be
	-- creating a new, seperate network onwership unit that we would have to wait for the server to
	-- assign us network ownership of before we would start simulating and replicating physics data
	-- for it, creating an additional round trip hitch on our end for our own character.
	local motors = Rigging.breakMotors(character, humanoid.RigType)

	-- Apply velocities from animation to the child parts to mantain visual momentum.
	--
	-- This should be done on the network owner's side just after disabling the kinematic joint so
	-- the child parts are split off as seperate dynamic bodies. For consistent animation times and
	-- visual momentum we want to do this on the machine that controls animation state for the
	-- character and will be simulating the ragdoll, in this case the client.
	--
	-- It's also important that this is called *before* any animations are canceled or changed after
	-- death! Otherwise there will be no animations to get velocities from or the velocities won't
	-- be consistent!
	local animator = humanoid:FindFirstChildWhichIsA("Animator")
	if animator then
		animator:ApplyJointVelocities(motors)
	end

	-- stiff shock phase...
	wait(0.1)

	-- gradually give up...
	easeJointFriction(character:GetDescendants(), 0.5)
end

local function onAnyHumanoidDeath(character, humanoid)
	-- time for friction fade out and settle
	wait(1.5)
	-- fade into the mist...
	disableParticleEmittersAndFadeOut(character:GetDescendants(), 0.6)
end

-- Handle Humanoid death
local function onHumanoidAdded(player, character, humanoid)
	if isServer then
		-- Server creates ragdoll joints on spawn to allow for seamless transition later.
		Rigging.createRagdollJoints(character, humanoid.RigType)
		-- We will only disable specific joints
		humanoid.BreakJointsOnDeath = false
		-- We don't bother with fade-out on the server
	else
		-- Any character: handle fade out on death
		humanoid.Died:Connect(function()
			onAnyHumanoidDeath(character, humanoid)
		end)
		-- Just my character: initiate ragdoll and do friction easing 
		if player == localPlayer then
			humanoid.Died:Connect(function()
				onOwnedHumanoidDeath(character, humanoid)
			end)
		end
	end
end

-- Track existing and new player Humanoids
local function onCharacterAdded(player, character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		onHumanoidAdded(player, character, humanoid)
	else
		character.ChildAdded:Connect(
			function(child)
				if child:IsA("Humanoid") then
					onHumanoidAdded(player, character, child)
				end
			end
		)
	end
end

-- Track existing and new player characters
local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)

	if isServer then
		player.CharacterAppearanceLoaded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
	end

	local character = player.Character
	if character then
		onCharacterAdded(player, character)
	end
end

-- Track all players (including local player on the client)
Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in pairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

return Ragdoll

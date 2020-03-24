local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DefaultRagdoll = ReplicatedStorage:WaitForChild("DefaultRagdoll", 120)
local Rigging = require(DefaultRagdoll:WaitForChild("Rigging", 120))

local localPlayer = Players.LocalPlayer

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
	-- If we're missing our RemoteEvent to notify the server that we've started simulating our
	-- ragdoll so it can authoritatively replicate the joint removal, don't ragdoll at all.
	local remote = humanoid:FindFirstChild("OnRagdoll")
	if not remote then
		return
	end

	-- We first disable the motors on the network owner (the player that owns this character).
	--
	-- This way there is no visible round trip hitch. By the time the server receives the joint
	-- break physics data for the child parts should already be available. Seamless transition.
	--
	-- If we initiated ragdoll by disabling joints on the server there's a visible hitch while the
	-- server waits at least a full round trip time for the network owner to receive the joint
	-- removal, start simulating the ragdoll, and replicate physics data. Meanwhile the other body
	-- parts would be frozen in air on the server and other clients until physics data arives from
	-- the owner. The ragdolled player wouldn't see it, but other players would.
	--
	-- We also specifically do not disable the root joint on the client so we can maintain a
	-- consistent mechanism and network ownership unit root. If we did disable the root joint we'd
	-- be creating a new, seperate network ownership unit that we would have to wait for the server
	-- to assign us network ownership of before we would start simulating and replicating physics
	-- data for it, creating an additional round trip hitch on our end for our own character.
	local motors = Rigging.disableMotors(character, humanoid.RigType)
	
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

	-- Tell the server that we started simulating our ragdoll
	remote:FireServer(true)

	-- stiff shock phase...
	wait(0.1)

	-- gradually give up...
	easeJointFriction(character:GetDescendants(), 0.5)
end

local function humanoidReady(player, character, humanoid)
	local ancestryChangedConn
	local diedConn
	local function disconnect()
		ancestryChangedConn:Disconnect()
		diedConn:Disconnect()
	end

	-- Handle Humanoid death
	diedConn = humanoid.Died:Connect(function()
		-- Assume death is final
		disconnect()
		-- Any character: handle fade out on death
		delay(1.5, function()
			-- fade into the mist...
			disableParticleEmittersAndFadeOut(character:GetDescendants(), 0.4)
		end)
		-- Just my character: initiate ragdoll and do friction easing 
		if player == localPlayer then
			onOwnedHumanoidDeath(character, humanoid)
		end
	end)

	-- Handle connection cleanup on remove
	ancestryChangedConn = humanoid.AncestryChanged:Connect(function(_child, parent)
		if not game:IsAncestorOf(parent) then
			disconnect()
		end
	end)
end

local function characterAdded(player, character)
	-- Avoiding memory leaks in the face of Character/Humanoid/RootPart lifetime has a few complications:
	-- * character deparenting is a Remove instead of a Destroy, so signals are not cleaned up automatically.
	-- ** must use a waitForFirst on everything and listen for hierarchy changes.
	-- * the character might not be in the dm by the time CharacterAdded fires
	-- ** constantly check consistency with player.Character and abort if CharacterAdded is fired again
	-- * Humanoid may not exist immediately, and by the time it's inserted the character might be deparented.
	-- * RootPart probably won't exist immediately.
	-- ** by the time RootPart is inserted and Humanoid.RootPart is set, the character or the humanoid might be deparented.

	if not character.Parent then
		waitForFirst(character.AncestryChanged, player.CharacterAdded)
	end

	if player.Character ~= character or not character.Parent then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	while character:IsDescendantOf(game) and not humanoid do
		waitForFirst(character.ChildAdded, character.AncestryChanged, player.CharacterAdded)
		humanoid = character:FindFirstChildOfClass("Humanoid")
	end

	if player.Character ~= character or not character:IsDescendantOf(game) then
		return
	end

	-- must rely on HumanoidRootPart naming because Humanoid.RootPart does not fire changed signals
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	while character:IsDescendantOf(game) and not rootPart do
		waitForFirst(character.ChildAdded, character.AncestryChanged, humanoid.AncestryChanged, player.CharacterAdded)
		rootPart = character:FindFirstChild("HumanoidRootPart")
	end

	if rootPart and humanoid:IsDescendantOf(game) and character:IsDescendantOf(game) and player.Character == character then
		humanoidReady(player, character, humanoid)
	end
end

local function playerAdded(player)
	local characterAddedConn = player.CharacterAdded:Connect(function(character)
		characterAdded(player, character)
	end)
	
	-- Players are Removed, not Destroyed, by replication so we must clean up
	local ancestryChangedConn
	ancestryChangedConn = player.AncestryChanged:Connect(function(_child, parent)
		if not game:IsAncestorOf(parent) then
			ancestryChangedConn:Disconnect()
			characterAddedConn:Disconnect()
		end
	end)

	local character = player.Character
	if character then
		characterAdded(player, character)
	end
end

-- Track all players (including local player on the client)
Players.PlayerAdded:Connect(playerAdded)
for _, player in pairs(Players:GetPlayers()) do
	playerAdded(player)
end
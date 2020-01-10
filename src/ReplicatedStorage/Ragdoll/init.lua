local Ragdoll = {}

--[[
	Module that can be used to ragdoll arbitrary R6/R15 rigs or set whether players ragdoll or fall to pieces by default
--]]

local EVENT_NAME = "Event"
local RAGDOLLED_TAG = "__Ragdoll_Active"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local StarterGui = game:GetService("StarterGui")
local RigTypes = require(script:WaitForChild("RigTypes"))

if RunService:IsServer() then
		
	-- Used for telling the client to set their own character to Physics mode:
	local event = Instance.new("RemoteEvent")
	event.Name = EVENT_NAME
	event.Parent = script
	
	-- Whether players ragdoll by default: (true = ragdoll, false = fall into pieces)
	local playerDefault = false
	
	-- Activating ragdoll on an arbitrary model with a Humanoid:
	local function activateRagdoll(model, humanoid)
		assert(humanoid:IsDescendantOf(model))
		if CollectionService:HasTag(model, RAGDOLLED_TAG) then
			return
		end
		CollectionService:AddTag(model, RAGDOLLED_TAG)
		
		-- Propagate to player if applicable:
		local player = Players:GetPlayerFromCharacter(model)
		if player then
			event:FireClient(player, true, model, humanoid)
		elseif model.PrimaryPart then
			event:FireAllClients(false, model, humanoid)
		end
		
		-- Turn into loose body:
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		
		-- Instantiate BallSocketConstraints:
		local attachments = RigTypes.getAttachments(model, humanoid.RigType)
		for name, objects in pairs(attachments) do
			local parent = model:FindFirstChild(name)
			if parent then
				local constraint = Instance.new("BallSocketConstraint")
				constraint.Name = "RagdollBallSocketConstraint"
				constraint.Attachment0 = objects.attachment0
				constraint.Attachment1 = objects.attachment1
				constraint.LimitsEnabled = true
				constraint.UpperAngle = objects.limits.UpperAngle
				constraint.TwistLimitsEnabled = true
				constraint.TwistLowerAngle = objects.limits.TwistLowerAngle
				constraint.TwistUpperAngle = objects.limits.TwistUpperAngle
				constraint.Parent = parent
			end
		end
		
		-- Instantiate NoCollisionConstraints:
		local parts = RigTypes.getNoCollisions(model, humanoid.RigType)
		for _, objects in pairs(parts) do
			local constraint = Instance.new("NoCollisionConstraint")
			constraint.Name = "RagdollNoCollisionConstraint"
			constraint.Part0 = objects[1]
			constraint.Part1 = objects[2]
			constraint.Parent = objects[1]
		end
		
		-- Destroy all regular joints:
		for _, motor in pairs(model:GetDescendants()) do
			if motor:IsA("Motor6D") then
				motor:Destroy()
			end
		end
	end
	
	-- Set player Humanoid properties:
	local function onHumanoidAdded(character, humanoid)
		humanoid.BreakJointsOnDeath = not playerDefault
		humanoid.Died:Connect(
			function()
				if playerDefault then
					-- Ragdoll them:
					humanoid.BreakJointsOnDeath = false
					activateRagdoll(character, humanoid)
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
		player.CharacterAdded:Connect(onCharacterAdded)
		if player.Character then
			onCharacterAdded(player.Character)
		end
	end
	
	-- Track all players:
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in pairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
	
	-- Activating the ragdoll on a specific model
	function Ragdoll:Activate(model)
		if typeof(model) ~= "Instance" or not model:IsA("Model") then
			error("bad argument #1 to 'Activate' (Model expected, got " .. typeof(model) .. ")", 2)
		end
		
		-- Model must have a humanoid:
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return warn("[Ragdoll] Could not ragdoll " .. model:GetFullName() .. " because it has no Humanoid")
		end
		
		activateRagdoll(model, humanoid)
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
	
	-- Client sets their own character to Physics mode when told to:
	script:WaitForChild(EVENT_NAME).OnClientEvent:Connect(
		function(isSelf, model, humanoid)
			if isSelf then
				local head = model:FindFirstChild("Head")
				if head then
					workspace.CurrentCamera.CameraSubject = head
				end
			end
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		end
	)
	
	-- Other API not available from client-side:
	
	function Ragdoll:Activate()
		error("Ragdoll::Activate cannot be used from the client", 2)
	end
	
	function Ragdoll:SetPlayerDefault()
		error("Ragdoll::SetPlayerDefault cannot be used from the client", 2)
	end

end

return Ragdoll

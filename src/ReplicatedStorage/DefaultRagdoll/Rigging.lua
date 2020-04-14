local RunService = game:GetService("RunService")

local Rigging = {}

-- Gravity that joint friction values were tuned under.
local REFERENCE_GRAVITY = 196.2

-- ReferenceMass values from mass of child part. Used to normalized "stiffness" for differently
-- sized avatars (with different mass).
local DEFAULT_MAX_FRICTION_TORQUE = 500

local HEAD_LIMITS = {
	UpperAngle = 45,
	TwistLowerAngle = -40,
	TwistUpperAngle = 40,
	FrictionTorque = 400,
	ReferenceMass = 1.0249234437943,
}

local WAIST_LIMITS = {
	UpperAngle = 20,
	TwistLowerAngle = -40,
	TwistUpperAngle = 20,
	FrictionTorque = 750,
	ReferenceMass = 2.861558675766,
}

local ANKLE_LIMITS = {
	UpperAngle = 10,
	TwistLowerAngle = -10,
	TwistUpperAngle = 10,
	ReferenceMass = 0.43671694397926,
}

local ELBOW_LIMITS = {
	-- Elbow is basically a hinge, but allow some twist for Supination and Pronation
	UpperAngle = 20, 
	TwistLowerAngle = 5,
	TwistUpperAngle = 120,
	ReferenceMass = 0.70196455717087
}

local WRIST_LIMITS = {
	UpperAngle = 30,
	TwistLowerAngle = -10,
	TwistUpperAngle = 10,
	ReferenceMass = 0.69132566452026,
}

local KNEE_LIMITS = {
	UpperAngle = 5,
	TwistLowerAngle = -120,
	TwistUpperAngle = -5,
	ReferenceMass = 0.65389388799667,
}

local SHOULDER_LIMITS = {
	UpperAngle = 110,
	TwistLowerAngle = -85,
	TwistUpperAngle = 85,
	FrictionTorque = 600,
	ReferenceMass = 0.90918225049973,
}

local HIP_LIMITS = {
	UpperAngle = 40,
	TwistLowerAngle = -5,
	TwistUpperAngle = 80,
	FrictionTorque = 600,
	ReferenceMass = 1.9175016880035,
}

local R6_HEAD_LIMITS = {
	UpperAngle = 30,
	TwistLowerAngle = -60,
	TwistUpperAngle = 60,
}

local R6_SHOULDER_LIMITS = {
	UpperAngle = 90,
	TwistLowerAngle = -30,
	TwistUpperAngle = 175,
}

local R6_HIP_LIMITS = {
	UpperAngle = 40,
	TwistLowerAngle = -120,
	TwistUpperAngle = 15,
}

local V3_ZERO = Vector3.new()
local V3_UP = Vector3.new(0, 1, 0)
local V3_DOWN = Vector3.new(0, -1, 0)
local V3_RIGHT = Vector3.new(1, 0, 0)
local V3_LEFT = Vector3.new(-1, 0, 0)

-- To model shoulder cone and twist limits correctly we really need the primary axis of the UpperArm
-- to be going down the limb. the waist and neck joints attachments actually have the same problem
-- of non-ideal axis orientation, but it's not as noticable there since the limits for natural
-- motion are tighter for those joints anyway.
local R15_ADDITIONAL_ATTACHMENTS = {
	{"UpperTorso", "RightShoulderRagdollAttachment", CFrame.fromMatrix(V3_ZERO, V3_RIGHT, V3_UP), "RightShoulderRigAttachment"},
	{"RightUpperArm", "RightShoulderRagdollAttachment", CFrame.fromMatrix(V3_ZERO, V3_DOWN, V3_RIGHT), "RightShoulderRigAttachment"},
	{"UpperTorso", "LeftShoulderRagdollAttachment", CFrame.fromMatrix(V3_ZERO, V3_LEFT, V3_UP), "LeftShoulderRigAttachment"},
	{"LeftUpperArm", "LeftShoulderRagdollAttachment", CFrame.fromMatrix(V3_ZERO, V3_DOWN, V3_LEFT), "LeftShoulderRigAttachment"},
}
-- { { parentPart, childPart, attachmentName, limits }, ... }
local R15_RAGDOLL_RIG = {
	{"UpperTorso", "Head", "NeckRigAttachment", HEAD_LIMITS},

	{"LowerTorso", "UpperTorso", "WaistRigAttachment", WAIST_LIMITS},

	{"UpperTorso", "LeftUpperArm", "LeftShoulderRagdollAttachment", SHOULDER_LIMITS},
	{"LeftUpperArm", "LeftLowerArm", "LeftElbowRigAttachment", ELBOW_LIMITS},
	{"LeftLowerArm", "LeftHand", "LeftWristRigAttachment", WRIST_LIMITS},

	{"UpperTorso", "RightUpperArm", "RightShoulderRagdollAttachment", SHOULDER_LIMITS},
	{"RightUpperArm", "RightLowerArm", "RightElbowRigAttachment", ELBOW_LIMITS},
	{"RightLowerArm", "RightHand", "RightWristRigAttachment", WRIST_LIMITS},

	{"LowerTorso", "LeftUpperLeg", "LeftHipRigAttachment", HIP_LIMITS},
	{"LeftUpperLeg", "LeftLowerLeg", "LeftKneeRigAttachment", KNEE_LIMITS},
	{"LeftLowerLeg", "LeftFoot", "LeftAnkleRigAttachment", ANKLE_LIMITS},

	{"LowerTorso", "RightUpperLeg", "RightHipRigAttachment", HIP_LIMITS},
	{"RightUpperLeg", "RightLowerLeg", "RightKneeRigAttachment", KNEE_LIMITS},
	{"RightLowerLeg", "RightFoot", "RightAnkleRigAttachment", ANKLE_LIMITS},
}
local R15_NO_COLLIDES = {
	{"LowerTorso", "LeftUpperArm"},
	{"LeftUpperArm", "LeftHand"},

	{"LowerTorso", "RightUpperArm"},
	{"RightUpperArm", "RightHand"},

	{"LeftUpperLeg", "RightUpperLeg"},

	{"UpperTorso", "RightUpperLeg"},
	{"RightUpperLeg", "RightFoot"},

	{"UpperTorso", "LeftUpperLeg"},
	{"LeftUpperLeg", "LeftFoot"},

	-- Support weird R15 rigs
	{"UpperTorso", "LeftLowerLeg"},
	{"UpperTorso", "RightLowerLeg"},
	{"LowerTorso", "LeftLowerLeg"},
	{"LowerTorso", "RightLowerLeg"},

	{"UpperTorso", "LeftLowerArm"},
	{"UpperTorso", "RightLowerArm"},

	{"Head", "LeftUpperArm"},
	{"Head", "RightUpperArm"},
}
-- DFS tree order
local R15_MOTOR6DS = {
	{"Waist", "UpperTorso"},

	{"Neck", "Head"},

	{"LeftShoulder", "LeftUpperArm"},
	{"LeftElbow", "LeftLowerArm"},
	{"LeftWrist", "LeftHand"},

	{"RightShoulder", "RightUpperArm"},
	{"RightElbow", "RightLowerArm"},
	{"RightWrist", "RightHand"},

	{"LeftHip", "LeftUpperLeg"},
	{"LeftKnee", "LeftLowerLeg"},
	{"LeftAnkle", "LeftFoot"},

	{"RightHip", "RightUpperLeg"},
	{"RightKnee", "RightLowerLeg"},
	{"RightAnkle", "RightFoot"},
}

-- R6 has hard coded part sizes and does not have a full set of rig Attachments.
local R6_ADDITIONAL_ATTACHMENTS = {
	{"Head", "NeckAttachment", CFrame.new(0, -0.5, 0)},

	{"Torso", "RightShoulderRagdollAttachment", CFrame.new(1, 0.5, 0)},
	{"Right Arm", "RightShoulderRagdollAttachment", CFrame.new(-0.5, 0.5, 0)},

	{"Torso", "LeftShoulderRagdollAttachment", CFrame.new(-1, 0.5, 0)},
	{"Left Arm", "LeftShoulderRagdollAttachment", CFrame.new(0.5, 0.5, 0)},

	{"Torso", "RightHipAttachment", CFrame.new(0.5, -1, 0)},
	{"Right Leg", "RightHipAttachment", CFrame.new(0, 1, 0)},

	{"Torso", "LeftHipAttachment", CFrame.new(-0.5, -1, 0)},
	{"Left Leg", "LeftHipAttachment", CFrame.new(0, 1, 0)},
}
local R6_RAGDOLL_RIG = {
	{"Head", "Torso", "NeckAttachment", R6_HEAD_LIMITS},

	{"Left Leg", "Torso", "LeftHipAttachment", R6_HIP_LIMITS},
	{"Right Leg", "Torso", "RightHipAttachment", R6_HIP_LIMITS},

	{"Left Arm", "Torso", "LeftShoulderRagdollAttachment", R6_SHOULDER_LIMITS},
	{"Right Arm", "Torso", "RightShoulderRagdollAttachment", R6_SHOULDER_LIMITS},
}
local R6_NO_COLLIDES = {
	{"Left Leg", "Right Leg"},
	{"Head", "Right Arm"},
	{"Head", "Left Arm"},
}
local R6_MOTOR6DS = {
	{"Neck", "Torso"},
	{"Left Shoulder", "Torso"},
	{"Right Shoulder", "Torso"},
	{"Left Hip", "Torso"},
	{"Right Hip", "Torso"},
}

local BALL_SOCKET_NAME = "RagdollBallSocket"
local NO_COLLIDE_NAME = "RagdollNoCollision"

local function createRigJoint(model, part0Name, part1Name, attachmentName, limits)
	local part0 = model:FindFirstChild(part0Name)
	local part1 = model:FindFirstChild(part1Name)
	if part0 and part1 then
		local a0 = part0:FindFirstChild(attachmentName)
		local a1 = part1:FindFirstChild(attachmentName)
		if a0 and a1 and a0:IsA("Attachment") and a1:IsA("Attachment") then
			local constraint = Instance.new("BallSocketConstraint")
			constraint.Name = BALL_SOCKET_NAME
			constraint.Attachment0 = a0
			constraint.Attachment1 = a1
			constraint.LimitsEnabled = true
			constraint.UpperAngle = limits.UpperAngle
			constraint.TwistLimitsEnabled = true
			constraint.TwistLowerAngle = limits.TwistLowerAngle
			constraint.TwistUpperAngle = limits.TwistUpperAngle
			-- Scale constant torque limit for joint friction relative to gravity and the mass of
			-- the body part.
			local gravityScale = workspace.Gravity / REFERENCE_GRAVITY
			local referenceMass = limits.ReferenceMass
			local massScale = referenceMass and (part1:GetMass() / referenceMass) or 1
			local maxTorque = limits.FrictionTorque or DEFAULT_MAX_FRICTION_TORQUE
			constraint.MaxFrictionTorque = maxTorque * massScale * gravityScale
			constraint.Parent = part1
		end
	end
end

local function createNoCollide(model, part0Name, part1Name)
	local part0 = model:FindFirstChild(part0Name)
	local part1 = model:FindFirstChild(part1Name)
	if part0 and part1 then
		local constraint = Instance.new("NoCollisionConstraint")
		constraint.Name = NO_COLLIDE_NAME
		constraint.Part0 = part0
		constraint.Part1 = part1
		constraint.Parent = part0
	end
end

local function createAdditionalAttachments(model, attachments)
	for _, attachmentParams in ipairs(attachments) do
		local part = model:FindFirstChild(attachmentParams[1])
		if part and part:IsA("BasePart") then
			local name = attachmentParams[2]
			if not part:FindFirstChild(name) then
				local cframe = attachmentParams[3]
				local baseName = attachmentParams[4]
				if baseName then
					local base = part:FindFirstChild(baseName)
					if base and base:IsA("Attachment") then
						cframe = base.CFrame * cframe
					end
				end
				local attachment = part:FindFirstChild(name)
				if not attachment then
					attachment = Instance.new("Attachment")
					attachment.Name = name
					attachment.CFrame = cframe
					attachment.Parent = part
				elseif attachment:IsA("Attachment") then
					attachment.CFrame = cframe
				end
			end
		end
	end
end

local function createRigJoints(model, rig, noCollides)
	for parentName, params in pairs(rig) do
		createRigJoint(model, unpack(params))
	end
	for _, params in ipairs(noCollides) do
		createNoCollide(model, unpack(params))
	end
end

local function disableMotorSet(model, motorSet)
	local motors = {}
	-- Destroy all regular joints:
	for _, params in ipairs(motorSet) do
		local part = model:FindFirstChild(params[2])
		if part then
			local motor = part:FindFirstChild(params[1])
			if motor and motor:IsA("Motor6D") then
				table.insert(motors, motor)
				motor.Enabled = false
			end
		end
	end
	return motors
end

function Rigging.createRagdollJoints(model, rigType)
	if rigType == Enum.HumanoidRigType.R6 then
		createAdditionalAttachments(model, R6_ADDITIONAL_ATTACHMENTS)
		createRigJoints(model, R6_RAGDOLL_RIG, R6_NO_COLLIDES)
	elseif rigType == Enum.HumanoidRigType.R15 then
		createAdditionalAttachments(model, R15_ADDITIONAL_ATTACHMENTS)
		createRigJoints(model, R15_RAGDOLL_RIG, R15_NO_COLLIDES)
	else
		error("unknown rig type", 2)
	end
end

function Rigging.removeRagdollJoints(model)
	for _, descendant in pairs(model:GetDescendants()) do
		if (descendant:IsA("BallSocketConstraint") and descendant.Name == BALL_SOCKET_NAME)
			or (descendant:IsA("NoCollisionConstraint") and descendant.Name == NO_COLLIDE_NAME)
		then
			descendant:Destroy()
		end
	end
end

function Rigging.disableMotors(model, rigType)
	-- Note: We intentionally do not disable the root joint so that the mechanism root of the
	-- character stays consistent when we break joints on the client. This avoid the need for the client to wait
	-- for re-assignment of network ownership of a new mechanism, which creates a visible hitch.

	local motors
	if rigType == Enum.HumanoidRigType.R6 then
		motors = disableMotorSet(model, R6_MOTOR6DS)
	elseif rigType == Enum.HumanoidRigType.R15 then
		motors = disableMotorSet(model, R15_MOTOR6DS)
	else
		error("unknown rig type", 2)
	end

	-- Set the root part to non-collide
	local rootPart = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		rootPart.CanCollide = false
	end

	return motors
end

function Rigging.disableParticleEmittersAndFadeOut(character, duration)
	if RunService:IsServer() then
		-- This causes a lot of unnecesarry replicated property changes
		error("disableParticleEmittersAndFadeOut should not be called on the server.", 2)
	end

	local descendants = character:GetDescendants()
	local transparencies = {}
	for _, instance in pairs(descendants) do
		if instance:IsA("BasePart") or instance:IsA("Decal") then
			transparencies[instance] = instance.Transparency
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
		for part, initialTransparency in pairs(transparencies) do
			part.Transparency = (1 - alpha) * initialTransparency + alpha * 1
		end
	end
end

function Rigging.easeJointFriction(character, duration)
	local descendants = character:GetDescendants()
	-- { { joint, initial friction, end friction }, ... }
	local frictionJoints = {}
	for _, v in pairs(descendants) do
		if v:IsA("BallSocketConstraint") and v.Name == BALL_SOCKET_NAME then
			local current = v.MaxFrictionTorque
			-- Keep the torso and neck a little stiffer...
			local parentName = v.Parent.Name
			local scale = (parentName.Name == "UpperTorso" or parentName.Name == "Head") and 0.5 or 0.05
			local next = current * scale
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
			local ballSocket, a, b = unpack(tuple)
			ballSocket.MaxFrictionTorque = (1 - alpha) * a + alpha * b
		end
	end
end

return Rigging
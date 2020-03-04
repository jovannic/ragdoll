local Rigging = {}

local HEAD_LIMITS = {
	UpperAngle = 45;
	TwistLowerAngle = -40;
	TwistUpperAngle = 40;
	FrictionTorque = 400;
}

local WAIST_LIMITS = {
	UpperAngle = 20;
	TwistLowerAngle = -40;
	TwistUpperAngle = 20;
	FrictionTorque = 750;
}

local ANKLE_LIMITS = {
	UpperAngle = 10;
	TwistLowerAngle = -10;
	TwistUpperAngle = 10;
}

local ELBOW_LIMITS = {
	UpperAngle = 60; -- an elbow is basically a hinge, but this allows some lower arm wrist twist
	TwistLowerAngle = 0;
	TwistUpperAngle = 120;
}

local WRIST_LIMITS = {
	UpperAngle = 30;
	TwistLowerAngle = -10;
	TwistUpperAngle = 10;
}

local KNEE_LIMITS = {
	UpperAngle = 5;
	TwistLowerAngle = -120;
	TwistUpperAngle = 0;
}

local SHOULDER_LIMITS = {
	UpperAngle = 60;
	TwistLowerAngle = -60;
	TwistUpperAngle = 175;
}

local HIP_LIMITS = {
	UpperAngle = 40;
	TwistLowerAngle = -5;
	TwistUpperAngle = 100;
}

local R6_HEAD_LIMITS = {
	UpperAngle = 30;
	TwistLowerAngle = -60;
	TwistUpperAngle = 60;
}

local R6_SHOULDER_LIMITS = {
	UpperAngle = 90;
	TwistLowerAngle = -30;
	TwistUpperAngle = 175;
}

local R6_HIP_LIMITS = {
	UpperAngle = 40;
	TwistLowerAngle = -120;
	TwistUpperAngle = 15;
}

-- { { parentPart, childPart, attachmentName, limits }, ... }
local R15_RAGDOLL_RIG = {
	{"UpperTorso", "Head", "NeckRigAttachment", HEAD_LIMITS},

	{"LowerTorso", "UpperTorso", "WaistRigAttachment", WAIST_LIMITS},

	{"UpperTorso", "LeftUpperArm", "LeftShoulderRigAttachment", SHOULDER_LIMITS},
	{"LeftUpperArm", "LeftLowerArm", "LeftElbowRigAttachment", ELBOW_LIMITS},
	{"LeftLowerArm", "LeftHand", "LeftWristRigAttachment", WRIST_LIMITS},

	{"UpperTorso", "RightUpperArm", "RightShoulderRigAttachment", SHOULDER_LIMITS},
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
R6_ADDITIONAL_ATTACHMENTS = {
	{"Head", "NeckAttachment", Vector3.new(0, -0.5, 0)},

	{"Torso", "RightShoulderRagdollAttachment", Vector3.new(1, 0.5, 0)},
	{"Right Arm", "RightShoulderRagdollAttachment", Vector3.new(-0.5, 0.5, 0)},

	{"Torso", "LeftShoulderRagdollAttachment", Vector3.new(-1, 0.5, 0)},
	{"Left Arm", "LeftShoulderRagdollAttachment", Vector3.new(0.5, 0.5, 0)},

	{"Torso", "RightHipAttachment", Vector3.new(0.5, -1, 0)},
	{"Right Leg", "RightHipAttachment", Vector3.new(0, 1, 0)},

	{"Torso", "LeftHipAttachment", Vector3.new(-0.5, -1, 0)},
	{"Left Leg", "LeftHipAttachment", Vector3.new(0, 1, 0)},
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
			local gravityScale = workspace.Gravity / 196.2
			local maxTorque = limits.FrictionTorque or 500
			constraint.MaxFrictionTorque = maxTorque * gravityScale
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

local function createRigJoints(model, rig, noCollides)
	for parentName, params in pairs(rig) do
		createRigJoint(model, unpack(params))
	end
	for _, params in ipairs(noCollides) do
		createNoCollide(model, unpack(params))
	end
end

local function breakMotorSet(model, motorSet)
	local motors = {}
	-- Destroy all regular joints:
	for _, params in ipairs(motorSet) do
		local part = model:FindFirstChild(params[2])
		if part then
			local motor = part:FindFirstChild(params[1])
			if motor and motor:IsA("Motor6D") then
				table.insert(motors, motor)
				motor:Destroy()
			end
		end
	end
	return motors
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
		-- Add additional "missing" attachments for R6
		for _, attachmentParams in ipairs(R6_ADDITIONAL_ATTACHMENTS) do
			local part = model:FindFirstChild(attachmentParams[1])
			if part and part:IsA("BasePart") then
				local name = attachmentParams[2]
				if not part:FindFirstChild(name) then
					local attachment = Instance.new("Attachment")
					attachment.Name = name
					attachment.Position = attachmentParams[3]
					attachment.Parent = part
				end
			end
		end

		createRigJoints(model, R6_RAGDOLL_RIG, R6_NO_COLLIDES)
	elseif rigType == Enum.HumanoidRigType.R15 then
		createRigJoints(model, R15_RAGDOLL_RIG, R15_NO_COLLIDES)
	else
		error("unknown rig type")
	end
end

function Rigging.removeRagdollJoints(model)
	for _, descendant in pairs(model:GetDescendants()) do
		if (descendant:IsA("BallSocketConstraint") and descendant.Name == BALL_SOCKET_NAME)
			or (descendant:IsA("NoCollisionConstraint") and descendant.Name == NO_COLLIDE_NAME)
		then
			descendant.Parent = nil
		end
	end
end

function Rigging.breakMotors(model, rigType)
	-- Note: We intentionally do not destroy the root joint so that the mechanism root of the
	-- character stays consistent when we break joints on the client before the server can do the
	-- same on a client-side triggered death.

	local motors
	if rigType == Enum.HumanoidRigType.R6 then
		motors = breakMotorSet(model, R6_MOTOR6DS)
	elseif rigType == Enum.HumanoidRigType.R15 then
		motors = breakMotorSet(model, R15_MOTOR6DS)
	else
		error("unknown rig type")
	end

	-- Set the root part to non-collide
	local rootPart = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		rootPart.CanCollide = false
	end

	return motors
end

function Rigging.disableMotors(model, rigType)
	-- Note: We intentionally do not destroy the root joint so that the mechanism root of the
	-- character stays consistent when we break joints on the client. This avoid the need for the client to wait
	-- for re-assignment of network ownership of a new mechanism, which creates a visible hitch.

	local motors
	if rigType == Enum.HumanoidRigType.R6 then
		motors = disableMotorSet(model, R6_MOTOR6DS)
	elseif rigType == Enum.HumanoidRigType.R15 then
		motors = disableMotorSet(model, R15_MOTOR6DS)
	else
		error("unknown rig type")
	end

	-- Set the root part to non-collide
	local rootPart = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		rootPart.CanCollide = false
	end

	return motors
end

return Rigging
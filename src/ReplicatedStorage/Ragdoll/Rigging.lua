local Rigging = {}

local HEAD_LIMITS = {
	UpperAngle = 60;
	TwistLowerAngle = -60;
	TwistUpperAngle = 60;
}

local LOWER_TORSO_LIMITS = {
	UpperAngle = 20;
	TwistLowerAngle = -30;
	TwistUpperAngle = 60;
}

local HAND_FOOT_LIMITS = {
	UpperAngle = 10;
	TwistLowerAngle = -10;
	TwistUpperAngle = 10;
}

local ELBOW_LIMITS = {
	UpperAngle = 10;
	TwistLowerAngle = 0;
	TwistUpperAngle = 120;
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
	TwistUpperAngle = 130;
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

	{"UpperTorso", "LowerTorso", "WaistRigAttachment", LOWER_TORSO_LIMITS},

	{"UpperTorso", "LeftUpperArm", "LeftShoulderRigAttachment", SHOULDER_LIMITS},
	{"LeftUpperArm", "LeftLowerArm", "LeftElbowRigAttachment", ELBOW_LIMITS},
	{"LeftLowerArm", "LeftHand", "LeftWristRigAttachment", HAND_FOOT_LIMITS},

	{"UpperTorso", "RightUpperArm", "RightShoulderRigAttachment", SHOULDER_LIMITS},
	{"RightUpperArm", "RightLowerArm", "RightElbowRigAttachment", ELBOW_LIMITS},
	{"RightLowerArm", "RightHand", "RightWristRigAttachment", HAND_FOOT_LIMITS},

	{"LowerTorso", "LeftUpperLeg", "LeftHipRigAttachment", HIP_LIMITS},
	{"LeftUpperLeg", "LeftLowerLeg", "LeftKneeRigAttachment", KNEE_LIMITS},
	{"LeftLowerLeg", "LeftFoot", "LeftAnkleRigAttachment", HAND_FOOT_LIMITS},

	{"LowerTorso", "RightUpperLeg", "RightHipRigAttachment", HIP_LIMITS},
	{"RightUpperLeg", "RightLowerLeg", "RightKneeRigAttachment", KNEE_LIMITS},
	{"RightLowerLeg", "RightFoot", "RightAnkleRigAttachment", HAND_FOOT_LIMITS},
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
local R15_MOTOR6DS = {
	{"Neck", "Head"},

	{"Waist", "LowerTorso"},

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
local R6_NO_COLLIDE = {
	{"Left Leg", "Right Leg"},
}
local R6_MOTOR6DS = {
	{"Neck", "Torso"},
	{"Left Shoulder", "Torso"},
	{"Right Shoulder", "Torso"},
	{"Left Hip", "Torso"},
	{"Right Hip", "Torso"},
}

local function createRigJoint(model, part0Name, part1Name, attachmentName, limits)
	local part0 = model:FindFirstChild(part0Name)
	local part1 = model:FindFirstChild(part1Name)
	if part0 and part1 then
		local a0 = part0:FindFirstChild(attachmentName)
		local a1 = part1:FindFirstChild(attachmentName)
		if a0 and a1 and a0:IsA("Attachment") and a1:IsA("Attachment") then
			local constraint = Instance.new("BallSocketConstraint")
			constraint.Name = "RagdollBallSocket"
			constraint.Attachment0 = a0
			constraint.Attachment1 = a1
			constraint.LimitsEnabled = true
			constraint.UpperAngle = limits.UpperAngle
			constraint.TwistLimitsEnabled = true
			constraint.TwistLowerAngle = limits.TwistLowerAngle
			constraint.TwistUpperAngle = limits.TwistUpperAngle
			constraint.Parent = part1
		end
	end
end

local function createRigJoints(model, rig)
	for _, params in ipairs(rig) do
		createRigJoint(model, unpack(params))
	end
end

local function createNoCollide(model, part0Name, part1Name)
	local part0 = model:FindFirstChild(part0Name)
	local part1 = model:FindFirstChild(part1Name)
	if part0 and part1 then
		local constraint = Instance.new("NoCollisionConstraint")
		constraint.Name = "RagdollNoCollision"
		constraint.Part0 = part0
		constraint.Part1 = part1
		constraint.Parent = part0
	end
end

function Rigging.createJoints(model, rigType)
	if rigType == Enum.HumanoidRigType.R6 then
		for _, attachmentParams in ipairs(R6_ADDITIONAL_ATTACHMENTS) do
			local part = model:FindFirstChild(attachmentParams[1])
			if part then
				local attachment = Instance.new("Attachment")
				attachment.Name = attachmentParams[2]
				attachment.Position = attachmentParams[3]
				attachment.Parent = part
			end
		end

		createRigJoints(model, R6_RAGDOLL_RIG)
		createNoCollide(model, "Left Leg", "Right Leg")
		createNoCollide(model, "Head", "Right Arm")
		createNoCollide(model, "Head", "Left Arm")
	elseif rigType == Enum.HumanoidRigType.R15 then
		createRigJoints(model, R15_RAGDOLL_RIG)
		for _, params in ipairs(R15_NO_COLLIDES) do
			createNoCollide(model, unpack(params))
		end
	else
		assert(false) -- Unknown rig type
	end
end

function Rigging.breakMotors(model, rigType)
	-- Note: We intentionally do not destroy the root joint so that the mechanism root of the
	-- character stays consistent when we break joints on the client before the server can do the
	-- same on a client-side triggered death.

	local motorSet
	if rigType == Enum.HumanoidRigType.R6 then
		motorSet = R6_MOTOR6DS
	elseif rigType == Enum.HumanoidRigType.R15 then
		motorSet = R15_MOTOR6DS
	else
		assert(false) -- Unknown rig type
	end

	-- Destroy all regular joints:
	for _, params in ipairs(motorSet) do
		local part = model:FindFirstChild(params[2])
		if part then
			local motor = part:FindFirstChild(params[1])
			if motor and motor:IsA("Motor6D") then
				motor:Destroy()
			end
		end
	end

	-- Set the root part to non-collide
	local rootPart = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		rootPart.CanCollide = false
	end
end

return Rigging
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ragdoll = require(ReplicatedStorage.Ragdoll)

-- Set ragdoll when China mode, and set breaking into pieces (default) 
Ragdoll:SetPlayerDefault(true)

require(ReplicatedStorage.Kill)
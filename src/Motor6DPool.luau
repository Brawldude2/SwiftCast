--!strict

local Config = require(script.Parent.Config)

local GROWTH_RATE = 2

local FreeMotor6Ds: {Motor6D} = {}
local Motor6DPoolSize = #FreeMotor6Ds

local function GrowPool(target: number)
	local growth = target - Motor6DPoolSize
	for i=1, growth do
		table.insert(FreeMotor6Ds, Instance.new("Motor6D"))
	end
	Motor6DPoolSize = target
end

local function Get(): Motor6D
	if #FreeMotor6Ds > 0 then
		return table.remove(FreeMotor6Ds) :: Motor6D
	else
		GrowPool(Motor6DPoolSize * GROWTH_RATE)
		return Get()
	end
end

local function Return(motor6d: Motor6D)
	table.insert(FreeMotor6Ds, motor6d)

	motor6d.Part0 = nil
	motor6d.Part1 = nil
	motor6d.Parent = nil
	motor6d.Transform = CFrame.identity
end

local function Initialize()
	GrowPool(Config.InitialMotor6DPoolSize)
end

return {
	Get = Get,
	Return = Return,
	Initialize = Initialize,
}
--!strict
--!optimize 2

local Simulation = {}
Simulation.IsRunning = false

local RunService = game:GetService("RunService")
local Types = require(script.Parent.Types)
local Config = require(script.Parent.Config)
local ProjectileSettings = require(script.Parent.ProjectileSettings)

type Projectile = Types.Projectile
type ProjectileEvent = Types.ProjectileEvent
type ProjectileSettings = Types.ProjectileSettings
type ProjectileContructorArgs = Types.ProjectileContructorArgs

local EPSILON = 1e-6

local ActiveInstancedProjectiles: {Projectile} = {}
local ActiveInstancelessProjectiles: {Projectile} = {}

local QueuedProjectileEvents: {ProjectileEvent} = {}

local PartTemplate = Instance.new("Part") :: BasePart
local Motor6DTemplate = Instance.new("Motor6D")
local Motor6DAnchor = Instance.new("Part")
Motor6DAnchor.Name = "SwiftCastAnchor"
Motor6DAnchor.Transparency = 1
Motor6DAnchor.CanCollide = false
Motor6DAnchor.CanQuery = false
Motor6DAnchor.CanTouch = false
Motor6DAnchor.AudioCanCollide = false
Motor6DAnchor.EnableFluidForces = false
Motor6DAnchor.Anchored = true
Motor6DAnchor.CFrame = CFrame.identity
Motor6DAnchor.Parent = workspace

local DefaultProjectileSettings = ProjectileSettings.new()
local StepConnection: RBXScriptConnection? = nil

local function OnError(errorMessage: string)
	warn(errorMessage)
end

local function ClearPostTranformConnections(projectile: Projectile)
	local connection = projectile._PostTransformFireConnection
	if connection then
		connection:Disconnect()
		projectile._PostTransformFireConnection = nil
	end
end

local function DestroyProjectileMotor6D(projectile: Projectile)
	if projectile._ProjectileMotor6D ~= Motor6DTemplate then
		projectile._ProjectileMotor6D:Destroy()
	end
end

local function ConnectTransform(projectile: Projectile)
	local projectilePart = projectile.ProjectilePart
	if not projectilePart then return end
	projectilePart.Anchored = false
	local motor6d = Instance.new("Motor6D")
	motor6d.Transform = projectilePart.CFrame
	motor6d.Part0 = Motor6DAnchor
	motor6d.Part1 = projectile.ProjectilePart
	motor6d.Parent = Motor6DAnchor
	ClearPostTranformConnections(projectile)
	projectile._ProjectileMotor6D = motor6d
	if projectile.PostTransform or projectile.PostTransformSafe then
		projectile._PostTransformFireConnection = RunService.Heartbeat:Once(function(deltaTime: number)
			if projectile.PostTransform then
				projectile.PostTransform(projectile)
			end
			if projectile.PostTransformSafe then
				projectile._PostTransformFireConnection = RunService.Heartbeat:Once(function(deltaTime: number)
					projectile.PostTransformSafe(projectile)
				end)
			end
		end)
	end
	return motor6d
end

local function GetCanPierce(projectile: Projectile, raycastResult: RaycastResult): boolean
	if typeof(projectile.CanPierce) == "function" then
		return projectile.CanPierce(projectile, raycastResult)
	else
		return projectile.CanPierce
	end
end

local function QueueProjectileEvent(callback: (Types.EventCallback)?, projectile: Projectile, arg1: any, arg2: any)
	if not callback then return end
	table.insert(QueuedProjectileEvents, { Callback = callback, Projectile = projectile, Arg1 = arg1, Arg2 = arg2 })
end

local DispatchAllProjectileEvents: () -> ()
local DispatchLastProjectileEvents: (removeCount: number) -> ()
if Config.UseProtectedCalls == true then
	DispatchAllProjectileEvents = function()
		for _, event in QueuedProjectileEvents do
			xpcall(event.Callback, OnError, event.Projectile, event.Arg1, event.Arg2)
		end
		table.clear(QueuedProjectileEvents)
	end
	DispatchLastProjectileEvents = function(removeCount)
		if removeCount <= 0 then return end
		local eventCount = #QueuedProjectileEvents
		for eventIndex = (eventCount - removeCount + 1), eventCount do
			local event = QueuedProjectileEvents[eventIndex]
			xpcall(event.Callback, OnError, event.Projectile, event.Arg1, event.Arg2)
		end
		for i = 1, removeCount do
			table.remove(QueuedProjectileEvents)
		end
	end
else
	DispatchAllProjectileEvents = function()
		for _, event in QueuedProjectileEvents do
			event.Callback(event.Projectile, event.Arg1, event.Arg2)
		end
		table.clear(QueuedProjectileEvents)
	end
	DispatchLastProjectileEvents = function(removeCount)
		if removeCount <= 0 then return end
		local eventCount = #QueuedProjectileEvents
		for eventIndex = (eventCount - removeCount + 1), eventCount do
			local event = QueuedProjectileEvents[eventIndex]
			event.Callback(event.Projectile, event.Arg1, event.Arg2)
		end
		for i = 1, removeCount do
			table.remove(QueuedProjectileEvents)
		end
	end
end

local function InsertProjectile(projectileArray: {Projectile}, projectile: Projectile)
	local index = #projectileArray + 1
	projectile._Index = index
	table.insert(projectileArray, projectile)
	projectile._ProjectileArray = projectileArray
end

local function RemoveProjectile(projectile: Projectile)
	if not projectile._ProjectileArray then return end
	local projectileArray = projectile._ProjectileArray
	local index = projectile._Index
	local lastProjectile = table.remove(projectileArray) :: Projectile
	if lastProjectile ~= projectile then
		projectileArray[index] = lastProjectile
		lastProjectile._Index = index
	end
end

local function DestroyProjectile(projectile: Projectile)
	if projectile._Destroyed then return end
	RemoveProjectile(projectile)
	DestroyProjectileMotor6D(projectile)
	ClearPostTranformConnections(projectile)
	projectile._MarkedForDestruction = true
	projectile._Destroyed = true
end

local function MoveProjectileToArray(targetProjectileArray: {Projectile}, projectile: Projectile)
	RemoveProjectile(projectile)
	InsertProjectile(targetProjectileArray, projectile)
end

local function MarkProjectileAsDestroyed(projectile: Projectile, reason: string?)
	QueueProjectileEvent(projectile.OnDestroy, projectile, reason)
	projectile._MarkedForDestruction = true
end

local function UpdateProjectile(projectile: Projectile, deltaTime: number)
	projectile.Elapsed += deltaTime
	if projectile.Elapsed >= projectile.MaxFlyTime then
		MarkProjectileAsDestroyed(projectile, "MaxTime")
		return
	end
	
	local position = projectile.Position
	
	local newVelocity = projectile.Velocity + (projectile.Acceleration * deltaTime)
	local newPosition = position + (newVelocity * deltaTime)
	
	local deltaDistance = (newPosition - position).Magnitude
	if deltaDistance <= EPSILON then
		QueueProjectileEvent(projectile.OnStep, projectile, deltaTime)
		return
	end
	
	projectile.DistanceTravelled += deltaDistance
	if projectile.DistanceTravelled >= projectile.MaxFlyDistance then
		MarkProjectileAsDestroyed(projectile, "MaxDistance")
		return
	end

	local direction = newVelocity.Unit
	local raycastParams = projectile.RaycastParams
	local raycastFunction = projectile.RaycastFunction
	
	local rayOrigin = position
	local rayOffset = direction * 0.01
	local remainingDistance = deltaDistance

	for iteration = 1, projectile.MaxPiercesPerStep do
		local raycastResult = raycastFunction(rayOrigin, direction * remainingDistance, raycastParams, projectile, iteration)
		if not raycastResult then break end
		
		local canPierce = GetCanPierce(projectile, raycastResult)
		if canPierce ~= true then
			MarkProjectileAsDestroyed(projectile, "Hit")
			return
		end
		
		QueueProjectileEvent(projectile.OnRayPierce, projectile, raycastResult)

		remainingDistance -= raycastResult.Distance + 0.01
		if remainingDistance <= 0 then
			break
		end

		rayOrigin = raycastResult.Position + rayOffset
	end

	QueueProjectileEvent(projectile.OnStep, projectile, deltaTime)
	QueueProjectileEvent(projectile.OnPositionChange, projectile, newPosition, position)

	projectile.PreviousPosition = position
	projectile.Position = newPosition
	projectile.Velocity = newVelocity
end

local UpdateInstancedProjectiles: (deltaTime: number, destroyedProjectiles: {Projectile}) -> ()
if Config.MovementMethod == "Transform" then
	UpdateInstancedProjectiles = function(deltaTime: number, destroyedProjectiles: {Projectile})
		for index, projectile in ActiveInstancedProjectiles do
			UpdateProjectile(projectile, deltaTime)
			projectile._ProjectileMotor6D.Transform = projectile.ProjectilePartRotation.Rotation + projectile.Position
			if projectile._MarkedForDestruction then
				table.insert(destroyedProjectiles, projectile)
			end
		end
	end
else
	UpdateInstancedProjectiles = function(deltaTime: number, destroyedProjectiles: {Projectile})
		local cframes = table.create(#ActiveInstancedProjectiles, CFrame.identity) :: {CFrame}
		local parts = table.create(#ActiveInstancedProjectiles, PartTemplate) :: {BasePart}
		for index, projectile in ActiveInstancedProjectiles do
			UpdateProjectile(projectile, deltaTime)
			cframes[index] = projectile.ProjectilePartRotation.Rotation + projectile.Position
			parts[index] = projectile.ProjectilePart :: BasePart
			if projectile._MarkedForDestruction then
				table.insert(destroyedProjectiles, projectile)
			end
		end
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

local function NewProjectile(constructorArgs: ProjectileContructorArgs, projectileSettings: ProjectileSettings?): Projectile
	local projectileSettings = projectileSettings or DefaultProjectileSettings
	local position = constructorArgs.Position or Vector3.zero
	local canPierce = constructorArgs.CanPierce :: Types.CanPierce
	if canPierce == nil then
		canPierce = projectileSettings.CanPierce
	end
	local projectilePart = constructorArgs.ProjectilePart
	local projectilePartRotation = if projectilePart then projectilePart.CFrame.Rotation else CFrame.identity
	local projectile: Projectile = {
		_Active = false,
		_Destroyed = false,
		_MarkedForDestruction = false,
		_ProjectileArray = nil,
		_Index = 0,
		_ProjectileMotor6D = Motor6DTemplate,
		_PostTransformFireConnection = nil,

		Position = position,
		PreviousPosition = position,
		Velocity = constructorArgs.Velocity or Vector3.zero,
		Acceleration = constructorArgs.Acceleration or Vector3.zero,
		
		Elapsed = 0,
		DistanceTravelled = 0,

		MaxFlyTime = constructorArgs.MaxFlyTime or projectileSettings.MaxFlyTime,
		MaxFlyDistance = constructorArgs.MaxFlyDistance or projectileSettings.MaxFlyDistance,
		MaxPiercesPerStep = constructorArgs.MaxPiercesPerStep or projectileSettings.MaxPiercesPerStep,
		RaycastParams = constructorArgs.RaycastParams or projectileSettings.RaycastParams,
		RaycastFunction = constructorArgs.RaycastFunction or projectileSettings.RaycastFunction,
		ProjectilePart = projectilePart,
		ProjectilePartRotation = projectilePartRotation,

		CanPierce = canPierce,
		
		OnRayPierce = constructorArgs.OnRayPierce,
		OnStep = constructorArgs.OnStep,
		OnPositionChange = constructorArgs.OnPositionChange,
		OnDestroy = constructorArgs.OnDestroy,
		PostTransform = constructorArgs.PostTransform,

		BlockcastSize = constructorArgs.BlockcastSize or projectileSettings.BlockcastSize,
		SpherecastRadius = constructorArgs.SpherecastRadius or projectileSettings.SpherecastRadius,
		ShapecastPart = constructorArgs.ShapecastPart or projectileSettings.ShapecastPart,
		UserData = constructorArgs.UserData,
	}
	
	if Config.MovementMethod == "Transform" then
		ConnectTransform(projectile)
	end
	
	return projectile
end

-- Creates a projectile and activates it
function Simulation.SpawnProjectile(constructorArgs: ProjectileContructorArgs, projectileSettings: ProjectileSettings?): Projectile
	local projectile = NewProjectile(constructorArgs, projectileSettings)
	projectile._Active = true
	if projectile.ProjectilePart then
		InsertProjectile(ActiveInstancedProjectiles, projectile)
	else
		InsertProjectile(ActiveInstancelessProjectiles, projectile)
	end
	return projectile
end

-- Creates a projectile
function Simulation.CreateProjectile(constructorArgs: ProjectileContructorArgs, projectileSettings: ProjectileSettings?): Projectile
	local projectile = NewProjectile(constructorArgs, projectileSettings)
	projectile._Active = false
	return projectile
end

-- Marks projectile as destroyed, emits destroyed event and destroys the projectile
function Simulation.TerminateProjectile(projectile: Projectile, reason: string?)
	local lastEventIndex = #QueuedProjectileEvents
	MarkProjectileAsDestroyed(projectile, reason)

	local newEventCount = #QueuedProjectileEvents - lastEventIndex
	DispatchLastProjectileEvents(newEventCount)

	DestroyProjectile(projectile)
end

-- Activates a projectile making it start simulating
function Simulation.ActivateProjectile(projectile: Projectile)
	if projectile._Active then return end
	if projectile.ProjectilePart then
		MoveProjectileToArray(ActiveInstancedProjectiles, projectile)
	else
		MoveProjectileToArray(ActiveInstancelessProjectiles, projectile)
	end
end

-- Deactivates a projectile making it stop simulating
function Simulation.DeactivateProjectile(projectile: Projectile)
	if not projectile._Active then return end
	RemoveProjectile(projectile)
end

-- Steps a projectile
function Simulation.StepProjectile(projectile: Projectile, deltaTime: number)
	local lastEventIndex = #QueuedProjectileEvents

	UpdateProjectile(projectile, deltaTime)
	if projectile.ProjectilePart then
		projectile.ProjectilePart.CFrame = CFrame.new(projectile.Position)
	end

	local newEventCount = #QueuedProjectileEvents - lastEventIndex
	if newEventCount > 0 then
		DispatchLastProjectileEvents(newEventCount)
	end

	if projectile._MarkedForDestruction then
		DestroyProjectile(projectile)
	end
end

-- Sets a projectile part for the projectile
function Simulation.SetProjectilePart(projectile: Projectile, basePart: BasePart?)
	projectile.ProjectilePart = basePart

	local isBasePartNil = basePart == nil
	local isProjectiePartNil = projectile.ProjectilePart == nil
	if isBasePartNil == isProjectiePartNil then return end

	DestroyProjectileMotor6D(projectile)
	if Config.MovementMethod == "Transform" then
		ConnectTransform(projectile)
	end
	
	if projectile.ProjectilePart then
		MoveProjectileToArray(ActiveInstancedProjectiles, projectile)
	else
		MoveProjectileToArray(ActiveInstancelessProjectiles, projectile)
	end
end

-- Starts SwiftCast simulation
function Simulation.Start()
	if Simulation.IsRunning then return end
	Simulation.IsRunning = true
	StepConnection = RunService.PreSimulation:Connect(Simulation.Step)
end

-- Stops SwiftCast simulation
function Simulation.Stop()
	if not Simulation.IsRunning then return end
	Simulation.IsRunning = false
	if StepConnection then
		StepConnection:Disconnect()
		StepConnection = nil
	end
end

-- Steps SwiftCast simulation
function Simulation.Step(deltaTime: number)
	local destroyedProjectiles: {Projectile} = {}
	for index, projectile in ActiveInstancelessProjectiles do
		UpdateProjectile(projectile, deltaTime)
		if projectile._MarkedForDestruction then
			table.insert(destroyedProjectiles, projectile)
		end
	end

	if #ActiveInstancedProjectiles >= 0 then
		UpdateInstancedProjectiles(deltaTime, destroyedProjectiles)
	end

	DispatchAllProjectileEvents()

	for _, projectile in destroyedProjectiles do
		DestroyProjectile(projectile)
	end
end

if Config.StartOnRequire then
	Simulation.Start()
end

return Simulation
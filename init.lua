--!strict
--!optimize 2

local SwiftCast = {}

local Types = require(script.Types)
local Simulation = require(script.Simulation)
local RaycastFunctions = require(script.RaycastFunctions)
local ProjectileSettings = require(script.ProjectileSettings)

export type Projectile = Types.Projectile
export type RaycastFunction = Types.RaycastFunction
export type ProjectileSettings = Types.ProjectileSettings
export type ProjectileContructorArgs = Types.ProjectileContructorArgs

SwiftCast.ProjectileSettings = ProjectileSettings
SwiftCast.RaycastFunctions = RaycastFunctions

SwiftCast.SpawnProjectile = Simulation.SpawnProjectile
SwiftCast.CreateProjectile = Simulation.CreateProjectile
SwiftCast.ActivateProjectile = Simulation.ActivateProjectile
SwiftCast.DeactivateProjectile = Simulation.DeactivateProjectile
SwiftCast.TerminateProjectile = Simulation.TerminateProjectile

SwiftCast.Start = Simulation.Start
SwiftCast.Stop = Simulation.Stop
SwiftCast.Step = Simulation.Step
SwiftCast.StepProjectile = Simulation.StepProjectile
SwiftCast.SetProjectilePart = Simulation.SetProjectilePart

-- Checks if SwiftCast simulation is running
function SwiftCast.IsRunning(): boolean
	return Simulation.IsRunning
end

return table.freeze(SwiftCast)
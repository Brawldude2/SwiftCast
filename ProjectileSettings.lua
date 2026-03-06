--!strict
--!optimize 2

local ProjectileSettings = {}

local Types = require(script.Parent.Types)
local RaycastFunctions = require(script.Parent.RaycastFunctions)

function ProjectileSettings.new(projectileSettings: Types.ProjectileSettingsOptional?): Types.ProjectileSettings
	local projectileSettings: Types.ProjectileSettingsOptional = projectileSettings or {}
	return {
		MaxFlyTime = projectileSettings.MaxFlyTime or math.huge,
		MaxFlyDistance = projectileSettings.MaxFlyDistance or 100,
		RaysPerMove =  projectileSettings.RaysPerMove or 1,
		RaycastParams = projectileSettings.RaycastParams or RaycastParams.new(),
		RaycastFunction = projectileSettings.RaycastFunction or RaycastFunctions.Default,
		ProjectileContainer = projectileSettings.ProjectileContainer or workspace,
		CanPierce = projectileSettings.CanPierce or false,
		BlockcastSize = projectileSettings.BlockcastSize,
		SpherecastRadius = projectileSettings.SpherecastRadius,
		ShapecastPart = projectileSettings.ShapecastPart,
	}
end

return table.freeze(ProjectileSettings)
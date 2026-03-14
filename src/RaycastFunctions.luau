--!strict
--!optimize 2

local RaycastFunctions = {}

local Types = require(script.Parent.Types)

RaycastFunctions.Raycast = function(rayOrigin, rayDirection, raycastParams, projectile, iteration)
	return workspace:Raycast(rayOrigin, rayDirection, raycastParams)
end :: Types.RaycastFunction

RaycastFunctions.Blockcast = function(rayOrigin, rayDirection, raycastParams, projectile, iteration)
	if not projectile.BlockcastSize then
		warn("[SwiftCast]: No BlockcastSize assigned for the projectile.")
		return nil
	end
	return workspace:Blockcast(CFrame.lookAlong(rayOrigin, rayDirection), projectile.BlockcastSize, rayDirection, raycastParams)
end :: Types.RaycastFunction

RaycastFunctions.Spherecast = function(rayOrigin, rayDirection, raycastParams, projectile, iteration)
	if not projectile.SpherecastRadius then
		warn("[SwiftCast]: No SpherecastRadius assigned for the projectile.")
		return nil
	end
	return workspace:Spherecast(rayOrigin, projectile.SpherecastRadius, rayDirection, raycastParams)
end :: Types.RaycastFunction

RaycastFunctions.Shapecast = function(rayOrigin, rayDirection, raycastParams, projectile, iteration)
	if not projectile.ShapecastPart then
		warn("[SwiftCast]: No ShapecastPart assigned for the projectile.")
		return nil
	end
	projectile.ShapecastPart.Position = rayOrigin
	return workspace:Shapecast(projectile.ShapecastPart, rayDirection, raycastParams)
end :: Types.RaycastFunction

RaycastFunctions.Default = RaycastFunctions.Raycast

return table.freeze(RaycastFunctions)
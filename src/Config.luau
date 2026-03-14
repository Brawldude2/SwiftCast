--!strict

local Types = require(script.Parent.Types)
local Config: Types.Config = {
	-- Uses protected calls for event callbacks
	UseProtectedCalls = true,

	-- Starts the simulation on require
	StartOnRequire = true,

	-- Switches between BulkMoveTo and Transform movement methods
	MovementMethod = "BulkMoveTo",
	
	-- The offset ray adds to the raycast position to search for the next hit
	RaySearchOffset = 0.001,
}
return table.freeze(Config)
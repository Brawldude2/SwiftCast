--!strict

local Types = require(script.Parent.Types)
local Config: Types.Config = {
	-- Uses protected calls for event callbacks
	UseProtectedCalls = true,

	-- Starts the simulation on require
	StartOnRequire = true,

	-- Switches between BulkMoveTo and Transform movement methods
	MovementMethod = "BulkMoveTo",
}
return table.freeze(Config)
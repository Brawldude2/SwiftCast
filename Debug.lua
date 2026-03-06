--!strict
--!optimize 2

local Debug = {}

local function VisualizeSegment(castStartCFrame: CFrame, castLength: number, Color: Color3)
	local adornment = Instance.new("Part")
	adornment.CFrame = castStartCFrame * CFrame.new(0, 0, -castLength / 2)
	adornment.Color = Color
	adornment.CanCollide = false
	adornment.CanTouch = false
	adornment.CanQuery = false
	adornment.Reflectance = 0
	adornment.CastShadow = false
	adornment.Anchored = true
	adornment.Material = Enum.Material.SmoothPlastic
	adornment.Size = Vector3.new(0.2, 0.2, castLength)
	adornment.Transparency = 0.5
	adornment.Parent = workspace.Visualization
end

local function VisualizeDot(castStartPosition: Vector3, Color: Color3, Size: Vector3)
	local adornment = Instance.new("Part")
	adornment.CastShadow = false
	adornment.CanCollide = false
	adornment.CanTouch = false
	adornment.CanQuery = false
	adornment.Anchored = true
	adornment.Shape = Enum.PartType.Ball
	adornment.Position = castStartPosition
	adornment.Reflectance = 0
	adornment.Material = Enum.Material.SmoothPlastic
	adornment.Size = Size
	adornment.Color = Color
	adornment.Parent = workspace.Visualization
end

Debug.VisualizeSegment = VisualizeSegment
Debug.VisualizeDot = VisualizeDot

return Debug

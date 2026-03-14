--!strict

export type CanPierce = (CanPierceCallback | boolean)
export type RaycastFunction = (rayOrigin: Vector3, rayDirection: Vector3, raycastParams: RaycastParams, projectile: Projectile, iteration: number) -> (RaycastResult?)

export type PostTransform = (projectile: Projectile) -> ()
export type PostTransformSafe = (projectile: Projectile) -> ()
export type OnStep = (projectile: Projectile, deltaTime: number) -> ()
export type OnPositionChange = (projectile: Projectile, newPosition: Vector3, oldPosition: Vector3) -> ()
export type OnHit = (projectile: Projectile, result: RaycastResult, hasPierced: boolean) -> ()
export type OnDestroy = (projectile: Projectile, reason: string | "MaxTime" | "MaxDistance" | "Hit" | nil) -> ()
export type CanPierceCallback = (projectile: Projectile, result: RaycastResult) -> (boolean)

export type EventCallback = (projectile: Projectile, arg1: any, arg2: any) -> ()
export type ProjectileEvent = {Callback: EventCallback, Projectile: Projectile, Arg1: any, Arg2: any}

export type Config = {
	UseProtectedCalls: boolean,
	StartOnRequire: boolean,
	MovementMethod: "BulkMoveTo" | "Transform",
	RaySearchOffset: number,
}

export type ProjectileSettings = {
	MaxFlyTime: number,
	MaxFlyDistance: number,
	MaxPiercesPerStep: number,
	RaycastParams: RaycastParams,
	RaycastFunction: RaycastFunction,
	CanPierce: CanPierce,

	BlockcastSize: Vector3?,
	SpherecastRadius: number?,
	ShapecastPart: BasePart?,
}

export type ProjectileSettingsOptional = {
	MaxFlyTime: number?,
	MaxFlyDistance: number?,
	MaxPiercesPerStep: number?,
	RaycastParams: RaycastParams?,
	RaycastFunction: RaycastFunction?,
	CanPierce: CanPierce?,

	BlockcastSize: Vector3?,
	SpherecastRadius: number?,
	ShapecastPart: BasePart?,
}

export type ProjectileConstructorArgs = {
	MaxFlyTime: number?,
	MaxFlyDistance: number?,
	MaxPiercesPerStep: number?,
	RaycastParams: RaycastParams?,
	RaycastFunction: RaycastFunction?,
	CanPierce: CanPierce?,

	Position: Vector3?,
	Velocity: Vector3?,
	Acceleration: Vector3?,

	OnHit: OnHit?,
	OnStep: OnStep?,
	OnPositionChange: OnPositionChange?,
	OnDestroy: OnDestroy?,
	PostTransform: PostTransform?,
	PostTransformSafe: PostTransformSafe?,
	
	ProjectilePart: BasePart?,
	ProjectilePartRotation: CFrame?,

	BlockcastSize: Vector3?,
	SpherecastRadius: number?,
	ShapecastPart: BasePart?,
	UserData: any?,
}

export type Projectile = {
	-- Lifetime
	_Active: boolean,
	_Destroyed: boolean,
	_MarkedForDestruction: boolean,
	_Index: number,
	_ProjectileArray: {Projectile}?,
	_ProjectileMotor6D: Motor6D,
	_PostTransformFireConnection: RBXScriptConnection?,
	
	-- State
	PreviousPosition: Vector3,
	Position: Vector3,
	Velocity: Vector3,
	Acceleration: Vector3,
	Elapsed: number,
	DistanceTravelled: number,
	
	-- Data
	MaxFlyTime: number,
	MaxFlyDistance: number,
	MaxPiercesPerStep: number,
	RaycastParams: RaycastParams,
	RaycastFunction: RaycastFunction,
	ProjectilePart: BasePart?,
	ProjectilePartRotation: CFrame,
	
	-- Callbacks
	CanPierce: CanPierce,
	OnHit: OnHit?,
	OnStep: OnStep?,
	OnPositionChange: OnPositionChange?,
	OnDestroy: OnDestroy?,
	PostTransform: PostTransform?,
	PostTransformSafe: PostTransformSafe?,
	
	-- Optional data
	BlockcastSize: Vector3?,
	SpherecastRadius: number?,
	ShapecastPart: BasePart?,
	UserData: any,
}

return nil
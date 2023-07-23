extends Item

class_name Weapon

@export var damage: int
@export var attackRange: int
@export var manaCost: int
@export var isHealing: bool = false
@export var canTargetFriendly: bool = true
@export var canTargetEnemy: bool = true

@export var bulletSpeed: float
@export var bulletTexture: Texture

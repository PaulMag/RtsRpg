extends Item

class_name Weapon

@export var damage: int
@export var range: int
@export var manaCost: int
@export var canTargetFriendly: bool = true
@export var canTargetEnemy: bool = true

@export var bulletSpeed: float
@export var bulletTexture: Texture

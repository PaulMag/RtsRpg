extends Area2D

class_name Projectile


@onready var sprite: Sprite2D = $Sprite2D

var attack: Attack
var target: Unit
var texture: Texture
var speed: float


const SCENE := preload("res://scenes/Projectile.tscn")
static func init(_attack: Attack, _target: Unit, _texture: Texture = null, _speed: float = 999) -> Projectile:
	var scene: Projectile = SCENE.instantiate()
	scene.attack = _attack
	scene.target = _target
	scene.texture = _texture
	scene.speed = _speed
	scene.position = _attack.attackingUnit.position
	return scene

func _ready() -> void:
	if texture:
		sprite.set_texture(texture as Texture2D)

func _physics_process(delta: float) -> void:
	if target and is_instance_valid(target):
		rotation = position.angle_to_point(target.position)
		position += position.direction_to(target.position) * speed * delta
	else:
		position += Vector2.from_angle(rotation) * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body == target:
		target.damage(attack)
		queue_free()

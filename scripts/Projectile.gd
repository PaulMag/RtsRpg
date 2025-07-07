extends Area3D

class_name Projectile


# @onready var sprite: Sprite2D = $Sprite2D  #TODO: Replace with MeshInstance3D or similar for 3D

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
	print(_speed)
	return scene

func _ready() -> void:
	pass
	#TODO: Teplace this with mesh
	#if texture:
		#sprite.set_texture(texture as Texture2D)

func _physics_process(delta: float) -> void:
	if target and is_instance_valid(target):
		if target.position != position:
			look_at(Vector3(target.position.x, position.y, target.position.z))
		position += position.direction_to(target.position) * speed * delta
	else:
		position += -transform.basis.z * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if body == target:
		target.damage(attack)
		queue_free()

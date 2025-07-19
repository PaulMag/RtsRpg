extends Area3D

class_name Projectile


@onready var meshInstance: MeshInstance3D = $MeshInstance

var attack: Attack
var target: Unit
var mesh: Mesh
var speed: float

const heightAboveGround := Vector3(0, 0.8, 0)  # Keep projectile above ground


const SCENE := preload("res://scenes/Projectile.tscn")
static func init(_attack: Attack, _target: Unit, _mesh: Mesh = null, _speed: float = 999) -> Projectile:
	var scene: Projectile = SCENE.instantiate()
	scene.attack = _attack
	scene.target = _target
	scene.mesh = _mesh
	scene.speed = _speed
	scene.position = _attack.attackingUnit.position + heightAboveGround
	return scene

func _ready() -> void:
	if mesh:
		meshInstance.mesh = mesh

func _physics_process(delta: float) -> void:
	if target and is_instance_valid(target):
		if target.position != position:
			look_at(Vector3(target.position.x, position.y, target.position.z))
		position += position.direction_to(target.position + heightAboveGround) * speed * delta
	else:
		position += -transform.basis.z * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if body == target:
		target.damage(attack)
		queue_free()

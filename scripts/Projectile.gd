extends Area3D

class_name Projectile


@onready var meshInstance: MeshInstance3D = $MeshInstance
@onready var audioPlayer: AudioStreamPlayer3D = $AudioPlayer

var attack: Attack
var target: Unit
var mesh: Mesh
var audioStreamShoot: AudioStream
var audioStreamHit: AudioStream
var speed: float

var isActive: bool = true

const heightAboveGround := Vector3(0, 0.8, 0)  # Keep projectile above ground


const SCENE := preload("res://scenes/Projectile.tscn")
static func init(
		_attack: Attack,
		_target: Unit,
		_mesh: Mesh = null,
		_audioStreamShoot: AudioStream = null,
		_audioStreamHit: AudioStream = null,
		_speed: float = 999,
) -> Projectile:
	var scene: Projectile = SCENE.instantiate()
	scene.attack = _attack
	scene.target = _target
	scene.mesh = _mesh
	scene.audioStreamShoot = _audioStreamShoot
	scene.audioStreamHit = _audioStreamHit
	scene.speed = _speed
	scene.position = _attack.attackingUnit.position + heightAboveGround
	return scene

func _ready() -> void:
	if mesh:
		meshInstance.mesh = mesh
	if audioStreamShoot:
		audioPlayer.stream = audioStreamShoot
		audioPlayer.play()

func _physics_process(delta: float) -> void:
	if not isActive:
		return
	if target and is_instance_valid(target):
		if Global.vec3_to_vec2(target.position) != Global.vec3_to_vec2(position):
			look_at(Vector3(target.position.x, position.y, target.position.z))
		position += position.direction_to(target.position + heightAboveGround) * speed * delta
	else:
		position += -transform.basis.z * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if body == target and isActive:
		target.damage(attack)
		if audioPlayer.playing:
			audioPlayer.stop()
		if audioStreamHit:
			audioPlayer.stream = audioStreamHit
			audioPlayer.play()
		visible = false
		isActive = false
		if audioPlayer.playing:
			await audioPlayer.finished
		queue_free()

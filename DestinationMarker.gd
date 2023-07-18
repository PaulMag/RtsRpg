extends Node2D

class_name DestinationMarker


const AMPLITUDE := 10.0
const SPEED := 2 * PI
const COLOR_MOVE := Color.GREEN
const COLOR_ATTACK := Color.RED

@onready var sprite: Sprite2D = $Sprite2D
@onready var timer: Timer = $Timer

var markerMotion: float
var targetUnit: Unit = null
var offset: float


func _process(delta) -> void:
	if visible:
		if is_instance_valid(targetUnit):
			position = targetUnit.position
		sprite.position.y = offset + sin(markerMotion * SPEED) * AMPLITUDE - AMPLITUDE
		markerMotion += delta

func markMove(pos: Vector2) -> void:
	targetUnit = null
	position = pos
	modulate = COLOR_MOVE
	markerMotion = - SPEED / 2
	offset = 0
	visible = true
	timer.start()

func markAttack(unit: Unit) -> void:
	targetUnit = unit
	modulate = COLOR_ATTACK
	markerMotion = - SPEED / 2
	offset = - 64
	visible = true
	timer.start()

func _on_timer_timeout():
	visible = false
	targetUnit = null

extends StaticBody2D

class_name Bullet

var SPEED = 500

var damage: int = 1
var target: Unit = null

func _physics_process(delta: float) -> void:
	if target:
		rotation = position.angle_to_point(target.position)
		position += position.direction_to(target.position) * SPEED * delta


func _on_area_2d_body_entered(unit: Unit) -> void:
	if unit == target:
		unit.damage(damage)
		queue_free()

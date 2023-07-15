extends StaticBody2D

class_name Bullet

var speed: int
var damage: int
var target: Unit

var sprite: Sprite2D

func _ready() -> void:
	sprite = $Sprite2D

func _physics_process(delta: float) -> void:
	if target and is_instance_valid(target):
		rotation = position.angle_to_point(target.position)
		position += position.direction_to(target.position) * speed * delta
	else:
		position += Vector2.from_angle(rotation) * speed * delta


func _on_area_2d_body_entered(unit: Unit) -> void:
	if unit == target:
		unit.damage(damage)
		queue_free()

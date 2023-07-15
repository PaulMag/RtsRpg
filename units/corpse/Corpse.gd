extends Node2D

class_name Corpse


@onready var sprite = $AnimatedSprite2D


func _ready() -> void:
	var fallFrame = randi_range(0, 5)
	var fallRight = fallFrame <= 2

	sprite.frame = fallFrame

	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "rotation_degrees", 90 if fallRight else -90, 0.3)
	tween.tween_property(sprite, "modulate", Color(0.5, 0.5, 0.5), 1)
	tween.set_parallel(false)
	tween.tween_property(sprite, "modulate", Color(0.5, 0.5, 0.5, 0), 10)
	tween.tween_callback(queue_free)

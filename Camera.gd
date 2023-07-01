extends Camera2D

const SPEED = 200

func _process(delta):

	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	position += direction * delta * SPEED

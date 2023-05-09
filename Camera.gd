extends Camera2D

const SPEED = 200

func _process(delta):

	if false:
		if Input.is_action_pressed("ui_left"):
			position.x -= delta * SPEED
		if Input.is_action_pressed("ui_right"):
			position.x += delta * SPEED
		if Input.is_action_pressed("ui_up"):
			position.y -= delta * SPEED
		if Input.is_action_pressed("ui_down"):
			position.y += delta * SPEED
 

extends StaticBody3D


func _on_input_event(_camera: Node, event: InputEvent, event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event.is_action_pressed("mouse_right_click"):
		Global.getPlayerCurrent().moveTo(event_position)

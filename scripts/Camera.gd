extends Node3D


@onready var camera: Camera3D = $Camera


func _ready() -> void:
	Global.cameraArm = self


func _process(delta: float) -> void:
	var currentPlayer := Global.getPlayerCurrent()
	if currentPlayer == null:  #TODO: Workaround for bug.
		return

	var selectedUnit := Global.getUnitFromUnitId(currentPlayer.selectedUnitId)
	if selectedUnit:
		position = selectedUnit.position
		position.y += 0.8

	if Input.is_action_pressed("camera_left"):
		rotation.y -= PI * 0.6 * delta
	if Input.is_action_pressed("camera_right"):
		rotation.y += PI * 0.6 * delta
	if Input.is_action_pressed("camera_up"):
		rotation.x -= PI * 0.4 * delta
		rotation.x = clamp(rotation.x, -PI / 2, 0)
	if Input.is_action_pressed("camera_down"):
		rotation.x += PI * 0.4 * delta
		rotation.x = clamp(rotation.x, -PI / 2, 0)
	if Input.is_action_pressed("camera_in"):
		camera.position.z -= 10 * delta
		camera.position.z = clamp(camera.position.z, 1, 20)
	if Input.is_action_pressed("camera_out"):
		camera.position.z += 10 * delta
		camera.position.z = clamp(camera.position.z, 1, 20)
	if Input.is_action_just_released("camera_in_scroll"):
		camera.position.z -= 0.5
		camera.position.z = clamp(camera.position.z, 1, 20)
	if Input.is_action_just_released("camera_out_scroll"):
		camera.position.z += 0.5
		camera.position.z = clamp(camera.position.z, 1, 20)

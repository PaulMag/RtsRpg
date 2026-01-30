extends Node3D


@onready var camera: Camera3D = $Camera

var rotate_mode: bool = false
var rot_x: float = 0
var rot_y: float = -PI / 4


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
		rot_x -= PI * 0.6 * delta
	if Input.is_action_pressed("camera_right"):
		rot_x += PI * 0.6 * delta
	if Input.is_action_pressed("camera_up"):
		rot_y -= PI * 0.4 * delta
	if Input.is_action_pressed("camera_down"):
		rot_y += PI * 0.4 * delta
	if Input.is_action_pressed("camera_in"):
		camera.position.z -= 10 * delta
		camera.position.z = clamp(camera.position.z, 1, 20)
	if Input.is_action_pressed("camera_out"):
		camera.position.z += 10 * delta
		camera.position.z = clamp(camera.position.z, 1, 20)

	rot_y = clamp(rot_y, -PI / 2, -0.087)  # 90 to 5 degrees
	transform.basis = Basis()
	rotate_object_local(Vector3(0, 1, 0), rot_x)
	rotate_object_local(Vector3(1, 0, 0), rot_y)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("camera_rotate_mode"):
		rotate_mode = true
	elif event.is_action_released("camera_rotate_mode"):
		rotate_mode = false
	elif rotate_mode and event is InputEventMouseMotion:
		var mouse_motion_event := event as InputEventMouseMotion
		rot_x -= mouse_motion_event.screen_relative.x * 0.005
		rot_y -= mouse_motion_event.screen_relative.y * 0.005
	elif event.is_action_released("camera_in_scroll"):
		camera.position.z -= 0.5
		camera.position.z = clamp(camera.position.z, 1, 20)
	elif event.is_action_released("camera_out_scroll"):
		camera.position.z += 0.5
		camera.position.z = clamp(camera.position.z, 1, 20)

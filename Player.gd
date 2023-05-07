extends Node

@export var playerId = 0
@export var direction := Vector2()
@export var selectedUnits = []

@export var isCloning = false

const SELECTION_BOX_MINIMUM_SIZE = 5

var allUnits = []
var isDraggingMouse = false
var isSelecting = false
var selectionStart = Vector2()
var selectionEnd = Vector2()


func _ready():
	playerId = name.to_int()
	set_multiplayer_authority(playerId)
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())
#	print("Processing for player %s." % $"..".playerId)
	if multiplayer.is_server():
		print("Player on server: ", playerId, "  '", name, "'  ")
	else:
		print("Player on peer:   ", playerId, "  '", name, "'  ")


func _process(delta):
	
	if isDraggingMouse:
		draw_selection_box()
		
#	$"..".playerId = multiplayer.get_unique_id()
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
#	if direction:
#		print(playerId, "   ", direction)
	if Input.is_action_just_pressed("ui_cancel"):
		clone.rpc()
		

@rpc("call_local")
func clone():
	isCloning = true


func area_selected(start, end):
	var area = []
	area.append(Vector2(min(start.x, end.x), min(start.y, end.y)))
	area.append(Vector2(max(start.x, end.x), max(start.y, end.y)))
	set_selection_area(area)

func _input(event):
	event.is_action_pressed("mouse_left_click")
	if event.is_action_pressed("mouse_left_click"):
		selectionStart = $Panel.get_global_mouse_position()
		isDraggingMouse = true	
		$Panel.visible = true
	if isDraggingMouse:
		selectionEnd = $Panel.get_global_mouse_position()
	if event.is_action_released("mouse_left_click"):
		selectionEnd = $Panel.get_global_mouse_position()
		isDraggingMouse = false
		$Panel.visible = false
		area_selected(selectionStart, selectionEnd)

func _on_selection_timer_timeout():
	isSelecting = false
	$SelectionDetector/CollisionShape2D.disabled  = true

func set_selection_area(area):
	allUnits = get_tree().get_nodes_in_group("units")
	for unit in allUnits:
		unit.set_selected(false)
	selectedUnits = []
	isSelecting = true
	$SelectionDetector/CollisionShape2D.disabled  = false
	$SelectionDetector.position = (area[0] + area[1]) * 0.5
	$SelectionDetector/CollisionShape2D.shape.size.x = abs(area[0].x - area[1].x)
	$SelectionDetector/CollisionShape2D.shape.size.y = abs(area[0].y - area[1].y)
	$SelectionTimer.start()

func _on_selection_detector_area_entered(area):
	if isSelecting:
		var unit = area.get_parent()
		unit.set_selected(true)
		selectedUnits.append(unit)
		print(selectedUnits)
		#TODO: Should select according to z_index ordering
		var boxShape = abs(selectionStart - selectionEnd)
		if boxShape.x + boxShape.y < SELECTION_BOX_MINIMUM_SIZE:
			isSelecting = false
			$SelectionDetector/CollisionShape2D.disabled  = true

func draw_selection_box(s=true):
	$Panel.size = Vector2(abs(selectionStart.x - selectionEnd.x), abs(selectionStart.y - selectionEnd.y))
	var pos = Vector2()
	pos.x = min(selectionStart.x, selectionEnd.x)
	pos.y = min(selectionStart.y, selectionEnd.y)
	$Panel.position = pos
	$Panel.size *= int(s)




## Backup script for PlayerInput

#@export var direction := Vector2()
#
#func _ready():
#	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())
#	set_multiplayer_authority($"..".playerId)
##	print("Processing for player %s." % $"..".playerId)
#
#func _process(delta):
##	$"..".playerId = multiplayer.get_unique_id()
#	# Get the input direction and handle the movement/deceleration.
#	# As good practice, you should replace UI actions with custom gameplay actions.
#	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
#	if(direction):
#		print($"..".playerId, "   ", direction)



extends Node

const SELECTION_BOX_MINIMUM_SIZE = 5

var allUnits = []
var selectedUnits = []
var isDraggingMouse = false
var isSelecting = false
var selectionStart = Vector2()
var selectionEnd = Vector2()

func _ready():
	allUnits = get_tree().get_nodes_in_group("units")

func area_selected(start, end):
	var area = []
	area.append(Vector2(min(start.x, end.x), min(start.y, end.y)))
	area.append(Vector2(max(start.x, end.x), max(start.y, end.y)))
	set_selection_area(area)

func _input(event):
	event.is_action_pressed("mouse_left_click")
	if event.is_action_pressed("mouse_left_click"):
		selectionStart = $Dungeon.get_global_mouse_position()
		isDraggingMouse = true	
		$Panel.visible = true
	if isDraggingMouse:
		selectionEnd = $Dungeon.get_global_mouse_position()
	if event.is_action_released("mouse_left_click"):
		selectionEnd = $Dungeon.get_global_mouse_position()
		isDraggingMouse = false
		$Panel.visible = false
		area_selected(selectionStart, selectionEnd)

func _process(delta):
	if isDraggingMouse:
		draw_selection_box()

func _physics_process(delta):
	var players = $Multiplayer/Players.get_children()
	var units = $Dungeon/Units.get_children()
	for player in players:
		for unit in units:
			print("player %s,  unit %s,  direction %s" % [player.name, unit.playerId, player.direction])
			if player.name.to_int() == unit.playerId:
				unit.position += player.direction * delta * unit.SPEED
				if player.isCloning:
					unit.position.x -= 75
		player.isCloning = false

func _on_selection_timer_timeout():
	isSelecting = false
	$SelectionDetector/CollisionShape2D.disabled  = true

func set_selection_area(area):
	allUnits = get_tree().get_nodes_in_group("units")
	for unit in allUnits:
		unit.set_selected(false)
	isSelecting = true
	$SelectionDetector/CollisionShape2D.disabled  = false
	$SelectionDetector.position = (area[0] + area[1]) * 0.5
	$SelectionDetector/CollisionShape2D.shape.size.x = abs(area[0].x - area[1].x)
	$SelectionDetector/CollisionShape2D.shape.size.y = abs(area[0].y - area[1].y)
	$SelectionTimer.start()

func _on_selection_detector_area_entered(area):
	if isSelecting:
		area.get_parent().set_selected(true)
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

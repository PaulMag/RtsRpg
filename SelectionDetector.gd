extends Area2D

class_name SelectionDetector


@onready var player: Player = $"../.."
@onready var playerInput: PlayerInput = $".."
@onready var selectionPanel: Panel = $"../../Panel"
@onready var selectionDetector: Area2D = $"."
@onready var selectionDetectorCollision: CollisionShape2D = $CollisionShape2D
@onready var targetDetector: Area2D = $"../TargetDetector"
@onready var targetDetectorCollision: CollisionShape2D = $"../TargetDetector/CollisionShape2D"

const SELECTION_BOX_MINIMUM_SIZE := 5


var isDraggingMouse := false
var isSelecting := false
var isTargeting := false
var selectionAreaStart: Vector2
var selectionAreaEnd: Vector2


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_left_click"):
		selectionAreaStart = selectionPanel.get_global_mouse_position()
		isDraggingMouse = true
		selectionPanel.visible = true
	if isDraggingMouse:
		selectionAreaEnd = selectionPanel.get_global_mouse_position()
	if event.is_action_released("mouse_left_click"):
		selectionAreaEnd = selectionPanel.get_global_mouse_position()
		isDraggingMouse = false
		selectionPanel.visible = false
		area_selected(selectionAreaStart, selectionAreaEnd)

	if event.is_action_pressed("mouse_right_click"):
		var targetPosition = get_global_mouse_position()
		set_target_area(targetPosition)

func _process(delta: float) -> void:
	if isDraggingMouse:
		draw_selection_box()

func _physics_process(delta) -> void:
	if isSelecting == true:
		var areas = selectionDetector.get_overlapping_areas()
		if areas:
			var unitsInSelectionDetector: Array[Unit] = []
			for area in areas:
				var unit = area.get_parent() as Unit
				if unit is Unit:
					unitsInSelectionDetector.append(unit)
			isSelecting = false
			selectionDetectorCollision.disabled = true
			selectUnit(unitsInSelectionDetector)
	if isTargeting == true:
		var areas = targetDetector.get_overlapping_areas()
		if areas:
			var unitsInTargetDetector: Array[Unit] = []
			for area in areas:
				var unit = area.get_parent() as Unit
				if unit is Unit:
					unitsInTargetDetector.append(unit)
			isTargeting = false
			targetDetectorCollision.disabled = true
			targetUnit(unitsInTargetDetector)

func draw_selection_box(s:=true) -> void:
	selectionPanel.size = Vector2(abs(selectionAreaStart.x - selectionAreaEnd.x), abs(selectionAreaStart.y - selectionAreaEnd.y))
	var pos = Vector2()
	pos.x = min(selectionAreaStart.x, selectionAreaEnd.x)
	pos.y = min(selectionAreaStart.y, selectionAreaEnd.y)
	selectionPanel.position = pos
	selectionPanel.size *= int(s)

func area_selected(start: Vector2, end: Vector2) -> void:
	var area = []
	area.append(Vector2(min(start.x, end.x), min(start.y, end.y)))
	area.append(Vector2(max(start.x, end.x), max(start.y, end.y)))
	set_selection_area(area)

func set_selection_area(area) -> void:
	isSelecting = true
	selectionDetectorCollision.disabled  = false
	selectionDetector.position = (area[0] + area[1]) * 0.5
	selectionDetectorCollision.shape.size.x = abs(area[0].x - area[1].x)
	selectionDetectorCollision.shape.size.y = abs(area[0].y - area[1].y)
	$"../../SelectionTimer".start()
	playerInput.selectUnit(null)

func _on_selection_timer_timeout() -> void:
	isSelecting = false
	selectionDetectorCollision.disabled  = true

func selectUnit(unitsInSelectionDetector: Array[Unit]) -> void:
	var maxY := 1e9
	var unit: Unit
	for u in unitsInSelectionDetector:
		if u in player.getUnits() and (unit == null or u.position.y > unit.position.y):
			maxY = u.position.y
			unit = u
	if (unit == null) or (not unit in player.getUnits()):
		return
	playerInput.selectUnit(unit)

func set_target_area(targetPosition: Vector2) -> void:
	isTargeting = true
	targetDetectorCollision.disabled  = false
	targetDetector.position = targetPosition

func _on_target_timer_timeout():
	isTargeting = false
	targetDetectorCollision.disabled = true

func targetUnit(unitsInSelectionDetector: Array[Unit]) -> void:
	var maxY := 1e9
	var unit: Unit
	for u in unitsInSelectionDetector:
		if (unit == null or u.position.y > unit.position.y):
			maxY = u.position.y
			unit = u
	if unit != null:
		playerInput.targetUnit(unit)

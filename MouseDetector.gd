extends ShapeCast2D

class_name MouseDetector


@onready var player: Player = $"../.."
@onready var playerInput: PlayerInput = $".."
@onready var selectionPanel: Panel = $"../SelectionPanel"

var isDraggingMouse := false
var selectionAreaStart: Vector2
var selectionAreaEnd: Vector2


func _process(delta: float) -> void:
	if isDraggingMouse:
		selectionAreaEnd = get_global_mouse_position()
		draw_selection_box()

func startMouseSelection() -> void:
	selectionAreaStart = get_global_mouse_position()
	isDraggingMouse = true
	selectionPanel.visible = true

func finishMouseSelection() -> void:
	selectionAreaEnd = get_global_mouse_position()
	isDraggingMouse = false
	selectionPanel.visible = false
	selectArea(selectionAreaStart, selectionAreaEnd)

func draw_selection_box(s:=true) -> void:
	selectionPanel.size = Vector2(abs(selectionAreaStart.x - selectionAreaEnd.x), abs(selectionAreaStart.y - selectionAreaEnd.y))
	var pos = Vector2()
	pos.x = min(selectionAreaStart.x, selectionAreaEnd.x)
	pos.y = min(selectionAreaStart.y, selectionAreaEnd.y)
	selectionPanel.position = pos
	selectionPanel.size *= int(s)

func selectArea(start: Vector2, end: Vector2) -> void:
	var cornerA = Vector2(min(start.x, end.x), min(start.y, end.y))
	var cornerB = Vector2(max(start.x, end.x), max(start.y, end.y))

	var center: Vector2 = (cornerA + cornerB) * 0.5
	var shape := Vector2(
		abs(cornerA.x - cornerB.x),
		abs(cornerA.y - cornerB.y),
	)

	var unitsInDetector = getUnitsInDetector(center, shape)
	var selectedUnit = pickSelectedUnit(unitsInDetector)
	playerInput.selectUnit(selectedUnit)

func targetMousePoint() -> void:
	var point := get_global_mouse_position()
	var unitsInDetector = getUnitsInDetector(point)
	var targetedUnit = pickTargetedUnit(unitsInDetector)

	if targetedUnit:
		playerInput.targetUnit(targetedUnit)
	else:
		playerInput.moveTo(point)

func getUnitsInDetector(pos: Vector2, size := Vector2.ONE) -> Array[Unit]:
	position = pos
	shape.size = size
	force_shapecast_update()
	var unitsInDetector: Array[Unit] = []
	for i in range(get_collision_count()):
		var unit = get_collider(i).get_parent() as Unit
		if unit is Unit:
			unitsInDetector.append(unit)
	return unitsInDetector

func pickSelectedUnit(unitsInSelectionDetector: Array[Unit]) -> Unit:
	var maxY := 1e9
	var unit: Unit
	for u in unitsInSelectionDetector:
		if u in player.getUnits() and (unit == null or u.position.y > unit.position.y):
			maxY = u.position.y
			unit = u
	if (unit == null) or (not unit in player.getUnits()):
		return null
	else:
		return unit

func pickTargetedUnit(unitsInSelectionDetector: Array[Unit]) -> Unit:
	var maxY := 1e9
	var unit: Unit = null
	for u in unitsInSelectionDetector:
		if (unit == null or u.position.y > unit.position.y):
			maxY = u.position.y
			unit = u
	return unit

extends ShapeCast2D

class_name MouseDetector


@onready var playerInput: LocalPlayer = $".."
@onready var selectionPanel: Panel = $"../SelectionPanel"

var isDraggingMouse := false
var selectionAreaStart: Vector2
var selectionAreaEnd: Vector2


func targetMousePoint(moveTo: bool) -> void:
	var point := get_global_mouse_position()
	var unitsInDetector := getUnitsInDetector(point)
	var targetedUnit := pickTargetedUnit(unitsInDetector)

	if targetedUnit:
		playerInput.setTargetUnit(targetedUnit, moveTo)
	elif moveTo:
		playerInput.moveTo(point)

func getUnitsInDetector(pos: Vector2, size := Vector2.ONE) -> Array[Unit]:
	position = pos
	var rectangleShape: RectangleShape2D = shape
	rectangleShape.size = size
	force_shapecast_update()
	var unitsInDetector: Array[Unit] = []
	for i in range(get_collision_count()):
		var collidingShape: Area2D = get_collider(i)
		var unit := collidingShape.get_parent() as Unit
		if unit is Unit:
			unitsInDetector.append(unit)
	return unitsInDetector

func pickSelectedUnit(unitsInSelectionDetector: Array[Unit]) -> Unit:
	var unit: Unit = null
	for u in unitsInSelectionDetector:
		if u.faction == Global.Faction.PLAYERS and (unit == null or u.position.y > unit.position.y):
			unit = u
	if (unit == null) or (not unit.faction == Global.Faction.PLAYERS):
		return null
	else:
		return unit

func pickTargetedUnit(unitsInSelectionDetector: Array[Unit]) -> Unit:
	var unit: Unit = null
	for u in unitsInSelectionDetector:
		if (unit == null or u.position.y > unit.position.y):
			unit = u
	return unit

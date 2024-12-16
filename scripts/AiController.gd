extends Node

class_name AiController


@onready var unit: Unit = $".."

var flag := false


func _process(_delta: float) -> void:
	if not unit.targetUnit:
		return
	if not unit.getEquippedWeapon():
		unit.orderMove(unit.targetUnit.position)
	elif unit.position.distance_to(unit.targetUnit.position) < unit.getEquippedWeapon().attackRange:
		unit.orderMove(unit.position)  # Stop moving
	elif unit.position.distance_to(unit.targetUnit.position) > unit.getEquippedWeapon().attackRange:
		unit.orderMove(unit.targetUnit.position)

func recalculateTarget() -> void:
	unit.targetUnit = getMostThreateningUnit()

func getMostThreateningUnit() -> Unit:
	var mostThreateningUnit: Unit = null
	var highestThreat := -1
	var threatTable := unit.threatTable.keys()
	for u: Unit in threatTable:
		if not is_instance_valid(u):
			unit.threatTable.erase(u)  # Remove dead units from threat list.
		elif unit.threatTable[u] > highestThreat:
			mostThreateningUnit = u
			highestThreat = unit.threatTable[u]
	return mostThreateningUnit

func getClosestUnit() -> Unit:
	var units := getAllEnemyUnits()
	var minDistance := 1e9
	var closestUnit: Unit
	for u in units:
		var distance := u.position.distance_to(unit.position)
		if distance < minDistance:
			minDistance = distance
			closestUnit = u
	return closestUnit

func getAllEnemyUnits() -> Array[Unit]:
	var units: Array[Unit] = []
	for u in Global.getAllUnits():
		if u.faction != unit.faction:
			units.append(u)
	return units

func _on_range_field_body_entered(body: Object) -> void:
	if body is Unit:
		var u := body as Unit
		if u.faction != unit.faction:
			if not u in unit.threatTable:
				unit.threatTable[u] = 0
				recalculateTarget()

extends Node


@onready var unit: Unit = $".."

var flag = false


func _process(delta):
	unit.targetUnit = getClosestUnit()
	if not unit.getEquippedWeapon():
		unit.move_to(unit.targetUnit.position)
	elif unit.position.distance_to(unit.targetUnit.position) < unit.getEquippedWeapon().range:
		unit.move_to(unit.position)  # Stop moving
	elif unit.position.distance_to(unit.targetUnit.position) > unit.getEquippedWeapon().range:
		unit.move_to(unit.targetUnit.position)

func getClosestUnit() -> Unit:
	var units = getAllUnitsExceptSelf()
	var minDistance := 1e9
	var closestUnit: Unit
	for unit in units:
		var distance = unit.position.distance_to(self.unit.position)
		if distance < minDistance:
			minDistance = distance
			closestUnit = unit
	return closestUnit

func getAllUnitsExceptSelf() -> Array[Unit]:
	var units: Array[Unit] = []
	for unit in getAllUnits():
		if unit != self.unit:
			units.append(unit)
	return units

func getAllUnits() -> Array[Unit]:
	var allNodes = get_tree().get_nodes_in_group("units")
	var allUnits: Array[Unit] = []
	for node in allNodes:
		if node is Unit:
			allUnits.append(node as Unit)
	return allUnits

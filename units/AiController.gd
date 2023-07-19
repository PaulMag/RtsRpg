extends Node


@onready var unit: Unit = $".."

var flag = false


func _process(delta):
	unit.targetUnit = getClosestUnit()
	if not unit.targetUnit:
		return
	if not unit.getEquippedWeapon():
		unit.move_to(unit.targetUnit.position)
	elif unit.position.distance_to(unit.targetUnit.position) < unit.getEquippedWeapon().range:
		unit.move_to(unit.position)  # Stop moving
	elif unit.position.distance_to(unit.targetUnit.position) > unit.getEquippedWeapon().range:
		unit.move_to(unit.targetUnit.position)

func getClosestUnit() -> Unit:
	var units = getAllEnemyUnits()
	var minDistance := 1e9
	var closestUnit: Unit
	for unit in units:
		var distance = unit.position.distance_to(self.unit.position)
		if distance < minDistance:
			minDistance = distance
			closestUnit = unit
	return closestUnit

func getAllEnemyUnits() -> Array[Unit]:
	var units: Array[Unit] = []
	for unit in Global.getAllUnits():
		if unit.faction != self.unit.faction:
			units.append(unit)
	return units

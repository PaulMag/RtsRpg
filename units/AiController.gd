extends Node


@onready var unit: Unit = $".."

var flag = false


func _process(delta):
	unit.targetUnit = getMostHatedUnit()
	if not unit.targetUnit:
		return
	if not unit.getEquippedWeapon():
		unit.orderMove(unit.targetUnit.position)
	elif unit.position.distance_to(unit.targetUnit.position) < unit.getEquippedWeapon().range:
		unit.orderMove(unit.position)  # Stop moving
	elif unit.position.distance_to(unit.targetUnit.position) > unit.getEquippedWeapon().range:
		unit.orderMove(unit.targetUnit.position)

func getMostHatedUnit() -> Unit:
	var mostHatedUnit: Unit = null
	var highestHate := -1
	var hatedUnits = unit.hatedUnits.keys()
	for u in hatedUnits:
		if not is_instance_valid(u):
			unit.hatedUnits.erase(u)  # Remove dead units from hate list.
		elif unit.hatedUnits[u] > highestHate:
			mostHatedUnit = u
			highestHate = unit.hatedUnits[u]
	return mostHatedUnit

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

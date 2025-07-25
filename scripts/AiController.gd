extends Area3D
class_name AiController


@export var unit: Unit

# Which abilities the AI will use, in prioritized order.
var abilityIdsPrioritized: Array[Global.AbilityIds] = []


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	if not multiplayer.is_server():
		return

	if unit.targetUnit:
		unit.followTarget = unit.position.distance_to(unit.targetUnit.position) > Global.getAbility[abilityIdsPrioritized[0]].targetRange
		if not unit.followTarget:
			var target_pos := unit.targetUnit.position
			target_pos.y = unit.position.y  # Ignore vertical difference
			unit.look_at(target_pos, Vector3.UP)
			unit.rotate_y(PI)  # Mesh is rotated the wrong way.

	# Use the first viable ability
	if unit.targetUnit and not unit.isCasting and not unit.isRecovering:
		for abilityId in abilityIdsPrioritized:
			if unit.canUseAbility(abilityId):
				unit.useAbilityOnServer(abilityId)
				return


func recalculateTarget() -> void:
	if not multiplayer.is_server():
		return
	unit.orderFollowUnit(getMostThreateningUnit())
	alertAllies()


func getMostThreateningUnit() -> Unit:
	var mostThreateningUnit: Unit = null
	var highestThreat := -1.0
	var threatTable := unit.threatTable.keys()
	for u: Unit in threatTable:
		if not is_instance_valid(u):
			unit.threatTable.erase(u)  # Remove dead units from threat list.
		elif unit.threatTable[u] > highestThreat:
			mostThreateningUnit = u
			highestThreat = unit.threatTable[u]
	return mostThreateningUnit


func alertAllies() -> void:
	for body in get_overlapping_bodies():
		if body is Unit:
			var nearbyAlliedUnit := body as Unit
			if nearbyAlliedUnit.aiController and nearbyAlliedUnit.faction == unit.faction:
				for u in unit.threatTable.keys() as Array[Unit]:
					if not u in nearbyAlliedUnit.threatTable:
						print("%s alerts %s about unit %s" % [unit.unitName, nearbyAlliedUnit.unitName, u.unitName])
						nearbyAlliedUnit.threatTable[u] = 0
						nearbyAlliedUnit.aiController.recalculateTarget()


func _on_body_entered(body: Node3D) -> void:
	if not multiplayer.is_server():
		return
	if body is Unit:
		var u := body as Unit
		if u.faction != unit.faction:
			if not u in unit.threatTable:
				print("%s is aware of unit %s" % [unit.unitName, u.unitName])
				unit.threatTable[u] = 0
				recalculateTarget()

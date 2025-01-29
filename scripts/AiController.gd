extends Node

class_name AiController


@export var unit: Unit

# Which abilities the AI will use, in prioritized order.
var abilityIdsPrioritized: Array[Global.AbilityIds] = [Global.AbilityIds.MeleeAttack, Global.AbilityIds.Fireball]


func _process(_delta: float) -> void:
	if not multiplayer.is_server():
		return

	# Use the first viable ability
	if unit.targetUnit and not unit.isRecovering:
		for abilityId in abilityIdsPrioritized:
			if unit.canUseAbility(abilityId):
				unit.useAbilityOnClients(abilityId)
				return

func recalculateTarget() -> void:
	unit.orderFollowUnit(getMostThreateningUnit())

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

func _on_range_field_body_entered(body: Object) -> void:
	if body is Unit:
		var u := body as Unit
		if u.faction != unit.faction:
			if not u in unit.threatTable:
				unit.threatTable[u] = 0
				recalculateTarget()

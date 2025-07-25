extends AiController
class_name AiControllerArcher


func _ready() -> void:
	abilityIdsPrioritized = [Global.AbilityIds.RangedAttack]


func _process(_delta: float) -> void:
	if not multiplayer.is_server():
		return

	unit.followTarget = false
	unit.followCursor = true

	if unit.targetUnit:
		var selfPos := Global.vec3_to_vec2(unit.position)
		var targetPos := Global.vec3_to_vec2(unit.targetUnit.position)
		var direction := targetPos.direction_to(selfPos)

		var intendedPosition := Global.vec2_to_vec3(targetPos + direction * Global.getAbility[abilityIdsPrioritized[0]].targetRange * 0.95)
		var closest_point := NavigationServer3D.map_get_closest_point(unit.navigationAgent.get_navigation_map(), intendedPosition)

		unit.destination = closest_point

		if unit.isCasting:
			unit.look_at(unit.targetUnit.position, Vector3.UP)
			unit.rotate_y(PI)  # Mesh is rotated the wrong way.

	# Use the first viable ability
	if unit.targetUnit and not unit.isCasting and not unit.isRecovering:
		for abilityId in abilityIdsPrioritized:
			if unit.canUseAbility(abilityId):
				unit.useAbilityOnServer(abilityId)
				return

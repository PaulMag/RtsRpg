extends Node

func _physics_process(delta):
	var players = $Multiplayer/Players.get_children() as Array[Player]
	var units = $Dungeon/Units.get_children() as Array[Unit]
	for player in players:
		if player.isIssuingMoveOrder:
			for unitId in player.selectedUnitIds:
				var unit = instance_from_id(unitId)
				if unit.playerId == player.playerId:
					unit.move_to(player.destination)
					if player.targetedUnitId != 0:
						unit.targetUnit = instance_from_id(player.targetedUnitId)
			player.isIssuingMoveOrder = false

		if player.isIssuingAttackOrder:
			for unitId in player.selectedUnitIds:
				var unit = instance_from_id(unitId)
				unit.attack()
			player.isIssuingAttackOrder = false

		if player.isIssuingEquipOrder != 0:
			for unitId in player.selectedUnitIds:
				var unit: Unit = instance_from_id(unitId) as Unit
				unit.equip(player.isIssuingEquipOrder)
			player.isIssuingEquipOrder = 0

		for unit in units:
			if player.name.to_int() == unit.playerId:
				unit.position += player.direction * delta * unit.SPEED
				if player.isCloning:
					unit.position.x -= 75
		player.isCloning = false

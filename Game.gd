extends Node

func _physics_process(delta):
	var players = $Multiplayer/Players.get_children()
	var units = $Dungeon/Units.get_children()
	for player in players:
		if player.isIssuingMoveOrder:
			for unitId in player.selectedUnitIds:
				var unit = instance_from_id(unitId)
				if unit.playerId == player.playerId:
					unit.move_to(player.destination)
			player.isIssuingMoveOrder = false
		for unit in units:
			if player.name.to_int() == unit.playerId:
				unit.position += player.direction * delta * unit.SPEED
				if player.isCloning:
					unit.position.x -= 75
		player.isCloning = false

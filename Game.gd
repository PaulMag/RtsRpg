extends Node

func _physics_process(delta):
	var players = $Multiplayer/Players.get_children()
	var units = $Dungeon/Units.get_children()
	for player in players:
		for unit in units:
#			print("player %s,  unit %s,  direction %s" % [player.name, unit.playerId, player.direction])
			if player.name.to_int() == unit.playerId:
				unit.position += player.direction * delta * unit.SPEED
				if player.isCloning:
					unit.position.x -= 75
		player.isCloning = false

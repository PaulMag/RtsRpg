extends Node


enum Faction {
	PLAYERS,
	ENEMIES,
}


func getPlayers() -> Array[Player]:
	var players: Array[Player] = []
	for player in get_tree().get_nodes_in_group("players"):
		players.append(player as Player)
	return players

# This returns the Player that represents the current Peer.
func getPlayerCurrent() -> Player:
	for player in getPlayers():
		if player.playerId == multiplayer.get_unique_id():
			return player
	return null

func getAllUnits(faction = null) -> Array[Unit]:
	var units: Array[Unit] = []
	for unit in get_tree().get_nodes_in_group("units"):
		if (faction == null) or unit.faction == faction:
			units.append(unit as Unit)
	return units

func getAllUnitsNotFaction(faction) -> Array[Unit]:
	var units: Array[Unit] = []
	for unit in get_tree().get_nodes_in_group("units"):
		if unit.faction != faction:
			units.append(unit as Unit)
	return units

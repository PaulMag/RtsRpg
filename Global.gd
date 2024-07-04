extends Node


enum Faction {
	PLAYERS,
	ENEMIES,
}


func getPlayers() -> Array[ServerPlayer]:
	var players: Array[ServerPlayer] = []
	for player in get_tree().get_nodes_in_group("players"):
		players.append(player as ServerPlayer)
	return players

# This returns the Player that represents the current Peer.
func getPlayerCurrent() -> ServerPlayer:
	for player in getPlayers():
		if player.playerId == multiplayer.get_unique_id():
			return player
	return null

func getAllUnits() -> Array[Unit]:
	var units: Array[Unit] = []
	for unit in get_tree().get_nodes_in_group("units"):
		units.append(unit as Unit)
	return units

func getAllUnitsInFaction(faction: Faction) -> Array[Unit]:
	var units: Array[Unit] = []
	for unit in get_tree().get_nodes_in_group("units") as Array[Unit]:
		if unit.faction == faction:
			units.append(unit as Unit)
	return units

func getAllUnitsNotFaction(faction: Faction) -> Array[Unit]:
	var units: Array[Unit] = []
	for unit in get_tree().get_nodes_in_group("units") as Array[Unit]:
		if unit.faction != faction:
			units.append(unit as Unit)
	return units

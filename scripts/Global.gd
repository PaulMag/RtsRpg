extends Node


enum Faction {
	PLAYERS,
	ENEMIES,
}


func getPlayers() -> Array[LocalPlayer]:
	var players: Array[LocalPlayer] = []
	for player in get_tree().get_nodes_in_group("players"):
		players.append(player as LocalPlayer)
	return players

# This returns the Player that represents the current Peer.
func getPlayerCurrent() -> LocalPlayer:
	for player in getPlayers():
		if player.playerId == multiplayer.get_unique_id():
			return player
	return null

func getAllUnits() -> Array[Unit]:
	var units: Array[Unit] = []
	for unit in get_tree().get_nodes_in_group("units"):
		units.append(unit as Unit)
	return units

func getUnitFromUnitId(unitId: int) -> Unit:
	for unit in Global.getAllUnits():
		if unit.unitId == unitId:
			return unit
	return null

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

func deleteUnit(unit: Unit) -> void:
	if unit == getPlayerCurrent().getSelectedUnit():
		getPlayerCurrent().selectUnit(null)
	for u in getAllUnits():
		if unit in u.threatTable:
			u.threatTable.erase(unit)
	unit.queue_free()

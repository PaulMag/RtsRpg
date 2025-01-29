extends Node


enum Faction {
	PLAYERS,
	ENEMIES,
}

enum Items {
	Bow,
	HealingStaff,
	Sword,
}

# AbilityIds and getAbility array MUST be in the same order
enum AbilityIds {
	MeleeAttack,
	Fireball,
	HealingWord,
}
var getAbility: Array[Ability] = [
	load("res://resources/abilities/MeleeAttack.tres"),
	load("res://resources/abilities/Fireball.tres"),
	load("res://resources/abilities/HealingWord.tres"),
]


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
		if u.targetUnit == unit:
			u.targetUnit = null
			if u.isAi:
				u.aiController.recalculateTarget()
	unit.queue_free()

	var timer := get_tree().create_timer(0.2)
	timer.connect("timeout", getPlayerCurrent().updateUnitList)  #TODO Temporary ugly way to remove from UnitList

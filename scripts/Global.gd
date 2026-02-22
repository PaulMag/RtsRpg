extends Node


enum Faction {
	PLAYERS,
	ENEMIES,
}

enum Items {
	NONE,
	dagger,
	sword_short,
	sword_long,
	crossbow_light,
	crossbow_heavy,
	staff_healing,
	wand_fire,
	cuirass_iron,
	robe_mage,
	tunic_leather,
	helmet_iron,
	hat_pointy,
	hat_bear,
	shield_round,
	shield_kite,
	shield_kite_spiked,
	shield_tower,
	spellbook,
}

enum ItemSlots {
	None, # For items that don't fit in a slot
	MainHand,
	OffHand,
	Head,
	Torso,
}

# AbilityIds and getAbility array MUST be in the same order
enum AbilityIds {
	MeleeAttack,
	Fireball,
	HealingWord,
	Taunt,
	Slow,
	RangedAttack,
	Haste,
	Prowess,
	CureWounds,
	Revive,
	Firebolt,
	FireAura,
	FireAuraEffect,
}
var getAbility: Array[Ability] = [
	load("res://resources/abilities/MeleeAttack.tres"),
	load("res://resources/abilities/Fireball.tres"),
	load("res://resources/abilities/HealingWord.tres"),
	load("res://resources/abilities/Taunt.tres"),
	load("res://resources/abilities/Slow.tres"),
	load("res://resources/abilities/RangedAttack.tres"),
	load("res://resources/abilities/Haste.tres"),
	load("res://resources/abilities/Prowess.tres"),
	load("res://resources/abilities/CureWounds.tres"),
	load("res://resources/abilities/Revive.tres"),
	load("res://resources/abilities/Firebolt.tres"),
	load("res://resources/abilities/FireAura.tres"),
	load("res://resources/abilities/FireAuraEffect.tres"),
]


var cameraArm: Node3D
var dungeon: Dungeon


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
			if u.aiController:
				u.aiController.recalculateTarget()
	unit.queue_free()

	var timer := get_tree().create_timer(0.2)
	timer.connect("timeout", getPlayerCurrent().updateUnitList)  #TODO Temporary ugly way to remove from UnitList


func vec3_to_vec2(vector3: Vector3) -> Vector2:
	return Vector2(vector3.x, vector3.z)

func vec2_to_vec3(vector2: Vector2, y: float = 0.0) -> Vector3:
	return Vector3(vector2.x, y, vector2.y)

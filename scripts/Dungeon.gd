class_name Dungeon
extends Node3D

const SCENE := preload("res://scenes/Dungeon.tscn")

var xpStart: float = 1.0
var xpRewardMultiplier: float = 1.0
var enemyStartMultiplier: float = 1.0
var enemyLevelMultiplier: float = 1.0

var remainingLoot: Array[Item.Id] = []


static func init() -> Dungeon:
	var scene := SCENE.instantiate() as Dungeon
	Global.dungeon = scene
	return scene


func _ready() -> void:
	if multiplayer.is_server():
		await get_tree().create_timer(1.0).timeout # TODO: This is very ugly, but it works for now
		distributeTalentPoints(xpStart)


func distributeTalentPoints(amount: float) -> void:
	var numberOfPlayers := Global.getPlayers().size()
	var playerUnits := Global.getAllUnitsInFaction(Global.Faction.PLAYERS)

	for unit in playerUnits:
		unit.giveTalentPointsOnServer(amount / numberOfPlayers)


func getNextLoot() -> Item.Id:
	if remainingLoot.is_empty():
		for item in range(1, Item.Id.values().size()):
			remainingLoot.append(item)
		remainingLoot.shuffle()
	return remainingLoot.pop_back()

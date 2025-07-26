extends Node3D
class_name Dungeon


var remainingLoot: Array[Global.Items] = []


const SCENE := preload("res://scenes/Dungeon.tscn")
static func init() -> Dungeon:
	var scene := SCENE.instantiate() as Dungeon
	Global.dungeon = scene
	return scene


func getNextLoot() -> Global.Items:
	if remainingLoot.is_empty():
		for item in range(1, Global.Items.values().size()):
			remainingLoot.append(item)
		remainingLoot.shuffle()
	return remainingLoot.pop_back()

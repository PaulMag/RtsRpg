extends Node3D
class_name Dungeon


const SCENE := preload("res://scenes/Dungeon.tscn")
static func init() -> Dungeon:
	var scene := SCENE.instantiate() as Dungeon
	return scene

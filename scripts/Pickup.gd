extends Area2D

class_name Pickup


@export var itemType: int
var itemResource: Item
@onready var sprite: Sprite2D = $Sprite2D

const SCENE := preload("res://scenes/Pickup.tscn")
static func init(_itemType: Global.Items) -> Pickup:
	var scene := SCENE.instantiate() as Pickup
	scene.itemType = _itemType
	return scene

func _ready() -> void:
	itemResource = load("res://resources/items/%s.tres" % Global.Items.find_key(itemType))
	sprite.texture = itemResource.texture

func _on_body_entered(body: Node2D) -> void:
	if body is Unit and multiplayer.is_server():
		var unit := body as Unit
		if unit.faction == Global.Faction.PLAYERS:
			if unit.giveItem(itemType):
				queue_free()

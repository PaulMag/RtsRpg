extends Area3D

class_name Pickup


@export var itemType: Global.Items
var itemResource: Item
@onready var meshInstance: MeshInstance3D = $MeshInstance

const SCENE := preload("res://scenes/Pickup.tscn")
static func init(_itemType: Global.Items) -> Pickup:
	var scene := SCENE.instantiate() as Pickup
	scene.itemType = _itemType
	return scene

func _ready() -> void:
	itemResource = load("res://resources/items/%s.tres" % Global.Items.find_key(itemType))
	meshInstance.mesh = itemResource.mesh
	var aabb := meshInstance.get_aabb()
	meshInstance.position = -aabb.get_center()
	meshInstance.position.y += aabb.size.y * 0.5



func _process(delta: float) -> void:
	rotation.y += delta * PI


func _on_body_entered(body: Node3D) -> void:
	if body is Unit and multiplayer.is_server():
		var unit := body as Unit
		if unit.faction == Global.Faction.PLAYERS:
			if unit.giveItem(itemType):
				queue_free()

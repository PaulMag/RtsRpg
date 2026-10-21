class_name Item
extends Resource

@export var itemType: Global.Items
@export var name: String
@export var texture: Texture2D
@export var mesh: Mesh
@export var slot: Global.ItemSlots
@export var attributes: Attributes
@export var position: Vector3
@export var rotation: Vector3


static func load(_itemType: Global.Items) -> Item:
	return load("res://resources/items/%s.tres" % Global.Items.find_key(_itemType))


func getDescription() -> String:
	var description := "  %s\n" % name
	if slot != Global.ItemSlots.None:
		description += "Slot:          %s\n" % Global.ItemSlots.find_key(slot)
	if attributes:
		description += attributes.getDescriptionNoZero()
	return description.trim_suffix("\n")

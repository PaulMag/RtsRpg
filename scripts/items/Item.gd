extends Resource

class_name Item

@export var itemType: Global.Items
@export var name: String
@export var texture: Texture2D
@export var mesh: Mesh
@export var slot: Global.ItemSlots
@export var attributes: Attributes
@export var position: Vector3
@export var rotation: Vector3


func getDescription() -> String:
	var description := "  %s\n" % name
	if slot != Global.ItemSlots.None:
		description += "Slot:          %s\n" % Global.ItemSlots.find_key(slot)
	if attributes:
		description += attributes.getDescriptionNoZero()
	return description.trim_suffix("\n")

class_name Item
extends Resource

enum Id {
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

enum Slot {
	NONE, # For items that don't fit in a slot
	MAIN_HAND,
	OFF_HAND,
	HEAD,
	TORSO,
}

@export var itemId: Item.Id
@export var name: String
@export var texture: Texture2D
@export var mesh: Mesh
@export var slot: Item.Slot
@export var attributes: Attributes
@export var position: Vector3
@export var rotation: Vector3


static func load(_itemId: Item.Id) -> Item:
	return load("res://resources/items/%s.tres" % Id.find_key(_itemId))


func getDescription() -> String:
	var description := "  %s\n" % name
	if slot != Item.Slot.NONE:
		description += "Slot:          %s\n" % Item.Slot.find_key(slot)
	if attributes:
		description += attributes.getDescriptionNoZero()
	return description.trim_suffix("\n")

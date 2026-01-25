extends Node3D

class_name CharacterModel

@export var defaultMeshes: Dictionary[Global.ItemSlots, Mesh]

@onready var animationPlayer: AnimationPlayer = $AnimationPlayer
@onready var itemMeshes: Dictionary[Global.ItemSlots, MeshInstance3D] = {
	Global.ItemSlots.MainHand: %RightHandItem,
	Global.ItemSlots.OffHand: %LeftHandItem,
	Global.ItemSlots.Head: %HeadItem,
	Global.ItemSlots.Torso: %Torso,
}


func equipItem(item: Item) -> void:
	if item.slot in itemMeshes:
		var meshInstance := itemMeshes[item.slot]
		meshInstance.mesh = item.mesh
		meshInstance.position = item.position
		meshInstance.rotation = item.rotation


func unEquipItemSlot(itemSlot: Global.ItemSlots) -> void:
	if itemSlot in itemMeshes:
		var meshInstance := itemMeshes[itemSlot]
		if itemSlot in defaultMeshes:
			meshInstance.mesh = defaultMeshes[itemSlot]
		else:
			meshInstance.mesh = null

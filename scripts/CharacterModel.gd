# @tool
extends Node3D

class_name CharacterModel

@export var defaultMeshes: Dictionary[Global.ItemSlots, Mesh]
@export var headMeshes: Array[Mesh]
@export var textures: Array[Texture2D]

@onready var animationPlayer: AnimationPlayer = $AnimationPlayer
@onready var itemMeshes: Dictionary[Global.ItemSlots, MeshInstance3D] = {
	Global.ItemSlots.MainHand: %RightHandItem,
	Global.ItemSlots.OffHand: %LeftHandItem,
	Global.ItemSlots.Head: %HeadItem,
	Global.ItemSlots.Torso: %Torso,
}
@onready var headMeshInstance: MeshInstance3D = %Head
@onready var meshInstances: Array[MeshInstance3D] = [
	%Torso,
	%ArmLeft,
	%ArmRight,
	%LegLeft,
	%LegRight,
	%BackItem,
	%HeadItem,
	%RightHandItem,
	%LeftHandItem,
]

var clothesMaterial: StandardMaterial3D


func _ready() -> void:
	headMeshInstance.mesh = headMeshes.pick_random()
	var material := StandardMaterial3D.new()
	material.albedo_texture = textures.pick_random()
	headMeshInstance.set_surface_override_material(0, material)

	clothesMaterial = StandardMaterial3D.new()
	clothesMaterial.albedo_texture = textures.pick_random()
	for meshInstance in meshInstances:
		meshInstance.set_surface_override_material(0, clothesMaterial)
	for meshInstance: MeshInstance3D in meshInstances.slice(6, 9):
		# These 3 only needed a mesh set to allow set_surface_override_material to work.
		meshInstance.mesh = null


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

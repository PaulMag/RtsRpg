class_name CharacterModel
# @tool
extends Node3D

@export var selectedHeadMeshId: int
@export var selectedHeadTextureId: int
@export var selectedClothesTextureId: int

@export var defaultMeshes: Dictionary[Item.Slot, Mesh]
@export var headMeshes: Array[Mesh]
@export var textures: Array[Texture2D]

var clothesMaterial: StandardMaterial3D

@onready var animationPlayer: AnimationPlayer = $AnimationPlayer
@onready var itemMeshes: Dictionary[Item.Slot, MeshInstance3D] = {
	Item.Slot.MAIN_HAND: %RightHandItem,
	Item.Slot.OFF_HAND: %LeftHandItem,
	Item.Slot.HEAD: %HeadItem,
	Item.Slot.TORSO: %Torso,
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


func _ready() -> void:
	if multiplayer.is_server():
		selectedHeadMeshId = randi_range(0, headMeshes.size() - 1)
		selectedHeadTextureId = randi_range(0, textures.size() - 1)
		selectedClothesTextureId = randi_range(0, textures.size() - 1)
		setAppearance()


func setAppearance() -> void:
	# Is called by signal from MultiplayerSynchronizer on peers
	headMeshInstance.mesh = headMeshes[selectedHeadMeshId]
	var material := StandardMaterial3D.new()
	material.albedo_texture = textures[selectedHeadTextureId]
	headMeshInstance.set_surface_override_material(0, material)

	clothesMaterial = StandardMaterial3D.new()
	clothesMaterial.albedo_texture = textures[selectedClothesTextureId]
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


func unEquipItemSlot(itemSlot: Item.Slot) -> void:
	if itemSlot in itemMeshes:
		var meshInstance := itemMeshes[itemSlot]
		if itemSlot in defaultMeshes:
			meshInstance.mesh = defaultMeshes[itemSlot]
		else:
			meshInstance.mesh = null

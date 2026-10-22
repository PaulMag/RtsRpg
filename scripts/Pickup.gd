class_name Pickup
extends Area3D

const SCENE := preload("res://scenes/Pickup.tscn")

@export var itemId: Item.Id

var itemResource: Item

@onready var meshInstance: MeshInstance3D = $MeshInstance
@onready var collisionShape: CollisionShape3D = $CollisionShape
@onready var descriptionPanel: PanelContainer = %DescriptionPanel
@onready var descriptionLabel: Label = %DescriptionLabel


static func init(_itemId: Item.Id) -> Pickup:
	var scene := SCENE.instantiate() as Pickup
	scene.itemId = _itemId
	return scene


func _ready() -> void:
	if itemId == Item.Id.NONE:
		queue_free()
		return

	itemResource = Item.load(itemId)
	meshInstance.mesh = itemResource.mesh

	var aabb := meshInstance.get_aabb()
	meshInstance.position = -aabb.get_center()
	meshInstance.position.y += aabb.size.y * 0.5

	var shape := collisionShape.shape as CylinderShape3D
	shape.radius = (aabb.size.x + aabb.size.z) * 0.5
	shape.height = aabb.size.y
	collisionShape.position.y = aabb.size.y * 0.5

	descriptionPanel.visible = false
	descriptionLabel.text = itemResource.getDescription()


func _process(delta: float) -> void:
	meshInstance.rotation.y += delta * PI


func _on_body_entered(body: Node3D) -> void:
	if body is Unit and multiplayer.is_server():
		var unit := body as Unit
		if unit.faction == Global.Faction.PLAYERS:
			if unit.giveItem(itemId):
				queue_free()


func _on_mouse_entered() -> void:
	descriptionPanel.visible = true


func _on_mouse_exited() -> void:
	descriptionPanel.visible = false

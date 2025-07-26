extends Area3D

class_name Pickup


@export var itemType: Global.Items
var itemResource: Item

@onready var meshInstance: MeshInstance3D = $MeshInstance
@onready var collisionShape: CollisionShape3D = $CollisionShape
@onready var descriptionPanel: PanelContainer = %DescriptionPanel
@onready var descriptionLabel: Label = %DescriptionLabel

const SCENE := preload("res://scenes/Pickup.tscn")
static func init(_itemType: Global.Items) -> Pickup:
	var scene := SCENE.instantiate() as Pickup
	scene.itemType = _itemType
	return scene


func _ready() -> void:
	if itemType == Global.Items.NONE:
		queue_free()
		return

	itemResource = load("res://resources/items/%s.tres" % Global.Items.find_key(itemType))
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
			if unit.giveItem(itemType):
				queue_free()


func _on_mouse_entered() -> void:
	descriptionPanel.visible = true

func _on_mouse_exited() -> void:
	descriptionPanel.visible = false

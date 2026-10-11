class_name ItemButton
extends TextureButton

signal drop_item

const SCENE := preload("res://scenes/ItemButton.tscn")

var item: Item
var nodeIndex: int

@onready var equippedBorder: Sprite2D = %EquippedBorder
@onready var descriptionPanel: PanelContainer = %DescriptionPanel
@onready var descriptionLabel: Label = %DescriptionLabel


static func init(_item: Item, _nodeIndex: int) -> ItemButton:
	var scene: ItemButton = SCENE.instantiate()
	scene.item = _item
	scene.nodeIndex = _nodeIndex
	scene.texture_normal = _item.texture
	return scene


func _ready() -> void:
	descriptionPanel.visible = false
	descriptionLabel.text = item.getDescription()


func setEquipped(toggledOn: bool) -> void:
	equippedBorder.visible = toggledOn


func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_released("mouse_right_click"):
		drop_item.emit()


func _on_mouse_entered() -> void:
	descriptionPanel.visible = true
	self_modulate = Color.LIGHT_GREEN


func _on_mouse_exited() -> void:
	descriptionPanel.visible = false
	self_modulate = Color.WHITE

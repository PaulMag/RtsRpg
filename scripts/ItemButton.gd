extends TextureButton
class_name ItemButton


@onready var equippedBorder: Sprite2D = %EquippedBorder
@onready var descriptionPanel: PanelContainer = %DescriptionPanel
@onready var descriptionLabel: Label = %DescriptionLabel

var item: Item
var nodeIndex: int

signal drop_item


const SCENE := preload("res://scenes/ItemButton.tscn")
static func init(_item: Item, _nodeIndex: int) -> ItemButton:
	var scene: ItemButton = SCENE.instantiate()
	scene.item = _item
	scene.nodeIndex = _nodeIndex
	scene.texture_normal = _item.texture
	return scene


func _ready() -> void:
	descriptionPanel.visible = false
	descriptionLabel.text = item.getDescription()


func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_released("mouse_right_click"):
		drop_item.emit()


func setEquipped(toggledOn: bool) -> void:
	equippedBorder.visible = toggledOn


func _on_mouse_entered() -> void:
	descriptionPanel.visible = true
	self_modulate = Color.LIGHT_GREEN

func _on_mouse_exited() -> void:
	descriptionPanel.visible = false
	self_modulate = Color.WHITE

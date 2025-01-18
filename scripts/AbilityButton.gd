extends TextureButton
class_name AbilityButton

@onready var cooldownProgressBar: TextureProgressBar = $CooldownProgressBar
@onready var autocastBorder: AnimatedSprite2D = $AutocastBorder

var ability: Ability
var nodeIndex: int

signal toggle_autocast


const SCENE := preload("res://scenes/AbilityButton.tscn")
static func init(_ability: Ability) -> AbilityButton:
	var scene: AbilityButton = SCENE.instantiate()
	scene.ability = _ability
	scene.texture_normal = _ability.texture
	return scene

func _ready() -> void:
	cooldownProgressBar.value = 0

func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_released("mouse_right_click"):
		toggle_autocast.emit()

func setAutocast(toggledOn: bool) -> void:
	autocastBorder.visible = toggledOn

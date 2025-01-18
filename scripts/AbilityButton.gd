extends TextureButton
class_name AbilityButton

@onready var cooldownProgressBar: TextureProgressBar = $CooldownProgressBar

var ability: Ability
var nodeIndex: int


const SCENE := preload("res://scenes/AbilityButton.tscn")
static func init(_ability: Ability, _nodeIndex: int) -> AbilityButton:
	var scene: AbilityButton = SCENE.instantiate()
	scene.ability = _ability
	scene.nodeIndex = _nodeIndex
	scene.texture_normal = _ability.texture
	return scene

func _ready() -> void:
	cooldownProgressBar.value = 0


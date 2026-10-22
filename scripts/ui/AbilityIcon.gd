class_name AbilityIcon
extends TextureRect

const SCENE := preload("res://scenes/ui/AbilityIcon.tscn")

var abilityId: Ability.Id


static func init(_abilityId: Ability.Id) -> AbilityIcon:
	var scene: AbilityIcon = SCENE.instantiate()
	scene.abilityId = _abilityId
	return scene


func _ready() -> void:
	texture = Ability.load(abilityId).texture

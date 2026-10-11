class_name AbilityIcon
extends TextureRect

const SCENE := preload("res://scenes/ui/AbilityIcon.tscn")

var abilityId: Global.AbilityIds


static func init(_abilityId: Global.AbilityIds) -> AbilityIcon:
	var scene: AbilityIcon = SCENE.instantiate()
	scene.abilityId = _abilityId
	return scene


func _ready() -> void:
	texture = Global.getAbility[abilityId].texture

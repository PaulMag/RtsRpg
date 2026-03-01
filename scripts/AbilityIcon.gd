extends TextureRect
class_name AbilityIcon


@export var abilityId: Global.AbilityIds


func _ready() -> void:
	texture = Global.getAbility[abilityId].texture

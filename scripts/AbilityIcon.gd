class_name AbilityIcon
extends TextureRect

@export var abilityId: Global.AbilityIds


func _ready() -> void:
	texture = Global.getAbility[abilityId].texture

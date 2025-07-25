extends AiController
class_name AiControllerMelee


func _ready() -> void:
	super._ready()

	abilityIdsPrioritized = [Global.AbilityIds.MeleeAttack]

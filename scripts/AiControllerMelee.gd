class_name AiControllerMelee
extends AiController


func _ready() -> void:
	super._ready()

	abilityIdsPrioritized = [Global.AbilityIds.MeleeAttack]

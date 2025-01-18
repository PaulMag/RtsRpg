extends Resource
class_name Ability

@export var name: String
@export var texture: Texture
@export var abilityId: Global.AbilityIds

@export var damage: int
@export var targetRange: int
@export var manaCost: int
@export var isHealing: bool = false

@export var recoveryTime: float = 1

@export var canTargetSelf: bool = false
@export var canTargetFriend: bool = false
@export var canTargetEnemy: bool = false

func use(user: Unit, target: Unit) -> bool:
	if target == null:
		return false
	if user == target and !canTargetSelf:
		return false
	if user.faction == target.faction and !canTargetFriend:
		return false
	if user.faction != target.faction and !canTargetEnemy:
		return false
	if user != target and user.position.distance_to(target.position) > targetRange:
		return false
	if user.mana < manaCost:
		return false

	user.mana -= manaCost

	var attack := Attack.new()
	attack.attackingUnit = user
	attack.damage = damage
	attack.isHealing = isHealing

	target.damage(attack)

	return true

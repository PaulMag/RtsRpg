extends Resource
class_name Ability

@export var name: String
@export var texture: Texture
@export var abilityId: Global.AbilityIds

@export var damagePhysical: int
@export var damageMagical: int
@export var healingAmount: int
@export var threatAmount: int
@export var targetRange: int
@export var manaCost: int
@export var isHealing: bool = false

@export var recoveryTime: float = 1

@export var projectileSpeed: float = 500
@export var projectileTexture: Texture

@export var canTargetSelf: bool = false
@export var canTargetFriend: bool = false
@export var canTargetEnemy: bool = false


func canUse(user: Unit, target: Unit) -> bool:
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
	return true

func use(user: Unit, target: Unit) -> bool:
	if !canUse(user, target):
		return false

	user.mana -= manaCost

	var attack := Attack.new()
	attack.attackingUnit = user
	attack.damagePhysical = damagePhysical * (1 + user.attributes.attackSkill * 0.01)
	attack.damageMagical = damageMagical * (1 + user.attributes.magicSkill * 0.01)
	attack.healingAmount = healingAmount * (1 + user.attributes.healSkill * 0.01)
	attack.threat = (attack.damagePhysical + attack.damageMagical + threatAmount) * (1 + user.attributes.threatSkill * 0.01)
	attack.isHealing = isHealing

	var newProjectile := Projectile.init(attack, target, projectileTexture, projectileSpeed)
	user.add_sibling(newProjectile, true)

	return true

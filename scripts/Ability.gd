@tool  # Necessary for TalentAbilityButton button to not complain
extends Resource
class_name Ability

@export var name: String
@export var texture: Texture
@export var abilityId: Global.AbilityIds

@export var damageMelee: int
@export var damageRanged: int
@export var damageMagical: int
@export var healingAmount: int
@export var threatAmount: int
@export var targetRange: int
@export var manaCost: int
@export var isHealing: bool = false
@export var aoeRadius: float = 0

@export var buffDuration: float
@export var buffAttributes: Attributes = null
@export var tickDuration: float
@export var persistentEffectAbility: Ability = null

@export var castTime: float = 2  # Time in seconds to cast the ability.
@export var recoveryTime: float = 1  # Time in seconds before Unit can use an ability again.
@export var speedFactorWhileCasting: float = 0.5

@export var projectileSpeed: float = 20
@export var projectileMesh: Mesh
@export var projectileShootAudio: AudioStream
@export var projectileHitAudio: AudioStream
@export var castingAudio: AudioStream

@export var canTargetSelf: bool = false
@export var canTargetFriend: bool = false
@export var canTargetEnemy: bool = false
@export var canTargetAlive: bool = true
@export var canTargetDead: bool = false


func canUse(user: Unit, target: Unit) -> bool:
	if target == null:
		return false
	if user == target and !canTargetSelf:
		return false
	if user.faction == target.faction and !canTargetFriend:
		return false
	if user.faction != target.faction and !canTargetEnemy:
		return false
	if target.isDead and !canTargetDead:
		return false
	if !target.isDead and !canTargetAlive:
		return false
	if user != target and user.position.distance_to(target.position) > targetRange:
		return false
	if user.mana < manaCost:
		return false
	return true

func payCost(user: Unit) -> void:
	user.mana -= manaCost

func refundCost(user: Unit) -> void:
	user.mana += manaCost
	user.mana = clampf(user.mana, 0, user.attributes.maxMana)

func use(user: Unit, target: Unit, source: Unit = null) -> bool:
	var attack := Attack.new()
	attack.attackingUnit = user
	attack.sourceUnit = source
	attack.damageMelee = damageMelee * (1 + user.attributes.meleeSkill * 0.01)
	attack.damageRanged = damageRanged * (1 + user.attributes.rangedSkill * 0.01)
	attack.damageMagical = damageMagical * (1 + user.attributes.magicSkill * 0.01)
	attack.healingAmount = healingAmount * (1 + user.attributes.healSkill * 0.01)
	attack.threat = (attack.damageMelee + attack.damageRanged + attack.damageMagical + threatAmount) * (1 + user.attributes.threatSkill * 0.01)
	attack.isHealing = isHealing
	attack.ability = self

	if buffAttributes:
		var buff := Buff.new()
		buff.attributes = buffAttributes
		buff.duration = buffDuration * (1 + user.attributes.durationSkill * 0.01)
		buff.texture = texture
		var buffs: Array[Buff] = [buff]
		attack.buffs = buffs

	if aoeRadius > 0:
		var _targets := Global.getAllUnits().filter(
			func(u: Unit) -> bool:
				return (
					(target.position.distance_to(u.position) <= aoeRadius)
					and !(user == u and !canTargetSelf)
					and !(user.faction == u.faction and !canTargetFriend)
					and !(user.faction != u.faction and !canTargetEnemy)
				)
		) as Array[Unit]
		for _target in _targets:
			var newProjectile := Projectile.init(attack, _target, projectileMesh, projectileHitAudio, projectileShootAudio, projectileSpeed)
			user.add_sibling(newProjectile, true)
	else:
		var newProjectile := Projectile.init(attack, target, projectileMesh, projectileHitAudio, projectileShootAudio, projectileSpeed)
		user.add_sibling(newProjectile, true)

	return true


func getDescription() -> String:
	var description := ""
	if damageMelee != 0:
		description += "Melee damage:   %d\n" % damageMelee
	if damageRanged != 0:
		description += "Ranged damage:  %d\n" % damageRanged
	if damageMagical != 0:
		description += "Fire damage:    %d\n" % damageMagical
	if healingAmount != 0:
		description += "Healing amount: %d\n" % healingAmount
	if threatAmount != 0:
		description += "Threat amount:  %d\n" % threatAmount
	description += "Range:          %d m\n" % targetRange
	description += "Cast time:      %.1f + %d s\n" % [castTime, recoveryTime]
	if aoeRadius > 0:
		description += "AoE radius:     %d m\n" % aoeRadius
	if manaCost > 0:
		description += "Mana cost:      %d\n" % manaCost
	description += "Targets:        %s%s%s%s" % [
		"self, " if canTargetSelf else "",
		"friend, " if canTargetFriend else "",
		"enemy, " if canTargetEnemy else "",
		"dead, " if canTargetDead else "",
	]
	description = description.trim_suffix(", ") + "\n"
	if persistentEffectAbility:
		description += "Duration:       %d s\n" % buffDuration
		description += persistentEffectAbility.getPersistentEffectDescription(tickDuration)
	elif buffAttributes:
		description += "Duration:       %d s\n  %s effect\n" % [buffDuration, "Debuff" if canTargetEnemy else "Buff"]
		description += buffAttributes.getDescriptionNoZero()

	return description.trim_suffix("\n")


func getPersistentEffectDescription(_tickDuration: float) -> String:
	var description := ""
	#TODO: The friend/self here should consider tha sourceUnit
	description += "  Effect on nearby %s%s%s" % [
		"friends, " if canTargetFriend else "",
		"enemies, " if canTargetEnemy else "",
		"and self, " if canTargetSelf else "",
	]
	description = description.trim_suffix(", ") + "\n"
	if damageMelee != 0:
		description += "Melee damage:   %d/s\n" % (damageMelee/_tickDuration)
	if damageRanged != 0:
		description += "Ranged damage:  %d/s\n" % (damageRanged/_tickDuration)
	if damageMagical != 0:
		description += "Fire damage:    %d/s\n" % (damageMagical/_tickDuration)
	if healingAmount != 0:
		description += "Healing amount: %d/s\n" % (healingAmount/_tickDuration)
	if threatAmount != 0:
		description += "Threat amount:  %d/s\n" % (threatAmount/_tickDuration)
	if aoeRadius > 0:
		description += "AoE radius:     %d m\n" % aoeRadius

	return description.trim_suffix("\n")

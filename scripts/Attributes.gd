@tool  # Necessary for TalentAttributeButton button to not complain
extends Resource
class_name Attributes

@export var maxHealth: int = 0
@export var healthRegen: float = 0
@export var maxMana: int = 0
@export var manaRegen: float = 0

@export var meleePower: int = 0
@export var rangedPower: int = 0
@export var firePower: int = 0
@export var healingPower: int = 0

@export var meleeSkill: int = 0
@export var rangedSkill: int = 0
@export var fireSkill: int = 0
@export var healingSkill: int = 0

@export var armorPoints: int = 0
@export var carryCapacity: int = 0
@export var armorSkill: int = 0
@export var speed: float = 0
@export var threatSkill: int = 0
@export var durationSkill: int = 0

@export var speedRatio: float = 1.0

var effMeleePower: float:
	get: return meleePower * (1 + meleeSkill / 100.0)

var effRangedPower: float:
	get: return rangedPower * (1 + rangedSkill / 100.0)

var effFirePower: float:
	get: return firePower * (1 + fireSkill / 100.0)

var effHealPower: float:
	get: return healingPower * (1 + healingSkill / 100.0)


func add(other: Attributes) -> Attributes:
	var total := Attributes.new()

	total.maxHealth = maxHealth + other.maxHealth
	total.healthRegen = healthRegen + other.healthRegen
	total.maxMana = maxMana + other.maxMana
	total.manaRegen = manaRegen + other.manaRegen
	total.meleePower = meleePower + other.meleePower
	total.rangedPower = rangedPower + other.rangedPower
	total.firePower = firePower + other.firePower
	total.healingPower = healingPower + other.healingPower
	total.armorPoints = armorPoints + other.armorPoints
	total.carryCapacity = carryCapacity + other.carryCapacity
	total.armorSkill = armorSkill + other.armorSkill
	total.meleeSkill = meleeSkill + other.meleeSkill
	total.rangedSkill = rangedSkill + other.rangedSkill
	total.fireSkill = fireSkill + other.fireSkill
	total.healingSkill = healingSkill + other.healingSkill
	total.speed = speed + other.speed
	total.threatSkill = threatSkill + other.threatSkill
	total.durationSkill = durationSkill + other.durationSkill

	total.speedRatio = speedRatio * other.speedRatio

	return total


func getDescription() -> String:
	var effectiveArmorPoints := armorPoints * (100 + armorSkill)
	var damageReduction := (1 - 10_000. / (10_000. + effectiveArmorPoints)) * 100
	var effectiveSpeed := speed * speedRatio

	return """
         Max    Regen
Health: %4d  %5.1f/s
Mana:   %4d  %5.1f/s

         Power   Skill  Eff.Power
Melee:     %3d   %3d %%   %6.1f
Ranged:    %3d   %3d %%   %6.1f
Fire:      %3d   %3d %%   %6.1f
Healing:   %3d   %3d %%   %6.1f

Threat Skill:    %3d %%
Duration Skill:  %3d %%

Armor   Skill  Eff.Armor
  %3d   %3d %%   %6.1f
Damage Reduction: %5.2f %%

 Speed      Ratio   Eff.Speed
%4.1f m/s   %5.1f %%   %4.1f m/s
""".trim_prefix("\n") % [
	maxHealth,
	healthRegen,
	maxMana,
	manaRegen,

	meleePower,
	meleeSkill,
	effMeleePower,

	rangedPower,
	rangedSkill,
	effRangedPower,

	firePower,
	fireSkill,
	effFirePower,

	healingPower,
	healingSkill,
	effHealPower,

	threatSkill,
	durationSkill,
	armorPoints,
	armorSkill,
	effectiveArmorPoints * 0.01,
	damageReduction,

	speed,
	(speedRatio - 1) * 100,
	effectiveSpeed,
]

func getDescriptionNoZero() -> String:
	var lines := []
	if maxHealth != 0:
		lines.append("Health Max:    %d" % maxHealth)
	if maxMana != 0:
		lines.append("Mana Max:      %d" % maxMana)
	if healthRegen != 0:
		lines.append("Health Regen:  %.1f/s" % healthRegen)
	if manaRegen != 0:
		lines.append("Mana Regen:    %.1f/s" % manaRegen)
	if meleeSkill != 0:
		lines.append("Melee Skill:   %d %%" % meleeSkill)
	if rangedSkill != 0:
		lines.append("Ranged Skill:  %d %%" % rangedSkill)
	if fireSkill != 0:
		lines.append("Fire Skill:    %d %%" % fireSkill)
	if healingSkill != 0:
		lines.append("Healing Skill: %d %%" % healingSkill)

	if meleePower != 0:
		lines.append("Melee Power:   %d" % meleePower)
	if rangedPower != 0:
		lines.append("Ranged Power:  %d" % rangedPower)
	if firePower != 0:
		lines.append("Fire Power:    %d" % firePower)
	if healingPower != 0:
		lines.append("Healing Power: %d" % healingPower)

	if threatSkill != 0:
		lines.append("Threat Skill:  %d %%" % threatSkill)
	if durationSkill != 0:
		lines.append("Duration Skill: %d %%" % durationSkill)
	if armorPoints != 0:
		lines.append("Armor Points:  %d" % armorPoints)
	if armorSkill != 0:
		lines.append("Armor Skill:   %d %%" % armorSkill)
	if speed != 0:
		lines.append("Speed:         %.1f m/s" % speed)
	if speedRatio != 1.0:
		lines.append("Speed Ratio:   %d %%" % ((speedRatio - 1) * 100))
	return "\n".join(lines)


static func sum(attributesList: Array[Attributes]) -> Attributes:
	var total := Attributes.new()
	for attributes in attributesList:
		total = total.add(attributes)
	return total

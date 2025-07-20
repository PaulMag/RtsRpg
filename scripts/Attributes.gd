@tool  # Necessary for TalentAttributeButton button to not complain
extends Resource
class_name Attributes

@export var maxHealth: int = 0
@export var healthRegen: float = 0
@export var maxMana: int = 0
@export var manaRegen: float = 0
@export var armorPoints: int = 0
@export var carryCapacity: int = 0
@export var armorSkill: int = 0
@export var meleeSkill: int = 0
@export var rangedSkill: int = 0
@export var magicSkill: int = 0
@export var healSkill: int = 0
@export var speed: float = 0
@export var threatSkill: int = 0

@export var speedRatio: float = 1.0


func add(other: Attributes) -> Attributes:
	var total := Attributes.new()

	total.maxHealth = maxHealth + other.maxHealth
	total.healthRegen = healthRegen + other.healthRegen
	total.maxMana = maxMana + other.maxMana
	total.manaRegen = manaRegen + other.manaRegen
	total.armorPoints = armorPoints + other.armorPoints
	total.carryCapacity = carryCapacity + other.carryCapacity
	total.armorSkill = armorSkill + other.armorSkill
	total.meleeSkill = meleeSkill + other.meleeSkill
	total.rangedSkill = rangedSkill + other.rangedSkill
	total.magicSkill = magicSkill + other.magicSkill
	total.healSkill = healSkill + other.healSkill
	total.speed = speed + other.speed
	total.threatSkill = threatSkill + other.threatSkill

	total.speedRatio = speedRatio * other.speedRatio

	return total


func getDescription() -> String:
	var effectiveArmorPoints := armorPoints * (100 + armorSkill)
	var damageReduction := (1 - 10_000. / (10_000. + effectiveArmorPoints)) * 100
	var effectiveSpeed := speed * speedRatio

	return """
Max Health:       %d
Max Mana:         %d
Health regen:     %.1f/s
Mana regen:       %.1f/s

Melee skill:      %d %%
Ranged skill:     %d %%
Fire skill:       %d %%
Healing skill:    %d %%
Threat skill:     %d %%

Armor Points:     %d
Armor skill:      %d %%
Eff. Armor Pts.:  %.1f
Damage Reduction: %.2f %%

Speed:            %.1f m/s
Speed ratio:      %d %%
Eff. Speed:       %.1f m/s
""" % [
	maxHealth,
	maxMana,
	healthRegen,
	manaRegen,
	meleeSkill,
	rangedSkill,
	magicSkill,
	healSkill,
	threatSkill,
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
		lines.append("Max Health:    %d" % maxHealth)
	if maxMana != 0:
		lines.append("Max Mana:      %d" % maxMana)
	if healthRegen != 0:
		lines.append("Health regen:  %.1f/s" % healthRegen)
	if manaRegen != 0:
		lines.append("Mana regen:    %.1f/s" % manaRegen)
	if meleeSkill != 0:
		lines.append("Melee skill:   %d %%" % meleeSkill)
	if rangedSkill != 0:
		lines.append("Ranged skill:  %d %%" % rangedSkill)
	if magicSkill != 0:
		lines.append("Fire skill:    %d %%" % magicSkill)
	if healSkill != 0:
		lines.append("Healing skill: %d %%" % healSkill)
	if threatSkill != 0:
		lines.append("Threat skill:  %d %%" % threatSkill)
	if armorPoints != 0:
		lines.append("Armor Points:  %d" % armorPoints)
	if armorSkill != 0:
		lines.append("Armor skill:   %d %%" % armorSkill)
	if speed != 0:
		lines.append("Speed:         %.1f m/s" % speed)
	if speedRatio != 1.0:
		lines.append("Speed ratio:   %d %%" % ((speedRatio - 1) * 100))
	return "\n".join(lines)


static func sum(attributesList: Array[Attributes]) -> Attributes:
	var total := Attributes.new()
	for attributes in attributesList:
		total = total.add(attributes)
	return total

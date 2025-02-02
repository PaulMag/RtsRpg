extends Resource
class_name Attributes

@export var maxHealth: int = 0
@export var healthRegen: float = 0
@export var maxMana: int = 0
@export var manaRegen: float = 0
@export var armorPoints: int = 0
@export var carryCapacity: int = 0
@export var armorSkill: int = 0
@export var attackSkill: int = 0
@export var magicSkill: int = 0
@export var healSkill: int = 0
@export var speed: int = 0
@export var threatSkill: int = 0

func add(other: Attributes) -> Attributes:
	var total := Attributes.new()
	total.maxHealth = maxHealth + other.maxHealth
	total.healthRegen = healthRegen + other.healthRegen
	total.maxMana = maxMana + other.maxMana
	total.manaRegen = manaRegen + other.manaRegen
	total.armorPoints = armorPoints + other.armorPoints
	total.carryCapacity = carryCapacity + other.carryCapacity
	total.armorSkill = armorSkill + other.armorSkill
	total.attackSkill = attackSkill + other.attackSkill
	total.magicSkill = magicSkill + other.magicSkill
	total.healSkill = healSkill + other.healSkill
	total.speed = speed + other.speed
	total.threatSkill = threatSkill + other.threatSkill
	return total

static func sum(attributesList: Array[Attributes]) -> Attributes:
	var total := Attributes.new()
	for attributes in attributesList:
		total = total.add(attributes)
	return total

extends Unit
class_name UnitBarbarian


func _ready() -> void:
	super._ready()

	var classAttributes := Attributes.new()
	classAttributes.armorPoints = 50

	for i in range(1, level):
		classAttributes.maxHealth += 50
		classAttributes.armorSkill += 25
		classAttributes.meleeSkill += 50

	addAttributes(classAttributes)

	health = attributes.maxHealth
	mana = attributes.maxMana

	scale = Vector3.ONE * (0.7 + level * 0.1)

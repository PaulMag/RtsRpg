extends Unit
class_name UnitArcher


func _ready() -> void:
	super._ready()

	var classAttributes := Attributes.new()

	for i in range(1, level):
		classAttributes.maxHealth += 50
		classAttributes.speed += 0.25
		classAttributes.rangedSkill += 50

	addAttributes(classAttributes)

	health = attributes.maxHealth
	mana = attributes.maxMana

	scale = Vector3.ONE * (0.7 + level * 0.1)

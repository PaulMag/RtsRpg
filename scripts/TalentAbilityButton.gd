@tool
extends TalentBaseButton
class_name TalentAbilityButton

@export var ability: Ability:
	set(_ability):
		ability = _ability
		if _ability:
			talentName = _ability.name
			texture_normal = _ability.texture
@export var maxRank: int = 1
@export var rank: int = 0

func _ready() -> void:
	nameLabel.text = talentName
	rankLabel.text = "%d/%d" % [rank, maxRank]

func rankUp() -> void:
	rank += 1
	rankLabel.text = "%d/%d" % [rank, maxRank]
	if rank == maxRank:
		disabled = true

@tool
extends TalentBaseButton
class_name TalentAttributeButton

@export var attributes: Attributes
@export var maxRank: int = 10
@export var rank: int = 0

func _ready() -> void:
	nameLabel.text = talentName
	rankLabel.text = "%d/%d" % [rank, maxRank]

func rankUp() -> void:
	rank += 1
	rankLabel.text = "%d/%d" % [rank, maxRank]
	if rank == maxRank:
		disabled = true

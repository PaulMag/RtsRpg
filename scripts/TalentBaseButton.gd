@tool
extends TextureButton
class_name TalentBaseButton

@onready var nameLabel: Label = $NameLabel
@onready var rankLabel: Label = $MarginContainer/RankLabel
@onready var disableTexture: TextureRect = $MarginContainer/DisableTexture
@export var maxRank: int = 1
@export var rank: int = 0

@export var talentName: String:
	set(_talentName):
		talentName = _talentName
		if Engine.is_editor_hint() and nameLabel:
			nameLabel.text = _talentName


func _ready() -> void:
	nameLabel.text = talentName
	rankLabel.text = "%d/%d" % [rank, maxRank]

func rankUp() -> void:
	rank += 1
	rankLabel.text = "%d/%d" % [rank, maxRank]
	if rank == maxRank:
		disabled = true
		disableTexture.visible = true

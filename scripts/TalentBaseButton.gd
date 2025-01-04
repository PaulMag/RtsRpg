@tool
extends TextureButton
class_name TalentBaseButton

@onready var nameLabel: Label = $NameLabel
@onready var rankLabel: Label = $MarginContainer/RankLabel

@export var talentName: String:
	set(_talentName):
		talentName = _talentName
		if Engine.is_editor_hint() and nameLabel:
			nameLabel.text = _talentName

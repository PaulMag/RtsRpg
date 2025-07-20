@tool
extends TextureButton
class_name TalentBaseButton

@onready var nameLabel: Label = $NameLabel
@onready var rankLabel: Label = $MarginContainer/RankLabel
@onready var disableTexture: TextureRect = $MarginContainer/DisableTexture
@onready var descriptionPanel: PanelContainer = %DescriptionPanel
@onready var descriptionLabel: Label = %DescriptionLabel


@export var maxRank: int = 1
@export var rank: int = 0

@export var talentName: String:
	set(_talentName):
		talentName = _talentName
		if Engine.is_editor_hint() and nameLabel:
			nameLabel.text = _talentName

@export var talentDescription: String:
	set(_talentDescription):
		talentDescription = _talentDescription
		if Engine.is_editor_hint() and nameLabel:
			descriptionLabel.text = _talentDescription


func _ready() -> void:
	nameLabel.text = talentName
	rankLabel.text = "%d/%d" % [rank, maxRank]
	descriptionPanel.visible = false


func rankUp() -> void:
	rank += 1
	rankLabel.text = "%d/%d" % [rank, maxRank]
	if rank == maxRank:
		disabled = true
		disableTexture.visible = true


func _on_mouse_entered() -> void:
	descriptionPanel.visible = true
	self_modulate = Color.LIGHT_GREEN

func _on_mouse_exited() -> void:
	descriptionPanel.visible = false
	self_modulate = Color.WHITE

@tool
extends TextureButton
class_name TalentBaseButton

signal ranked_up

@onready var nameLabel: Label = $NameLabel
@onready var rankLabel: Label = $MarginContainer/RankLabel
@onready var disableTexture: TextureRect = $MarginContainer/DisableTexture
@onready var descriptionPanel: PanelContainer = %DescriptionPanel
@onready var descriptionLabel: Label = %DescriptionLabel


@export var maxRank: int = 1
@export var rank: int = 0
@export var requiredTalents: Array[TalentBaseButton] = []

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
	if requiredTalents:
		drawLines()
	for requiredTalent in requiredTalents:
		requiredTalent.ranked_up.connect(drawLines)

func drawLines() -> void:
	disabled = true
	disableTexture.visible = true
	nameLabel.modulate = Color.GRAY
	for requiredTalent in requiredTalents:
		var line := Line2D.new()
		line.z_index = -1
		line.points = [size / 2, requiredTalent.global_position - global_position + size / 2]
		line.width = 4
		if requiredTalent.rank >= 1:
			line.default_color = Color.YELLOW
			disabled = false
			disableTexture.visible = false
			nameLabel.modulate = Color.WHITE
		else:
			line.default_color = Color.LIGHT_GRAY
		add_child(line)

func rankUp() -> void:
	rank += 1
	rankLabel.text = "%d/%d" % [rank, maxRank]
	if rank == maxRank:
		disabled = true
		disableTexture.visible = true
	ranked_up.emit()


func _on_mouse_entered() -> void:
	descriptionPanel.visible = true
	if not disabled:
		self_modulate = Color.LIGHT_GREEN

func _on_mouse_exited() -> void:
	descriptionPanel.visible = false
	self_modulate = Color.WHITE

@tool
class_name TalentBaseButton
extends TextureButton

signal ranked_up

const COLOR_LOCKED: Color = Color.DARK_GRAY
const COLOR_AVAILABLE: Color = Color.GREEN
const COLOR_FULL: Color = Color.YELLOW

@export var maxRank: int = 1
@export var rank: int = 0
@export var requiredTalents: Array[TalentBaseButton] = []

@export var talentName: String:
	set(_talentName):
		talentName = _talentName
		if Engine.is_editor_hint() and nameLabel:
			nameLabel.text = _talentName

@export_multiline var talentDescription: String:
	set(_talentDescription):
		talentDescription = _talentDescription
		if Engine.is_editor_hint() and nameLabel:
			descriptionLabel.text = _talentDescription

@onready var nameLabel: Label = %NameLabel
@onready var rankLabel: Label = %RankLabel
@onready var border: TextureRect = %Border
@onready var descriptionPanel: PanelContainer = %DescriptionPanel
@onready var descriptionLabel: Label = %DescriptionLabel


func _ready() -> void:
	nameLabel.text = talentName
	rankLabel.text = "%d/%d" % [rank, maxRank]
	descriptionPanel.visible = false
	self_modulate = Color.WHITE
	_setColors(COLOR_AVAILABLE)
	if requiredTalents:
		drawLines()
	for requiredTalent in requiredTalents:
		requiredTalent.ranked_up.connect(drawLines)


func drawLines() -> void:
	disabled = true
	self_modulate = COLOR_LOCKED
	_setColors(COLOR_LOCKED)
	for requiredTalent in requiredTalents:
		var line := Line2D.new()
		line.z_index = -1
		line.points = [size / 2, requiredTalent.global_position - global_position + size / 2]
		line.width = 4
		if requiredTalent.rank >= 1:
			line.default_color = COLOR_FULL
			disabled = false
			self_modulate = Color.WHITE
			_setColors(COLOR_AVAILABLE)
		else:
			line.default_color = COLOR_LOCKED
		add_child(line)


func rankUp() -> void:
	rank += 1
	rankLabel.text = "%d/%d" % [rank, maxRank]
	if rank == maxRank:
		disabled = true
		_setColors(COLOR_FULL)
	ranked_up.emit()


func _setColors(color: Color) -> void:
	rankLabel.modulate = color
	nameLabel.modulate = color
	border.modulate = color


func _on_mouse_entered() -> void:
	descriptionPanel.visible = true


func _on_mouse_exited() -> void:
	descriptionPanel.visible = false

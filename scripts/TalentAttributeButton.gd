@tool
extends TalentBaseButton
class_name TalentAttributeButton

@export var attributes: Attributes


func _ready() -> void:
	super._ready()
	if attributes:
		talentDescription = attributes.getDescriptionNoZero()
	descriptionLabel.text = talentDescription

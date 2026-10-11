@tool
class_name TalentAbilityButton
extends TalentBaseButton

@export var ability: Ability:
	set(_ability):
		ability = _ability
		if _ability:
			talentName = _ability.name
			texture_normal = _ability.texture


func _ready() -> void:
	super._ready()
	if ability:
		talentDescription = ability.getDescription()
	descriptionLabel.text = talentDescription


func _get_drag_data(_at_position: Vector2) -> Ability:
	if rank >= 1:
		var preview := TextureRect.new()
		preview.size = Vector2(64, 64)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.texture = texture_normal
		set_drag_preview(preview)
		return ability
	return null

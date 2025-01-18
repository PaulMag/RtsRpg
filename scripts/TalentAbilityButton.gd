@tool
extends TalentBaseButton
class_name TalentAbilityButton

@export var ability: Ability:
	set(_ability):
		ability = _ability
		if _ability:
			talentName = _ability.name
			texture_normal = _ability.texture

extends TextureProgressBar
class_name CastBar

@onready var label: Label = $Label


func setToCastMode(abilityName: String, castTime: float) -> void:
	label.text = abilityName
	max_value = castTime
	fill_mode = TextureProgressBar.FillMode.FILL_LEFT_TO_RIGHT
	tint_progress = Color.YELLOW
	label.modulate = Color.WHITE
	visible = true


func setToRecoveryMode(recoveryTime: float) -> void:
	max_value = recoveryTime
	fill_mode = TextureProgressBar.FillMode.FILL_RIGHT_TO_LEFT
	tint_progress = Color.ORANGE
	label.modulate = Color.DARK_GRAY

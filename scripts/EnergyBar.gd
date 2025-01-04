extends TextureProgressBar
class_name EnergyBar

@onready var energyBar: TextureProgressBar = $"."
@onready var label: Label = $Label

func setValue(amount: float) -> void:
	energyBar.value = amount
	label.text = "%s/%s" % [energyBar.value, energyBar.max_value]

func setMaxValue(amount: int) -> void:
	energyBar.max_value = amount
	label.text = "%s/%s" % [energyBar.value, energyBar.max_value]

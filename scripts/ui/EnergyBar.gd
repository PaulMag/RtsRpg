class_name EnergyBar
extends TextureProgressBar

@onready var energyBar: TextureProgressBar = $"."
@onready var label: Label = $Label


func setValue(amount: float) -> void:
	energyBar.value = amount
	label.text = "%s" % roundi(energyBar.value)


func setMaxValue(amount: int) -> void:
	energyBar.max_value = amount

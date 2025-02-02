extends Camera2D


func _process(_delta: float) -> void:
	var selectedUnit := Global.getUnitFromUnitId(Global.getPlayerCurrent().selectedUnitId)
	if selectedUnit:
		position = selectedUnit.position

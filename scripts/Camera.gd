extends Camera2D


func _process(_delta: float) -> void:
	var currentPlayer := Global.getPlayerCurrent()
	if currentPlayer == null:  #TODO: Workaround for bug.
		return

	var selectedUnit := Global.getUnitFromUnitId(currentPlayer.selectedUnitId)
	if selectedUnit:
		position = selectedUnit.position

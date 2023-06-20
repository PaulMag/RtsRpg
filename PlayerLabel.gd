extends HBoxContainer

@export var playerId = 0
@export var playerName = ""
@export var playerColor = Color()

func _ready():
	$PlayerId.text = "Player " + str(playerId)
	$PlayerName.text = playerName
	modulate = playerColor

extends HBoxContainer
class_name PlayerLabel

@export var playerId := 0
@export var playerName := ""
@export var playerColor := Color()

@onready var playerIdLabel: Label = $PlayerId
@onready var playerNameLabel: Label = $PlayerName

func _ready() -> void:
	playerIdLabel.text = "Player " + str(playerId)
	playerNameLabel.text = playerName
	modulate = playerColor

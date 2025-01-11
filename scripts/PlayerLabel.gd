extends HBoxContainer
class_name PlayerLabel

@export var playerId := 0
@export var playerName := ""
@export var playerColor := Color()

@onready var playerIdLabel: Label = $PlayerId
@onready var playerNameLabel: Label = $PlayerName


const SCENE = preload("res://scenes/PlayerLabel.tscn")
static func init() -> PlayerLabel:
	var scene := SCENE.instantiate() as PlayerLabel
	return scene

func _ready() -> void:
	playerIdLabel.text = "Player " + str(playerId)
	playerNameLabel.text = playerName
	modulate = playerColor

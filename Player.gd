extends Node

class_name Player

@export var playerId: int
@export var playerName: String
@export var playerColor: Color

@onready var input: PlayerInput = $PlayerInput
@onready var selectionDetector: SelectionDetector = $PlayerInput/SelectionDetector


func _ready() -> void:
	playerId = name.to_int()
	playerColor = Color(randf(), randf(), randf())

	input.set_process(playerId == multiplayer.get_unique_id())
	input.set_multiplayer_authority(playerId)

	selectionDetector.set_process(playerId == multiplayer.get_unique_id())
	selectionDetector.set_physics_process(playerId == multiplayer.get_unique_id())
	selectionDetector.set_multiplayer_authority(playerId)

	if playerId == multiplayer.get_unique_id():
		input.createHud()
	if multiplayer.is_server():
		print("Player on server: ", playerId, "  '", name, "'  ", input.get_multiplayer_authority(), "'  ")
	else:
		print("Player on peer:   ", playerId, "  '", name, "'  ", input.get_multiplayer_authority(), "'  ")


func _process(delta):
	if not multiplayer.is_server():
		return

	if input.isIssuingMoveOrder != Vector2.INF:  # INF represents no value
		var unit = input.getSelectedUnit()
		if unit and (unit.playerId == playerId):
			unit.move_to(input.isIssuingMoveOrder)
		input.isIssuingMoveOrder = Vector2.INF

	if input.isIssuingAttackOrder != 0:
		var unit = input.getSelectedUnit()
		if unit and (unit.playerId == playerId):
			var targetUnit = instance_from_id(input.isIssuingAttackOrder) as Unit
			if targetUnit != unit:
				unit.targetUnit = targetUnit
			input.isIssuingAttackOrder = 0

	if input.isIssuingEquipOrder != 0:
		var unit: Unit = input.getSelectedUnit()
		if unit and (unit.playerId == playerId):
			unit.equip(input.isIssuingEquipOrder)
			input.isIssuingEquipOrder = 0

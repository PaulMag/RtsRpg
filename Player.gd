extends Node

class_name Player

@export var playerId: int
@export var playerName: String
@export var playerColor: Color

var input: PlayerInput


func _ready() -> void:
	input = $PlayerInput as PlayerInput
	playerId = name.to_int()
	playerColor = Color(randf(), randf(), randf())
	input.set_multiplayer_authority(playerId)
	input.set_process(playerId == multiplayer.get_unique_id())
	if playerId == multiplayer.get_unique_id():
		input.createHud()
	if multiplayer.is_server():
		print("Player on server: ", playerId, "  '", name, "'  ", input.get_multiplayer_authority(), "'  ")
	else:
		print("Player on peer:   ", playerId, "  '", name, "'  ", input.get_multiplayer_authority(), "'  ")


func _process(delta):
	if not multiplayer.is_server():
		return

	if input.isIssuingMoveOrder:
		for unitId in input.selectedUnitIds:
			var unit = instance_from_id(unitId)
			if unit.playerId == playerId:
				unit.move_to(input.destination)
				if input.targetedUnitId != 0:
					unit.targetUnit = instance_from_id(input.targetedUnitId)
		input.isIssuingMoveOrder = false

	if input.isIssuingAttackOrder:
		for unitId in input.selectedUnitIds:
			var unit = instance_from_id(unitId)
			unit.attack()
		input.isIssuingAttackOrder = false

	if input.isIssuingEquipOrder != 0:
		for unitId in input.selectedUnitIds:
			var unit: Unit = instance_from_id(unitId) as Unit
			unit.equip(input.isIssuingEquipOrder)
		input.isIssuingEquipOrder = 0

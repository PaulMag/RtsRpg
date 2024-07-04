extends Node

class_name ServerPlayer


@export var playerId: int
@export var playerName: String
@export var playerColor: Color

var input: LocalPlayer

@export var unitIds: Array[int] = []

@onready var timer: Timer = $Timer


var hasStarted := false

func _enter_tree() -> void:
	add_to_group("players")

func _ready() -> void:
	playerId = name.to_int()
	playerColor = Color(randf(), randf(), randf())
	timer.start()  #TODO: This is stupid.

func _on_timer_timeout() -> void:  #TODO: This is stupid.
	for pi in get_tree().get_nodes_in_group("playerInputs"):
		print("PlayerInput: %s   Name: %s" % [pi, pi.name])
		if pi.name.to_int() == playerId:
			input = pi
			hasStarted = true
			return

func _process(_delta: float) -> void:
	if not hasStarted:
		return
	if not multiplayer.is_server():
		return

	if input.isIssuingMoveOrder != Vector2.INF:  # INF represents no value
		var unit := input.getSelectedUnit()
		if unit and (unit in getUnits()):
			unit.orderMove(input.isIssuingMoveOrder)
		input.isIssuingMoveOrder = Vector2.INF

	if input.isIssuingAttackOrder != 0:
		var unit := input.getSelectedUnit()
		if unit and (unit in getUnits()):
			var targetUnit := instance_from_id(input.isIssuingAttackOrder) as Unit
			if targetUnit != unit:
				unit.orderAttack(targetUnit)
			input.isIssuingAttackOrder = 0

	if input.isIssuingEquipOrder != 0:
		var unit: Unit = input.getSelectedUnit()
		if unit and (unit in getUnits()):
			unit.equip(input.isIssuingEquipOrder)
			input.isIssuingEquipOrder = 0

func giveUnit(unit: Unit) -> void:
	unitIds.append(unit.get_instance_id())

func getUnits() -> Array[Unit]:
	var units: Array[Unit] = []
	for unitId in unitIds:
		units.append(instance_from_id(unitId))
	return units

extends Node
class_name LocalPlayer


@export var isReady: bool = false
@export var playerId: int
@export var playerName: String
@export var playerColor: Color

@onready var destinationMarker: DestinationMarker = $DestinationMarker
@onready var canvasLayer: CanvasLayer = $CanvasLayer
@onready var unitList: VBoxContainer = $CanvasLayer/GameHud/VBoxContainer/UnitList

var selectedUnitId: int

@export var moveDirection := Vector2.ZERO


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	playerId = name.to_int()
	add_to_group("players")


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	var select_unit := getSelectedUnit()

	if select_unit and not select_unit.isDead:
		for abilityButtonIndex in range(0, 9):
			if event.is_action_pressed("cast_%s" % (abilityButtonIndex + 1)):
				if select_unit.getAbilityButtons().size() < abilityButtonIndex + 1:
					print("No ability assigned to button %s." % (abilityButtonIndex + 1))
					return
				var ability := select_unit.getAbilityButtons()[abilityButtonIndex].ability
				if select_unit.isCasting or select_unit.isRecovering:
					select_unit.queueAbilityOnServer.rpc_id(1, ability.abilityId)
				else:
					select_unit.useAbilityOnServer.rpc_id(1, ability.abilityId)
				select_unit.setRangeCircle(ability.targetRange)
				var abilityButton := select_unit.getAbilityButtons()[abilityButtonIndex]
				abilityButton.self_modulate = Color.LIGHT_GREEN
				return
			elif event.is_action_released("cast_%s" % (abilityButtonIndex + 1)):
				if select_unit.getAbilityButtons().size() < abilityButtonIndex + 1:
					return
				select_unit.setRangeCircle(0)
				var abilityButton := select_unit.getAbilityButtons()[abilityButtonIndex]
				abilityButton.self_modulate = Color.WHITE

	for unitIndex in range(0, 6):
		if event.is_action_pressed("select_unit_%s" % (unitIndex + 1)):
			var playerUnits := Global.getAllUnitsInFaction(Global.Faction.PLAYERS)
			if unitIndex < playerUnits.size():
				selectUnitByIndex(unitIndex)
			break


func issueMoveOrder(destination: Vector3) -> void:
	var unit := getSelectedUnit()
	if unit:
		unit.orderMove.rpc_id(1, destination)
		destinationMarker.markMove(destination)


@rpc("call_local")
func setSelectedUnitId(unitId: int) -> void:
	selectedUnitId = unitId


func _physics_process(_delta: float) -> void:
	if playerId == multiplayer.get_unique_id() and is_instance_valid(Global.cameraArm):
		moveDirection = Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down").rotated(-Global.cameraArm.rotation.y)
	if multiplayer.is_server() and getSelectedUnit():
		getSelectedUnit().moveDirection = Vector3(moveDirection.x, 0, moveDirection.y)


func getSelectedUnit() -> Unit:
	return Global.getUnitFromUnitId(selectedUnitId)


func selectUnitByIndex(unitIndex: int) -> void:
	var playerUnits := Global.getAllUnitsInFaction(Global.Faction.PLAYERS)
	selectUnit(playerUnits[unitIndex])
	updateUnitList(unitIndex)


func selectUnit(unit: Unit) -> void:
	var selectedUnit := getSelectedUnit()
	if unit  == null:
		if selectedUnit:
			selectedUnit.setSelected(false)
			setSelectedUnitId.rpc_id(1, 0)
		return
	if selectedUnit:
		selectedUnit.setSelected(false)
	unit.setSelected(true)
	selectedUnitId = unit.unitId
	setSelectedUnitId.rpc_id(1, unit.unitId)

func setTargetUnit(unit: Unit, follow: bool) -> void:
	var selectedUnit := getSelectedUnit()
	if unit == null or selectedUnit == null:
		return
	selectedUnit.setTargetUnitOnClients.rpc(unit.unitId, follow)


func setStatusOnServer(_isReady: bool, _playerName: String, _playerColor: Color) -> void:
	setStatusClients.rpc_id(1,_isReady, _playerName, _playerColor)

@rpc("any_peer", "call_local")
func setStatusClients(_isReady: bool, _playerName: String, _playerColor: Color) -> void:
	if multiplayer.is_server():
		setStatus.rpc(_isReady, _playerName, _playerColor)

@rpc("any_peer", "call_local")
func setStatus(_isReady: bool, _playerName: String, _playerColor: Color) -> void:
	isReady = _isReady
	playerName = _playerName
	playerColor = _playerColor


func updateUnitList(selectedUnitIndex: int = -1) -> void:
	for node in unitList.get_children():
		node.queue_free()

	var unitIndex := 0

	for unit in Global.getAllUnitsInFaction(Global.Faction.PLAYERS):
		var unitSelectButton: Button = Button.new()
		unitSelectButton.text = "[F%s]  %s" % [unitIndex+1, unit.unitName]
		unitSelectButton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		unitSelectButton.connect("pressed", selectUnitByIndex.bind(unitIndex))

		if unitIndex == selectedUnitIndex:
			unitSelectButton.modulate = Color.GREEN
		elif unit.unitId == selectedUnitId:
			unitSelectButton.modulate = Color.GREEN
		else:
			unitSelectButton.modulate = Color.WHITE

		unitList.add_child(unitSelectButton, true)
		unitIndex += 1

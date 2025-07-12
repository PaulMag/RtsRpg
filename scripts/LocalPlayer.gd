extends MultiplayerSynchronizer

class_name LocalPlayer



@export var playerId: int
@export var playerName: String
@export var playerColor: Color

# @onready var mouseDetector: MouseDetector = $MouseDetector
@onready var destinationMarker: DestinationMarker = $DestinationMarker
@onready var canvasLayer: CanvasLayer = $CanvasLayer
@onready var playerList: VBoxContainer = $CanvasLayer/GameHud/VBoxContainer/PlayerList
@onready var unitList: VBoxContainer = $CanvasLayer/GameHud/VBoxContainer/UnitList

var selectedUnitId: int

var isIssuingMoveOrder := Vector3.INF  # INF represents no value
@export var moveDirection := Vector2.ZERO


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	add_to_group("players")

func _ready() -> void:
	playerColor = Color(randf(), randf(), randf())

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	if getSelectedUnit():
		for abilityButtonIndex in range(0, 4):
			if event.is_action_pressed("cast_%s" % (abilityButtonIndex + 1)):
				if getSelectedUnit().getAbilityButtons().size() < abilityButtonIndex + 1:
					print("No ability assigned to button %s." % (abilityButtonIndex + 1))
					return
				var ability := getSelectedUnit().getAbilityButtons()[abilityButtonIndex].ability
				getSelectedUnit().useAbilityOnServer(ability.abilityId)
				return

	for unitIndex in range(0, 6):
		if event.is_action_pressed("select_unit_%s" % (unitIndex + 1)):
			var playerUnits := Global.getAllUnitsInFaction(Global.Faction.PLAYERS)
			if unitIndex < playerUnits.size():
				selectUnitByIndex(unitIndex)
			break

@rpc("call_local")
func issueMoveOrder(destination: Vector3) -> void:
	isIssuingMoveOrder = destination

@rpc("call_local")
func setSelectedUnitId(unitId: int) -> void:
	selectedUnitId = unitId

var unitUpdateCountdown := 0  # Necessary because there is some delay in the syncing. (TODO)

func _physics_process(_delta: float) -> void:
	if playerId == multiplayer.get_unique_id():
		moveDirection = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down").rotated(-Global.cameraArm.rotation.y)
	if multiplayer.is_server() and getSelectedUnit():
		getSelectedUnit().moveDirection = Vector3(moveDirection.x, 0, moveDirection.y)

func _process(_delta: float) -> void:
	if is_multiplayer_authority():
		updatePlayerStats()  #TODO: Should not happen every frame.

	if multiplayer.is_server():
		var unit := getSelectedUnit()
		if unit == null:
			return

		if isIssuingMoveOrder != Vector3.INF:  # INF represents no value
			unit = getSelectedUnit()
			print("isIssuingMoveOrder  player %s  unit %s  unitId %s" % [playerId, unit, unit.unitId])
			if unit and (unit.faction == Global.Faction.PLAYERS):
				unit.orderMove(isIssuingMoveOrder)
			isIssuingMoveOrder = Vector3.INF


func getSelectedUnit() -> Unit:
	return Global.getUnitFromUnitId(selectedUnitId)

func moveTo(destination: Vector3) -> void:
	if getSelectedUnit():
		issueMoveOrder.rpc_id(1, destination)
		destinationMarker.markMove(destination)

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

func updatePlayerStats() -> void:
	for node in playerList.get_children():
		node.queue_free()
	for player in Global.getPlayers():
		var playerLabelNode := PlayerLabel.init()
		playerLabelNode.playerId = player.playerId
		playerLabelNode.playerName = player.name
		playerLabelNode.playerColor = player.playerColor
		playerList.add_child(playerLabelNode, true)

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
		else:
			unitSelectButton.modulate = Color.WHITE

		unitList.add_child(unitSelectButton, true)
		unitIndex += 1

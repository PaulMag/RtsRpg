extends MultiplayerSynchronizer

class_name LocalPlayer


#const HUD = preload("res://Hud.tscn")

@export var playerId: int
@export var playerName: String
@export var playerColor: Color

@onready var mouseDetector: MouseDetector = $MouseDetector
@onready var destinationMarker: DestinationMarker = $DestinationMarker
@onready var canvasLayer: CanvasLayer = $CanvasLayer
@onready var playerList: VBoxContainer = $CanvasLayer/GameHud/VBoxContainer/PlayerList
@onready var unitList: VBoxContainer = $CanvasLayer/GameHud/VBoxContainer/UnitList

var selectedUnitId: int

var isIssuingMoveOrder := Vector2.INF  # INF represents no value
var isIssuingEquipOrder := 0

#var hud: Hud
@onready var inventoryHud: VBoxContainer = $CanvasLayer/Inventories

var INVENTORY_SLOTS := preload("res://scenes/InventorySlots.tscn")
var unitInventories: Dictionary = {}


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	add_to_group("players")

func _ready() -> void:
	playerColor = Color(randf(), randf(), randf())

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	if event.is_action_pressed("mouse_left_click"):
		mouseDetector.targetMousePoint(false)
	elif event.is_action_pressed("mouse_right_click"):
		mouseDetector.targetMousePoint(true)

	elif event.is_action_pressed("select_slot_1"):
		issueEquipOrder.rpc_id(1, 1)
	elif event.is_action_pressed("select_slot_2"):
		issueEquipOrder.rpc_id(1, 2)
	elif event.is_action_pressed("select_slot_3"):
		issueEquipOrder.rpc_id(1, 3)
	elif event.is_action_pressed("select_slot_4"):
		issueEquipOrder.rpc_id(1, 4)

	for unitIndex in range(0, 6):
		if event.is_action_pressed("select_unit_%s" % (unitIndex + 1)):
			var playerUnits := Global.getAllUnitsInFaction(Global.Faction.PLAYERS)
			if unitIndex < playerUnits.size():
				selectUnitByIndex(unitIndex)
			break

@rpc("call_local")
func issueMoveOrder(destination: Vector2) -> void:
	isIssuingMoveOrder = destination

@rpc("call_local")
func issueEquipOrder(slot: int) -> void:
	isIssuingEquipOrder = slot

@rpc("call_local")
func setSelectedUnitId(unitId: int) -> void:
	selectedUnitId = unitId

var unitUpdateCountdown := 0  # Necessary because there is some delay in the syncing. (TODO)

func _process(_delta: float) -> void:
	if is_multiplayer_authority():
		var unit := getSelectedUnit()
		if unit and (unit.isBeingUpdated or unitUpdateCountdown > 0):
			drawUnitInventory(unit)
			if unit.isBeingUpdated:
				unitUpdateCountdown = 10
			else:
				unitUpdateCountdown -= 1
			unit.isBeingUpdated = 0
		updatePlayerStats()  #TODO: Should not happen every frame.

	if multiplayer.is_server():
		if isIssuingMoveOrder != Vector2.INF:  # INF represents no value
			var unit := getSelectedUnit()
			print("isIssuingMoveOrder  player %s  unit %s  unitId %s" % [playerId, unit, unit.unitId])
			if unit and (unit.faction == Global.Faction.PLAYERS):
				unit.orderMove(isIssuingMoveOrder)
			isIssuingMoveOrder = Vector2.INF

		if isIssuingEquipOrder != 0:
			var unit: Unit = getSelectedUnit()
			if unit and (unit.faction == Global.Faction.PLAYERS):
				unit.equip(isIssuingEquipOrder)
				isIssuingEquipOrder = 0

func getSelectedUnit() -> Unit:
	return Global.getUnitFromUnitId(selectedUnitId)

func moveTo(destination: Vector2) -> void:
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
		resetUnitInventories()
		return
	if selectedUnit:
		selectedUnit.setSelected(false)
	unit.setSelected(true)
	selectedUnitId = unit.unitId
	setSelectedUnitId.rpc_id(1, unit.unitId)
	resetUnitInventories()
	drawUnitInventory(unit)

func setTargetUnit(unit: Unit, follow: bool) -> void:
	var selectedUnit := getSelectedUnit()
	if unit == null or selectedUnit == null:
		return
	selectedUnit.setTargetUnit.rpc(unit.unitId, follow)

func resetUnitInventories() -> void:
	for unit: Unit in unitInventories:
		var unitInventorySlots: InventorySlots = unitInventories[unit]
		unitInventorySlots.queue_free()
	unitInventories = {}

func drawUnitInventory(unit: Unit) -> void:
	if unitInventories.has(unit):
		var unitInventorySlots: InventorySlots = unitInventories[unit]
		unitInventorySlots.update(unit)
	else:
		var inventory: InventorySlots = INVENTORY_SLOTS.instantiate() as InventorySlots
		unitInventories[unit] = inventory
		inventoryHud.add_child(inventory)
		inventory.player = self
		inventory.update(unit)
		inventory.set_process(true)
		inventory.set_process_input(true)

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

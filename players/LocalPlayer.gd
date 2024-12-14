extends MultiplayerSynchronizer

class_name LocalPlayer


#const HUD = preload("res://Hud.tscn")

@export var playerId: int
@export var playerName: String
@export var playerColor: Color

@onready var mouseDetector: MouseDetector = $MouseDetector
@onready var destinationMarker: DestinationMarker = $DestinationMarker
@onready var canvasLayer: CanvasLayer = $CanvasLayer

var selectedUnitId: int

var isIssuingMoveOrder := Vector2.INF  # INF represents no value
var isIssuingAttackOrder := 0
var isIssuingEquipOrder := 0

#var hud: Hud
@onready var inventoryHud: VBoxContainer = $CanvasLayer/Inventories

var INVENTORY_SLOTS := preload("res://InventorySlots.tscn")
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
		mouseDetector.startMouseSelection()
		mouseDetector.finishMouseSelection()
	elif event.is_action_pressed("mouse_right_click"):
		mouseDetector.targetMousePoint()

	elif event.is_action_pressed("select_slot_1"):
		issueEquipOrder.rpc_id(1, 1)
	elif event.is_action_pressed("select_slot_2"):
		issueEquipOrder.rpc_id(1, 2)
	elif event.is_action_pressed("select_slot_3"):
		issueEquipOrder.rpc_id(1, 3)
	elif event.is_action_pressed("select_slot_4"):
		issueEquipOrder.rpc_id(1, 4)


@rpc("call_local")
func issueMoveOrder(destination: Vector2) -> void:
	isIssuingMoveOrder = destination

@rpc("call_local")
func issueAttackOrder(unitId: int) -> void:
	isIssuingAttackOrder = unitId

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

	if multiplayer.is_server():
		if isIssuingMoveOrder != Vector2.INF:  # INF represents no value
			var unit := getSelectedUnit()
			print("isIssuingMoveOrder  player %s  unit %s  unitId %s" % [playerId, unit, unit.unitId])
			if unit and (unit.faction == Global.Faction.PLAYERS):
				unit.orderMove(isIssuingMoveOrder)
			isIssuingMoveOrder = Vector2.INF

		if isIssuingAttackOrder != 0:
			var unit := getSelectedUnit()
			if unit and (unit.faction == Global.Faction.PLAYERS):
				var targetUnit := Global.getUnitFromUnitId(isIssuingAttackOrder) as Unit
				if targetUnit != unit:
					unit.orderAttack(targetUnit)
				isIssuingAttackOrder = 0

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

func selectUnit(unit: Unit) -> void:
	if unit  == null:
		if getSelectedUnit():
			getSelectedUnit().setSelected(false)
			if is_instance_valid(getSelectedUnit().targetUnit):
				getSelectedUnit().targetUnit.setTargeted(false)
			setSelectedUnitId.rpc_id(1, 0)
		resetUnitInventories()
		return
	if getSelectedUnit():
		getSelectedUnit().setSelected(false)
		if is_instance_valid(getSelectedUnit().targetUnit):
			getSelectedUnit().targetUnit.setTargeted(false)
	unit.setSelected(true)
	selectedUnitId = unit.unitId
	setSelectedUnitId.rpc_id(1, unit.unitId)
	if is_instance_valid(getSelectedUnit().targetUnit):
		getSelectedUnit().targetUnit.setTargeted(true)
	resetUnitInventories()
	drawUnitInventory(unit)

func targetUnit(unit: Unit) -> void:
	if unit == null or getSelectedUnit() == null:
		return
	issueAttackOrder.rpc_id(1, unit.unitId)
	if is_instance_valid(getSelectedUnit().targetUnit):
		getSelectedUnit().targetUnit.setTargeted(false)
	unit.setTargeted(true)
	destinationMarker.markAttack(unit)

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

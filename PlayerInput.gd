extends MultiplayerSynchronizer

class_name PlayerInput


const HUD = preload("res://HUD.tscn")

@onready var player: Player = $".."
@onready var mouseDetector: MouseDetector = $MouseDetector

@export var selectedUnitId: int

var isIssuingMoveOrder := Vector2.INF  # INF represents no value
var isIssuingAttackOrder := 0
var isIssuingEquipOrder := 0

var hud: Hud
var inventoryHud: VBoxContainer

var INVENTORY_SLOTS = preload("res://InventorySlots.tscn")
#var unitInventories: Array[InventorySlots] = []
var unitInventories: Dictionary = {}


func createHud() -> void:
	hud = HUD.instantiate()
	add_child(hud)
	inventoryHud = hud.inventories

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	if event.is_action_pressed("mouse_left_click"):
		mouseDetector.startMouseSelection()
		mouseDetector.finishMouseSelection()
	elif event.is_action_pressed("mouse_right_click"):
		mouseDetector.targetMousePoint()

	elif event.is_action_pressed("select_slot_1"):
		issueEquipOrder.rpc(1)
	elif event.is_action_pressed("select_slot_2"):
		issueEquipOrder.rpc(2)
	elif event.is_action_pressed("select_slot_3"):
		issueEquipOrder.rpc(3)
	elif event.is_action_pressed("select_slot_4"):
		issueEquipOrder.rpc(4)


@rpc("call_local")
func issueMoveOrder(destination: Vector2):
	isIssuingMoveOrder = destination

@rpc("call_local")
func issueAttackOrder(unitId: int):
	isIssuingAttackOrder = unitId

@rpc("call_local")
func issueEquipOrder(slot: int):
	isIssuingEquipOrder = slot

var unitUpdateCountdown = 0  # Necessary because there is some delay in the syncing. (TODO)

func _process(delta: float) -> void:
	var unit = getSelectedUnit()
	if unit and (unit.isBeingUpdated or unitUpdateCountdown > 0):
		drawUnitInventory(unit)
		if unit.isBeingUpdated:
			unitUpdateCountdown = 10
		else:
			unitUpdateCountdown -= 1
		unit.isBeingUpdated = 0

func getSelectedUnit() -> Unit:
	return instance_from_id(selectedUnitId)

func moveTo(destination: Vector2) -> void:
	issueMoveOrder.rpc(destination)

func selectUnit(unit: Unit) -> void:
	if unit  == null:
		if getSelectedUnit():
			getSelectedUnit().set_selected(false)
			selectedUnitId = 0
		resetUnitInventories()
		return
	if not unit in player.getUnits():
		return
	if getSelectedUnit():
		getSelectedUnit().set_selected(false)
	unit.set_selected(true)
	selectedUnitId = unit.get_instance_id()
	resetUnitInventories()
	drawUnitInventory(unit)

func targetUnit(unit: Unit) -> void:
	if unit == null:
		return
	issueAttackOrder.rpc(unit.get_instance_id())

func resetUnitInventories() -> void:
	for unit in unitInventories:
		unitInventories[unit].queue_free()
	unitInventories = {}

func drawUnitInventory(unit: Unit) -> void:
	if unitInventories.has(unit):
		unitInventories[unit].update(unit)
	else:
		var inventory: InventorySlots = INVENTORY_SLOTS.instantiate() as InventorySlots
		unitInventories[unit] = inventory
		inventoryHud.add_child(inventory)
		inventory.player = self
		inventory.update(unit)

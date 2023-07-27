extends MultiplayerSynchronizer

class_name LocalPlayer


#const HUD = preload("res://Hud.tscn")

var player: ServerPlayer
@onready var mouseDetector: MouseDetector = $MouseDetector
@onready var destinationMarker: DestinationMarker = $DestinationMarker

var selectedUnitId: int

var isIssuingMoveOrder := Vector2.INF  # INF represents no value
var isIssuingAttackOrder := 0
var isIssuingEquipOrder := 0

#var hud: Hud
@onready var inventoryHud: VBoxContainer = $CanvasLayer/Inventories

var INVENTORY_SLOTS = preload("res://InventorySlots.tscn")
var unitInventories: Dictionary = {}


func _enter_tree():
	set_multiplayer_authority(name.to_int(), true)
	add_to_group("playerInputs")

func _ready():
	for p in get_tree().get_nodes_in_group("players"):
		if p.playerId == name.to_int():
			player = p
			$CanvasLayer.visible = true
#			break
		else:
			$CanvasLayer.queue_free()
	set_process(player.playerId == multiplayer.get_unique_id())
#	createHud()

#func createHud() -> void:
#	hud = HUD.instantiate()
#	add_child(hud)
#	inventoryHud = hud.inventories

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

@rpc("call_local")
func setSelectedUnitId(unitId: int):
	selectedUnitId = unitId

var unitUpdateCountdown = 0  # Necessary because there is some delay in the syncing. (TODO)

func _process(_delta: float) -> void:
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
	if getSelectedUnit():
		issueMoveOrder.rpc(destination)
		destinationMarker.markMove(destination)

func selectUnit(unit: Unit) -> void:
	if unit  == null:
		if getSelectedUnit():
			getSelectedUnit().setSelected(false)
			if is_instance_valid(getSelectedUnit().targetUnit):
				getSelectedUnit().targetUnit.setTargeted(false)
			setSelectedUnitId.rpc(0)
		resetUnitInventories()
		return
	if not unit in player.getUnits():
		return
	if getSelectedUnit():
		getSelectedUnit().setSelected(false)
		if is_instance_valid(getSelectedUnit().targetUnit):
			getSelectedUnit().targetUnit.setTargeted(false)
	unit.setSelected(true)
	selectedUnitId = unit.get_instance_id()
	setSelectedUnitId.rpc(unit.get_instance_id())
	if is_instance_valid(getSelectedUnit().targetUnit):
		getSelectedUnit().targetUnit.setTargeted(true)
	resetUnitInventories()
	drawUnitInventory(unit)

func targetUnit(unit: Unit) -> void:
	if unit == null or getSelectedUnit() == null:
		return
	issueAttackOrder.rpc(unit.get_instance_id())
	if is_instance_valid(getSelectedUnit().targetUnit):
		getSelectedUnit().targetUnit.setTargeted(false)
	unit.setTargeted(true)
	destinationMarker.markAttack(unit)

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
		inventory.set_process(true)
		inventory.set_process_input(true)

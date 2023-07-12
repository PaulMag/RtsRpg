extends MultiplayerSynchronizer

class_name PlayerInput

const HUD = preload("res://HUD.tscn")

@onready var player: Player = $".."
@onready var selectionPanel: Panel = $"../Panel"
@onready var selectionDetector: Area2D = $"../SelectionDetector"
@onready var selectionDetectorCollision: CollisionShape2D = $"../SelectionDetector/CollisionShape2D"

@export var selectedUnitId: int
@export var destination: Vector2
@export var targetedUnitId: int

@export var isIssuingMoveOrder := false
@export var isIssuingAttackOrder := false
@export var isIssuingEquipOrder := 0

var hud: Hud
var inventoryHud: VBoxContainer

const SELECTION_BOX_MINIMUM_SIZE := 5

var INVENTORY_SLOTS = preload("res://InventorySlots.tscn")
#var unitInventories: Array[InventorySlots] = []
var unitInventories: Dictionary = {}

var isDraggingMouse := false
var isSelecting := false
var isTargeting := false
var selectionStart: Vector2
var selectionEnd: Vector2
var unitsInSelectionDetector: Array[Unit]

#func _ready() -> void:
#	set_process(player.playerId == multiplayer.get_unique_id())


func createHud() -> void:
	hud = HUD.instantiate()
	add_child(hud)
	inventoryHud = hud.inventories

func _unhandled_input(event: InputEvent) -> void:
#	print("before ", player.playerId)
	if not is_multiplayer_authority():
		return
#	print("after ", player.playerId)
	if event.is_action_pressed("mouse_left_click"):
		selectionStart = selectionPanel.get_global_mouse_position()
		isDraggingMouse = true
		selectionPanel.visible = true
	if isDraggingMouse:
		selectionEnd = selectionPanel.get_global_mouse_position()
	if event.is_action_released("mouse_left_click"):
		selectionEnd = selectionPanel.get_global_mouse_position()
		isDraggingMouse = false
		selectionPanel.visible = false
		area_selected(selectionStart, selectionEnd)

	if event.is_action_pressed("mouse_right_click"):
		destination = selectionPanel.get_global_mouse_position()
		set_target_area(destination)
		issueMoveOrder.rpc()
	if event.is_action_pressed("ui_accept"):
		issueAttackOrder.rpc()

	if event.is_action_pressed("select_slot_1"):
		issueEquipOrder.rpc(1)
	elif event.is_action_pressed("select_slot_2"):
		issueEquipOrder.rpc(2)
	elif event.is_action_pressed("select_slot_3"):
		issueEquipOrder.rpc(3)
	elif event.is_action_pressed("select_slot_4"):
		issueEquipOrder.rpc(4)


@rpc("call_local")
func issueMoveOrder():
	isIssuingMoveOrder = true

@rpc("call_local")
func issueAttackOrder():
	isIssuingAttackOrder = true

@rpc("call_local")
func issueEquipOrder(slot: int):
	isIssuingEquipOrder = slot

var unitUpdateCountdown = 0  # Necessary because there is some delay in the syncing. (TODO)

func _process(delta: float) -> void:
	if isDraggingMouse:
		draw_selection_box()
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

func area_selected(start: Vector2, end: Vector2) -> void:
	var area = []
	area.append(Vector2(min(start.x, end.x), min(start.y, end.y)))
	area.append(Vector2(max(start.x, end.x), max(start.y, end.y)))
	set_selection_area(area)



func _on_selection_timer_timeout() -> void:
	isSelecting = false
	selectionDetectorCollision.disabled  = true

func get_all_units() -> Array[Unit]:
	var allNodes = get_tree().get_nodes_in_group("units")
	var allUnits: Array[Unit] = []
	for node in allNodes:
		allUnits.append(node as Unit)
	return allUnits

func selectUnit(unit: Unit) -> void:
	var maxY := 1e9
	for u in unitsInSelectionDetector:
		if u.playerId == player.playerId and u.position.y > unit.position.y:
			maxY = u.position.y
			unit = u
	if unit.playerId != player.playerId:
		return
	if getSelectedUnit():
		getSelectedUnit().set_selected(false)
	unit.set_selected(true)
	selectedUnitId = unit.get_instance_id()
	resetUnitInventories()
	drawUnitInventory(unit)

func set_selection_area(area) -> void:
	for unit in get_all_units():
		unit.set_selected(false)
	selectedUnitId = 0
	unitsInSelectionDetector = []
	resetUnitInventories()
	isSelecting = true
	selectionDetectorCollision.disabled  = false
	selectionDetector.position = (area[0] + area[1]) * 0.5
	selectionDetectorCollision.shape.size.x = abs(area[0].x - area[1].x)
	selectionDetectorCollision.shape.size.y = abs(area[0].y - area[1].y)
	$"../SelectionTimer".start()

func _on_selection_detector_area_entered(area) -> void:
	if isSelecting:
		var unit = area.get_parent() as Unit
		if not unit is Unit:
			return
		unitsInSelectionDetector.append(unit)
		selectUnit(unit)

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

func draw_selection_box(s:=true) -> void:
	selectionPanel.size = Vector2(abs(selectionStart.x - selectionEnd.x), abs(selectionStart.y - selectionEnd.y))
	var pos = Vector2()
	pos.x = min(selectionStart.x, selectionEnd.x)
	pos.y = min(selectionStart.y, selectionEnd.y)
	selectionPanel.position = pos
	selectionPanel.size *= int(s)


func set_target_area(position: Vector2) -> void:
	#TODO: Do this properly.
	for unit in get_all_units():
		if position.distance_to(unit.position) < 12:
			targetedUnitId = unit.get_instance_id()
			return

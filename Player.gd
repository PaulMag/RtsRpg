extends Node

class_name Player

@export var playerId: int
@export var playerName: String
@export var playerColor: Color

@export var direction: Vector2
@export var selectedUnitIds: Array[int] = []
@export var destination: Vector2
@export var targetedUnitId: int

@export var isCloning := false
@export var isIssuingMoveOrder := false
@export var isIssuingAttackOrder := false
@export var isIssuingEquipOrder := 0

const SELECTION_BOX_MINIMUM_SIZE := 5

var INVENTORY_SLOTS = preload("res://InventorySlots.tscn")
#var unitInventories: Array[InventorySlots] = []
var unitInventories: Dictionary = {}

var isDraggingMouse := false
var isSelecting := false
var isTargeting := false
var selectionStart: Vector2
var selectionEnd: Vector2

func _ready() -> void:
	playerId = name.to_int()
	playerColor = Color(randf(), randf(), randf())
	set_multiplayer_authority(playerId)
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())
	if multiplayer.is_server():
		print("Player on server: ", playerId, "  '", name, "'  ")
	else:
		print("Player on peer:   ", playerId, "  '", name, "'  ")


func _process(delta: float) -> void:
	if isDraggingMouse:
		draw_selection_box()
	if Input.is_action_just_pressed("ui_cancel"):
		clone.rpc()


@rpc("call_local")
func clone():
	isCloning = true

@rpc("call_local")
func issueMoveOrder():
	isIssuingMoveOrder = true

@rpc("call_local")
func issueAttackOrder():
	isIssuingAttackOrder = true

@rpc("call_local")
func issueEquipOrder(slot: int):
	isIssuingEquipOrder = slot

func area_selected(start: Vector2, end: Vector2) -> void:
	var area = []
	area.append(Vector2(min(start.x, end.x), min(start.y, end.y)))
	area.append(Vector2(max(start.x, end.x), max(start.y, end.y)))
	set_selection_area(area)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_left_click"):
		selectionStart = $Panel.get_global_mouse_position()
		isDraggingMouse = true
		$Panel.visible = true
	if isDraggingMouse:
		selectionEnd = $Panel.get_global_mouse_position()
	if event.is_action_released("mouse_left_click"):
		selectionEnd = $Panel.get_global_mouse_position()
		isDraggingMouse = false
		$Panel.visible = false
		area_selected(selectionStart, selectionEnd)

	if event.is_action_pressed("mouse_right_click"):
		destination = $Panel.get_global_mouse_position()
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


func _on_selection_timer_timeout() -> void:
	isSelecting = false
	$SelectionDetector/CollisionShape2D.disabled  = true

func get_all_units() -> Array[Unit]:
	var allNodes = get_tree().get_nodes_in_group("units")
	var allUnits: Array[Unit] = []
	for node in allNodes:
		allUnits.append(node as Unit)
	return allUnits

func set_selection_area(area) -> void:
	for unit in get_all_units():
		unit.set_selected(false)
	selectedUnitIds = []
	resetUnitInventories()
	isSelecting = true
	$SelectionDetector/CollisionShape2D.disabled  = false
	$SelectionDetector.position = (area[0] + area[1]) * 0.5
	$SelectionDetector/CollisionShape2D.shape.size.x = abs(area[0].x - area[1].x)
	$SelectionDetector/CollisionShape2D.shape.size.y = abs(area[0].y - area[1].y)
	$SelectionTimer.start()

func _on_selection_detector_area_entered(area) -> void:
	if isSelecting:
		var unit = area.get_parent() as Unit
		if not unit is Unit:
			return
		unit.set_selected(true)
		selectedUnitIds.append(unit.get_instance_id())
		#TODO: Should select according to z_index ordering
		var boxShape = abs(selectionStart - selectionEnd)
		if boxShape.x + boxShape.y < SELECTION_BOX_MINIMUM_SIZE:
			isSelecting = false
			$SelectionDetector/CollisionShape2D.disabled  = true
		drawUnitInventory(unit)

func resetUnitInventories() -> void:
	for unit in unitInventories:
		unitInventories[unit].queue_free()
	unitInventories = {}

func drawUnitInventory(unit: Unit) -> void:
	var inventory: InventorySlots = INVENTORY_SLOTS.instantiate() as InventorySlots
	if unitInventories.has(unit):
		unitInventories[unit].queue_free()
	unitInventories[unit] = inventory
	$HUD/Inventories.add_child(inventory)
	inventory.update(unit)
	inventory.player = self
	unit.player = self  #TODO: Do this properly

func draw_selection_box(s:=true) -> void:
	$Panel.size = Vector2(abs(selectionStart.x - selectionEnd.x), abs(selectionStart.y - selectionEnd.y))
	var pos = Vector2()
	pos.x = min(selectionStart.x, selectionEnd.x)
	pos.y = min(selectionStart.y, selectionEnd.y)
	$Panel.position = pos
	$Panel.size *= int(s)


func set_target_area(position: Vector2) -> void:
	#TODO: Do this properly.
	for unit in get_all_units():
		if position.distance_to(unit.position) < 12:
			targetedUnitId = unit.get_instance_id()
			return

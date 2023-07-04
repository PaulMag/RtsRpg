extends TextureRect

class_name InventorySlots

var buttons: Array[TextureButton]
var _unit: Unit
var player: Player

const COLOR_EQUIPPED = Color(1, 1, 1)
const COLOR_UNEQUIPPED = Color(0.5, 0.5, 0.5)
const COLOR_HOVER = Color(0.5, 1, 0.5)

func _ready() -> void:
	buttons = [
		$HBoxContainer/InventorySlot1 as TextureButton,
		$HBoxContainer/InventorySlot2 as TextureButton,
		$HBoxContainer/InventorySlot3 as TextureButton,
		$HBoxContainer/InventorySlot4 as TextureButton,
	]

func update(unit: Unit) -> void:
	_unit = unit  #TODO: Do this properly
	for slot in range(1, 4+1):
		var weapon = unit.get_weapon(slot)
		var button = buttons[slot - 1]
		button.set_texture_normal(weapon.texture if weapon else null)
		if unit.weaponSlotEquipped == slot:
			button.modulate = COLOR_EQUIPPED
		else:
			button.modulate = COLOR_UNEQUIPPED


func _on_inventory_slot_1_pressed() -> void:
	player.issueEquipOrder.rpc(1)

func _on_inventory_slot_2_pressed() -> void:
	player.issueEquipOrder.rpc(2)

func _on_inventory_slot_3_pressed() -> void:
	player.issueEquipOrder.rpc(3)

func _on_inventory_slot_4_pressed() -> void:
	player.issueEquipOrder.rpc(4)


func _on_inventory_slot_1_mouse_entered():
	if _unit.weaponSlotEquipped != 1:
		buttons[0].modulate = COLOR_HOVER

func _on_inventory_slot_1_mouse_exited():
	if _unit.weaponSlotEquipped != 1:
		buttons[0].modulate = COLOR_UNEQUIPPED


func _on_inventory_slot_2_mouse_entered():
	if _unit.weaponSlotEquipped != 2:
		buttons[1].modulate = COLOR_HOVER

func _on_inventory_slot_2_mouse_exited():
	if _unit.weaponSlotEquipped != 2:
		buttons[1].modulate = COLOR_UNEQUIPPED


func _on_inventory_slot_3_mouse_entered():
	if _unit.weaponSlotEquipped != 3:
		buttons[2].modulate = COLOR_HOVER

func _on_inventory_slot_3_mouse_exited():
	if _unit.weaponSlotEquipped != 3:
		buttons[2].modulate = COLOR_UNEQUIPPED


func _on_inventory_slot_4_mouse_entered():
	if _unit.weaponSlotEquipped != 4:
		buttons[3].modulate = COLOR_HOVER

func _on_inventory_slot_4_mouse_exited():
	if _unit.weaponSlotEquipped != 4:
		buttons[3].modulate = COLOR_UNEQUIPPED

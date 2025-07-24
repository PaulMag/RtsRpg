extends CharacterBody3D
class_name Unit


signal died


const BARBARIAN_SCENE := preload("res://scenes/character_models/Barbarian.tscn")
const ROGUE_SCENE := preload("res://scenes/character_models/RogueHooded.tscn")

var CORPSE := preload("res://scenes/Corpse.tscn")

@export var unitId : int
@export var faction := Global.Faction.ENEMIES
@export var loot := Global.Items.Bow
@export var playerColor := Color.DIM_GRAY

# Attributes
var damageReduction: float = 0
var attributes: Attributes
@export var baseAttributes: Attributes

enum states {
	IDLE,
	WALKING,
	ATTACKING,
	SPELLCASTING,
}

@export var unitName: String = ""

@export var health: float = 75
@export var mana: float = 40
@export var state := states.IDLE
@export var aiController: AiController

@onready var characterModel: CharacterModel = $CharacterModel
@onready var animationPlayer: AnimationPlayer = characterModel.animationPlayer
@onready var selectedCircle: Sprite3D = $SelectedCircle
@onready var targetCircle: Sprite3D = $TargetCircle
@onready var healthBar: EnergyBar  = %HealthBar
@onready var manaBar: EnergyBar  = %ManaBar
@onready var castBar: CastBar  = %CastBar
@onready var navigationAgent: NavigationAgent3D = $NavigationAgent
@onready var label: Label = %Label
@onready var armorLabel: Label = %ArmorLabel
@onready var damageSound: AudioStreamPlayer2D = $DamageSound
@onready var castTimer: Timer = $CastTimer
@onready var recoveryTimer: Timer = $RecoveryTimer
@onready var regenTimer: Timer = $RegenTimer
@onready var unitHud: CanvasLayer = $UnitHud
@onready var talentTree: Panel = $UnitHud/TalentTree
@onready var talentTreeButton: Button = %TalentTreeButton
@onready var talentTreeAttributeButtons: Control = %TalentAttributeButtons
@onready var talentTreeAbilityButtons: Control = %TalentAbilityButtons
@onready var cancelCastButton: TextureButton = %CancelCastButton
@onready var abilityButtonsContainer: HBoxContainer = %AbilityButtonsContainer
@onready var buffIcons: HBoxContainer = %BuffIcons
@onready var inventoryButton: Button = %InventoryButton
@onready var inventoryPanel: Panel = %InventoryPanel
@onready var inventoryContainer: GridContainer = %InventoryContainer
@onready var attributesLabel: Label = %AttributesLabel

@onready var destination : Vector3
var moveDirection := Vector3.ZERO

@export var targetUnit: Unit = null

var isSelected := false
var followCursor := false
var followTarget := false
var isCasting := false
var castingAbilityId: Global.AbilityIds
var isRecovering := false
var isAutocasting := false
var autocastAbilityId: Global.AbilityIds

var threatTable: Dictionary[Unit, float] = {}
var buffs: Array[Buff] = []

var equippedItemButtons: Dictionary[Global.ItemSlots, ItemButton] = {
	Global.ItemSlots.MainHand: null,
	Global.ItemSlots.Offhand: null,
	Global.ItemSlots.Head: null,
	Global.ItemSlots.Torso: null,
}


func _ready() -> void:
	if multiplayer.is_server():
		unitId = randi()
		regenTimer.start()
	print("unit _ready   player %s  unit %s  unitId %s" % [multiplayer.get_unique_id(), get_instance_id(), unitId])

	self.add_to_group("units")

	if aiController:
		var characterModelScene: CharacterModel
		if aiController is AiControllerArcher:
			characterModelScene = ROGUE_SCENE.instantiate()
		else:
			characterModelScene = BARBARIAN_SCENE.instantiate()
		var characterModelOld := characterModel
		add_child(characterModelScene)
		characterModel = characterModelScene
		animationPlayer = characterModel.animationPlayer
		characterModelOld.queue_free()

	updateAttributes()

	health = attributes.maxHealth
	mana = attributes.maxMana

	if unitName == "":
		unitName = "Unit #" + str(randi_range(1, 99))
	label.text = unitName

	var nodeIndex := 0
	for node in talentTreeAttributeButtons.get_children():
		if node is TalentAttributeButton:
			var talentAttributeButton := node as TalentAttributeButton
			talentAttributeButton.pressed.connect(learnTalentAttributeOnServer.bind(nodeIndex))
		nodeIndex += 1

	nodeIndex = 0
	for node in talentTreeAbilityButtons.get_children():
		if node is TalentAbilityButton:
			var talentAbilityButton := node as TalentAbilityButton
			talentAbilityButton.pressed.connect(learnTalentAbilityOnServer.bind(nodeIndex))
		nodeIndex += 1

	selectedCircle.modulate = playerColor

	unitHud.visible = isSelected
	talentTree.visible = talentTreeButton.button_pressed
	inventoryPanel.visible = inventoryButton.button_pressed


func learnTalentAttributeOnServer(nodeIndex: int) -> void:
	learnTalentAttributeOnClients.rpc(nodeIndex)

func learnTalentAbilityOnServer(nodeIndex: int) -> void:
	learnTalentAbilityOnClients.rpc(nodeIndex)

@rpc("any_peer", "call_local")
func learnTalentAttributeOnClients(nodeIndex: int) -> void:
	if multiplayer.is_server():
		learnTalentAttribute.rpc(nodeIndex)

@rpc("any_peer", "call_local")
func learnTalentAbilityOnClients(nodeIndex: int) -> void:
	if multiplayer.is_server():
		learnTalentAbility.rpc(nodeIndex)

@rpc("authority", "call_local")
func learnTalentAttribute(nodeIndex: int) -> void:
	var talentAttributeButton := talentTreeAttributeButtons.get_children()[nodeIndex] as TalentAttributeButton
	addAttributes(talentAttributeButton.attributes)
	talentAttributeButton.rankUp()
	print("Learned '%s' rank %s" % [talentAttributeButton.talentName, talentAttributeButton.rank])

@rpc("authority", "call_local")
func learnTalentAbility(nodeIndex: int) -> void:
	var talentAbilityButton := talentTreeAbilityButtons.get_children()[nodeIndex] as TalentAbilityButton

	var newAbilityButton := AbilityButton.init(talentAbilityButton.ability)
	newAbilityButton.pressed.connect(useAbilityOnServer.bind(newAbilityButton.ability.abilityId))
	newAbilityButton.toggle_autocast.connect(toggleAutocastOnServer.bind(newAbilityButton.ability.abilityId))
	abilityButtonsContainer.add_child(newAbilityButton)

	talentAbilityButton.rankUp()
	print("Learned '%s' rank %s" % [talentAbilityButton.talentName, talentAbilityButton.rank])

func getAbilityButtons() -> Array[AbilityButton]:
	var abilityButtons: Array[AbilityButton] = []
	for node in abilityButtonsContainer.get_children():
		if node is AbilityButton:
			abilityButtons.append(node as AbilityButton)
	return abilityButtons

func getAbilityButton(abilityId: Global.AbilityIds) -> AbilityButton:
	for abilityButton in getAbilityButtons():
		if abilityButton.ability.abilityId == abilityId:
			return abilityButton
	return null

func useAbilityOnServer(abilityId: Global.AbilityIds, _targetUnit: Unit = null) -> void:
	if _targetUnit == null:
		_targetUnit = targetUnit
	if _targetUnit == null:
		return
	useAbilityOnClients.rpc(abilityId, _targetUnit.unitId)

@rpc("any_peer", "call_local")
func useAbilityOnClients(abilityId: Global.AbilityIds, targetUnitId: int) -> void:
	if multiplayer.is_server():
		useAbility.rpc(abilityId, targetUnitId)

@rpc("authority", "call_local")
func useAbility(abilityId: Global.AbilityIds, targetUnitId: int) -> void:
	if isCasting:
		print("Unit %s is already casting" % [unitName])
		return
	if isRecovering:
		print("Unit %s is recovering" % [unitName])
		return

	var _targetUnit := Global.getUnitFromUnitId(targetUnitId)

	var ability := Global.getAbility[abilityId]

	if not ability.canUse(self, _targetUnit):
		print("Unit %s cannot use ability %s on unit %s" % [unitName, ability.name, _targetUnit.unitName if _targetUnit else "NULL"])
		return

	ability.payCost(self)

	isCasting = true
	cancelCastButton.visible = true
	castingAbilityId = abilityId
	castBar.max_value = ability.castTime
	castBar.label.text = ability.name
	castTimer.start(ability.castTime)
	castBar.visible = true

func _on_cast_timer_timeout() -> void:
	animationPlayer.play("Spellcast_Shoot")

	castBar.visible = false
	isCasting = false
	cancelCastButton.visible = false

	var ability := Global.getAbility[castingAbilityId]
	var success := ability.use(self, targetUnit)

	if success:
		isRecovering = true
		for abilityButton in getAbilityButtons():
			abilityButton.cooldownProgressBar.max_value = ability.recoveryTime
			abilityButton.cooldownProgressBar.value = ability.recoveryTime
		recoveryTimer.start(ability.recoveryTime)
		print("Unit %s ability %s on unit %s" % [unitName, ability.name, targetUnit.unitName if targetUnit else "NULL"])
	else:
		ability.refundCost(self)
		print("Unit %s failed to use ability %s on unit %s" % [unitName, ability.name, targetUnit.unitName if targetUnit else "NULL"])

func canUseAbility(abilityId: Global.AbilityIds) -> bool:
	var ability := Global.getAbility[abilityId]
	return ability.canUse(self, targetUnit)

func toggleAutocastOnServer(abilityId: Global.AbilityIds) -> void:
	toggleAutocastOnClients.rpc(abilityId)

@rpc("any_peer", "call_local")
func toggleAutocastOnClients(abilityId: Global.AbilityIds) -> void:
	if multiplayer.is_server():
		toggleAutocast.rpc(abilityId)

@rpc("authority", "call_local")
func toggleAutocast(abilityId: Global.AbilityIds) -> void:
	if not isAutocasting:
		getAbilityButton(abilityId).setAutocast(true)
		autocastAbilityId = abilityId
		isAutocasting = true
	elif autocastAbilityId == abilityId:
		getAbilityButton(abilityId).setAutocast(false)
		isAutocasting = false
	else:
		for abilityButton in getAbilityButtons():
			if abilityButton.ability.abilityId == abilityId:
				abilityButton.setAutocast(true)
				autocastAbilityId = abilityId
				isAutocasting = true
			else:
				abilityButton.setAutocast(false)  # Un-toggle all the other abilities

func updateAttributes() -> void:
	var buffAttributesList: Array[Attributes]
	buffAttributesList.assign(buffs.map(  # This is a workaround because map doesn't support proper typing.
		func(buff: Buff) -> Attributes: return buff.attributes
	))

	var itemAttributesList: Array[Attributes]
	itemAttributesList.assign(equippedItemButtons.values().map(  # This is a workaround because map doesn't support proper typing.
		func(itemButton: ItemButton) -> Attributes:
			return itemButton.item.attributes if itemButton and itemButton.item and itemButton.item.attributes else Attributes.new()
	))

	var buffAttributes := Attributes.sum(buffAttributesList)
	var itemAttributes := Attributes.sum(itemAttributesList)

	attributes = Attributes.sum([baseAttributes, buffAttributes, itemAttributes])

	healthBar.setMaxValue(attributes.maxHealth)
	manaBar.setMaxValue(attributes.maxMana)

	damageReduction = 10_000. / (10_000. + attributes.armorPoints * (100 + attributes.armorSkill))
	armorLabel.text = str(roundi((1 - damageReduction) * 100))
	attributesLabel.text = attributes.getDescription()


func addAttributes(newAttributes: Attributes) -> void:
	baseAttributes = baseAttributes.add(newAttributes)
	updateAttributes()

func setSelected(toggleOn: bool) -> void:
	isSelected = toggleOn
	# selectedCircle.modulate.a = 1.0 if isSelected else 0.2
	# selectedCircle.modulate = (playerColor+Color.WHITE)*0.5 if isSelected else playerColor
	unitHud.visible = toggleOn
	if not toggleOn:
		talentTreeButton.button_pressed = false
		inventoryButton.button_pressed = false
	if targetUnit:
		targetUnit.setTargeted(toggleOn)

@rpc("any_peer", "call_local")
func setTargetUnitOnClients(targetUnitId: int, follow: bool = false) -> void:
	if multiplayer.is_server():
		setTargetUnit.rpc(targetUnitId, follow)

@rpc("authority", "call_local")
func setTargetUnit(targetUnitId: int, follow: bool = false) -> void:
	if isSelected and targetUnit:  # If is selected and has previous target
		targetUnit.setTargeted(false)  # Remove targetCircle from previous target
	targetUnit = Global.getUnitFromUnitId(targetUnitId)
	if follow:
		followTarget = true
		followCursor = false
	if isSelected:
		targetUnit.setTargeted(true)  # Display targetCircle on new target

func setTargeted(toggleOn: bool) -> void:  # Display/hide TargetCircle. This is only visual.
	if toggleOn:
		if faction == Global.Faction.PLAYERS:
			targetCircle.modulate = Color.GREEN
		elif faction == Global.Faction.ENEMIES:
			targetCircle.modulate = Color.RED
	targetCircle.visible = toggleOn

func _process(_delta: float) -> void:
	healthBar.setValue(health)
	manaBar.setValue(mana)

	if isCasting:
		castBar.value = castTimer.wait_time - castTimer.time_left
	elif isRecovering:
		for abilityButton in getAbilityButtons():
			abilityButton.cooldownProgressBar.value = recoveryTimer.time_left
		if recoveryTimer.is_stopped():
			isRecovering = false
	elif multiplayer.is_server() and isAutocasting:
		useAbilityOnServer(autocastAbilityId)

	if multiplayer.is_server():
		if isCasting:
			state = states.SPELLCASTING
		elif velocity:
			state = states.WALKING
		else:
			state = states.IDLE

	if velocity:
		rotation.y = - Vector2(velocity.x, velocity.z).angle() + PI / 2

	if animationPlayer.current_animation == "Spellcast_Shoot" and animationPlayer.is_playing():
		pass
	elif state == states.SPELLCASTING:
		animationPlayer.play("Spellcasting")
	elif state == states.WALKING:
		animationPlayer.play("Walking_A")
	elif state == states.IDLE:
		animationPlayer.play("Idle")


func orderMove(_destination: Vector3) -> void:
	destination = _destination
	followTarget = false
	followCursor = true

func orderFollowUnit(unit: Unit) -> void:
	targetUnit = unit
	followCursor = false
	followTarget = true


func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		if moveDirection != Vector3.ZERO:
			for i in range(5):
				# This is a hack that allows sliding along the edges of the navigation mesh
				var intended_velocity: Vector3
				if i == 0:
					intended_velocity = moveDirection.normalized() * attributes.speed * attributes.speedRatio
				elif i == 1:
					intended_velocity = moveDirection.normalized().rotated(Vector3.UP, PI/8) * attributes.speed * attributes.speedRatio
				elif i == 2:
					intended_velocity = moveDirection.normalized().rotated(Vector3.UP, -PI/8) * attributes.speed * attributes.speedRatio
				elif i == 3:
					intended_velocity = Vector3(moveDirection.normalized().x, 0, 0) * attributes.speed * attributes.speedRatio
				elif i == 4:
					intended_velocity = Vector3(0, 0, moveDirection.normalized().z) * attributes.speed * attributes.speedRatio

				var intended_position := position + intended_velocity * delta

				var closest_point := NavigationServer3D.map_get_closest_point(navigationAgent.get_navigation_map(), intended_position)

				if intended_position.distance_to(closest_point) < 0.4:
					velocity = intended_velocity
					followCursor = false
					followTarget = false
					break
				else:
					velocity = Vector3.ZERO

		else:
			velocity = Vector3.ZERO


		if followCursor:
			navigationAgent.target_position = destination
		elif followTarget:
			if is_instance_valid(targetUnit):
				navigationAgent.target_position = targetUnit.position
			else:
				followTarget = false

		if (followCursor or followTarget) and navigationAgent.is_target_reachable():
			var destinationNext := navigationAgent.get_next_path_position()

			velocity = position.direction_to(destinationNext).normalized() * attributes.speed * attributes.speedRatio
			navigationAgent.set_velocity(velocity)

			var followRange := 1.5

			if followCursor and Vector2(position.x, position.z).distance_to(Vector2(destination.x, destination.z)) < 0.05:  # Close enough to stop
				velocity = Vector3.ZERO
				followCursor = false
			elif followTarget and position.distance_to(targetUnit.position) < followRange:
				velocity = Vector3.ZERO
		elif moveDirection == Vector3.ZERO:
			velocity = Vector3.ZERO

		if isCasting:
			velocity *= Global.getAbility[castingAbilityId].speedFactorWhileCasting

		move_and_slide()


func damage(_attack: Attack) -> void:
	if _attack.buffs:
		for buff in _attack.buffs:
			var buffIcon := BuffIcon.init(buff)
			buffIcons.add_child(buffIcon)
			buffs.append(buff)
			buff.timer = get_tree().create_timer(buff.duration)
			buff.timer.timeout.connect(func() -> void:
				buffIcons.remove_child(buffIcon)
				buffs.erase(buff)
				updateAttributes()
			)
		updateAttributes()

	if not multiplayer.is_server():
		return

	var HEALING_THREAT_FACTOR := 0.25

	if _attack.isHealing:  #TODO: With healing and damage separated, this should be reworked.
		var healthBefore := health
		health += _attack.healingAmount
		health = clampf(health, 0, attributes.maxHealth)
		if is_instance_valid(_attack.attackingUnit):
			var healingReceived := health - healthBefore
			var awareEnemyUnits: Array[Unit] = _attack.attackingUnit.getAllAwareEnemyUnits()
			for enemyUnit in awareEnemyUnits:
				enemyUnit.addThreat(_attack.attackingUnit, float(healingReceived * HEALING_THREAT_FACTOR) / awareEnemyUnits.size())
	else:
		health -= _attack.damageMelee * damageReduction
		health -= _attack.damageRanged * damageReduction
		health -= _attack.damageMagical * damageReduction
		if is_instance_valid(_attack.attackingUnit):
			addThreat(_attack.attackingUnit, _attack.threat)
		damageSound.play()

	if health <= 0:
		die.rpc()

func addThreat(unit: Unit, amount: float = 0) -> void:
	if not unit in threatTable:
		threatTable[unit] = 0
	threatTable[unit] += amount
	if aiController:
		aiController.recalculateTarget()

func getAllAwareEnemyUnits() -> Array[Unit]:
	var awareEnemyUnits: Array[Unit] = []
	for unit in Global.getAllUnitsNotFaction(faction):
		if self in unit.threatTable:
			awareEnemyUnits.append(unit)
	return awareEnemyUnits


@rpc("call_local")
func die() -> void:
	died.emit()
	if multiplayer.is_server():
		var pickup := Pickup.init(loot)
		pickup.position = position
		call_deferred("add_sibling", pickup, true)
	# var corpse: Corpse = CORPSE.instantiate()
	# corpse.position = position
	# get_parent().add_child(corpse)
	Global.deleteUnit(self)

func spendMana(amount: int) -> void:
	mana -= amount


func equipItemOnServer(itemButton: ItemButton, unEquipSlot: Global.ItemSlots = Global.ItemSlots.None) -> void:
	var nodeIndex := 0
	for node in inventoryContainer.get_children():
		if node == itemButton:
			break
		nodeIndex += 1
	var toggledOn := (false if itemButton.equippedBorder.visible else true)
	equipItemOnClients.rpc(nodeIndex, toggledOn, unEquipSlot)

@rpc("any_peer", "call_local")
func equipItemOnClients(nodeIndex: int, toggledOn: bool, unEquipSlot: Global.ItemSlots) -> void:
	if multiplayer.is_server():
		equipItem.rpc(nodeIndex, toggledOn, unEquipSlot)

@rpc("authority", "call_local")
func equipItem(nodeIndex: int, toggledOn: bool, unEquipSlot: Global.ItemSlots) -> void:
	if unEquipSlot != Global.ItemSlots.None:
		var oldItemButton := equippedItemButtons[unEquipSlot]
		if oldItemButton:
			oldItemButton.setEquipped(false)
			equippedItemButtons[unEquipSlot] = null
			print("Unequipped item %s in slot %s" % [oldItemButton.item.name, unEquipSlot])
			updateAttributes()
		return

	var itemButton := inventoryContainer.get_children()[nodeIndex] as ItemButton
	var item := itemButton.item

	if toggledOn:
		var oldItemButton := equippedItemButtons[item.slot]
		if oldItemButton:
			oldItemButton.setEquipped(false)
		equippedItemButtons[item.slot] = itemButton
		itemButton.setEquipped(true)
		print("Equipped item %s in slot %s" % [item.name, item.slot])
	elif equippedItemButtons[item.slot] == itemButton:
		equippedItemButtons[item.slot] = null
		itemButton.setEquipped(false)
		print("Unequipped item %s in slot %s" % [item.name, item.slot])
	updateAttributes()


@rpc("call_remote")
func giveItem(itemType: Global.Items) -> bool:
	# This method is called normally only on the server, which calls it again on the clients with rpc.
	var item := load("res://resources/items/%s.tres" % Global.Items.find_key(itemType)) as Item

	if multiplayer.is_server():
		giveItem.rpc(itemType)

	var itemButton := ItemButton.init(item, 0)
	inventoryContainer.add_child(itemButton)
	itemButton.drop_item.connect(dropItemOnServer.bind(itemButton))
	itemButton.pressed.connect(equipItemOnServer.bind(itemButton))

	print("Picked up item %s" % item.name)
	return true


func dropItemOnServer(itemButton: ItemButton) -> void:
	var nodeIndex := 0
	for node in inventoryContainer.get_children():
		if node == itemButton:
			break
		nodeIndex += 1

	if equippedItemButtons[itemButton.item.slot] == itemButton:
		equipItemOnClients.rpc(0, false, itemButton.item.slot)

	dropItemOnClients.rpc(nodeIndex)

@rpc("any_peer", "call_local")
func dropItemOnClients(nodeIndex: int) -> void:
	if multiplayer.is_server():
		dropItem.rpc(nodeIndex)

@rpc("authority", "call_local")
func dropItem(nodeIndex: int) -> void:
	var itemButton := inventoryContainer.get_children()[nodeIndex] as ItemButton
	var item := itemButton.item
	inventoryContainer.remove_child(itemButton)

	if multiplayer.is_server():
		var pickup := Pickup.init(item.itemType)
		pickup.position = position + Vector3(2, 0, 0)  # Just a small offset to avoid collision with the unit
		call_deferred("add_sibling", pickup, true)
		print("Dropped item %s" % item.name)


func _on_talent_tree_button_toggled(toggledOn: bool) -> void:
	talentTree.visible = toggledOn
	inventoryPanel.visible = toggledOn
	inventoryButton.button_pressed = toggledOn

func _on_inventory_button_toggled(toggledOn: bool) -> void:
	talentTree.visible = toggledOn
	inventoryPanel.visible = toggledOn
	talentTreeButton.button_pressed = toggledOn


func _on_regen_timer_timeout() -> void:
	health += attributes.healthRegen * regenTimer.wait_time
	health = clampf(health, 0, attributes.maxHealth)
	mana += attributes.manaRegen * regenTimer.wait_time
	mana = clampf(mana, 0, attributes.maxMana)

func _on_cancel_cast_button_pressed() -> void:
	print("Cancel cast")
	if isCasting:
		castTimer.stop()
		castBar.visible = false
		isCasting = false
		cancelCastButton.visible = false
		Global.getAbility[castingAbilityId].refundCost(self)


func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event.is_action_pressed("mouse_left_click"):
		Global.getPlayerCurrent().setTargetUnit(self, false)
	elif event.is_action_pressed("mouse_right_click"):
		Global.getPlayerCurrent().setTargetUnit(self, true)


func _on_mouse_entered() -> void:
	selectedCircle.modulate = (playerColor + 2*Color.WHITE) / 3
	if aiController and Global.getPlayerCurrent().getSelectedUnit() not in threatTable.keys():
		# Show the AI detection area only if the AI is not already aware of the player unit.
		aiController.visible = true

func _on_mouse_exited() -> void:
	selectedCircle.modulate = playerColor
	if aiController:
		aiController.visible = false

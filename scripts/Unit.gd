class_name Unit
extends CharacterBody3D

signal died
signal ressurected

enum State {
	IDLE,
	WALKING,
	ATTACKING,
	SPELLCASTING,
}

@export var unitId: int
@export var faction := Global.Faction.ENEMIES
@export var loot: Array[Item.Id]
@export var playerColor := Color.DIM_GRAY
@export var baseAttributes: Attributes

@export var unitName: String = ""
@export var level: int = 1 # Only relevant for enemies for now
@export var health: float = 75
@export var mana: float = 40
@export var state := State.IDLE
@export var aiController: AiController

# Attributes
var damageReduction: float = 0
var attributes: Attributes
var moveDirection := Vector3.ZERO

var targetUnit: Unit = null
var castTargetUnit: Unit = null

var isSelected := false
var followCursor := false
var followTarget := false
var isCasting := false
var castingAbilityId: Ability.Id
var queuedAbilityIds: Array[Ability.Id] = []
var isRecovering := false
var canRegenMana := true
var isAutocasting := false
var autocastAbilityId: Ability.Id
var isDead := false

var threatTable: Dictionary[Unit, float] = { }
var buffs: Array[Buff] = []

var equippedItemButtons: Dictionary[Item.Slot, ItemButton] = {
	Item.Slot.MAIN_HAND: null,
	Item.Slot.OFF_HAND: null,
	Item.Slot.HEAD: null,
	Item.Slot.TORSO: null,
}
var talentPoints: float = 0

@onready var characterModel: CharacterModel = $CharacterModel
@onready var animationPlayer: AnimationPlayer = characterModel.animationPlayer
@onready var selectedCircle: Sprite3D = $SelectedCircle
@onready var targetCircle: Sprite3D = $TargetCircle
@onready var rangeCircle: MeshInstance3D = $RangeCircle
@onready var rangeCircleMesh: SphereMesh = rangeCircle.mesh
@onready var healthBar: EnergyBar = %HealthBar
@onready var manaBar: EnergyBar = %ManaBar
@onready var castBar: CastBar = %CastBar
@onready var navigationAgent: NavigationAgent3D = $NavigationAgent
@onready var label: Label = %Label
@onready var armorLabel: Label = %ArmorLabel
@onready var castTimer: Timer = $CastTimer
@onready var recoveryTimer: Timer = $RecoveryTimer
@onready var regenTimer: Timer = $RegenTimer
@onready var unitHud: CanvasLayer = $UnitHud
@onready var talentTree: Panel = $UnitHud/TalentTree
@onready var talentTreeButton: Button = %TalentTreeButton
@onready var talentTreeButtons: Control = %TalentButtons
@onready var cancelCastButton: TextureButton = %CancelCastButton
@onready var abilityButtonsContainer: HBoxContainer = %AbilityButtonsContainer
@onready var queuedAbilitiesContainer: HBoxContainer = %QueuedAbilitiesContainer
@onready var buffIcons: HBoxContainer = %BuffIcons
@onready var inventoryButton: Button = %InventoryButton
@onready var inventoryPanel: Panel = %InventoryPanel
@onready var inventoryContainer: GridContainer = %InventoryContainer
@onready var attributesLabel: Label = %AttributesLabel
@onready var labelTalentPoints: Label = %LabelTalentPoints

# Audio
@onready var audioPlayerWalking: AudioStreamPlayer3D = $AudioPlayerWalking
@onready var audioPlayerCasting: AudioStreamPlayer3D = $AudioPlayerCasting

@onready var destination: Vector3


func _ready() -> void:
	if multiplayer.is_server():
		unitId = randi()
		regenTimer.start()
	print("unit _ready   player %s  unit %s  unitId %s" % [multiplayer.get_unique_id(), get_instance_id(), unitId])

	self.add_to_group("units")

	updateAttributes()

	health = attributes.maxHealth
	mana = attributes.maxMana

	if unitName == "":
		unitName = "Unit #" + str(randi_range(1, 99))
	label.text = unitName

	var nodeIndex := 0
	for node in talentTreeButtons.get_children():
		if node is TalentAttributeButton:
			var talentAttributeButton := node as TalentAttributeButton
			talentAttributeButton.pressed.connect(learnTalentAttributeOnServer.bind(nodeIndex))
		nodeIndex += 1

	nodeIndex = 0
	for node in talentTreeButtons.get_children():
		if node is TalentAbilityButton:
			var talentAbilityButton := node as TalentAbilityButton
			talentAbilityButton.pressed.connect(learnTalentAbilityOnServer.bind(nodeIndex))
			talentAbilityButton.mouse_entered.connect(setRangeCircle.bind(talentAbilityButton.ability.targetRange))
			talentAbilityButton.mouse_exited.connect(setRangeCircle.bind(0))
		nodeIndex += 1

	nodeIndex = 1
	for abilityButton in getAbilityButtons():
		abilityButton.hotkeyLabel.text = str(nodeIndex) if nodeIndex <= 9 else ""
		nodeIndex += 1

	selectedCircle.modulate = playerColor

	unitHud.visible = isSelected
	talentTree.visible = talentTreeButton.button_pressed
	inventoryPanel.visible = inventoryButton.button_pressed


func _process(_delta: float) -> void:
	healthBar.setValue(health)
	manaBar.setValue(mana)

	if isCasting:
		castBar.value = castTimer.wait_time - castTimer.time_left
	elif isRecovering:
		castBar.value = recoveryTimer.time_left
	elif multiplayer.is_server() and queuedAbilityIds.size() > 0:
		dequeueAbilityOnServer()
	elif multiplayer.is_server() and isAutocasting:
		useAbilityOnServer(autocastAbilityId)

	if multiplayer.is_server():
		if isCasting:
			state = State.SPELLCASTING
		elif velocity:
			state = State.WALKING
		else:
			state = State.IDLE

	if velocity:
		rotation.y = -Vector2(velocity.x, velocity.z).angle() + PI / 2
		if not audioPlayerWalking.is_playing():
			audioPlayerWalking.play()

	if animationPlayer.current_animation == "Spellcast_Shoot" and animationPlayer.is_playing():
		pass
	elif state == State.SPELLCASTING:
		animationPlayer.play("Spellcasting")
	elif state == State.WALKING:
		animationPlayer.play("Walking_A")
	elif state == State.IDLE:
		animationPlayer.play("Idle")


func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		if moveDirection != Vector3.ZERO:
			for i in range(5):
				# This is a hack that allows sliding along the edges of the navigation mesh
				var intended_velocity: Vector3
				if i == 0:
					intended_velocity = moveDirection.normalized() * attributes.speed * attributes.speedRatio
				elif i == 1:
					intended_velocity = moveDirection.normalized().rotated(Vector3.UP, PI / 8) * attributes.speed * attributes.speedRatio
				elif i == 2:
					intended_velocity = moveDirection.normalized().rotated(Vector3.UP, -PI / 8) * attributes.speed * attributes.speedRatio
				elif i == 3:
					intended_velocity = Vector3(moveDirection.normalized().x, 0, 0) * attributes.speed * attributes.speedRatio
				elif i == 4:
					intended_velocity = Vector3(0, 0, moveDirection.normalized().z) * attributes.speed * attributes.speedRatio

				var intended_position := position + intended_velocity * delta

				var closest_point := NavigationServer3D.map_get_closest_point(
					navigationAgent.get_navigation_map(),
					intended_position,
				)

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

			if (
				followCursor
				and Vector2(position.x, position.z).distance_to(Vector2(destination.x, destination.z)) < 0.05
			): # Close enough to stop
				velocity = Vector3.ZERO
				followCursor = false
			elif followTarget and position.distance_to(targetUnit.position) < followRange:
				velocity = Vector3.ZERO
		elif moveDirection == Vector3.ZERO:
			velocity = Vector3.ZERO

		if isCasting:
			velocity *= Ability.load(castingAbilityId).speedFactorWhileCasting

		move_and_slide()


func learnTalentAttributeOnServer(nodeIndex: int) -> void:
	if talentPoints >= 1:
		learnTalentAttributeOnClients.rpc(nodeIndex)


func learnTalentAbilityOnServer(nodeIndex: int) -> void:
	if talentPoints >= 1:
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
	var talentAttributeButton := talentTreeButtons.get_children()[nodeIndex] as TalentAttributeButton
	addAttributes(talentAttributeButton.attributes)
	talentAttributeButton.rankUp()
	print("Learned '%s' rank %s" % [talentAttributeButton.talentName, talentAttributeButton.rank])
	giveTalentPoints(-1)
	health = attributes.maxHealth
	mana = attributes.maxMana


@rpc("authority", "call_local")
func learnTalentAbility(nodeIndex: int) -> void:
	var talentAbilityButton := talentTreeButtons.get_children()[nodeIndex] as TalentAbilityButton

	for abilityButton in getAbilityButtons():
		if not abilityButton.ability:
			abilityButton.setAbility(talentAbilityButton.ability, self)
			# Set the first available ability button with the new ability
			break

	talentAbilityButton.rankUp()
	print("Learned '%s' rank %s" % [talentAbilityButton.talentName, talentAbilityButton.rank])
	giveTalentPoints(-1)
	health = attributes.maxHealth
	mana = attributes.maxMana


func getAbilityButtons() -> Array[AbilityButton]:
	var abilityButtons: Array[AbilityButton] = []
	for node in abilityButtonsContainer.get_children():
		if node is AbilityButton:
			abilityButtons.append(node as AbilityButton)
	return abilityButtons


func getSpecificAbilityButton(abilityId: Ability.Id) -> Array[AbilityButton]:
	var abilityButtons := getAbilityButtons()
	return abilityButtons.filter(
		func(abilityButton: AbilityButton) -> bool:
			return abilityButton.ability and abilityButton.ability.abilityId == abilityId,
	)


@rpc("any_peer", "call_local")
func useAbilityOnServer(abilityId: Ability.Id, _targetUnit: Unit = null) -> void:
	if _targetUnit == null:
		_targetUnit = targetUnit
	if _targetUnit == null:
		var ability := Ability.load(abilityId)
		if ability.canTargetSelf:
			_targetUnit = self # Default to targeting self if valid
		else:
			return
	useAbility.rpc(abilityId, _targetUnit.unitId)


@rpc("authority", "call_local")
func useAbility(abilityId: Ability.Id, targetUnitId: int) -> void:
	if isCasting:
		print("Unit %s is already casting" % [unitName])
		return
	if isRecovering:
		print("Unit %s is recovering" % [unitName])
		return

	var _targetUnit := Global.getUnitFromUnitId(targetUnitId)

	var ability := Ability.load(abilityId)

	# Self-Abilities default to targeting self when no other valid target
	if self != _targetUnit and ability.canTargetSelf:
		if self.faction != _targetUnit.faction and !ability.canTargetEnemy:
			_targetUnit = self
		elif self.faction == _targetUnit.faction and !ability.canTargetFriend:
			_targetUnit = self

	if not ability.canUse(self, _targetUnit):
		print(
			"Unit %s cannot use ability %s on unit %s"
			% [unitName, ability.name, _targetUnit.unitName if _targetUnit else "NULL"]
		)
		return

	ability.payCost(self)

	isCasting = true
	audioPlayerCasting.stream = ability.castingAudio
	audioPlayerCasting.play()
	cancelCastButton.visible = true
	castingAbilityId = abilityId
	castTargetUnit = _targetUnit
	castTimer.start(ability.castTime)
	castBar.setToCastMode(ability.name, ability.castTime)
	if ability.manaCost > 0: # Can not regenerate mana while casting Ability with mana cost
		canRegenMana = false
		manaBar.modulate = Color.DARK_GRAY


@rpc("any_peer", "call_local")
func queueAbilityOnServer(abilityId: Ability.Id) -> void:
	queueAbility.rpc(abilityId)


@rpc("authority", "call_local")
func queueAbility(abilityId: Ability.Id) -> void:
	queuedAbilityIds.append(abilityId)
	var queuedAbilityIcon: AbilityIcon = AbilityIcon.init(abilityId)
	queuedAbilitiesContainer.add_child(queuedAbilityIcon, true)
	print("Unit %s queued ability %s" % [unitName, abilityId])


func dequeueAbilityOnServer() -> void:
	dequeueAbilityOnClients.rpc()


@rpc("any_peer", "call_local")
func dequeueAbilityOnClients() -> void:
	if multiplayer.is_server() and not isCasting and not isRecovering:
		dequeueAbility.rpc()


@rpc("authority", "call_local")
func dequeueAbility() -> void:
	var queuedAbilityId := queuedAbilityIds[0]
	queuedAbilityIds.pop_front()
	queuedAbilitiesContainer.get_child(0).queue_free()
	if multiplayer.is_server():
		useAbilityOnServer(queuedAbilityId)


func canUseAbility(abilityId: Ability.Id) -> bool:
	var ability := Ability.load(abilityId)
	return ability.canUse(self, targetUnit)


func toggleAutocastOnServer(abilityId: Ability.Id) -> void:
	toggleAutocastOnClients.rpc(abilityId)


@rpc("any_peer", "call_local")
func toggleAutocastOnClients(abilityId: Ability.Id) -> void:
	if multiplayer.is_server():
		toggleAutocast.rpc(abilityId)


@rpc("authority", "call_local")
func toggleAutocast(abilityId: Ability.Id) -> void:
	if not isAutocasting:
		for abilityButton in getSpecificAbilityButton(abilityId):
			abilityButton.setAutocast(true)
		autocastAbilityId = abilityId
		isAutocasting = true
	elif autocastAbilityId == abilityId:
		for abilityButton in getSpecificAbilityButton(abilityId):
			abilityButton.setAutocast(false)
		isAutocasting = false
	else:
		for abilityButton in getAbilityButtons():
			if abilityButton.ability == null:
				pass
			elif abilityButton.ability.abilityId == abilityId:
				abilityButton.setAutocast(true)
				autocastAbilityId = abilityId
				isAutocasting = true
			else:
				abilityButton.setAutocast(false) # Un-toggle all the other abilities


func setRangeCircle(radius: float) -> void:
	if radius > 0:
		rangeCircleMesh.radius = radius
		rangeCircle.visible = true
	else:
		rangeCircle.visible = false


func updateAttributes() -> void:
	var buffAttributesList: Array[Attributes]
	buffAttributesList.assign(
		buffs.map(
			# This is a workaround because map doesn't support proper typing.
			func(buff: Buff) -> Attributes:
				return buff.attributes,
		)
	)

	var itemAttributesList: Array[Attributes]
	itemAttributesList.assign(
		equippedItemButtons
		.values()
		.map(
			# This is a workaround because map doesn't support proper typing.
			func(itemButton: ItemButton) -> Attributes:
				return itemButton.item.attributes if itemButton and itemButton.item and itemButton.item.attributes else Attributes.new(),
		)
	)

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
	if isSelected and targetUnit: # If is selected and has previous target
		targetUnit.setTargeted(false) # Remove targetCircle from previous target
	targetUnit = Global.getUnitFromUnitId(targetUnitId)
	if follow:
		followTarget = true
		followCursor = false
	if isSelected:
		targetUnit.setTargeted(true) # Display targetCircle on new target


func setTargeted(toggleOn: bool) -> void: # Display/hide TargetCircle. This is only visual.
	if toggleOn:
		if faction == Global.Faction.PLAYERS:
			targetCircle.modulate = Color.GREEN
		elif faction == Global.Faction.ENEMIES:
			targetCircle.modulate = Color.RED
	targetCircle.visible = toggleOn


@rpc("any_peer", "call_local")
func orderMove(_destination: Vector3) -> void:
	destination = _destination
	followTarget = false
	followCursor = true


func orderFollowUnit(unit: Unit) -> void:
	targetUnit = unit
	followCursor = false
	followTarget = true


func damage(_attack: Attack) -> void:
	if _attack.buffs:
		for buff in _attack.buffs:
			var buffIcon := BuffIcon.init(buff)
			buffIcons.add_child(buffIcon)
			buffs.append(buff)
			buff.timer = get_tree().create_timer(buff.duration)
			buff.timer.timeout.connect(
				func() -> void:
					buffIcons.remove_child(buffIcon)
					buffs.erase(buff)
					updateAttributes(),
			)
		updateAttributes()

	if not multiplayer.is_server():
		return

	var HEALING_THREAT_FACTOR := 0.25

	if _attack.isHealing: #TODO: With healing and damage separated, this should be reworked.
		var healthBefore := health
		health += _attack.healingAmount
		health = clampf(health, 0, attributes.maxHealth)
		if is_instance_valid(_attack.attackingUnit):
			var healingReceived := health - healthBefore
			var awareEnemyUnits: Array[Unit] = _attack.attackingUnit.getAllAwareEnemyUnits()
			for enemyUnit in awareEnemyUnits:
				enemyUnit.addThreat(
					_attack.attackingUnit,
					float(healingReceived * HEALING_THREAT_FACTOR) / awareEnemyUnits.size(),
				)
	else:
		health -= _attack.damageMelee * damageReduction
		health -= _attack.damageRanged * damageReduction
		health -= _attack.damageMagical * damageReduction
		if is_instance_valid(_attack.attackingUnit):
			addThreat(_attack.attackingUnit, _attack.threat)

	if health <= 0 and not isDead:
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
	isDead = true
	set_process(false)
	set_physics_process(false)
	if aiController:
		aiController.set_process(true)
	healthBar.setValue(0)
	if aiController:
		aiController.set_process(false)

	died.emit()

	if multiplayer.is_server():
		_on_cancel_cast_button_pressed()
		for item in loot:
			var pickup := Pickup.init(item)
			pickup.position = position
			call_deferred("add_sibling", pickup, true)

	animationPlayer.play("Death_A")


@rpc("call_local")
func ressurect() -> void:
	isDead = false
	set_process(true)
	set_physics_process(true)
	if aiController:
		aiController.set_process(true)
	ressurected.emit()
	animationPlayer.play("Lie_StandUp") #TODO: This is immediately overwritten by Idle in _process. Add a delay?


func spendMana(amount: int) -> void:
	mana -= amount


func equipItemOnServer(itemButton: ItemButton, unEquipSlot: Item.Slot = Item.Slot.NONE) -> void:
	var nodeIndex := 0
	for node in inventoryContainer.get_children():
		if node == itemButton:
			break
		nodeIndex += 1
	var toggledOn := (false if itemButton.equippedBorder.visible else true)
	equipItemOnClients.rpc(nodeIndex, toggledOn, unEquipSlot)


@rpc("any_peer", "call_local")
func equipItemOnClients(nodeIndex: int, toggledOn: bool, unEquipSlot: Item.Slot) -> void:
	if multiplayer.is_server():
		equipItem.rpc(nodeIndex, toggledOn, unEquipSlot)


@rpc("authority", "call_local")
func equipItem(nodeIndex: int, toggledOn: bool, unEquipSlot: Item.Slot) -> void:
	if unEquipSlot != Item.Slot.NONE:
		var oldItemButton := equippedItemButtons[unEquipSlot]
		if oldItemButton:
			oldItemButton.setEquipped(false)
			equippedItemButtons[unEquipSlot] = null
			characterModel.unEquipItemSlot(unEquipSlot)
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
		characterModel.equipItem(item)
		print("Equipped item %s in slot %s" % [item.name, item.slot])
	elif equippedItemButtons[item.slot] == itemButton:
		equippedItemButtons[item.slot] = null
		itemButton.setEquipped(false)
		characterModel.unEquipItemSlot(item.slot)
		print("Unequipped item %s in slot %s" % [item.name, item.slot])
	updateAttributes()


@rpc("call_remote")
func giveItem(itemId: Item.Id) -> bool:
	# This method is called normally only on the server, which calls it again on the clients with rpc.
	var item := Item.load(itemId)

	if multiplayer.is_server():
		giveItem.rpc(itemId)

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
		var pickup := Pickup.init(item.itemId)
		pickup.position = position + Vector3(2, 0, 0) # Just a small offset to avoid collision with the unit
		call_deferred("add_sibling", pickup, true)
		print("Dropped item %s" % item.name)


@rpc("any_peer", "call_local")
func cancelCastOnClients() -> void:
	if multiplayer.is_server():
		cancelCast.rpc()


@rpc("authority", "call_local")
func cancelCast() -> void:
	if isCasting:
		castTimer.stop()
		castBar.visible = false
		isCasting = false
		audioPlayerCasting.stop()
		cancelCastButton.visible = false
		Ability.load(castingAbilityId).refundCost(self)
		canRegenMana = true
		manaBar.modulate = Color.WHITE


func giveTalentPointsOnServer(amount: float) -> void:
	giveTalentPointsOnClients.rpc(amount)


@rpc("any_peer", "call_local")
func giveTalentPointsOnClients(amount: float) -> void:
	if multiplayer.is_server():
		giveTalentPoints.rpc(amount)


@rpc("authority", "call_local")
func giveTalentPoints(amount: float) -> void:
	talentPoints += amount
	labelTalentPoints.text = "Talent Points: %d" % talentPoints


func _on_cast_timer_timeout() -> void:
	animationPlayer.play("Spellcast_Shoot")
	isCasting = false
	audioPlayerCasting.stop()
	cancelCastButton.visible = false

	var ability := Ability.load(castingAbilityId)
	var success := (
		false
		if (castTargetUnit == null or not is_instance_valid(castTargetUnit))
		else ability.use(self, castTargetUnit)
	)

	if success:
		isRecovering = true
		for abilityButton in getAbilityButtons():
			if abilityButton.ability == null:
				pass
			elif abilityButton.ability.abilityId == ability.abilityId:
				abilityButton.startCooldown(maxf(ability.cooldownTime, ability.recoveryTime))
			else:
				abilityButton.startCooldown(ability.recoveryTime)
		recoveryTimer.start(ability.recoveryTime)
		print("Unit %s ability %s on unit %s" % [unitName, ability.name, targetUnit.unitName if targetUnit else "NULL"])
		castBar.setToRecoveryMode(ability.recoveryTime)
	else:
		ability.refundCost(self)
		print(
			"Unit %s failed to use ability %s on unit %s"
			% [unitName, ability.name, targetUnit.unitName if targetUnit else "NULL"]
		)


func _on_recovery_timer_timeout() -> void:
	isRecovering = false
	canRegenMana = true
	manaBar.modulate = Color.WHITE
	castBar.visible = false


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

	if canRegenMana:
		mana += attributes.manaRegen * regenTimer.wait_time
	mana = clampf(mana, 0, attributes.maxMana)


func _on_cancel_cast_button_pressed() -> void:
	print("Canceled cast for unit %s" % unitName)
	if isCasting:
		cancelCastOnClients.rpc_id(1)


func _on_input_event(
	_camera: Node,
	event: InputEvent,
	_event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int,
) -> void:
	if event.is_action_pressed("mouse_left_click"):
		Global.getPlayerCurrent().setTargetUnit(self, false)
	elif event.is_action_pressed("mouse_right_click"):
		Global.getPlayerCurrent().setTargetUnit(self, true)


func _on_mouse_entered() -> void:
	selectedCircle.modulate = (playerColor + 2 * Color.WHITE) / 3
	if aiController and Global.getPlayerCurrent().getSelectedUnit() not in threatTable.keys():
		# Show the AI detection area only if the AI is not already aware of the player unit.
		aiController.visible = true


func _on_mouse_exited() -> void:
	selectedCircle.modulate = playerColor
	if aiController:
		aiController.visible = false

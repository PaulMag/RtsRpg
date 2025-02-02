extends CharacterBody2D

class_name Unit


var CORPSE := preload("res://scenes/Corpse.tscn")

@export var unitId : int
@export var faction := Global.Faction.ENEMIES
@export var isAi := false
@export var weapons: Array[Weapon]
@export var weaponSlotEquipped := 0
@export var loot := Global.Items.Bow
@export var playerColor := Color.WHITE

# Attributes
var damageReduction: float = 0
var attributes: Attributes
@export var attributesList: Array[Attributes]

const FACING_MAPPING = {
	1: "right",
	2: "down",
	3: "left",
	4: "up",
}
enum states {
	IDLE,
	WALKING,
	ATTACKING,
}

@export var unitName: String = ""

@export var health: float = 75
@export var mana: float = 40
@export var facing := 2;
@export var state := states.IDLE

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var selectedCircle: Sprite2D = $SelectedCircle
@onready var targetCircle: Sprite2D = $TargetCircle
@onready var healthBar: EnergyBar  = $ProgressBars/HealthBar
@onready var manaBar: EnergyBar  = $ProgressBars/ManaBar
@onready var navigationAgent: NavigationAgent2D = $NavigationAgent2D
@onready var aiController: AiController = $AiController
@onready var rangeField: Area2D = $RangeField
@onready var label: Label = $Label
@onready var damageSound: AudioStreamPlayer2D = $DamageSound
@onready var recoveryTimer: Timer = $RecoveryTimer
@onready var regenTimer: Timer = $RegenTimer
@onready var unitHud: CanvasLayer = $UnitHud
@onready var talentTree: Panel = $UnitHud/TalentTree
@onready var talentTreeButton: Button = $UnitHud/TalentTreeButton
@onready var talentTreeAttributeButtons: Control = $UnitHud/TalentTree/TalentAttributeButtons
@onready var talentTreeAbilityButtons: Control = $UnitHud/TalentTree/TalentAbilityButtons
@onready var abilityButtonsContainer: HBoxContainer = $UnitHud/AbilityButtonsContainer

@onready var destination : Vector2 = position
var moveDirection := Vector2.ZERO

@export var targetUnit: Unit = null

var followCursor := false
var followTarget := false
var isRecovering := false
var isAutocasting := false
var autocastAbilityId: Global.AbilityIds

var threatTable: Dictionary = {}


func _ready() -> void:
	sprite.self_modulate = playerColor
	if multiplayer.is_server():
		unitId = randi()
		regenTimer.start()
	print("unit _ready   player %s  unit %s  unitId %s" % [multiplayer.get_unique_id(), get_instance_id(), unitId])

	self.add_to_group("units")
	if faction != Global.Faction.PLAYERS:
		isAi = true

	if isAi:
		var a := Attributes.new()  #TODO: This is just here until proper starting attributes are defined.
		a.speed = 150
		addAttributes(a)
	else:
		attributesList = []
		var a := Attributes.new()  #TODO: This is just here until proper starting attributes are defined.
		a.maxHealth = 10
		# a.maxMana = 100
		a.armorSkill = 100
		a.speed = 150
		addAttributes(a)
	updateAttributes()

	health = attributes.maxHealth
	mana = attributes.maxMana

	if unitName == "":
		unitName = "Unit #" + str(randi_range(1, 99))
	if not isAi:
		aiController.queue_free()
		remove_child(aiController)

	var nodeIndex := 0
	for node in talentTreeAttributeButtons.get_children():
		if node is TalentAttributeButton:
			var talentAttributeButton := node as TalentAttributeButton
			talentAttributeButton.pressed.connect(learnTalentAttributeOnClients.bind(nodeIndex))
		nodeIndex += 1

	nodeIndex = 0
	for node in talentTreeAbilityButtons.get_children():
		if node is TalentAbilityButton:
			var talentAbilityButton := node as TalentAbilityButton
			talentAbilityButton.pressed.connect(learnTalentAbilityOnClients.bind(nodeIndex))
		nodeIndex += 1

func learnTalentAttributeOnClients(nodeIndex: int) -> void:
	learnTalentAttribute.rpc(nodeIndex)

func learnTalentAbilityOnClients(nodeIndex: int) -> void:
	learnTalentAbility.rpc(nodeIndex)

@rpc("any_peer", "call_local")
func learnTalentAttribute(nodeIndex: int) -> void:
	var talentAttributeButton := talentTreeAttributeButtons.get_children()[nodeIndex] as TalentAttributeButton
	addAttributes(talentAttributeButton.attributes)
	talentAttributeButton.rankUp()
	print("Learned '%s' rank %s" % [talentAttributeButton.talentName, talentAttributeButton.rank])

@rpc("any_peer", "call_local")
func learnTalentAbility(nodeIndex: int) -> void:
	var talentAbilityButton := talentTreeAbilityButtons.get_children()[nodeIndex] as TalentAbilityButton

	var newAbilityButton := AbilityButton.init(talentAbilityButton.ability)
	newAbilityButton.pressed.connect(useAbilityOnClients.bind(newAbilityButton.ability.abilityId))
	newAbilityButton.toggle_autocast.connect(toggleAutocastOnClients.bind(newAbilityButton.ability.abilityId))
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

func useAbilityOnClients(abilityId: Global.AbilityIds, _targetUnit: Unit = null) -> void:
	if _targetUnit == null:
		_targetUnit = targetUnit
	if _targetUnit == null:
		return
	useAbility.rpc(abilityId, _targetUnit.unitId)

@rpc("any_peer", "call_local")
func useAbility(abilityId: Global.AbilityIds, targetUnitId: int) -> void:
	if isRecovering:
		print("Unit %s is recovering" % [unitName])
		return

	var _targetUnit := Global.getUnitFromUnitId(targetUnitId)

	var ability := Global.getAbility[abilityId]

	var success := ability.use(self, _targetUnit)
	if faction == Global.Faction.ENEMIES:
		print("Unit %s %s ability %s on unit %s"
			% [unitName, "used" if success else "failed to use", ability.name, _targetUnit.unitName if _targetUnit else "NULL"])

	if success:
		isRecovering = true
		for abilityButton in getAbilityButtons():
			abilityButton.cooldownProgressBar.max_value = ability.recoveryTime
			abilityButton.cooldownProgressBar.value = ability.recoveryTime
		recoveryTimer.start(ability.recoveryTime)

func canUseAbility(abilityId: Global.AbilityIds) -> bool:
	var ability := Global.getAbility[abilityId]
	return ability.canUse(self, targetUnit)

func toggleAutocastOnClients(abilityId: Global.AbilityIds) -> void:
	toggleAutocast.rpc(abilityId)

@rpc("any_peer", "call_local")
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
	attributes = Attributes.sum(attributesList)
	healthBar.setMaxValue(attributes.maxHealth)
	manaBar.setMaxValue(attributes.maxMana)
	damageReduction = 10_000. / (10_000. + attributes.armorPoints * attributes.armorSkill)

func addAttributes(newAttributes: Attributes) -> void:
	attributesList.append(newAttributes)
	updateAttributes()

func setSelected(toggleOn: bool) -> void:
	selectedCircle.visible = toggleOn
	if toggleOn and getEquippedWeapon():
		viewRangeField(getEquippedWeapon().attackRange, Color(0, 0.5, 1))
	else:
		hideRangeField()
	unitHud.visible = toggleOn
	if not toggleOn:
		talentTreeButton.button_pressed = false
	if targetUnit:
		targetUnit.setTargeted(toggleOn)

@rpc("any_peer", "call_local")
func setTargetUnit(targetUnitId: int, follow: bool = false) -> void:
	if selectedCircle.visible and targetUnit:  # If is selected and has previous target
		targetUnit.setTargeted(false)  # Remove targetCircle from previous target
	targetUnit = Global.getUnitFromUnitId(targetUnitId)
	if follow:
		followTarget = true
		followCursor = false
	if selectedCircle.visible:
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

	if isRecovering:
		for abilityButton in getAbilityButtons():
			abilityButton.cooldownProgressBar.value = recoveryTimer.time_left
		if recoveryTimer.is_stopped():
			isRecovering = false
	elif multiplayer.is_server() and isAutocasting:
		useAbilityOnClients(autocastAbilityId)

	if multiplayer.is_server():
		if state == states.ATTACKING:
			pass
		elif velocity:
			state = states.WALKING
		else:
			state = states.IDLE

	if abs(velocity.x) >= abs(velocity.y):
		if velocity.x > 0:
			facing = 1
		elif velocity.x < 0:
			facing = 3
	elif abs(velocity.y) > abs(velocity.x):
		if velocity.y < 0:
			facing = 4
		elif velocity.y > 0:
			facing = 2

	if state == states.ATTACKING:
		sprite.animation = "attack_" + FACING_MAPPING[facing]
	elif state == states.WALKING:
		sprite.animation = "walk_" + FACING_MAPPING[facing]
	elif state == states.IDLE:
		sprite.animation = "idle_" + FACING_MAPPING[facing]

	label.text = (
		"Player: %s\n%s\n%s\n" % [
			unitName,
			str(state),
			(getEquippedWeapon().name if getEquippedWeapon() else "no weapon")
		]
	)

func viewRangeField(radius: float, color: Color) -> void:
	rangeField.scale = float(radius) / 320. * Vector2.ONE
	rangeField.modulate = color
	rangeField.visible = true

func hideRangeField() -> void:
	rangeField.visible = false

func orderMove(_destination: Vector2) -> void:
	destination = _destination
	followTarget = false
	followCursor = true

func orderFollowUnit(unit: Unit) -> void:
	targetUnit = unit
	followCursor = false
	followTarget = true

func _physics_process(_delta: float) -> void:
	if multiplayer.is_server():
		if moveDirection != Vector2.ZERO:
			velocity = moveDirection.normalized() * attributes.speed
			navigationAgent.set_velocity(velocity)
			followCursor = false
			followTarget = false
			print(velocity)

		if followCursor:
			navigationAgent.target_position = destination
		elif followTarget:
			if is_instance_valid(targetUnit):
				navigationAgent.target_position = targetUnit.position
			else:
				followTarget = false

		if (followCursor or followTarget) and navigationAgent.is_target_reachable():
			var destinationNext := navigationAgent.get_next_path_position()

			velocity = position.direction_to(destinationNext).normalized() * attributes.speed
			navigationAgent.set_velocity(velocity)

			var followRange := 50

			if followCursor and position.distance_to(destination) < 15:
				velocity = Vector2.ZERO
				followCursor = false
			elif followTarget and position.distance_to(targetUnit.position) < followRange:
				velocity = Vector2.ZERO
		elif moveDirection == Vector2.ZERO:
			velocity = Vector2.ZERO

		move_and_slide()

func damage(_attack: Attack) -> void:
	if not multiplayer.is_server():
		return

	if _attack.isHealing:  #TODO: With healing and damage separated, this should be reworked.
		var healthBefore := health
		health += _attack.healingAmount
		health = clampf(health, 0, attributes.maxHealth)
		if is_instance_valid(_attack.attackingUnit):
			var healingReceived := health - healthBefore
			var awareEnemyUnits: Array[Unit] = _attack.attackingUnit.getAllAwareEnemyUnits()
			for enemyUnit in awareEnemyUnits:
				enemyUnit.addThreat(_attack.attackingUnit, float(healingReceived) / awareEnemyUnits.size())
	else:
		health -= _attack.damagePhysical * damageReduction
		health -= _attack.damageMagical * damageReduction
		addThreat(_attack.attackingUnit, _attack.threat)
		damageSound.play()

	if health <= 0:
		die.rpc()

func addThreat(unit: Unit, amount: float = 0) -> void:
	if not unit in threatTable:
		threatTable[unit] = 0
	threatTable[unit] += amount
	if isAi:
		aiController.recalculateTarget()

func getAllAwareEnemyUnits() -> Array[Unit]:
	var awareEnemyUnits: Array[Unit] = []
	for unit in Global.getAllUnitsNotFaction(faction):
		if self in unit.threatTable:
			awareEnemyUnits.append(unit)
	return awareEnemyUnits


@rpc("call_local")
func die() -> void:
	if multiplayer.is_server():
		var pickup := Pickup.init(loot)
		pickup.position = position
		call_deferred("add_sibling", pickup, true)
	var corpse: Corpse = CORPSE.instantiate()
	corpse.position = position
	get_parent().add_child(corpse)
	Global.deleteUnit(self)

func spendMana(amount: int) -> void:
	mana -= amount

@rpc("call_remote")
func giveItem(itemType: Global.Items) -> bool:
	# This method is called normally only on the server, which calls it again on the clients with rpc.
	var item := load("res://resources/items/%s.tres" % Global.Items.find_key(itemType)) as Item

	if not item is Weapon:  # Only support for Weapon type so far
		return false
	if weapons.size() >= 4:  # Inventory is full
		return false

	if multiplayer.is_server():
		giveItem.rpc(itemType)

	weapons.append(item)
	update.rpc()
	return true

func equip(slot: int) -> void:
	weaponSlotEquipped = slot
	update.rpc()
	if getEquippedWeapon():
		viewRangeField(getEquippedWeapon().attackRange, Color(0, 0.5, 1))

func get_weapon(slot: int) -> Weapon:
	if slot == 0:
		return null
	elif slot > weapons.size():
		return null
	else:
		return weapons[slot - 1]

func getEquippedWeapon() -> Weapon:
	return get_weapon(weaponSlotEquipped)

var isBeingUpdated := false

@rpc("call_local")
func update() -> void:
	isBeingUpdated = true


func _on_selection_area_mouse_entered() -> void:
	if faction == Global.Faction.PLAYERS:
		sprite.modulate = Color.GREEN
	else:
		sprite.modulate = Color.RED
		if isAi:
			viewRangeField(320, Color.RED)

func _on_selection_area_mouse_exited() -> void:
	sprite.modulate = Color.WHITE
	if faction != Global.Faction.PLAYERS:
		hideRangeField()

func _on_talent_tree_button_toggled(toggled_on: bool) -> void:
	talentTree.visible = toggled_on

func _on_regen_timer_timeout() -> void:
	health += attributes.healthRegen * regenTimer.wait_time
	health = clampf(health, 0, attributes.maxHealth)
	mana += attributes.manaRegen * regenTimer.wait_time
	mana = clampf(mana, 0, attributes.maxMana)

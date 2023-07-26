extends CharacterBody2D

class_name Unit


var PROJECTILE = preload("res://projectiles/Bullet.tscn")
var CORPSE = preload("res://units/corpse/Corpse.tscn")

@export var faction := Global.Faction.ENEMIES
@export var isAi := false
@export var weapons: Array[Weapon]
@export var weaponSlotEquipped := 0

const SPEED := 150.0
const ATTACK_RANGE := 30
const HEALTH_MAX := 100
const MANA_MAX := 50

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

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var selectedCircle : Sprite2D = $SelectedCircle
@onready var healthBar :TextureProgressBar  = $ProgressBars/HealthBar
@onready var manaBar :TextureProgressBar  = $ProgressBars/ManaBar
@onready var destination : Vector2 = position
@onready var aiController : Node = $AiController
@onready var rangeField : Area2D = $RangeField

@export var targetUnit: Unit = null


var followCursor := false
var followTarget := false

var threatTable: Dictionary = {}


func _ready():
	self.add_to_group("units")
	if faction != Global.Faction.PLAYERS:
		isAi = true

	healthBar.max_value = HEALTH_MAX
	healthBar.value = health
	manaBar.max_value = MANA_MAX
	manaBar.value = mana

	if unitName == "":
		unitName = "Unit #" + str(randi_range(1, 99))
	if not isAi:
		aiController.queue_free()
		remove_child(aiController)

func setSelected(flag: bool):
	selectedCircle.modulate = Color.GREEN
	selectedCircle.visible = flag
	if flag and getEquippedWeapon():
		viewRangeField(getEquippedWeapon().attackRange, Color(0, 0.5, 1))
	else:
		hideRangeField()

func setTargeted(flag: bool):
	selectedCircle.modulate = Color.RED
	selectedCircle.visible = flag

func _process(_delta: float):
	healthBar.value = health
	manaBar.value = mana

	if is_multiplayer_authority():
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

	$Label.text = (
		"Player: %s\n%s\n%s\n%s\n" % [
			(str(getPlayer().playerId) if getPlayer() else "none"),
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

func getPlayer() -> ServerPlayer:
	for player in Global.getPlayers():
		if self in player.getUnits():
			return player
	return null

func orderMove(_destination: Vector2):
	destination = _destination
	followTarget = false
	followCursor = true

func orderAttack(unit: Unit) -> void:
	targetUnit = unit
	followCursor = false
	followTarget = true

	destination = targetUnit.position

func _physics_process(_delta: float):

	if is_multiplayer_authority():

		if followCursor:
			$NavigationAgent2D.target_position = destination
		elif followTarget:
			if is_instance_valid(targetUnit):
				$NavigationAgent2D.target_position = targetUnit.position
			else:
				followTarget = false

		if (followCursor or followTarget) and $NavigationAgent2D.is_target_reachable():
			var destinationNext = $NavigationAgent2D.get_next_path_position()

			velocity = position.direction_to(destinationNext).normalized() * SPEED
			$NavigationAgent2D.set_velocity(velocity)

			var followRange = getEquippedWeapon().attackRange if getEquippedWeapon() else 50

			if followCursor and position.distance_to(destination) < 15:
				velocity = Vector2.ZERO
				followCursor = false
			elif followTarget and position.distance_to(targetUnit.position) < followRange:
				velocity = Vector2.ZERO
				followTarget = false
		else:
			pass

		move_and_slide()

		if (state == states.IDLE
			and getEquippedWeapon() != null
			and targetUnit != null
			and targetUnit != self
			and position.distance_to(targetUnit.position) <= getEquippedWeapon().attackRange
		):
			attack()

func damage(_attack: Attack):
	if _attack.isHealing:
		var healthBefore = health
		health += _attack.damage
		health = clampf(health, 0, HEALTH_MAX)
		if is_instance_valid(_attack.attackingUnit):
			var healingReceived = health - healthBefore
			var awareEnemyUnits: Array[Unit] = _attack.attackingUnit.getAllAwareEnemyUnits()
			for enemyUnit in awareEnemyUnits:
				enemyUnit.addThreat(_attack.attackingUnit, float(healingReceived) / awareEnemyUnits.size())
	else:
		health -= _attack.damage
		addThreat(_attack.attackingUnit, _attack.damage)
		$DamageSound.play()

	if health <= 0:
		die.rpc()

func addThreat(unit: Unit, amount: float = 0) -> void:
	if not unit in threatTable:
		threatTable[unit] = 0
	threatTable[unit] += amount

func getAllAwareEnemyUnits() -> Array[Unit]:
	var awareEnemyUnits: Array[Unit] = []
	for unit in Global.getAllUnitsNotFaction(faction):
		if self in unit.threatTable:
			awareEnemyUnits.append(unit)
	return awareEnemyUnits


@rpc("call_local")
func die() -> void:
	var corpse = CORPSE.instantiate()
	corpse.position = position
	get_parent().add_child(corpse)
	queue_free()

func attack():
	if getEquippedWeapon() == null:
		return
	if position.distance_to(targetUnit.position) > getEquippedWeapon().attackRange:
		return
	if getEquippedWeapon().manaCost > mana:
		return
	if not ((getEquippedWeapon().canTargetFriendly and targetUnit.faction == faction)
			or (getEquippedWeapon().canTargetEnemy and targetUnit.faction != faction)
		):
		return
	state = states.ATTACKING
	spendMana(getEquippedWeapon().manaCost)
	$AttackTimer.start()
	var newProjectile = PROJECTILE.instantiate() as Bullet
	newProjectile.position = position
	newProjectile.attackingUnit = self
	newProjectile.target = targetUnit
	newProjectile.damage = getEquippedWeapon().damage
	newProjectile.isHealing = getEquippedWeapon().isHealing
	newProjectile.speed = getEquippedWeapon().bulletSpeed
	get_parent().get_parent().add_child(newProjectile)
	newProjectile.sprite.set_texture(getEquippedWeapon().bulletTexture)

func spendMana(amount: int) -> void:
	mana -= amount

func _on_attack_timer_timeout():
	state = states.IDLE

func giveItem(item: Item) -> bool:
	if not item is Weapon:  # Only support for Weapon type so far
		return false
	if weapons.size() >= 4:  # Inventory is full
		return false
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
func update():
	isBeingUpdated = true


func _on_selection_area_mouse_entered():
	if getPlayer() == Global.getPlayerCurrent():
		sprite.modulate = Color.GREEN
	elif faction == Global.Faction.PLAYERS:
		sprite.modulate = Color.YELLOW
	else:
		sprite.modulate = Color.RED
		if isAi:
			viewRangeField(320, Color.RED)

func _on_selection_area_mouse_exited():
	sprite.modulate = Color.WHITE
	if faction != Global.Faction.PLAYERS:
		hideRangeField()

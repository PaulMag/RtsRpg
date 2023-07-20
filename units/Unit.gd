extends CharacterBody2D

class_name Unit


var PROJECTILE = preload("res://projectiles/Bullet.tscn")
var AI_CONTROLLER = preload("res://units/AiController.tscn")
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

@export var health : int = 75
@export var mana := 40
@export var facing := 2;
@export var state := states.IDLE

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var selectedCircle : Sprite2D = $SelectedCircle
@onready var healthBar :TextureProgressBar  = $ProgressBars/HealthBar
@onready var manaBar :TextureProgressBar  = $ProgressBars/ManaBar
@onready var destination : Vector2 = position

@export var targetUnit: Unit = null


var followCursor := false
var followTarget := false

var hatedUnits: Dictionary = {}


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
	if isAi:
		add_child(AI_CONTROLLER.instantiate())

func setSelected(flag: bool):
	selectedCircle.modulate = Color.GREEN
	selectedCircle.visible = flag

func setTargeted(flag: bool):
	selectedCircle.modulate = Color.RED
	selectedCircle.visible = flag

func _process(delta: float):
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
		"Player " + str(getPlayer().playerId if getPlayer() else null) + "\n"
		+ unitName + "\n"
		+ str(state) + "\n"
		+ (getEquippedWeapon().name if getEquippedWeapon() else "no weapon")
	)

func getPlayer() -> Player:
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

func _physics_process(delta: float):

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

			var followRange = getEquippedWeapon().range if getEquippedWeapon() else 50

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
			and position.distance_to(targetUnit.position) <= getEquippedWeapon().range
		):
			attack()

func damage(attack: Attack):
	health -= attack.damage
	if isAi:
		if not attack.attackingUnit in hatedUnits:
			hatedUnits[attack.attackingUnit] = 0
		hatedUnits[attack.attackingUnit] += attack.damage
		print(hatedUnits)
	$DamageSound.play()
	health = clampi(health, 0, HEALTH_MAX)
	if health <= 0:
		die.rpc()

@rpc("call_local")
func die() -> void:
	var corpse = CORPSE.instantiate()
	corpse.position = position
	get_parent().add_child(corpse)
	queue_free()

func attack():
	if getEquippedWeapon() == null:
		return
	if position.distance_to(targetUnit.position) > getEquippedWeapon().range:
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
	newProjectile.speed = getEquippedWeapon().bulletSpeed
	get_parent().get_parent().add_child(newProjectile)
	newProjectile.sprite.set_texture(getEquippedWeapon().bulletTexture)

func spendMana(amount: int) -> void:
	mana -= getEquippedWeapon().manaCost

func _on_attack_timer_timeout():
	state = states.IDLE

func equip(slot: int) -> void:
	weaponSlotEquipped = slot
	update.rpc()

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


func _on_mouse_entered():
	modulate = Color.RED


func _on_selection_area_mouse_entered():
	if getPlayer() == Global.getPlayerCurrent():
		sprite.modulate = Color.GREEN
	elif faction == Global.Faction.PLAYERS:
		sprite.modulate = Color.YELLOW
	else:
		sprite.modulate = Color.RED

func _on_selection_area_mouse_exited():
	sprite.modulate = Color.WHITE

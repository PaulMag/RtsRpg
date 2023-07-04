extends CharacterBody2D

class_name Unit

#var PLAYER_UNIT = load("Unit.tscn")
#var PLAYER_UNIT = preload("res://units/Unit.tscn")
#var PLAYER_UNIT = preload("Unit.tscn")

signal selected
signal deselected

@export var PROJECTILE = preload("res://projectiles/Bullet.tscn")
@export var weapons: Array[Weapon]
@export var weaponSlotEquipped := 0

const SPEED = 150.0
const ATTACK_RANGE = 30
const HP_MAX = 100
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

@export var playerId := 1
var player: Player

@export var unitName: String = ""
@export var hp := 75
@export var facing := 2;
var target := self
@export var state := states.IDLE

@export var isSelected := false
@onready var selectedCircle : Sprite2D = $SelectedCircle
@onready var destination : Vector2 = position

@export var targetUnit: Unit = self


var followCursor := false

func _ready():
	self.add_to_group("units")
	selectedCircle.visible = isSelected
	$HealthBar.value = hp
	if unitName == "":
		unitName = "Unit #" + str(randi_range(1, 99))

func set_selected(flag: bool):
	isSelected = flag
	selectedCircle.visible = flag
	if flag:
		emit_signal("selected")
	else:
		emit_signal("deselected")

func _process(delta: float):

	$HealthBar.value = hp

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
		$AnimatedSprite2D.animation = "attack_" + FACING_MAPPING[facing]
	elif state == states.WALKING:
		$AnimatedSprite2D.animation = "walk_" + FACING_MAPPING[facing]
	elif state == states.IDLE:
		$AnimatedSprite2D.animation = "idle_" + FACING_MAPPING[facing]

	$Label.text = (
		"Player " + str(playerId) + "\n"
		+ unitName + "\n"
		+ str(state) + "\n"
		+ (getEquippedWeapon().name if getEquippedWeapon() else "no weapon")
	)


func move_to(_destination: Vector2):
	destination = _destination
	followCursor = true

func _physics_process(delta: float):

	if is_multiplayer_authority():

		if followCursor:
			$NavigationAgent2D.target_position = destination

		if $NavigationAgent2D.is_target_reachable():
			var destinationNext = $NavigationAgent2D.get_next_path_position()

			velocity = position.direction_to(destinationNext).normalized() * SPEED
			$NavigationAgent2D.set_velocity(velocity)

			if position.distance_to(destination) < 15:
				velocity = Vector2.ZERO
				followCursor = false
			else:
				pass
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

func damage(amount: int = 1):
	hp -= amount
	$HealthBar.value = hp
	$DamageSound.play()

func attack():
	if getEquippedWeapon() == null:
		return
	if position.distance_to(targetUnit.position) > getEquippedWeapon().range:
		return
	state = states.ATTACKING
	$AttackTimer.start()
	var newProjectile = PROJECTILE.instantiate() as Bullet
	newProjectile.position = position
	newProjectile.target = targetUnit
	newProjectile.damage = getEquippedWeapon().damage
	newProjectile.speed = getEquippedWeapon().bulletSpeed
	get_parent().get_parent().add_child(newProjectile)
	newProjectile.sprite.set_texture(getEquippedWeapon().bulletTexture)


func _on_attack_timer_timeout():
	state = states.IDLE

func equip(slot: int) -> void:
	weaponSlotEquipped = slot
	if player != null:
		player.drawUnitInventory(self)  #TODO: Do this properly

func get_weapon(slot: int) -> Weapon:
	if slot == 0:
		return null
	elif slot > weapons.size():
		return null
	else:
		return weapons[slot - 1]

func getEquippedWeapon() -> Weapon:
	return get_weapon(weaponSlotEquipped)


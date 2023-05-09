extends CharacterBody2D

var PLAYER_UNIT = load("Unit.tscn")

signal selected
signal deselected

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

@export var playerId = 1

@export var hp = 75
@export var facing = 2;
var target = self
@export var state = states.IDLE

@export var isSelected = false
@onready var selectedCircle = $SelectedCircle
@onready var destination = position
var targetUnit = null

var isAttacking = false
var followCursor = false

func _ready():
	self.add_to_group("units")
	selectedCircle.visible = isSelected
	$HealthBar.value = hp

func set_selected(flag):
	isSelected = flag
	selectedCircle.visible = flag
	if flag:
		emit_signal("selected")
	else:
		emit_signal("deselected")
		

func _input(event):
	
	if is_multiplayer_authority():
	
		if event.is_action_pressed("mouse_right_click"):
			followCursor = true
		elif event.is_action_released("mouse_right_click"):
			followCursor = false
		
		if event.is_action_released("mouse_right_click") and selectedCircle.visible:
			var pos = get_global_mouse_position()
			if pos.distance_to(position) < 20:
				damage(7)


func _process(delta):
	
	$HealthBar.value = hp
	
	if is_multiplayer_authority():
		if velocity:
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
	
	if isAttacking:
		$AnimatedSprite2D.animation = "attack_up"
	elif state == states.WALKING:
		$AnimatedSprite2D.animation = "walk_" + FACING_MAPPING[facing]
	elif state == states.IDLE:
		$AnimatedSprite2D.animation = "idle_" + FACING_MAPPING[facing]

func move_to(_destination):
	destination = _destination
	followCursor = true

func _physics_process(delta):
	
	if is_multiplayer_authority():
	
#	if isSelected:
#		if Input.is_action_pressed("ui_left"):
#			position.x -= delta * SPEED
#		if Input.is_action_pressed("ui_right"):
#			position.x += delta * SPEED
#		if Input.is_action_pressed("ui_up"):
#			position.y -= delta * SPEED
#		if Input.is_action_pressed("ui_down"):
#			position.y += delta * SPEED
	
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
	#	velocity = position.direction_to(destination) * SPEED
	#	if position.distance_to(destination) > 15:
	#		move_and_slide()
	#	else:
	#		pass

func damage(amount=1):
	hp -= amount
	$HealthBar.value = hp
	$DamageSound.play()

func attack(target):
	target.damage()

#	if selected:
#		var direction_x = Input.get_axis("ui_left", "ui_right")
#		var direction_y = Input.get_axis("ui_up", "ui_down")
#		if direction_x:
#			velocity.x = direction_x * SPEED
#		else:
#			velocity.x = move_toward(velocity.x, 0, SPEED)
#		if direction_y:
#			velocity.y = direction_y * SPEED
#		else:
#			velocity.y = move_toward(velocity.y, 0, SPEED)
#
#		move_and_slide()

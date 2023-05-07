extends Node

@export var playerId = 0
@export var direction := Vector2()
@export var selectedUnits = []

@export var isCloning = false


func _ready():
	playerId = name.to_int()
	set_multiplayer_authority(playerId)
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())
#	print("Processing for player %s." % $"..".playerId)
	if multiplayer.is_server():
		print("Player on server: ", playerId, "  '", name, "'  ")
	else:
		print("Player on peer:   ", playerId, "  '", name, "'  ")

func _process(delta):
#	$"..".playerId = multiplayer.get_unique_id()
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
#	if direction:
#		print(playerId, "   ", direction)
	if Input.is_action_just_pressed("ui_cancel"):
		clone.rpc()
		

@rpc("call_local")
func clone():
	isCloning = true





## Backup script for PlayerInput

#@export var direction := Vector2()
#
#func _ready():
#	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())
#	set_multiplayer_authority($"..".playerId)
##	print("Processing for player %s." % $"..".playerId)
#
#func _process(delta):
##	$"..".playerId = multiplayer.get_unique_id()
#	# Get the input direction and handle the movement/deceleration.
#	# As good practice, you should replace UI actions with custom gameplay actions.
#	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
#	if(direction):
#		print($"..".playerId, "   ", direction)

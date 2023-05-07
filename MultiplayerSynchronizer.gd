extends MultiplayerSynchronizer

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

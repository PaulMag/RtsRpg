extends Node

const PLAYER = preload("res://Player.tscn")

const PORT = 4433

func _process(delta):
#	var allPlayersAndMultiplayer = get_tree().get_nodes_in_group("players")
#	var allPlayers = []
#	var first = true
#	for player in allPlayersAndMultiplayer:
#		if not first:
#			allPlayers.append(player.playerId)
#		first = false
#	print(allPlayers)
	var allPlayers = $Players.get_children()
	var allPlayerIds = []
	for player in allPlayers:
		allPlayerIds.append(player.playerId)
#	if randi_range(0, 60) == 0:
#		print(multiplayer.get_unique_id(), "   ", allPlayerIds)

func _ready():
#	get_tree().paused = true
	multiplayer.server_relay = false
	if DisplayServer.get_name() == "headless":
		print("Automatically starting dedicated server.")
		_on_host_pressed.call_deferred()
		
func _on_host_pressed():
	# Start game as server
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server.")
		print("Failed to start multiplayer server.")		
		return
	multiplayer.multiplayer_peer = peer
#	start_game()

func _on_connect_pressed():
	# Start game as client, and join existing host
	var txt : String = $UI/Net/Options/Remote.text
	if txt == "":
		OS.alert("Need a remote to connect to.")
		return
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(txt, PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client.")
		return
	multiplayer.multiplayer_peer = peer
#	start_game()


func start_game():
	
	$UI.hide()
	print("Game started")
	get_tree().paused = false
	
	var playerd2id : int
	
	if multiplayer.is_server():
#		multiplayer.peer_connected.connect(add_player)
		
		for id in multiplayer.get_peers():
			add_player(id)
			print("Added peer player %s." % id)
			playerd2id = id
			
		
		if not OS.has_feature("dedicated_server"):
			add_player(1)
			print("Not dedicated server. Added player 1.")
	
	$"../Dungeon/Units/Unit3".playerId = playerd2id
#	$"../Dungeon/Units/Unit3".set_multiplayer_authority(playerd2id)


func _on_start_game_pressed():
	start_game()

func add_player(id: int):
	var playerNode = PLAYER.instantiate()
	playerNode.playerId = id
	playerNode.name = str(id)
	$Players.add_child(playerNode, true)

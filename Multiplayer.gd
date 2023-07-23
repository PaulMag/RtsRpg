extends Node

const PLAYER = preload("res://Player.tscn")
const PLAYER_LABEL = preload("res://PlayerLabel.tscn")

const PORT = 4433


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
	var txt : String = $UI/Options/Joining/Remote.text
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

	if multiplayer.is_server():
#		multiplayer.peer_connected.connect(add_player)
#		multiplayer.peer_disconnected.connect(delete_player)

		for id in multiplayer.get_peers():
			add_player(id)
			print("Added peer player %s." % id)

		if not OS.has_feature("dedicated_server"):
			add_player(1)
			print("Not dedicated server. Added player 1.")

	var players = Global.getPlayers()
	var i = 0
	for unit in Global.getAllUnits(Global.Faction.PLAYERS):
		players[i].giveUnit(unit)
		i += 1
		i = 0 if i >= players.size() else i

	for player in Global.getPlayers():
		var playerLabelNode = PLAYER_LABEL.instantiate()
		playerLabelNode.playerId = player.playerId
		playerLabelNode.playerName = player.name
		playerLabelNode.playerColor = player.playerColor
		$PanelContainer/PlayerList.add_child(playerLabelNode, true)


func _on_start_game_pressed():
	start_game()

func add_player(id: int):
	var playerNode = PLAYER.instantiate()
	playerNode.playerId = id
	playerNode.name = str(id)
	$Players.add_child(playerNode, true)

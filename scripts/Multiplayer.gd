extends Node

const LOCAL_PLAYER = preload("res://scenes/LocalPlayer.tscn")

const PORT = 4433

@onready var gameVersionLabel: Label = %GameVersionLabel
@onready var multiplayerOptions: VBoxContainer = $UI/MultiplayerOptions
@onready var remoteLineEdit: LineEdit = $UI/MultiplayerOptions/Joining/Remote
@onready var players: Node = $Players
@onready var hostOptions: Container = %HostOptions
@onready var xpStartMultiplierInput: LineEdit = %XpStartMultiplier
@onready var xpRewardMultiplierInput: LineEdit = %XpRewardMultiplier
@onready var enemyStartMultiplierInput: LineEdit = %EnemyStartMultiplier
@onready var enemyLevelMultiplierInput: LineEdit = %EnemyLevelMultiplier

var dungeon: Dungeon


func _ready() -> void:
	var gameName: String = ProjectSettings.get_setting("application/config/name")
	var gameVersion: String = ProjectSettings.get_setting("application/config/version")
	print("%s version %s" % [gameName, gameVersion])
	gameVersionLabel.text = "Version %s" % [gameVersion]

#	get_tree().paused = true
	var multiplayerScene := multiplayer as SceneMultiplayer
	multiplayerScene.server_relay = false
	#multiplayer.server_relay = false
	if DisplayServer.get_name() == "headless":
		print("Automatically starting dedicated server.")
		_on_host_pressed.call_deferred()

func _on_host_pressed() -> void:
	# Start game as server
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server.")
		print("Failed to start multiplayer server.")
		return
	multiplayer.multiplayer_peer = peer
#	start_game()

func _on_connect_pressed() -> void:
	# Start game as client, and join existing host
	var txt := remoteLineEdit.text
	if txt == "":
		OS.alert("Need a remote to connect to.")
		return
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(txt, PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client.")
		return
	multiplayer.multiplayer_peer = peer
#	start_game()


func spawn_dungeon() -> void:
	dungeon = Dungeon.init()

	var xpStartMultiplier := xpStartMultiplierInput.text.to_float()
	var xpRewardMultiplier := xpRewardMultiplierInput.text.to_float()
	var enemyStartMultiplier := enemyStartMultiplierInput.text.to_float()
	var enemyLevelMultiplier := enemyLevelMultiplierInput.text.to_float()

	dungeon.xpStart = xpStartMultiplier
	dungeon.xpRewardMultiplier = xpRewardMultiplier
	dungeon.enemyStartMultiplier = enemyStartMultiplier
	dungeon.enemyLevelMultiplier = enemyLevelMultiplier

	add_sibling(dungeon, true)
	print("Spawned dungeon %s" % dungeon)


func start_game() -> void:

	multiplayerOptions.hide()
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

		spawn_dungeon()

	for player in Global.getPlayers():
		player.playerId = player.name.to_int()   #TODO: Why is this necessary???

	Global.getPlayerCurrent().updateUnitList()
	Global.getPlayerCurrent().canvasLayer.visible = true

	if multiplayer.is_server():
		hostOptions.show()

func _on_start_game_pressed() -> void:
	start_game()

func add_player(id: int) -> void:
	var localPLayer: LocalPlayer = LOCAL_PLAYER.instantiate() as LocalPlayer
	localPLayer.playerId = id  #TODO: Why does this not work???
	localPLayer.name = str(id)
	players.add_child(localPLayer, true)


func _on_restart_game_button_pressed() -> void:
	dungeon.queue_free()
	await dungeon.tree_exited
	spawn_dungeon()

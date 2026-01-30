extends Node

const LOCAL_PLAYER = preload("res://scenes/LocalPlayer.tscn")

const PORT = 4433

@onready var gameVersionLabel: Label = %GameVersionLabel
@onready var multiplayerOptions: VBoxContainer = $UI/MultiplayerOptions
@onready var readying: Container = %Readying
@onready var playerNameInput: LineEdit = %PlayerName
@onready var colorPickerButton: ColorPickerButton = %ColorPickerButton
@onready var colorPickerRect: ColorRect = %ColorPickerRect

@onready var hostButton: Button = %HostButton
@onready var connectButton: Button = %ConnectButton
@onready var readyButton: Button = %ReadyButton
@onready var startButton: Button = %StartButton

@onready var remoteLineEdit: LineEdit = $UI/MultiplayerOptions/Joining/Remote
@onready var players: Node = $Players
@onready var hostOptions: Container = %HostOptions
@onready var playerLabelList: GridContainer = %PlayerLabelList

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

	readying.hide()
	colorPickerButton.color = Color(randf(), randf(), randf())
	readyButton.hide()
	readyButton.disabled = true
	startButton.hide()  # Single player mode is currently broken

	var multiplayerScene := multiplayer as SceneMultiplayer
	multiplayerScene.server_relay = false
	if DisplayServer.get_name() == "headless":
		print("Automatically starting dedicated server.")
		_on_host_pressed.call_deferred()

func _on_host_pressed() -> void:
	# Start game as server
	hostButton.hide()
	remoteLineEdit.hide()
	connectButton.hide()
	readying.show()
	readyButton.show()
	startButton.text = "Start Game"
	startButton.show()
	startButton.disabled = true

	var peer := ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server.")
		print("Failed to start multiplayer server.")
		return
	multiplayer.multiplayer_peer = peer

	add_player(1)  # Add host as player 1
	multiplayer.peer_connected.connect(add_player)  # Will be called for each connecting player

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

	hostButton.hide()
	remoteLineEdit.hide()
	connectButton.hide()
	readying.show()
	readyButton.show()
	startButton.hide()


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

	if multiplayer.is_server():
		const UNIT_SCENE = preload("res://scenes/Unit.tscn")
		var zPosition := -6  #TODO: Should use dedicated Dungeon.startPosition or similar
		for node in players.get_children():
			print("Adding player unit for %s" % node.name)
			if node is LocalPlayer:
				var localPLayer: LocalPlayer = node as LocalPlayer
				var unit: Unit = UNIT_SCENE.instantiate() as Unit
				unit.faction = Global.Faction.PLAYERS
				unit.unitName = localPLayer.playerName
				unit.playerColor = localPLayer.playerColor
				unit.position = Vector3(-5, 0.01, zPosition)
				zPosition += 3
				dungeon.add_child(unit, true)
		showUnitList.rpc()


@rpc("authority", "call_local")
func showUnitList() -> void:
	Global.getPlayerCurrent().updateUnitList()
	Global.getPlayerCurrent().canvasLayer.visible = true


func _on_start_game_pressed() -> void:
	hideMultiplayerOptions.rpc()
	print("Game started")
	get_tree().paused = false

	if multiplayer.is_server():
		spawn_dungeon()
		hostOptions.show()


@rpc("authority", "call_local")
func hideMultiplayerOptions() -> void:
	multiplayerOptions.hide()


func add_player(id: int) -> void:
	var localPLayer: LocalPlayer = LOCAL_PLAYER.instantiate() as LocalPlayer
	localPLayer.name = str(id)
	players.add_child(localPLayer, true)
	print("Added player %s with id %s." % [localPLayer.name, localPLayer.playerId])

	for player in Global.getPlayers():
		player.setStatusOnServer(player.isReady, player.playerName, player.playerColor)  # Set correct status for newly joined player
	updatePlayerStatsOnClients.rpc()


func _on_restart_game_button_pressed() -> void:
	dungeon.queue_free()
	await dungeon.tree_exited
	spawn_dungeon()


func _on_player_name_text_changed(newText: String) -> void:
	if newText == "":
		readyButton.disabled = true
	else:
		readyButton.disabled = false


func _on_ready_toggled(toggledOn: bool) -> void:
	var currentPlayer := Global.getPlayerCurrent()
	if toggledOn:
		currentPlayer.setStatusOnServer(true, playerNameInput.text, colorPickerButton.color)
		colorPickerRect.color = colorPickerButton.color
		playerNameInput.editable = false
		colorPickerButton.visible = false
		colorPickerRect.visible = true
		readyButton.text = "Un-ready"
		await get_tree().create_timer(0.2).timeout  #TODO: Do this properly
		updatePlayerStatsOnClients.rpc()
	else:
		currentPlayer.setStatusOnServer(false, playerNameInput.text, colorPickerButton.color)
		playerNameInput.editable = true
		colorPickerButton.visible = true
		colorPickerRect.visible = false
		readyButton.text = "Ready"
		await get_tree().create_timer(0.2).timeout  #TODO: Do this properly
		updatePlayerStatsOnClients.rpc()


@rpc("any_peer", "call_local")
func updatePlayerStatsOnClients() -> void:
	if multiplayer.is_server():
		updatePlayerStats.rpc()


@rpc("authority", "call_local")
func updatePlayerStats() -> void:
	var isReady := true

	for node in playerLabelList.get_children():
		node.queue_free()
	for player in Global.getPlayers():
		var label: Label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.set_custom_minimum_size(Vector2(100, 0))
		label.text = str(player.playerId)
		label.modulate = player.playerColor
		playerLabelList.add_child(label, true)

		label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.set_custom_minimum_size(Vector2(100, 0))
		label.text = player.playerName
		label.modulate = player.playerColor
		playerLabelList.add_child(label, true)

		label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.set_custom_minimum_size(Vector2(100, 0))
		label.text = "Ready" if player.isReady else "Not Ready"
		label.modulate = player.playerColor
		playerLabelList.add_child(label, true)

		if not player.isReady:  # All players must be ready to start the game
			isReady = false

	startButton.disabled = not isReady

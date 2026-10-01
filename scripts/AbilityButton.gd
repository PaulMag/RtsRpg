extends TextureButton
class_name AbilityButton

@onready var cooldownTimer: Timer = $CooldownTimer
@onready var cooldownProgressBar: TextureProgressBar = $CooldownProgressBar
@onready var autocastBorder: AnimatedSprite2D = $AutocastBorder
@onready var descriptionPanel: PanelContainer = %DescriptionPanel
@onready var descriptionLabel: Label = %DescriptionLabel
@onready var hotkeyLabel: Label = %HotkeyLabel

var ability: Ability
var nodeIndex: int
var onCooldown: bool = false

signal toggle_autocast


const SCENE := preload("res://scenes/AbilityButton.tscn")
static func init(_ability: Ability, _nodeIndex: int) -> AbilityButton:
	var scene: AbilityButton = SCENE.instantiate()
	scene.ability = _ability
	scene.nodeIndex = _nodeIndex
	scene.texture_normal = _ability.texture
	return scene

func _ready() -> void:
	cooldownProgressBar.value = 0
	descriptionPanel.visible = false
	descriptionLabel.text = "  %s\n%s" % [ability.name, ability.getDescription()]
	hotkeyLabel.text = "%s" % (nodeIndex + 1)
	cooldownTimer.timeout.connect(_on_cooldown_timeout)


func _process(_delta: float) -> void:
	# if not cooldownTimer.is_stopped():
	if onCooldown:
		cooldownProgressBar.value = cooldownTimer.time_left


func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_released("mouse_right_click"):
		toggle_autocast.emit()

func setAutocast(toggledOn: bool) -> void:
	autocastBorder.visible = toggledOn


func startCooldown(duration: float = 0) -> void:
	if duration > cooldownTimer.time_left:
		cooldownProgressBar.max_value = duration
		cooldownProgressBar.value = duration
		cooldownTimer.start(duration)
		onCooldown = true
		disabled = true


func _on_cooldown_timeout() -> void:
	onCooldown = false
	disabled = false


func _on_mouse_entered() -> void:
	descriptionPanel.visible = true
	self_modulate = Color.LIGHT_GREEN

func _on_mouse_exited() -> void:
	descriptionPanel.visible = false
	self_modulate = Color.WHITE

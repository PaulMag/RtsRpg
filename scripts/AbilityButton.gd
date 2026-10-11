extends TextureButton
class_name AbilityButton

@onready var cooldownTimer: Timer = $CooldownTimer
@onready var cooldownProgressBar: TextureProgressBar = $CooldownProgressBar
@onready var autocastBorder: AnimatedSprite2D = $AutocastBorder
@onready var descriptionPanel: PanelContainer = %DescriptionPanel
@onready var descriptionLabel: Label = %DescriptionLabel
@onready var hotkeyLabel: Label = %HotkeyLabel
@onready var backgroundRect: ColorRect = $BackgroundRect

var ability: Ability
var onCooldown: bool = false

signal toggle_autocast


func _ready() -> void:
	cooldownProgressBar.value = 0
	descriptionPanel.visible = false
	cooldownTimer.timeout.connect(_on_cooldown_timeout)


func _process(_delta: float) -> void:
	if onCooldown:
		cooldownProgressBar.value = cooldownTimer.time_left


func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_released("mouse_right_click"):
		toggle_autocast.emit()
	elif event.is_action_released("mouse_middle_click"):
		clearAbility(Global.getPlayerCurrent().getSelectedUnit())


func setAbility(_ability: Ability, unit: Unit) -> void:
	clearAbility(unit)
	ability = _ability
	texture_normal = ability.texture
	backgroundRect.hide()
	hotkeyLabel.modulate.a = 1.0
	descriptionLabel.text = "  %s\n%s" % [ability.name, ability.getDescription()]
	pressed.connect(unit.useAbilityOnServer.bind(ability.abilityId))
	toggle_autocast.connect(unit.toggleAutocastOnServer.bind(ability.abilityId))
	mouse_entered.connect(unit.setRangeCircle.bind(ability.targetRange))
	mouse_exited.connect(unit.setRangeCircle.bind(0))


func clearAbility(unit: Unit) -> void:
	if ability:
		ability = null
		texture_normal = null
		backgroundRect.show()
		autocastBorder.hide()
		hotkeyLabel.modulate.a = 0.5
		descriptionLabel.text = ""
		pressed.disconnect(unit.useAbilityOnServer)
		toggle_autocast.disconnect(unit.toggleAutocastOnServer)
		mouse_entered.disconnect(unit.setRangeCircle)
		mouse_exited.disconnect(unit.setRangeCircle)


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


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is Ability:
		var _ability: Ability = data
		return true
	return false


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Ability:
		var _ability: Ability = data
		setAbility(_ability, Global.getPlayerCurrent().getSelectedUnit())


func _on_mouse_entered() -> void:
	if ability:
		descriptionPanel.visible = true
		self_modulate = Color.LIGHT_GREEN


func _on_mouse_exited() -> void:
	descriptionPanel.visible = false
	self_modulate = Color.WHITE

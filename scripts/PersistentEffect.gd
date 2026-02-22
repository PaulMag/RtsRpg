extends Node
class_name PersistentEffect

@onready var tickTimer: Timer = $TickTimer
@onready var durationTimer: Timer = $DurationTimer

var ability: Ability
var buff: Buff  #TODO: Need handle buff vs persistentEffectAbility better.
var castingUnit: Unit
var targetUnit: Unit


const SCENE := preload("res://scenes/PersistentEffect.tscn")
static func init(_ability: Ability, _buff: Buff, user: Unit, target: Unit) -> PersistentEffect:
	var scene: PersistentEffect = SCENE.instantiate()
	scene.ability = _ability
	scene.buff = _buff
	scene.castingUnit = user
	scene.targetUnit = target
	return scene


func _ready() -> void:
	tickTimer.start(ability.tickDuration)
	durationTimer.start(buff.duration)


func _on_tick_timer_timeout() -> void:
	ability.persistentEffectAbility.use(castingUnit, targetUnit, targetUnit)

func _on_duration_timer_timeout() -> void:
	queue_free()

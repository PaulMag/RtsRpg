class_name BuffIcon
extends TextureRect

const SCENE := preload("res://scenes/ui/BuffIcon.tscn")

var buff: Buff

@onready var buffProgressBar: TextureProgressBar = $BuffProgressBar


static func init(_buff: Buff) -> BuffIcon:
	var scene: BuffIcon = SCENE.instantiate()
	scene.buff = _buff
	scene.texture = _buff.texture
	return scene


func _ready() -> void:
	buffProgressBar.max_value = buff.duration
	buffProgressBar.value = buff.duration


func _process(_delta: float) -> void:
	buffProgressBar.value = buff.duration - buff.timer.time_left

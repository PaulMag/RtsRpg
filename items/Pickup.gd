extends Area2D

class_name Pickup


@export var itemType: Item

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	sprite.texture = itemType.texture

func _on_body_entered(body) -> void:
	if body is Unit:
		var unit = body
		if unit.faction == Global.Faction.PLAYERS:
			if unit.giveItem(itemType):
				queue_free()

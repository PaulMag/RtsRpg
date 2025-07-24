extends Node3D
class_name UnitSpawner

@export var afterSpawnTarget: Node3D
@export var numberOfBarbarians: int
@export var numberOfArchers: int
@export var numberOfAdditionalBarbarians: int
@export var numberOfAdditionalArchers: int


const BARBARIAN_SCENE := preload("res://scenes/UnitBarbarian.tscn")
const ARCHER_SCENE := preload("res://scenes/UnitArcher.tscn")

const SPAWN_RADIUS: float = 3

var remainingSpawns: Array[PackedScene] = []


func _ready() -> void:
	if not multiplayer.is_server():
		return

	for i in range(numberOfBarbarians):
		spawnUnit(BARBARIAN_SCENE)

	for i in range(numberOfArchers):
		spawnUnit(ARCHER_SCENE)

	for i in range(numberOfAdditionalBarbarians):
		remainingSpawns.append(BARBARIAN_SCENE)

	for i in range(numberOfAdditionalArchers):
		remainingSpawns.append(ARCHER_SCENE)

	remainingSpawns.shuffle()



func spawnUnit(UNIT_SCENE: PackedScene) -> void:
	var newUnit := UNIT_SCENE.instantiate() as Unit

	var offset := Vector3(randf_range(-SPAWN_RADIUS, SPAWN_RADIUS), 0, randf_range(-SPAWN_RADIUS, SPAWN_RADIUS))
	newUnit.position = position + offset
	add_sibling.call_deferred(newUnit, true)

	if afterSpawnTarget:
		newUnit.destination = afterSpawnTarget.global_position + offset
		newUnit.followCursor = true

	newUnit.died.connect(spawnAdditionalUnit)


func spawnAdditionalUnit() -> void:
	if not remainingSpawns.is_empty():
		print("%s spawns additional unit" % self)
		var newScene := remainingSpawns.pop_back() as PackedScene
		spawnUnit(newScene)

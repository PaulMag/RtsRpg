extends Node3D
class_name UnitSpawner


@export var level: int = 1
@export var afterSpawnTarget: Node3D
@export var numberOfBarbarians: int
@export var numberOfArchers: int
@export var numberOfAdditionalBarbarians: int
@export var numberOfAdditionalArchers: int
@export var numberOfLoot: int = 3
@export var talentPointsReward: float = 10

@onready var label: Label = %Label

const BARBARIAN_SCENE := preload("res://scenes/UnitBarbarian.tscn")
const ARCHER_SCENE := preload("res://scenes/UnitArcher.tscn")

const SPAWN_RADIUS: float = 3

var numberOfLivingUnits: int = 0
var remainingSpawns: Array[PackedScene] = []
var livingUnits: Array[Unit] = []


func _ready() -> void:
	if not multiplayer.is_server():
		return

	await Global.dungeon.ready

	for i in range(numberOfAdditionalBarbarians):
		remainingSpawns.append(BARBARIAN_SCENE)

	for i in range(numberOfAdditionalArchers):
		remainingSpawns.append(ARCHER_SCENE)

	remainingSpawns.shuffle()

	for i in range(numberOfBarbarians):
		spawnUnit(BARBARIAN_SCENE)

	for i in range(numberOfArchers):
		spawnUnit(ARCHER_SCENE)


func spawnUnit(UNIT_SCENE: PackedScene, joiningExistingUnits: bool = false) -> void:
	var newUnit := UNIT_SCENE.instantiate() as Unit
	newUnit.level = level

	var offset := Vector3(randf_range(-SPAWN_RADIUS, SPAWN_RADIUS), 0, randf_range(-SPAWN_RADIUS, SPAWN_RADIUS))
	newUnit.position = position + offset
	add_sibling.call_deferred(newUnit, true)
	await newUnit.ready

	if joiningExistingUnits:
		var randomExistingUnit := livingUnits[randi() % livingUnits.size()]
		newUnit.destination = randomExistingUnit.global_position + offset
		newUnit.followCursor = true
	elif afterSpawnTarget:
		newUnit.destination = afterSpawnTarget.global_position + offset
		newUnit.followCursor = true

	numberOfLivingUnits += 1
	livingUnits.append(newUnit)
	setLabel.rpc("Enemies: %d" % (numberOfLivingUnits + remainingSpawns.size()))

	newUnit.died.connect(onUnitDied.bind(newUnit))

func onUnitDied(deadUnit: Unit) -> void:
	numberOfLivingUnits -= 1
	livingUnits.erase(deadUnit)
	setLabel.rpc("Enemies: %d" % (numberOfLivingUnits + remainingSpawns.size()))

	if not remainingSpawns.is_empty():
		print("%s spawns additional unit" % self)
		var newScene := remainingSpawns[~0]
		remainingSpawns.pop_back()
		spawnUnit(newScene, true)

	elif numberOfLivingUnits == 0:
		for i in range(numberOfLoot):
			var angleDiff := 2 * PI / numberOfLoot
			var positionOffset := Vector3(cos(angleDiff * i), 0, sin(angleDiff * i)) * numberOfLoot / PI

			var item := Global.dungeon.getNextLoot()
			var pickup := Pickup.init(item)
			pickup.position = position + positionOffset
			call_deferred("add_sibling", pickup, true)

		setLabel.rpc("Encounter\ndefeated!")
		Global.dungeon.distributeTalentPoints(talentPointsReward * Global.dungeon.xpRewardMultiplier)

@rpc("authority", "call_local")
func setLabel(text: String) -> void:
	label.text = text

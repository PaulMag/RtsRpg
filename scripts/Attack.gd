class_name Attack

var damageMelee: float
var damageRanged: float
var damageMagical: float
var healingAmount: float
var threat: float  # Threat from healing is separate.
var isHealing := false
var attackingUnit: Unit
var sourceUnit: Unit  # Used for persistent effects. When null, attackingUnit is used as source.
var ability: Ability

var buffs: Array[Buff] = []

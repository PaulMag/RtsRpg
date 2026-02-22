@tool
extends Ability
class_name Revive


func use(user: Unit, target: Unit, source: Unit = null) -> bool:
	if super.use(user, target, source):
		target.ressurect()
		return true
	return false

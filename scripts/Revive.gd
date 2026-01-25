@tool
extends Ability
class_name Revive


func use(user: Unit, target: Unit) -> bool:
	if super.use(user, target):
		target.ressurect()
		return true
	return false

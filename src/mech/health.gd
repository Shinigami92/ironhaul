class_name Health
extends RefCounted

signal changed(current: float, maximum: float)
signal depleted

var current: float
var maximum: float


func _init(max_value: float) -> void:
	maximum = max_value
	current = max_value


func take_damage(amount: float) -> void:
	if is_depleted():
		return
	current = max(0.0, current - amount)
	changed.emit(current, maximum)
	if current <= 0.0:
		depleted.emit()


func is_depleted() -> bool:
	return current <= 0.0

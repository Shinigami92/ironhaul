class_name Heat
extends RefCounted

signal changed(current: float, maximum: float)
signal overheated
signal cooled

var current: float = 0.0
var maximum: float
var decay_per_sec: float
var cool_threshold: float
var is_overheated: bool = false


func _init(max_value: float, decay_rate: float, cool_at: float) -> void:
	maximum = max_value
	decay_per_sec = decay_rate
	cool_threshold = cool_at


func apply(amount: float) -> void:
	current = min(maximum, current + amount)
	changed.emit(current, maximum)
	if current >= maximum and not is_overheated:
		is_overheated = true
		overheated.emit()


func decay(delta: float) -> void:
	if current <= 0.0:
		return
	current = max(0.0, current - decay_per_sec * delta)
	changed.emit(current, maximum)
	if is_overheated and current <= cool_threshold:
		is_overheated = false
		cooled.emit()

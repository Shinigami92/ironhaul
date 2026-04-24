class_name Thrust
extends RefCounted

signal changed(current: float, maximum: float)

var current: float
var maximum: float
var regen_per_sec: float
var regen_delay_sec: float
var _regen_delay: float = 0.0


func _init(max_value: float, regen_rate: float, regen_delay: float) -> void:
	maximum = max_value
	regen_per_sec = regen_rate
	regen_delay_sec = regen_delay
	current = max_value


func consume(amount: float) -> bool:
	# Attempting to consume — successful or not — always resets the regen delay.
	# Otherwise an empty tank regens while the button is still held, producing
	# a flickery hover that lets the player climb with "zero fuel".
	_regen_delay = regen_delay_sec
	if current >= amount:
		current -= amount
		changed.emit(current, maximum)
		return true
	return false


func regen(delta: float) -> void:
	# Pause regen for regen_delay_sec after each consumption. Only the remaining
	# delta after the delay expires counts toward regen this frame.
	var regen_delta := delta
	if _regen_delay > 0.0:
		var consumed: float = minf(delta, _regen_delay)
		_regen_delay -= consumed
		regen_delta -= consumed
	if regen_delta > 0.0 and current < maximum:
		current = min(maximum, current + regen_per_sec * regen_delta)
		changed.emit(current, maximum)

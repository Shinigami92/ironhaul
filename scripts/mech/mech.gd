class_name Mech
extends CharacterBody3D

signal health_changed(current: float, max_value: float)
signal heat_changed(current: float, max_value: float)
signal thrust_changed(current: float, max_value: float)
signal overheated
signal cooled
signal died

@export var max_health: float = 100.0
@export var max_heat: float = 100.0
@export var max_thrust: float = 100.0
@export var heat_decay_per_sec: float = 18.0
@export var thrust_regen_per_sec: float = 40.0
# Seconds after the last thrust consumption before regen resumes. Prevents the
# "endless thrust" feel that came from regen overlapping drain every frame.
@export var thrust_regen_delay_sec: float = 0.15
@export var overheat_cool_threshold: float = 30.0
@export var is_enemy: bool = false

var current_health: float
var current_heat: float = 0.0
var current_thrust: float
var is_overheated: bool = false
var is_dead: bool = false

var camera: Camera3D
var movement: Node
var weapon: Node

var _thrust_regen_delay: float = 0.0


func _ready() -> void:
	current_health = max_health
	current_thrust = max_thrust
	MechBuilder.build_greybox(self, is_enemy)
	if is_enemy:
		add_to_group("enemy_mech")
	else:
		add_to_group("player_mech")
		_setup_camera()
	_attach_components()


func _process(delta: float) -> void:
	if is_dead:
		return
	if current_heat > 0.0:
		current_heat = max(0.0, current_heat - heat_decay_per_sec * delta)
		heat_changed.emit(current_heat, max_heat)
		if is_overheated and current_heat <= overheat_cool_threshold:
			is_overheated = false
			cooled.emit()

	# Thrust regen: pause for thrust_regen_delay_sec after each consumption so
	# holding thrust drains cleanly, and only the *remaining* delta after the
	# delay expires counts toward regen this frame.
	var regen_delta := delta
	if _thrust_regen_delay > 0.0:
		var consumed: float = minf(delta, _thrust_regen_delay)
		_thrust_regen_delay -= consumed
		regen_delta -= consumed
	if regen_delta > 0.0 and current_thrust < max_thrust:
		current_thrust = min(max_thrust, current_thrust + thrust_regen_per_sec * regen_delta)
		thrust_changed.emit(current_thrust, max_thrust)


func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_health = max(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		is_dead = true
		died.emit()


func apply_heat(amount: float) -> void:
	current_heat = min(max_heat, current_heat + amount)
	heat_changed.emit(current_heat, max_heat)
	if current_heat >= max_heat and not is_overheated:
		is_overheated = true
		overheated.emit()


func can_fire() -> bool:
	return not is_dead and not is_overheated


func consume_thrust(amount: float) -> bool:
	# Attempting to thrust — successful or not — always resets the regen delay.
	# Otherwise an empty tank regens while the button is still held, producing
	# a flickery hover that lets the player climb with "zero fuel".
	_thrust_regen_delay = thrust_regen_delay_sec
	if current_thrust >= amount:
		current_thrust -= amount
		thrust_changed.emit(current_thrust, max_thrust)
		return true
	return false


func _setup_camera() -> void:
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(0, 3.0, 0.2)
	camera.current = true
	add_child(camera)


func _attach_components() -> void:
	if is_enemy:
		return
	movement = preload("res://scripts/mech/mech_movement.gd").new()
	movement.name = "Movement"
	add_child(movement)
	weapon = preload("res://scripts/mech/mech_weapon.gd").new()
	weapon.name = "Weapon"
	add_child(weapon)

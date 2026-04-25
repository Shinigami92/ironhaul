class_name Mech
extends CharacterBody3D

signal health_changed(current: float, max_value: float)
signal heat_changed(current: float, max_value: float)
signal thrust_changed(current: float, max_value: float)
signal overheated
signal cooled
signal died

# Barrel offsets in mech-local space. Godot convention: -Z is forward, so
# barrels sit in front of the torso. Must stay in sync with MechBuilder._add_arms,
# which places arm barrels at (±1.15, 2.0, -0.9).
const BARREL_LOCAL_LEFT: Vector3 = Vector3(-1.15, 2.0, -0.9)
const BARREL_LOCAL_RIGHT: Vector3 = Vector3(1.15, 2.0, -0.9)

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

# State components. Each one is a focused RefCounted class owning a single
# concern (hp / heat / thrust). Mech is a thin composer that forwards their
# signals and ticks them from _process.
var health: Health
var heat: Heat
var thrust: Thrust
var is_dead: bool = false

var _next_barrel_left: bool = true

# Authored children from mech.tscn. `get_node_or_null` so bare `Mech.new()`
# (tests, enemy AI paths that don't instantiate the full scene) doesn't crash;
# downstream code already null-checks `mech.camera` etc.
@onready var camera: Camera3D = get_node_or_null("Camera")
@onready var movement: Node = get_node_or_null("Movement")
@onready var weapon: Node = get_node_or_null("Weapon")


func _ready() -> void:
	health = Health.new(max_health)
	heat = Heat.new(max_heat, heat_decay_per_sec, overheat_cool_threshold)
	thrust = Thrust.new(max_thrust, thrust_regen_per_sec, thrust_regen_delay_sec)

	# Forward component signals so listeners (HUD, zone, grunt AI) bind to
	# `mech.*` as before and don't need to reach into `mech.health.*` etc.
	health.changed.connect(health_changed.emit)
	health.depleted.connect(_on_health_depleted)
	heat.changed.connect(heat_changed.emit)
	heat.overheated.connect(overheated.emit)
	heat.cooled.connect(cooled.emit)
	thrust.changed.connect(thrust_changed.emit)

	MechBuilder.build_greybox(self, is_enemy)
	if is_enemy:
		add_to_group("enemy_mech")
	else:
		add_to_group("player_mech")


func _process(delta: float) -> void:
	if is_dead:
		return
	heat.decay(delta)
	thrust.regen(delta)


func take_damage(amount: float) -> void:
	if is_dead:
		return
	health.take_damage(amount)


func apply_heat(amount: float) -> void:
	heat.apply(amount)


func consume_thrust(amount: float) -> bool:
	return thrust.consume(amount)


func can_fire() -> bool:
	return not is_dead and not heat.is_overheated


func take_next_barrel_offset() -> Vector3:
	# Alternates left/right each call so both arms visibly fire over a burst.
	var offset := BARREL_LOCAL_LEFT if _next_barrel_left else BARREL_LOCAL_RIGHT
	_next_barrel_left = not _next_barrel_left
	return offset


func _on_health_depleted() -> void:
	is_dead = true
	died.emit()

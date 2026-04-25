extends Node

const THRUSTER_LOOP_SOUND: AudioStream = preload("res://audio/sfx/movement/thruster_loop.mp3")
const THRUSTER_BURST_SOUND: AudioStream = preload("res://audio/sfx/movement/thruster_burst.ogg")
const FOOTSTEP_SOUND: AudioStream = preload("res://audio/sfx/movement/footstep.mp3")

const WALK_SPEED_THRESHOLD: float = 1.0

@export var walk_speed: float = 10.0
@export var acceleration: float = 28.0
@export var friction: float = 22.0
@export var gravity: float = 26.0
@export var thrust_hold_velocity: float = 7.5
@export var thrust_cost_per_sec: float = 45.0
@export var dodge_impulse: float = 15.0
@export var dodge_cost: float = 25.0
@export var mouse_sensitivity: float = 0.0022
@export var pitch_min_deg: float = -70.0
@export var pitch_max_deg: float = 70.0

var mech: Mech
var yaw: float = 0.0
var pitch: float = 0.0

var _thruster_player: AudioStreamPlayer3D
var _footstep_player: AudioStreamPlayer3D


func _ready() -> void:
	mech = get_parent() as Mech
	if mech == null:
		push_error("MechMovement: parent must be Mech")
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_setup_thruster_audio()
	_setup_footstep_audio()


func _setup_thruster_audio() -> void:
	# Duplicate the stream so `loop = true` doesn't leak to other consumers of
	# the preloaded resource. The player stays attached to the mech so the
	# thruster hum is always positioned at the mech.
	var looped: AudioStreamMP3 = THRUSTER_LOOP_SOUND.duplicate()
	looped.loop = true
	_thruster_player = AudioStreamPlayer3D.new()
	_thruster_player.stream = looped
	_thruster_player.volume_db = -6.0
	# Deferred: mech is still propagating ready to its authored children when
	# our _ready runs, so a direct add_child hits `data.blocked > 0`.
	mech.add_child.call_deferred(_thruster_player)


func _setup_footstep_audio() -> void:
	# The footstep mp3 is a multi-step sequence (~5 steps over 5s). Looping it
	# gives a continuous walking cadence without per-step timers.
	var looped: AudioStreamMP3 = FOOTSTEP_SOUND.duplicate()
	looped.loop = true
	_footstep_player = AudioStreamPlayer3D.new()
	_footstep_player.stream = looped
	_footstep_player.volume_db = -4.0
	mech.add_child.call_deferred(_footstep_player)


func _unhandled_input(event: InputEvent) -> void:
	if mech == null or mech.is_dead:
		return
	if event.is_action_pressed("ui_cancel"):
		_toggle_mouse_capture()
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion: InputEventMouseMotion = event
		yaw -= motion.relative.x * mouse_sensitivity
		pitch -= motion.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(pitch_min_deg), deg_to_rad(pitch_max_deg))
		mech.rotation.y = yaw
		if mech.camera != null:
			mech.camera.rotation.x = pitch


func _physics_process(delta: float) -> void:
	if mech == null or mech.is_dead:
		return

	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wish_dir := mech.transform.basis * Vector3(input_vec.x, 0, input_vec.y)
	wish_dir.y = 0
	if wish_dir.length() > 0.01:
		wish_dir = wish_dir.normalized()
	else:
		wish_dir = Vector3.ZERO

	var velocity := mech.velocity
	var target_h := wish_dir * walk_speed
	var current_h := Vector3(velocity.x, 0.0, velocity.z)
	var accel_rate := acceleration if wish_dir.length() > 0.01 else friction
	current_h = current_h.move_toward(target_h, accel_rate * delta)
	velocity.x = current_h.x
	velocity.z = current_h.z

	if not mech.is_on_floor():
		velocity.y -= gravity * delta

	var thrust_pressed := Input.is_action_pressed("thrust")
	var thrust_applied := false
	if thrust_pressed:
		if mech.consume_thrust(thrust_cost_per_sec * delta):
			velocity.y = max(velocity.y, thrust_hold_velocity)
			thrust_applied = true

	if Input.is_action_just_pressed("dodge") and wish_dir.length() > 0.01:
		if mech.consume_thrust(dodge_cost):
			velocity += wish_dir * dodge_impulse
			WeaponVFX.play_one_shot_3d(
				mech.get_tree().current_scene, mech.global_position, THRUSTER_BURST_SOUND
			)

	mech.velocity = velocity
	mech.move_and_slide()

	_update_thruster_loop(thrust_applied)
	_update_footsteps(delta)


func _update_thruster_loop(thrust_applied: bool) -> void:
	# The audio players are added to mech via call_deferred; skip until the
	# deferred add_child has flushed into the scene tree.
	if not _thruster_player.is_inside_tree():
		return
	if thrust_applied and not _thruster_player.playing:
		_thruster_player.play()
	elif not thrust_applied and _thruster_player.playing:
		_thruster_player.stop()


func _update_footsteps(_delta: float) -> void:
	if not _footstep_player.is_inside_tree():
		return
	var h_speed := Vector2(mech.velocity.x, mech.velocity.z).length()
	var walking := mech.is_on_floor() and h_speed >= WALK_SPEED_THRESHOLD
	if walking and not _footstep_player.playing:
		_footstep_player.play()
	elif not walking and _footstep_player.playing:
		_footstep_player.stop()


func _toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

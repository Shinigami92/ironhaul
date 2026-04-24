extends Node

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


func _ready() -> void:
	mech = get_parent() as Mech
	if mech == null:
		push_error("MechMovement: parent must be Mech")
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


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
	var wish_dir := (mech.transform.basis * Vector3(input_vec.x, 0, input_vec.y))
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

	if Input.is_action_pressed("thrust"):
		if mech.consume_thrust(thrust_cost_per_sec * delta):
			velocity.y = max(velocity.y, thrust_hold_velocity)

	if Input.is_action_just_pressed("dodge") and wish_dir.length() > 0.01:
		if mech.consume_thrust(dodge_cost):
			velocity += wish_dir * dodge_impulse

	mech.velocity = velocity
	mech.move_and_slide()


func _toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

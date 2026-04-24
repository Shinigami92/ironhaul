class_name Grunt
extends Mech

enum AIState { PATROL, ENGAGE, RETREAT }

@export var detection_range: float = 35.0
@export var engage_range: float = 22.0
@export var retreat_health_frac: float = 0.25
@export var move_speed: float = 5.0
@export var attack_damage: float = 6.0
@export var attack_interval: float = 1.4
@export var enemy_gravity: float = 26.0

var ai_state: AIState = AIState.PATROL
var player: Mech
var _attack_timer: float = 0.0
var _patrol_target: Vector3 = Vector3.ZERO


func _ready() -> void:
	is_enemy = true
	super._ready()
	_pick_patrol_target()
	died.connect(_on_died)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_find_player_if_missing()

	if _attack_timer > 0.0:
		_attack_timer -= delta

	match ai_state:
		AIState.PATROL:
			_patrol(delta)
			if (
				player != null
				and global_position.distance_to(player.global_position) < detection_range
			):
				ai_state = AIState.ENGAGE
		AIState.ENGAGE:
			_engage(delta)
			if current_health / max_health < retreat_health_frac:
				ai_state = AIState.RETREAT
		AIState.RETREAT:
			_retreat(delta)
			if current_health / max_health > retreat_health_frac + 0.15:
				ai_state = AIState.ENGAGE


func _find_player_if_missing() -> void:
	if player != null and is_instance_valid(player):
		return
	var mechs := get_tree().get_nodes_in_group("player_mech")
	if mechs.size() > 0:
		player = mechs[0] as Mech


func _pick_patrol_target() -> void:
	var angle := randf() * TAU
	var radius := randf_range(6.0, 14.0)
	_patrol_target = global_position + Vector3(cos(angle) * radius, 0, sin(angle) * radius)


func _patrol(delta: float) -> void:
	if global_position.distance_to(_patrol_target) < 1.5:
		_pick_patrol_target()
	_move_toward(_patrol_target, delta)


func _engage(delta: float) -> void:
	if player == null:
		ai_state = AIState.PATROL
		return
	_face(player.global_position)
	var dist := global_position.distance_to(player.global_position)
	if dist > engage_range:
		_move_toward(player.global_position, delta)
	else:
		_apply_gravity_and_slide(delta)
	if _attack_timer <= 0.0 and dist < engage_range:
		_attempt_attack()


func _retreat(delta: float) -> void:
	if player == null:
		ai_state = AIState.PATROL
		return
	var away := global_position - player.global_position
	away.y = 0
	if away.length() < 0.01:
		away = Vector3.FORWARD
	_move_toward(global_position + away.normalized() * 12.0, delta)


func _face(target: Vector3) -> void:
	var flat_target := Vector3(target.x, global_position.y, target.z)
	if flat_target.distance_to(global_position) > 0.01:
		look_at(flat_target, Vector3.UP)


func _move_toward(target: Vector3, delta: float) -> void:
	var dir := target - global_position
	dir.y = 0
	if dir.length() > 0.01:
		dir = dir.normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	_apply_gravity_and_slide(delta)


func _apply_gravity_and_slide(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= enemy_gravity * delta
	move_and_slide()


func _attempt_attack() -> void:
	if player == null or player.is_dead:
		return
	var origin := global_position + Vector3.UP * 2.4
	var target := player.global_position + Vector3.UP * 2.2
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	_attack_timer = attack_interval
	if hit.is_empty():
		return
	var collider: Object = hit.get("collider")
	if collider == player and collider.has_method("take_damage"):
		collider.take_damage(attack_damage)


func _on_died() -> void:
	GameState.add_material("scrap", 10)
	GameState.add_material("ore", randi_range(0, 3))
	queue_free()

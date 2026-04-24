extends Node

# Barrel positions in the mech's local space — must stay in sync with
# MechBuilder._add_arms, which places arm barrels at (±1.15, 2.0, 0.9).
const BARREL_LOCAL_LEFT: Vector3 = Vector3(-1.15, 2.0, 0.9)
const BARREL_LOCAL_RIGHT: Vector3 = Vector3(1.15, 2.0, 0.9)

const PRIMARY_COLOR: Color = Color(1.0, 0.75, 0.3)  # warm orange
const SECONDARY_COLOR: Color = Color(0.45, 0.8, 1.0)  # cold cyan

@export var primary_damage: float = 8.0
@export var primary_fire_rate: float = 4.0
@export var primary_heat_per_shot: float = 11.0
@export var secondary_damage: float = 26.0
@export var secondary_heat_per_shot: float = 38.0
@export var max_range: float = 80.0

var mech: Mech
var _primary_cooldown: float = 0.0
var _use_left_barrel: bool = true


func _ready() -> void:
	mech = get_parent() as Mech
	if mech == null:
		push_error("MechWeapon: parent must be Mech")


func _process(delta: float) -> void:
	if mech == null:
		return
	if _primary_cooldown > 0.0:
		_primary_cooldown -= delta
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if not mech.can_fire() or mech.camera == null:
		return
	if Input.is_action_pressed("fire_primary") and _primary_cooldown <= 0.0:
		_fire_shot(primary_damage, primary_heat_per_shot, PRIMARY_COLOR)
		_primary_cooldown = 1.0 / primary_fire_rate
	if Input.is_action_just_pressed("fire_secondary"):
		_fire_shot(secondary_damage, secondary_heat_per_shot, SECONDARY_COLOR)


func _fire_shot(damage: float, heat_cost: float, color: Color) -> void:
	var cam := mech.camera
	var origin := cam.global_position
	var forward := -cam.global_transform.basis.z
	var max_target := origin + forward * max_range

	var space := mech.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, max_target)
	query.exclude = [mech.get_rid()]
	var hit := space.intersect_ray(query)

	mech.apply_heat(heat_cost)

	var hit_pos: Vector3 = max_target
	var collider: Object = null
	if not hit.is_empty():
		hit_pos = hit["position"]
		collider = hit.get("collider")

	_spawn_vfx(color, hit_pos, not hit.is_empty())

	if collider != null and collider.has_method("take_damage"):
		collider.take_damage(damage)


func _spawn_vfx(color: Color, end_pos: Vector3, did_hit: bool) -> void:
	# Alternate barrels each shot so both arms feel active.
	var barrel_local := BARREL_LOCAL_LEFT if _use_left_barrel else BARREL_LOCAL_RIGHT
	_use_left_barrel = not _use_left_barrel
	var barrel_world := mech.to_global(barrel_local)

	var world_root := mech.get_tree().current_scene
	if world_root == null:
		return
	WeaponVFX.spawn_muzzle_flash(world_root, barrel_world, color)
	WeaponVFX.spawn_tracer(world_root, barrel_world, end_pos, color)
	if did_hit:
		WeaponVFX.spawn_impact(world_root, end_pos, color)

extends Node

const PRIMARY_COLOR: Color = Color(1.0, 0.75, 0.3)  # warm orange
const SECONDARY_COLOR: Color = Color(0.45, 0.8, 1.0)  # cold cyan

const PRIMARY_FIRE_SOUND: AudioStream = preload("res://audio/sfx/weapons/primary_fire.ogg")
const SECONDARY_FIRE_SOUND: AudioStream = preload("res://audio/sfx/weapons/secondary_fire.ogg")

@export var primary_damage: float = 8.0
@export var primary_fire_rate: float = 4.0
@export var primary_heat_per_shot: float = 11.0
@export var secondary_damage: float = 26.0
@export var secondary_heat_per_shot: float = 38.0
@export var max_range: float = 80.0

var mech: Mech
var _primary_cooldown: float = 0.0


func _ready() -> void:
	mech = get_parent() as Mech
	if mech == null:
		push_error("MechWeapon: parent must be Mech")
		return
	if mech.is_enemy:
		# Enemy mechs inherit mech.tscn so Weapon is attached, but Grunt fires
		# via its own _attempt_attack logic. Disable _process so we don't also
		# fire on player input.
		set_process(false)


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
		_fire_shot(primary_damage, primary_heat_per_shot, PRIMARY_COLOR, PRIMARY_FIRE_SOUND)
		_primary_cooldown = 1.0 / primary_fire_rate
	if Input.is_action_just_pressed("fire_secondary"):
		_fire_shot(secondary_damage, secondary_heat_per_shot, SECONDARY_COLOR, SECONDARY_FIRE_SOUND)


func _fire_shot(damage: float, heat_cost: float, color: Color, fire_sound: AudioStream) -> void:
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

	WeaponVFX.spawn_shot_effects(mech, hit_pos, not hit.is_empty(), color)

	var world_root := mech.get_tree().current_scene
	WeaponVFX.play_one_shot_3d(world_root, mech.global_position, fire_sound)
	if not hit.is_empty():
		WeaponVFX.play_one_shot_3d(world_root, hit_pos, WeaponVFX.IMPACT_SOUND)

	if collider != null and collider.has_method("take_damage"):
		collider.take_damage(damage)

extends Node

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
		_fire_shot(primary_damage, primary_heat_per_shot)
		_primary_cooldown = 1.0 / primary_fire_rate
	if Input.is_action_just_pressed("fire_secondary"):
		_fire_shot(secondary_damage, secondary_heat_per_shot)


func _fire_shot(damage: float, heat_cost: float) -> void:
	var cam := mech.camera
	var origin := cam.global_position
	var forward := -cam.global_transform.basis.z
	var target := origin + forward * max_range

	var space := mech.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.exclude = [mech.get_rid()]
	var hit := space.intersect_ray(query)

	mech.apply_heat(heat_cost)

	if hit.is_empty():
		return
	var collider: Object = hit.get("collider")
	if collider != null and collider.has_method("take_damage"):
		collider.take_damage(damage)

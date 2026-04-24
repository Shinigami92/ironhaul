class_name ScrapPickup
extends Area3D

# A floating, spinning cube dropped by dead enemies. Walks over = collected.
# Same class handles scrap and ore — just set `material_kind`, `amount`, and `tint`.

const BOB_AMPLITUDE: float = 0.15
const BOB_SPEED: float = 2.0
const SPIN_SPEED: float = 1.5

@export var material_kind: String = "scrap"
@export var amount: int = 10
@export var tint: Color = Color(0.4, 1.0, 0.4)

var _time: float = 0.0
var _base_y: float = 0.0


func _ready() -> void:
	_base_y = position.y
	_build_visual()
	_build_collision()
	body_entered.connect(_on_body_entered)
	# Handle the case where the pickup spawns on top of the player — e.g.
	# a grunt killed at point-blank range. body_entered only fires on overlap
	# transitions, so we actively check the first frame after setup.
	_check_initial_overlap.call_deferred()


func _process(delta: float) -> void:
	_time += delta
	position.y = _base_y + sin(_time * BOB_SPEED) * BOB_AMPLITUDE
	rotation.y = _time * SPIN_SPEED


func _build_visual() -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.4, 0.4, 0.4)
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.emission_enabled = true
	mat.emission = tint
	mat.emission_energy_multiplier = 2.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	add_child(mi)


func _build_collision() -> void:
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.2
	shape.shape = sphere
	add_child(shape)


func _check_initial_overlap() -> void:
	for body in get_overlapping_bodies():
		if _is_collector(body):
			_collect(body)
			return


func _on_body_entered(body: Node) -> void:
	if _is_collector(body):
		_collect(body)


func _is_collector(body: Node) -> bool:
	return body is Mech and not (body as Mech).is_enemy


func _collect(_body: Node) -> void:
	GameState.add_material(material_kind, amount)
	var world := get_tree().current_scene
	if world != null:
		WeaponVFX.spawn_impact(world, global_position, tint)
	queue_free()

class_name WeaponVFX
extends RefCounted

# Short-lived visual effects for weapon fire: tracer beams, muzzle flash, and
# impact pops. All built from primitives — no assets required.

const TRACER_LIFE_SEC: float = 0.05
const MUZZLE_LIFE_SEC: float = 0.06
const IMPACT_LIFE_SEC: float = 0.15

const TRACER_RADIUS: float = 0.03
const MUZZLE_RADIUS: float = 0.25
const IMPACT_RADIUS: float = 0.3

const IMPACT_SOUND: AudioStream = preload("res://audio/sfx/weapons/impact.ogg")


# Plays a one-shot positional sound at `pos`. Spawns a temporary
# AudioStreamPlayer3D as a child of `world`, plays, and auto-frees on finish.
# No-op if `stream` is null (e.g. audio file not yet installed).
static func play_one_shot_3d(
	world: Node, pos: Vector3, stream: AudioStream, volume_db: float = 0.0
) -> void:
	if stream == null or world == null:
		return
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = volume_db
	world.add_child(player)
	player.global_position = pos
	player.play()
	player.finished.connect(player.queue_free)


# High-level helper: spawns muzzle + tracer (+ impact when the ray connected)
# for a single shot fired from `shooter`. Barrels alternate left/right per call.
static func spawn_shot_effects(
	shooter: Mech, end_pos: Vector3, did_hit: bool, color: Color
) -> void:
	var world := shooter.get_tree().current_scene
	if world == null:
		return
	var barrel_world := shooter.to_global(shooter.take_next_barrel_offset())
	spawn_muzzle_flash(world, barrel_world, color)
	spawn_tracer(world, barrel_world, end_pos, color)
	if did_hit:
		spawn_impact(world, end_pos, color)


static func spawn_tracer(world: Node, from_pos: Vector3, to_pos: Vector3, color: Color) -> void:
	var distance := from_pos.distance_to(to_pos)
	if distance < 0.01:
		return

	var tracer := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = TRACER_RADIUS
	mesh.bottom_radius = TRACER_RADIUS
	mesh.height = distance
	tracer.mesh = mesh
	tracer.material_override = _make_glow_material(color)

	world.add_child(tracer)
	# Add to tree BEFORE positioning — look_at() requires the node be inside
	# the tree (it reads global_transform). CylinderMesh defaults to standing
	# on +Y; look_at points -Z at the target, so we rotate 90° around X to
	# align the cylinder's axis with the ray.
	tracer.global_position = (from_pos + to_pos) * 0.5
	tracer.look_at(to_pos, Vector3.UP)
	tracer.rotate_object_local(Vector3.RIGHT, PI / 2)

	_fade_and_free(tracer, TRACER_LIFE_SEC)


static func spawn_muzzle_flash(world: Node, pos: Vector3, color: Color) -> void:
	var flash := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = MUZZLE_RADIUS
	mesh.height = MUZZLE_RADIUS * 2.0
	flash.mesh = mesh
	flash.material_override = _make_glow_material(color)

	world.add_child(flash)
	flash.global_position = pos
	_fade_and_free(flash, MUZZLE_LIFE_SEC)


static func spawn_impact(world: Node, pos: Vector3, color: Color) -> void:
	var impact := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = IMPACT_RADIUS
	mesh.height = IMPACT_RADIUS * 2.0
	impact.mesh = mesh
	impact.material_override = _make_glow_material(color)

	world.add_child(impact)
	impact.global_position = pos
	_fade_and_free(impact, IMPACT_LIFE_SEC)


static func _make_glow_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat


static func _fade_and_free(node: Node3D, life: float) -> void:
	var mat: StandardMaterial3D = node.material_override
	var tween := node.create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, life)
	tween.parallel().tween_property(mat, "emission_energy_multiplier", 0.0, life)
	tween.tween_callback(node.queue_free)

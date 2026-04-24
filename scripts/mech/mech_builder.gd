class_name MechBuilder
extends RefCounted

# v0.1: builds a primitive greybox mech (boxes + cylinders) as children of the
# target CharacterBody3D. v0.2+ will replace the internals with runtime
# composition from real 3D part assets (one asset per head / core / arms /
# legs / weapon slot, sourced from CC0 kitbash, AI-generation, or community).
# The `build_greybox(target, is_enemy)` signature should stay stable so the
# parts system can drop in without rippling changes through callers.

const ENEMY_TINT: Color = Color(0.72, 0.24, 0.24)
const PLAYER_TINT: Color = Color(0.38, 0.52, 0.66)
const ACCENT_TINT: Color = Color(0.18, 0.20, 0.22)


static func build_greybox(target: CharacterBody3D, is_enemy: bool = false) -> void:
	_add_collision(target)
	var body_mat := _make_material(ENEMY_TINT if is_enemy else PLAYER_TINT)
	var accent_mat := _make_material(ACCENT_TINT)
	_add_legs(target, body_mat)
	_add_torso(target, body_mat, accent_mat)
	_add_head(target, accent_mat)
	_add_arms(target, body_mat, accent_mat)


static func _add_collision(target: CharacterBody3D) -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.9
	capsule.height = 3.8
	shape.shape = capsule
	shape.position = Vector3(0, 1.9, 0)
	target.add_child(shape)


static func _add_legs(target: CharacterBody3D, mat: Material) -> void:
	# Godot convention: -Z is forward. Toes point to -Z.
	for x_offset in [-0.45, 0.45]:
		var leg := _make_box(Vector3(0.6, 1.5, 0.7), Vector3(x_offset, 0.9, 0), mat)
		target.add_child(leg)
		var foot := _make_box(Vector3(0.8, 0.2, 1.1), Vector3(x_offset, 0.1, -0.1), mat)
		target.add_child(foot)


static func _add_torso(target: CharacterBody3D, body_mat: Material, accent_mat: Material) -> void:
	var torso := _make_box(Vector3(1.7, 1.4, 1.0), Vector3(0, 2.35, 0), body_mat)
	target.add_child(torso)
	# Chest plate on the front face (-Z side) of the torso.
	var chest_plate := _make_box(Vector3(1.2, 0.8, 0.15), Vector3(0, 2.5, -0.55), accent_mat)
	target.add_child(chest_plate)


static func _add_head(target: CharacterBody3D, mat: Material) -> void:
	var neck := _make_box(Vector3(0.4, 0.3, 0.4), Vector3(0, 3.1, 0), mat)
	target.add_child(neck)
	# Slight forward-lean of the head.
	var head := _make_box(Vector3(0.8, 0.55, 0.7), Vector3(0, 3.4, -0.05), mat)
	target.add_child(head)


static func _add_arms(target: CharacterBody3D, body_mat: Material, accent_mat: Material) -> void:
	for side_x in [-1.15, 1.15]:
		var shoulder := _make_box(Vector3(0.5, 0.5, 0.6), Vector3(side_x, 2.7, 0), body_mat)
		target.add_child(shoulder)
		var arm := _make_box(Vector3(0.45, 1.1, 0.45), Vector3(side_x, 2.0, 0), body_mat)
		target.add_child(arm)
		# Barrels mounted forward of the arms. _make_cylinder's -90° X rotation
		# aligns the cylinder along -Z so the muzzle tip ends up further forward.
		var barrel := _make_cylinder(0.14, 1.2, Vector3(side_x, 2.0, -0.9), accent_mat)
		target.add_child(barrel)


static func _make_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.35
	mat.roughness = 0.65
	return mat


static func _make_box(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	return mi


static func _make_cylinder(
	radius: float, height: float, pos: Vector3, mat: Material
) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = Vector3(-90, 0, 0)
	return mi

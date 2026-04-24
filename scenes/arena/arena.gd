extends Node3D

const ARENA_SIZE: float = 80.0
const RETURN_ZONE_POS: Vector3 = Vector3(0, 0.3, 36.0)
const KILL_PLANE_Y: float = -20.0
const RESPAWN_DELAY_SEC: float = 2.0

var player: Mech
var return_area: Area3D
var return_label: Label3D
var player_in_return: bool = false
var _respawn_triggered: bool = false


func _ready() -> void:
	_build_ground()
	_build_worldenvironment()
	_build_cover()
	_build_return_zone()
	_spawn_player()
	player.died.connect(_on_player_died)
	_spawn_enemies()
	_spawn_hud()


func _process(_delta: float) -> void:
	if player_in_return and Input.is_action_just_pressed("interact"):
		SaveManager.save_game()
		SceneManager.go_to_hub()
	_check_kill_plane()


func _check_kill_plane() -> void:
	if player == null or player.is_dead:
		return
	if player.global_position.y < KILL_PLANE_Y:
		# Overkill guarantees the died signal fires regardless of max_health tuning.
		player.take_damage(player.max_health * 10.0)


func _on_player_died() -> void:
	if _respawn_triggered:
		return
	_respawn_triggered = true
	await get_tree().create_timer(RESPAWN_DELAY_SEC).timeout
	SceneManager.go_to_hub()


func _build_ground() -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(ARENA_SIZE, 1.0, ARENA_SIZE)
	col.shape = shape
	body.add_child(col)
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(ARENA_SIZE, 1.0, ARENA_SIZE)
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.24, 0.26)
	mat.roughness = 0.9
	mi.material_override = mat
	body.add_child(mi)
	body.position = Vector3(0, -0.5, 0)
	add_child(body)


func _build_worldenvironment() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()

	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.33, 0.40, 0.36)

	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.65, 0.60)
	env.ambient_light_energy = 0.55

	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.035
	env.volumetric_fog_albedo = Color(0.42, 0.55, 0.48)

	env.fog_enabled = true
	env.fog_light_color = Color(0.4, 0.55, 0.5)
	env.fog_density = 0.012

	env.glow_enabled = true
	env.glow_intensity = 0.85
	env.glow_bloom = 0.22
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT

	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.1

	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 0.93

	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -35, 0)
	sun.light_energy = 0.9
	sun.light_color = Color(1.0, 0.95, 0.85)
	sun.shadow_enabled = true
	add_child(sun)


func _build_cover() -> void:
	var cube_mat := StandardMaterial3D.new()
	cube_mat.albedo_color = Color(0.4, 0.42, 0.44)
	cube_mat.roughness = 0.78

	var spawns := [
		{"size": Vector3(4, 5, 4), "pos": Vector3(10, 2.5, -5)},
		{"size": Vector3(6, 5, 3), "pos": Vector3(-12, 2.5, -10)},
		{"size": Vector3(5, 7, 5), "pos": Vector3(5, 3.5, -25)},
		{"size": Vector3(3, 9, 8), "pos": Vector3(-8, 4.5, 5)},
		{"size": Vector3(4, 5, 4), "pos": Vector3(18, 2.5, 10)},
		{"size": Vector3(6, 6, 5), "pos": Vector3(-20, 3, -20)},
		{"size": Vector3(5, 4, 5), "pos": Vector3(22, 2.0, -15)},
	]
	for spawn in spawns:
		_make_cover(spawn["size"], spawn["pos"], cube_mat)


func _build_return_zone() -> void:
	var marker_mat := StandardMaterial3D.new()
	marker_mat.albedo_color = Color(0.9, 0.45, 0.2)
	marker_mat.emission_enabled = true
	marker_mat.emission = Color(1.0, 0.5, 0.2)
	marker_mat.emission_energy_multiplier = 2.2

	var marker := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 3.5
	mesh.bottom_radius = 3.5
	mesh.height = 0.2
	marker.mesh = mesh
	marker.material_override = marker_mat
	marker.position = RETURN_ZONE_POS
	add_child(marker)

	return_area = Area3D.new()
	return_area.position = RETURN_ZONE_POS
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 4.0
	shape.height = 6.0
	col.shape = shape
	return_area.add_child(col)
	return_area.body_entered.connect(_on_return_enter)
	return_area.body_exited.connect(_on_return_exit)
	add_child(return_area)

	return_label = Label3D.new()
	return_label.text = "RETURN TO HUB  [E]"
	return_label.position = RETURN_ZONE_POS + Vector3(0, 4.0, 0)
	return_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	return_label.modulate = Color(1.0, 0.72, 0.35)
	return_label.font_size = 42
	return_label.visible = false
	add_child(return_label)


func _on_return_enter(body: Node) -> void:
	if body is Mech and not (body as Mech).is_enemy:
		player_in_return = true
		return_label.visible = true


func _on_return_exit(body: Node) -> void:
	if body is Mech and not (body as Mech).is_enemy:
		player_in_return = false
		return_label.visible = false


func _spawn_player() -> void:
	player = Mech.new()
	player.is_enemy = false
	player.position = Vector3(0, 0.2, 32)
	add_child(player)


func _spawn_enemies() -> void:
	var positions := [
		Vector3(2, 0.2, -18),
		Vector3(-10, 0.2, -5),
	]
	for pos in positions:
		var grunt: CharacterBody3D = preload("res://scripts/enemy/grunt.gd").new()
		grunt.position = pos
		add_child(grunt)


func _spawn_hud() -> void:
	var hud: CanvasLayer = preload("res://scripts/ui/hud.gd").new()
	add_child(hud)


func _make_cover(size: Vector3, pos: Vector3, mat: Material) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	body.add_child(mi)
	add_child(body)

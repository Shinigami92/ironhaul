@tool
extends Node3D

# `@tool` so the static city geometry renders inside the Godot editor when
# arena.tscn is opened. Dynamic spawning (player, enemies, HUD, signal wiring)
# is guarded by `Engine.is_editor_hint()` so the editor only shows the world,
# not runtime entities.

const ARENA_HALF: float = 250.0  # full arena is 500×500m
const WALL_HEIGHT: float = 30.0
const WALL_THICKNESS: float = 2.0
const KILL_PLANE_Y: float = -20.0
const PLAYER_RESPAWN_DELAY_SEC: float = 2.0
const GRUNT_RESPAWN_DELAY_SEC: float = 10.0

const RETURN_ZONE_POS: Vector3 = Vector3(180, 0.3, -180)
const PLAYER_SPAWN_POS: Vector3 = Vector3(0, 0.2, 0)

const GROUND_COLOR: Color = Color(0.22, 0.24, 0.26)
const WALL_COLOR: Color = Color(0.18, 0.20, 0.22)
const BUILDING_COLOR: Color = Color(0.30, 0.32, 0.34)
const PLATFORM_COLOR: Color = Color(0.40, 0.36, 0.28)
const PLAZA_COVER_COLOR: Color = Color(0.40, 0.42, 0.44)

# Tall, varied "building" boxes clustered in four cardinal districts plus two
# smaller diagonal clusters. Edit entries here to reshape the city — arena.gd
# rebuilds the full layout whenever the scene is (re)loaded.
const BUILDINGS: Array = [
	# North district
	{"pos": Vector3(0, 15, -150), "size": Vector3(22, 30, 16)},
	{"pos": Vector3(-40, 18, -170), "size": Vector3(20, 36, 18)},
	{"pos": Vector3(40, 14, -170), "size": Vector3(18, 28, 20)},
	{"pos": Vector3(-20, 22, -200), "size": Vector3(16, 44, 22)},
	{"pos": Vector3(30, 20, -200), "size": Vector3(22, 40, 18)},
	{"pos": Vector3(-60, 12, -220), "size": Vector3(24, 24, 20)},
	# South district
	{"pos": Vector3(0, 16, 150), "size": Vector3(24, 32, 18)},
	{"pos": Vector3(-35, 14, 170), "size": Vector3(18, 28, 16)},
	{"pos": Vector3(45, 20, 170), "size": Vector3(20, 40, 20)},
	{"pos": Vector3(-15, 22, 200), "size": Vector3(22, 44, 18)},
	{"pos": Vector3(40, 18, 210), "size": Vector3(18, 36, 22)},
	{"pos": Vector3(-50, 15, 225), "size": Vector3(26, 30, 18)},
	# East district
	{"pos": Vector3(150, 18, 0), "size": Vector3(16, 36, 22)},
	{"pos": Vector3(180, 14, -30), "size": Vector3(20, 28, 18)},
	{"pos": Vector3(160, 20, 40), "size": Vector3(18, 40, 20)},
	{"pos": Vector3(210, 22, 10), "size": Vector3(22, 44, 18)},
	{"pos": Vector3(190, 16, 55), "size": Vector3(20, 32, 16)},
	{"pos": Vector3(220, 12, -45), "size": Vector3(18, 24, 22)},
	# West district
	{"pos": Vector3(-150, 16, 0), "size": Vector3(20, 32, 20)},
	{"pos": Vector3(-175, 20, -35), "size": Vector3(18, 40, 18)},
	{"pos": Vector3(-155, 14, 35), "size": Vector3(22, 28, 20)},
	{"pos": Vector3(-205, 18, 5), "size": Vector3(16, 36, 22)},
	{"pos": Vector3(-190, 22, -50), "size": Vector3(20, 44, 18)},
	{"pos": Vector3(-215, 14, 55), "size": Vector3(22, 28, 16)},
	# NE small cluster
	{"pos": Vector3(120, 16, -130), "size": Vector3(18, 32, 20)},
	{"pos": Vector3(145, 20, -145), "size": Vector3(16, 40, 18)},
	{"pos": Vector3(105, 14, -155), "size": Vector3(20, 28, 22)},
	# SW small cluster
	{"pos": Vector3(-125, 16, 130), "size": Vector3(20, 32, 18)},
	{"pos": Vector3(-150, 18, 145), "size": Vector3(18, 36, 20)},
	{"pos": Vector3(-110, 14, 155), "size": Vector3(22, 28, 16)},
]

# Thin elevated slabs between the plaza and the outer districts. Thrust-up to
# reach them for a temporary high ground.
const PLATFORMS: Array = [
	{"pos": Vector3(-30, 7, -60), "size": Vector3(12, 1, 10)},
	{"pos": Vector3(30, 8, 60), "size": Vector3(14, 1, 12)},
	{"pos": Vector3(60, 7, 0), "size": Vector3(12, 1, 12)},
	{"pos": Vector3(-60, 8, 20), "size": Vector3(10, 1, 10)},
]

# Small cover blocks scattered across the central plaza.
const PLAZA_COVER: Array = [
	{"pos": Vector3(15, 2.5, 15), "size": Vector3(5, 5, 5)},
	{"pos": Vector3(-18, 3.0, 20), "size": Vector3(6, 6, 5)},
	{"pos": Vector3(25, 2.0, -20), "size": Vector3(5, 4, 5)},
	{"pos": Vector3(-25, 2.5, -15), "size": Vector3(5, 5, 6)},
	{"pos": Vector3(5, 3.0, 40), "size": Vector3(4, 6, 4)},
	{"pos": Vector3(0, 2.5, -40), "size": Vector3(6, 5, 4)},
]

# Grunt spawn points — one grunt spawns per point on arena load, and the
# corresponding point respawns GRUNT_RESPAWN_DELAY_SEC after each death.
const ENEMY_SPAWN_POINTS: Array[Vector3] = [
	Vector3(0, 0.2, -100),
	Vector3(0, 0.2, 100),
	Vector3(100, 0.2, 0),
	Vector3(-100, 0.2, 0),
	Vector3(80, 0.2, -80),
	Vector3(-80, 0.2, 80),
]

const GRUNT_SCRIPT := preload("res://src/enemy/grunt/grunt.gd")
const HUD_SCRIPT := preload("res://src/ui/hud/hud.gd")

var player: Mech
var return_area: Area3D
var return_label: Label3D
var player_in_return: bool = false

var _player_respawn_triggered: bool = false


func _ready() -> void:
	_build_ground()
	_build_worldenvironment()
	_build_perimeter_walls()
	_build_boxes(BUILDINGS, BUILDING_COLOR)
	_build_boxes(PLATFORMS, PLATFORM_COLOR)
	_build_boxes(PLAZA_COVER, PLAZA_COVER_COLOR)
	_build_return_zone_marker()

	if Engine.is_editor_hint():
		return

	_build_return_zone_trigger()
	_spawn_player()
	player.died.connect(_on_player_died)
	_spawn_initial_grunts()
	_spawn_hud()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if player_in_return and Input.is_action_just_pressed("interact"):
		SaveManager.save_game()
		SceneManager.go_to_hub()
	_check_kill_plane()


func _check_kill_plane() -> void:
	for node in get_tree().get_nodes_in_group("player_mech"):
		_maybe_kill_by_plane(node)
	for node in get_tree().get_nodes_in_group("enemy_mech"):
		_maybe_kill_by_plane(node)


func _maybe_kill_by_plane(node: Node) -> void:
	if not (node is Mech):
		return
	var mech := node as Mech
	if mech.is_dead:
		return
	if mech.global_position.y < KILL_PLANE_Y:
		# Overkill guarantees the died signal fires regardless of max_health tuning.
		mech.take_damage(mech.max_health * 10.0)


func _on_player_died() -> void:
	if _player_respawn_triggered:
		return
	_player_respawn_triggered = true
	await get_tree().create_timer(PLAYER_RESPAWN_DELAY_SEC).timeout
	SceneManager.go_to_hub()


func _spawn_initial_grunts() -> void:
	for i in ENEMY_SPAWN_POINTS.size():
		_spawn_grunt_at(i)


func _spawn_grunt_at(spawn_index: int) -> void:
	var grunt: Grunt = GRUNT_SCRIPT.new()
	grunt.position = ENEMY_SPAWN_POINTS[spawn_index]
	grunt.died.connect(_on_grunt_died.bind(spawn_index))
	add_child(grunt)


func _on_grunt_died(spawn_index: int) -> void:
	await get_tree().create_timer(GRUNT_RESPAWN_DELAY_SEC).timeout
	if not is_inside_tree():
		return
	_spawn_grunt_at(spawn_index)


# ---- Static geometry ---------------------------------------------------------


func _build_ground() -> void:
	var size := Vector3(ARENA_HALF * 2.0, 1.0, ARENA_HALF * 2.0)
	_make_static_box(size, Vector3(0, -0.5, 0), GROUND_COLOR)


func _build_perimeter_walls() -> void:
	var half := ARENA_HALF
	var y := WALL_HEIGHT * 0.5
	var long_size := Vector3(half * 2.0, WALL_HEIGHT, WALL_THICKNESS)
	var wide_size := Vector3(WALL_THICKNESS, WALL_HEIGHT, half * 2.0)
	_make_static_box(long_size, Vector3(0, y, -half), WALL_COLOR)
	_make_static_box(long_size, Vector3(0, y, half), WALL_COLOR)
	_make_static_box(wide_size, Vector3(-half, y, 0), WALL_COLOR)
	_make_static_box(wide_size, Vector3(half, y, 0), WALL_COLOR)


func _build_boxes(specs: Array, color: Color) -> void:
	for spec in specs:
		_make_static_box(spec["size"], spec["pos"], color)


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


func _build_return_zone_marker() -> void:
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


# ---- Runtime-only -----------------------------------------------------------


func _build_return_zone_trigger() -> void:
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
	player.position = PLAYER_SPAWN_POS
	add_child(player)


func _spawn_hud() -> void:
	var hud: CanvasLayer = HUD_SCRIPT.new()
	add_child(hud)


func _make_static_box(size: Vector3, pos: Vector3, color: Color) -> void:
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
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mi.material_override = mat
	body.add_child(mi)
	add_child(body)

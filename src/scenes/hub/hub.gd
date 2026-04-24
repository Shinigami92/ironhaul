extends Node3D

const HUB_SIZE: float = 30.0
const HUB_HEIGHT: float = 14.0

var player: Mech
var terminal_area: Area3D
var prompt_label: Label3D
var player_in_terminal: bool = false


func _ready() -> void:
	_build_environment()
	_build_lighting()
	_build_terminal()
	_spawn_player()
	_spawn_hud()


func _process(_delta: float) -> void:
	if player_in_terminal and Input.is_action_just_pressed("interact"):
		SaveManager.save_game()
		SceneManager.go_to_arena()


func _build_environment() -> void:
	var h := HUB_HEIGHT
	var s := HUB_SIZE
	var half := s * 0.5
	var wall_color := Color(0.36, 0.38, 0.42)
	_make_static_box(Vector3(s, 1, s), Vector3(0, -0.5, 0), Color(0.28, 0.30, 0.32))
	_make_static_box(Vector3(s, 1, s), Vector3(0, h + 0.5, 0), Color(0.16, 0.17, 0.19))
	_make_static_box(Vector3(s, h, 1), Vector3(0, h * 0.5, -half), wall_color)
	_make_static_box(Vector3(s, h, 1), Vector3(0, h * 0.5, half), wall_color)
	_make_static_box(Vector3(1, h, s), Vector3(-half, h * 0.5, 0), wall_color)
	_make_static_box(Vector3(1, h, s), Vector3(half, h * 0.5, 0), wall_color)


func _build_lighting() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.08, 0.10)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.62, 0.68)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.5
	world_env.environment = env
	add_child(world_env)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, 30, 0)
	light.light_energy = 0.55
	add_child(light)


func _build_terminal() -> void:
	var pedestal_mat := StandardMaterial3D.new()
	pedestal_mat.albedo_color = Color(0.22, 0.45, 0.42)
	pedestal_mat.emission_enabled = true
	pedestal_mat.emission = Color(0.25, 0.9, 0.8)
	pedestal_mat.emission_energy_multiplier = 1.8
	pedestal_mat.metallic = 0.3

	var pedestal := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.2, 2.8, 2.2)
	pedestal.mesh = mesh
	pedestal.material_override = pedestal_mat
	pedestal.position = Vector3(0, 1.4, -HUB_SIZE * 0.5 + 4.0)
	add_child(pedestal)

	terminal_area = Area3D.new()
	terminal_area.position = pedestal.position
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(7, 6, 7)
	col.shape = shape
	terminal_area.add_child(col)
	terminal_area.body_entered.connect(_on_terminal_enter)
	terminal_area.body_exited.connect(_on_terminal_exit)
	add_child(terminal_area)

	prompt_label = Label3D.new()
	prompt_label.text = "DEPLOY  [E]"
	prompt_label.position = pedestal.position + Vector3(0, 4.0, 0)
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.modulate = Color(0.35, 1.0, 0.92)
	prompt_label.font_size = 48
	prompt_label.visible = false
	add_child(prompt_label)


func _on_terminal_enter(body: Node) -> void:
	if body is Mech and not (body as Mech).is_enemy:
		player_in_terminal = true
		prompt_label.visible = true


func _on_terminal_exit(body: Node) -> void:
	if body is Mech and not (body as Mech).is_enemy:
		player_in_terminal = false
		prompt_label.visible = false


func _spawn_player() -> void:
	player = Mech.new()
	player.is_enemy = false
	player.position = Vector3(0, 0.1, HUB_SIZE * 0.5 - 4.0)
	add_child(player)


func _spawn_hud() -> void:
	var hud: CanvasLayer = preload("res://src/ui/hud/hud.gd").new()
	add_child(hud)


func _make_static_box(size: Vector3, pos: Vector3, color: Color) -> StaticBody3D:
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
	return body

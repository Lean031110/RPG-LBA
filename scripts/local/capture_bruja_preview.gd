extends SceneTree
## Captura de evidencia del puppet procedural de la Bruja (Fase 2): montaje
## visual ( tunica, panuelo, orbe orbitando) y un cast de la Espina de Jucaro
## contra un maniqui de pruebas. Herramienta local de revision artistica.
## Uso: godot --path . --script res://scripts/local/capture_bruja_preview.gd -- <salida.png>

var _frames := 0
var _root: Node = null
var _player: Node = null
var _output := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 1:
		_output = String(args[0])
	DisplayServer.window_set_size(Vector2i(1280, 720))


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 5 and _root == null:
		_root = Node3D.new()
		root.add_child(_root)
		var player_script: GDScript = load("res://scripts/arpg/player/arpg_player.gd")
		_player = player_script.new()
		_root.add_child(_player)
		_player.setup("bruja")
		_player.level = 5
		_player.global_position = Vector3(0, 0.5, 0)
		# Suelo y luz para lectura visual.
		var ground := MeshInstance3D.new()
		var plane := PlaneMesh.new()
		plane.size = Vector2(24, 24)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.3, 0.38, 0.26)
		plane.material = material
		ground.mesh = plane
		_root.add_child(ground)
		# Suelo FISICO: sin el, el CharacterBody3D del jugador cae por gravedad.
		var floor_body := StaticBody3D.new()
		var floor_shape := CollisionShape3D.new()
		var floor_box := BoxShape3D.new()
		floor_box.size = Vector3(24, 0.2, 24)
		floor_shape.shape = floor_box
		floor_body.add_child(floor_shape)
		floor_body.position = Vector3(0, -0.1, 0)
		_root.add_child(floor_body)
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-45, 30, 0)
		light.light_energy = 1.1
		_root.add_child(light)
		var camera := Camera3D.new()
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = 50.0
		camera.global_position = Vector3(2.6, 1.6, 3.4)
		_root.add_child(camera)
		camera.look_at(Vector3(0, 1.0, -1.0), Vector3.UP)
		camera.current = true
		return false
	if _frames == 40:
		# Cast de la Espina de Jucaro (proyectil penetrante) de frente.
		_player.rotate_y(PI * 0.5)
		_player.kit.try_skill_index(0)
	if _frames == 90:
		if _output != "":
			var image := root.get_viewport().get_texture().get_image()
			image.save_png(ProjectSettings.globalize_path(_output))
			print("CAPTURED ", _output, " ", image.get_size())
		return true
	return false

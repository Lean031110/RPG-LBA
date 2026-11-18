extends Node3D
## Escena de revision aislada del puppet y kit del Sepulturero de Guanabacoa
## (Fase 2, tercera clase). No sustituye la vertical slice jugable (esa sigue
## siendo del Machetero): es la vitrina de la clase, como bruja_preview.

var _player: Node = null


func _ready() -> void:
	# Suelo visual + fisico (el jugador es CharacterBody3D: sin suelo cae).
	var ground := MeshInstance3D.new()
	ground.name = "Suelo"
	var plane := PlaneMesh.new()
	plane.size = Vector2(24, 24)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.34, 0.33, 0.30)
	ground.mesh = plane
	ground.material_override = material
	add_child(ground)
	var floor_body := StaticBody3D.new()
	floor_body.name = "SueloFisico"
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(24, 0.2, 24)
	floor_shape.shape = floor_box
	floor_body.add_child(floor_shape)
	# Capa WORLD del proyecto: el CharacterBody3D del jugador colisiona solo
	# contra esa capa; sin ella caeria a traves del suelo.
	floor_body.collision_layer = ArpgLayers.WORLD
	floor_body.position = Vector3(0, -0.1, 0)
	add_child(floor_body)
	var light := DirectionalLight3D.new()
	light.name = "Sol"
	light.rotation_degrees = Vector3(-45, 30, 0)
	light.light_energy = 1.1
	add_child(light)
	# Jugador: Sepulturero de Guanabacoa con nivel 5 (kit completo desbloqueado).
	var player_script: GDScript = load("res://scripts/arpg/player/arpg_player.gd")
	_player = player_script.new()
	add_child(_player)
	_player.setup("sepulturero")
	_player.level = 5
	_player.global_position = Vector3(0, 0.5, 0)
	# Camara de revision: tres cuartos frontales a altura de ojo.
	var camera := Camera3D.new()
	camera.name = "PreviewCamera"
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 50.0
	add_child(camera)
	camera.global_position = Vector3(2.4, 1.5, 3.2)
	camera.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	camera.current = true
	# Cast de la Llamada del Osario: el guardián espectral nace delante del
	# Sepulturero y se pone a escoltarlo (evidencia del sistema de invocaciones).
	_player.rotate_y(PI * 0.5)
	_player.kit.try_skill_index(0)

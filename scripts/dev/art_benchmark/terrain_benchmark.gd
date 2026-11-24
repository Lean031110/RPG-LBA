class_name TerrainArtBenchmark
extends Node3D
## Escena de desarrollo aislada para comparar materiales de Valdeluz.
## No participa en la lógica de la slice ni crea recursos externos.

const SAMPLE_LAYOUT: Array[Dictionary] = [
	{"name": "Grass", "label": "CÉSPED", "material_key": "grass"},
	{"name": "RedDirt", "label": "TIERRA ROJA", "material_key": "red_dirt"},
	{"name": "Limestone", "label": "CALIZA", "material_key": "limestone"},
	{"name": "Mud", "label": "BARRO", "material_key": "mud"},
	{"name": "WetMud", "label": "CHARCO HÚMEDO", "material_key": "puddle_wet"},
]

const SAMPLE_SPACING := 4.4
const SAMPLE_WIDTH := 4.0
const SAMPLE_DEPTH := 5.4
const CAMERA_SIZE := 12.4

var palette: Dictionary = {}
var environment_controller: EnvironmentController = null


func _ready() -> void:
	palette = TerrainMaterialLibrary.create_valdeluz_palette()
	_build_environment()
	_build_backing_ground()
	_build_samples()
	_build_camera()


func _build_environment() -> void:
	environment_controller = EnvironmentController.new()
	environment_controller.name = "EnvironmentController"
	environment_controller.auto_advance = false
	environment_controller.enable_rain_particles = false
	environment_controller.start_time_hours = 12.0
	add_child(environment_controller)
	environment_controller.set_world_time_hours(12.0)
	# El benchmark compara albedo, ruido y respuesta de material con luz fija;
	# sombras dinámicas ni niebla forman parte de esta prueba de terreno.
	environment_controller.set_process(false)
	if environment_controller.active_environment != null:
		environment_controller.active_environment.fog_enabled = false
	if environment_controller.sun_light != null:
		# El keyframe solar de mediodía del controlador actual apunta hacia arriba.
		# Se usa una dirección descendente solo en este banco para exponer los albedos;
		# la orientación del ciclo de juego queda fuera del alcance de este cambio.
		environment_controller.sun_light.rotation_degrees = Vector3(-50.0, 34.0, 0.0)
		environment_controller.sun_light.light_energy = 1.0
		environment_controller.sun_light.shadow_enabled = false


func _build_backing_ground() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "BackingGround"
	var plane := PlaneMesh.new()
	plane.size = Vector2(32.0, 20.0)
	ground.mesh = plane
	# Fondo neutro para que el parche de césped pueda distinguirse de la base.
	ground.material_override = VisualKit.flat_material(Color(0.34, 0.35, 0.34))
	ground.position = Vector3(0.0, -0.19, 0.0)
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ground)


func _build_samples() -> void:
	var samples := Node3D.new()
	samples.name = "MaterialSamples"
	add_child(samples)
	var first_x := -SAMPLE_SPACING * float(SAMPLE_LAYOUT.size() - 1) * 0.5
	for index: int in SAMPLE_LAYOUT.size():
		var spec: Dictionary = SAMPLE_LAYOUT[index]
		var sample := Node3D.new()
		sample.name = String(spec["name"])
		sample.position.x = first_x + SAMPLE_SPACING * float(index)
		samples.add_child(sample)
		_add_surface(sample, String(spec["material_key"]))
		_add_label(sample, String(spec["label"]))
		_add_material_detail(sample, String(spec["material_key"]))


func _add_surface(sample: Node3D, material_key: String) -> void:
	var surface := VisualKit.add_box(
		sample, Vector3(SAMPLE_WIDTH, 0.12, SAMPLE_DEPTH), Vector3(0.0, -0.07, 0.0), palette[material_key]
	)
	surface.name = "Surface"
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _add_label(sample: Node3D, label_text: String) -> void:
	var label := Label3D.new()
	label.name = "MaterialLabel"
	label.text = label_text
	label.font_size = 30
	label.pixel_size = 0.012
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.96, 0.88, 0.70)
	label.outline_size = 6
	label.outline_modulate = Color(0.08, 0.075, 0.065)
	label.position = Vector3(0.0, 0.28, SAMPLE_DEPTH * 0.5 - 0.15)
	sample.add_child(label)


func _add_material_detail(sample: Node3D, material_key: String) -> void:
	match material_key:
		"grass":
			var tuft_material: Material = palette["wind_tuft"]
			for tuft_index: int in 3:
				var side := float(tuft_index - 1)
				VisualKit.add_cone(sample, 0.12, 0.48, Vector3(side * 0.85, 0.24, -1.25 + side * 0.25), tuft_material)
		"red_dirt":
			var tracks_material: Material = palette["wheel_tracks"]
			for side: float in [-0.7, 0.7]:
				VisualKit.add_box(sample, Vector3(0.26, 0.025, 4.35), Vector3(side, 0.0025, -0.15), tracks_material)
		"limestone":
			var stone := VisualKit.add_sphere(sample, 0.34, Vector3(-1.15, 0.24, -0.95), palette["limestone"])
			stone.scale = Vector3(1.25, 0.7, 1.0)
			var moss := VisualKit.add_sphere(sample, 0.22, Vector3(-0.95, 0.17, -0.78), palette["moss"])
			moss.scale = Vector3(1.2, 0.42, 0.9)
		"puddle_wet":
			var puddle := VisualKit.add_sphere(sample, 0.7, Vector3(0.0, 0.015, -0.7), palette["puddle_wet"])
			puddle.scale = Vector3(1.45, 0.055, 0.78)
			puddle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "BenchmarkCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = CAMERA_SIZE
	camera.near = 0.1
	camera.far = 100.0
	add_child(camera)
	camera.global_position = Vector3(0.0, 13.0, 18.0)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	camera.current = true

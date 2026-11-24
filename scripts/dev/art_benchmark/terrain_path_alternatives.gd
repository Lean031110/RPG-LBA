class_name TerrainPathAlternatives
extends Node3D
## Banco aislado para comparar tres lecturas de camino en Valdeluz.
## No modifica ni sustituye la geometría de la escena jugable.
const PANEL_SPECS: Array[Dictionary] = [
	{"name": "StraightRoad", "title": "A · FRANJA RECTA", "kind": "straight"},
	{"name": "NoRoad", "title": "B · SIN CAMINO", "kind": "none"},
	{"name": "OrganicRoad", "title": "C · SENDERO ORGÁNICO", "kind": "organic"},
]
const PANEL_SPACING := 10.0
const PANEL_WIDTH := 8.8
const PANEL_DEPTH := 17.2
const TRAIL_LENGTH := 15.8
const TRAIL_SEGMENTS := 48
const ORGANIC_HALF_WIDTH := 1.25
const CAMERA_VERTICAL_SIZE := 18.4
var palette: Dictionary = {}
var environment_controller: EnvironmentController = null


func _ready() -> void:
	palette = TerrainMaterialLibrary.create_valdeluz_palette()
	_build_environment()
	_build_panels()
	_build_camera()


func _build_environment() -> void:
	environment_controller = EnvironmentController.new()
	environment_controller.name = "EnvironmentController"
	environment_controller.auto_advance = false
	environment_controller.enable_rain_particles = false
	environment_controller.start_time_hours = 12.0
	add_child(environment_controller)
	environment_controller.set_world_time_hours(12.0)
	environment_controller.set_process(false)
	if environment_controller.active_environment != null:
		environment_controller.active_environment.fog_enabled = false
	if environment_controller.sun_light != null:
		environment_controller.sun_light.rotation_degrees = Vector3(-48.0, 24.0, 0.0)
		environment_controller.sun_light.light_energy = 1.0
		environment_controller.sun_light.shadow_enabled = false


func _build_panels() -> void:
	var panels := Node3D.new()
	panels.name = "Panels"
	add_child(panels)
	for index: int in PANEL_SPECS.size():
		var spec: Dictionary = PANEL_SPECS[index]
		var panel := Node3D.new()
		panel.name = String(spec["name"])
		panel.position.x = (float(index) - 1.0) * PANEL_SPACING
		panels.add_child(panel)
		_build_panel(panel, spec)


func _build_panel(panel: Node3D, spec: Dictionary) -> void:
	var ground := VisualKit.add_box(
		panel, Vector3(PANEL_WIDTH, 0.18, PANEL_DEPTH), Vector3(0.0, -0.1, 0.0), palette["grass"]
	)
	ground.name = "GrassTerrain"
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var kind := String(spec["kind"])
	if kind == "straight":
		_build_straight_road(panel)
	elif kind == "organic":
		_build_organic_road(panel)
	_build_edge_grass(panel, kind)
	_add_player_reference(panel, kind)
	_add_panel_label(panel, String(spec["title"]))


func _build_straight_road(panel: Node3D) -> void:
	var road := VisualKit.add_box(
		panel, Vector3(4.6, 0.035, PANEL_DEPTH - 0.12), Vector3(0.0, 0.008, 0.0), palette["red_dirt"]
	)
	road.name = "BroadStraightRoad"
	road.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for side: float in [-0.78, 0.78]:
		var rut := VisualKit.add_box(
			panel, Vector3(0.32, 0.018, PANEL_DEPTH - 0.45), Vector3(side, 0.036, 0.0), palette["wheel_tracks"]
		)
		rut.name = "StraightWheelTrack"
		rut.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_organic_road(panel: Node3D) -> void:
	var path := MeshInstance3D.new()
	path.name = "TrailSurface"
	path.mesh = _build_ribbon_mesh(0.0, ORGANIC_HALF_WIDTH, 0.012, false)
	path.material_override = _two_sided_material(palette["red_dirt"] as StandardMaterial3D)
	path.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	panel.add_child(path)
	for spec: Dictionary in [
		{"name": "WheelTrackLeft", "offset": -0.68},
		{"name": "WheelTrackRight", "offset": 0.68},
	]:
		var rut := MeshInstance3D.new()
		rut.name = String(spec["name"])
		rut.mesh = _build_ribbon_mesh(float(spec["offset"]), 0.105, 0.035, true)
		rut.material_override = _two_sided_material(palette["wheel_tracks"] as StandardMaterial3D)
		rut.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		panel.add_child(rut)
	_add_organic_edge_details(panel)


func _two_sided_material(source: StandardMaterial3D) -> StandardMaterial3D:
	var material := source.duplicate() as StandardMaterial3D
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _build_ribbon_mesh(center_offset: float, half_width: float, height: float, is_track: bool) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var material: Material = palette["wheel_tracks"] if is_track else palette["red_dirt"]
	surface.set_material(material)
	for index: int in TRAIL_SEGMENTS:
		var t0 := float(index) / float(TRAIL_SEGMENTS)
		var t1 := float(index + 1) / float(TRAIL_SEGMENTS)
		var left0 := _ribbon_edge(t0, center_offset, half_width, height, -1.0, is_track)
		var right0 := _ribbon_edge(t0, center_offset, half_width, height, 1.0, is_track)
		var left1 := _ribbon_edge(t1, center_offset, half_width, height, -1.0, is_track)
		var right1 := _ribbon_edge(t1, center_offset, half_width, height, 1.0, is_track)
		_add_triangle(surface, left0, left1, right0)
		_add_triangle(surface, right0, left1, right1)
	surface.generate_normals()
	return surface.commit()


func _ribbon_edge(
	t: float, center_offset: float, half_width: float, height: float, side: float, is_track: bool
) -> Vector3:
	var z := lerpf(-TRAIL_LENGTH * 0.5, TRAIL_LENGTH * 0.5, t)
	var center_x := _organic_center_x(t) + center_offset
	var natural_width := half_width
	if not is_track and center_offset == 0.0:
		natural_width += sin(t * 17.0 + 0.6) * 0.14 + sin(t * 7.0) * 0.09
	var edge_wobble := sin(t * 22.0 + side * 1.7) * 0.045
	return Vector3(center_x + side * (natural_width + edge_wobble), height, z)


func _add_triangle(surface: SurfaceTool, first: Vector3, second: Vector3, third: Vector3) -> void:
	for point: Vector3 in [first, second, third]:
		surface.set_uv(Vector2(point.x * 0.16, point.z * 0.16))
		surface.add_vertex(point)


func _organic_center_x(t: float) -> float:
	return sin(t * 3.7 - 0.45) * 1.25 + sin(t * 9.0 + 0.3) * 0.22


func _organic_width_at(t: float) -> float:
	return ORGANIC_HALF_WIDTH + sin(t * 17.0 + 0.6) * 0.14 + sin(t * 7.0) * 0.09


func _add_organic_edge_details(panel: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1953
	for index: int in 12:
		var t := (float(index) + 0.4) / 12.0
		var side := -1.0 if index % 2 == 0 else 1.0
		var z := lerpf(-TRAIL_LENGTH * 0.5 + 0.4, TRAIL_LENGTH * 0.5 - 0.4, t)
		var half_width := _organic_width_at(t)
		var edge_x := _organic_center_x(t) + side * (half_width + rng.randf_range(0.12, 0.32))
		if index % 3 == 0:
			var stone := VisualKit.add_sphere(
				panel, rng.randf_range(0.14, 0.24), Vector3(edge_x, 0.12, z), palette["limestone"]
			)
			stone.scale = Vector3(1.35, 0.55, 0.9)
			stone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for blade_index: int in 3:
			var blade_offset := float(blade_index - 1) * 0.12
			VisualKit.add_cone(
				panel,
				0.055,
				rng.randf_range(0.2, 0.38),
				Vector3(edge_x + blade_offset, 0.12, z + blade_offset * 0.6),
				palette["wind_tuft"]
			)


func _build_edge_grass(panel: Node3D, kind: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1953
	for index: int in 14:
		var z := lerpf(-PANEL_DEPTH * 0.43, PANEL_DEPTH * 0.43, float(index) / 13.0)
		var side := -1.0 if index % 2 == 0 else 1.0
		var x := side * rng.randf_range(3.35, 4.05)
		if kind == "organic" and absf(x - _organic_center_x(float(index) / 13.0)) < 2.1:
			continue
		for blade_index: int in 3:
			var offset := float(blade_index - 1) * 0.11
			VisualKit.add_cone(
				panel, 0.06, rng.randf_range(0.24, 0.43), Vector3(x + offset, 0.12, z + offset), palette["wind_tuft"]
			)


func _add_player_reference(panel: Node3D, kind: String) -> void:
	var player := MacheteroPuppet.new()
	player.name = "PlayerReference"
	var player_x := 0.0
	if kind == "organic":
		player_x = _organic_center_x(0.87)
	player.position = Vector3(player_x, 0.0, 5.9)
	panel.add_child(player)
	player.name = "PlayerReference"


func _add_panel_label(panel: Node3D, text_value: String) -> void:
	var label := Label3D.new()
	label.name = "AlternativeLabel"
	label.text = text_value
	label.font_size = 36
	label.pixel_size = 0.014
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.96, 0.88, 0.70)
	label.outline_size = 6
	label.outline_modulate = Color(0.08, 0.075, 0.065)
	label.position = Vector3(0.0, 2.1, -PANEL_DEPTH * 0.44)
	panel.add_child(label)


func _build_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "BenchmarkCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = CAMERA_VERTICAL_SIZE
	camera.near = 0.1
	camera.far = 100.0
	add_child(camera)
	camera.global_position = Vector3(0.0, 26.0, 26.0)
	camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)
	camera.current = true

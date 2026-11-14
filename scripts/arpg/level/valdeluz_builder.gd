class_name ValdeluzBuilder
## Construcción determinista de las afueras de Valdeluz (vertical slice).
## La densidad procede del perfil activo. La atmósfera vive en un controlador separado.

const LAYOUT_SEED := 20261113
const AREA_MIN_X := -20.0
const AREA_MAX_X := 20.0
const AREA_MIN_Z := -28.0
const AREA_MAX_Z := 26.0
const PATH_HALF_WIDTH := 2.3
const PATH_END_Z := 22.0
const BOUNDARY_MARGIN := 1.6


static func build_all(root: Node3D, density: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = LAYOUT_SEED
	var scaled := clampf(density, 0.1, 1.0)
	var palette := TerrainMaterialLibrary.create_valdeluz_palette()
	_build_ground(root, palette)
	_build_lighting(root)
	_build_boundaries(root, rng, scaled, palette)
	_build_vegetation(root, rng, scaled, palette)
	_build_props(root, rng, palette)


static func play_area_rect() -> Rect2:
	return Rect2(
		AREA_MIN_X + BOUNDARY_MARGIN,
		AREA_MIN_Z + BOUNDARY_MARGIN,
		(AREA_MAX_X - AREA_MIN_X) - BOUNDARY_MARGIN * 2.0,
		(AREA_MAX_Z - AREA_MIN_Z) - BOUNDARY_MARGIN * 2.0
	)


static func _build_ground(root: Node3D, palette: Dictionary) -> void:
	var grass := Node3D.new()
	grass.name = "Ground"
	root.add_child(grass)

	var ground_mesh := MeshInstance3D.new()
	ground_mesh.name = "GroundMesh"
	ground_mesh.mesh = _build_rolling_ground_mesh(
		Vector2((AREA_MAX_X - AREA_MIN_X) + 24.0, (AREA_MAX_Z - AREA_MIN_Z) + 24.0), palette["grass"]
	)
	ground_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	grass.add_child(ground_mesh)

	# Colisión sencilla: el relieve es visual y muy suave para no crear escalones.
	var ground_body := StaticBody3D.new()
	ground_body.name = "GroundBody"
	ground_body.collision_layer = ArpgLayers.WORLD
	ground_body.collision_mask = 0
	var ground_shape := CollisionShape3D.new()
	var ground_box := BoxShape3D.new()
	ground_box.size = Vector3(88.0, 0.4, 102.0)
	ground_shape.shape = ground_box
	ground_body.add_child(ground_shape)
	ground_body.position = Vector3(0.0, -0.2, 0.0)
	grass.add_child(ground_body)

	# Camino de tierra roja con dos roderas.
	var path := Node3D.new()
	path.name = "RedDirtPath"
	grass.add_child(path)
	var path_mesh := VisualKit.add_box(
		path,
		Vector3(PATH_HALF_WIDTH * 2.0, 0.08, PATH_END_Z - AREA_MIN_Z + 2.0),
		Vector3(0.0, 0.045, (PATH_END_Z + AREA_MIN_Z) / 2.0),
		palette["red_dirt"]
	)
	path_mesh.name = "PathMesh"
	var tracks := Node3D.new()
	tracks.name = "WheelTracks"
	path.add_child(tracks)
	for offset_x in [-0.85, 0.85]:
		VisualKit.add_box(
			tracks,
			Vector3(0.55, 0.035, PATH_END_Z - AREA_MIN_Z),
			Vector3(offset_x, 0.09, (PATH_END_Z + AREA_MIN_Z) / 2.0),
			palette["wheel_tracks"]
		)

		# Caliza erosionada y musgo en los bordes.

		# Charcas con brillo humedo (shader wet del Art Pass); sin reflejos ni SSR.
	var stones := Node3D.new()
	stones.name = "Limestone"
	grass.add_child(stones)
	var stone_spots: Array[Vector3] = [
		Vector3(-6.5, 0.0, -6.0),
		Vector3(7.2, 0.0, -1.5),
		Vector3(-8.0, 0.0, 8.0),
		Vector3(6.8, 0.0, 12.5),
		Vector3(-3.4, 0.0, 18.0),
		Vector3(3.9, 0.0, 21.5)
	]
	for spot in stone_spots:
		var rock := VisualKit.add_sphere(
			stones, randf_range_clamped(0.9, 1.4, LAYOUT_SEED), spot + Vector3(0.0, 0.35, 0.0), palette["limestone"]
		)
		rock.scale = Vector3(1.25, 0.62, 1.0)
		VisualKit.add_sphere(stones, 0.55, spot + Vector3(1.6, 0.22, 0.9), palette["limestone"])
		var moss := VisualKit.add_sphere(stones, 0.26, spot + Vector3(-0.45, 0.38, 0.18), palette["moss"])
		moss.scale = Vector3(1.2, 0.45, 0.9)

		# Charcas con brillo humedo (shader wet del Art Pass); sin reflejos ni SSR.
	var mud := Node3D.new()
	mud.name = "MudPatches"
	grass.add_child(mud)
	for patch in [
		Vector3(-4.8, 0.055, 5.5), Vector3(5.1, 0.055, 15.5), Vector3(-9.4, 0.055, -0.5), Vector3(9.2, 0.055, 6.0)
	]:
		var puddle := VisualKit.add_sphere(mud, 0.72, patch, palette["puddle_wet"])
		puddle.scale = Vector3(1.75, 0.08, 0.95)
		puddle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func _build_rolling_ground_mesh(size: Vector2, material: Material) -> ArrayMesh:
	## Pequeño relieve procedural fuera del camino; no requiere físicas adicionales.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(material)
	const SEGMENTS_X := 40
	const SEGMENTS_Z := 52

	for z_index in range(SEGMENTS_Z):
		for x_index in range(SEGMENTS_X):
			var x0 := (float(x_index) / float(SEGMENTS_X) - 0.5) * size.x
			var x1 := (float(x_index + 1) / float(SEGMENTS_X) - 0.5) * size.x
			var z0 := (float(z_index) / float(SEGMENTS_Z) - 0.5) * size.y
			var z1 := (float(z_index + 1) / float(SEGMENTS_Z) - 0.5) * size.y
			var p00 := _terrain_point(x0, z0)
			var p01 := _terrain_point(x0, z1)
			var p10 := _terrain_point(x1, z0)
			var p11 := _terrain_point(x1, z1)
			_add_terrain_vertex(surface, p00)
			_add_terrain_vertex(surface, p01)
			_add_terrain_vertex(surface, p10)
			_add_terrain_vertex(surface, p10)
			_add_terrain_vertex(surface, p01)
			_add_terrain_vertex(surface, p11)
	surface.generate_normals()
	return surface.commit()


static func _terrain_point(x: float, z: float) -> Vector3:
	var path_center := sin((z + 28.0) * 0.035) * 0.55
	var path_distance := absf(x - path_center)
	var relief_factor := clampf((path_distance - 3.2) / 7.0, 0.0, 1.0)
	var relief := sin(x * 0.22 + z * 0.08) * 0.07 + cos(z * 0.16 - x * 0.12) * 0.05
	return Vector3(x, relief * relief_factor, z)


static func _add_terrain_vertex(surface: SurfaceTool, point: Vector3) -> void:
	surface.set_uv(Vector2(point.x * 0.08, point.z * 0.08))
	surface.add_vertex(point)


static func randf_range_clamped(low: float, high: float, seed_value: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng.randf_range(low, high)


static func _build_lighting(root: Node3D) -> void:
	var controller := EnvironmentController.new()
	controller.name = "EnvironmentController"
	controller.day_length_seconds = 1440.0
	controller.start_time_hours = 7.25
	controller.auto_advance = true
	root.add_child(controller)


static func _build_boundaries(root: Node3D, rng: RandomNumberGenerator, density: float, palette: Dictionary) -> void:
	var walls := Node3D.new()
	walls.name = "Boundaries"
	root.add_child(walls)
	var rect := play_area_rect()
	var wall_specs := [
		{"pos": Vector3(0, 1.2, rect.position.y), "size": Vector3(rect.size.x + 2.0, 2.4, 0.8)},
		{"pos": Vector3(0, 1.2, rect.position.y + rect.size.y), "size": Vector3(rect.size.x + 2.0, 2.4, 0.8)},
		{
			"pos": Vector3(rect.position.x, 1.2, rect.position.y + rect.size.y / 2.0),
			"size": Vector3(0.8, 2.4, rect.size.y + 2.0)
		},
		{
			"pos": Vector3(rect.position.x + rect.size.x, 1.2, rect.position.y + rect.size.y / 2.0),
			"size": Vector3(0.8, 2.4, rect.size.y + 2.0)
		}
	]
	for spec: Dictionary in wall_specs:
		var body := StaticBody3D.new()
		body.collision_layer = ArpgLayers.WORLD
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = spec["size"]
		shape.shape = box
		body.add_child(shape)
		body.position = spec["pos"]
		walls.add_child(body)
		# Iteración 4C: los muros del recinto son VISIBLES (antes eran solo
		# colisión invisible) y se registran como oclusores: cuando tapan al
		# jugador, ArpgOcclusionManager los hace semitransparentes. La malla
		# cuelga del StaticBody3D para que el raycast la encuentre.
		var wall_mesh := VisualKit.add_box(
			body, spec["size"], Vector3.ZERO, VisualKit.noise_material(Color(0.44, 0.40, 0.34), 0.15, 3)
		)
		wall_mesh.add_to_group("arpg_occluders")

		# Anillo de palmas y ceibas para enmarcar el horizonte.
	var palms := int(26.0 * density) + 8
	for _index in range(palms):
		var edge := rng.randi_range(0, 3)
		var t := rng.randf()
		var edge_x := rect.position.x + t * rect.size.x
		var edge_z := rect.position.y + t * rect.size.y
		var pos := Vector3.ZERO
		match edge:
			0:
				pos = Vector3(edge_x, 0.0, rect.position.y - 1.2)
			1:
				pos = Vector3(edge_x, 0.0, rect.position.y + rect.size.y + 1.2)
			2:
				pos = Vector3(rect.position.x - 1.2, 0.0, edge_z)
			_:
				pos = Vector3(rect.position.x + rect.size.x + 1.2, 0.0, edge_z)
		_build_palm(walls, pos, rng, palette)
	for corner in [
		Vector3(rect.position.x - 1.5, 0.0, rect.position.y - 1.5),
		Vector3(rect.position.x + rect.size.x + 1.5, 0.0, rect.position.y - 1.5),
		Vector3(rect.position.x - 1.5, 0.0, rect.position.y + rect.size.y + 1.5),
		Vector3(rect.position.x + rect.size.x + 1.5, 0.0, rect.position.y + rect.size.y + 1.5)
	]:
		_build_ceiba(walls, corner, rng, palette)


static func _build_vegetation(root: Node3D, rng: RandomNumberGenerator, density: float, palette: Dictionary) -> void:
	var veg := Node3D.new()
	veg.name = "Vegetation"
	root.add_child(veg)
	var rect := play_area_rect()
	var bush_mat: Material = palette["leaves_mid"]
	var trunk_mat: Material = palette["tree_bark"]

	# Arbustos y maleza separados para no formar una alfombra uniforme.
	var bushes := int(34.0 * density) + 6
	for _index in range(bushes):
		var pos := Vector3(
			rng.randf_range(rect.position.x + 2.0, rect.position.x + rect.size.x - 2.0),
			0.0,
			rng.randf_range(rect.position.y + 2.0, rect.position.y + rect.size.y - 2.0)
		)
		if absf(pos.x) < PATH_HALF_WIDTH + 1.2:
			pos.x += signf(pos.x) * (PATH_HALF_WIDTH + 1.4)
		var bush := VisualKit.add_sphere(veg, rng.randf_range(0.45, 0.85), pos + Vector3(0.0, 0.3, 0.0), bush_mat)
		bush.scale = Vector3(1.3, 0.8, 1.1)

		# Palmas interiores: mallas sencillas con materiales compartidos por zona.

		# Troncos caídos con forma diferenciada.
	var inner_palms := int(9.0 * density) + 3
	for _index in range(inner_palms):
		var pos := Vector3(
			rng.randf_range(rect.position.x + 3.0, rect.position.x + rect.size.x - 3.0),
			0.0,
			rng.randf_range(rect.position.y + 3.0, rect.position.y + rect.size.y - 3.0)
		)
		if absf(pos.x) < PATH_HALF_WIDTH + 1.8:
			pos.x += signf(pos.x) * (PATH_HALF_WIDTH + 2.0)
		_build_palm(veg, pos, rng, palette)

		# Troncos caídos con forma diferenciada.
	var tufts := int(40.0 * density) + 10
	var tuft_mat: Material = palette["wind_tuft"]
	for _index in range(tufts):
		var side := 1.0 if rng.randf() > 0.5 else -1.0
		var pos := Vector3(
			side * rng.randf_range(PATH_HALF_WIDTH + 0.4, PATH_HALF_WIDTH + 2.6),
			0.0,
			rng.randf_range(rect.position.y + 2.0, rect.position.y + rect.size.y - 2.0)
		)
		var tuft := VisualKit.add_cone(
			veg, rng.randf_range(0.22, 0.4), rng.randf_range(0.5, 0.9), pos + Vector3(0.0, 0.3, 0.0), tuft_mat
		)
		tuft.rotation_degrees.y = rng.randf_range(0.0, 360.0)

		# Troncos caídos con forma diferenciada.
	for log_pos in [Vector3(-7.5, 0.28, 3.5), Vector3(8.4, 0.28, 16.0)]:
		var log := VisualKit.add_cylinder(veg, 0.32, 3.2, log_pos, trunk_mat, 7)
		log.rotation_degrees = Vector3(90.0, rng.randf_range(0.0, 180.0), 0.0)


static func _build_props(root: Node3D, rng: RandomNumberGenerator, palette: Dictionary) -> void:
	var props := Node3D.new()
	props.name = "Props"
	root.add_child(props)
	var wood_mat: Material = palette["weathered_wood"]
	var iron_mat: Material = palette["wrought_iron"]

	# Carreta de Cheo con herrajes de hierro envejecido.
	var cart := Node3D.new()
	cart.name = "CheoCart"
	cart.position = Vector3(4.6, 0.0, -23.5)
	cart.rotation_degrees.y = 28.0
	props.add_child(cart)
	VisualKit.add_box(cart, Vector3(2.4, 0.16, 1.5), Vector3(0.0, 0.9, 0.0), wood_mat)
	VisualKit.add_box(cart, Vector3(2.4, 0.5, 0.14), Vector3(0.0, 1.2, 0.72), wood_mat)
	VisualKit.add_box(cart, Vector3(2.4, 0.5, 0.14), Vector3(0.0, 1.2, -0.72), wood_mat)
	var wheel_mat: Material = palette["worn_iron"]
	for wheel_x in [-0.8, 0.8]:
		for wheel_z in [-0.9, 0.9]:
			VisualKit.add_cylinder(cart, 0.55, 0.12, Vector3(wheel_x, 0.55, wheel_z), wheel_mat, 12).rotation_degrees.x = 90.0

		# Casas rurales coloniales como silueta de fondo.

		# Farol cálido: la luz se modula con la transición noche/día. Poste de
		# hierro forjado (shader worn_iron del Art Pass).
	for nail_position in [
		Vector3(-1.13, 1.22, 0.74), Vector3(1.13, 1.22, 0.74), Vector3(-1.13, 1.22, -0.74), Vector3(1.13, 1.22, -0.74)
	]:
		VisualKit.add_sphere(cart, 0.055, nail_position, iron_mat)

		# Casas rurales coloniales como silueta de fondo.

		# Farol cálido: la luz se modula con la transición noche/día. Poste de
		# hierro forjado (shader worn_iron del Art Pass).
	VisualKit.add_tetra(
		cart,
		0.22,
		Vector3(-1.3, 0.2, 1.4),
		VisualKit.flat_material(Color(0.72, 0.48, 0.18), Color(1.0, 0.72, 0.25), 0.8)
	)

	# Casas rurales coloniales como silueta de fondo.
	var town := Node3D.new()
	town.name = "ValdeluzEdge"
	town.position = Vector3(0.0, 0.0, AREA_MIN_Z - 7.0)
	props.add_child(town)
	var wall_mat := VisualKit.noise_material(Color(0.55, 0.47, 0.38), 0.25, 3)
	var roof_mat := VisualKit.noise_material(Color(0.42, 0.24, 0.16), 0.3, 3)
	for house_spec in [
		{"pos": Vector3(-8.0, 0.0, 0.0), "size": Vector3(5.0, 3.0, 4.0)},
		{"pos": Vector3(0.5, 0.0, -0.5), "size": Vector3(6.0, 3.4, 4.6)},
		{"pos": Vector3(8.5, 0.0, 0.4), "size": Vector3(4.6, 2.8, 4.0)}
	]:
		var body := VisualKit.add_box(
			town,
			house_spec["size"],
			Vector3(house_spec["pos"].x, house_spec["size"].y * 0.5, house_spec["pos"].z),
			wall_mat
		)
		body.rotation_degrees.y = rng.randf_range(-8.0, 8.0)
		VisualKit.add_box(
			town,
			Vector3(house_spec["size"].x + 0.8, 0.9, house_spec["size"].z + 0.8),
			Vector3(house_spec["pos"].x, house_spec["size"].y + 0.45, house_spec["pos"].z),
			roof_mat
		)

		# Farol cálido: la luz se modula con la transición noche/día. Poste de
		# hierro forjado (shader worn_iron del Art Pass).
	VisualKit.add_cylinder(town, 0.16, 3.2, Vector3(-3.0, 1.6, 2.6), palette["worn_iron"], 6)
	VisualKit.add_sphere(
		town, 0.3, Vector3(-3.0, 3.35, 2.6), VisualKit.flat_material(Color(0.9, 0.75, 0.4), Color(1.0, 0.8, 0.45), 1.2)
	)
	var lantern := OmniLight3D.new()
	lantern.name = "ValdeluzEntryLamp"
	lantern.position = Vector3(-3.0, 3.35, 2.6)
	lantern.light_color = Color(1.0, 0.58, 0.28)
	lantern.light_energy = 0.85
	lantern.omni_range = 6.5
	lantern.shadow_enabled = false
	town.add_child(lantern)
	var controller := root.get_node_or_null("EnvironmentController") as EnvironmentController
	if controller != null:
		controller.register_night_light(lantern)


static func _build_palm(parent: Node, base: Vector3, rng: RandomNumberGenerator, palette: Dictionary) -> void:
	var palm := Node3D.new()
	palm.position = base
	parent.add_child(palm)
	var height := rng.randf_range(3.2, 4.6)
	var lean := Vector3(rng.randf_range(-0.18, 0.18), 0.0, rng.randf_range(-0.18, 0.18))
	var trunk := VisualKit.add_cylinder(
		palm, 0.22, height, Vector3(lean.x * height * 0.5, height / 2.0, lean.z * height * 0.5), palette["tree_bark"], 7
	)
	trunk.rotation_degrees = Vector3(lean.z * 18.0, 0.0, -lean.x * 18.0)
	var crown_pos := Vector3(lean.x * height, height + 0.05, lean.z * height)
	var frond_count := 7
	var frond_material: Material = palette["wind_frond"]
	for index in range(frond_count):
		var angle := (TAU / float(frond_count)) * float(index) + rng.randf_range(-0.2, 0.2)
		var frond := VisualKit.add_box(
			palm,
			Vector3(1.7, 0.06, 0.34),
			crown_pos + Vector3(cos(angle) * 0.85, 0.12, sin(angle) * 0.85),
			frond_material
		)
		frond.rotation_degrees = Vector3(0.0, -rad_to_deg(angle) + 90.0, 14.0)
	VisualKit.add_sphere(palm, 0.28, crown_pos, palette["weathered_wood"])


static func _build_ceiba(parent: Node, base: Vector3, rng: RandomNumberGenerator, palette: Dictionary) -> void:
	var ceiba := Node3D.new()
	ceiba.position = base
	parent.add_child(ceiba)
	var height := rng.randf_range(4.0, 5.2)
	VisualKit.add_cylinder(ceiba, 0.55, height, Vector3(0.0, height / 2.0, 0.0), palette["tree_bark"], 9)
	for canopy in [
		{"pos": Vector3(0.0, height + 0.2, 0.0), "scale": Vector3(2.6, 1.1, 2.6)},
		{"pos": Vector3(-1.4, height - 0.3, 0.6), "scale": Vector3(1.7, 0.8, 1.7)},
		{"pos": Vector3(1.3, height - 0.2, -0.8), "scale": Vector3(1.5, 0.8, 1.5)}
	]:
		var blob := VisualKit.add_sphere(ceiba, 1.0, canopy["pos"], palette["wind_canopy"])
		blob.scale = canopy["scale"]
		# Raíces tablares de ceiba.
	for root_angle: float in [0.4, 1.7, 2.9, 4.2]:
		var root_pos := Vector3(cos(root_angle) * 0.55, 0.35, sin(root_angle) * 0.55)
		var buttress := VisualKit.add_box(ceiba, Vector3(0.5, 0.9, 0.35), root_pos, palette["tree_bark"])
		buttress.rotation_degrees.y = -rad_to_deg(root_angle) + 90.0

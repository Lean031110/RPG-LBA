class_name ValdeluzBuilder
## Construcción determinista de las afueras de Valdeluz (vertical slice).
## Semilla fija: el layout es reproducible y testeable. La densidad de vegetación se
## toma del perfil gráfico activo (Low = referencia de diseño). El Art Pass (Fase 1B)
## rehace estos materiales y siluetas con dirección artística aprobada.

const LAYOUT_SEED := 20261113
const AREA_MIN_X := -20.0
const AREA_MAX_X := 20.0
const AREA_MIN_Z := -28.0
const AREA_MAX_Z := 26.0
const PATH_HALF_WIDTH := 2.3
const PATH_END_Z := 22.0
const BOUNDARY_MARGIN := 1.6


static func build_all(root: Node3D, density: float) -> void:
	## Ensambla terreno, límites, vegetación, props e iluminación bajo `root`.
	var rng := RandomNumberGenerator.new()
	rng.seed = LAYOUT_SEED
	var scaled := clampf(density, 0.1, 1.0)
	_build_ground(root)
	_build_lighting(root)
	_build_boundaries(root, rng, scaled)
	_build_vegetation(root, rng, scaled)
	_build_props(root, rng)


static func play_area_rect() -> Rect2:
	## Rectángulo jugable (XZ) sin el margen de límites; lo usan las pruebas.
	return Rect2(
		AREA_MIN_X + BOUNDARY_MARGIN,
		AREA_MIN_Z + BOUNDARY_MARGIN,
		(AREA_MAX_X - AREA_MIN_X) - BOUNDARY_MARGIN * 2.0,
		(AREA_MAX_Z - AREA_MIN_Z) - BOUNDARY_MARGIN * 2.0
	)


static func _build_ground(root: Node3D) -> void:
	# Suelo de césped tropical con variación de tono (ruido procedural, sin texturas externas).
	var grass := Node3D.new()
	grass.name = "Ground"
	root.add_child(grass)
	var ground_mat := VisualKit.noise_material(VisualKit.MAT_GRASS, 0.05, 5)
	var ground_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2((AREA_MAX_X - AREA_MIN_X) + 24.0, (AREA_MAX_Z - AREA_MIN_Z) + 24.0)
	plane.center_offset = Vector3.ZERO
	ground_mesh.mesh = plane
	ground_mesh.material_override = ground_mat
	ground_mesh.position = Vector3(0, 0, 0)
	grass.add_child(ground_mesh)

	# Colisión del suelo para el jugador y enemigos.
	var ground_body := StaticBody3D.new()
	ground_body.name = "GroundBody"
	ground_body.collision_layer = ArpgLayers.WORLD
	ground_body.collision_mask = 0
	var ground_shape := CollisionShape3D.new()
	var ground_box := BoxShape3D.new()
	ground_box.size = Vector3(plane.size.x + 24.0, 0.4, plane.size.y + 24.0)
	ground_shape.shape = ground_box
	ground_body.add_child(ground_shape)
	ground_body.position = Vector3(0, -0.2, 0)
	grass.add_child(ground_body)

	# Camino de tierra roja con roderas sugeridas (dos bandas más oscuras).
	var dirt_mat := VisualKit.noise_material(VisualKit.MAT_DIRT, 0.14, 4)
	var path := Node3D.new()
	path.name = "RedDirtPath"
	grass.add_child(path)
	var path_mesh := VisualKit.add_box(
		path,
		Vector3(PATH_HALF_WIDTH * 2.0, 0.08, PATH_END_Z - AREA_MIN_Z + 2.0),
		Vector3(0, 0.045, (PATH_END_Z + AREA_MIN_Z) / 2.0),
		dirt_mat
	)
	path_mesh.name = "PathMesh"
	# Roderas: dos bandas oscuras sobre el camino.
	var wheel_mat := VisualKit.noise_material(VisualKit.MAT_DIRT.darkened(0.45), 0.2, 3)
	VisualKit.add_box(
		path,
		Vector3(0.55, 0.035, PATH_END_Z - AREA_MIN_Z),
		Vector3(-0.85, 0.09, (PATH_END_Z + AREA_MIN_Z) / 2.0),
		wheel_mat
	)
	VisualKit.add_box(
		path,
		Vector3(0.55, 0.035, PATH_END_Z - AREA_MIN_Z),
		Vector3(0.85, 0.09, (PATH_END_Z + AREA_MIN_Z) / 2.0),
		wheel_mat
	)

	# Afloramientos de piedra caliza a los lados del camino (legibilidad de material).
	var stone_mat := VisualKit.noise_material(VisualKit.MAT_STONE, 0.18, 4)
	var stones := Node3D.new()
	stones.name = "Limestone"
	grass.add_child(stones)
	var stone_spots := [
		Vector3(-6.5, 0.0, -6.0),
		Vector3(7.2, 0.0, -1.5),
		Vector3(-8.0, 0.0, 8.0),
		Vector3(6.8, 0.0, 12.5),
		Vector3(-3.4, 0.0, 18.0),
		Vector3(3.9, 0.0, 21.5)
	]
	for spot: Vector3 in stone_spots:
		var rock := VisualKit.add_sphere(
			stones, randf_range_clamped(0.9, 1.4, 20261113), spot + Vector3(0, 0.35, 0), stone_mat
		)
		rock.scale = Vector3(1.25, 0.62, 1.0)
		VisualKit.add_sphere(stones, 0.55, spot + Vector3(1.6, 0.22, 0.9), stone_mat)


static func randf_range_clamped(low: float, high: float, seed_value: int) -> float:
	## Valor pseudoaleatorio estable para detalles fijos del layout.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng.randf_range(low, high)


static func _build_lighting(root: Node3D) -> void:
	# Día fijo a media mañana. El ciclo día/noche completo llega en el Art Pass (Fase 1B).
	var environment := WorldEnvironment.new()
	environment.name = "WorldEnvironment"
	var env := Environment.new()
	var sky := ProceduralSkyMaterial.new()
	sky.sky_top_color = Color(0.24, 0.42, 0.62)
	sky.sky_horizon_color = Color(0.78, 0.72, 0.60)
	sky.ground_bottom_color = Color(0.16, 0.14, 0.12)
	sky.ground_horizon_color = Color(0.55, 0.50, 0.42)
	sky.sun_angle_max = 24.0
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.46, 0.52)
	env.ambient_light_energy = 0.9
	# Niebla suave de mañana: sin ocultar telegráficos (dirección artística §3).
	env.fog_enabled = true
	env.fog_light_color = Color(0.72, 0.74, 0.78)
	env.fog_density = 0.008
	environment.environment = env
	root.add_child(environment)

	var sun := DirectionalLight3D.new()
	sun.name = "MorningSun"
	sun.rotation_degrees = Vector3(-52.0, 32.0, 0.0)
	sun.light_color = Color(1.0, 0.95, 0.85)
	sun.light_energy = 1.15
	sun.shadow_enabled = false
	root.add_child(sun)


static func _build_boundaries(root: Node3D, rng: RandomNumberGenerator, density: float) -> void:
	## Límites físicos invisibles + anillo visual denso de vegetación (dirección artística §2:
	## límites integrados en el paisaje, no muros visibles).
	var walls := Node3D.new()
	walls.name = "Boundaries"
	root.add_child(walls)
	var wall_mat := VisualKit.noise_material(VisualKit.MAT_LEAF_DARK, 0.09, 4)
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
		},
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

	# Anillo de palmas y ceibas en el borde: silueta variada, no un muro uniforme.
	var palms := int(26.0 * density) + 8
	for index: int in palms:
		var edge := rng.randi_range(0, 3)
		var t := rng.randf()
		var edge_x := rect.position.x + t * rect.size.x
		var edge_z := rect.position.y + t * rect.size.y
		var pos := Vector3.ZERO
		match edge:
			0:
				pos = Vector3(edge_x, 0, rect.position.y - 1.2)
			1:
				pos = Vector3(edge_x, 0, rect.position.y + rect.size.y + 1.2)
			2:
				pos = Vector3(rect.position.x - 1.2, 0, edge_z)
			_:
				pos = Vector3(rect.position.x + rect.size.x + 1.2, 0, edge_z)
		_build_palm(walls, pos, rng)
	# Ceibas grandes en las esquinas para cerrar la lectura del horizonte.
	for corner: Vector3 in [
		Vector3(rect.position.x - 1.5, 0, rect.position.y - 1.5),
		Vector3(rect.position.x + rect.size.x + 1.5, 0, rect.position.y - 1.5),
		Vector3(rect.position.x - 1.5, 0, rect.position.y + rect.size.y + 1.5),
		Vector3(rect.position.x + rect.size.x + 1.5, 0, rect.position.y + rect.size.y + 1.5),
	]:
		_build_ceiba(walls, corner, rng)


static func _build_vegetation(root: Node3D, rng: RandomNumberGenerator, density: float) -> void:
	## Vegetación interior: manigua dispersa sin tapar al jugador (dirección artística §2).
	var veg := Node3D.new()
	veg.name = "Vegetation"
	root.add_child(veg)
	var rect := play_area_rect()
	var bush_mat := VisualKit.flat_material(VisualKit.MAT_LEAF_MID)
	var trunk_mat := VisualKit.flat_material(VisualKit.MAT_TRUNK)
	# Arbustos y maleza.
	var bushes := int(34.0 * density) + 6
	for index: int in bushes:
		var pos := Vector3(
			rng.randf_range(rect.position.x + 2.0, rect.position.x + rect.size.x - 2.0),
			0,
			rng.randf_range(rect.position.y + 2.0, rect.position.y + rect.size.y - 2.0)
		)
		if absf(pos.x) < PATH_HALF_WIDTH + 1.2:
			pos.x += signf(pos.x) * (PATH_HALF_WIDTH + 1.4)
		var bush := VisualKit.add_sphere(veg, rng.randf_range(0.45, 0.85), pos + Vector3(0, 0.3, 0), bush_mat)
		bush.scale = Vector3(1.3, 0.8, 1.1)
	# Palmas interiores fuera del camino.
	var inner_palms := int(9.0 * density) + 3
	for index: int in inner_palms:
		var pos := Vector3(
			rng.randf_range(rect.position.x + 3.0, rect.position.x + rect.size.x - 3.0),
			0,
			rng.randf_range(rect.position.y + 3.0, rect.position.y + rect.size.y - 3.0)
		)
		if absf(pos.x) < PATH_HALF_WIDTH + 1.8:
			pos.x += signf(pos.x) * (PATH_HALF_WIDTH + 2.0)
		_build_palm(veg, pos, rng)
	# Matas de hierba alta junto al camino.
	var tufts := int(40.0 * density) + 10
	var tuft_mat := VisualKit.flat_material(VisualKit.MAT_LEAF_MID.darkened(0.15))
	for index: int in tufts:
		var side := 1.0 if rng.randf() > 0.5 else -1.0
		var pos := Vector3(
			side * rng.randf_range(PATH_HALF_WIDTH + 0.4, PATH_HALF_WIDTH + 2.6),
			0,
			rng.randf_range(rect.position.y + 2.0, rect.position.y + rect.size.y - 2.0)
		)
		var tuft := VisualKit.add_cone(
			veg, rng.randf_range(0.22, 0.4), rng.randf_range(0.5, 0.9), pos + Vector3(0, 0.3, 0), tuft_mat
		)
		tuft.rotation_degrees.y = rng.randf_range(0.0, 360.0)
	# Troncos caídos: lectura de "selva viva", no parque.
	for log_pos: Vector3 in [Vector3(-7.5, 0.28, 3.5), Vector3(8.4, 0.28, 16.0)]:
		var log := VisualKit.add_cylinder(veg, 0.32, 3.2, log_pos, trunk_mat, 7)
		log.rotation_degrees = Vector3(90, rng.randf_range(0.0, 180.0), 0)


static func _build_props(root: Node3D, rng: RandomNumberGenerator) -> void:
	## Punto de partida: la carreta de Cheo y siluetas del pueblo al fondo (marco narrativo).
	var props := Node3D.new()
	props.name = "Props"
	root.add_child(props)
	var wood_mat := VisualKit.noise_material(VisualKit.MAT_WOOD, 0.3, 3)
	# Carreta volcada junto al portal de Cheo.
	var cart := Node3D.new()
	cart.name = "CheoCart"
	cart.position = Vector3(4.6, 0, -23.5)
	cart.rotation_degrees.y = 28.0
	props.add_child(cart)
	VisualKit.add_box(cart, Vector3(2.4, 0.16, 1.5), Vector3(0, 0.9, 0), wood_mat)
	VisualKit.add_box(cart, Vector3(2.4, 0.5, 0.14), Vector3(0, 1.2, 0.72), wood_mat)
	VisualKit.add_box(cart, Vector3(2.4, 0.5, 0.14), Vector3(0, 1.2, -0.72), wood_mat)
	var wheel_mat := VisualKit.noise_material(VisualKit.MAT_WOOD.darkened(0.4), 0.3, 3)
	VisualKit.add_cylinder(cart, 0.55, 0.12, Vector3(-0.8, 0.55, 0.9), wheel_mat, 12).rotation_degrees.x = 90.0
	VisualKit.add_cylinder(cart, 0.55, 0.12, Vector3(0.8, 0.55, 0.9), wheel_mat, 12).rotation_degrees.x = 90.0
	VisualKit.add_cylinder(cart, 0.55, 0.12, Vector3(-0.8, 0.55, -0.9), wheel_mat, 12).rotation_degrees.x = 90.0
	VisualKit.add_cylinder(cart, 0.55, 0.12, Vector3(0.8, 0.55, -0.9), wheel_mat, 12).rotation_degrees.x = 90.0
	# Fragmentos sueltos de la carga.
	VisualKit.add_tetra(
		cart,
		0.22,
		Vector3(-1.3, 0.2, 1.4),
		VisualKit.flat_material(VisualKit.MAT_BRONZE, VisualKit.MAT_BRONZE_GLOW, 0.8)
	)

	# Bohíos del pueblo al fondo (silueta, sin interior).
	var town := Node3D.new()
	town.name = "ValdeluzEdge"
	town.position = Vector3(0, 0, AREA_MIN_Z - 7.0)
	props.add_child(town)
	var wall_mat := VisualKit.noise_material(Color(0.55, 0.47, 0.38), 0.25, 3)
	var roof_mat := VisualKit.noise_material(Color(0.42, 0.24, 0.16), 0.3, 3)
	for house_spec: Dictionary in [
		{"pos": Vector3(-8.0, 0, 0), "size": Vector3(5.0, 3.0, 4.0)},
		{"pos": Vector3(0.5, 0, -0.5), "size": Vector3(6.0, 3.4, 4.6)},
		{"pos": Vector3(8.5, 0, 0.4), "size": Vector3(4.6, 2.8, 4.0)},
	]:
		var body := VisualKit.add_box(
			town, house_spec["size"], Vector3(house_spec["pos"].x, 1.5, house_spec["pos"].z), wall_mat
		)
		body.rotation_degrees.y = rng.randf_range(-8.0, 8.0)
		VisualKit.add_box(
			town,
			Vector3(house_spec["size"].x + 0.8, 0.9, house_spec["size"].z + 0.8),
			Vector3(house_spec["pos"].x, 3.4, house_spec["pos"].z),
			roof_mat
		)
	# Farol de la entrada (se enciende de noche en el Art Pass).
	VisualKit.add_cylinder(town, 0.16, 3.2, Vector3(-3.0, 1.6, 2.6), wood_mat, 6)
	VisualKit.add_sphere(
		town, 0.3, Vector3(-3.0, 3.35, 2.6), VisualKit.flat_material(Color(0.9, 0.75, 0.4), Color(1.0, 0.8, 0.45), 1.2)
	)


static func _build_palm(parent: Node, base: Vector3, rng: RandomNumberGenerator) -> void:
	## Palma real: tronco inclinado + corona de pencas. Silueta distinta a la ceiba.
	var palm := Node3D.new()
	palm.position = base
	parent.add_child(palm)
	var trunk_mat := VisualKit.noise_material(VisualKit.MAT_TRUNK, 0.2, 4)
	var height := rng.randf_range(3.2, 4.6)
	var lean := Vector3(rng.randf_range(-0.18, 0.18), 0, rng.randf_range(-0.18, 0.18))
	var trunk := VisualKit.add_cylinder(
		palm, 0.22, height, Vector3(lean.x * height * 0.5, height / 2.0, lean.z * height * 0.5), trunk_mat, 7
	)
	trunk.rotation_degrees = Vector3(lean.z * 18.0, 0, -lean.x * 18.0)
	var crown_pos := Vector3(lean.x * height, height + 0.05, lean.z * height)
	var frond_mat := VisualKit.flat_material(VisualKit.MAT_LEAF_DARK if rng.randf() > 0.5 else VisualKit.MAT_LEAF_MID)
	var fronds := 7
	for index: int in fronds:
		var angle := (TAU / fronds) * index + rng.randf_range(-0.2, 0.2)
		var frond := VisualKit.add_box(
			palm, Vector3(1.7, 0.06, 0.34), crown_pos + Vector3(cos(angle) * 0.85, 0.12, sin(angle) * 0.85), frond_mat
		)
		frond.rotation_degrees = Vector3(0, -rad_to_deg(angle) + 90.0, 14.0)
	VisualKit.add_sphere(palm, 0.28, crown_pos, VisualKit.flat_material(Color(0.48, 0.38, 0.20)))


static func _build_ceiba(parent: Node, base: Vector3, rng: RandomNumberGenerator) -> void:
	## Ceiba: tronco grueso + copa ancha y baja. Contrapeso visual de la palma.
	var ceiba := Node3D.new()
	ceiba.position = base
	parent.add_child(ceiba)
	var trunk_mat := VisualKit.noise_material(VisualKit.MAT_TRUNK.darkened(0.2), 0.13, 4)
	var height := rng.randf_range(4.0, 5.2)
	VisualKit.add_cylinder(ceiba, 0.55, height, Vector3(0, height / 2.0, 0), trunk_mat, 9)
	var leaf_mat := VisualKit.flat_material(VisualKit.MAT_LEAF_MID.darkened(0.08))
	for canopy: Dictionary in [
		{"pos": Vector3(0, height + 0.2, 0), "scale": Vector3(2.6, 1.1, 2.6)},
		{"pos": Vector3(-1.4, height - 0.3, 0.6), "scale": Vector3(1.7, 0.8, 1.7)},
		{"pos": Vector3(1.3, height - 0.2, -0.8), "scale": Vector3(1.5, 0.8, 1.5)},
	]:
		var blob := VisualKit.add_sphere(ceiba, 1.0, canopy["pos"], leaf_mat)
		blob.scale = canopy["scale"]
	# Raíces tablares.
	for root_angle: float in [0.4, 1.7, 2.9, 4.2]:
		var root_pos := Vector3(cos(root_angle) * 0.55, 0.35, sin(root_angle) * 0.55)
		var buttress := VisualKit.add_box(ceiba, Vector3(0.5, 0.9, 0.35), root_pos, trunk_mat)
		buttress.rotation_degrees.y = -rad_to_deg(root_angle) + 90.0

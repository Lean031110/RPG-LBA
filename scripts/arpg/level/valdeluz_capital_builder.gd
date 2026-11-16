class_name ValdeluzCapitalBuilder
extends RefCounted
## Construcción determinista de la capital de Valdeluz.
## Geometría procedural original, materiales compartidos y colisiones estáticas simples.

const CITY_SEED := 1953
const CITY_HALF_WIDTH := 54.0
const CITY_HALF_DEPTH := 44.0
const ROAD_WIDTH := 7.0
const PLAZA_SIZE := 23.0


static func build(root: Node3D, density: float = 0.75) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = CITY_SEED
	var palette := _create_city_palette()
	_build_ground(root, palette)
	_build_roads(root, palette)
	_build_plaza(root, palette)
	_build_districts(root, rng, palette)
	_build_street_furniture(root, palette)
	_build_greenery(root, rng, clampf(density, 0.25, 1.0), palette)
	_build_city_edges(root, palette)


static func _create_city_palette() -> Dictionary:
	return {
		"ground": VisualKit.noise_material(Color(0.24, 0.32, 0.19), 0.045, 5),
		"road": VisualKit.noise_material(Color(0.43, 0.25, 0.17), 0.075, 5),
		"cobble": VisualKit.noise_material(Color(0.48, 0.46, 0.40), 0.12, 4),
		"limestone": VisualKit.noise_material(Color(0.72, 0.66, 0.54), 0.10, 5),
		"plaster_cream": VisualKit.noise_material(Color(0.78, 0.70, 0.55), 0.055, 5),
		"plaster_ochre": VisualKit.noise_material(Color(0.62, 0.39, 0.25), 0.065, 5),
		"plaster_teal": VisualKit.noise_material(Color(0.24, 0.39, 0.39), 0.06, 5),
		"plaster_rose": VisualKit.noise_material(Color(0.57, 0.31, 0.27), 0.06, 5),
		"roof": VisualKit.noise_material(Color(0.42, 0.19, 0.13), 0.14, 5),
		"roof_shadow": VisualKit.noise_material(Color(0.25, 0.15, 0.12), 0.12, 4),
		"wood": VisualKit.noise_material(Color(0.29, 0.19, 0.12), 0.10, 4),
		"wood_light": VisualKit.noise_material(Color(0.49, 0.34, 0.20), 0.10, 4),
		"iron": VisualKit.noise_material(Color(0.12, 0.15, 0.17), 0.18, 4),
		"glass": VisualKit.flat_material(Color(0.10, 0.23, 0.27), Color(0.10, 0.23, 0.27), 0.08),
		"gold": VisualKit.flat_material(Color(0.63, 0.45, 0.19)),
		"water": VisualKit.flat_material(Color(0.13, 0.35, 0.39), Color(0.08, 0.22, 0.28), 0.12),
		"leaf": VisualKit.noise_material(Color(0.13, 0.31, 0.16), 0.10, 4),
		"leaf_light": VisualKit.noise_material(Color(0.25, 0.40, 0.19), 0.12, 4),
		"bark": VisualKit.noise_material(Color(0.25, 0.17, 0.12), 0.10, 4)
	}


static func _build_ground(root: Node3D, palette: Dictionary) -> void:
	var ground := Node3D.new()
	ground.name = "CityGround"
	root.add_child(ground)
	VisualKit.add_box(
		ground,
		Vector3(CITY_HALF_WIDTH * 2.0 + 26.0, 0.5, CITY_HALF_DEPTH * 2.0 + 26.0),
		Vector3(0.0, -0.28, 0.0),
		palette["ground"]
	)
	var body := StaticBody3D.new()
	body.name = "GroundCollision"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(CITY_HALF_WIDTH * 2.0 + 26.0, 0.5, CITY_HALF_DEPTH * 2.0 + 26.0)
	shape.shape = box
	body.add_child(shape)
	body.position.y = -0.28
	body.collision_layer = ArpgLayers.WORLD
	body.collision_mask = 0
	ground.add_child(body)


static func _build_roads(root: Node3D, palette: Dictionary) -> void:
	var roads := Node3D.new()
	roads.name = "RoadNetwork"
	root.add_child(roads)
	var road_length := CITY_HALF_DEPTH * 2.0
	VisualKit.add_box(roads, Vector3(ROAD_WIDTH, 0.10, road_length), Vector3(0.0, 0.035, 0.0), palette["road"])
	VisualKit.add_box(roads, Vector3(CITY_HALF_WIDTH * 2.0, 0.10, ROAD_WIDTH), Vector3(0.0, 0.04, 0.0), palette["road"])
	VisualKit.add_box(roads, Vector3(ROAD_WIDTH - 1.0, 0.11, road_length), Vector3(0.0, 0.045, 0.0), palette["cobble"])
	VisualKit.add_box(
		roads, Vector3(CITY_HALF_WIDTH * 2.0, 0.11, ROAD_WIDTH - 1.0), Vector3(0.0, 0.05, 0.0), palette["cobble"]
	)
	# Calles de conexión entre barrios y anillo perimetral.
	for z_value in [-25.0, 25.0]:
		VisualKit.add_box(
			roads, Vector3(CITY_HALF_WIDTH * 2.0, 0.09, 4.2), Vector3(0.0, 0.025, z_value), palette["road"]
		)

		# Bordillos claros definen las aceras sin elevar el terreno jugable.
	for x_value in [-31.0, 31.0]:
		VisualKit.add_box(
			roads, Vector3(4.2, 0.09, CITY_HALF_DEPTH * 2.0), Vector3(x_value, 0.025, 0.0), palette["road"]
		)
		# Bordillos claros definen las aceras sin elevar el terreno jugable.
	for side in [-1.0, 1.0]:
		VisualKit.add_box(
			roads, Vector3(0.42, 0.22, road_length), Vector3(side * 3.85, 0.11, 0.0), palette["limestone"]
		)
		VisualKit.add_box(
			roads, Vector3(CITY_HALF_WIDTH * 2.0, 0.22, 0.42), Vector3(0.0, 0.11, side * 3.85), palette["limestone"]
		)


static func _build_plaza(root: Node3D, palette: Dictionary) -> void:
	var plaza := Node3D.new()
	plaza.name = "PlazaMayor"
	root.add_child(plaza)
	VisualKit.add_box(plaza, Vector3(PLAZA_SIZE, 0.12, PLAZA_SIZE), Vector3(0.0, 0.08, 0.0), palette["limestone"])
	# Adoquines de borde y bandas radiales discretas.
	for side in [-1.0, 1.0]:
		VisualKit.add_box(
			plaza,
			Vector3(PLAZA_SIZE + 1.2, 0.16, 0.48),
			Vector3(0.0, 0.13, side * (PLAZA_SIZE * 0.5)),
			palette["roof_shadow"]
		)
		VisualKit.add_box(
			plaza,
			Vector3(0.48, 0.16, PLAZA_SIZE + 1.2),
			Vector3(side * (PLAZA_SIZE * 0.5), 0.13, 0.0),
			palette["roof_shadow"]
		)
	_build_fountain(plaza, palette)
	_build_bench(plaza, Vector3(-7.2, 0.0, 5.8), 0.0, palette)
	_build_bench(plaza, Vector3(7.2, 0.0, 5.8), 0.0, palette)
	_build_bench(plaza, Vector3(-7.2, 0.0, -5.8), 180.0, palette)
	_build_bench(plaza, Vector3(7.2, 0.0, -5.8), 180.0, palette)


static func _build_fountain(parent: Node3D, palette: Dictionary) -> void:
	var fountain := Node3D.new()
	fountain.name = "FuenteDeLaCeniza"
	parent.add_child(fountain)
	VisualKit.add_cylinder(fountain, 3.0, 0.48, Vector3(0.0, 0.28, 0.0), palette["limestone"], 16)
	VisualKit.add_cylinder(fountain, 2.55, 0.16, Vector3(0.0, 0.60, 0.0), palette["water"], 16)
	VisualKit.add_cylinder(fountain, 0.48, 1.35, Vector3(0.0, 1.05, 0.0), palette["limestone"], 12)
	VisualKit.add_cylinder(fountain, 1.05, 0.22, Vector3(0.0, 1.78, 0.0), palette["limestone"], 12)
	VisualKit.add_sphere(fountain, 0.28, Vector3(0.0, 2.05, 0.0), palette["gold"])


static func _build_districts(root: Node3D, rng: RandomNumberGenerator, palette: Dictionary) -> void:
	var districts := Node3D.new()
	districts.name = "Districts"
	root.add_child(districts)
	var specs: Array[Dictionary] = [
		{
			"district": "BarrioDelSol",
			"pos": Vector3(-18.0, 0.0, -16.0),
			"size": Vector3(10.0, 5.8, 8.0),
			"rot": 90.0,
			"mat": "plaster_ochre"
		},
		{
			"district": "BarrioDelSol",
			"pos": Vector3(-43.0, 0.0, -16.0),
			"size": Vector3(9.0, 5.0, 8.0),
			"rot": 90.0,
			"mat": "plaster_cream"
		},
		{
			"district": "BarrioDelSol",
			"pos": Vector3(-18.0, 0.0, -36.0),
			"size": Vector3(10.0, 5.5, 8.0),
			"rot": 0.0,
			"mat": "plaster_rose"
		},
		{
			"district": "BarrioDelSol",
			"pos": Vector3(-43.0, 0.0, -36.0),
			"size": Vector3(9.0, 4.8, 8.0),
			"rot": 0.0,
			"mat": "plaster_teal"
		},
		{
			"district": "BarrioDelSol",
			"pos": Vector3(18.0, 0.0, -16.0),
			"size": Vector3(10.0, 5.8, 8.0),
			"rot": -90.0,
			"mat": "plaster_cream"
		},
		{
			"district": "BarrioDelSol",
			"pos": Vector3(43.0, 0.0, -16.0),
			"size": Vector3(9.0, 5.0, 8.0),
			"rot": -90.0,
			"mat": "plaster_ochre"
		},
		{
			"district": "BarrioDelSol",
			"pos": Vector3(18.0, 0.0, -36.0),
			"size": Vector3(10.0, 5.5, 8.0),
			"rot": 0.0,
			"mat": "plaster_teal"
		},
		{
			"district": "BarrioDelSol",
			"pos": Vector3(43.0, 0.0, -36.0),
			"size": Vector3(9.0, 4.8, 8.0),
			"rot": 0.0,
			"mat": "plaster_rose"
		},
		{
			"district": "BarrioDelSur",
			"pos": Vector3(-18.0, 0.0, 16.0),
			"size": Vector3(10.0, 5.8, 8.0),
			"rot": 90.0,
			"mat": "plaster_teal"
		},
		{
			"district": "BarrioDelSur",
			"pos": Vector3(-43.0, 0.0, 16.0),
			"size": Vector3(9.0, 5.0, 8.0),
			"rot": 90.0,
			"mat": "plaster_rose"
		},
		{
			"district": "BarrioDelSur",
			"pos": Vector3(-18.0, 0.0, 36.0),
			"size": Vector3(10.0, 5.5, 8.0),
			"rot": 180.0,
			"mat": "plaster_cream"
		},
		{
			"district": "BarrioDelSur",
			"pos": Vector3(-43.0, 0.0, 36.0),
			"size": Vector3(9.0, 4.8, 8.0),
			"rot": 180.0,
			"mat": "plaster_ochre"
		},
		{
			"district": "BarrioDelSur",
			"pos": Vector3(18.0, 0.0, 16.0),
			"size": Vector3(10.0, 5.8, 8.0),
			"rot": -90.0,
			"mat": "plaster_rose"
		},
		{
			"district": "BarrioDelSur",
			"pos": Vector3(43.0, 0.0, 16.0),
			"size": Vector3(9.0, 5.0, 8.0),
			"rot": -90.0,
			"mat": "plaster_teal"
		},
		{
			"district": "BarrioDelSur",
			"pos": Vector3(18.0, 0.0, 36.0),
			"size": Vector3(10.0, 5.5, 8.0),
			"rot": 180.0,
			"mat": "plaster_ochre"
		},
		{
			"district": "BarrioDelSur",
			"pos": Vector3(43.0, 0.0, 36.0),
			"size": Vector3(9.0, 4.8, 8.0),
			"rot": 180.0,
			"mat": "plaster_cream"
		}
	]
	var index := 0
	for spec in specs:
		var material: Material = palette[String(spec["mat"])]
		_build_house(districts, spec, index, material, palette, rng)
		index += 1
		# Edificios singulares, situados en los extremos de sus manzanas.
	_build_landmark(
		districts,
		"CasaDeCabildo",
		Vector3(-18.0, 0.0, 0.0),
		Vector3(12.0, 7.0, 9.0),
		palette["plaster_cream"],
		palette,
		true
	)
	_build_landmark(
		districts,
		"MercadoDelPuerto",
		Vector3(18.0, 0.0, 0.0),
		Vector3(12.0, 5.4, 10.0),
		palette["plaster_ochre"],
		palette,
		false
	)
	_build_landmark(
		districts,
		"SantuarioDeLasCampanas",
		Vector3(43.0, 0.0, 0.0),
		Vector3(10.0, 8.0, 12.0),
		palette["plaster_teal"],
		palette,
		true
	)


static func _build_house(
	parent: Node3D, spec: Dictionary, index: int, wall_mat: Material, palette: Dictionary, rng: RandomNumberGenerator
) -> void:
	var house := Node3D.new()
	house.name = "%s_Casa_%02d" % [String(spec["district"]), index + 1]
	house.position = spec["pos"]
	house.rotation_degrees.y = float(spec["rot"])
	parent.add_child(house)
	var size: Vector3 = spec["size"]
	var width := size.x
	var height := size.y
	var depth := size.z
	VisualKit.add_box(house, Vector3(width + 0.45, 0.42, depth + 0.45), Vector3(0.0, 0.21, 0.0), palette["limestone"])
	VisualKit.add_box(house, Vector3(width, height, depth), Vector3(0.0, height * 0.5 + 0.35, 0.0), wall_mat)
	VisualKit.add_box(
		house, Vector3(width + 0.9, 0.38, depth + 0.9), Vector3(0.0, height + 0.54, 0.0), palette["roof_shadow"]
	)
	VisualKit.add_box(
		house, Vector3(width + 0.55, 0.52, depth + 0.55), Vector3(0.0, height + 0.92, 0.0), palette["roof"]
	)
	# Cornisas y pilastras de caliza para romper las masas planas.
	for side in [-1.0, 1.0]:
		VisualKit.add_box(
			house,
			Vector3(0.28, height, 0.32),
			Vector3(side * (width * 0.5 - 0.22), height * 0.5 + 0.35, -depth * 0.5 - 0.08),
			palette["limestone"]
		)

		# Entrada, marco y hojas de madera.

		# Balcón corrido de madera y baranda de hierro.

		# Collisión única por edificio: el interior no es transitable en esta entrega.

		# Variación mínima reproducible para que la calle no parezca una repetición rígida.
	VisualKit.add_box(
		house, Vector3(width + 0.45, 0.22, 0.28), Vector3(0.0, height + 0.28, -depth * 0.5 - 0.08), palette["limestone"]
	)
	# Entrada, marco y hojas de madera.
	VisualKit.add_box(house, Vector3(1.55, 2.55, 0.18), Vector3(0.0, 1.62, -depth * 0.5 - 0.12), palette["wood"])
	VisualKit.add_box(house, Vector3(1.18, 2.2, 0.12), Vector3(0.0, 1.56, -depth * 0.5 - 0.23), palette["wood_light"])
	VisualKit.add_box(house, Vector3(0.10, 0.10, 0.08), Vector3(0.42, 1.45, -depth * 0.5 - 0.31), palette["gold"])
	for window_x in [-width * 0.29, width * 0.29]:
		VisualKit.add_box(
			house, Vector3(1.25, 1.28, 0.12), Vector3(window_x, 2.55, -depth * 0.5 - 0.14), palette["wood"]
		)
		VisualKit.add_box(
			house, Vector3(0.96, 0.98, 0.08), Vector3(window_x, 2.55, -depth * 0.5 - 0.23), palette["glass"]
		)
		for shutter_side in [-1.0, 1.0]:
			VisualKit.add_box(
				house,
				Vector3(0.18, 1.34, 0.16),
				Vector3(window_x + shutter_side * 0.69, 2.55, -depth * 0.5 - 0.22),
				palette["wood_light"]
			)
		# Balcón corrido de madera y baranda de hierro.

		# Collisión única por edificio: el interior no es transitable en esta entrega.

		# Variación mínima reproducible para que la calle no parezca una repetición rígida.
	VisualKit.add_box(house, Vector3(width * 0.72, 0.16, 1.0), Vector3(0.0, 2.05, -depth * 0.5 - 0.75), palette["wood"])
	VisualKit.add_box(
		house, Vector3(width * 0.72, 0.12, 0.12), Vector3(0.0, 2.62, -depth * 0.5 - 1.15), palette["iron"]
	)
	for rail_x in range(-3, 4):
		VisualKit.add_box(
			house, Vector3(0.07, 0.58, 0.07), Vector3(float(rail_x) * 0.7, 2.34, -depth * 0.5 - 1.15), palette["iron"]
		)
		# Collisión única por edificio: el interior no es transitable en esta entrega.

		# Variación mínima reproducible para que la calle no parezca una repetición rígida.
	var body := StaticBody3D.new()
	body.name = "BuildingCollision"
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, height + 0.6, depth)
	collision.shape = shape
	body.add_child(collision)
	body.position.y = (height + 0.6) * 0.5
	body.collision_layer = ArpgLayers.WORLD
	body.collision_mask = 0
	house.add_child(body)
	# Variación mínima reproducible para que la calle no parezca una repetición rígida.
	if rng.randf() > 0.45:
		VisualKit.add_box(
			house, Vector3(0.7, 0.16, 0.7), Vector3(-width * 0.36, height + 1.23, depth * 0.25), palette["limestone"]
		)


static func _build_landmark(
	parent: Node3D,
	landmark_name: String,
	position: Vector3,
	size: Vector3,
	wall_mat: Material,
	palette: Dictionary,
	tower: bool
) -> void:
	var landmark := Node3D.new()
	landmark.name = landmark_name
	landmark.position = position
	parent.add_child(landmark)
	VisualKit.add_box(landmark, Vector3(size.x + 0.8, 0.5, size.z + 0.8), Vector3(0.0, 0.25, 0.0), palette["limestone"])
	VisualKit.add_box(landmark, size, Vector3(0.0, size.y * 0.5 + 0.5, 0.0), wall_mat)
	VisualKit.add_box(
		landmark, Vector3(size.x + 1.4, 0.42, size.z + 1.4), Vector3(0.0, size.y + 0.72, 0.0), palette["roof_shadow"]
	)
	VisualKit.add_box(
		landmark, Vector3(size.x + 0.8, 0.48, size.z + 0.8), Vector3(0.0, size.y + 1.15, 0.0), palette["roof"]
	)
	for window_x in [-size.x * 0.28, size.x * 0.28]:
		VisualKit.add_box(
			landmark, Vector3(1.3, 1.8, 0.12), Vector3(window_x, 2.7, -size.z * 0.5 - 0.12), palette["glass"]
		)
	if tower:
		VisualKit.add_box(landmark, Vector3(3.0, 4.2, 3.0), Vector3(0.0, size.y + 2.6, 0.0), palette["limestone"])
		VisualKit.add_cone(landmark, 2.2, 2.4, Vector3(0.0, size.y + 6.0, 0.0), palette["roof"])
		VisualKit.add_box(landmark, Vector3(0.22, 1.4, 0.22), Vector3(0.0, size.y + 7.4, 0.0), palette["gold"])
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size + Vector3(0.0, 0.8, 0.0)
	collision.shape = shape
	body.add_child(collision)
	body.position.y = (size.y + 0.8) * 0.5
	body.collision_layer = ArpgLayers.WORLD
	body.collision_mask = 0
	landmark.add_child(body)


static func _build_street_furniture(root: Node3D, palette: Dictionary) -> void:
	var furniture := Node3D.new()
	furniture.name = "StreetFurniture"
	root.add_child(furniture)
	for z_value in [-28.0, 28.0]:
		_build_lamp(furniture, Vector3(-7.0, 0.0, z_value), palette)
		_build_lamp(furniture, Vector3(7.0, 0.0, z_value), palette)
	for x_value in [-42.0, 42.0]:
		_build_lamp(furniture, Vector3(x_value, 0.0, -7.0), palette)
		_build_lamp(furniture, Vector3(x_value, 0.0, 7.0), palette)
	_build_market_stall(furniture, Vector3(36.0, 0.0, -8.0), palette)
	_build_market_stall(furniture, Vector3(36.0, 0.0, 8.0), palette)


static func _build_lamp(parent: Node3D, position: Vector3, palette: Dictionary) -> void:
	var lamp := Node3D.new()
	lamp.name = "FarolColonial"
	lamp.position = position
	parent.add_child(lamp)
	VisualKit.add_cylinder(lamp, 0.12, 3.4, Vector3(0.0, 1.7, 0.0), palette["iron"], 8)
	VisualKit.add_box(lamp, Vector3(0.58, 0.68, 0.58), Vector3(0.0, 3.55, 0.0), palette["iron"])
	VisualKit.add_sphere(lamp, 0.22, Vector3(0.0, 3.55, 0.0), palette["gold"])
	var light := OmniLight3D.new()
	light.name = "LuzAmbar"
	light.position = Vector3(0.0, 3.55, 0.0)
	light.light_color = Color(1.0, 0.63, 0.31)
	light.light_energy = 0.55
	light.omni_range = 5.0
	light.shadow_enabled = false
	lamp.add_child(light)
	var controller := parent.get_parent().get_node_or_null("EnvironmentController") as EnvironmentController
	if controller != null:
		controller.register_night_light(light)


static func _build_market_stall(parent: Node3D, position: Vector3, palette: Dictionary) -> void:
	var stall := Node3D.new()
	stall.name = "PuestoMercado"
	stall.position = position
	parent.add_child(stall)
	VisualKit.add_box(stall, Vector3(3.8, 0.18, 2.4), Vector3(0.0, 1.3, 0.0), palette["wood"])
	for x_value in [-1.65, 1.65]:
		for z_value in [-0.95, 0.95]:
			VisualKit.add_cylinder(stall, 0.09, 2.7, Vector3(x_value, 1.35, z_value), palette["wood"], 6)

		# Toldos alternos rosa/verde: identidad de mercado portuario caribeno.
	VisualKit.add_box(stall, Vector3(4.3, 0.14, 2.8), Vector3(0.0, 2.75, 0.0), palette["roof"])
	# Toldos alternos rosa/verde: identidad de mercado portuario caribeno.
	var awning_materials: Array = [palette["plaster_rose"], palette["plaster_teal"]]
	for awning_index in range(4):
		VisualKit.add_box(
			stall,
			Vector3(1.12, 0.10, 3.0),
			Vector3(-1.72 + awning_index * 1.15, 2.95, 0.0),
			awning_materials[awning_index % 2]
		)


static func _build_bench(parent: Node3D, position: Vector3, rotation: float, palette: Dictionary) -> void:
	var bench := Node3D.new()
	bench.name = "BancoDePlaza"
	bench.position = position
	bench.rotation_degrees.y = rotation
	parent.add_child(bench)
	VisualKit.add_box(bench, Vector3(2.6, 0.16, 0.62), Vector3(0.0, 0.62, 0.0), palette["wood"])
	VisualKit.add_box(bench, Vector3(2.6, 0.72, 0.14), Vector3(0.0, 0.98, 0.25), palette["wood"])
	for x_value in [-1.0, 1.0]:
		VisualKit.add_box(bench, Vector3(0.16, 0.62, 0.52), Vector3(x_value, 0.31, 0.0), palette["iron"])


static func _build_greenery(root: Node3D, rng: RandomNumberGenerator, density: float, palette: Dictionary) -> void:
	var greenery := Node3D.new()
	greenery.name = "Greenery"
	root.add_child(greenery)
	var tree_count := int(18.0 * density) + 6
	for index in range(tree_count):
		var side := -1.0 if index % 2 == 0 else 1.0
		var x_value := side * rng.randf_range(39.0, 47.0)
		var z_value := rng.randf_range(-38.0, 38.0)
		_build_tree(greenery, Vector3(x_value, 0.0, z_value), rng, palette)
	for position in [
		Vector3(-8.8, 0.0, -8.8), Vector3(8.8, 0.0, -8.8), Vector3(-8.8, 0.0, 8.8), Vector3(8.8, 0.0, 8.8)
	]:
		_build_tree(greenery, position, rng, palette)


static func _build_tree(parent: Node3D, position: Vector3, rng: RandomNumberGenerator, palette: Dictionary) -> void:
	var tree := Node3D.new()
	tree.name = "ArbolTropical"
	tree.position = position
	parent.add_child(tree)
	var height := rng.randf_range(3.8, 5.0)
	VisualKit.add_cylinder(tree, 0.28, height, Vector3(0.0, height * 0.5, 0.0), palette["bark"], 8)
	var canopy := VisualKit.add_sphere(tree, 1.8, Vector3(0.0, height + 0.55, 0.0), palette["leaf"])
	canopy.scale = Vector3(1.35, 0.9, 1.25)
	for offset in [Vector3(-1.0, height + 0.25, 0.4), Vector3(0.9, height + 0.4, -0.5)]:
		var cluster := VisualKit.add_sphere(tree, 1.1, offset, palette["leaf_light"])
		cluster.scale = Vector3(1.2, 0.8, 1.1)


static func _build_city_edges(root: Node3D, palette: Dictionary) -> void:
	var edges := Node3D.new()
	edges.name = "CityEdgeAndEntrances"
	root.add_child(edges)
	for x_value in [-CITY_HALF_WIDTH, CITY_HALF_WIDTH]:
		VisualKit.add_box(
			edges, Vector3(0.8, 2.2, CITY_HALF_DEPTH * 2.0), Vector3(x_value, 1.1, 0.0), palette["limestone"]
		)

		# Portales visuales abiertos en los dos extremos del camino principal.
	for z_value in [-CITY_HALF_DEPTH, CITY_HALF_DEPTH]:
		var segment_width := CITY_HALF_WIDTH - 4.5
		VisualKit.add_box(
			edges,
			Vector3(segment_width, 2.2, 0.8),
			Vector3(-CITY_HALF_WIDTH * 0.5 - 2.25, 1.1, z_value),
			palette["limestone"]
		)
		VisualKit.add_box(
			edges,
			Vector3(segment_width, 2.2, 0.8),
			Vector3(CITY_HALF_WIDTH * 0.5 + 2.25, 1.1, z_value),
			palette["limestone"]
		)
		# Portales visuales abiertos en los dos extremos del camino principal.
	for z_value in [-CITY_HALF_DEPTH, CITY_HALF_DEPTH]:
		VisualKit.add_box(edges, Vector3(0.65, 5.2, 0.65), Vector3(-4.2, 2.6, z_value), palette["limestone"])
		VisualKit.add_box(edges, Vector3(0.65, 5.2, 0.65), Vector3(4.2, 2.6, z_value), palette["limestone"])
		VisualKit.add_box(edges, Vector3(9.0, 0.55, 0.7), Vector3(0.0, 5.2, z_value), palette["limestone"])

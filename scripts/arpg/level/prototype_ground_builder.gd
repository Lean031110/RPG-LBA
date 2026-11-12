class_name PrototypeGroundBuilder
## Escenario de pruebas de la Fase 2 (prompt FASE 2 §8): pequeño, funcional y
## determinista (sin RNG) para validar movimiento, colisiones, pendientes y escala.
## NO es una región de Lythara ni contenido del juego: es infraestructura de prueba;
## la ambientación completa llega con el Art Pass (Fase 1B) sobre dirección aprobada.
## Grupos: Ground, WorldEnvironment, Boundaries, Obstacles, Heights, ScaleRefs.

const AREA_MIN_X := -14.0
const AREA_MAX_X := 14.0
const AREA_MIN_Z := -12.0
const AREA_MAX_Z := 16.0
const BOUNDARY_MARGIN := 1.6
const PATH_HALF_WIDTH := 2.3

# Alturas de la Fase 2: plataforma de piedra + dos rampas (pendiente ~15°, muy por
# debajo del límite de 45° de CharacterBody3D). Geometría fija: sin RNG, testeable.
const PLATFORM_CENTER := Vector3(8.0, 0.375, 10.0)
const PLATFORM_SIZE := Vector3(5.0, 0.75, 5.0)
const RAMP_RUN := 2.75
const RAMP_RISE := 0.75
const RAMP_THICKNESS := 0.24
const RAMP_WIDTH := 3.0


static func build_all(root: Node3D) -> void:
	_build_ground(root)
	_build_lighting(root)
	_build_boundaries(root)
	_build_obstacles(root)
	_build_heights(root)
	_build_scale_refs(root)


static func play_area_rect() -> Rect2:
	## Rectángulo jugable (XZ) sin el margen de límites; lo usan las pruebas.
	return Rect2(
		AREA_MIN_X + BOUNDARY_MARGIN,
		AREA_MIN_Z + BOUNDARY_MARGIN,
		(AREA_MAX_X - AREA_MIN_X) - BOUNDARY_MARGIN * 2.0,
		(AREA_MAX_Z - AREA_MIN_Z) - BOUNDARY_MARGIN * 2.0
	)


static func _build_ground(root: Node3D) -> void:
	var ground := Node3D.new()
	ground.name = "Ground"
	root.add_child(ground)
	var ground_mat := VisualKit.noise_material(VisualKit.MAT_GRASS, 0.05, 5)
	var ground_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2((AREA_MAX_X - AREA_MIN_X) + 12.0, (AREA_MAX_Z - AREA_MIN_Z) + 12.0)
	ground_mesh.mesh = plane
	ground_mesh.material_override = ground_mat
	ground.add_child(ground_mesh)

	var ground_body := StaticBody3D.new()
	ground_body.name = "GroundBody"
	ground_body.collision_layer = ArpgLayers.WORLD
	ground_body.collision_mask = 0
	var ground_shape := CollisionShape3D.new()
	var ground_box := BoxShape3D.new()
	ground_box.size = Vector3(plane.size.x + 12.0, 0.4, plane.size.y + 12.0)
	ground_shape.shape = ground_box
	ground_body.add_child(ground_shape)
	ground_body.position = Vector3(0, -0.2, 0)
	ground.add_child(ground_body)

	# Camino principal de tierra roja (N-S) y ramal corto (E-W, ligeramente más bajo
	# que el principal para evitar z-fighting en el cruce).
	var dirt_mat := VisualKit.noise_material(VisualKit.MAT_DIRT, 0.14, 4)
	var paths := Node3D.new()
	paths.name = "RedDirtPaths"
	ground.add_child(paths)
	VisualKit.add_box(
		paths,
		Vector3(PATH_HALF_WIDTH * 2.0, 0.08, (AREA_MAX_Z - AREA_MIN_Z) + 2.0),
		Vector3(0, 0.045, (AREA_MAX_Z + AREA_MIN_Z) / 2.0),
		dirt_mat
	)
	VisualKit.add_box(paths, Vector3((AREA_MAX_X - AREA_MIN_X) + 2.0, 0.06, 3.0), Vector3(0, 0.035, 0.0), dirt_mat)


static func _build_lighting(root: Node3D) -> void:
	# Misma receta de la vertical slice (media mañana, sin sombras dinámicas: perfil Low
	# como referencia de diseño). El ciclo día/noche completo llega en el Art Pass.
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


static func _build_boundaries(root: Node3D) -> void:
	## Límites físicos invisibles + postes de madera como referencia visual del borde.
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

		# Postes de madera (solo visuales; el bloqueo real lo hacen los muros invisibles).
	var post_mat := VisualKit.noise_material(VisualKit.MAT_WOOD, 0.3, 3)
	var post_positions := [
		Vector3(rect.position.x, 0, rect.position.y),
		Vector3(rect.position.x + rect.size.x, 0, rect.position.y),
		Vector3(rect.position.x, 0, rect.position.y + rect.size.y),
		Vector3(rect.position.x + rect.size.x, 0, rect.position.y + rect.size.y),
		Vector3(rect.position.x, 0, rect.position.y + rect.size.y / 2.0),
		Vector3(rect.position.x + rect.size.x, 0, rect.position.y + rect.size.y / 2.0),
		Vector3(rect.position.x + rect.size.x / 2.0, 0, rect.position.y),
		Vector3(rect.position.x + rect.size.x / 2.0, 0, rect.position.y + rect.size.y),
	]
	for post_position: Vector3 in post_positions:
		VisualKit.add_cylinder(walls, 0.18, 1.4, post_position + Vector3(0, 0.7, 0), post_mat, 7)


static func _build_obstacles(root: Node3D) -> void:
	## Obstáculos con colisión real (capa WORLD): cajas, barriles y tronco caído.
	var obstacles := Node3D.new()
	obstacles.name = "Obstacles"
	root.add_child(obstacles)
	var wood_mat := VisualKit.noise_material(VisualKit.MAT_WOOD, 0.3, 3)
	var crate_mat := VisualKit.noise_material(Color(0.52, 0.40, 0.24), 0.25, 3)
	# Cajones de carga (empalizada de la carreta de prueba).
	_box_obstacle(obstacles, Vector3(1.2, 1.2, 1.2), Vector3(-7.0, 0.6, 3.0), crate_mat, 18.0)
	_box_obstacle(obstacles, Vector3(1.0, 1.0, 1.0), Vector3(-5.6, 0.5, 6.4), crate_mat, -12.0)
	_box_obstacle(obstacles, Vector3(0.9, 0.9, 0.9), Vector3(9.5, 0.45, -6.0), crate_mat, 40.0)
	# Barriles (cilindros).
	_cylinder_obstacle(obstacles, 0.5, 1.1, Vector3(-2.5, 0.55, -5.0), wood_mat)
	_cylinder_obstacle(obstacles, 0.5, 1.1, Vector3(-3.4, 0.55, -2.2), wood_mat)
	# Tronco caído atravesado (salto de escala: se rodea, no se salta).
	_box_obstacle(obstacles, Vector3(4.0, 0.6, 0.6), Vector3(-10.0, 0.35, 10.0), wood_mat, 8.0)


static func _build_heights(root: Node3D) -> void:
	## Plataforma de piedra + rampa de acceso en Z y rampa de acceso en X.
	## La rampa sube 0.75 m en 2.75 m (15.3°): la cara SUPERIOR queda a ras de la
	## línea de pendiente para no dejar escalón al unirse con la plataforma.
	var heights := Node3D.new()
	heights.name = "Heights"
	root.add_child(heights)
	var stone_mat := VisualKit.noise_material(VisualKit.MAT_STONE, 0.18, 4)
	var wood_mat := VisualKit.noise_material(VisualKit.MAT_WOOD.darkened(0.15), 0.25, 3)
	_box_obstacle(heights, PLATFORM_SIZE, PLATFORM_CENTER, stone_mat, 0.0)

	var angle := ramp_angle_rad()
	var slope_length := sqrt(RAMP_RUN * RAMP_RUN + RAMP_RISE * RAMP_RISE)
	# Centro en la línea de pendiente menos medio espesor/cos: cara superior a ras.
	var center_y := (RAMP_RISE * 0.5) - (RAMP_THICKNESS * 0.5) / cos(angle)
	# Rampa A: asciende hacia +Z y remata en el borde sur de la plataforma.
	var ramp_a := _box_obstacle(
		heights,
		Vector3(RAMP_WIDTH, RAMP_THICKNESS, slope_length),
		Vector3(8.0, center_y, PLATFORM_CENTER.z - PLATFORM_SIZE.z * 0.5 - RAMP_RUN * 0.5),
		wood_mat,
		0.0
	)
	ramp_a.rotation_degrees.x = -rad_to_deg(angle)
	# Rampa B: asciende hacia +X y remata en el borde oeste de la plataforma.
	var ramp_b := _box_obstacle(
		heights,
		Vector3(slope_length, RAMP_THICKNESS, RAMP_WIDTH),
		Vector3(PLATFORM_CENTER.x - PLATFORM_SIZE.x * 0.5 - RAMP_RUN * 0.5, center_y, 10.0),
		wood_mat,
		0.0
	)
	ramp_b.rotation_degrees.z = rad_to_deg(angle)


static func ramp_angle_rad() -> float:
	return atan(RAMP_RISE / RAMP_RUN)


static func _build_scale_refs(root: Node3D) -> void:
	## Referencias de escala humana: marco de puerta (2.1 m) y farol (3.2 m).
	var refs := Node3D.new()
	refs.name = "ScaleRefs"
	root.add_child(refs)
	var wood_mat := VisualKit.noise_material(VisualKit.MAT_WOOD, 0.3, 3)
	# Marco de puerta: jambas con colisión (delgadas) + dintel solo visual.
	_box_obstacle(refs, Vector3(0.24, 2.1, 0.24), Vector3(-12.1, 1.05, 0.0), wood_mat, 0.0)
	_box_obstacle(refs, Vector3(0.24, 2.1, 0.24), Vector3(-10.9, 1.05, 0.0), wood_mat, 0.0)
	var lintel := Node3D.new()
	lintel.name = "DoorLintel"
	refs.add_child(lintel)
	VisualKit.add_box(lintel, Vector3(1.7, 0.22, 0.24), Vector3(-11.5, 2.0, 0.0), wood_mat)
	# Farol: poste con colisión + esfera encendida (emisión).
	_cylinder_obstacle(refs, 0.14, 3.2, Vector3(12.0, 1.6, -9.0), wood_mat)
	VisualKit.add_sphere(
		refs,
		0.28,
		Vector3(12.0, 3.35, -9.0),
		VisualKit.flat_material(Color(0.9, 0.75, 0.4), Color(1.0, 0.8, 0.45), 1.2)
	)


static func _box_obstacle(
	parent: Node, size: Vector3, position: Vector3, material: Material, yaw_deg := 0.0
) -> StaticBody3D:
	## Cuerpo estático en capa WORLD con su malla: una sola fuente de geometría.
	var body := StaticBody3D.new()
	body.collision_layer = ArpgLayers.WORLD
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	VisualKit.add_box(body, size, Vector3.ZERO, material)
	body.position = position
	if not is_zero_approx(yaw_deg):
		body.rotation_degrees.y = yaw_deg
	parent.add_child(body)
	return body


static func _cylinder_obstacle(
	parent: Node, radius: float, height: float, position: Vector3, material: Material
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = ArpgLayers.WORLD
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = height
	shape.shape = cylinder
	body.add_child(shape)
	VisualKit.add_cylinder(body, radius, height, Vector3.ZERO, material, 10)
	body.position = position
	parent.add_child(body)
	return body

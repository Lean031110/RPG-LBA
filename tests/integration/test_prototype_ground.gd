class_name TestPrototypeGround
extends GdUnitTestSuite
## Escenario de pruebas de la Fase 2: montaje determinista, capas de colisión,
## subida/bajada de rampa (floor_snap), límites que bloquean y gravedad real.


func _build() -> Node3D:
	var root: Node3D = auto_free(Node3D.new())
	add_child(root)
	PrototypeGroundBuilder.build_all(root)
	return root


func _make_scene() -> PrototypeGround:
	var scene: Node = load("res://scenes/arpg/prototype/prototype_ground.tscn").instantiate()
	var ground: PrototypeGround = auto_free(scene) as PrototypeGround
	add_child(ground)
	return ground


func _frames(count: int) -> void:
	for index: int in count:
		await get_tree().physics_frame


func test_builder_creates_all_groups() -> void:
	var root := _build()
	for group: String in ["Ground", "WorldEnvironment", "Boundaries", "Obstacles", "Heights", "ScaleRefs"]:
		assert_bool(root.get_node_or_null(group) != null).is_true()


func test_play_area_rect_is_sane() -> void:
	var rect := PrototypeGroundBuilder.play_area_rect()
	assert_float(rect.size.x).is_greater(20.0)
	assert_float(rect.size.y).is_greater(20.0)


func test_colliders_use_world_layer() -> void:
	var root := _build()
	var checked := 0
	for group: String in ["Boundaries", "Obstacles", "Heights"]:
		for child in root.get_node(group).get_children():
			if child is StaticBody3D:
				checked += 1
				assert_int((child as StaticBody3D).collision_layer).is_equal(ArpgLayers.WORLD)
				assert_int((child as StaticBody3D).collision_mask).is_equal(0)
	assert_int(checked).is_greater_equal(10)


func test_layout_is_deterministic() -> void:
	var first := _build()
	var second := _build()
	for group: String in ["Obstacles", "Heights", "ScaleRefs"]:
		assert_int(first.get_node(group).get_child_count()).is_equal(second.get_node(group).get_child_count())


func test_scene_assembles_player_camera_hud() -> void:
	var ground := _make_scene()
	assert_object(ground.player).is_instanceof(ArpgPlayer)
	assert_object(ground.camera_rig).is_instanceof(IsoCameraRig)
	assert_object(ground.hud).is_instanceof(ArpgHUD)
	# El jugador arranca en el marcador de aparición (0, 0.1, -8).
	assert_float(ground.player.global_position.z).is_less(-7.0)
	# Fase 2: la cámara queda registrada como marco del movimiento.
	assert_object(ground.player.camera_source).is_instanceof(IsoCameraRig)


func test_player_climbs_ramp_and_stays_on_floor() -> void:
	var ground := _make_scene()
	var player := ground.player
	# Base de la rampa A (asciende hacia +Z hasta la plataforma de piedra).
	player.global_position = Vector3(8.0, 0.15, 4.2)
	player.joystick_vector = Vector2(0, 1)
	await _frames(60)
	assert_float(player.global_position.y).is_greater(0.6)
	assert_bool(player.is_on_floor()).is_true()
	# Bajada por la misma rampa: floor_snap evita el micro-vuelo en el descenso.
	player.joystick_vector = Vector2(0, -1)
	await _frames(60)
	assert_float(player.global_position.y).is_less(0.2)
	assert_bool(player.is_on_floor()).is_true()
	player.joystick_vector = Vector2.ZERO


func test_boundary_walls_block_player() -> void:
	var ground := _make_scene()
	var player := ground.player
	var rect := PrototypeGroundBuilder.play_area_rect()
	# Correr hacia el muro sur a plena velocidad: el muro invisible frena al jugador.
	player.joystick_vector = Vector2(0, -1)
	await _frames(90)
	assert_float(player.global_position.z).is_greater(rect.position.y - 0.7)
	assert_bool(player.is_on_floor()).is_true()
	player.joystick_vector = Vector2.ZERO


func test_gravity_lands_on_ground() -> void:
	var ground := _make_scene()
	var player := ground.player
	player.global_position = Vector3(0, 3.0, -8)
	await _frames(40)
	assert_bool(player.is_on_floor()).is_true()
	assert_float(player.velocity.y).is_equal_approx(0.0, 0.01)

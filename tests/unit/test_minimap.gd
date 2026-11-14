class_name TestMinimap
extends GdUnitTestSuite
## Minimapa Fase 3: matemática pura (mundo->blip, yaw->ángulo), estructura del control,
## cámara cenital que sigue al jugador y grupos de blips (enemigos/recogibles/NPCs).


func test_world_to_blip_center_is_player() -> void:
	var blip := ArpgMinimap.world_to_blip(Vector3.ZERO, 30.0, Vector2(224, 168))
	assert_vector(blip).is_equal_approx(Vector2(112, 84), Vector2(0.01, 0.01))


func test_world_to_blip_edges() -> void:
	# Este (+X) queda al borde derecho; norte (-Z) al borde superior (norte arriba).
	var east := ArpgMinimap.world_to_blip(Vector3(15, 0, 0), 30.0, Vector2(224, 168))
	assert_float(east.x).is_equal_approx(224.0, 0.01)
	var north := ArpgMinimap.world_to_blip(Vector3(0, 0, -15), 30.0, Vector2(224, 168))
	assert_float(north.y).is_equal_approx(0.0, 0.01)


func test_world_to_blip_scales_with_span() -> void:
	# Con el doble de alcance mundial, el mismo offset ocupa la mitad de píxeles.
	var near := ArpgMinimap.world_to_blip(Vector3(10, 0, 0), 30.0, Vector2(224, 168))
	var far := ArpgMinimap.world_to_blip(Vector3(10, 0, 0), 60.0, Vector2(224, 168))
	assert_float(near.x - 112.0).is_equal_approx((far.x - 112.0) * 2.0, 0.01)


func test_facing_arrow_angles() -> void:
	# Norte (-Z, yaw=PI) apunta arriba (0 rad); este (+X, yaw=PI/2) a la derecha;
	# sur (+Z, yaw=0) hacia abajo (PI). Convención draw_* de Godot (horario).
	assert_float(ArpgMinimap.facing_to_arrow_angle(PI)).is_equal_approx(0.0, 0.001)
	assert_float(ArpgMinimap.facing_to_arrow_angle(PI / 2.0)).is_equal_approx(PI / 2.0, 0.001)
	assert_float(ArpgMinimap.facing_to_arrow_angle(0.0)).is_equal_approx(PI, 0.001)


func _make_minimap() -> ArpgMinimap:
	var minimap: ArpgMinimap = auto_free(ArpgMinimap.new())
	add_child(minimap)
	return minimap


func _make_player(at: Vector3) -> ArpgPlayer:
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = ArpgLayers.WORLD
	floor_body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0, -0.55, 0)
	add_child(auto_free(floor_body))
	var player: ArpgPlayer = auto_free(ArpgPlayer.new())
	add_child(player)
	player.setup("machetero")
	player.global_position = at
	return player


func test_structure_builds_viewport_and_camera() -> void:
	var minimap := _make_minimap()
	assert_object(minimap.get_map_viewport()).is_not_null()
	assert_object(minimap.get_map_camera()).is_not_null()
	var camera := minimap.get_map_camera()
	assert_int(camera.projection).is_equal(Camera3D.PROJECTION_ORTHOGONAL)
	# Mirada cenital: pitch -90 grados deja el norte (-Z) arriba en pantalla.
	assert_float(camera.rotation.x).is_equal_approx(-PI / 2.0, 0.001)


func test_set_player_shares_world_and_camera_follows() -> void:
	var minimap := _make_minimap()
	var player := _make_player(Vector3(3, 0.5, -7))
	minimap.set_player(player)
	assert_object(minimap.get_map_viewport().world_3d).is_same(player.get_world_3d())
	player.global_position = Vector3(20, 0.5, 14)
	for index: int in 45:
		await get_tree().physics_frame
	var camera := minimap.get_map_camera()
	assert_float(camera.global_position.x).is_equal_approx(20.0, 0.6)
	assert_float(camera.global_position.z).is_equal_approx(14.0, 0.6)
	assert_float(camera.global_position.y).is_equal_approx(ArpgMinimap.CAMERA_HEIGHT, 0.6)


func test_blip_groups_registered_by_entities() -> void:
	# Contrato de grupos Fase 3: minimapa consulta arpg_enemies/arpg_pickups/arpg_npcs.
	var enemy: ShadowOfPortal = auto_free(ShadowOfPortal.new())
	add_child(enemy)
	enemy.setup("sombra_de_portal")
	assert_bool(enemy.is_in_group("arpg_enemies")).is_true()

	var pickup: ArpgPickup = auto_free(ArpgPickup.new())
	add_child(pickup)
	pickup.setup("pocion_curativa")
	assert_bool(pickup.is_in_group("arpg_pickups")).is_true()

	var cheo: CheoNPC = auto_free(CheoNPC.new())
	add_child(cheo)
	cheo.setup("cheo")
	assert_bool(cheo.is_in_group("arpg_npcs")).is_true()


func test_blips_draw_without_errors_with_entities() -> void:
	var minimap := _make_minimap()
	var player := _make_player(Vector3(0, 0.5, 0))
	minimap.set_player(player)
	var enemy: ShadowOfPortal = auto_free(ShadowOfPortal.new())
	add_child(enemy)
	enemy.global_position = Vector3(4, 0.5, 3)
	enemy.setup("sombra_de_portal")
	for index: int in 10:
		await get_tree().physics_frame
	# Sin errores de dibujo/escript en el camino completo (headless: estructura, no píxeles).
	assert_object(minimap.get_map_camera()).is_not_null()

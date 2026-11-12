class_name TestPickups
extends GdUnitTestSuite
## Recogibles: fragmento de bronce notifica a la misión (via el que escucha la señal,
## como hace la slice); la poción la añade el propio pickup al inventario del jugador.


func _frames(count: int) -> void:
	for index: int in count:
		await get_tree().physics_frame


func before_test() -> void:
	QuestSystem.reset_for_new_game()


func _ensure_floor() -> void:
	if get_node_or_null("TestFloor") != null:
		return
	var floor_body := StaticBody3D.new()
	floor_body.name = "TestFloor"
	floor_body.collision_layer = ArpgLayers.WORLD
	floor_body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(160, 1, 160)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0, -0.55, 0)
	add_child(auto_free(floor_body))


func _make_player(at: Vector3) -> ArpgPlayer:
	_ensure_floor()
	var player: ArpgPlayer = auto_free(ArpgPlayer.new())
	add_child(player)
	player.setup("machetero")
	player.global_position = at
	return player


func _make_pickup(type: String, at: Vector3) -> ArpgPickup:
	var pickup: ArpgPickup = auto_free(ArpgPickup.new())
	add_child(pickup)
	pickup.global_position = at
	pickup.setup(type)
	return pickup


func test_fragment_collect_notifies_quest() -> void:
	QuestSystem.accept("VS_P00")
	var player := _make_player(Vector3(-6, 0.5, -6))
	# Alambre igual que la slice: la señal la traduce a notificacion de mision.
	var collected_types := []
	var pickup := _make_pickup("fragmento_bronce", Vector3(-6, 0.45, -6))
	pickup.collected.connect(
		func(pickup_type: String, amount: int) -> void:
			collected_types.append(pickup_type)
			QuestSystem.notify_collect(pickup_type, amount)
	)
	await _frames(10)
	assert_array(collected_types).has_size(1)
	assert_int(QuestSystem.objective_progress("VS_P00", "obj_vs_p00_collect")).is_equal(1)


func test_potion_pickup_adds_to_player() -> void:
	var player := _make_player(Vector3(0, 0.5, 4))
	var potions_before := player.potions
	_make_pickup("pocion_curativa", Vector3(0, 0.45, 4))
	await _frames(10)
	assert_int(player.potions).is_equal(potions_before + 1)


func test_pickup_requires_player_body() -> void:
	# Un nodo cualquiera sin add_potion no dispara la recoleccion.
	var player := _make_player(Vector3(12, 0.5, 12))
	var pickup := _make_pickup("pocion_curativa", Vector3(4, 0.45, 4))
	var collected_count := [0]
	pickup.collected.connect(func(_type: String, _amount: int) -> void: collected_count[0] += 1)
	await _frames(8)
	assert_int(collected_count[0]).is_equal(0)
	assert_bool(is_instance_valid(pickup))
	# El jugador entra en el radio: se recoge.
	player.global_position = Vector3(4, 0.5, 4)
	await _frames(8)
	assert_int(collected_count[0]).is_equal(1)


func test_fragment_pickup_bobs_and_spins() -> void:
	var pickup := _make_pickup("fragmento_bronce", Vector3(-10, 0.45, 10))
	var root := pickup._visual_root
	var y_before := root.position.y
	var rot_before := root.rotation_degrees.y
	await _frames(30)
	assert_float(absf(root.position.y - y_before)).is_greater(0.0)
	assert_float(root.rotation_degrees.y - rot_before).is_not_equal(0.0)

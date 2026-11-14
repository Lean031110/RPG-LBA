class_name TestEnemyAi
extends GdUnitTestSuite
## Sombra de Portal: detectar -> perseguir -> telegraph (windup) -> golpear -> recuperar.
## El telegráfico es legible y el daño pasa por take_damage del jugador (dodge lo anula).


func _frames(count: int) -> void:
	for index: int in count:
		await get_tree().physics_frame


func _ensure_floor() -> void:
	## Suelo de prueba: sin el, la gravedad desplaza a los cuerpos y rompe las distancias.
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


func _make_pair(player_pos: Vector3, enemy_pos: Vector3) -> Array:
	_ensure_floor()
	var player: ArpgPlayer = auto_free(ArpgPlayer.new())
	add_child(player)
	player.setup("machetero")
	player.global_position = player_pos
	var enemy: ShadowOfPortal = auto_free(ShadowOfPortal.new())
	add_child(enemy)
	enemy.global_position = enemy_pos
	enemy.setup("sombra_de_portal")
	enemy.set_target(player)
	return [player, enemy]


func test_starts_idle_far_away() -> void:
	var pair := _make_pair(Vector3(0, 0.5, 0), Vector3(0, 0.5, 14))
	await _frames(10)
	assert_str(pair[1].get_state_name()).is_equal("idle")


func test_detects_and_chases() -> void:
	var pair := _make_pair(Vector3(0, 0.5, 0), Vector3(0, 0.5, 14))
	var enemy: ShadowOfPortal = pair[1]
	enemy.global_position = Vector3(0, 0.5, 7.5)
	await _frames(10)
	assert_str(enemy.get_state_name()).is_equal("chase")


func test_loses_target_beyond_radius() -> void:
	var pair := _make_pair(Vector3(0, 0.5, 0), Vector3(0, 0.5, 2.0))
	var enemy: ShadowOfPortal = pair[1]
	await _frames(6)
	assert_str(enemy.get_state_name()).is_not_equal("idle")
	pair[0].global_position = Vector3(0, 0.5, 40)
	await _frames(10)
	assert_str(enemy.get_state_name()).is_equal("idle")


func test_windup_then_strike_then_recover() -> void:
	var pair := _make_pair(Vector3(0, 0.5, 0), Vector3(0, 0.5, 1.8))
	var player: ArpgPlayer = pair[0]
	var enemy: ShadowOfPortal = pair[1]
	await _frames(10)
	assert_str(enemy.get_state_name()).is_equal("windup")
	# Windup 0.75 s (frames ~45) -> strike.
	await _frames(50)
	assert_str(enemy.get_state_name()).is_equal("strike")
	var hp_after_strike := player.hp
	assert_float(player.max_hp - hp_after_strike).is_greater(5.0)
	# La ventana de golpe es 0.25 s (frames ~15) -> recover.
	await _frames(20)
	assert_str(enemy.get_state_name()).is_equal("recover")
	# Recover 1.1 s -> chase; atrapar el frame exacto del cambio (luego re-ataca).
	for index: int in 90:
		await get_tree().physics_frame
		if enemy.get_state_name() != "recover":
			break
	assert_str(enemy.get_state_name()).is_equal("chase")


func test_strike_damage_matches_data() -> void:
	var pair := _make_pair(Vector3(0, 0.5, 0), Vector3(0, 0.5, 1.6))
	var player: ArpgPlayer = pair[0]
	var enemy: ShadowOfPortal = pair[1]
	var hp_before := player.hp
	await _frames(10)
	await _frames(55)
	var hp_after := player.hp
	var dealt := hp_before - hp_after
	var expected := (
		CombatService
		. damage_from_data(
			{
				"potency": float(enemy.enemy_data["potency"]),
				"damage_coeff": float(enemy.enemy_data["damage_coeff"]),
				"damage_type": String(enemy.enemy_data["damage_type"]),
			},
			enemy.get_attribute_value(),
			player.armor,
		)
	)
	# Un solo golpe con gracia de 0.25 s: no hay doble aplicacion.
	assert_float(dealt).is_greater(expected * 0.9)
	assert_float(dealt).is_less(expected * 1.1)


func test_dodge_annuls_strike_damage() -> void:
	var pair := _make_pair(Vector3(0, 0.5, 0), Vector3(0, 0.5, 1.6))
	var player: ArpgPlayer = pair[0]
	var enemy: ShadowOfPortal = pair[1]
	var dodged_count := [0]
	player.dodged.connect(func() -> void: dodged_count[0] += 1)
	await _frames(10)
	assert_str(enemy.get_state_name()).is_equal("windup")
	# Esperar al cambio exacto a strike y esquivar ANTES del momento del golpe (0.1 s).
	for index: int in 120:
		await get_tree().physics_frame
		if enemy.get_state_name() == "strike":
			break
	assert_str(enemy.get_state_name()).is_equal("strike")
	# Esquivar hacia atras (input -Z): esquivar al frente cruza detras del enemigo
	# y el gate frontal anula el intento de golpe.
	player.joystick_vector = Vector2(0, -1)
	assert_bool(player.try_dodge()).is_true()
	player.joystick_vector = Vector2.ZERO
	var hp_before := player.hp
	await _frames(16)
	assert_float(player.hp).is_equal(hp_before)
	assert_int(dodged_count[0]).is_greater(0)


func test_take_damage_kills_and_emits() -> void:
	var pair := _make_pair(Vector3(0, 0.5, 0), Vector3(0, 0.5, 5))
	var enemy: ShadowOfPortal = pair[1]
	var died := {"id": "", "pos": Vector3.ZERO}
	enemy.enemy_died.connect(
		func(enemy_id: String, position: Vector3) -> void:
			died["id"] = enemy_id
			died["pos"] = position
	)
	assert_bool(enemy.take_damage(999.0)).is_true()
	assert_str(enemy.get_state_name()).is_equal("dead")
	assert_str(died["id"]).is_equal("sombra_de_portal")
	assert_float((died["pos"] as Vector3).length()).is_greater(0.0)
	# Muerto: no recibe mas dano.
	assert_bool(enemy.take_damage(10.0)).is_false()


func test_dead_enemy_stops_moving() -> void:
	var pair := _make_pair(Vector3(0, 0.5, 0), Vector3(0, 0.5, 8))
	var enemy: ShadowOfPortal = pair[1]
	await _frames(8)
	enemy.take_damage(999.0)
	await _frames(10)
	assert_str(enemy.get_state_name()).is_equal("dead")
	assert_float(enemy.velocity.length()).is_less(0.01)

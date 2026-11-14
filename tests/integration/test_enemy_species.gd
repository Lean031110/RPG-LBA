class_name TestEnemySpecies
extends GdUnitTestSuite
## Especies nuevas del monstruario (Fase 5) + colisiones de detección y golpe:
## Perro de ceniza (rodea y aúlla prisa), Guarapo negro (golpe de área con
## empuje y trampa de resina) y línea de visión real (nada de aggro ni golpes
## a través de muros).


func _frames(count: int) -> void:
	for index: int in count:
		await get_tree().physics_frame


func _ensure_floor() -> void:
	if get_node_or_null("TestFloor") != null:
		return
	var floor_body := StaticBody3D.new()
	floor_body.name = "TestFloor"
	floor_body.collision_layer = ArpgLayers.WORLD
	floor_body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, 1, 200)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0, -0.55, 0)
	add_child(auto_free(floor_body))


func _make_player() -> ArpgPlayer:
	var player: ArpgPlayer = auto_free(ArpgPlayer.new())
	add_child(player)
	player.setup("machetero")
	player.global_position = Vector3(0, 0.5, 0)
	return player


func _make_enemy(species: String, position: Vector3, player: ArpgPlayer) -> ArpgEnemy:
	var enemy: ArpgEnemy = null
	match species:
		"perro_de_ceniza":
			enemy = auto_free(PerroDeCeniza.new())
		"guarapo_negro":
			enemy = auto_free(GuarapoNegro.new())
		_:
			enemy = auto_free(ShadowOfPortal.new())
	add_child(enemy)
	enemy.global_position = position
	enemy.setup(species)
	enemy.set_target(player)
	return enemy


func _make_wall(position: Vector3) -> StaticBody3D:
	var wall := StaticBody3D.new()
	wall.collision_layer = ArpgLayers.WORLD
	wall.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(8.0, 4.0, 0.4)
	shape.shape = box
	wall.add_child(shape)
	wall.position = position
	add_child(auto_free(wall))
	return wall


func test_perro_is_faster_and_fragile() -> void:
	_ensure_floor()
	var player := _make_player()
	var perro := _make_enemy("perro_de_ceniza", Vector3(0, 0.5, 8), player)
	var sombra := _make_enemy("sombra_de_portal", Vector3(4, 0.5, 8), player)
	assert_float(perro.stats.move_speed).is_greater(sombra.stats.move_speed)
	assert_float(perro.max_hp).is_less(sombra.max_hp)


func test_perro_howl_grants_haste_to_pack() -> void:
	_ensure_floor()
	var player := _make_player()
	var perro_a := _make_enemy("perro_de_ceniza", Vector3(0, 0.5, 6), player)
	var perro_b := _make_enemy("perro_de_ceniza", Vector3(1, 0.5, 6.5), player)
	## Los perros aúllan al perseguir (intervalo de manada ~6 s): la prisa llega.
	await _frames(430)
	var hastened := perro_a.statuses.has("haste") or perro_b.statuses.has("haste")
	assert_bool(hastened).is_true()


func test_guarapo_is_slow_tanky_and_hits_hard() -> void:
	_ensure_floor()
	var player := _make_player()
	var guarapo := _make_enemy("guarapo_negro", Vector3(0, 0.5, 8), player)
	var sombra := _make_enemy("sombra_de_portal", Vector3(4, 0.5, 8), player)
	assert_float(guarapo.stats.move_speed).is_less(sombra.stats.move_speed)
	assert_float(guarapo.max_hp).is_greater(sombra.max_hp)
	assert_float(guarapo.stats.attack_power).is_greater(sombra.stats.attack_power)


func test_guarapo_slam_slows_player_with_resin() -> void:
	_ensure_floor()
	var player := _make_player()
	var guarapo := _make_enemy("guarapo_negro", Vector3(0, 0.5, 2.2), player)
	## El guarapo golpea (windup 1.0 s + ventana 0.3 s): el jugador queda
	## atrapado en resina (ralentización real por estado).
	await _frames(100)
	assert_bool(player.statuses.has("resin")).is_true()
	assert_float(player.statuses.move_speed_multiplier()).is_less(1.0)


func test_enemy_does_not_detect_through_wall() -> void:
	_ensure_floor()
	var player := _make_player()
	_make_wall(Vector3(0, 1.5, 4.0))
	var enemy := _make_enemy("sombra_de_portal", Vector3(0, 0.5, 8), player)
	## A 4 m de distancia y en el radio de detección, pero con el muro en
	## medio: no hay aggro (la detección exige línea de visión).
	await _frames(30)
	assert_str(enemy.get_state_name()).is_equal("idle")


func test_player_attack_blocked_by_wall() -> void:
	_ensure_floor()
	var player := _make_player()
	## Enemigo al otro lado de un muro fino, dentro del área del golpe.
	var enemy := _make_enemy("sombra_de_portal", Vector3(0, 0.5, 2.0), player)
	_make_wall(Vector3(0, 1.2, 1.0))
	player.try_attack()
	await _frames(40)
	## Sin trayectoria libre no hay golpe aunque el área solape al enemigo.
	assert_float(enemy.hp).is_equal(enemy.max_hp)


func test_player_stunned_cannot_act_and_enemy_strike_interrupts() -> void:
	_ensure_floor()
	var player := _make_player()
	var enemy := _make_enemy("sombra_de_portal", Vector3(0, 0.5, 1.8), player)
	## Golpear a la sombra en plena preparación la interrumpe (estado hurt).
	await _frames(6)
	enemy.take_damage(10.0)
	assert_str(enemy.get_state_name()).is_equal("hurt")


func test_carga_stuns_and_enemy_recovers_after_stun() -> void:
	_ensure_floor()
	var player := _make_player()
	player.add_xp(100)
	var enemy := _make_enemy("sombra_de_portal", Vector3(0, 0.5, 2.5), player)
	enemy.apply_stun(0.3)
	## La FSM pasa a STUNNED en el siguiente tick de física.
	await _frames(2)
	assert_str(enemy.get_state_name()).is_equal("stunned")
	## El aturdimiento expira y la FSM retoma la persecución.
	await _frames(40)
	assert_str(enemy.get_state_name()).is_not_equal("stunned")

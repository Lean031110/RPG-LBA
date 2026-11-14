class_name TestMacheteroKit
extends GdUnitTestSuite
## Kit completo del Machetero (Fase 5): combo de 3 tajos con buffer, ataque
## pesado, las 4 habilidades del canon con desbloqueo/coste/recarga, definitiva
## con carga real, bloqueo/parada (Pulso de monte), regeneración de vigor y
## guardado del kit. Todo por el camino real (try_* del jugador).


class DummyEnemy:
	extends CharacterBody3D
	var enemy_data := {"armor": 2.0, "resistance": 1.0}
	var hp := 200.0
	var hits := 0
	var last_context := {}

	func _init() -> void:
		collision_layer = ArpgLayers.ENEMY
		collision_mask = ArpgLayers.WORLD
		var shape := CollisionShape3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.4
		capsule.height = 1.8
		shape.shape = capsule
		add_child(shape)

	func take_damage(amount: float, context: Dictionary = {}) -> bool:
		hp -= amount
		hits += 1
		last_context = context
		return true


func _frames(count: int) -> void:
	for index: int in count:
		await get_tree().physics_frame


func _ensure_floor() -> void:
	## Suelo de prueba: sin él la gravedad tira al jugador y rompe los
	## solapamientos sostenidos (el Huracán necesita contacto continuo).
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


func _make_dummy(position: Vector3) -> DummyEnemy:
	var dummy: DummyEnemy = auto_free(DummyEnemy.new())
	add_child(dummy)
	dummy.global_position = position
	return dummy


func test_combo_chains_three_steps() -> void:
	_ensure_floor()
	var player := _make_player()
	var steps: Array = []
	player.combo_step_changed.connect(func(step: int) -> void: steps.append(step))
	player.try_attack()
	# Pulsar durante la acción encola el siguiente paso (buffer).
	await _frames(20)
	player.try_attack()
	await _frames(34)
	player.try_attack()
	await _frames(45)
	## Tres pasos del combo con índices consecutivos (1, 2, 0).
	assert_int(steps.size()).is_equal(3)
	assert_int(int(steps[0])).is_equal(1)
	assert_int(int(steps[1])).is_equal(2)
	assert_int(int(steps[2])).is_equal(0)


func test_combo_resets_after_pause() -> void:
	var player := _make_player()
	player.try_attack()
	await _frames(30)
	# Sin pulsar más de 1.2 s, el combo caduta: el próximo ataque vuelve al paso 1.
	await _frames(80)
	var steps: Array = []
	player.combo_step_changed.connect(func(step: int) -> void: steps.append(step))
	player.try_attack()
	await _frames(10)
	assert_int(steps.size()).is_equal(1)
	assert_int(int(steps[0])).is_equal(1)


func test_heavy_attack_cooldown_and_knockback_context() -> void:
	var player := _make_player()
	var dummy := _make_dummy(Vector3(0, 0.5, 1.4))
	assert_bool(player.try_heavy_attack()).is_true()
	# En plena acción, el pesado no se repite.
	assert_bool(player.try_heavy_attack()).is_false()
	await _frames(70)
	assert_int(dummy.hits).is_equal(1)
	## El contexto del pesado lleva empuje (knockback 3.5 de datos).
	assert_float(float(dummy.last_context.get("knockback", 0.0))).is_equal(3.5)
	## Recarga del pesado (4.5 s): sigue bloqueado a los ~1.1 s.
	assert_bool(player.try_heavy_attack()).is_false()


func test_skill_unlock_by_level() -> void:
	var player := _make_player()
	## S1 (tajo_guasima) desbloqueada al nivel 1; S2 (guardia) al 2.
	assert_bool(player.is_skill_unlocked(0)).is_true()
	assert_bool(player.is_skill_unlocked(1)).is_false()
	player.add_xp(100)
	assert_int(player.level).is_equal(2)
	assert_bool(player.is_skill_unlocked(1)).is_true()
	assert_bool(player.is_skill_unlocked(3)).is_false()


func test_skill_costs_vigor_and_enters_cooldown() -> void:
	var player := _make_player()
	var vigor_before := player.vigor
	assert_bool(player.try_skill_index(0)).is_true()
	assert_float(player.vigor).is_equal(vigor_before - 20.0)
	## Recarga de 5 s activa: no se relanza.
	assert_bool(player.try_skill_index(0)).is_false()
	assert_float(player.get_skill_cooldown_left_at(0)).is_greater(4.0)


func test_skill_denied_without_vigor() -> void:
	var player := _make_player()
	player.vigor = 5.0
	assert_bool(player.try_skill_index(0)).is_false()


func test_tajo_guasima_applies_bleed() -> void:
	var player := _make_player()
	var dummy := _make_dummy(Vector3(0, 0.5, 1.6))
	assert_bool(player.try_skill_index(0)).is_true()
	await _frames(45)
	## El tajo conecta y deja sangrado (estado real con duración).
	assert_int(dummy.hits).is_equal(1)


func test_guardia_del_bohio_blocks_and_parries() -> void:
	var player := _make_player()
	## Nivel 2 para desbloquear la Guardia.
	player.add_xp(100)
	assert_bool(player.try_skill_index(1)).is_true()
	assert_bool(player.is_blocking()).is_true()
	## Con la guardia activa, el bloqueo es reforzado (0.65) y una parada
	## perfecta dentro de la ventana anula TODO el daño.
	var hp_before := player.hp
	var vigor_before := player.vigor
	player.take_damage(30.0, {"source": null})
	assert_float(player.hp).is_equal(hp_before)
	## La parada restaura vigor (Pulso de monte) y deja "empowered".
	assert_float(player.vigor).is_greater(vigor_before)
	assert_bool(player.statuses.has("empowered")).is_true()


func test_plain_block_reduces_damage() -> void:
	var player := _make_player()
	player.set_blocking(true)
	var hp_before := player.hp
	## Fuera de la ventana de parada (>0.2 s): bloqueo normal (reducción 0.45).
	await _frames(20)
	player.take_damage(30.0, {"source": null})
	## Pasa el 55%: 16.5 de 30.
	assert_float(player.hp).is_equal_approx(hp_before - 16.5, 0.5)


func test_carga_del_mambi_stuns_target() -> void:
	var player := _make_player()
	player.add_xp(100)
	## Dummy delante: la carga lo atraviesa y lo aturde (contexto stun 1.2 s).
	var dummy := _make_dummy(Vector3(0, 0.5, 3.0))
	assert_bool(player.try_skill_index(2)).is_true()
	await _frames(40)
	assert_int(dummy.hits).is_greater_equal(1)
	assert_float(float(dummy.last_context.get("stun_duration", 0.0))).is_equal(1.2)


func test_ultimate_requires_charge_and_spends_it() -> void:
	var player := _make_player()
	## La definitiva se desbloquea al nivel 3 (dato) y exige carga completa.
	player.add_xp(300)
	assert_int(player.level).is_equal(3)
	assert_bool(player.try_ultimate()).is_false()
	player.kit.gain_ultimate_charge(player.get_ultimate_max())
	assert_bool(player.is_ultimate_ready()).is_true()
	assert_bool(player.try_ultimate()).is_true()
	## La carga se gastó entera al lanzarla.
	assert_float(player.get_ultimate_charge()).is_equal(0.0)
	assert_bool(player.try_ultimate()).is_false()


func test_ultimate_charge_from_hits() -> void:
	var player := _make_player()
	var dummy := _make_dummy(Vector3(0, 0.5, 1.4))
	var charge_before := player.get_ultimate_charge()
	player.try_attack()
	await _frames(30)
	## Cada golpe conectado suma carga (8 por golpe de datos).
	assert_float(player.get_ultimate_charge()).is_greater(charge_before)
	assert_float(player.get_ultimate_charge() - charge_before).is_equal(8.0)


func test_ultimate_spin_multi_hits() -> void:
	_ensure_floor()
	var player := _make_player()
	player.add_xp(300)
	var dummy := _make_dummy(Vector3(0, 0.5, 1.2))
	player.kit.gain_ultimate_charge(player.get_ultimate_max())
	assert_bool(player.try_ultimate()).is_true()
	await _frames(140)
	## Huracán: 5 ticks + remate; el mismo enemigo recibe un golpe por tick.
	assert_int(dummy.hits).is_equal(5)


func test_vigor_regenerates_over_time() -> void:
	_ensure_floor()
	var player := _make_player()
	player.vigor = 50.0
	await _frames(60)
	## Regeneración 5/s: tras ~1 s recupera ~5 de vigor.
	assert_float(player.vigor).is_greater(54.0)


func test_dodge_denied_while_stunned() -> void:
	var player := _make_player()
	player.apply_stun(1.0)
	assert_bool(player.try_dodge()).is_false()
	## Un aturdido tampoco ataca ni lanza habilidades.
	assert_bool(player.try_attack()).is_false()
	assert_bool(player.try_skill_index(0)).is_false()
	assert_bool(player.try_ultimate()).is_false()


func test_attribute_points_spend_and_boost() -> void:
	var player := _make_player()
	player.add_xp(100)
	## Nivel 2: +5 puntos (canon docs/diseno/02).
	assert_int(player.attribute_points).is_equal(5)
	var fuerza_before := player.get_attribute("fuerza")
	assert_bool(player.spend_attribute_point("fuerza", 3)).is_true()
	assert_float(player.get_attribute("fuerza")).is_equal(fuerza_before + 3.0)
	assert_int(player.attribute_points).is_equal(2)
	assert_bool(player.spend_attribute_point("atributo_inexistente")).is_false()


func test_kit_survives_save_roundtrip() -> void:
	var player := _make_player()
	player.add_xp(100)
	player.spend_attribute_point("fuerza", 2)
	player.kit.gain_ultimate_charge(60.0)
	var data := player.serialize()
	var restored: ArpgPlayer = auto_free(ArpgPlayer.new())
	add_child(restored)
	restored.setup("machetero")
	restored.restore(data)
	assert_int(restored.level).is_equal(2)
	assert_float(restored.get_attribute("fuerza")).is_equal(player.get_attribute("fuerza"))
	assert_float(restored.get_ultimate_charge()).is_equal(60.0)
	assert_int(restored.attribute_points).is_equal(3)

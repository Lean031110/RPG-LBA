class_name TestBrujaKit
extends GdUnitTestSuite
## Kit de la Bruja de la Manigua (Fase 2): dano real a distancia, coste de
## Esencia, recargas, estados de control (slow/root), pasivas, definitiva de
## zona y la regla de identidad SIN bloqueo. Dummies con estados reales.


class BrujaDummy:
	extends CharacterBody3D
	var enemy_data := {"armor": 2.0, "resistance": 1.0, "attribute_value": 10.0}
	var is_boss := false
	var hp := 60.0
	var hits := 0
	var statuses := StatusEffectController.new()

	func _init() -> void:
		collision_layer = ArpgLayers.ENEMY
		collision_mask = ArpgLayers.WORLD
		var shape := CollisionShape3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.4
		capsule.height = 1.8
		shape.shape = capsule
		add_child(shape)

	func take_damage(amount: float, _context: Dictionary = {}) -> bool:
		hp -= amount
		hits += 1
		return true

	func apply_status(id: String, duration: float, params: Dictionary = {}) -> void:
		statuses.apply(id, duration, params)

	func get_status_controller() -> StatusEffectController:
		return statuses

	func tick_statuses(delta: float) -> void:
		statuses.tick(delta)


func _frames(count: int) -> void:
	for index: int in count:
		await get_tree().physics_frame


func _wait(seconds: float) -> void:
	## Espera TIEMPO REAL de escena: el runner headless no garantiza 60
	## physics-frames por segundo, asi que las duraciones se esperan por
	## temporizador, no contando frames.
	await get_tree().create_timer(seconds).timeout


func _make_bruja() -> ArpgPlayer:
	var player: ArpgPlayer = auto_free(ArpgPlayer.new())
	add_child(player)
	player.setup("bruja")
	player.global_position = Vector3(0, 0.5, 0)
	return player


func _orientar_hacia(player: ArpgPlayer, objetivo: Vector3) -> void:
	## Convencion del proyecto: el FRENTE es +Z (player/orientacion/targeting).
	## look_at orienta -Z al objetivo, asi que se gira 180 grados para que
	## +basis.z apunte al objetivo como espera el motor del juego.
	player.look_at(objetivo, Vector3.UP)
	player.rotate_y(PI)


func _make_dummy(position: Vector3) -> BrujaDummy:
	## El grupo "arpg_enemies" es como el TargetingSystem real descubre
	## objetivos (mismo contrato que los enemigos del juego).
	var dummy: BrujaDummy = auto_free(BrujaDummy.new())
	add_child(dummy)
	dummy.global_position = position
	dummy.add_to_group("arpg_enemies")
	return dummy


func test_bruja_stats_recurso_y_sin_bloqueo() -> void:
	var player := _make_bruja()
	assert_float(player.max_hp).is_equal(85.0)
	assert_float(player.max_vigor).is_equal(125.0)
	assert_str(player.get_resource_name()).is_equal("Esencia")
	assert_bool(player.kit.can_block()).is_false()
	assert_bool(player.kit.set_blocking(true)).is_false()
	assert_bool(player.kit.is_blocking()).is_false()


func test_basic_attack_is_a_real_ranged_projectile() -> void:
	var player := _make_bruja()
	var dummy := _make_dummy(Vector3(0, 0.5, -6.0))
	_orientar_hacia(player, Vector3(0, 0.5, -6.0))
	assert_bool(player.try_attack()).is_true()
	await _wait(1.2)
	assert_int(dummy.hits).is_greater_equal(1)
	assert_float(dummy.hp).is_less(60.0)


func test_basic_attack_cooldown_limits_fire_rate() -> void:
	var player := _make_bruja()
	_orientar_hacia(player, Vector3(0, 0.5, -6.0))
	assert_bool(player.try_attack()).is_true()
	await _wait(0.05)
	# En recarga (0.65 s): no dispara otra espina inmediatamente.
	assert_bool(player.try_attack()).is_false()


func test_espina_costs_esencia_and_starts_cooldown() -> void:
	var player := _make_bruja()
	var esencia_inicial := player.vigor
	assert_bool(player.kit.try_skill_index(0)).is_true()
	assert_float(player.vigor).is_equal(esencia_inicial - 15.0)
	assert_float(player.cooldowns.left("espina_de_jucaro")).is_greater(0.0)
	# Sin Esencia suficiente: bloqueada por recurso.
	player.vigor = 5.0
	await _wait(1.0)
	assert_bool(player.kit.try_skill_index(0)).is_false()


func test_niebla_applies_slow_to_enemies_inside() -> void:
	var player := _make_bruja()
	player.level = 5
	var dummy := _make_dummy(Vector3(0, 0.5, -5.0))
	_orientar_hacia(player, Vector3(0, 0.5, -5.0))
	assert_bool(player.kit.try_skill_index(1)).is_true()
	await _wait(1.5)
	assert_bool(dummy.statuses.has("slow")).is_true()
	assert_float(dummy.statuses.move_speed_multiplier()).is_equal_approx(0.6, 0.05)


func test_raices_root_blocks_movement_not_actions() -> void:
	var player := _make_bruja()
	player.level = 5
	var dummy := _make_dummy(Vector3(0, 0.5, -4.0))
	_orientar_hacia(player, Vector3(0, 0.5, -4.0))
	assert_bool(player.kit.try_skill_index(2)).is_true()
	await _wait(1.5)
	assert_bool(dummy.statuses.has("root")).is_true()
	assert_bool(dummy.statuses.can_move()).is_false()
	assert_bool(dummy.statuses.can_act()).is_true()
	assert_int(dummy.hits).is_greater_equal(1)


func test_raiz_persistente_extends_control_on_already_slowed_target() -> void:
	var player := _make_bruja()
	var dummy := _make_dummy(Vector3(0, 0.5, -4.0))
	# Objetivo YA afectado por naturaleza (slow activo).
	dummy.apply_status("slow", 3.0, {"slow_fraction": 0.4})
	var root_status := {"id": "root", "duration": 1.6, "params": {}}
	var boosted: Dictionary = player.kit.boosted_control_status(root_status, dummy)
	assert_float(float(boosted["duration"])).is_equal_approx(1.6 * 1.5, 0.001)
	# Sin control previo: duracion intacta (la pasiva no inflaba desde cero).
	var limpio := BrujaDummy.new()
	auto_free(limpio)
	add_child(limpio)
	var untouched: Dictionary = player.kit.boosted_control_status(root_status, limpio)
	assert_float(float(untouched["duration"])).is_equal(1.6)


func test_raiz_persistente_is_capped_against_bosses() -> void:
	var player := _make_bruja()
	var boss := BrujaDummy.new()
	auto_free(boss)
	add_child(boss)
	boss.is_boss = true
	# El jefe YA esta afectado por naturaleza (slow activo): la pasiva aplica,
	# pero con el multiplicador recortado propio de jefes (cap del canon).
	boss.apply_status("slow", 3.0, {"slow_fraction": 0.4})
	var root_status := {"id": "root", "duration": 1.6, "params": {}}
	var boosted: Dictionary = player.kit.boosted_control_status(root_status, boss)
	assert_float(float(boosted["duration"])).is_equal_approx(1.6 * 1.15, 0.001)


func test_mariposa_spawns_homing_familiar() -> void:
	var player := _make_bruja()
	player.level = 5
	var dummy := _make_dummy(Vector3(0, 0.5, -7.0))
	_orientar_hacia(player, dummy.global_position)
	await _wait(0.05)
	player.targeting.force_rescan()
	await _wait(0.05)
	assert_bool(player.targeting.has_target()).is_true()
	assert_bool(player.kit.try_skill_index(3)).is_true()
	await _wait(0.8)
	var proyectiles: Array[Node] = []
	for child: Node in player.get_parent().get_children():
		if child is ArpgProjectile:
			proyectiles.append(child)
	assert_int(proyectiles.size()).is_greater_equal(1)


func test_ultimate_needs_full_charge_then_damages_by_ticks() -> void:
	var player := _make_bruja()
	player.level = 5
	var dummy := _make_dummy(Vector3(2.0, 0.5, -2.0))
	# Sin carga: no se lanza.
	assert_bool(player.kit.try_ultimate()).is_false()
	player.kit.set_charge(100.0)
	assert_bool(player.kit.is_ultimate_ready()).is_true()
	assert_bool(player.kit.try_ultimate()).is_true()
	# El lanzamiento consume TODA la carga (verificado antes de que los ticks
	# de la propia tormenta vuelvan a generar carga por per_hit_dealt).
	assert_float(player.kit.get_ultimate_charge()).is_equal(0.0)
	await _wait(2.0)
	# La tormenta de zona danio al dummy en varios ticks (no de golpe) y lo
	# ralentiza; la carga vuelve a crecer por los golpes (motor comun).
	assert_int(dummy.hits).is_greater_equal(2)
	assert_float(dummy.hp).is_less(60.0)
	assert_bool(dummy.statuses.has("slow")).is_true()
	assert_float(player.kit.get_ultimate_charge()).is_greater(0.0)
	# Limpieza: la tormenta vive 6 s; se corta para no ensuciar tests siguientes.
	for child: Node in player.get_parent().get_children():
		if child is ArpgAreaEffect:
			child.queue_free()


func test_ultimate_charge_from_damage_taken() -> void:
	var player := _make_bruja()
	assert_float(player.kit.get_ultimate_charge()).is_equal(0.0)
	player.take_damage(10.0, {})
	assert_float(player.kit.get_ultimate_charge()).is_equal(5.0)


func test_oido_de_la_manigua_regen_multiplier_when_still() -> void:
	var player := _make_bruja()
	assert_bool(player.kit.is_still_listening()).is_false()
	assert_float(player.kit.resource_regen_multiplier()).is_equal(1.0)
	for _index: int in 120:
		player.kit.tick(1.0 / 60.0)
	assert_bool(player.kit.is_still_listening()).is_true()
	assert_float(player.kit.resource_regen_multiplier()).is_equal(2.0)


func test_dodge_costs_esencia_and_cancels_recovery() -> void:
	var player := _make_bruja()
	var esencia_inicial := player.vigor
	assert_bool(player.kit.try_dodge()).is_true()
	assert_float(player.vigor).is_equal(esencia_inicial - 15.0)
	assert_float(player.cooldowns.left("dodge")).is_greater(0.0)


func test_machetero_still_works_after_kit_refactor() -> void:
	## Regresion del refactor a ClassKit: el Machetero conserva su kit y su
	## marioneta reales.
	var player: ArpgPlayer = auto_free(ArpgPlayer.new())
	add_child(player)
	player.setup("machetero")
	assert_bool(player.kit is MacheteroKit).is_true()
	assert_bool(player.kit.can_block()).is_true()
	assert_float(player.max_vigor).is_equal(100.0)
	var bruja := _make_bruja()
	assert_bool(bruja.kit is BrujaKit).is_true()
	assert_bool(bruja.kit is MacheteroKit).is_false()

# gdlint: ignore=max-public-methods
class_name TestSepultureroKit
extends GdUnitTestSuite
## Kit del Sepulturero de Guanabacoa (Fase 2, tercera clase): invocaciones con
## presupuesto compartido, expiracion con onda, marca + pasiva de fragmentos,
## procesion, vela, definitiva y la regla de identidad SIN bloqueo. Maniquies
## con estados reales (canon del repo para pruebas de combate).


class Maniqui:
	extends CharacterBody3D
	## Enemigo de pruebas con el pipeline real: estados, stats y muerte. Capa
	## ENEMY (lo ven las consultas del eco y del jugador) y grupo arpg_enemies
	## (lo encuentra la busqueda en cono de la Marca).
	var enemy_data := {"armor": 2.0, "resistance": 1.0, "attribute_value": 10.0}
	var is_boss := false
	var hp := 60.0
	var max_hp := 60.0
	var hits := 0
	var last_context := {}
	var statuses := StatusEffectController.new()
	var _dead := false
	var _knockback := Vector3.ZERO

	func _init() -> void:
		collision_layer = ArpgLayers.ENEMY
		collision_mask = ArpgLayers.WORLD
		add_to_group("arpg_enemies")
		var shape := CollisionShape3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.4
		capsule.height = 1.8
		shape.shape = capsule
		add_child(shape)

	func take_damage(amount: float, context: Dictionary = {}) -> bool:
		if _dead or amount <= 0.0:
			return false
		hp -= amount
		hits += 1
		last_context = context
		var source := context.get("source") as Node3D
		if source != null:
			var dir := global_position - source.global_position
			dir.y = 0.0
			if dir.length() > 0.05:
				_knockback = dir.normalized() * float(context.get("knockback", 0.0))
		if hp <= 0.0:
			_dead = true
			statuses.clear()
		return true

	func apply_status(id: String, duration: float, params: Dictionary = {}) -> void:
		statuses.apply(id, duration, params)

	func get_status_controller() -> StatusEffectController:
		return statuses

	func get_combat_stats() -> CombatStats:
		var fallback := CombatStats.new()
		fallback.armor = 2.0
		fallback.resistance = 1.0
		fallback.primary_attribute = 10.0
		return fallback

	func is_dead() -> bool:
		return _dead

	func tick_statuses(delta: float) -> void:
		statuses.tick(delta)

	func _physics_process(delta: float) -> void:
		if not is_on_floor():
			velocity.y -= 18.0 * delta
		else:
			velocity.y = 0.0
		velocity += _knockback
		_knockback = Vector3.ZERO
		move_and_slide()


func make_maniqui(position: Vector3) -> CharacterBody3D:
	## Fabrica publica: la usan las pruebas y el script de captura artistica.
	var maniqui := Maniqui.new()
	maniqui.position = position
	return maniqui


func _dispose_test_entities(player: ArpgPlayer) -> void:
	## Limpieza INMEDIATA (free, no queue_free) al final del cuerpo de la
	## prueba: los ecos duran 14s por diseno y sobrevivirian al informe de
	## huerfanos de GdUnit. La disposicion directa evita falsos huerfanos.
	for echo: ArpgEcho in _kit(player).active_echoes():
		echo.free()
	for child: Node in player.get_parent().get_children():
		if (
			child is ArpgAreaEffect
			or (
				child != null
				and child.has_method("get_status_controller")
				and not child is ArpgPlayer
				and not child is ArpgEcho
			)
		):
			if child is ArpgAreaEffect or String(child.name).begins_with("Eco_"):
				child.free()


func after_test() -> void:
	## class_data viene de RpgDB COMPARTIDO: la mutacion de prueba (duracion
	## corta del guardian para el test de expiracion) se restaura SIEMPRE al
	## valor canonico del JSON para no envenenar las pruebas siguientes.
	for class_entry: Dictionary in RpgDB.get_classes():
		if String(class_entry.get("id", "")) == "sepulturero":
			var summons: Dictionary = class_entry.get("summons", {})
			if summons.has("guardian"):
				summons["guardian"]["duration"] = 14.0
	# Residuos de la prueba: ecos y zonas vivos fuera del arbol del jugador.
	# Sin esta purga, la busqueda en cono de la Marca puede encontrar un
	# maniqui de OTRA prueba (falso negativo) y quedan nodos huerfanos.
	for group_name: String in ["arpg_summons", "arpg_enemies"]:
		for body: Node in get_tree().get_nodes_in_group(group_name):
			if body != null and is_instance_valid(body):
				body.queue_free()


func _frames(count: int) -> void:
	for index: int in count:
		await get_tree().physics_frame


func _wait(seconds: float) -> void:
	## Espera en TIEMPO DE JUEGO (frames de fisica). El runner headless no
	## garantiza frames por segundo reales (canon del repo): las duraciones de
	## ventanas, ecos y zonas avanzan con el delta de fisica, asi que esperar
	## por frames es determinista; esperar por reloj real es flaky.
	var frames := int(ceil(seconds * 60.0)) + 6
	await _frames(frames)


func _make_sepulturero(level := 5) -> ArpgPlayer:
	var player: ArpgPlayer = auto_free(ArpgPlayer.new())
	add_child(player)
	player.setup("sepulturero")
	player.level = level
	player.global_position = Vector3(0, 0.5, 0)
	player.stats_changed.emit()
	return player


func _kit(player: ArpgPlayer) -> SepultureroKit:
	## La API propia del Sepulturero (ecos, marcas) no vive en ClassKit: el cast
	## tipado permite usarla desde las pruebas sin romper el tipado estricto.
	return player.kit as SepultureroKit


func _make_floor(size := 48.0) -> void:
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = ArpgLayers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size, 0.2, size)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0, -0.1, 0)
	add_child(auto_free(floor_body))


func _cast(skill_index: int, player: ArpgPlayer) -> void:
	## Lanza una habilidad y espera a que la accion complete (windup + ventana
	## + recuperacion) en tiempo de JUEGO, con guarda de seguridad.
	player.kit.try_skill_index(skill_index)
	var guard := 0
	while player.skills.is_busy() and guard < 600:
		await get_tree().physics_frame
		guard += 1
	await _frames(2)


# ---------------------------------------------------------------------------
# Carga, datos y localizacion
# ---------------------------------------------------------------------------


func test_class_loads_with_complete_data() -> void:
	var player := _make_sepulturero()
	assert_dict(player.class_data).is_not_empty()
	assert_int(player.class_data.get("skills", []).size()).is_equal(4)
	assert_bool(bool(player.class_data["basic_attack"].get("implemented", false))).is_true()
	assert_dict(player.class_data.get("passives", {})).is_not_empty()
	assert_int(int(player.class_data.get("summons", {}).get("max_active", 0))).is_equal(3)
	for skill: Dictionary in player.class_data.get("skills", []):
		assert_bool(bool(skill.get("implemented", false))).is_true()
	assert_str(RpgDB.get_text("class.sepulturero.name", "es")).is_not_equal("class.sepulturero.name")


func test_resource_economy_matches_design() -> void:
	var player := _make_sepulturero(1)
	assert_float(player.max_vigor).is_equal_approx(115.0, 0.01)
	assert_float(player.class_data["resource"].get("regen_per_second", 0.0)).is_equal(2.0)


func test_identity_has_no_block() -> void:
	var player := _make_sepulturero()
	assert_bool(player.kit.can_block()).is_false()
	assert_str(String(player.class_data.get("id", ""))).is_equal("sepulturero")


# ---------------------------------------------------------------------------
# Ataque basico (Barrido de Farol): melee arcano corto con ventana + hitbox
# ---------------------------------------------------------------------------


func test_basic_attack_deals_real_damage_with_window() -> void:
	_make_floor()
	var player := _make_sepulturero()
	var maniqui := make_maniqui(Vector3(0, 0.5, 1.6))
	add_child(auto_free(maniqui))
	await _frames(4)
	var hp_before: float = maniqui.hp
	player.kit.try_attack()
	await _wait(0.8)
	assert_int(maniqui.hits).is_greater(0)
	assert_float(maniqui.hp).is_less(hp_before)


func test_basic_attack_costs_no_ceniza() -> void:
	var player := _make_sepulturero()
	var vigor_before := player.vigor
	player.kit.try_attack()
	assert_float(player.vigor).is_equal(vigor_before)


# ---------------------------------------------------------------------------
# Invocaciones: presupuesto compartido, duracion, onda y muerte
# ---------------------------------------------------------------------------


func test_llamada_del_osario_spawns_guardian() -> void:
	_make_floor()
	var player := _make_sepulturero()
	await _frames(2)
	await _cast(0, player)
	assert_int(_kit(player).active_echo_count()).is_equal(1)
	var echoes: Array[ArpgEcho] = _kit(player).active_echoes()
	assert_str(echoes[0].get_echo_kind()).is_equal("guardian")
	assert_bool(echoes[0].is_in_group("arpg_summons")).is_true()
	assert_float(echoes[0].remaining_time()).is_greater(10.0)


func test_summon_cap_is_shared_budget() -> void:
	_make_floor()
	var player := _make_sepulturero()
	await _frames(2)
	await _cast(0, player)
	player.cooldowns.clear()
	await _cast(0, player)
	player.cooldowns.clear()
	await _cast(0, player)
	assert_int(_kit(player).active_echo_count()).is_equal(3)
	player.cooldowns.clear()
	assert_bool(player.kit.try_skill_index(0)).is_false()
	assert_int(_kit(player).active_echo_count()).is_equal(3)


func test_summon_spends_ceniza_and_starts_cooldown() -> void:
	_make_floor()
	var player := _make_sepulturero()
	await _frames(2)
	var vigor_before := player.vigor
	await _cast(0, player)
	assert_float(player.vigor).is_less(vigor_before)
	assert_float(player.cooldowns.left("llamada_del_osario")).is_greater(0.0)


func test_expiry_leaves_wave_zone_with_slow() -> void:
	_make_floor()
	var player := _make_sepulturero()
	# Duracion corta SOLO para la prueba (el reloj del eco es el mismo motor).
	player.class_data["summons"]["guardian"]["duration"] = 1.0
	await _frames(2)
	var maniqui := make_maniqui(Vector3(0, 0.5, 2.2))
	add_child(auto_free(maniqui))
	await _cast(0, player)
	assert_int(_kit(player).active_echo_count()).is_equal(1)
	await _wait(1.6)
	assert_int(_kit(player).active_echo_count()).is_equal(0)
	assert_bool(maniqui.statuses.has("slow")).is_true()
	assert_int(maniqui.hits).is_greater(0)
	await _wait(0.6)
	assert_bool(is_instance_valid(maniqui)).is_true()
	_dispose_test_entities(player)


func test_combat_death_has_no_wave() -> void:
	_make_floor()
	var player := _make_sepulturero()
	await _frames(2)
	await _cast(0, player)
	var echoes: Array[ArpgEcho] = _kit(player).active_echoes()
	assert_int(echoes.size()).is_equal(1)
	echoes[0].take_damage(999.0, {})
	# La disolucion espectral dura ~0.5s (tween) antes de liberar el nodo:
	# esperar TIEMPO REAL, no frames (canon del runner headless del repo).
	await _wait(1.0)
	assert_int(_kit(player).active_echo_count()).is_equal(0)
	assert_bool(maniqui_has_wave(player)).is_false()


func maniqui_has_wave(player: ArpgPlayer) -> bool:
	for child in player.get_parent().get_children():
		if child is ArpgAreaEffect and String(child.name).begins_with("ultimo_encargo"):
			return true
	return false


func test_echo_never_damages_owner_or_siblings() -> void:
	_make_floor()
	var player := _make_sepulturero()
	await _frames(2)
	var hp_player := player.hp
	await _cast(0, player)
	player.cooldowns.clear()
	await _cast(0, player)
	var maniqui := make_maniqui(Vector3(0, 0.5, 3.0))
	add_child(auto_free(maniqui))
	await _wait(2.5)
	assert_float(player.hp).is_equal(hp_player)
	for echo: ArpgEcho in _kit(player).active_echoes():
		assert_float(echo.hp).is_equal(echo.max_hp)


func test_echo_follows_owner_without_enemies() -> void:
	_make_floor()
	var player := _make_sepulturero()
	await _frames(2)
	await _cast(0, player)
	await _wait(1.2)
	var echoes: Array[ArpgEcho] = _kit(player).active_echoes()
	assert_int(echoes.size()).is_equal(1)
	var distance := player.global_position.distance_to(echoes[0].global_position)
	assert_float(distance).is_less(6.0)


# ---------------------------------------------------------------------------
# Procesion de Hueso y Bronce: carga en linea con dano y empuje
# ---------------------------------------------------------------------------


func test_procesion_charges_and_pushes() -> void:
	_make_floor()
	var player := _make_sepulturero()
	await _frames(2)
	await _cast(0, player)
	var maniqui := make_maniqui(Vector3(0, 0.5, 3.0))
	add_child(auto_free(maniqui))
	await _frames(4)
	var pos_before := maniqui.global_position
	player.vigor = player.max_vigor
	player.cooldowns.clear()
	await _cast(2, player)
	await _wait(1.2)
	assert_int(maniqui.hits).is_greater(0)
	assert_float(float(maniqui.last_context.get("knockback", 0.0))).is_greater(0.0)
	assert_bool(maniqui.global_position != pos_before).is_true()


func test_procesion_requires_active_echoes() -> void:
	_make_floor()
	var player := _make_sepulturero()
	await _frames(2)
	assert_int(_kit(player).active_echo_count()).is_equal(0)
	assert_bool(player.kit.try_skill_index(2)).is_false()


# ---------------------------------------------------------------------------
# Vela de los Ausentes: sacrificio de duracion, curacion y recurso
# ---------------------------------------------------------------------------


func test_vela_sacrifices_heals_and_restores() -> void:
	_make_floor()
	var player := _make_sepulturero()
	await _frames(2)
	await _cast(0, player)
	await _wait(0.2)
	var echoes: Array[ArpgEcho] = _kit(player).active_echoes()
	var eco_hp_before_time: float = echoes[0].remaining_time()
	player.hp = player.max_hp * 0.4
	player.vigor = 10.0
	var hp_before := player.hp
	player.cooldowns.clear()
	await _cast(3, player)
	await _wait(0.9)
	assert_float(player.hp).is_greater(hp_before)
	assert_float(player.vigor).is_greater(10.0)
	assert_float(echoes[0].remaining_time()).is_less(eco_hp_before_time)


func test_vela_requires_active_echoes() -> void:
	_make_floor()
	var player := _make_sepulturero()
	await _frames(2)
	assert_bool(player.kit.try_skill_index(3)).is_false()


# ---------------------------------------------------------------------------
# Marca + pasiva Nombre prestado
# ---------------------------------------------------------------------------


func test_mark_applies_vulnerable_in_cone() -> void:
	_make_floor()
	var player := _make_sepulturero()
	await _frames(2)
	var maniqui := make_maniqui(Vector3(0, 0.5, 3.0))
	add_child(auto_free(maniqui))
	await _cast(1, player)
	assert_bool(maniqui.statuses.has("vulnerable")).is_true()
	assert_float(float(maniqui.statuses.get_param("vulnerable", "multiplier", 1.0))).is_equal_approx(1.3, 0.01)


func test_marked_kill_grants_ceniza_fragments() -> void:
	_make_floor()
	var player := _make_sepulturero()
	await _frames(2)
	var maniqui := make_maniqui(Vector3(0, 0.5, 3.0))
	add_child(auto_free(maniqui))
	player.vigor = player.max_vigor - 30.0
	await _cast(1, player)
	# Linea base DESPUES del gasto del cast: la pasiva debe AUMENTAR desde aqui.
	var vigor_before := player.vigor
	assert_bool(_kit(player).has_marked_targets())
	maniqui.take_damage(999.0, {})
	CombatEvents.enemy_killed.emit(maniqui)
	assert_float(player.vigor).is_greater(vigor_before)
	assert_bool(_kit(player).has_marked_targets()).is_false()


func test_unmarked_kill_grants_nothing() -> void:
	_make_floor()
	var player := _make_sepulturero()
	await _frames(2)
	var maniqui := make_maniqui(Vector3(0, 0.5, 3.0))
	add_child(auto_free(maniqui))
	var vigor_before := player.vigor
	maniqui.take_damage(999.0, {})
	CombatEvents.enemy_killed.emit(maniqui)
	assert_float(player.vigor).is_equal(vigor_before)


# ---------------------------------------------------------------------------
# Definitiva: El Patio de los que Vuelven
# ---------------------------------------------------------------------------


func test_ultimate_fills_cap_with_patio_echoes() -> void:
	_make_floor()
	var player := _make_sepulturero()
	await _frames(2)
	await _cast(0, player)
	player.kit.set_charge(100.0)
	player.cooldowns.clear()
	player.kit.try_ultimate()
	await _wait(1.2)
	assert_int(_kit(player).active_echo_count()).is_equal(3)
	var kinds := 0
	for echo: ArpgEcho in _kit(player).active_echoes():
		if echo.get_echo_kind() == "patio":
			kinds += 1
	assert_int(kinds).is_equal(2)


func test_ultimate_needs_free_slot_and_charge() -> void:
	_make_floor()
	var player := _make_sepulturero()
	await _frames(2)
	assert_bool(player.kit.try_ultimate()).is_false()
	player.kit.set_charge(100.0)
	player.cooldowns.clear()
	await _cast(0, player)
	player.cooldowns.clear()
	await _cast(0, player)
	player.cooldowns.clear()
	await _cast(0, player)
	player.kit.set_charge(100.0)
	assert_bool(player.kit.try_ultimate()).is_false()


# ---------------------------------------------------------------------------
# Desbloqueos por nivel (regla comun del motor)
# ---------------------------------------------------------------------------


func test_unlocks_follow_levels() -> void:
	var player := _make_sepulturero(1)
	assert_bool(player.is_skill_def_unlocked(player.class_data["skills"][0])).is_true()
	assert_bool(player.is_skill_def_unlocked(player.class_data["skills"][1])).is_false()
	var veteran := _make_sepulturero(5)
	for skill: Dictionary in veteran.class_data.get("skills", []):
		assert_bool(veteran.is_skill_def_unlocked(skill)).is_true()


# ---------------------------------------------------------------------------
# Muerte del jugador y limpieza (sin restos, sin fugas)
# ---------------------------------------------------------------------------


func test_player_death_dissolves_echoes_silently() -> void:
	_make_floor()
	var player := _make_sepulturero()
	await _frames(2)
	await _cast(0, player)
	assert_int(_kit(player).active_echo_count()).is_equal(1)
	player.take_damage(99999.0, {})
	await _frames(10)
	assert_int(_kit(player).active_echo_count()).is_equal(0)
	assert_bool(maniqui_has_wave(player)).is_false()


func test_freed_echo_prunes_from_kit() -> void:
	_make_floor()
	var player := _make_sepulturero()
	await _frames(2)
	await _cast(0, player)
	var echoes: Array[ArpgEcho] = _kit(player).active_echoes()
	echoes[0].queue_free()
	await _frames(6)
	player.kit.tick(0.016)
	assert_int(_kit(player).active_echo_count()).is_equal(0)
	assert_bool(player.kit.try_skill_index(2)).is_false()


# ---------------------------------------------------------------------------
# Contencion de amenazas del enemigo (motor comun, bandera engage_summons)
# ---------------------------------------------------------------------------


func test_enemy_switches_to_closer_summon_then_returns_home() -> void:
	_make_floor(64.0)
	var player := _make_sepulturero()
	player.global_position = Vector3(0, 0.5, 10.0)
	await _frames(2)
	var enemy := ShadowOfPortal.new()
	add_child(enemy)
	enemy.global_position = Vector3(0, 0.5, 0.0)
	enemy.setup("sombra_de_portal")
	enemy.set_target(player)
	# Un guardián MAS CERCA del enemigo que el jugador: la bandera le roba la atencion.
	player.global_position = Vector3(0, 0.5, 10.0)
	await _frames(2)
	await _cast(0, player)
	await _wait(1.4)
	assert_int(_kit(player).active_echo_count()).is_greater(0)
	var echo: ArpgEcho = _kit(player).active_echoes()[0]
	# El eco nace delante del jugador (a ~1.6m); lo acercamos al enemigo a mano.
	echo.global_position = Vector3(0, 0.5, 2.0)
	await _wait(1.2)
	assert_bool(enemy._target == echo).is_true()
	# Al desvanecer el eco, el enemigo vuelve al hogar (el jugador).
	echo.expire_silently()
	await _wait(1.2)
	assert_bool(enemy._target == player).is_true()


func test_boss_flag_survives_mark_and_wave() -> void:
	_make_floor()
	var player := _make_sepulturero()
	await _frames(2)
	var maniqui := make_maniqui(Vector3(0, 0.5, 3.0))
	maniqui.is_boss = true
	add_child(auto_free(maniqui))
	player.class_data["summons"]["guardian"]["duration"] = 1.0
	await _cast(1, player)
	assert_bool(maniqui.statuses.has("vulnerable")).is_true()
	await _cast(0, player)
	await _wait(2.0)
	assert_int(maniqui.hits).is_greater(0)
	assert_bool(is_instance_valid(maniqui)).is_true()

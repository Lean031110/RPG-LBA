class_name TestAttackWindow
extends GdUnitTestSuite
## Ataque básico con hitbox REAL activa solo en su ventana (prompt 01).
## El dummy enemigo registra cada take_damage; el daño sale de CombatService.


class DummyEnemy:
	extends CharacterBody3D
	var enemy_data := {"armor": 2.0, "resistance": 1.0}
	var hp := 45.0
	var hits := 0

	func _init() -> void:
		collision_layer = ArpgLayers.ENEMY
		collision_mask = ArpgLayers.WORLD
		var shape := CollisionShape3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.4
		capsule.height = 1.8
		shape.shape = capsule
		add_child(shape)

	func take_damage(amount: float) -> bool:
		hp -= amount
		hits += 1
		return true


func _frames(count: int) -> void:
	for index: int in count:
		await get_tree().physics_frame


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


func test_hitbox_disabled_outside_window() -> void:
	var player := _make_player()
	# Sin accion: la forma de la hitbox esta deshabilitada.
	assert_bool(player._hitbox_shape.disabled).is_true()
	var dummy := _make_dummy(Vector3(0, 0.5, 1.4))
	player.try_attack()
	# Durante el windup (0.12 s ~ 7 frames) todavia no hay golpe.
	await _frames(5)
	assert_int(dummy.hits).is_equal(0)
	assert_bool(player._hitbox_shape.disabled).is_true()


func test_damage_lands_inside_window_once() -> void:
	var player := _make_player()
	var dummy := _make_dummy(Vector3(0, 0.5, 1.4))
	player.try_attack()
	# Ventana: 0.12–0.30 s (frames 8..18). A 12 frames estamos dentro.
	await _frames(12)
	assert_int(dummy.hits).is_equal(1)
	# Sigue dentro de la ventana: no hay doble golpe (set por swing).
	await _frames(4)
	assert_int(dummy.hits).is_equal(1)


func test_damage_uses_combat_service_values() -> void:
	var player := _make_player()
	var dummy := _make_dummy(Vector3(0, 0.5, 1.4))
	var expected := CombatService.damage_from_data(
		player.class_data["basic_attack"], player.get_attribute("fuerza"), 2.0
	)
	player.try_attack()
	await _frames(40)
	assert_int(dummy.hits).is_equal(1)
	# Sin critico (5%) el dano es exacto; con critico es 1.5x. Rango determinista:
	assert_float(dummy.hp).is_less_equal(45.0 - expected + 0.001)
	assert_float(dummy.hp).is_greater_equal(45.0 - expected * 1.5 - 0.001)


func test_behind_player_is_not_hit() -> void:
	var player := _make_player()
	# El dummy detras: la hitbox frontal no lo alcanza.
	var dummy := _make_dummy(Vector3(0, 0.5, -1.4))
	player.try_attack()
	await _frames(40)
	assert_int(dummy.hits).is_equal(0)


func test_far_enemy_is_not_hit() -> void:
	var player := _make_player()
	var dummy := _make_dummy(Vector3(0, 0.5, 4.5))
	player.try_attack()
	await _frames(40)
	assert_int(dummy.hits).is_equal(0)


func test_attack_cooldown() -> void:
	var player := _make_player()
	player.try_attack()
	await _frames(40)
	# 0.55 s de accion termino; cooldown 0.9 s activo.
	assert_bool(player.try_attack()).is_false()
	await _frames(60)
	assert_bool(player.try_attack()).is_true()


func test_skill_costs_vigor_and_cooldowns() -> void:
	var player := _make_player()
	var vigor_before := player.vigor
	assert_bool(player.try_skill()).is_true()
	assert_float(player.vigor).is_less(vigor_before)
	await _frames(50)
	assert_bool(player.try_skill()).is_false()


func test_skill_denied_without_vigor() -> void:
	var player := _make_player()
	player.vigor = 5.0
	assert_bool(player.try_skill()).is_false()

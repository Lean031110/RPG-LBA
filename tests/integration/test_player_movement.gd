class_name TestPlayerMovement
extends GdUnitTestSuite
## Movimiento omnidireccional (prompt 01): teclado + joystick virtual, velocidad
## desde datos de clase, giro suave y esquiva con desplazamiento.
## Fase 2: el movimiento ahora acelera/frena (24/30 m/s²); los asertos de velocidad
## esperan fotogramas de asentamiento (~26) en vez de los 6 de la Fase 1.


func _make_player() -> ArpgPlayer:
	var player: ArpgPlayer = auto_free(ArpgPlayer.new())
	add_child(player)
	player.setup("machetero")
	player.global_position = Vector3(0, 0.5, 0)
	return player


func _frames(count: int) -> void:
	for index: int in count:
		await get_tree().physics_frame


func test_speed_comes_from_class_data() -> void:
	var player := _make_player()
	player.joystick_vector = Vector2(0, 1)
	await _frames(26)
	# machetero move_speed 4.2; el joystick max (0,1) mueve hacia +Z.
	# Se mide velocidad PLANAR: la caída libre no es parte del modelo de movimiento
	# (estas pruebas no colocan suelo, como en la Fase 1).
	var planar := Vector2(player.velocity.x, player.velocity.z).length()
	assert_float(planar).is_greater(3.8)
	assert_float(planar).is_less(4.6)
	assert_float(player.velocity.z).is_greater(0.0)


func test_keyboard_actions_move_player() -> void:
	var player := _make_player()
	Input.action_press("move_forward")
	await _frames(26)
	Input.action_release("move_forward")
	assert_float(absf(player.velocity.z)).is_greater(3.8)
	# move_forward = -Z (arriba en pantalla); el jugador se acerca a la camara.
	assert_float(player.velocity.z).is_less(0.0)


func test_diagonal_is_normalized() -> void:
	var player := _make_player()
	player.joystick_vector = Vector2(1, 1)
	await _frames(26)
	var planar := Vector2(player.velocity.x, player.velocity.z).length()
	assert_float(planar).is_greater(3.8)
	assert_float(planar).is_less(4.6)


func test_facing_follows_direction() -> void:
	var player := _make_player()
	player.joystick_vector = Vector2(0, 1)
	await _frames(12)
	# +Z al frente: la convencion de la rebanada usa +basis.z como frontal.
	var forward := player.transform.basis.z
	assert_float(forward.z).is_greater(0.7)


func test_dodge_moves_and_expires() -> void:
	var player := _make_player()
	assert_bool(player.try_dodge()).is_true()
	assert_bool(player.is_dodging).is_true()
	var vigor_after_start := player.vigor
	assert_float(vigor_after_start).is_less(100.0)
	await _frames(30)
	# 0.35 s a 60 fps = 21 frames; a 30 ya termino.
	assert_bool(player.is_dodging).is_false()


func test_dodge_cooldown_blocks_spam() -> void:
	var player := _make_player()
	assert_bool(player.try_dodge()).is_true()
	await _frames(30)
	assert_bool(player.try_dodge()).is_false()
	await _frames(80)
	assert_bool(player.try_dodge()).is_true()


func test_dodge_requires_vigor() -> void:
	var player := _make_player()
	player.vigor = 5.0
	assert_bool(player.try_dodge()).is_false()


func test_potion_heals_and_consumes() -> void:
	var player := _make_player()
	player.take_damage(60.0)
	var potions_before := player.potions
	var hp_before := player.hp
	assert_bool(player.try_potion()).is_true()
	assert_int(player.potions).is_equal(potions_before - 1)
	assert_float(player.hp - hp_before).is_equal_approx(40.0, 0.001)


func test_potion_blocked_at_full_health() -> void:
	var player := _make_player()
	assert_bool(player.try_potion()).is_false()


func test_take_damage_respects_grace() -> void:
	var player := _make_player()
	assert_bool(player.take_damage(10.0)).is_true()
	assert_bool(player.take_damage(10.0)).is_false()
	await _frames(20)
	assert_bool(player.take_damage(10.0)).is_true()

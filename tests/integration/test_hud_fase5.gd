class_name TestHudFase5
extends GdUnitTestSuite
## HUD de la Fase 5: barra de habilidades con recargas y candados, definitiva
## con carga, marco de objetivo, números de daño, chips de estados, bloqueo
## mantenido y teclado completo. Todo conectado a datos reales del jugador.


func _make_hud() -> ArpgHUD:
	var hud: ArpgHUD = auto_free(load("res://scenes/arpg/ui/arpg_hud.tscn").instantiate())
	add_child(hud)
	return hud


func _make_player() -> ArpgPlayer:
	var player: ArpgPlayer = auto_free(ArpgPlayer.new())
	add_child(player)
	player.setup("machetero")
	player.global_position = Vector3(0, 0.5, 0)
	return player


func test_skill_bar_builds_all_slots() -> void:
	var hud := _make_hud()
	var player := _make_player()
	hud.bind_player(player)
	## Cuatro huecos de habilidad + definitiva + pesado + bloqueo.
	assert_int(hud._skill_buttons.size()).is_equal(4)
	assert_int(hud._skill_overlays.size()).is_equal(4)
	assert_object(hud._ultimate_button).is_not_null()
	assert_object(hud._heavy_button).is_not_null()
	assert_object(hud._block_button).is_not_null()


func test_locked_skill_is_disabled_until_level() -> void:
	var hud := _make_hud()
	var player := _make_player()
	hud.bind_player(player)
	## Nivel 1: S1 activa, S2 (Guardia, nivel 2) bloqueada con candado real.
	assert_bool(hud._skill_buttons[0].disabled).is_false()
	assert_bool(hud._skill_buttons[1].disabled).is_true()
	player.add_xp(100)
	assert_int(player.level).is_equal(2)
	hud._refresh_skill_availability()
	assert_bool(hud._skill_buttons[1].disabled).is_false()


func test_ultimate_button_tracks_charge() -> void:
	var hud := _make_hud()
	var player := _make_player()
	player.add_xp(300)
	hud.bind_player(player)
	## Sin carga: atenuada y sin acción.
	assert_bool(player.try_ultimate()).is_false()
	player.kit.gain_ultimate_charge(player.get_ultimate_max())
	## La carga llena el relleno y el botón brilla al estar lista.
	hud._on_ultimate_charge_changed(player.get_ultimate_charge(), player.get_ultimate_max())
	assert_float(hud._ultimate_overlay.progress).is_equal_approx(0.0, 0.02)
	assert_bool(player.is_ultimate_ready()).is_true()


func test_block_button_holds() -> void:
	var hud := _make_hud()
	var player := _make_player()
	hud.bind_player(player)
	## El bloqueo se mantiene entre pulsación y liberación (hold real).
	hud._on_block_down()
	assert_bool(player.is_blocking()).is_true()
	hud._on_block_up()
	assert_bool(player.is_blocking()).is_false()


func test_status_chips_show_player_states() -> void:
	var hud := _make_hud()
	var player := _make_player()
	hud.bind_player(player)
	assert_int(hud._status_row.get_child_count()).is_equal(0)
	player.apply_status("bleed", 4.0, {"damage_per_tick": 2.0, "interval": 1.0})
	assert_int(hud._status_row.get_child_count()).is_equal(1)
	var chip := hud._status_row.get_child(0) as PanelContainer
	var label := chip.get_child(0) as Label
	assert_str(label.text).is_equal("Sangrado")


func test_damage_number_spawns_on_event() -> void:
	var hud := _make_hud()
	var player := _make_player()
	hud.bind_player(player)
	## Un golpe real genera número de daño visible en pantalla.
	var camera := Camera3D.new()
	add_child(auto_free(camera))
	camera.global_position = Vector3(0, 6, -8)
	camera.look_at(Vector3(0, 1, 0))
	player.global_position = Vector3(0, 0.5, 0)
	CombatEvents.damage_dealt.emit(player, 25.0, false, Vector3(0, 1.5, 0))
	assert_int(hud._combat_feedback._damage_pool.size()).is_equal(1)
	assert_bool(hud._combat_feedback._damage_pool[0].visible).is_true()
	assert_str(hud._combat_feedback._damage_pool[0].text).is_equal("25")


func test_target_frame_binds_to_focused_enemy() -> void:
	var hud := _make_hud()
	var player := _make_player()
	hud.bind_player(player)
	## Golpear a un enemigo lo enfoca; el marco muestra nombre y nivel reales.
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = ArpgLayers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0, -0.55, 0)
	add_child(auto_free(floor_body))
	var enemy: ShadowOfPortal = auto_free(ShadowOfPortal.new())
	add_child(enemy)
	enemy.global_position = Vector3(0, 0.5, 2.0)
	enemy.setup("sombra_de_portal")
	player.targeting.notify_hit(enemy)
	assert_bool(hud._combat_feedback._target_frame.visible).is_true()
	assert_str(hud._combat_feedback._target_name.text).is_equal("Sombra de Portal")
	assert_str(hud._combat_feedback._target_level.text).is_equal("Nv 2")
	## La vida del marco baja con el daño real del enemigo.
	enemy.take_damage(22.5)
	assert_float(hud._combat_feedback._target_hp.value).is_equal_approx(50.0, 1.0)


func test_keyboard_actions_reach_player() -> void:
	var hud := _make_hud()
	var player := _make_player()
	hud.bind_player(player)
	var vigor_before := player.vigor
	## La acción de teclado de la habilidad 1 dispara el lanzamiento real.
	var event := InputEventAction.new()
	event.action = "arpg_skill"
	event.pressed = true
	hud._unhandled_input(event)
	assert_float(player.vigor).is_equal(vigor_before - 20.0)

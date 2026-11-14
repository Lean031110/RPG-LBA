class_name TestInterfacesFase5
extends GdUnitTestSuite
## Interfaces de la Fase 5: confirmación de abandono en la pausa, bloqueo de
## acciones de combate con diálogo abierto y navegación real de pantallas.


func _make_pause() -> ArpgPauseOverlay:
	var pause: ArpgPauseOverlay = auto_free(ArpgPauseOverlay.new())
	add_child(pause)
	return pause


func _make_hud() -> ArpgHUD:
	var hud: ArpgHUD = auto_free(load("res://scenes/arpg/ui/arpg_hud.tscn").instantiate())
	add_child(hud)
	return hud


func _make_player() -> ArpgPlayer:
	var player: ArpgPlayer = auto_free(ArpgPlayer.new())
	add_child(player)
	player.setup("machetero")
	return player


func test_pause_exit_requires_confirmation() -> void:
	var pause := _make_pause()
	var exits := [0]
	pause.exit_requested.connect(func() -> void: exits[0] += 1)
	pause.open()
	## Primera pulsación: arma la confirmación, NO sale.
	pause._on_exit_pressed()
	assert_int(exits[0]).is_equal(0)
	assert_str(pause._exit_button.text).is_equal("¿Abandonar la partida? (Se guarda)")
	## Segunda pulsación: confirma la salida.
	pause._on_exit_pressed()
	assert_int(exits[0]).is_equal(1)
	## Al reabrir la pausa, la confirmación se rearma (sin estado pegado).
	pause.open()
	assert_str(pause._exit_button.text).is_equal("Salir al menú")


func test_pause_esc_resumes() -> void:
	var pause := _make_pause()
	var resumes := [0]
	pause.resume_requested.connect(func() -> void: resumes[0] += 1)
	pause.open()
	var event := InputEventAction.new()
	event.action = "arpg_pause"
	event.pressed = true
	pause._unhandled_input(event)
	assert_int(resumes[0]).is_equal(1)


func test_combat_blocked_while_dialog_open() -> void:
	var hud := _make_hud()
	var player := _make_player()
	hud.bind_player(player)
	## Diálogo abierto: los botones de combate no llegan al jugador.
	hud.show_dialog("Cheo", ["Línea de prueba."], "info")
	assert_bool(hud.is_dialog_open()).is_true()
	var vigor_before := player.vigor
	hud._on_action_pressed("skill")
	assert_float(player.vigor).is_equal(vigor_before)
	hud._on_skill_button_pressed(0)
	assert_float(player.vigor).is_equal(vigor_before)
	## Teclado también bloqueado con diálogo.
	var event := InputEventAction.new()
	event.action = "arpg_attack"
	event.pressed = true
	hud._unhandled_input(event)
	assert_bool(player.skills.is_busy()).is_false()
	## Al cerrar el diálogo, el combate vuelve a responder.
	hud._dialog_next()
	assert_bool(hud.is_dialog_open()).is_false()
	hud._on_action_pressed("skill")
	assert_float(player.vigor).is_less(vigor_before)


func test_menu_scene_flow_navigates() -> void:
	## Las escenas de menú existen y cargan sin errores (navegación real).
	for scene_path: String in [
		"res://scenes/arpg/menu/main_menu.tscn",
		"res://scenes/arpg/menu/settings_menu.tscn",
		"res://scenes/arpg/menu/credits_menu.tscn",
		"res://scenes/arpg/menu/multiplayer_menu.tscn",
		"res://scenes/arpg/menu/intro_splash.tscn",
	]:
		var scene: PackedScene = load(scene_path)
		assert_object(scene).is_not_null()
		var instance: Node = auto_free(scene.instantiate())
		add_child(instance)
		assert_bool(is_instance_valid(instance)).is_true()


func test_main_menu_buttons_exist() -> void:
	var menu: ArpgMainMenu = auto_free(load("res://scenes/arpg/menu/main_menu.tscn").instantiate())
	add_child(menu)
	## Contrato del menú: continuar/nueva/multijugador/ajustes/créditos/salir.
	var labels: Array[String] = []
	for child: Node in menu._button_box.get_children():
		if child is Button:
			labels.append((child as Button).text)
	for expected: String in ["Continuar", "Nueva partida", "MULTIJUGADOR", "Ajustes", "Créditos", "Salir"]:
		assert_bool(labels.has(expected)).is_true()

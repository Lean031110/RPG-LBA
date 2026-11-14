class_name TestHudIteracion4C
extends GdUnitTestSuite
## Iteración 4C en el HUD: botón táctil de pausa junto al minimapa, recargas
## radiales en habilidad y esquiva conectadas a los valores REALES del jugador,
## y realce táctil al pulsar los botones del arco.


func _make_hud() -> ArpgHUD:
	var hud: ArpgHUD = auto_free(load("res://scenes/arpg/ui/arpg_hud.tscn").instantiate())
	add_child(hud)
	return hud


func _find_button_by_name(root: Node, node_name: String) -> Button:
	if root is Button and root.name == node_name:
		return root
	for child: Node in root.get_children():
		var found := _find_button_by_name(child, node_name)
		if found != null:
			return found
	return null


func test_pause_button_exists_and_signals() -> void:
	var hud := _make_hud()
	var pause := _find_button_by_name(hud, "PauseButton")
	assert_object(pause).is_not_null()
	assert_bool(pause.visible).is_true()
	# La señal pause_requested existe en el contrato del HUD.
	assert_bool(hud.has_signal("pause_requested")).is_true()
	var flags: Array = []
	hud.pause_requested.connect(func() -> void: flags.append(1))
	pause.pressed.emit()
	assert_int(flags.size()).is_equal(1)


func test_cooldown_overlays_track_player_values() -> void:
	var hud := _make_hud()
	var player: ArpgPlayer = auto_free(ArpgPlayer.new())
	add_child(player)
	player.setup("machetero")
	hud.bind_player(player)
	# Sin recarga: los overlays se ocultan.
	assert_bool(hud._skill_cooldown.visible).is_false()
	# Recarga real de la habilidad (datos de clase): el overlay se enciende.
	player._skill_cooldown_left = player.get_skill_cooldown_total()
	hud._process(0.016)
	assert_bool(hud._skill_cooldown.visible).is_true()
	assert_float(hud._skill_cooldown.progress).is_equal_approx(1.0, 0.01)
	# Y baja conforme corre el tiempo.
	player._skill_cooldown_left = player.get_skill_cooldown_total() * 0.5
	hud._process(0.016)
	assert_float(hud._skill_cooldown.progress).is_equal_approx(0.5, 0.02)


func test_stats_panel_keeps_gold_accent() -> void:
	var hud := _make_hud()
	var style: StyleBoxFlat = hud._stats_panel.get_theme_stylebox("panel")
	assert_int(style.border_width_left).is_greater(1)


func test_player_exposes_cooldown_getters() -> void:
	var player: ArpgPlayer = auto_free(ArpgPlayer.new())
	add_child(player)
	player.setup("machetero")
	assert_float(player.get_skill_cooldown_total()).is_greater(0.0)
	assert_float(player.get_dodge_cooldown_total()).is_greater(0.0)
	assert_float(player.get_skill_cooldown_left()).is_equal(0.0)

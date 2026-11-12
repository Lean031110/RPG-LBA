class_name TestHudFase3
extends GdUnitTestSuite
## HUD Fase 3 (estilo ARPG móvil): botones de acción en arco abajo-derecha con el ataque
## como botón más grande, todo semitransparente, minimapa arriba-derecha, mochila junto al
## minimapa y sin solapamientos en landscape 16:9 y 20:9. La API de la Fase 1 queda intacta.


func _make_hud() -> ArpgHUD:
	var hud: ArpgHUD = auto_free(load("res://scenes/arpg/ui/arpg_hud.tscn").instantiate())
	add_child(hud)
	return hud


func _layout(hud: ArpgHUD, size: Vector2) -> void:
	var root := hud.get_root_control()
	root.size = size
	hud._layout_hud()


func _rect(button: Button) -> Rect2:
	return Rect2(button.position, button.size)


func test_action_buttons_are_circular_and_sized() -> void:
	var hud := _make_hud()
	assert_float(hud._attack_button.custom_minimum_size.x).is_equal(104.0)
	assert_float(hud._skill_button.custom_minimum_size.x).is_equal(84.0)
	assert_float(hud._dodge_button.custom_minimum_size.x).is_equal(72.0)
	assert_float(hud._potion_button.custom_minimum_size.x).is_equal(64.0)
	# El ataque es el botón más grande del clúster (referencia Diablo Immortal/MLBB).
	assert_float(hud._attack_button.custom_minimum_size.x).is_greater(hud._skill_button.custom_minimum_size.x)


func test_action_buttons_are_semitransparent() -> void:
	var hud := _make_hud()
	for button: Button in [hud._attack_button, hud._skill_button, hud._dodge_button, hud._potion_button]:
		var style := button.get_theme_stylebox("normal") as StyleBoxFlat
		assert_object(style).is_not_null()
		assert_float(style.bg_color.a).is_less(0.6)
		assert_float(style.bg_color.a).is_greater(0.1)


func test_minimap_sits_top_right_and_inventory_button_below() -> void:
	var hud := _make_hud()
	_layout(hud, Vector2(1280, 720))
	# Minimapa pegado a la esquina superior derecha con margen.
	assert_float(hud._minimap.position.x).is_equal_approx(1280.0 - 224.0 - 16.0, 0.5)
	assert_float(hud._minimap.position.y).is_equal_approx(14.0, 0.5)
	# Botón de mochila debajo del minimapa, alineado a la derecha.
	assert_float(hud._inventory_button.position.x).is_equal_approx(1280.0 - 72.0, 0.5)
	assert_float(hud._inventory_button.position.y).is_greater(160.0)


func test_arc_cluster_lands_bottom_right_16x9() -> void:
	var hud := _make_hud()
	_layout(hud, Vector2(1280, 720))
	for button: Button in [hud._attack_button, hud._skill_button, hud._dodge_button, hud._potion_button]:
		assert_float(button.position.x).is_greater(760.0)
		assert_float(button.position.y).is_greater(300.0)
		# Dentro del viewport con margen.
		assert_float(button.position.y + button.size.y).is_less_equal(721.0)


func test_no_overlaps_at_16x9_and_20x9() -> void:
	for viewport_size: Vector2 in [Vector2(1280, 720), Vector2(1600, 720)]:
		var hud := _make_hud()
		_layout(hud, viewport_size)
		var buttons: Array[Button] = [hud._attack_button, hud._skill_button, hud._dodge_button, hud._potion_button]
		for index: int in buttons.size():
			for other: int in range(index + 1, buttons.size()):
				assert_bool(_rect(buttons[index]).intersects(_rect(buttons[other]))).is_false()
		# El joystick (abajo-izquierda) nunca choca con el clúster (abajo-derecha).
		var joy_rect := Rect2(hud._joystick.position, hud._joystick.size)
		for button: Button in buttons:
			assert_bool(joy_rect.intersects(_rect(button))).is_false()
		# El minimapa (arriba-derecha) no choca con stats/misión (arriba-izquierda).
		var map_rect := Rect2(hud._minimap.position, hud._minimap.size)
		assert_bool(map_rect.intersects(hud._stats_panel.get_rect())).is_false()


func test_potion_badge_still_updates() -> void:
	var player: ArpgPlayer = auto_free(ArpgPlayer.new())
	add_child(player)
	player.setup("machetero")
	var hud := _make_hud()
	hud.bind_player(player)
	player.add_potion(2)
	await get_tree().process_frame
	assert_str(hud._potion_badge.text).is_equal("x3")


func test_inventory_panel_toggles() -> void:
	var player: ArpgPlayer = auto_free(ArpgPlayer.new())
	add_child(player)
	player.setup("machetero")
	var hud := _make_hud()
	hud.bind_player(player)
	assert_bool(hud.is_inventory_open()).is_false()
	hud.toggle_inventory()
	assert_bool(hud.is_inventory_open()).is_true()
	assert_bool(hud._inventory_panel.visible).is_true()
	# Con el jugador vinculado, la rejilla muestra los huecos activos (16 base).
	assert_int(hud._inventory_panel._slot_buttons.size()).is_equal(PlayerInventory.MAX_INVENTORY_SIZE)
	hud.toggle_inventory()
	assert_bool(hud.is_inventory_open()).is_false()


func test_interact_and_dialog_api_unchanged() -> void:
	# Regresión ligera de la API de la Fase 1 tras la reorganización del HUD.
	var hud := _make_hud()
	hud.set_interact_prompt(true, "Hablar con Cheo (E)")
	assert_bool(hud._interact_button.visible).is_true()
	assert_str(hud._interact_button.text).is_equal("Hablar con Cheo (E)")
	hud.show_dialog("Cheo", ["Linea."], "info")
	assert_bool(hud.is_dialog_open()).is_true()

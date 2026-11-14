class_name TestMultiplayerMenu
extends GdUnitTestSuite
## Iteración 4C: el apartado MULTIJUGADOR existe desde el menú principal y su
## pantalla es honesta: lobby LAN real (ENet) + lo que falta marcado como en
## desarrollo. Nada simulado: sin lista de salas falsas ni botones decorativos.
##
## Nota: el autoload Network NO registra el diccionario `players` cuando corre
## bajo DisplayServer headless (comportamiento del servidor dedicado); en esta
## suite se verifica el servidor ENet real y la UI, no el registro headless.


func _make_menu() -> ArpgMultiplayerMenu:
	var menu: ArpgMultiplayerMenu = auto_free(load("res://scenes/arpg/menu/multiplayer_menu.tscn").instantiate())
	add_child(menu)
	return menu


func _find_button(root: Node, text: String) -> Button:
	if root is Button and (root as Button).text == text:
		return root
	for child: Node in root.get_children():
		var found := _find_button(child, text)
		if found != null:
			return found
	return null


func test_main_menu_has_multiplayer_entry() -> void:
	var menu: ArpgMainMenu = auto_free(load("res://scenes/arpg/menu/main_menu.tscn").instantiate())
	add_child(menu)
	var button := _find_button(menu, "MULTIJUGADOR")
	assert_object(button).is_not_null()
	assert_bool(button.visible).is_true()


func test_multiplayer_menu_builds_with_real_actions() -> void:
	var menu := _make_menu()
	assert_object(menu._host_button).is_not_null()
	assert_object(menu._join_button).is_not_null()
	assert_object(menu._leave_button).is_not_null()
	# Volver al menú principal siempre disponible.
	assert_object(_find_button(menu, "Volver al menú principal")).is_not_null()


func test_empty_room_shows_no_fake_players() -> void:
	var menu := _make_menu()
	Network.leave_game()
	# Sin sesión no hay jugadores: la lista lo dice sin inventar conectados.
	assert_int(Network.players.size()).is_equal(0)
	assert_str(menu._players_count.text).is_equal("Jugadores: 0")
	assert_str(menu._status_label.text).is_equal("Sin conectar")


func test_host_creates_real_lan_room() -> void:
	var menu := _make_menu()
	menu._nick_field.text = "Tester"
	menu._room_field.text = "Sala de prueba"
	Network.leave_game()
	menu._on_host_pressed()
	# El autoload Network aloja de verdad (servidor ENet en el puerto 8080).
	assert_bool(Network.multiplayer.is_server()).is_true()
	assert_bool(Network.multiplayer.multiplayer_peer is ENetMultiplayerPeer).is_true()
	assert_str(menu._room_label.text).is_equal("Sala de prueba")
	assert_bool(menu._status_label.text.contains("Sala creada")).is_true()
	Network.leave_game()


func test_host_without_nick_reports_error() -> void:
	var menu := _make_menu()
	menu._nick_field.text = "   "
	menu._on_host_pressed()
	assert_bool(menu._status_label.text.contains("nombre")).is_true()
	# No se abrió ninguna sesión por un campo vacío.
	assert_bool(Network.multiplayer.is_server()).is_false()


func test_join_with_invalid_ip_reports_error() -> void:
	var menu := _make_menu()
	menu._nick_field.text = "Tester"
	menu._ip_field.text = "no-es-una-ip"
	menu._on_join_pressed()
	# La IP no válida no abre sesión: informe claro y sin ficción.
	assert_bool(menu._status_label.text.contains("no válida")).is_true()
	assert_bool(not (Network.multiplayer.multiplayer_peer is ENetMultiplayerPeer)).is_true()


func test_state_panel_does_not_pretend_online() -> void:
	## Sin servidor de listas ni matchmaking: la pantalla nunca muestra salas
	## ni jugadores conectados inventados.
	var menu := _make_menu()
	# El panel de estado existe y su texto menciona lo que falta.
	assert_bool(menu._status_label.text.contains("Sin conectar")).is_true()
	assert_int(Network.players.size()).is_equal(0)


func after_test() -> void:
	Network.leave_game()

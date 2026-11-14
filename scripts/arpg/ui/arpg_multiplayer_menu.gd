class_name ArpgMultiplayerMenu
extends Control
## Pantalla del modo MULTIJUGADOR (iteración 4C). Diseño profesional y, sobre
## todo, HONESTO: no simula online. Lo que funciona de verdad hoy (lobby LAN
## con ENet: crear sala, unirse por IP, lista de jugadores sincronizada por
## RPC del autoload Network) está activo; lo que falta (servidor de listas,
## matchmaking, sincronización de partida ARPG) queda marcado como "en
## desarrollo" sin botones que aparenten funcionar.
##
## Qué existe y qué falta queda documentado en docs/18_MULTIJUGADOR.md y en el
## panel "Estado del modo" de esta misma pantalla.

const MENU_SCENE := "res://scenes/arpg/menu/main_menu.tscn"

var _status_label: Label = null
var _room_label: Label = null
var _players_list: VBoxContainer = null
var _players_count: Label = null
var _host_button: Button = null
var _join_button: Button = null
var _nick_field: LineEdit = null
var _ip_field: LineEdit = null
var _room_field: LineEdit = null
var _leave_button: Button = null
var _room_name := "Sala de Valdeluz"
var _joining := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ArpgBackdrop.new(0.55))
	_build_header()
	_build_columns()
	_build_footer()
	resized.connect(_relayout)
	get_viewport().connect("size_changed", _relayout)
	Network.player_connected.connect(_on_player_connected)
	Network.server_disconnected.connect(_on_session_ended)
	_refresh_room()


func _exit_tree() -> void:
	if Network != null:
		Network.player_connected.disconnect(_on_player_connected)
		Network.server_disconnected.disconnect(_on_session_ended)


func _relayout() -> void:
	var vs := get_viewport().get_visible_rect().size
	if vs.x < 1.0 or vs.y < 1.0:
		return
	_column_position(vs)


func _column_position(vs: Vector2) -> void:
	var root := get_node_or_null("Columns") as HBoxContainer
	if root == null:
		return
	var ms := root.get_combined_minimum_size()
	if ms.x > 1.0 and vs.x > 1.0:
		root.position = Vector2((vs.x - ms.x) / 2.0, 108.0)


func _build_header() -> void:
	var header := Control.new()
	header.name = "Header"
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)
	var mini := ArpgUiTheme.logo_texture(300.0)
	mini.position = Vector2(24, 16)
	header.add_child(mini)
	var title := ArpgUiTheme.make_title("MULTIJUGADOR", 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 26)
	title.size = Vector2(1280, 44)
	header.add_child(title)
	var subtitle := ArpgUiTheme.make_dim("Lobby local (LAN) con ENet · El modo online está en desarrollo", 13)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(0, 72)
	subtitle.size = Vector2(1280, 20)
	header.add_child(subtitle)


func _build_columns() -> void:
	var columns := HBoxContainer.new()
	columns.name = "Columns"
	columns.add_theme_constant_override("separation", 18)
	columns.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(columns)

	columns.add_child(_build_actions_panel())
	columns.add_child(_build_room_panel())
	columns.add_child(_build_state_panel())


func _panel(title_text: String, width: float) -> Dictionary:
	## Panel estándar de la pantalla: contenedor + título en Cinzel dorado.
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", ArpgUiTheme.panel_style())
	panel.custom_minimum_size = Vector2(width, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)
	box.add_child(ArpgUiTheme.make_title(title_text, 20))
	return {"panel": panel, "box": box}


func _build_actions_panel() -> PanelContainer:
	var parts := _panel("Acciones", 360)
	var box: VBoxContainer = parts["box"]

	box.add_child(_field_label("Tu nombre"))
	_nick_field = _style_line_edit(LineEdit.new())
	_nick_field.text = "Cimarron_%d" % (randi() % 900 + 100)
	_nick_field.max_length = 24
	_nick_field.custom_minimum_size = Vector2(300, 40)
	box.add_child(_nick_field)

	box.add_child(_field_label("Nombre de la sala (solo anfitrión)"))
	_room_field = _style_line_edit(LineEdit.new())
	_room_field.text = _room_name
	_room_field.max_length = 24
	_room_field.custom_minimum_size = Vector2(300, 40)
	box.add_child(_room_field)

	_host_button = ArpgUiTheme.make_button("Crear partida (LAN)", ArpgUiTheme.ButtonStyle.PRIMARY, Vector2(310, 50))
	_host_button.pressed.connect(_on_host_pressed)
	box.add_child(_host_button)

	box.add_child(_field_label("IP del anfitrión (para unirse)"))
	_ip_field = _style_line_edit(LineEdit.new())
	_ip_field.text = "192.168.1."
	_ip_field.placeholder_text = "p. ej. 192.168.1.42"
	_ip_field.custom_minimum_size = Vector2(300, 40)
	box.add_child(_ip_field)

	_join_button = ArpgUiTheme.make_button("Unirse a la partida", ArpgUiTheme.ButtonStyle.PRIMARY, Vector2(310, 50))
	_join_button.pressed.connect(_on_join_pressed)
	box.add_child(_join_button)

	_leave_button = ArpgUiTheme.make_button("Abandonar sala", ArpgUiTheme.ButtonStyle.DANGER, Vector2(310, 46))
	_leave_button.pressed.connect(
		func() -> void:
			Network.leave_game()
			_on_session_ended()
	)
	box.add_child(_leave_button)
	return parts["panel"]


func _build_room_panel() -> PanelContainer:
	var parts := _panel("Sala", 330)
	var box: VBoxContainer = parts["box"]

	_room_label = ArpgUiTheme.make_body(_room_name, 18, Color("e8d2a4"))
	box.add_child(_room_label)

	_status_label = ArpgUiTheme.make_body("Sin conectar", 14, ArpgUiTheme.DIM)
	box.add_child(_status_label)

	_players_count = ArpgUiTheme.make_dim("Jugadores: 0", 13)
	box.add_child(_players_count)

	var list_panel := PanelContainer.new()
	list_panel.add_theme_stylebox_override("panel", ArpgUiTheme.hud_panel_style(0.55))
	list_panel.custom_minimum_size = Vector2(300, 220)
	_players_list = VBoxContainer.new()
	_players_list.add_theme_constant_override("separation", 6)
	list_panel.add_child(_players_list)
	box.add_child(list_panel)

	var hint := ArpgUiTheme.make_dim(
		"Con ambos teléfonos en el mismo WiFi: uno crea la partida y el otro se une con la IP que ve el anfitrión.", 12
	)
	hint.custom_minimum_size = Vector2(300, 0)
	box.add_child(hint)
	return parts["panel"]


func _build_state_panel() -> PanelContainer:
	var parts := _panel("Estado del modo", 330)
	var box: VBoxContainer = parts["box"]

	box.add_child(_state_row("Crear sala en LAN (ENet)", true))
	box.add_child(_state_row("Unirse por IP en LAN (ENet)", true))
	box.add_child(_state_row("Lista de jugadores sincronizada", true))
	box.add_child(_state_row("Nombres y salas persistentes", false))
	box.add_child(_state_row("Servidor de listas (internet)", false))
	box.add_child(_state_row("Sincronización de partida ARPG", false))
	box.add_child(_state_row("Matchmaking y salas públicas", false))

	var more := ArpgUiTheme.make_dim(
		(
			"Qué falta para el online completo: servidor dedicado, registro de salas, "
			+ "sincronización de jugadores/enemigos/daño en red, reconexión y cuentas. "
			+ "Detalle técnico: docs/18_MULTIJUGADOR.md"
		),
		12
	)
	more.custom_minimum_size = Vector2(300, 0)
	box.add_child(more)
	return parts["panel"]


func _state_row(label_text: String, available: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var mark := Label.new()
	mark.text = "●"
	mark.add_theme_font_size_override("font_size", 13)
	mark.add_theme_color_override("font_color", ArpgUiTheme.PALM if available else Color("6a4a4a"))
	row.add_child(mark)
	var label := ArpgUiTheme.make_body(label_text, 13, ArpgUiTheme.BONE if available else ArpgUiTheme.DIM)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	return row


func _field_label(text: String) -> Label:
	var label := ArpgUiTheme.make_dim(text, 12)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return label


func _style_line_edit(field: LineEdit) -> LineEdit:
	## Campo oscuro con borde dorado al enfocar, coherente con el resto.
	field.add_theme_color_override("font_color", ArpgUiTheme.BONE)
	field.add_theme_color_override("font_placeholder_color", Color("5a5f6a"))
	field.add_theme_color_override("caret_color", ArpgUiTheme.GOLD)
	field.add_theme_font_size_override("font_size", 15)
	var normal := ArpgUiTheme.panel_style(
		Color(ArpgUiTheme.GOLD_DARK.r, ArpgUiTheme.GOLD_DARK.g, ArpgUiTheme.GOLD_DARK.b, 0.35), 1, 6, ArpgUiTheme.NIGHT
	)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	var focused := ArpgUiTheme.panel_style(ArpgUiTheme.GOLD, 1, 6, ArpgUiTheme.PANEL_SOFT)
	focused.content_margin_left = 12
	focused.content_margin_right = 12
	focused.content_margin_top = 6
	focused.content_margin_bottom = 6
	field.add_theme_stylebox_override("normal", normal)
	field.add_theme_stylebox_override("focus", focused)
	return field


func _build_footer() -> void:
	var back := ArpgUiTheme.make_button("Volver al menú principal", ArpgUiTheme.ButtonStyle.NORMAL, Vector2(300, 48))
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	add_child(back)
	back.position = Vector2(490, 656)


# ---------------------------------------------------------------------------
# Comportamiento real (lobby ENet del autoload Network)
# ---------------------------------------------------------------------------


func _on_host_pressed() -> void:
	var nick := _nick_field.text.strip_edges()
	if nick.is_empty():
		_set_status("Escribe tu nombre para crear la sala.", ArpgUiTheme.EMBER)
		return
	_room_name = _room_field.text.strip_edges()
	if _room_name.is_empty():
		_room_name = "Sala de Valdeluz"
	var error: Variant = Network.start_host(nick, "blue")
	if error != null and int(error) != 0:
		_set_status("No se pudo abrir el puerto 8080 (¿otra sala activa?). Código: %s" % [error], ArpgUiTheme.EMBER)
		return
	_room_label.text = _room_name
	_set_status("Sala creada en LAN · IP: %s:%d" % [_primary_lan_ip(), Network.SERVER_PORT], ArpgUiTheme.PALM)
	_refresh_room()


func _on_join_pressed() -> void:
	var nick := _nick_field.text.strip_edges()
	if nick.is_empty():
		_set_status("Escribe tu nombre para unirte.", ArpgUiTheme.EMBER)
		return
	var address := _ip_field.text.strip_edges()
	if address.is_empty():
		_set_status("Escribe la IP del anfitrión.", ArpgUiTheme.EMBER)
		return
	_joining = true
	_set_status("Conectando con %s…" % [address], ArpgUiTheme.GOLD)
	var error: Variant = Network.join_game(nick, "blue", address)
	if error != null and int(error) != 0:
		_joining = false
		_set_status("IP no válida. Revisa el formato (solo números y puntos).", ArpgUiTheme.EMBER)
		return
	await get_tree().create_timer(2.5).timeout
	if _joining and not Network.players.is_empty():
		_joining = false
		_room_label.text = "Sala remota"
		_set_status("Conectado a %s" % [address], ArpgUiTheme.PALM)
		_refresh_room()
	elif _joining:
		_joining = false
		_set_status(
			"No se pudo conectar con %s (misma WiFi, juego abierto en el anfitrión)." % [address], ArpgUiTheme.EMBER
		)
		_refresh_room()


func _on_player_connected(_peer_id: int, _info: Dictionary) -> void:
	_refresh_room()


func _on_session_ended() -> void:
	_set_status("Sin conectar", ArpgUiTheme.DIM)
	_refresh_room()


func _refresh_room() -> void:
	if _players_list == null:
		return
	for child: Node in _players_list.get_children():
		child.queue_free()
	var count := 0
	for peer_id: int in Network.players:
		var info: Dictionary = Network.players[peer_id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var mark := Label.new()
		mark.text = "▸"
		mark.add_theme_font_size_override("font_size", 13)
		mark.add_theme_color_override("font_color", ArpgUiTheme.GOLD)
		row.add_child(mark)
		var name_label := ArpgUiTheme.make_body(str(info.get("nick", "Player")), 14)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(name_label)
		var role := ArpgUiTheme.make_dim("Anfitrión" if peer_id == 1 else "Invitado", 12)
		row.add_child(role)
		_players_list.add_child(row)
		count += 1
	if count == 0:
		var empty := ArpgUiTheme.make_dim("Todavía no hay jugadores en la sala.", 13)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_players_list.add_child(empty)
	_players_count.text = "Jugadores: %d" % count


func _set_status(text: String, color: Color) -> void:
	if _status_label != null:
		_status_label.text = text
		_status_label.add_theme_color_override("font_color", color)


func _primary_lan_ip() -> String:
	## Primera IP privada del dispositivo (para que el otro jugador la teclee).
	for address: String in IP.get_local_addresses():
		if address.begins_with("192.168.") or address.begins_with("10.") or address.begins_with("172."):
			return address
	return "IP no detectada"

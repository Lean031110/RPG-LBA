class_name ArpgHUD
extends CanvasLayer
## HUD de la vertical slice, reorganizado en los preparativos de la Fase 3 con la
## distribución de los ARPG móviles de referencia (Diablo Immortal / Mobile Legends):
## - Joystick abajo-izquierda; clúster de acciones en ARCO abajo-derecha (ataque grande).
## - Minimapa cenital arriba-derecha (ArpgMinimap); mochila (inventario) junto al minimapa.
## - Todo SEMITRANSPARENTE para no tapar la escena; paneles de stats/misión arriba-izquierda.
## Lógica desacoplada: solo escucha señales del jugador/misiones y expone el vector del
## joystick. Sin lógica de juego en la UI (regla del repositorio).

signal joystick_changed(vector: Vector2)
signal dialog_accepted
signal dialog_closed

const COLOR_PANEL := Color("14161c")
const COLOR_PANEL_LINE := Color("2a2e38")
const COLOR_TEXT := Color("e8e4d8")
const COLOR_TEXT_DIM := Color("9aa0a6")
const COLOR_HP := Color("a32130")
const COLOR_VIGOR := Color("c98a2d")
const COLOR_XP := Color("b08d3c")
const COLOR_ACCENT := Color("1e3a4a")
const COLOR_DANGER := Color("e0503e")
## Fase 3: transparencias del HUD móvil (semitransparente, referencia Diablo/MLBB).
const ALPHA_PANEL := 0.42
const ALPHA_BUTTON := 0.35
const ALPHA_BUTTON_HOVER := 0.55
const ALPHA_BUTTON_PRESSED := 0.85

const ICON_ATTACK: Texture2D = preload("res://assets/ui/icons/attack.png")
const ICON_SKILL: Texture2D = preload("res://assets/ui/icons/skill.png")
const ICON_DODGE: Texture2D = preload("res://assets/ui/icons/dodge.png")
const ICON_POTION: Texture2D = preload("res://assets/ui/icons/potion.png")
const ICON_BAG: Texture2D = preload("res://assets/ui/icons/bag.png")

var _player: Node = null
var _joystick_vector := Vector2.ZERO

var _stats_panel: PanelContainer = null
var _quest_panel: PanelContainer = null
var _hp_bar: ProgressBar = null
var _vigor_bar: ProgressBar = null
var _xp_bar: ProgressBar = null
var _level_label: Label = null
var _class_label: Label = null
var _resource_label: Label = null
var _potion_badge: Label = null
var _quest_title: Label = null
var _quest_lines: VBoxContainer = null
var _quest_hint: Label = null
var _toast_label: Label = null
var _interact_button: Button = null
var _joystick: ArpgVirtualJoystick = null
var _action_cluster: Control = null
var _attack_button: Button = null
var _skill_button: Button = null
var _dodge_button: Button = null
var _potion_button: Button = null
var _minimap: ArpgMinimap = null
var _inventory_button: Button = null
var _inventory_panel: ArpgInventoryPanel = null
var _dialog_panel: PanelContainer = null
var _dialog_name: Label = null
var _dialog_line: Label = null
var _dialog_action: Button = null
var _dialog_lines: Array = []
var _dialog_index := 0
var _dialog_mode := "info"
var _dialog_on_accept: Callable


func _ready() -> void:
	_build_stats_panel()
	_build_quest_tracker()
	_build_toast()
	_build_joystick()
	_build_action_buttons()
	_build_interact_button()
	_build_dialog_panel()
	_build_minimap()
	_build_inventory_button()
	_build_inventory_panel()
	var root := get_root_control()
	root.resized.connect(_layout_hud)
	_layout_hud()


func _unhandled_input(event: InputEvent) -> void:
	## Fase 3: la mochila se abre/cierra con la acción dedicada (tecla I en PC).
	if event.is_action_pressed("arpg_inventory"):
		toggle_inventory()
		get_viewport().set_input_as_handled()


func bind_player(player: Node) -> void:
	_player = player
	if player == null:
		return
	player.stats_changed.connect(_refresh_stats)
	player.leveled_up.connect(_on_leveled_up)
	_class_label.text = player.get_class_name()
	_resource_label.text = player.get_resource_name()
	_minimap.set_player(player as Node3D)
	_inventory_panel.bind_player(player as ArpgPlayer)
	_refresh_stats()


func is_dialog_open() -> bool:
	return _dialog_panel != null and _dialog_panel.visible


func get_joystick_vector() -> Vector2:
	return _joystick_vector


func is_inventory_open() -> bool:
	return _inventory_panel != null and _inventory_panel.is_open()


func toggle_inventory() -> void:
	if _inventory_panel != null:
		_inventory_panel.toggle()


func set_quest_tracker(title: String, lines: Array) -> void:
	_quest_title.text = title
	for child: Node in _quest_lines.get_children():
		_quest_lines.remove_child(child)
		child.queue_free()
	for line: String in lines:
		var label := Label.new()
		label.text = line
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
		_quest_lines.add_child(label)
	_quest_hint.text = ""


func set_quest_hint(hint: String) -> void:
	_quest_hint.text = hint


func clear_quest_tracker() -> void:
	_quest_title.text = ""
	set_quest_tracker("", [])


func show_toast(text: String, duration := 2.6) -> void:
	_toast_label.text = text
	_toast_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(duration)
	tween.tween_property(_toast_label, "modulate:a", 0.0, 0.5)


func set_interact_prompt(show_prompt: bool, text := "") -> void:
	_interact_button.visible = show_prompt
	if show_prompt:
		_interact_button.text = text


func show_dialog(npc_name: String, lines: Array, mode := "info", on_accept: Callable = Callable()) -> void:
	_dialog_lines = lines
	_dialog_index = 0
	_dialog_mode = mode
	_dialog_on_accept = on_accept
	_dialog_name.text = npc_name
	_dialog_line.text = String(lines[0]) if lines.size() > 0 else ""
	_dialog_action.text = "Aceptar misión" if mode == "offer" else "Cerrar"
	_dialog_panel.visible = true


func _dialog_next() -> void:
	if _dialog_index < _dialog_lines.size() - 1:
		_dialog_index += 1
		_dialog_line.text = String(_dialog_lines[_dialog_index])
		if _dialog_index == _dialog_lines.size() - 1:
			_dialog_action.text = _dialog_end_label()
		else:
			_dialog_action.text = "Continuar"
		return
	# Última línea: cerrar o aceptar.
	_dialog_panel.visible = false
	if (_dialog_mode == "offer" or _dialog_mode == "claim") and _dialog_on_accept.is_valid():
		_dialog_on_accept.call()
		dialog_accepted.emit()
	else:
		dialog_closed.emit()


func _dialog_end_label() -> String:
	if _dialog_mode == "offer":
		return "Aceptar misión"
	if _dialog_mode == "claim":
		return "Reclamar recompensa"
	return "Cerrar"


func _refresh_stats() -> void:
	if _player == null:
		return
	_hp_bar.value = _player.get_hp_fraction() * 100.0
	_vigor_bar.value = _player.get_vigor_fraction() * 100.0
	_xp_bar.value = _player.get_xp_fraction() * 100.0
	_level_label.text = "Nv %d" % _player.get_level()
	_potion_badge.text = "x%d" % _player.get_potions()


func _on_leveled_up(new_level: int) -> void:
	show_toast("¡Nivel %d! La manigua te reconoce." % new_level)


func _build_stats_panel() -> void:
	_stats_panel = PanelContainer.new()
	_stats_panel.name = "StatsPanel"
	_stats_panel.add_theme_stylebox_override("panel", _panel_style())
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	_stats_panel.add_child(box)
	_class_label = Label.new()
	_class_label.text = ""
	_class_label.add_theme_font_size_override("font_size", 15)
	_class_label.add_theme_color_override("font_color", COLOR_TEXT)
	box.add_child(_class_label)
	var head := HBoxContainer.new()
	box.add_child(head)
	_level_label = Label.new()
	_level_label.text = "Nv 1"
	_level_label.add_theme_font_size_override("font_size", 13)
	_level_label.add_theme_color_override("font_color", COLOR_XP)
	head.add_child(_level_label)
	_resource_label = Label.new()
	_resource_label.text = ""
	_resource_label.add_theme_font_size_override("font_size", 12)
	_resource_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	head.add_child(_resource_label)
	_hp_bar = _make_bar(COLOR_HP, 12)
	_vigor_bar = _make_bar(COLOR_VIGOR, 10)
	_xp_bar = _make_bar(COLOR_XP, 6)
	box.add_child(_hp_bar)
	box.add_child(_vigor_bar)
	box.add_child(_xp_bar)
	get_root_control().add_child(_stats_panel)


func _build_quest_tracker() -> void:
	_quest_panel = PanelContainer.new()
	_quest_panel.name = "QuestPanel"
	_quest_panel.add_theme_stylebox_override("panel", _panel_style())
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	_quest_panel.add_child(box)
	_quest_title = Label.new()
	_quest_title.text = ""
	_quest_title.add_theme_font_size_override("font_size", 14)
	_quest_title.add_theme_color_override("font_color", COLOR_XP)
	box.add_child(_quest_title)
	_quest_lines = VBoxContainer.new()
	box.add_child(_quest_lines)
	_quest_hint = Label.new()
	_quest_hint.text = ""
	_quest_hint.add_theme_font_size_override("font_size", 12)
	_quest_hint.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	_quest_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_hint.custom_minimum_size = Vector2(240, 0)
	box.add_child(_quest_hint)
	get_root_control().add_child(_quest_panel)


func _build_toast() -> void:
	_toast_label = Label.new()
	_toast_label.name = "Toast"
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.add_theme_font_size_override("font_size", 17)
	_toast_label.add_theme_color_override("font_color", COLOR_XP)
	_toast_label.modulate.a = 0.0
	_toast_label.custom_minimum_size = Vector2(0, 26)
	get_root_control().add_child(_toast_label)


func _build_joystick() -> void:
	_joystick = ArpgVirtualJoystick.new()
	_joystick.name = "VirtualJoystick"
	get_root_control().add_child(_joystick)
	_joystick.value_changed.connect(_on_joystick_value)


func _on_joystick_value(value: Vector2) -> void:
	_joystick_vector = value
	joystick_changed.emit(value)


func _set_joystick(vector: Vector2) -> void:
	## Compatibilidad de la Fase 1 (usada por pruebas): aplica un offset como si
	## el dedo estuviera en esa posición del área del joystick.
	_joystick.set_value_from_offset(vector)


func _build_action_buttons() -> void:
	## Fase 3: clúster en arco estilo ARPG móvil. El ataque es el botón más grande
	## (abajo-derecha); habilidad encima; poción a la izquierda; esquiva arriba-izquierda.
	_action_cluster = Control.new()
	_action_cluster.name = "ActionCluster"
	_action_cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_root_control().add_child(_action_cluster)
	_attack_button = _round_action_button(ICON_ATTACK, "J", 104.0)
	_skill_button = _round_action_button(ICON_SKILL, "K", 84.0)
	_dodge_button = _round_action_button(ICON_DODGE, "ESP", 72.0)
	_potion_button = _round_action_button(ICON_POTION, "Q", 64.0)
	_potion_badge = Label.new()
	_potion_badge.text = "x1"
	_potion_badge.add_theme_font_size_override("font_size", 13)
	_potion_badge.add_theme_color_override("font_color", COLOR_TEXT)
	_potion_button.add_child(_potion_badge)
	_potion_badge.position = Vector2(36, 2)
	_attack_button.pressed.connect(_on_action_pressed.bind("attack"))
	_skill_button.pressed.connect(_on_action_pressed.bind("skill"))
	_dodge_button.pressed.connect(_on_action_pressed.bind("dodge"))
	_potion_button.pressed.connect(_on_action_pressed.bind("potion"))
	for button: Button in [_attack_button, _skill_button, _dodge_button, _potion_button]:
		_action_cluster.add_child(button)


func _round_action_button(icon: Texture2D, key_hint: String, diameter: float) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(diameter, diameter)
	button.add_theme_stylebox_override("normal", _circle_style(diameter, ALPHA_BUTTON))
	button.add_theme_stylebox_override("hover", _circle_style(diameter, ALPHA_BUTTON_HOVER))
	button.add_theme_stylebox_override("pressed", _circle_style(diameter, ALPHA_BUTTON_PRESSED, true))
	var icon_rect := TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.texture = icon
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.modulate = Color(1, 1, 1, 0.95)
	var icon_size := Vector2(diameter * 0.5, diameter * 0.5)
	icon_rect.position = Vector2((diameter - icon_size.x) * 0.5, (diameter - icon_size.y) * 0.5 - 3.0)
	icon_rect.size = icon_size
	button.add_child(icon_rect)
	if key_hint != "":
		var hint := Label.new()
		hint.name = "KeyHint"
		hint.text = key_hint
		hint.add_theme_font_size_override("font_size", 10)
		hint.add_theme_color_override("font_color", COLOR_TEXT_DIM)
		hint.position = Vector2(diameter * 0.5 - 12.0, diameter - 16.0)
		button.add_child(hint)
	return button


func _on_action_pressed(action: String) -> void:
	if _player == null:
		return
	match action:
		"attack":
			_player.try_attack()
		"skill":
			_player.try_skill()
		"dodge":
			_player.try_dodge()
		"potion":
			_player.try_potion()


func _build_minimap() -> void:
	_minimap = ArpgMinimap.new()
	_minimap.name = "Minimap"
	get_root_control().add_child(_minimap)


func _build_inventory_button() -> void:
	_inventory_button = _round_action_button(ICON_BAG, "I", 56.0)
	_inventory_button.name = "InventoryButton"
	_inventory_button.pressed.connect(toggle_inventory)
	get_root_control().add_child(_inventory_button)


func _build_inventory_panel() -> void:
	_inventory_panel = ArpgInventoryPanel.new()
	_inventory_panel.name = "InventoryPanel"
	get_root_control().add_child(_inventory_panel)


func _build_interact_button() -> void:
	_interact_button = Button.new()
	_interact_button.name = "InteractButton"
	_interact_button.text = "Hablar (E)"
	_interact_button.visible = false
	_interact_button.custom_minimum_size = Vector2(180, 48)
	_interact_button.add_theme_font_size_override("font_size", 15)
	_interact_button.add_theme_color_override("font_color", COLOR_TEXT)
	_interact_button.add_theme_stylebox_override("normal", _button_style(Color(0.10, 0.16, 0.22, 0.55)))
	_interact_button.add_theme_stylebox_override("pressed", _accent_pressed_style())
	get_root_control().add_child(_interact_button)


func _build_dialog_panel() -> void:
	_dialog_panel = PanelContainer.new()
	_dialog_panel.name = "DialogPanel"
	_dialog_panel.visible = false
	_dialog_panel.add_theme_stylebox_override("panel", _panel_style(14))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_dialog_panel.add_child(box)
	_dialog_name = Label.new()
	_dialog_name.add_theme_font_size_override("font_size", 16)
	_dialog_name.add_theme_color_override("font_color", COLOR_XP)
	box.add_child(_dialog_name)
	_dialog_line = Label.new()
	_dialog_line.add_theme_font_size_override("font_size", 15)
	_dialog_line.add_theme_color_override("font_color", COLOR_TEXT)
	_dialog_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialog_line.custom_minimum_size = Vector2(560, 44)
	box.add_child(_dialog_line)
	_dialog_action = Button.new()
	_dialog_action.text = "Continuar"
	_dialog_action.custom_minimum_size = Vector2(180, 44)
	_dialog_action.add_theme_font_size_override("font_size", 14)
	_dialog_action.add_theme_color_override("font_color", COLOR_TEXT)
	_dialog_action.add_theme_stylebox_override("normal", _button_style(Color(0.13, 0.15, 0.20, 0.55)))
	_dialog_action.add_theme_stylebox_override("pressed", _accent_pressed_style())
	_dialog_action.pressed.connect(_dialog_next)
	box.add_child(_dialog_action)
	_dialog_panel.custom_minimum_size = Vector2(600, 150)
	get_root_control().add_child(_dialog_panel)


func _layout_hud() -> void:
	## Re-coloca todo el HUD según el tamaño del viewport (landscape 16:9 y 20:9 objetivo;
	## con anchos pequeños se hace clamp a 8 px). Distribución estilo ARPG móvil:
	## stats/misión arriba-izquierda, minimapa arriba-derecha, joystick abajo-izquierda,
	## clúster de acciones en arco abajo-derecha.
	var root := get_root_control()
	var viewport_size := root.size
	if viewport_size.x < 320.0 or viewport_size.y < 240.0:
		return
	_stats_panel.position = Vector2(16, 14)
	_quest_panel.position = Vector2(16, 132)
	_toast_label.position = Vector2(0, 84)
	_toast_label.size = Vector2(viewport_size.x, 30)
	var joy_size := Vector2(_joystick.radius * 2.0, _joystick.radius * 2.0)
	_joystick.position = Vector2(150.0, viewport_size.y - 150.0) - joy_size * 0.5
	_joystick.size = joy_size
	# Minimapa arriba-derecha + botón de mochila debajo (Fase 3).
	var map_size := _minimap.custom_minimum_size
	_minimap.position = Vector2(viewport_size.x - map_size.x - 16.0, 14.0)
	_minimap.size = map_size
	_inventory_button.position = Vector2(viewport_size.x - 72.0, 14.0 + map_size.y + 10.0)
	# Clúster de acciones en arco alrededor de la esquina inferior-derecha.
	var corner := Vector2(viewport_size.x - 20.0, viewport_size.y - 20.0)
	_place_arc_button(_attack_button, corner, 225.0, 128.0)
	_place_arc_button(_skill_button, corner, 250.0, 226.0)
	_place_arc_button(_potion_button, corner, 195.0, 220.0)
	_place_arc_button(_dodge_button, corner, 210.0, 280.0)
	_interact_button.position = Vector2(viewport_size.x / 2.0 - 90.0, viewport_size.y - 96.0)
	_dialog_panel.position = Vector2(maxf(viewport_size.x / 2.0 - 300.0, 8.0), maxf(viewport_size.y - 210.0, 8.0))
	var panel_size := _inventory_panel.custom_minimum_size
	_inventory_panel.position = Vector2(
		maxf(viewport_size.x / 2.0 - panel_size.x * 0.5, 8.0), maxf(viewport_size.y / 2.0 - panel_size.y * 0.5, 8.0)
	)
	_inventory_panel.size = panel_size


func _place_arc_button(button: Button, corner: Vector2, angle_deg: float, radius: float) -> void:
	## Coloca un botón circular en un ángulo/radio alrededor de la esquina (0°=este,
	## 90°=sur); los ángulos 195°-250° quedan arriba-izquierda de la esquina inferior-derecha.
	var angle := deg_to_rad(angle_deg)
	var button_size := button.custom_minimum_size
	var center := corner + Vector2(cos(angle), sin(angle)) * radius
	button.position = Vector2(
		maxf(center.x - button_size.x * 0.5, 8.0),
		maxf(center.y - button_size.y * 0.5, 8.0),
	)
	button.size = button_size


func _panel_style(margin := 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(COLOR_PANEL.r, COLOR_PANEL.g, COLOR_PANEL.b, ALPHA_PANEL)
	style.border_color = COLOR_PANEL_LINE
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style


func _button_style(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = COLOR_PANEL_LINE
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _circle_style(diameter: float, alpha: float, pressed := false) -> StyleBoxFlat:
	## Estilo circular semitransparente para los botones del arco (Fase 3).
	var style := StyleBoxFlat.new()
	if pressed:
		style.bg_color = Color(COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b, alpha)
	else:
		style.bg_color = Color(0.08, 0.10, 0.13, alpha)
	style.border_color = COLOR_PANEL_LINE
	style.set_border_width_all(1)
	style.set_corner_radius_all(int(diameter * 0.5) - 1)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _accent_pressed_style() -> StyleBoxFlat:
	## Presionado con acento (semitransparente); evita repetir el color largo en cada botón.
	return _button_style(Color(COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b, 0.85))


func _make_bar(color: Color, height: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(240, height)
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(color.r, color.g, color.b, 0.9)
	fill.corner_radius_top_left = 4
	fill.corner_radius_bottom_left = 4
	fill.corner_radius_top_right = 4
	fill.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("fill", fill)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.06, 0.07, 0.09, 0.45)
	background.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", background)
	return bar


func get_root_control() -> Control:
	if get_child_count() > 0:
		return get_child(0) as Control
	var root := Control.new()
	root.name = "HUDRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	return root

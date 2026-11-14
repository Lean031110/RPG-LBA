class_name ArpgHUD
extends CanvasLayer
## HUD provisional de la vertical slice (tema gótico caribeño; el rediseño completo
## llega en el Art Pass + UX Pass de la Fase 1B). Lógica desacoplada: solo escucha
## señales del jugador/misiones y expone el vector del joystick. Sin lógica de juego.

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
const JOY_RADIUS := 92.0
const JOY_KNOB := 38.0

var _player: Node = null
var _joystick_vector := Vector2.ZERO
var _joy_center := Vector2.ZERO
var _joy_active := false

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
var _joystick: Control = null
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


func bind_player(player: Node) -> void:
	_player = player
	if player == null:
		return
	player.stats_changed.connect(_refresh_stats)
	player.leveled_up.connect(_on_leveled_up)
	_class_label.text = player.get_class_name()
	_resource_label.text = player.get_resource_name()
	_refresh_stats()


func is_dialog_open() -> bool:
	return _dialog_panel != null and _dialog_panel.visible


func get_joystick_vector() -> Vector2:
	return _joystick_vector


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
	var panel := PanelContainer.new()
	panel.name = "StatsPanel"
	panel.add_theme_stylebox_override("panel", _panel_style())
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
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
	var root := get_root_control()
	root.add_child(panel)
	panel.position = Vector2(16, 14)


func _build_quest_tracker() -> void:
	var panel := PanelContainer.new()
	panel.name = "QuestPanel"
	panel.add_theme_stylebox_override("panel", _panel_style())
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
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
	var root := get_root_control()
	root.add_child(panel)
	panel.position = Vector2(16, 132)


func _build_toast() -> void:
	_toast_label = Label.new()
	_toast_label.name = "Toast"
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.add_theme_font_size_override("font_size", 17)
	_toast_label.add_theme_color_override("font_color", COLOR_XP)
	_toast_label.modulate.a = 0.0
	_toast_label.custom_minimum_size = Vector2(0, 26)
	var root := get_root_control()
	root.add_child(_toast_label)
	_toast_label.position = Vector2(0, 84)
	_toast_label.size = Vector2(root.size.x, 30)


func _build_joystick() -> void:
	_joystick = Control.new()
	_joystick.name = "VirtualJoystick"
	_joystick.custom_minimum_size = Vector2(JOY_RADIUS * 2.0, JOY_RADIUS * 2.0)
	_joystick.size = Vector2(JOY_RADIUS * 2.0, JOY_RADIUS * 2.0)
	_joystick.draw.connect(_draw_joystick)
	var root := get_root_control()
	root.add_child(_joystick)
	_joy_center = Vector2(150.0, 0.0)
	_position_joystick()
	_joystick.gui_input.connect(_on_joystick_input)


func _position_joystick() -> void:
	var root := get_root_control()
	_joy_center = Vector2(150.0, root.size.y - 150.0)
	_joystick.position = _joy_center - Vector2(JOY_RADIUS, JOY_RADIUS)
	_joystick.size = Vector2(JOY_RADIUS * 2.0, JOY_RADIUS * 2.0)


func _draw_joystick() -> void:
	_joystick.draw_circle(Vector2(JOY_RADIUS, JOY_RADIUS), JOY_RADIUS, Color(0.08, 0.09, 0.12, 0.55))
	_joystick.draw_arc(Vector2(JOY_RADIUS, JOY_RADIUS), JOY_RADIUS - 3.0, 0.0, TAU, 40, COLOR_ACCENT, 2.0)
	var knob_offset := _joystick_vector * (JOY_RADIUS - JOY_KNOB)
	_joystick.draw_circle(Vector2(JOY_RADIUS, JOY_RADIUS) + knob_offset, JOY_KNOB, Color(0.16, 0.18, 0.24, 0.92))
	_joystick.draw_circle(Vector2(JOY_RADIUS, JOY_RADIUS) + knob_offset, JOY_KNOB - 4.0, COLOR_TEXT_DIM)


func _on_joystick_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_joy_active = true
		else:
			_joy_active = false
			_set_joystick(Vector2.ZERO)
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mouse := event as InputEventMouseButton
		if mouse.pressed:
			_joy_active = true
		else:
			_joy_active = false
			_set_joystick(Vector2.ZERO)
	elif event is InputEventScreenDrag and _joy_active:
		_set_joystick(_clamp_to_radius((event as InputEventScreenDrag).position - Vector2(JOY_RADIUS, JOY_RADIUS)))
	elif event is InputEventMouseMotion and _joy_active:
		_set_joystick(_clamp_to_radius(_joystick.get_local_mouse_position() - Vector2(JOY_RADIUS, JOY_RADIUS)))


func _clamp_to_radius(vector: Vector2) -> Vector2:
	if vector.length() > JOY_RADIUS - JOY_KNOB * 0.5:
		return vector.normalized() * (JOY_RADIUS - JOY_KNOB * 0.5)
	return vector


func _set_joystick(vector: Vector2) -> void:
	var normalized := vector / (JOY_RADIUS - JOY_KNOB * 0.5)
	_joystick_vector = normalized
	joystick_changed.emit(normalized)
	_joystick.queue_redraw()


func _build_action_buttons() -> void:
	var root := get_root_control()
	var cluster := VBoxContainer.new()
	cluster.name = "ActionCluster"
	cluster.add_theme_constant_override("separation", 10)
	root.add_child(cluster)
	var attack := _action_button("Machete (J)", "attack")
	var skill := _action_button("Tajo de Guásima (K)", "skill")
	var dodge := _action_button("Esquiva (Espacio)", "dodge")
	var potion := _action_button("Poción (Q)", "potion")
	_potion_badge = Label.new()
	_potion_badge.text = "x1"
	_potion_badge.add_theme_font_size_override("font_size", 12)
	_potion_badge.add_theme_color_override("font_color", COLOR_TEXT)
	potion.add_child(_potion_badge)
	_potion_badge.position = Vector2(96, 6)
	for button: Button in [attack, skill, dodge, potion]:
		cluster.add_child(button)
	cluster.position = Vector2(root.size.x - 240.0, root.size.y - 240.0)


func _action_button(text: String, action: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(216, 52)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.13, 0.15, 0.20, 0.94)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.18, 0.21, 0.28, 0.96)))
	button.add_theme_stylebox_override("pressed", _button_style(COLOR_ACCENT))
	button.pressed.connect(_on_action_pressed.bind(action))
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


func _build_interact_button() -> void:
	_interact_button = Button.new()
	_interact_button.name = "InteractButton"
	_interact_button.text = "Hablar (E)"
	_interact_button.visible = false
	_interact_button.custom_minimum_size = Vector2(180, 48)
	_interact_button.add_theme_font_size_override("font_size", 15)
	_interact_button.add_theme_color_override("font_color", COLOR_TEXT)
	_interact_button.add_theme_stylebox_override("normal", _button_style(Color(0.10, 0.16, 0.22, 0.95)))
	_interact_button.add_theme_stylebox_override("pressed", _button_style(COLOR_ACCENT))
	var root := get_root_control()
	root.add_child(_interact_button)
	_interact_button.position = Vector2(root.size.x / 2.0 - 90.0, root.size.y - 96.0)


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
	_dialog_action.pressed.connect(_dialog_next)
	box.add_child(_dialog_action)
	var root := get_root_control()
	root.add_child(_dialog_panel)
	_dialog_panel.custom_minimum_size = Vector2(600, 150)
	_dialog_panel.position = Vector2(root.size.x / 2.0 - 300.0, root.size.y - 210.0)


func _panel_style(margin := 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(COLOR_PANEL.r, COLOR_PANEL.g, COLOR_PANEL.b, 0.93)
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


func _make_bar(color: Color, height: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(240, height)
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.corner_radius_top_left = 4
	fill.corner_radius_bottom_left = 4
	fill.corner_radius_top_right = 4
	fill.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("fill", fill)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.06, 0.07, 0.09, 0.9)
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

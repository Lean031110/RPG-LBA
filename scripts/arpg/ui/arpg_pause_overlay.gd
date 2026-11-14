class_name ArpgPauseOverlay
extends CanvasLayer
## Menú de pausa de la rebanada. process_mode WHEN_PAUSED: sigue respondiendo con el
## árbol en pausa. Incluye ajustes rápidos (perfil y volumen) sin salir de la partida.

signal resume_requested
signal exit_requested

const EXIT_CONFIRM_TEXT := "¿Abandonar la partida? (Se guarda)"
const EXIT_TEXT := "Salir al menú"

var _root: Control
var _profile_option: OptionButton
var _exit_button: Button = null
var _exit_armed := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	layer = 40
	_build()


func open() -> void:
	visible = true
	_disarm_exit()
	_sync_profile_option()


func close() -> void:
	visible = false


func _on_exit_pressed() -> void:
	## Confirmación en dos pasos: la primera pulsación arma el aviso (no hay
	## abandono accidental de la partida); la segunda confirma.
	if not _exit_armed:
		_exit_armed = true
		_exit_button.text = EXIT_CONFIRM_TEXT
		_exit_button.modulate = Color(1.0, 0.75, 0.6)
		return
	exit_requested.emit()


func _disarm_exit() -> void:
	_exit_armed = false
	if _exit_button != null:
		_exit_button.text = EXIT_TEXT
		_exit_button.modulate = Color(1, 1, 1, 1)


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	_root.add_child(panel)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := ArpgUiTheme.make_title("Pausa", 26)
	box.add_child(title)
	var resume := _button("Reanudar")
	resume.pressed.connect(func() -> void: resume_requested.emit())
	box.add_child(resume)
	# Ajustes rápidos.
	var profile_row := HBoxContainer.new()
	box.add_child(profile_row)
	var profile_label := Label.new()
	profile_label.text = "Perfil gráfico"
	profile_label.add_theme_font_size_override("font_size", 14)
	profile_label.add_theme_color_override("font_color", Color("e8e4d8"))
	profile_row.add_child(profile_label)
	_profile_option = OptionButton.new()
	for pair: Array in [["low", "Bajo"], ["medium", "Medio"], ["high", "Alto"]]:
		_profile_option.add_item(String(pair[1]))
		_profile_option.set_item_metadata(_profile_option.item_count - 1, String(pair[0]))

		# Centrado por rect del viewport (iteración 4C: PRESET_CENTER puede
		# quedar pegado arriba-izquierda en Android).
	profile_row.add_child(_profile_option)
	_profile_option.item_selected.connect(_on_profile_selected)
	var dyn_row := HBoxContainer.new()
	box.add_child(dyn_row)
	var dyn_label := Label.new()
	dyn_label.text = "Resolución dinámica"
	dyn_label.add_theme_font_size_override("font_size", 14)
	dyn_label.add_theme_color_override("font_color", Color("e8e4d8"))
	dyn_row.add_child(dyn_label)
	var dyn_check := CheckButton.new()
	dyn_check.button_pressed = GraphicsSettings.dynamic_resolution
	dyn_check.toggled.connect(
		func(pressed: bool) -> void:
			GraphicsSettings.set_dynamic_resolution_enabled(pressed)
			GraphicsSettings.apply_profile(GraphicsSettings.active_profile)
			GraphicsSettings.persist_settings()
	)
	dyn_row.add_child(dyn_check)
	var volume_row := HBoxContainer.new()
	box.add_child(volume_row)
	var volume_label := Label.new()
	volume_label.text = "Volumen"
	volume_label.add_theme_font_size_override("font_size", 14)
	volume_label.add_theme_color_override("font_color", Color("e8e4d8"))
	volume_row.add_child(volume_label)
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = 1.0
	volume.custom_minimum_size = Vector2(180, 24)
	volume_row.add_child(volume)
	volume.value_changed.connect(_on_volume_changed)
	_exit_button = _button(EXIT_TEXT)
	_exit_button.pressed.connect(_on_exit_pressed)
	box.add_child(_exit_button)
	add_child(_root)
	# Centrado por rect del viewport (iteración 4C: PRESET_CENTER puede
	# quedar pegado arriba-izquierda en Android).
	_root.resized.connect(_recenter)
	get_viewport().connect("size_changed", _recenter)
	visible = false


func _recenter() -> void:
	ArpgUiTheme.center_in_viewport(_root.get_child(1) as Control)


func _sync_profile_option() -> void:
	match GraphicsSettings.active_profile:
		"medium":
			_profile_option.selected = 1
		"high":
			_profile_option.selected = 2
		_:
			_profile_option.selected = 0


func _on_profile_selected(index: int) -> void:
	var profile_id := String(_profile_option.get_item_metadata(index))
	GraphicsSettings.apply_profile(profile_id)
	GraphicsSettings.persist_settings()


func _on_volume_changed(value: float) -> void:
	GraphicsSettings.set_master_volume(value)
	GraphicsSettings.persist_settings({"master_volume": value})


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("arpg_pause"):
		resume_requested.emit()
		get_viewport().set_input_as_handled()


func _button(text: String) -> Button:
	return ArpgUiTheme.make_button(text, ArpgUiTheme.ButtonStyle.NORMAL, Vector2(280, 52))


func _panel_style() -> StyleBoxFlat:
	return ArpgUiTheme.panel_style()

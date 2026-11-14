class_name ArpgSettingsMenu
extends Control
## Ajustes de la vertical slice: perfil gráfico y volumen. Controles completos,
## accesibilidad y más categorías llegan con el UX Pass (Fase 1B) y fases posteriores.


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.04, 0.05, 0.07)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var title := Label.new()
	title.text = "Ajustes"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("b08d3c"))
	box.add_child(title)
	# Perfil gráfico.
	var profile_row := HBoxContainer.new()
	box.add_child(profile_row)
	_add_spacer(profile_row, 12)
	var profile_label := Label.new()
	profile_label.text = "Perfil gráfico"
	profile_label.custom_minimum_size = Vector2(160, 0)
	profile_label.add_theme_font_size_override("font_size", 15)
	profile_label.add_theme_color_override("font_color", Color("e8e4d8"))
	profile_row.add_child(profile_label)
	var option := OptionButton.new()
	for pair: Array in [["low", "Bajo"], ["medium", "Medio"], ["high", "Alto"]]:
		option.add_item(String(pair[1]))
		option.set_item_metadata(option.item_count - 1, String(pair[0]))
	option.selected = _profile_index()
	option.item_selected.connect(_on_profile_selected.bind(option))
	profile_row.add_child(option)
	_add_spacer(profile_row, 12)
	var profile_note := Label.new()
	profile_note.text = (
		"El perfil Bajo es la referencia de diseño. No se promete FPS ni compatibilidad Android"
		+ " sin medir en hardware real."
	)
	profile_note.add_theme_font_size_override("font_size", 12)
	profile_note.add_theme_color_override("font_color", Color("9aa0a6"))
	profile_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profile_note.custom_minimum_size = Vector2(460, 0)
	box.add_child(profile_note)
	# Volumen.
	var volume_row := HBoxContainer.new()
	box.add_child(volume_row)
	_add_spacer(volume_row, 12)
	var volume_label := Label.new()
	volume_label.text = "Volumen general"
	volume_label.custom_minimum_size = Vector2(160, 0)
	volume_label.add_theme_font_size_override("font_size", 15)
	volume_label.add_theme_color_override("font_color", Color("e8e4d8"))
	volume_row.add_child(volume_label)
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = GraphicsSettings.last_master_volume
	volume.custom_minimum_size = Vector2(240, 28)
	volume.value_changed.connect(_on_volume_changed)
	volume_row.add_child(volume)
	_add_spacer(volume_row, 12)
	var back := _button("Volver")
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/arpg/menu/main_menu.tscn"))
	box.add_child(back)


func _profile_index() -> int:
	match GraphicsSettings.active_profile:
		"medium":
			return 1
		"high":
			return 2
		_:
			return 0


func _on_profile_selected(index: int, option: OptionButton) -> void:
	var profile_id := String(option.get_item_metadata(index))
	GraphicsSettings.apply_profile(profile_id)
	GraphicsSettings.persist_settings()


func _on_volume_changed(value: float) -> void:
	GraphicsSettings.set_master_volume(value)
	GraphicsSettings.persist_settings({"master_volume": value})


func _add_spacer(row: HBoxContainer, width: int) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(width, 0)
	row.add_child(spacer)


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(240, 52)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color("e8e4d8"))
	button.add_theme_stylebox_override("normal", _flat(Color(0.13, 0.15, 0.2, 0.96)))
	button.add_theme_stylebox_override("hover", _flat(Color(0.18, 0.21, 0.28, 0.98)))
	button.add_theme_stylebox_override("pressed", _flat(Color("1e3a4a")))
	return button


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.12, 0.98)
	style.border_color = Color("2a2e38")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	return style


func _flat(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color("2a2e38")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style

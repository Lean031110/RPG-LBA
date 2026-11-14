class_name ArpgSettingsMenu
extends Control
## Ajustes de RPG-LBA con el lenguaje visual compartido (iteración 4C):
## perfil gráfico, resolución dinámica y volumen. El perfil inicial lo sugiere
## la matriz de compatibilidad (docs/16) según el hardware detectado; el
## usuario puede cambiarlo aquí y persiste (user://settings.json).


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ArpgBackdrop.new(0.62))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", ArpgUiTheme.panel_style())
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.custom_minimum_size = Vector2(520, 0)
	panel.add_child(box)
	var title := ArpgUiTheme.make_title("Ajustes", 30)
	box.add_child(title)
	_add_hardware_report(box)
	_add_profile_row(box)
	_add_dynamic_resolution_row(box)
	_add_volume_row(box)
	var back := ArpgUiTheme.make_button("Volver", ArpgUiTheme.ButtonStyle.NORMAL, Vector2(240, 52))
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/arpg/menu/main_menu.tscn"))
	box.add_child(back)
	panel.resized.connect(func() -> void: ArpgUiTheme.center_in_viewport(panel))
	box.sort_children.connect(func() -> void: ArpgUiTheme.center_in_viewport(panel))
	get_viewport().connect("size_changed", func() -> void: ArpgUiTheme.center_in_viewport(panel))
	ArpgUiTheme.center_in_viewport(panel)


func _add_hardware_report(box: VBoxContainer) -> void:
	## Información de hardware detectado y perfil sugerido (matriz docs/16).
	var hw := GraphicsSettings.hardware_report
	var hw_lines: Array = [
		"Dispositivo: %s" % String(hw.get("model", "?")),
		(
			"GPU: %s · RAM: %.1f GB · Pantalla: %d px"
			% [
				String(hw.get("gpu", "?")),
				float(hw.get("ram_total_gb", 0.0)),
				int(hw.get("screen_long_px", 0)),
			]
		),
	]
	if String(hw.get("platform", "")) == "Android":
		hw_lines.append(
			"Android API %s · ABI: %s" % [str(hw.get("api_level", "?")), str(hw.get("abis", [])).substr(1, 40)]
		)
	hw_lines.append("Perfil sugerido: %s (cambiable abajo; se recuerda)." % GraphicsSettings.suggested_profile)
	for line: String in hw_lines:
		var hw_label := ArpgUiTheme.make_dim(line, 12)
		hw_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		hw_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hw_label.custom_minimum_size = Vector2(470, 0)
		box.add_child(hw_label)


func _add_profile_row(box: VBoxContainer) -> void:
	# Perfil gráfico.
	var profile_row := HBoxContainer.new()
	profile_row.add_theme_constant_override("separation", 12)
	box.add_child(profile_row)
	var profile_label := _row_label("Perfil gráfico")
	profile_row.add_child(profile_label)
	var option := OptionButton.new()
	for pair: Array in [["low", "Bajo"], ["medium", "Medio"], ["high", "Alto"]]:
		option.add_item(String(pair[1]))
		option.set_item_metadata(option.item_count - 1, String(pair[0]))
	option.selected = _profile_index()
	option.item_selected.connect(_on_profile_selected.bind(option))
	option.custom_minimum_size = Vector2(180, 40)
	profile_row.add_child(option)
	var profile_note := ArpgUiTheme.make_dim(
		"El perfil Bajo es la referencia de diseño. Sin promesas de FPS sin medir en hardware real (AGENTS.md §7)."
	)
	profile_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profile_note.custom_minimum_size = Vector2(470, 0)
	box.add_child(profile_note)


func _add_dynamic_resolution_row(box: VBoxContainer) -> void:
	# Resolución dinámica.
	var dyn_row := HBoxContainer.new()
	dyn_row.add_theme_constant_override("separation", 12)
	box.add_child(dyn_row)
	dyn_row.add_child(_row_label("Resolución dinámica"))
	var dyn_check := CheckButton.new()
	dyn_check.button_pressed = GraphicsSettings.dynamic_resolution
	dyn_check.toggled.connect(_on_dynamic_resolution_toggled)
	dyn_row.add_child(dyn_check)
	var dyn_note := ArpgUiTheme.make_dim("Ajusta la escala de render dentro de la ventana del perfil con histéresis.")
	dyn_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dyn_note.custom_minimum_size = Vector2(470, 0)
	box.add_child(dyn_note)


func _add_volume_row(box: VBoxContainer) -> void:
	# Volumen general.
	var volume_row := HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 12)
	box.add_child(volume_row)
	volume_row.add_child(_row_label("Volumen general"))
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = GraphicsSettings.last_master_volume
	volume.custom_minimum_size = Vector2(260, 28)
	volume.value_changed.connect(_on_volume_changed)
	volume_row.add_child(volume)


func _row_label(text: String) -> Label:
	var label := ArpgUiTheme.make_body(text, 15)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.custom_minimum_size = Vector2(200, 0)
	return label


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


func _on_dynamic_resolution_toggled(pressed: bool) -> void:
	GraphicsSettings.set_dynamic_resolution_enabled(pressed)
	GraphicsSettings.apply_profile(GraphicsSettings.active_profile)
	GraphicsSettings.persist_settings()


func _on_volume_changed(value: float) -> void:
	GraphicsSettings.set_master_volume(value)
	GraphicsSettings.persist_settings({"master_volume": value})

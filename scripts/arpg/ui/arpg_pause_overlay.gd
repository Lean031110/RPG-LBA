class_name ArpgPauseOverlay
extends CanvasLayer
## Menú de pausa de la rebanada. process_mode WHEN_PAUSED: sigue respondiendo con el
## árbol en pausa. Incluye ajustes rápidos (perfil y volumen) sin salir de la partida.

signal resume_requested
signal exit_requested

var _root: Control
var _profile_option: OptionButton


func _ready() -> void:
        process_mode = Node.PROCESS_MODE_WHEN_PAUSED
        layer = 40
        _build()


func open() -> void:
        visible = true
        _sync_profile_option()


func close() -> void:
        visible = false


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
        var title := Label.new()
        title.text = "Pausa"
        title.add_theme_font_size_override("font_size", 24)
        title.add_theme_color_override("font_color", Color("b08d3c"))
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
        var exit := _button("Salir al menú")
        exit.pressed.connect(func() -> void: exit_requested.emit())
        box.add_child(exit)
        add_child(_root)
        visible = false


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
        var button := Button.new()
        button.text = text
        button.custom_minimum_size = Vector2(280, 52)
        button.add_theme_font_size_override("font_size", 16)
        button.add_theme_color_override("font_color", Color("e8e4d8"))
        button.add_theme_stylebox_override("normal", _flat(Color(0.13, 0.15, 0.2, 0.96)))
        button.add_theme_stylebox_override("hover", _flat(Color(0.18, 0.21, 0.28, 0.98)))
        button.add_theme_stylebox_override("pressed", _flat(Color("1e3a4a")))
        return button


func _panel_style() -> StyleBoxFlat:
        var style := StyleBoxFlat.new()
        style.bg_color = Color(0.08, 0.09, 0.12, 0.97)
        style.border_color = Color("2a2e38")
        style.set_border_width_all(1)
        style.set_corner_radius_all(8)
        style.content_margin_left = 22
        style.content_margin_right = 22
        style.content_margin_top = 18
        style.content_margin_bottom = 18
        return style


func _flat(bg: Color) -> StyleBoxFlat:
        var style := StyleBoxFlat.new()
        style.bg_color = bg
        style.border_color = Color("2a2e38")
        style.set_border_width_all(1)
        style.set_corner_radius_all(6)
        return style

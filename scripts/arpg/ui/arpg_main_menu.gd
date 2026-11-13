class_name ArpgMainMenu
extends Control
## Menú principal de la vertical slice (prompt 01: Jugar/Ajustes/Créditos + Continuar).
## UI provisional; el rediseño visual completo llega en el Art Pass + UX Pass (Fase 1B).

const LOGO_PATH := "res://assets/branding/rpg-lba-logo.svg"

var _logo: TextureRect = null
var _subtitle: Label = null
var _button_box: VBoxContainer = null
var _footer: Label = null


func _ready() -> void:
        set_anchors_preset(Control.PRESET_FULL_RECT)
        _build_background()
        _build_title()
        _build_buttons()
        _build_footer()
        # Android: `size` vale (0,0) durante _ready y el menu quedaba pegado al
        # borde izquierdo (corrida 43482533022). El await no sirvio (la escena se
        # quedaba en el color de clearance; corridas 43484656222+). Patron del HUD,
        # probado desde Fase 3: re-layout cuando llega el tamano real (resized).
        resized.connect(_relayout)
        get_viewport().connect("size_changed", _relayout)
        _relayout()
        if OS.is_debug_build():
                print("ArpgMainMenu: ready size=%s viewport=%s" % [size, get_viewport().get_visible_rect().size])


func _relayout() -> void:
        ## Recoloca las piezas posicionadas a mano. Fuente de tamano: el RECT
        ## DEL VIEWPORT (disponible ya en _ready: 1280x720 en el emulador;
        ## corrida 43491990194: size=(0,0) para siempre y `resized` jamas disparo).
        ## Las ancladas (fondo, franja, panel de clase PRESET_CENTER) se ajustan solas.
        var vs := get_viewport().get_visible_rect().size
        if vs.x < 1.0 or vs.y < 1.0:
                return
        if _logo != null:
                _logo.position = Vector2(vs.x / 2.0 - 320.0, 56.0)
        if _subtitle != null:
                _subtitle.position = Vector2(0, 252.0)
                _subtitle.size = Vector2(vs.x, 26)
        if _button_box != null:
                _button_box.position = Vector2(vs.x / 2.0 - 150.0, 330.0)
        if _footer != null:
                _footer.position = Vector2(16.0, vs.y - 64.0)
                _footer.size = Vector2(vs.x - 32.0, 34)
        if OS.is_debug_build():
                print("ArpgMainMenu: relayout viewport=%s control_size=%s" % [vs, size])


func _build_background() -> void:
        var background := ColorRect.new()
        background.color = Color(0.04, 0.05, 0.07)
        background.set_anchors_preset(Control.PRESET_FULL_RECT)
        add_child(background)
        # Franja inferior azul petróleo: composición sobria, no decoración gratuita.
        var band := ColorRect.new()
        band.color = Color(0.10, 0.18, 0.24)
        band.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
        band.offset_top = -84.0
        add_child(band)


func _build_title() -> void:
        var texture: Texture2D = load(LOGO_PATH) as Texture2D
        if texture != null:
                var logo := TextureRect.new()
                logo.texture = texture
                logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                logo.custom_minimum_size = Vector2(640, 190)
                logo.position = Vector2(size.x / 2.0 - 320.0, 56.0)
                add_child(logo)
                _logo = logo
        var subtitle := Label.new()
        subtitle.text = "Cuba ficticia, 1953 · Una isla viva. Un mal antiguo. Una historia que todavía no termina."
        subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        subtitle.add_theme_font_size_override("font_size", 15)
        subtitle.add_theme_color_override("font_color", Color("9aa0a6"))
        subtitle.position = Vector2(0, 252.0)
        subtitle.size = Vector2(size.x, 26)
        add_child(subtitle)
        _subtitle = subtitle


func _build_buttons() -> void:
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 12)
        add_child(box)
        box.position = Vector2(size.x / 2.0 - 150.0, 330.0)
        _button_box = box
        var continue_button := _menu_button("Continuar")
        continue_button.disabled = not SaveSystem.has_save()
        continue_button.pressed.connect(_on_continue_pressed)
        box.add_child(continue_button)
        var new_game := _menu_button("Nueva partida")
        new_game.pressed.connect(_on_new_game_pressed)
        box.add_child(new_game)
        var prototype := _menu_button("Prototipo (Fase 2)")
        prototype.pressed.connect(
                func() -> void: get_tree().change_scene_to_file("res://scenes/arpg/prototype/prototype_ground.tscn")
        )
        box.add_child(prototype)
        var settings := _menu_button("Ajustes")
        settings.pressed.connect(
                func() -> void: get_tree().change_scene_to_file("res://scenes/arpg/menu/settings_menu.tscn")
        )
        box.add_child(settings)
        var credits := _menu_button("Créditos")
        credits.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/arpg/menu/credits_menu.tscn"))
        box.add_child(credits)
        var quit := _menu_button("Salir")
        quit.pressed.connect(func() -> void: get_tree().quit())
        box.add_child(quit)


func _build_footer() -> void:
        var footer := Label.new()
        footer.text = "Vertical slice — Fase 1 · Prototipo — Fase 2 · Preparativos — Fase 3 · Compatibilidad Android — Fase 4A · Godot 4.7.2 · Compatibility Renderer"
        footer.add_theme_font_size_override("font_size", 12)
        footer.add_theme_color_override("font_color", Color("6f757b"))
        footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        footer.position = Vector2(16.0, size.y - 64.0)
        footer.size = Vector2(size.x - 32.0, 34)
        add_child(footer)
        _footer = footer


func _on_new_game_pressed() -> void:
        ## Confirmación de clase: en la rebanada solo el Machetero es jugable (Fase 2: seis).
        var panel := PanelContainer.new()
        panel.add_theme_stylebox_override("panel", _panel_style())
        add_child(panel)
        panel.set_anchors_preset(Control.PRESET_CENTER)
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        panel.add_child(box)
        var title := Label.new()
        title.text = "Machetero de la Sierra"
        title.add_theme_font_size_override("font_size", 22)
        title.add_theme_color_override("font_color", Color("b08d3c"))
        box.add_child(title)
        var role := Label.new()
        role.text = RpgDB.get_text("class.machetero.role")
        role.add_theme_font_size_override("font_size", 14)
        role.add_theme_color_override("font_color", Color("e8e4d8"))
        role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        role.custom_minimum_size = Vector2(420, 0)
        box.add_child(role)
        var note := Label.new()
        note.text = (
                "Única clase jugable en la vertical slice. Las seis clases completas llegan en Fase 2"
                + " con sus recursos, habilidades y especializaciones."
        )
        note.add_theme_font_size_override("font_size", 12)
        note.add_theme_color_override("font_color", Color("9aa0a6"))
        note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        note.custom_minimum_size = Vector2(420, 0)
        box.add_child(note)
        var actions := HBoxContainer.new()
        box.add_child(actions)
        var play := _menu_button("Jugar")
        play.pressed.connect(
                func() -> void:
                        SliceRun.request_new_game()
                        get_tree().change_scene_to_file("res://scenes/arpg/valdeluz/valdeluz_slice.tscn")
        )
        actions.add_child(play)
        var back := _menu_button("Volver")
        back.pressed.connect(func() -> void: panel.queue_free())
        actions.add_child(back)


func _on_continue_pressed() -> void:
        var record := SaveSystem.load_game()
        if record.is_empty():
                return
        SliceRun.request_continue(record)
        get_tree().change_scene_to_file("res://scenes/arpg/valdeluz/valdeluz_slice.tscn")


func _menu_button(text: String) -> Button:
        var button := Button.new()
        button.text = text
        button.custom_minimum_size = Vector2(300, 54)
        button.add_theme_font_size_override("font_size", 17)
        button.add_theme_color_override("font_color", Color("e8e4d8"))
        button.add_theme_stylebox_override("normal", _flat(Color(0.13, 0.15, 0.2, 0.96)))
        button.add_theme_stylebox_override("hover", _flat(Color(0.18, 0.21, 0.28, 0.98)))
        button.add_theme_stylebox_override("pressed", _flat(Color("1e3a4a")))
        button.add_theme_stylebox_override("disabled", _flat(Color(0.08, 0.09, 0.11, 0.9)))
        return button


func _panel_style() -> StyleBoxFlat:
        var style := StyleBoxFlat.new()
        style.bg_color = Color(0.08, 0.09, 0.12, 0.98)
        style.border_color = Color("2a2e38")
        style.set_border_width_all(1)
        style.set_corner_radius_all(8)
        style.content_margin_left = 24
        style.content_margin_right = 24
        style.content_margin_top = 20
        style.content_margin_bottom = 20
        return style


func _flat(bg: Color) -> StyleBoxFlat:
        var style := StyleBoxFlat.new()
        style.bg_color = bg
        style.border_color = Color("2a2e38")
        style.set_border_width_all(1)
        style.set_corner_radius_all(6)
        return style

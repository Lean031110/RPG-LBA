class_name ArpgMainMenu
extends Control
## Menú principal rediseñado (iteración visual 4C): fondo cinematográfico
## compartido (ArpgBackdrop), emblema oficial con halo, columna de botones con
## jerarquía (continuar/nueva partida/multijugador destacados), pie con versión
## y estudio, y transición con fundido hacia cualquier pantalla.
##
## Contratos que se mantienen (CI + measure_menu_layout.gd):
##   - Botones con texto exacto: "Nueva partida", "Prototipo (Fase 2)", "Jugar".
##   - Método _on_new_game_pressed() que abre el panel de clase.
##   - Re-layout por rect del viewport (patrón probado en Android desde Fase 3).

const PROTOTYPE_SCENE := "res://scenes/arpg/prototype/prototype_ground.tscn"
const SETTINGS_SCENE := "res://scenes/arpg/menu/settings_menu.tscn"
const CREDITS_SCENE := "res://scenes/arpg/menu/credits_menu.tscn"
const MULTIPLAYER_SCENE := "res://scenes/arpg/menu/multiplayer_menu.tscn"
const FADE_SECONDS := 0.32

var _logo_block: Control = null
var _tagline: Label = null
var _button_box: VBoxContainer = null
var _footer_left: Label = null
var _footer_right: Label = null
var _class_panel: PanelContainer = null
var _fading := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ArpgBackdrop.new())
	_build_logo()
	_build_tagline()
	_build_buttons()
	_build_footer()
	resized.connect(_relayout)
	get_viewport().connect("size_changed", _relayout)
	_relayout()
	_animate_in()


func _relayout() -> void:
	## Recoloca según el RECT DEL VIEWPORT (en Android el Control del menú puede
	## quedarse a (0,0); corrida 43491990194). Las piezas ancladas se ajustan solas.
	var vs := get_viewport().get_visible_rect().size
	if vs.x < 1.0 or vs.y < 1.0:
		return
	if _logo_block != null:
		_logo_block.position = Vector2(0, 30)
	if _tagline != null:
		_tagline.position = Vector2(0, 224)
	if _button_box != null:
		var box_width := _button_box.get_combined_minimum_size().x
		_button_box.position = Vector2(vs.x / 2.0 - box_width / 2.0, 268)
	if _footer_left != null:
		_footer_left.position = Vector2(18, vs.y - 30)
	if _footer_right != null:
		_footer_right.position = Vector2(vs.x - 358, vs.y - 30)
	if _class_panel != null:
		ArpgUiTheme.center_in_viewport(_class_panel)


func _build_logo() -> void:
	_logo_block = Control.new()
	_logo_block.name = "LogoBlock"
	_logo_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo_block.position = Vector2(0, 30)
	add_child(_logo_block)
	var glow := TextureRect.new()
	glow.texture = ArpgUiTheme.radial_glow(Color(1.0, 0.66, 0.3, 0.3), 0.6)
	glow.size = Vector2(820, 400)
	glow.position = Vector2(230, -40)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo_block.add_child(glow)
	var logo := ArpgUiTheme.logo_texture(540.0)
	logo.position = Vector2(370, 22)
	_logo_block.add_child(logo)


func _build_tagline() -> void:
	_tagline = ArpgUiTheme.make_body(
		"Cuba ficticia, 1953 · Una isla viva. Un mal antiguo. Una historia que no termina.", 15, Color("b7ae97")
	)
	_tagline.position = Vector2(0, 224)
	_tagline.size = Vector2(1280, 24)
	_tagline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tagline)


func _build_buttons() -> void:
	_button_box = VBoxContainer.new()
	_button_box.add_theme_constant_override("separation", 9)
	_button_box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_button_box)

	var continue_button := ArpgUiTheme.make_button("Continuar", ArpgUiTheme.ButtonStyle.PRIMARY, Vector2(380, 54))
	continue_button.disabled = not SaveSystem.has_save()
	continue_button.pressed.connect(_on_continue_pressed)
	_button_box.add_child(continue_button)

	var new_game := ArpgUiTheme.make_button("Nueva partida", ArpgUiTheme.ButtonStyle.PRIMARY, Vector2(380, 54))
	new_game.pressed.connect(_on_new_game_pressed)
	_button_box.add_child(new_game)

	var multiplayer := ArpgUiTheme.make_button("MULTIJUGADOR", ArpgUiTheme.ButtonStyle.PRIMARY, Vector2(380, 54))
	multiplayer.pressed.connect(func() -> void: _goto(MULTIPLAYER_SCENE))
	_button_box.add_child(multiplayer)

	var settings := ArpgUiTheme.make_button("Ajustes", ArpgUiTheme.ButtonStyle.NORMAL, Vector2(380, 48))
	settings.pressed.connect(func() -> void: _goto(SETTINGS_SCENE))
	_button_box.add_child(settings)

	var credits := ArpgUiTheme.make_button("Créditos", ArpgUiTheme.ButtonStyle.NORMAL, Vector2(380, 48))
	credits.pressed.connect(func() -> void: _goto(CREDITS_SCENE))
	_button_box.add_child(credits)

	var quit := ArpgUiTheme.make_button("Salir", ArpgUiTheme.ButtonStyle.DANGER, Vector2(380, 48))
	quit.pressed.connect(func() -> void: get_tree().quit())
	_button_box.add_child(quit)


func _build_footer() -> void:
	_footer_left = ArpgUiTheme.make_dim("v0.1.1 · Las Cenizas de Lythara — Fase 4C", 12)
	_footer_left.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_footer_left.position = Vector2(18, 690)
	_footer_left.size = Vector2(420, 20)
	_footer_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_footer_left)
	_footer_right = ArpgUiTheme.make_dim("LBA Games · Godot 4.7.2 · Compatibility", 12)
	_footer_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_footer_right.position = Vector2(860, 690)
	_footer_right.size = Vector2(400, 20)
	_footer_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_footer_right)


func _animate_in() -> void:
	## Aparición del menú: emblema primero, botones en cascada discreta.
	_logo_block.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_logo_block, "modulate:a", 1.0, 0.5)
	var index := 0
	for child: Node in _button_box.get_children():
		if child is Control:
			(child as Control).modulate.a = 0.0
			var delay := 0.12 + index * 0.06
			tween.tween_property(child, "modulate:a", 1.0, 0.3).set_delay(delay)
		index += 1


func _goto(scene_path: String) -> void:
	## Transición con fundido a negro hacia cualquier pantalla del juego.
	if _fading:
		return
	_fading = true
	var curtain := ColorRect.new()
	curtain.color = Color(0, 0, 0, 0)
	curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(curtain)
	var tween := create_tween()
	tween.tween_property(curtain, "color:a", 1.0, FADE_SECONDS)
	tween.tween_callback(func() -> void: get_tree().change_scene_to_file(scene_path))


func _on_new_game_pressed() -> void:
	## Confirmación de clase: en la rebanada solo el Machetero es jugable.
	if _class_panel != null and is_instance_valid(_class_panel):
		_class_panel.queue_free()
	_class_panel = PanelContainer.new()
	_class_panel.add_theme_stylebox_override("panel", ArpgUiTheme.panel_style())
	add_child(_class_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.custom_minimum_size = Vector2(470, 0)
	_class_panel.add_child(box)

	var title := ArpgUiTheme.make_title("Machetero de la Sierra", 26)
	box.add_child(title)
	var role := ArpgUiTheme.make_body(RpgDB.get_text("class.machetero.role"), 15)
	role.custom_minimum_size = Vector2(430, 0)
	box.add_child(role)
	var stats := ArpgUiTheme.make_dim("Vitalidad alta · Vigor · Combate cuerpo a cuerpo con machete", 13)
	box.add_child(stats)
	var note := ArpgUiTheme.make_dim(
		"Única clase jugable de la vertical slice. Las seis clases completas llegan en la Fase 2.", 12
	)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(430, 0)
	box.add_child(note)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(actions)
	var play := ArpgUiTheme.make_button("Jugar", ArpgUiTheme.ButtonStyle.PRIMARY, Vector2(180, 52))
	play.pressed.connect(
		func() -> void:
			SliceRun.request_new_game()
			get_tree().change_scene_to_file("res://scenes/arpg/valdeluz/valdeluz_slice.tscn")
	)
	actions.add_child(play)
	var back := ArpgUiTheme.make_button("Volver", ArpgUiTheme.ButtonStyle.NORMAL, Vector2(150, 52))
	back.pressed.connect(func() -> void: _class_panel.queue_free())
	actions.add_child(back)

	# Centrado continuo: el panel se recentra cuando su tamaño se asienta
	# (los Labels con autowrap calculan su alto con un frame de retraso; el
	# `sort_children` del VBox avisa cada reorden interno, no solo el resized).
	_class_panel.resized.connect(_recenter_class_panel)
	box.sort_children.connect(_recenter_class_panel)
	get_viewport().connect("size_changed", _recenter_class_panel)
	_recenter_class_panel()


func _recenter_class_panel() -> void:
	if _class_panel != null and is_instance_valid(_class_panel):
		ArpgUiTheme.center_in_viewport(_class_panel)


func _on_continue_pressed() -> void:
	var record := SaveSystem.load_game()
	if record.is_empty():
		return
	SliceRun.request_continue(record)
	get_tree().change_scene_to_file("res://scenes/arpg/valdeluz/valdeluz_slice.tscn")

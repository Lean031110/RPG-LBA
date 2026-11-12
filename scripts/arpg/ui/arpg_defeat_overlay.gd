class_name ArpgDefeatOverlay
extends CanvasLayer
## Panel de derrota de la rebanada. Sin procesar pausa: se muestra sobre la partida viva.

signal retry_requested
signal menu_requested

var _root: Control


func _ready() -> void:
	layer = 50
	_build()
	visible = false


func open() -> void:
	visible = true


func close() -> void:
	visible = false


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.01, 0.02, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _flat_panel())
	_root.add_child(panel)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var title := Label.new()
	title.text = "Las sombras te cubrieron"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("e0503e"))
	box.add_child(title)
	var body := Label.new()
	body.text = "El eco de Valdeluz todavía puede oírse. Cheo espera en el portal."
	body.add_theme_font_size_override("font_size", 15)
	body.add_theme_color_override("font_color", Color("9aa0a6"))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(380, 0)
	box.add_child(body)
	var retry := _button("Reintentar")
	retry.pressed.connect(func() -> void: retry_requested.emit())
	box.add_child(retry)
	var menu := _button("Al menú")
	menu.pressed.connect(func() -> void: menu_requested.emit())
	box.add_child(menu)
	add_child(_root)


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


func _flat(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color("2a2e38")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style


func _flat_panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.12, 0.97)
	style.border_color = Color("2a2e38")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	return style

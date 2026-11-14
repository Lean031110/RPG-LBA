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
	var title := ArpgUiTheme.make_title("Las sombras te cubrieron", 26, ArpgUiTheme.EMBER)
	box.add_child(title)
	var body := ArpgUiTheme.make_dim("El eco de Valdeluz todavía puede oírse. Cheo espera en el portal.")
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
	_root.resized.connect(_recenter)
	get_viewport().connect("size_changed", _recenter)


func _recenter() -> void:
	ArpgUiTheme.center_in_viewport(_root.get_child(1) as Control)


func _button(text: String) -> Button:
	return ArpgUiTheme.make_button(text, ArpgUiTheme.ButtonStyle.NORMAL, Vector2(240, 52))


func _flat_panel() -> StyleBoxFlat:
	return ArpgUiTheme.panel_style()

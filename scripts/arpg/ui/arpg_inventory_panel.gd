class_name ArpgInventoryPanel
extends Control
## Panel de inventario ARPG (preparativos Fase 3): semitransparente, muestra el arma
## equipada y la rejilla del inventario propio del jugador. Sin lógica de juego:
## equipar/desequipar delega en el jugador (señal->método público), como el resto del HUD.
## Las pociones siguen en el contador rápido de la rebanada (decisión documentada).

signal open_changed(is_open: bool)

const COLOR_PANEL := Color("14161c")
const COLOR_PANEL_LINE := Color("2a2e38")
const COLOR_TEXT := Color("e8e4d8")
const COLOR_TEXT_DIM := Color("9aa0a6")
const COLOR_ACCENT := Color("1e3a4a")
const COLOR_GOLD := Color("b08d3c")
const PANEL_ALPHA := 0.42
const BUTTON_ALPHA := 0.35
const SLOT_SIZE := 56
const GRID_COLUMNS := 8

const ICON_MACHETE: Texture2D = preload("res://assets/ui/icons/attack.png")
const ICON_FRAGMENT: Texture2D = preload("res://assets/ui/icons/fragment.png")
const ICON_POTION: Texture2D = preload("res://assets/ui/icons/potion.png")

var _player: ArpgPlayer = null
var _panel: PanelContainer = null
var _equipped_icon: TextureRect = null
var _equipped_name: Label = null
var _equipped_bonus: Label = null
var _equipped_slot_button: Button = null
var _grid: GridContainer = null
var _slot_buttons: Array[Button] = []


static func icon_for_item(item_id: String) -> Texture2D:
	## Icono por defecto para los objetos conocidos de la rebanada (machete/fragmento/poción).
	match item_id:
		"machete_mellado":
			return ICON_MACHETE
		"fragmento_bronce":
			return ICON_FRAGMENT
		"pocion_curativa":
			return ICON_POTION
	return null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	visible = false


func bind_player(player: ArpgPlayer) -> void:
	_player = player


func is_open() -> bool:
	return visible


func open() -> void:
	visible = true
	_refresh()
	open_changed.emit(true)


func close() -> void:
	visible = false
	open_changed.emit(false)


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.name = "InventoryPanelBox"
	_panel.custom_minimum_size = Vector2(560, 0)
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_theme_stylebox_override("panel", _panel_style())
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_panel.add_child(box)
	box.add_child(_build_title_row())
	box.add_child(_build_equipped_row())
	_grid = GridContainer.new()
	_grid.name = "InventoryGrid"
	_grid.columns = GRID_COLUMNS
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	box.add_child(_grid)
	_build_slots()
	custom_minimum_size = _panel.get_combined_minimum_size()


func _build_title_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var title := Label.new()
	title.name = "Title"
	title.text = "Mochila"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", COLOR_GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "Cerrar (I)"
	close_button.add_theme_font_size_override("font_size", 13)
	close_button.add_theme_color_override("font_color", COLOR_TEXT)
	close_button.add_theme_stylebox_override("normal", _button_style(BUTTON_ALPHA))
	close_button.add_theme_stylebox_override("hover", _button_style(BUTTON_ALPHA + 0.2))
	close_button.add_theme_stylebox_override("pressed", _button_style(0.8))
	close_button.pressed.connect(close)
	row.add_child(close_button)
	return row


func _build_equipped_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_equipped_slot_button = Button.new()
	_equipped_slot_button.name = "EquippedSlot"
	_equipped_slot_button.custom_minimum_size = Vector2(64, 64)
	_equipped_slot_button.add_theme_stylebox_override("normal", _button_style(BUTTON_ALPHA))
	_equipped_slot_button.add_theme_stylebox_override("hover", _button_style(BUTTON_ALPHA + 0.2))
	_equipped_slot_button.add_theme_stylebox_override("pressed", _button_style(0.8))
	_equipped_slot_button.pressed.connect(_on_unequip_pressed)
	row.add_child(_equipped_slot_button)
	_equipped_icon = TextureRect.new()
	_equipped_icon.name = "EquippedIcon"
	_equipped_icon.custom_minimum_size = Vector2(44, 44)
	_equipped_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_equipped_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_equipped_icon.modulate = Color(1, 1, 1, 0.95)
	_equipped_slot_button.add_child(_equipped_icon)
	_equipped_icon.set_anchors_preset(Control.PRESET_CENTER)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)
	_equipped_name = Label.new()
	_equipped_name.name = "EquippedName"
	_equipped_name.text = "Sin arma equipada"
	_equipped_name.add_theme_font_size_override("font_size", 15)
	_equipped_name.add_theme_color_override("font_color", COLOR_TEXT)
	info.add_child(_equipped_name)
	_equipped_bonus = Label.new()
	_equipped_bonus.name = "EquippedBonus"
	_equipped_bonus.text = "Toca un arma de la mochila para equiparla"
	_equipped_bonus.add_theme_font_size_override("font_size", 12)
	_equipped_bonus.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	info.add_child(_equipped_bonus)
	var hint := Label.new()
	hint.text = "Desequipar: toca el arma"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	info.add_child(hint)
	return row


func _build_slots() -> void:
	for index: int in PlayerInventory.MAX_INVENTORY_SIZE:
		var button := Button.new()
		button.name = "Slot%d" % index
		button.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		button.add_theme_stylebox_override("normal", _button_style(BUTTON_ALPHA))
		button.add_theme_stylebox_override("hover", _button_style(BUTTON_ALPHA + 0.2))
		button.add_theme_stylebox_override("pressed", _button_style(0.8))
		button.pressed.connect(_on_slot_pressed.bind(index))
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.custom_minimum_size = Vector2(34, 34)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.modulate = Color(1, 1, 1, 0.95)
		icon.set_anchors_preset(Control.PRESET_CENTER)
		button.add_child(icon)
		_grid.add_child(button)
		_slot_buttons.append(button)


func _refresh() -> void:
	if _player == null or _player.inventory == null:
		return
	var inventory := _player.inventory
	var active_slots := inventory.get_active_slot_count()
	for index: int in _slot_buttons.size():
		var button := _slot_buttons[index]
		var icon := button.get_node("Icon") as TextureRect
		var slot := inventory.get_slot(index)
		var usable := index < active_slots
		button.visible = usable
		if not usable or slot.is_empty():
			icon.texture = null
			button.tooltip_text = ""
			continue
		icon.texture = icon_for_item(slot.item_id)
		var item_data := RpgDB.get_item(slot.item_id)
		button.tooltip_text = "%s (x%d)" % [RpgDB.get_text(String(item_data.get("name_key", ""))), slot.quantity]
	_refresh_equipped()


func _refresh_equipped() -> void:
	var inventory := _player.inventory
	if inventory.equipped_weapon.is_empty():
		_equipped_icon.texture = null
		_equipped_name.text = "Sin arma equipada"
		_equipped_bonus.text = "Toca un arma de la mochila para equiparla"
		return
	var weapon_id := inventory.equipped_weapon.item_id
	var item_data := RpgDB.get_item(weapon_id)
	_equipped_icon.texture = icon_for_item(weapon_id)
	_equipped_name.text = RpgDB.get_text(String(item_data.get("name_key", "")))
	var bonus := float(item_data.get("potency_bonus", 0.0))
	_equipped_bonus.text = ("Potencia +%d" % int(round(bonus))) if bonus > 0.0 else "Bonus pasivo"


func _on_slot_pressed(index: int) -> void:
	if _player == null:
		return
	_player.try_equip_weapon(index)
	_refresh()


func _on_unequip_pressed() -> void:
	if _player == null:
		return
	_player.try_equip_weapon(-1)
	_refresh()


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(COLOR_PANEL.r, COLOR_PANEL.g, COLOR_PANEL.b, PANEL_ALPHA)
	style.border_color = COLOR_PANEL_LINE
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _button_style(alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(COLOR_PANEL.r, COLOR_PANEL.g, COLOR_PANEL.b, alpha)
	style.border_color = COLOR_PANEL_LINE
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

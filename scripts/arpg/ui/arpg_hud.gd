class_name ArpgHUD
extends CanvasLayer
## HUD de la vertical slice, reorganizado en los preparativos de la Fase 3 con la
## distribución de los ARPG móviles de referencia (Diablo Immortal / Mobile Legends):
## - Joystick abajo-izquierda; clúster de acciones en ARCO abajo-derecha (ataque grande).
## - Minimapa cenital arriba-derecha (ArpgMinimap); mochila (inventario) junto al minimapa.
## - Todo SEMITRANSPARENTE para no tapar la escena; paneles de stats/misión arriba-izquierda.
## Lógica desacoplada: solo escucha señales del jugador/misiones y expone el vector del
## joystick. Sin lógica de juego en la UI (regla del repositorio).

signal joystick_changed(vector: Vector2)
signal dialog_accepted
signal dialog_closed
signal pause_requested

const COLOR_PANEL := Color("14161c")
const COLOR_PANEL_LINE := Color("2a2e38")
const COLOR_TEXT := Color("e8e4d8")
const COLOR_TEXT_DIM := Color("9aa0a6")
const COLOR_HP := Color("a32130")
const COLOR_VIGOR := Color("c98a2d")
const COLOR_XP := Color("b08d3c")
const COLOR_ACCENT := Color("1e3a4a")
const COLOR_DANGER := Color("e0503e")
const COLOR_GOLD := Color("c99543")
## Fase 3: transparencias del HUD móvil (semitransparente, referencia Diablo/MLBB).
const ALPHA_PANEL := 0.42
const ALPHA_BUTTON := 0.35
const ALPHA_BUTTON_HOVER := 0.55
const ALPHA_BUTTON_PRESSED := 0.85

const ICON_ATTACK: Texture2D = preload("res://assets/ui/icons/attack.png")
const ICON_SKILL: Texture2D = preload("res://assets/ui/icons/skill.png")
const ICON_DODGE: Texture2D = preload("res://assets/ui/icons/dodge.png")
const ICON_POTION: Texture2D = preload("res://assets/ui/icons/potion.png")
const ICON_BAG: Texture2D = preload("res://assets/ui/icons/bag.png")

var _player: Node = null
var _joystick_vector := Vector2.ZERO

var _stats_panel: PanelContainer = null
var _quest_panel: PanelContainer = null
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
var _toast_base_y := 84.0
var _interact_button: Button = null
var _joystick: ArpgVirtualJoystick = null
var _action_cluster: Control = null
var _attack_button: Button = null
var _skill_button: Button = null
var _dodge_button: Button = null
var _potion_button: Button = null
var _minimap: ArpgMinimap = null
var _inventory_button: Button = null
var _inventory_panel: ArpgInventoryPanel = null
var _pause_button: Button = null
var _skill_cooldown: ArpgCooldownOverlay = null
var _dodge_cooldown: ArpgCooldownOverlay = null
var _dialog_panel: PanelContainer = null
var _dialog_name: Label = null
var _dialog_line: Label = null
var _dialog_action: Button = null
var _dialog_lines: Array = []
var _dialog_index := 0
var _dialog_mode := "info"
var _dialog_on_accept: Callable
## Fase 5: barra de habilidades (4 huecos + definitiva), marco de objetivo,
## números de daño y estados alterados — todo por señales.
var _heavy_button: Button = null
var _skill_buttons: Array[Button] = []
var _skill_overlays: Array[ArpgCooldownOverlay] = []
var _ultimate_button: Button = null
var _ultimate_overlay: ArpgCooldownOverlay = null
var _block_button: Button = null
var _status_row: HBoxContainer = null
var _combat_feedback: ArpgCombatFeedback = null
var _availability_accumulator := 0.0


func _ready() -> void:
	_build_stats_panel()
	_build_status_chips()
	_build_quest_tracker()
	_build_toast()
	_build_combat_feedback()
	_build_joystick()
	_build_action_buttons()
	_build_interact_button()
	_build_dialog_panel()
	_build_minimap()
	_build_inventory_button()
	_build_pause_button()
	_build_inventory_panel()
	var root := get_root_control()
	root.resized.connect(_layout_hud)
	_layout_hud()


func _unhandled_input(event: InputEvent) -> void:
	## Fase 3: mochila con la acción dedicada. Fase 5: teclado completo del
	## combate (la UI traduce entrada → intención del jugador, igual que los
	## botones táctiles; el jugador no conoce los controles).
	if event.is_action_pressed("arpg_inventory"):
		toggle_inventory()
		get_viewport().set_input_as_handled()
		return
	if _player == null or _actions_blocked():
		return
	var arpg_player := _player as ArpgPlayer
	if event.is_action_pressed("arpg_attack"):
		arpg_player.try_attack()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("arpg_heavy"):
		arpg_player.try_heavy_attack()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("arpg_skill"):
		arpg_player.try_skill_index(0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("arpg_skill_2"):
		arpg_player.try_skill_index(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("arpg_skill_3"):
		arpg_player.try_skill_index(2)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("arpg_skill_4"):
		arpg_player.try_skill_index(3)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("arpg_ultimate"):
		arpg_player.try_ultimate()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("arpg_dodge"):
		arpg_player.try_dodge()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("arpg_potion"):
		arpg_player.try_potion()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("arpg_block"):
		arpg_player.set_blocking(true)
		get_viewport().set_input_as_handled()
	elif event.is_action_released("arpg_block"):
		arpg_player.set_blocking(false)
		get_viewport().set_input_as_handled()


func bind_player(player: Node) -> void:
	_player = player
	if player == null:
		return
	player.stats_changed.connect(_refresh_stats)
	player.leveled_up.connect(_on_leveled_up)
	_class_label.text = player.get_class_name()
	_resource_label.text = player.get_resource_name()
	_minimap.set_player(player as Node3D)
	_inventory_panel.bind_player(player as ArpgPlayer)
	# Fase 5: barra de habilidades, definitiva, objetivo y estados — por señales.
	_build_skill_bar()
	_wire_combat_signals()
	_refresh_stats()


func _wire_combat_signals() -> void:
	var arpg_player := _player as ArpgPlayer
	arpg_player.ultimate_charge_changed.connect(_on_ultimate_charge_changed)
	arpg_player.blocking_changed.connect(_on_blocking_changed)
	arpg_player.statuses.statuses_changed.connect(_refresh_status_chips)
	arpg_player.skill_cast.connect(_on_skill_cast)
	_combat_feedback.bind_targeting(arpg_player.targeting)
	if not arpg_player.cooldowns.cooldown_started.is_connected(_on_cooldown_started):
		arpg_player.cooldowns.cooldown_started.connect(_on_cooldown_started)
	if not arpg_player.cooldowns.cooldown_ended.is_connected(_on_cooldown_ended):
		arpg_player.cooldowns.cooldown_ended.connect(_on_cooldown_ended)


func is_dialog_open() -> bool:
	return _dialog_panel != null and _dialog_panel.visible


func _actions_blocked() -> bool:
	## Con un diálogo abierto (hablar con Cheo) no se combate: los botones y
	## el teclado de combate se ignoran hasta cerrarlo.
	return is_dialog_open()


func get_joystick_vector() -> Vector2:
	return _joystick_vector


func is_inventory_open() -> bool:
	return _inventory_panel != null and _inventory_panel.is_open()


func toggle_inventory() -> void:
	if _inventory_panel != null:
		_inventory_panel.toggle()


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
	# Art Pass: entrada con leve ascenso y fundido; salida igual.
	_toast_label.modulate.a = 0.0
	_toast_label.position.y = _toast_base_y + 14.0
	var intro := create_tween()
	intro.set_parallel(true)
	intro.tween_property(_toast_label, "modulate:a", 1.0, 0.18)
	intro.tween_property(_toast_label, "position:y", _toast_base_y, 0.22)
	var outro := create_tween()
	outro.tween_interval(duration)
	outro.tween_property(_toast_label, "modulate:a", 0.0, 0.5)


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

			# Última línea: cerrar o aceptar.
		else:
			_dialog_action.text = "Continuar"

			# Última línea: cerrar o aceptar.
		return
		# Última línea: cerrar o aceptar.
	_dialog_panel.visible = false
	if (_dialog_mode == "offer" or _dialog_mode == "claim") and _dialog_on_accept.is_valid():
		_dialog_on_accept.call()
		dialog_accepted.emit()
	else:
		dialog_closed.emit()


func _dialog_end_label() -> String:
	match _dialog_mode:
		"offer":
			return "Aceptar misión"
		"claim":
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


func _refresh_skill_availability_throttled() -> void:
	## La disponibilidad (vigor/candado) se refresca 4 veces por segundo como
	## máximo; las recargas van por señal, no por sondeo.
	_availability_accumulator += get_process_delta_time()
	if _availability_accumulator < 0.25:
		return
	_availability_accumulator = 0.0
	_refresh_skill_availability()


func _build_stats_panel() -> void:
	_stats_panel = PanelContainer.new()
	_stats_panel.name = "StatsPanel"
	_stats_panel.add_theme_stylebox_override("panel", _stats_style())
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	_stats_panel.add_child(box)
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
	get_root_control().add_child(_stats_panel)


func _build_quest_tracker() -> void:
	_quest_panel = PanelContainer.new()
	_quest_panel.name = "QuestPanel"
	_quest_panel.add_theme_stylebox_override("panel", _quest_style())
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	_quest_panel.add_child(box)
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
	get_root_control().add_child(_quest_panel)


func _build_toast() -> void:
	_toast_label = Label.new()
	_toast_label.name = "Toast"
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.add_theme_font_size_override("font_size", 17)
	_toast_label.add_theme_color_override("font_color", COLOR_XP)
	_toast_label.modulate.a = 0.0
	_toast_label.custom_minimum_size = Vector2(0, 26)
	get_root_control().add_child(_toast_label)


func _build_joystick() -> void:
	_joystick = ArpgVirtualJoystick.new()
	_joystick.name = "VirtualJoystick"
	get_root_control().add_child(_joystick)
	_joystick.value_changed.connect(_on_joystick_value)


func _on_joystick_value(value: Vector2) -> void:
	_joystick_vector = value
	joystick_changed.emit(value)


func _set_joystick(vector: Vector2) -> void:
	## Compatibilidad de la Fase 1 (usada por pruebas): aplica un offset como si
	## el dedo estuviera en esa posición del área del joystick.
	_joystick.set_value_from_offset(vector)


func _build_action_buttons() -> void:
	## Fase 3: clúster en arco estilo ARPG móvil. El ataque es el botón más grande
	## (abajo-derecha); habilidad encima; poción a la izquierda; esquiva arriba-izquierda.
	## Iteración 4C: recargas radiales en habilidad y esquiva + realce al pulsar.
	_action_cluster = Control.new()
	_action_cluster.name = "ActionCluster"
	_action_cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_root_control().add_child(_action_cluster)
	_attack_button = _round_action_button(ICON_ATTACK, "J", 100.0)
	_skill_button = _round_action_button(ICON_SKILL, "K", 58.0)
	_dodge_button = _round_action_button(ICON_DODGE, "ESP", 64.0)
	_potion_button = _round_action_button(ICON_POTION, "Q", 58.0)
	_heavy_button = _round_action_button(ArpgHudIcons.heavy_icon(), "L", 62.0)
	_block_button = _round_action_button(ArpgHudIcons.block_icon(), "MAY", 58.0)
	_dodge_cooldown = ArpgCooldownOverlay.new(64.0)
	_dodge_button.add_child(_dodge_cooldown)
	_potion_badge = Label.new()
	_potion_badge.text = "x1"
	_potion_badge.add_theme_font_size_override("font_size", 13)
	_potion_badge.add_theme_color_override("font_color", COLOR_TEXT)
	_potion_button.add_child(_potion_badge)
	_potion_badge.position = Vector2(33, 2)
	_attack_button.pressed.connect(_on_action_pressed.bind("attack"))
	_skill_button.pressed.connect(_on_action_pressed.bind("skill"))
	_dodge_button.pressed.connect(_on_action_pressed.bind("dodge"))
	_potion_button.pressed.connect(_on_action_pressed.bind("potion"))
	_heavy_button.pressed.connect(_on_action_pressed.bind("heavy"))
	# El bloqueo se MANTIENE pulsado (hold): button_down/button_up, no pressed.
	_block_button.button_down.connect(_on_block_down)
	_block_button.button_up.connect(_on_block_up)
	for button: Button in [_attack_button, _skill_button, _dodge_button, _potion_button, _heavy_button, _block_button]:
		_action_cluster.add_child(button)


func _round_action_button(icon: Texture2D, key_hint: String, diameter: float) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(diameter, diameter)
	button.pivot_offset = Vector2(diameter, diameter) / 2.0
	button.add_theme_stylebox_override("normal", _circle_style(diameter, ALPHA_BUTTON))
	button.add_theme_stylebox_override("hover", _circle_style(diameter, ALPHA_BUTTON_HOVER))
	button.add_theme_stylebox_override("pressed", _circle_style(diameter, ALPHA_BUTTON_PRESSED, true))
	button.add_theme_stylebox_override("focus", _circle_style(diameter, ALPHA_BUTTON_HOVER))
	# Realce al pulsar (táctil): leve contracción y rebote, como en el menú.
	button.pressed.connect(
		func() -> void:
			var tween := button.create_tween()
			tween.tween_property(button, "scale", Vector2(0.93, 0.93), 0.05)
			tween.tween_property(button, "scale", Vector2.ONE, 0.12)
	)
	var icon_rect := TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.texture = icon
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.modulate = Color(1, 1, 1, 0.95)
	var icon_size := Vector2(diameter * 0.5, diameter * 0.5)
	icon_rect.position = Vector2((diameter - icon_size.x) * 0.5, (diameter - icon_size.y) * 0.5 - 3.0)
	icon_rect.size = icon_size
	button.add_child(icon_rect)
	if key_hint != "":
		var hint := Label.new()
		hint.name = "KeyHint"
		hint.text = key_hint
		hint.add_theme_font_size_override("font_size", 10)
		hint.add_theme_color_override("font_color", COLOR_TEXT_DIM)
		hint.position = Vector2(diameter * 0.5 - 12.0, diameter - 16.0)
		button.add_child(hint)
	return button


func _on_action_pressed(action: String) -> void:
	if _player == null or _actions_blocked():
		return
	match action:
		"attack":
			_player.try_attack()
		"skill":
			_player.try_skill_index(0)
		"dodge":
			_player.try_dodge()
		"potion":
			_player.try_potion()
		"heavy":
			(_player as ArpgPlayer).try_heavy_attack()


func _on_block_down() -> void:
	if _player != null and not _actions_blocked():
		(_player as ArpgPlayer).set_blocking(true)


func _on_block_up() -> void:
	if _player != null:
		(_player as ArpgPlayer).set_blocking(false)


func _build_minimap() -> void:
	_minimap = ArpgMinimap.new()
	_minimap.name = "Minimap"
	get_root_control().add_child(_minimap)


func _build_inventory_button() -> void:
	_inventory_button = _round_action_button(ICON_BAG, "I", 56.0)
	_inventory_button.name = "InventoryButton"
	_inventory_button.pressed.connect(toggle_inventory)
	get_root_control().add_child(_inventory_button)


func _build_pause_button() -> void:
	## Botón táctil de pausa (iteración 4C): junto al minimapa, arriba-derecha.
	## El HUD no decide qué es pausar: emite pause_requested y la escena responde.
	_pause_button = _round_action_button(ArpgHudIcons.pause_icon(), "", 48.0)
	_pause_button.name = "PauseButton"
	_pause_button.pressed.connect(func() -> void: pause_requested.emit())
	get_root_control().add_child(_pause_button)


func _process(_delta: float) -> void:
	## Fase 5: rellenos radiales (hasta 6 overlays) + disponibilidad limitada a
	## 4 Hz. Vida, vigor, XP, objetivo y estados van por señales, sin sondeo.
	if _player == null or _skill_overlays.is_empty():
		return
	_dodge_cooldown.set_progress(_player.get_dodge_cooldown_left(), _player.get_dodge_cooldown_total())
	_update_skill_radials()
	_refresh_skill_availability_throttled()


func _build_inventory_panel() -> void:
	_inventory_panel = ArpgInventoryPanel.new()
	_inventory_panel.name = "InventoryPanel"
	get_root_control().add_child(_inventory_panel)


func _build_interact_button() -> void:
	_interact_button = Button.new()
	_interact_button.name = "InteractButton"
	_interact_button.text = "Hablar (E)"
	_interact_button.visible = false
	_interact_button.custom_minimum_size = Vector2(180, 48)
	_interact_button.add_theme_font_size_override("font_size", 15)
	_interact_button.add_theme_color_override("font_color", COLOR_TEXT)
	_interact_button.add_theme_stylebox_override("normal", _button_style(Color(0.10, 0.16, 0.22, 0.55)))
	_interact_button.add_theme_stylebox_override("pressed", _accent_pressed_style())
	get_root_control().add_child(_interact_button)


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
	_dialog_action.add_theme_font_size_override("font_size", 14)
	_dialog_action.add_theme_color_override("font_color", COLOR_TEXT)
	_dialog_action.add_theme_stylebox_override("normal", _button_style(Color(0.13, 0.15, 0.20, 0.55)))
	_dialog_action.add_theme_stylebox_override("pressed", _accent_pressed_style())
	_dialog_action.pressed.connect(_dialog_next)
	box.add_child(_dialog_action)
	_dialog_panel.custom_minimum_size = Vector2(600, 150)
	get_root_control().add_child(_dialog_panel)


# ---------------------------------------------------------------------------
# Fase 5: barra de habilidades, definitiva, objetivo, daño y estados
# ---------------------------------------------------------------------------


func _build_skill_bar() -> void:
	## Cuatro huecos de habilidad + definitiva, con recarga radial, candado de
	## desbloqueo y coste visible. Se reconstruye en cada bind (los datos de la
	## clase no cambian en partida).
	for button: Button in _skill_buttons:
		button.queue_free()
	_skill_buttons.clear()
	_skill_overlays.clear()
	if _ultimate_button != null:
		_ultimate_button.queue_free()
	var arpg_player := _player as ArpgPlayer
	var key_hints := ["K", "2", "3", "4"]
	for index: int in arpg_player.get_skill_count():
		var def := arpg_player.get_skill_def(index)
		## El hueco 0 REUTILIZA el botón de habilidad del arco (mismo contrato
		## de la Fase 3; no hay botones duplicados para la misma habilidad).
		var button := (
			_skill_button
			if index == 0
			else _round_action_button(ArpgHudIcons.skill_icon(index), String(key_hints[index]), 58.0)
		)
		if index > 0:
			button.name = "Skill%d" % (index + 1)
			_action_cluster.add_child(button)
		var overlay := ArpgCooldownOverlay.new(58.0)
		button.add_child(overlay)
		var cost_label := Label.new()
		cost_label.text = "%d" % int(float(def.get("resource_cost", 0)))
		cost_label.add_theme_font_size_override("font_size", 11)
		cost_label.add_theme_color_override("font_color", COLOR_VIGOR)
		cost_label.position = Vector2(4.0, 40.0)
		button.add_child(cost_label)
		button.pressed.connect(_on_skill_button_pressed.bind(index))
		_skill_buttons.append(button)
		_skill_overlays.append(overlay)
		if index == 0:
			_skill_cooldown = overlay
	# Definitiva: botón mayor con carga (relleno dorado hasta estar lista).
	_ultimate_button = _round_action_button(ArpgHudIcons.ultimate_icon(), "R", 72.0)
	_ultimate_button.name = "UltimateButton"
	_ultimate_overlay = ArpgCooldownOverlay.new(72.0)
	_ultimate_button.add_child(_ultimate_overlay)
	_ultimate_button.pressed.connect(
		func() -> void:
			if _player != null:
				(_player as ArpgPlayer).try_ultimate()
	)
	_action_cluster.add_child(_ultimate_button)
	_refresh_skill_availability()


func _on_skill_button_pressed(index: int) -> void:
	if _player != null and not _actions_blocked():
		(_player as ArpgPlayer).try_skill_index(index)


func _on_skill_cast(_skill_id: String) -> void:
	## Al lanzarse, la barra refresca disponibilidad (coste/bloqueo).
	_refresh_skill_availability()


func _refresh_skill_availability() -> void:
	## Estados reales por hueco: candado (sin nivel), atenuada (sin vigor),
	## recarga (overlay). Nada decorativo.
	var arpg_player := _player as ArpgPlayer
	if arpg_player == null:
		return
	for index: int in _skill_buttons.size():
		var button := _skill_buttons[index]
		var def := arpg_player.get_skill_def(index)
		var unlocked := arpg_player.is_skill_unlocked(index)
		var affordable := arpg_player.vigor >= float(def.get("resource_cost", 0))
		button.disabled = not unlocked
		button.modulate = Color(1, 1, 1, 1.0 if unlocked and affordable else 0.45)
		if not unlocked:
			button.tooltip_text = "Se desbloquea al nivel %d" % int(def.get("unlock_level", 1))
	_on_ultimate_charge_changed(arpg_player.get_ultimate_charge(), arpg_player.get_ultimate_max())


func _on_ultimate_charge_changed(current: float, maximum: float) -> void:
	## Carga de la definitiva: relleno creciente y brillo cuando está lista.
	if _ultimate_button == null or _player == null:
		return
	var arpg_player := _player as ArpgPlayer
	var ready := arpg_player.is_ultimate_ready()
	var fraction := clampf(current / maximum, 0.0, 1.0) if maximum > 0.0 else 0.0
	# El overlay dibuja "lo que queda"; para la carga usamos 1 - fracción.
	_ultimate_overlay.set_progress((1.0 - fraction) * maximum, maximum)
	_ultimate_button.modulate = Color(1, 1, 1, 1.0 if ready else 0.75)
	if ready:
		_ultimate_button.modulate = Color(1.35, 1.1, 0.8)


func _on_blocking_changed(is_blocking: bool) -> void:
	## Realce del botón de bloqueo mientras se mantiene.
	if _block_button != null:
		_block_button.modulate = Color(1, 1, 1, 0.55 if is_blocking else 1.0)


func _on_cooldown_started(_id: String, _duration: float) -> void:
	_refresh_skill_availability()


func _on_cooldown_ended(_id: String) -> void:
	_refresh_skill_availability()


func _update_skill_radials() -> void:
	## Relleno radial de las recargas (sondeo acotado: solo los ~5 overlays
	## activos; un radial es continuo por naturaleza y las reducciones externas
	## de recarga deben reflejarse al instante, cosa que un tween no garantiza).
	var arpg_player := _player as ArpgPlayer
	if arpg_player == null:
		return
	for index: int in _skill_overlays.size():
		var skill_id := String(arpg_player.get_skill_def(index).get("id", ""))
		_skill_overlays[index].set_progress(arpg_player.cooldowns.left(skill_id), arpg_player.cooldowns.total(skill_id))


func _build_status_chips() -> void:
	## Chips de estados alterados del JUGADOR (bajo el panel de stats).
	_status_row = HBoxContainer.new()
	_status_row.name = "StatusChips"
	_status_row.add_theme_constant_override("separation", 4)
	get_root_control().add_child(_status_row)


func _build_combat_feedback() -> void:
	## Capa de feedback (números de daño + marco de objetivo): componente
	## independiente que se conecta solo a CombatEvents y al TargetingSystem.
	_combat_feedback = ArpgCombatFeedback.new()
	_combat_feedback.name = "CombatFeedback"
	get_root_control().add_child(_combat_feedback)


func _refresh_status_chips() -> void:
	if _status_row == null or _player == null:
		return
	for child: Node in _status_row.get_children():
		child.queue_free()
	for status_id: String in (_player as ArpgPlayer).get_status_ids():
		_status_row.add_child(ArpgStatusChips.make(status_id))


func _on_status_added(_id: String, _duration: float) -> void:
	_refresh_status_chips()


func _on_status_removed(_id: String) -> void:
	_refresh_status_chips()


func _layout_hud() -> void:
	## Re-coloca todo el HUD según el tamaño del viewport (landscape 16:9 y
	## 20:9 objetivo; con anchos pequeños se hace clamp a 8 px): stats y
	## misión arriba-izquierda, objetivo arriba-centro (capa de feedback),
	## minimapa arriba-derecha, joystick abajo-izquierda y clúster de
	## acciones en arco abajo-derecha.
	var root := get_root_control()
	var viewport_size := root.size
	if viewport_size.x < 320.0 or viewport_size.y < 240.0:
		return
	_stats_panel.position = Vector2(16, 14)
	_status_row.position = Vector2(18, 112)
	_quest_panel.position = Vector2(16, 142)
	_toast_label.position = Vector2(0, 84)
	_toast_label.size = Vector2(viewport_size.x, 30)
	_toast_base_y = 84.0
	_combat_feedback.layout(viewport_size)
	var joy_size := Vector2(_joystick.radius * 2.0, _joystick.radius * 2.0)
	_joystick.position = Vector2(150.0, viewport_size.y - 150.0) - joy_size * 0.5
	_joystick.size = joy_size
	var map_size := _minimap.custom_minimum_size
	_minimap.position = Vector2(viewport_size.x - map_size.x - 16.0, 14.0)
	_minimap.size = map_size
	_inventory_button.position = Vector2(viewport_size.x - 72.0, 14.0 + map_size.y + 10.0)
	_pause_button.position = Vector2(viewport_size.x - map_size.x - 16.0 - 56.0, 14.0)
	# Clúster de acciones (Fase 5) en tres filas estilo ARPG móvil: habilidades
	# arriba (S1-S4), definitiva + pesado + poción en medio, y el ataque GRANDE
	# abajo-derecha con esquiva y bloqueo. Todo dentro del viewport 16:9/20:9.
	var cluster_right := viewport_size.x - 24.0
	_place_button(_skill_button, cluster_right, 460.0)
	for index: int in range(1, _skill_buttons.size()):
		## S2-S4 a la izquierda de S1 en la misma fila (paso = ancho + margen).
		_place_button(_skill_buttons[index], cluster_right - float(index) * 66.0, 460.0)
	_place_button(_ultimate_button, cluster_right - 8.0, 534.0)
	_place_button(_heavy_button, cluster_right - 96.0, 540.0)
	_place_button(_potion_button, cluster_right - 168.0, 544.0)
	_place_button(_attack_button, cluster_right, 612.0)
	_place_button(_dodge_button, cluster_right - 112.0, 648.0)
	_place_button(_block_button, cluster_right - 180.0, 652.0)
	_interact_button.position = Vector2(viewport_size.x / 2.0 - 90.0, viewport_size.y - 96.0)
	_dialog_panel.position = Vector2(maxf(viewport_size.x / 2.0 - 300.0, 8.0), maxf(viewport_size.y - 210.0, 8.0))
	var panel_size := _inventory_panel.custom_minimum_size
	_inventory_panel.position = Vector2(
		maxf(viewport_size.x / 2.0 - panel_size.x * 0.5, 8.0),
		maxf(viewport_size.y / 2.0 - panel_size.y * 0.5, 8.0),
	)
	_inventory_panel.size = panel_size
	_refresh_skill_availability()


func _place_button(button: Button, right_edge: float, top: float) -> void:
	## Coloca un botón anclado al borde derecho dado (fila del clúster).
	if button == null:
		return
	var size := button.custom_minimum_size
	button.position = Vector2(right_edge - size.x, top)
	button.size = size


func _place_arc_button(button: Button, corner: Vector2, angle_deg: float, radius: float) -> void:
	## Coloca un botón circular en un ángulo/radio alrededor de la esquina (0°=este,
	## 90°=sur). Los botones que aún no existen (HUD sin jugador atado) se omiten.
	if button == null:
		return
	var angle := deg_to_rad(angle_deg)
	var button_size := button.custom_minimum_size
	var center := corner + Vector2(cos(angle), sin(angle)) * radius
	button.position = Vector2(
		maxf(center.x - button_size.x * 0.5, 8.0),
		maxf(center.y - button_size.y * 0.5, 8.0),
	)
	button.size = button_size


func _panel_style(margin := 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(COLOR_PANEL.r, COLOR_PANEL.g, COLOR_PANEL.b, ALPHA_PANEL)
	style.border_color = COLOR_PANEL_LINE
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style


func _stats_style() -> StyleBoxFlat:
	## Iteración 4C: el panel de stats hereda el acento dorado lateral (misma
	## familia visual que el rastreador de misiones).
	var style := _panel_style(10)
	style.border_color = COLOR_GOLD
	style.border_width_left = 3
	style.set_corner_radius(3, 8)
	style.set_corner_radius(0, 8)
	return style


func _quest_style() -> StyleBoxFlat:
	## Art Pass: el rastreador de misiones lleva acento lateral dorado; se
	## distingue de un vistazo del resto de paneles semitransparentes.
	var style := _panel_style(10)
	style.border_color = COLOR_XP
	style.border_width_left = 3
	style.set_corner_radius(3, 8)
	style.set_corner_radius(0, 8)
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


func _circle_style(diameter: float, alpha: float, pressed := false) -> StyleBoxFlat:
	## Estilo circular semitransparente para los botones del arco (Fase 3).
	var style := StyleBoxFlat.new()
	if pressed:
		style.bg_color = Color(COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b, alpha)
	else:
		style.bg_color = Color(0.08, 0.10, 0.13, alpha)
	style.border_color = COLOR_PANEL_LINE
	style.set_border_width_all(1)
	style.set_corner_radius_all(int(diameter * 0.5) - 1)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _accent_pressed_style() -> StyleBoxFlat:
	## Presionado con acento (semitransparente); evita repetir el color largo en cada botón.
	return _button_style(Color(COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b, 0.85))


func _make_bar(color: Color, height: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(240, height)
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(color.r, color.g, color.b, 0.9)
	fill.corner_radius_top_left = 4
	fill.corner_radius_bottom_left = 4
	fill.corner_radius_top_right = 4
	fill.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("fill", fill)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.06, 0.07, 0.09, 0.45)
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

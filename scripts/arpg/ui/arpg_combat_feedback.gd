# gdlint: ignore=max-public-methods
class_name ArpgCombatFeedback
extends Control
## Capa de feedback de combate del HUD (Fase 5): números de daño flotantes
## (con variante de crítico y de parada perfecta), marco de objetivo (nombre,
## nivel, vida y estados del enemigo enfocado). Extraída de ArpgHUD para
## mantener cada archivo acotado; se conecta SOLA a CombatEvents y al
## TargetingSystem del jugador (cero sondeo por frame).

var _target_frame: PanelContainer = null
var _target_name: Label = null
var _target_level: Label = null
var _target_hp: ProgressBar = null
var _target_status_row: HBoxContainer = null
var _target_enemy: ArpgEnemy = null
var _damage_pool: Array[Label] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_target_frame()
	CombatEvents.damage_dealt.connect(_on_damage_dealt)
	CombatEvents.attack_parried.connect(_on_parry)


func _exit_tree() -> void:
	if CombatEvents != null:
		CombatEvents.damage_dealt.disconnect(_on_damage_dealt)
		CombatEvents.attack_parried.disconnect(_on_parry)


func bind_targeting(targeting: TargetingSystem) -> void:
	targeting.target_changed.connect(_on_target_changed)


func _build_target_frame() -> void:
	_target_frame = PanelContainer.new()
	_target_frame.name = "TargetFrame"
	_target_frame.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.11, 0.55)
	style.border_color = Color("c99543")
	style.border_width_left = 2
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	_target_frame.add_theme_stylebox_override("panel", style)
	_target_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	_target_frame.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	box.add_child(head)
	_target_name = Label.new()
	_target_name.add_theme_font_size_override("font_size", 15)
	_target_name.add_theme_color_override("font_color", Color("e8e4d8"))
	head.add_child(_target_name)
	_target_level = Label.new()
	_target_level.add_theme_font_size_override("font_size", 13)
	_target_level.add_theme_color_override("font_color", Color("b08d3c"))
	head.add_child(_target_level)
	_target_hp = ProgressBar.new()
	_target_hp.custom_minimum_size = Vector2(220, 8)
	_target_hp.min_value = 0.0
	_target_hp.max_value = 100.0
	_target_hp.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.64, 0.13, 0.19, 0.92)
	fill.set_corner_radius_all(4)
	_target_hp.add_theme_stylebox_override("fill", fill)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.06, 0.07, 0.09, 0.6)
	background.set_corner_radius_all(4)
	_target_hp.add_theme_stylebox_override("background", background)
	box.add_child(_target_hp)
	_target_status_row = HBoxContainer.new()
	_target_status_row.add_theme_constant_override("separation", 4)
	box.add_child(_target_status_row)
	add_child(_target_frame)


func layout(viewport_size: Vector2) -> void:
	## Recoloca el marco (arriba-centro) al cambiar la resolución.
	if _target_frame == null:
		return
	_target_frame.reset_size()
	_target_frame.position = Vector2(maxf(viewport_size.x * 0.5 - _target_frame.size.x * 0.5, 8.0), 116.0)


func _on_target_changed(target: Node) -> void:
	## Cambio de objetivo: rebind del marco y de su vida (por señales).
	_disconnect_target()
	_target_enemy = target as ArpgEnemy
	if _target_enemy == null:
		_target_frame.visible = false
		return
	_target_frame.visible = true
	_target_name.text = _target_enemy.get_display_name()
	_target_level.text = "Nv %d" % _target_enemy.get_level()
	_target_enemy.combatant_damaged.connect(_on_target_hp_changed)
	_target_enemy.combatant_died.connect(_on_target_died)
	_on_target_hp_changed(0.0)
	_refresh_target_status()


func _disconnect_target() -> void:
	if _target_enemy != null and is_instance_valid(_target_enemy):
		_target_enemy.combatant_damaged.disconnect(_on_target_hp_changed)
		_target_enemy.combatant_died.disconnect(_on_target_died)
	_target_enemy = null


func _on_target_hp_changed(_amount: float) -> void:
	if _target_enemy != null and is_instance_valid(_target_enemy):
		_target_hp.value = _target_enemy.get_hp_fraction() * 100.0


func _on_target_died() -> void:
	_target_frame.visible = false


func _refresh_target_status() -> void:
	for child: Node in _target_status_row.get_children():
		child.queue_free()
	if _target_enemy == null or not is_instance_valid(_target_enemy):
		return
	for status_id: String in _target_enemy.get_status_ids():
		_target_status_row.add_child(ArpgStatusChips.make(status_id))


func _on_damage_dealt(target: Node, amount: float, is_crit: bool, world_position: Vector3) -> void:
	## Números de daño flotantes proyectados a pantalla (crítico más grande).
	if not is_instance_valid(target):
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	if camera.is_position_behind(world_position):
		return
	var screen := camera.unproject_position(world_position + Vector3(0, 1.8, 0))
	spawn_number("%d" % int(round(amount)), screen, is_crit)


func _on_parry(victim: Node) -> void:
	## Parada perfecta visible (Pulso de monte) sobre el jugador.
	if victim == null:
		return
	spawn_number("¡PARADA!", Vector2(get_viewport().get_visible_rect().size.x * 0.5, 190.0), true, Color("ffd97a"))


func spawn_number(text: String, screen: Vector2, is_crit: bool, tint := Color.WHITE) -> void:
	var label := _acquire()
	label.text = text
	label.add_theme_font_size_override("font_size", 22 if is_crit else 16)
	var color := tint if tint != Color.WHITE else (Color("c99543") if is_crit else Color("e8e4d8"))
	label.add_theme_color_override("font_color", color)
	label.modulate.a = 1.0
	label.position = screen + Vector2(randf_range(-12.0, 12.0), 0.0)
	label.reset_size()
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - (46.0 if is_crit else 32.0), 0.7)
	tween.tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.25)
	tween.chain().tween_callback(func() -> void: label.visible = false)


func _acquire() -> Label:
	## Pila pequeña de etiquetas reutilizables (sin instanciar por golpe).
	for label: Label in _damage_pool:
		if not label.visible:
			label.visible = true
			return label
	var label := Label.new()
	label.name = "DamageNumber%d" % _damage_pool.size()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)
	_damage_pool.append(label)
	return label

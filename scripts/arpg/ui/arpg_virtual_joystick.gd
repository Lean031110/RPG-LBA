class_name ArpgVirtualJoystick
extends Control
## Joystick virtual de la Fase 2: control táctil autónomo, reutilizable y sin lógica de juego.
## - Sigue UN dedo (por índice) aunque el dedo salga del área o crucen otros toques.
## - Liberación en cualquier punto de la pantalla (nunca queda pegado en un valor).
## - Zona muerta configurable: evita deriva con el dedo casi quieto.
## - Emulación con botón izquierdo del ratón para pruebas en escritorio (mismo camino).
## La matemática pura (value_from_offset) es estática: unit-testeable sin escena.

signal value_changed(value: Vector2)

## Paleta del HUD de la Fase 1 (duplicada a propósito: el control es autónomo y
## reutilizable sin depender de ArpgHUD).
const COLOR_ACCENT := Color("1e3a4a")
const COLOR_TEXT_DIM := Color("9aa0a6")

@export_range(40.0, 240.0, 1.0) var radius := 92.0
@export_range(12.0, 96.0, 1.0) var knob_radius := 38.0
## Fracción del recorrido ignorada cerca del centro (0.12 ≈ 11 px con radius 92).
@export_range(0.0, 0.5, 0.01) var dead_zone := 0.12

var _value := Vector2.ZERO
var _finger_index := -1
var _mouse_active := false


static func value_from_offset(offset: Vector2, joy_radius: float, knob: float, dead: float) -> Vector2:
	## Pura: offset en píxeles respecto al centro -> Vector2 en [-1, 1] (recorto máximo),
	## con zona muerta aplicada. Mismo factor de normalización que el HUD de la Fase 1.
	var travel := joy_radius - knob * 0.5
	if travel <= 1.0:
		return Vector2.ZERO
	var clamped := offset.limit_length(travel)
	var value := clamped / travel
	if value.length() < dead:
		return Vector2.ZERO
	return value


func get_value() -> Vector2:
	return _value


func set_value_from_offset(offset: Vector2) -> void:
	## Aplica un offset externo como si el dedo estuviera ahí (pruebas y compatibilidad del HUD).
	_apply(value_from_offset(offset, radius, knob_radius, dead_zone))


func _ready() -> void:
	custom_minimum_size = Vector2(radius * 2.0, radius * 2.0)
	size = Vector2(radius * 2.0, radius * 2.0)
	# STOP: el área del joystick no deja pasar toques a lo que haya detrás (igual que Fase 1).
	mouse_filter = Control.MOUSE_FILTER_STOP
	draw.connect(_draw_joystick)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _input(event: InputEvent) -> void:
	## Entrada a nivel de viewport (ve TODOS los eventos, incluidos los que otros
	## controles consumirán después). Solo reacciona a su propio dedo o a su área.
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _finger_index == -1 and _is_inside(touch.position):
				_finger_index = touch.index
				_update_from_screen(touch.position)
		elif touch.index == _finger_index:
			_release()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _finger_index:
			_update_from_screen(drag.position)
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mouse := event as InputEventMouseButton
		if mouse.pressed:
			if _finger_index == -1 and not _mouse_active and _is_inside(mouse.global_position):
				_mouse_active = true
				_update_from_screen(mouse.global_position)
		elif _mouse_active:
			_release()
	elif event is InputEventMouseMotion and _mouse_active:
		_update_from_screen((event as InputEventMouseMotion).global_position)


func _is_inside(screen_position: Vector2) -> bool:
	return get_global_rect().has_point(screen_position)


func _update_from_screen(screen_position: Vector2) -> void:
	var center := global_position + size * 0.5
	_apply(value_from_offset(screen_position - center, radius, knob_radius, dead_zone))


func _release() -> void:
	_finger_index = -1
	_mouse_active = false
	_apply(Vector2.ZERO)


func _apply(value: Vector2) -> void:
	if value.is_equal_approx(_value):
		return
	_value = value
	value_changed.emit(value)
	queue_redraw()


func _draw_joystick() -> void:
	var center := size * 0.5
	draw_circle(center, radius, Color(0.08, 0.09, 0.12, 0.42))
	draw_arc(center, radius - 3.0, 0.0, TAU, 40, COLOR_ACCENT, 2.0)
	var knob_offset := _value * (radius - knob_radius)
	draw_circle(center + knob_offset, knob_radius, Color(0.16, 0.18, 0.24, 0.82))
	draw_circle(center + knob_offset, knob_radius - 4.0, COLOR_TEXT_DIM)

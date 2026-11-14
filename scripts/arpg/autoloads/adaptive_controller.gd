class_name ArpgAdaptiveController
extends RefCounted
## Controlador de resolucion dinamica (logica pura, testeable).
## Ajusta la escala de render dentro de [min, max] con histeresis:
## baja si el tiempo medio de fotograma supera el 130% del presupuesto durante
## `down_after_s`; sube si queda por debajo del 70% durante `up_after_s`.
## No reacciona a picos aislados; evita cambios bruscos.
## La senal de temperatura no es accesible de forma fiable desde Godot en todos
## los dispositivos: se usa tiempo de fotograma sostenido (docs/16).

var min_scale := 0.5
var max_scale := 0.75
var step := 0.05
var down_after_s := 2.0
var up_after_s := 6.0
var target_ms := 33.3
var current := 0.7
var active := false

var _slow_s := 0.0
var _fast_s := 0.0


func configure(window: Dictionary, target_fps: int, initial_scale: float, enabled: bool) -> void:
	min_scale = clampf(float(window.get("min", 0.5)), 0.5, 1.0)
	max_scale = clampf(float(window.get("max", 0.75)), min_scale, 1.0)
	step = clampf(float(window.get("step", 0.05)), 0.01, 0.1)
	down_after_s = maxf(float(window.get("down_after_s", 2.0)), 0.5)
	up_after_s = maxf(float(window.get("up_after_s", 6.0)), 1.0)
	var fps := maxi(target_fps, 10)
	target_ms = 1000.0 / float(fps)
	current = clampf(initial_scale, min_scale, max_scale)
	set_enabled(enabled)


func set_enabled(enabled: bool) -> void:
	active = enabled and max_scale > min_scale + 0.001
	if not active:
		_slow_s = 0.0
		_fast_s = 0.0


func note_frame(avg_ms: float, sample_window_s: float) -> String:
	## Recibe el promedio de fotograma de la ventana; devuelve la accion.
	if not active:
		return "hold"
	if avg_ms > target_ms * 1.3:
		_slow_s += sample_window_s
		_fast_s = 0.0
	elif avg_ms < target_ms * 0.7:
		_fast_s += sample_window_s
		_slow_s = 0.0
	else:
		_slow_s = 0.0
		_fast_s = 0.0
	if _slow_s >= down_after_s and current > min_scale + 0.001:
		current = maxf(min_scale, current - step)
		_slow_s = 0.0
		return "down"
	if _fast_s >= up_after_s and current < max_scale - 0.001:
		current = minf(max_scale, current + step)
		_fast_s = 0.0
		return "up"
	return "hold"


func reset_hysteresis() -> void:
	_slow_s = 0.0
	_fast_s = 0.0

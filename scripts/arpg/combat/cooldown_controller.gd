class_name CooldownController
extends RefCounted
## Enfriamientos por identificador (Fase 5). Sustituye los tres temporizadores
## sueltos del jugador (ataque/habilidad/esquiva) por un controlador único con
## señales, reutilizable por habilidades, enemigos y futuras clases.
##
## El HUD escucha cooldown_started/cooldown_ended y consulta left/total para
## el relleno radial; ningún sistema recalcula tiempos por su cuenta.

signal cooldown_started(id: String, duration: float)
signal cooldown_ended(id: String)

const MIN_DURATION := 0.0

var _remaining := {}
var _totals := {}


func tick(delta: float) -> void:
	## Avanza todos los enfriamientos y emite cooldown_ended al vencer.
	if _remaining.is_empty():
		return
	var expired: Array[String] = []
	for id: String in _remaining.keys():
		var left := maxf(float(_remaining[id]) - delta, 0.0)
		_remaining[id] = left
		if left <= 0.0:
			expired.append(id)
	for id: String in expired:
		_remaining.erase(id)
		_totals.erase(id)
		cooldown_ended.emit(id)


func start(id: String, duration: float) -> void:
	## Inicia (o reinicia) el enfriamiento de un identificador.
	var clamped := maxf(duration, MIN_DURATION)
	if clamped <= 0.0:
		return
	_remaining[id] = clamped
	_totals[id] = clamped
	cooldown_started.emit(id, clamped)


func is_ready(id: String) -> bool:
	return not _remaining.has(id)


func left(id: String) -> float:
	return maxf(float(_remaining.get(id, 0.0)), 0.0)


func total(id: String) -> float:
	return maxf(float(_totals.get(id, 0.0)), 0.0)


func progress_ratio(id: String) -> float:
	## 0.0 = recién arrancado, 1.0 = listo. Para rellenos radiales del HUD.
	var total_time := total(id)
	if total_time <= 0.0:
		return 1.0
	return clampf(1.0 - left(id) / total_time, 0.0, 1.0)


func reduce(id: String, seconds: float) -> void:
	## Rebaja tiempo de recarga (p. ej. reducción por equipo o efectos).
	if not _remaining.has(id) or seconds <= 0.0:
		return
	var new_left := maxf(float(_remaining[id]) - seconds, 0.0)
	if new_left <= 0.0:
		_remaining.erase(id)
		_totals.erase(id)
		cooldown_ended.emit(id)
	else:
		_remaining[id] = new_left


func clear() -> void:
	## Limpia todo (muerte, cambio de escena). No emite señales: el dueño
	## reconstruye su estado.
	_remaining.clear()
	_totals.clear()


func clear_one(id: String) -> void:
	if _remaining.erase(id):
		_totals.erase(id)
		cooldown_ended.emit(id)

class_name StatusEffectController
extends RefCounted
## Estados alterados de combate (Fase 5): aturdimiento, ralentización,
## vulnerabilidad, invulnerabilidad, rotura de armadura, sangrado, potenciación
## y trampa de resina. Un controlador por combatiente (jugador y enemigos).
##
## Reglas de solapado: el MISMO id no se apila (refresca duración y mezcla
## parámetros si el nuevo es más fuerte); ids DISTINTOS coexisten. Los estados
## incompatibles con acciones se resuelven con consultas (can_act, etc.), nunca
## con flags sueltos en el dueño.

signal status_added(id: String, duration: float)
signal status_removed(id: String)
signal statuses_changed
signal periodic_tick(id: String, payload: Dictionary)

const MOVE_SLOW_IDS := ["slow", "resin"]
const DAMAGE_OVER_TIME_IDS := ["bleed"]
const ROOT_IDS := ["root"]

var _effects := {}


func apply(id: String, duration: float, params: Dictionary = {}) -> void:
	## Aplica o refresca un estado. Si ya existía, la duración mayor gana y los
	## parámetros numéricos mayores sobreviven (sangrado más fuerte pisa al débil).
	if duration <= 0.0:
		return
	if has(id):
		var current: Dictionary = _effects[id]
		current["duration"] = maxf(float(current.get("duration", 0.0)), duration)
		var current_params: Dictionary = current.get("params", {})
		for key: String in params.keys():
			var old_value := float(current_params.get(key, 0.0))
			current_params[key] = maxf(old_value, float(params[key]))
		current["params"] = current_params
		statuses_changed.emit()
	else:
		_effects[id] = {"duration": duration, "params": params.duplicate(), "elapsed": 0.0}
		status_added.emit(id, duration)
		statuses_changed.emit()


func tick(delta: float) -> void:
	## Avanza duraciones, procesa efectos periódicos (sangrado) y expira estados.
	if _effects.is_empty():
		return
	var expired: Array[String] = []
	for id: String in _effects.keys():
		var effect: Dictionary = _effects[id]
		effect["duration"] = maxf(float(effect.get("duration", 0.0)) - delta, 0.0)
		effect["elapsed"] = float(effect.get("elapsed", 0.0)) + delta
		if DAMAGE_OVER_TIME_IDS.has(id):
			_process_periodic(id, effect, delta)
		if float(effect["duration"]) <= 0.0:
			expired.append(id)
	for id: String in expired:
		_effects.erase(id)
		status_removed.emit(id)
		statuses_changed.emit()


func _process_periodic(id: String, effect: Dictionary, _delta: float) -> void:
	## Efecto por segundos (sangrado): emite periodic_tick cada intervalo acumulado.
	var interval := maxf(float(effect.get("params", {}).get("interval", 1.0)), 0.1)
	var elapsed := float(effect.get("elapsed", 0.0))
	var ticks_due := int(elapsed / interval)
	if ticks_due <= 0:
		return
	var last_tick := float(effect.get("last_tick", 0.0))
	if elapsed - last_tick >= interval:
		effect["last_tick"] = elapsed
		var payload := {
			"damage_per_tick": float(effect.get("params", {}).get("damage_per_tick", 0.0)),
			"source_id": String(effect.get("params", {}).get("source_id", "")),
		}
		periodic_tick.emit(id, payload)


func has(id: String) -> bool:
	return _effects.has(id)


func time_left(id: String) -> float:
	return maxf(float(_effects.get(id, {}).get("duration", 0.0)), 0.0)


func get_param(id: String, key: String, default: Variant = null) -> Variant:
	return _effects.get(id, {}).get("params", {}).get(key, default)


func active_ids() -> Array[String]:
	return _effects.keys().duplicate()


func clear() -> void:
	if _effects.is_empty():
		return
	_effects.clear()
	statuses_changed.emit()


func remove(id: String) -> void:
	if _effects.erase(id):
		status_removed.emit(id)
		statuses_changed.emit()


# ---------------------------------------------------------------------------
# Consultas derivadas (las que gobiernan las acciones del dueño)
# ---------------------------------------------------------------------------


func can_act() -> bool:
	## Aturdido o muerto no puede actuar: ni atacar, ni esquivar, ni habilidades.
	return not has("stun")


func can_move() -> bool:
	## Aturdido o enraizado no se mueve. El "root" (Raices del Juegey) deja
	## ACTUAR (atacar, lanzar) pero no desplazarse: control sin anular al
	## jugador/enemigo (identidad de la Bruja, Fase 2).
	return not has("stun") and not has("root")


func is_invulnerable() -> bool:
	return has("invulnerable")


func move_speed_multiplier() -> float:
	## Multiplicador de velocidad de movimiento (lento/resina lo bajan; prisa lo sube).
	var multiplier := 1.0
	for id: String in MOVE_SLOW_IDS:
		if has(id):
			multiplier *= clampf(1.0 - float(get_param(id, "slow_fraction", 0.4)), 0.05, 1.0)
	if has("haste"):
		multiplier *= maxf(float(get_param("haste", "multiplier", 1.0)), 1.0)
	return multiplier


func armor_multiplier() -> float:
	## Multiplicador de armadura (Corte de la Ceiba la rompe).
	if has("armor_break"):
		return clampf(1.0 - float(get_param("armor_break", "reduction", 0.5)), 0.0, 1.0)
	return 1.0


func incoming_damage_multiplier() -> float:
	## Vulnerable aumenta el daño recibido.
	if has("vulnerable"):
		return maxf(float(get_param("vulnerable", "multiplier", 1.25)), 1.0)
	return 1.0


func outgoing_damage_multiplier() -> float:
	## Potenciado (Pulso de monte) aumenta el daño del siguiente golpe.
	if has("empowered"):
		return maxf(float(get_param("empowered", "multiplier", 1.5)), 1.0)
	return 1.0


func consume(id: String) -> void:
	## Elimina un estado de un solo uso (p. ej. empowered tras el golpe).
	remove(id)

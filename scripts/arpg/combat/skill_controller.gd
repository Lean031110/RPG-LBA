class_name SkillController
extends Node
## Controlador de acciones de combate (Fase 5): ejecuta UNA acción a la vez
## con sus ventanas reales (windup → activa → recuperación), cadenas de combo,
## buffer de entrada e interrupciones. Lo usan el jugador y los enemigos con
## las mismas reglas (el enemigo no teletransporta daño: pasa por aquí).
##
## El controlador NO aplica daño: emite window_opened / window_tick para que
## el dueño resuelva impactos con su HitboxController y su DamageSystem.
##
## Fases: WINDUP (preparación) → ACTIVE (ventana de impacto) → RECOVER
## (recuperación, cancelable por esquiva a partir de cancel_after).

signal action_started(def: Dictionary)
signal window_opened(def: Dictionary)
signal window_tick(delta: float)
signal window_closed(def: Dictionary)
signal action_finished(def: Dictionary)
signal action_interrupted(def: Dictionary, reason: String)

enum Phase { READY, WINDUP, ACTIVE, RECOVER }

const MIN_SPEED := 0.25
const BUFFER_WINDOW := 0.45

var _phase: Phase = Phase.READY
var _def: Dictionary = {}
var _timer := 0.0
var _scaled_windup := 0.0
var _scaled_active_until := 0.0
var _scaled_total := 0.0
var _window_emitted := false
var _buffered: String = ""
var _buffer_timer := 0.0
var _attack_speed := 1.0


func set_attack_speed(speed: float) -> void:
	## Velocidad de ataque de las estadísticas (acorta todas las ventanas).
	_attack_speed = clampf(speed, MIN_SPEED, 4.0)


func is_busy() -> bool:
	return _phase != Phase.READY


func current_def() -> Dictionary:
	return _def


func current_phase() -> Phase:
	return _phase


func phase_name() -> String:
	match _phase:
		Phase.WINDUP:
			return "windup"
		Phase.ACTIVE:
			return "active"
		Phase.RECOVER:
			return "recover"
		_:
			return "ready"


func begin(def: Dictionary) -> bool:
	## Arranca una acción si el controlador está libre. Devuelve false si está
	## ocupada (el dueño decide si encolarla con buffer_input).
	if def.is_empty() or _phase != Phase.READY:
		return false

		# Asegura el orden windup <= active_until <= total.
	_def = def
	_timer = 0.0
	_window_emitted = false
	_scaled_windup = _scale(float(def.get("windup", 0.12)))
	_scaled_active_until = _scale(float(def.get("active_until", 0.3)))
	_scaled_total = _scale(float(def.get("total_time", 0.55)))
	# Asegura el orden windup <= active_until <= total.
	_scaled_active_until = maxf(_scaled_active_until, _scaled_windup)
	_scaled_total = maxf(_scaled_total, _scaled_active_until)
	_phase = Phase.WINDUP
	action_started.emit(def)
	return true


func buffer_input(action_id: String) -> void:
	## Encola la intención del jugador durante una acción en curso. Se consume
	## automáticamente al terminar la acción (cadena de combo) o caduca.
	_buffered = action_id
	_buffer_timer = BUFFER_WINDOW


func take_buffered() -> String:
	## Devuelve (y limpia) la acción encolada si sigue viva.
	if _buffered.is_empty() or _buffer_timer <= 0.0:
		return ""
	var action := _buffered
	_buffered = ""
	return action


func clear_buffer() -> void:
	_buffered = ""
	_buffer_timer = 0.0


func interrupt(reason: String) -> void:
	## Corte total (aturdimiento, muerte, derribo). La ventana se cierra SIEMPRE.
	if _phase == Phase.READY:
		return
	var def := _def
	_finish()
	action_interrupted.emit(def, reason)


func try_cancel_with_dodge() -> bool:
	## La esquiva puede cancelar la RECUPERACIÓN a partir de cancel_after
	## (dato de la habilidad; por defecto, desde que empieza la recuperación).
	if _phase != Phase.RECOVER:
		return false
	var cancel_after := _scale(float(_def.get("cancel_after", 0.0)))
	if _timer >= _scaled_active_until + cancel_after:
		var def := _def
		_finish()
		action_interrupted.emit(def, "dodge")
		return true
	return false


func advance(delta: float) -> void:
	## Máquina de fases. Se llama desde _physics_process del dueño.
	if _buffer_timer > 0.0:
		_buffer_timer = maxf(_buffer_timer - delta, 0.0)
		if _buffer_timer <= 0.0:
			_buffered = ""
	if _phase == Phase.READY:
		return
	_timer += delta
	match _phase:
		Phase.WINDUP:
			if _timer >= _scaled_windup:
				_phase = Phase.ACTIVE
				_window_emitted = true
				window_opened.emit(_def)
		Phase.ACTIVE:
			window_tick.emit(delta)
			if _timer > _scaled_active_until:
				_phase = Phase.RECOVER
				window_closed.emit(_def)
		Phase.RECOVER:
			if _timer >= _scaled_total:
				var def := _def
				_finish()
				action_finished.emit(def)
		_:
			pass


func elapsed() -> float:
	## Tiempo transcurrido de la acción en curso (presentación y pruebas).
	return _timer


func _finish() -> void:
	if _window_emitted:
		window_closed.emit(_def)
	_phase = Phase.READY
	_def = {}
	_timer = 0.0
	_window_emitted = false


func _scale(duration: float) -> float:
	## La velocidad de ataque acorta TODAS las fases proporcionalmente.
	return maxf(duration / _attack_speed, 0.01)

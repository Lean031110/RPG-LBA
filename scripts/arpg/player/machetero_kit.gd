# gdlint: ignore=max-public-methods
class_name MacheteroKit
extends ClassKit
## Kit del Machetero (Fase 5): combo ligero de 3 pasos, pesado, bloqueo con
## parada perfecta, Guardia del Bohio y Huracan de Machetes. La interfaz y la
## economia comun (definitiva, validaciones, esquiva, buffer) viven en
## ClassKit; aqui SOLO la identidad melee del Machetero.

const COMBO_RESET_TIME := 1.2

var _blocking := false
var _block_time := 0.0
var _guardia_left := 0.0
var _guardia_def := {}
var _combo_index := 0
var _combo_reset_left := 0.0
var _pending_spin_ticks := 0
var _spin_tick_timer := 0.0
var _spin_hit_sets: Array = []
var _action := "none"
var _action_timer := 0.0
var _action_params: Dictionary = {}


func _on_dodge_started() -> void:
	_guardia_left = 0.0
	ArpgArtKit.dust_burst(_player, _player.global_position + Vector3(0, 0.1, 0))


# ---------------------------------------------------------------------------
# Consultas propias
# ---------------------------------------------------------------------------


func is_blocking() -> bool:
	return _blocking


func get_combo_step() -> int:
	return _combo_index


func parry_window_elapsed() -> float:
	## Tiempo desde el arranque del bloqueo actual (ventana de parada perfecta).
	return _block_time


# ---------------------------------------------------------------------------
# Acciones
# ---------------------------------------------------------------------------


func try_attack() -> bool:
	## Ataque ligero: encadena el combo de 3 pasos si se pulsa durante la accion
	## (buffer de entrada). El combo caduca si se deja de atacar.
	if _player.is_dead() or not _player.statuses.can_act():
		return false
	var combo: Array = _class_data.get("combo_steps", [])
	var basic: Dictionary = _class_data.get("basic_attack", {})
	if combo.is_empty():
		return _start_attack_action(basic, "attack")
	if _player.skills.is_busy():
		_player.skills.buffer_input("attack")
		return false
	if _combo_reset_left <= 0.0:
		_combo_index = 0
	var step: Dictionary = combo[clampi(_combo_index, 0, combo.size() - 1)]
	if not _start_attack_action(step, "attack"):
		return false
	_combo_index = (_combo_index + 1) % combo.size()
	_combo_reset_left = COMBO_RESET_TIME
	kit_combo_step_changed.emit(_combo_index)
	return true


func try_heavy_attack() -> bool:
	## Ataque pesado: lento, mas dano, empuje y parte de la armadura ignorada.
	if _player.is_dead() or not _player.statuses.can_act():
		return false
	var heavy: Dictionary = _class_data.get("heavy_attack", {})
	if heavy.is_empty():
		return false
	if _player.skills.is_busy():
		_player.skills.buffer_input("heavy")
		return false
	return _start_attack_action(heavy, "heavy")


func try_skill_index(index: int) -> bool:
	## Lanza la habilidad del hueco index (0..3): valida desbloqueo, coste y
	## recarga. Durante otra accion se encola en el buffer.
	if _player.is_dead() or not _player.statuses.can_act():
		return false
	var def := _player.get_skill_def(index)
	if _skill_blocked(def):
		return false
	if _player.skills.is_busy():
		_player.skills.buffer_input(String(def.get("id", "")))
		return false
	_player.vigor -= float(def.get("resource_cost", 0))
	_player.cooldowns.start(String(def.get("id", "")), float(def.get("cooldown", 5.0)))
	_player.stats_changed.emit()
	kit_skill_cast.emit(String(def.get("id", "")))
	if String(def.get("kind", "")) == "stance":
		return _begin_stance(def)
	return _start_attack_action(def, "skill", def)


func try_ultimate() -> bool:
	## Definitiva: requiere nivel de desbloqueo y carga completa; consume toda
	## la carga al lanzarse (Huracan de Machetes: giro + avance + ruptura).
	if _player.is_dead() or not _player.statuses.can_act() or _player.skills.is_busy():
		return false
	var def: Dictionary = _class_data.get("ultimate", {})
	if def.is_empty() or not _player.is_skill_def_unlocked(def) or _ultimate_charge < _ultimate_max:
		return false
	_ultimate_charge = 0.0
	kit_charge_changed.emit(_ultimate_charge, _ultimate_max)
	kit_ultimate_cast.emit()
	_pending_spin_ticks = int(def.get("spin_ticks", 5))
	_spin_hit_sets = []
	for _tick: int in _pending_spin_ticks:
		_spin_hit_sets.append([])
	_spin_tick_timer = 0.0
	_player.cooldowns.start("ultimate", float(def.get("cooldown", 1.0)))
	return _start_attack_action(def, "ultimate", def)


func set_blocking(active: bool) -> bool:
	## Bloqueo mantenido (boton tactil o tecla). Se puede ENGANCHAR durante una
	## accion, pero solo protege cuando no hay accion en curso (regla ARPG:
	## no se bloquea en mitad del tajo). La ventana de parada se rearma al
	## pulsar de nuevo y al empezar cada accion. Devuelve si cambio.
	if _player.is_dead() or active == _blocking:
		return false
	if active and (_player.is_dodging or not _player.statuses.can_act()):
		return false
	_blocking = active
	_block_time = 0.0
	kit_blocking_changed.emit(_blocking)
	return true


func parry_triggered(attacker_stun_duration: float, attacker: Node3D) -> void:
	## Pulso de monte conectado: el jugador resolvio la parada; el kit registra
	## la potenciacion, la carga y el aturdimiento del atacante con la Guardia.
	var block: Dictionary = _class_data.get("block", {})
	_player.vigor = minf(_player.vigor + float(block.get("parry_vigor_restore", 10.0)), _player.max_vigor)
	_player.statuses.apply("empowered", 10.0, {"multiplier": float(block.get("parry_empower_multiplier", 1.5))})
	gain_ultimate_charge(float(_charge_gain.get("per_parry", 0.0)))
	if _guardia_left > 0.0 and attacker != null and attacker.has_method("apply_stun"):
		attacker.apply_stun(attacker_stun_duration)


func tick(delta: float) -> void:
	## Relojes del kit (llamado desde _physics_process del jugador).
	if _combo_reset_left > 0.0:
		_combo_reset_left = maxf(_combo_reset_left - delta, 0.0)
		if _combo_reset_left <= 0.0:
			_combo_index = 0
	elif _combo_index != 0:
		_combo_reset_left = COMBO_RESET_TIME
	if _blocking:
		_block_time += delta
	if _guardia_left > 0.0:
		_guardia_left = maxf(_guardia_left - delta, 0.0)
	_player.stats.block_reduction = effective_block_reduction()
	if _player.is_dodging:
		_action_timer += delta
		var duration := maxf(float(_action_params.get("duration", 0.3)), 0.05)
		if _action_timer >= duration:
			end_action()


func end_action() -> void:
	_action = "none"
	_action_params = {}
	_action_timer = 0.0
	_player.is_dodging = false
	_player.hitbox.close()
	_pending_spin_ticks = 0


func stop_on_death() -> void:
	## Muerte del jugador: el kit suelta bloqueo, accion y carga pendiente.
	_blocking = false
	super.stop_on_death()


# ---------------------------------------------------------------------------
# Internos: arranque de acciones, postura y ventanas melee
# ---------------------------------------------------------------------------


func _start_attack_action(params: Dictionary, kind: String, def: Dictionary = {}) -> bool:
	## Arranca una accion ofensiva por el SkillController (ventanas reales).
	var attack_cooldown := float(params.get("cooldown", _class_data.get("basic_attack", {}).get("cooldown", 0.55)))
	if kind == "attack" and _player.cooldowns.left("attack") > 0.0:
		return false
	if kind == "heavy" and _player.cooldowns.left("heavy") > 0.0:
		return false
	_action = kind
	_action_timer = 0.0
	_action_params = def if not def.is_empty() else params
	_player.hitbox.reset_swing()
	# La ventana de parada se rearma al empezar una accion: el bloqueo previo
	# no cuenta para la parada perfecta del siguiente golpe.
	_block_time = 0.0
	if not _player.skills.begin(params):
		return false
	if kind == "attack":
		_player.cooldowns.start("attack", attack_cooldown)
	elif kind == "heavy":
		_player.cooldowns.start("heavy", float(params.get("cooldown", 4.5)))
	kit_action_started.emit(kind)
	return true


func _begin_stance(def: Dictionary) -> bool:
	## Guardia del Bohio: postura sin ventana de golpe; activa el bloqueo
	## reforzado durante su duracion.
	_guardia_def = def
	_guardia_left = float(def.get("stance_duration", 4.0))
	_player.stats.block_reduction = effective_block_reduction()
	set_blocking(true)
	_player.stats_changed.emit()
	return true


func effective_block_reduction() -> float:
	## Reduccion de bloqueo actual: la Guardia del Bohio pisa la base mientras
	## la postura esta activa.
	var base := float(_class_data.get("base_stats", {}).get("block_reduction", 0.5))
	if _guardia_left > 0.0 and not _guardia_def.is_empty():
		return maxf(float(_guardia_def.get("stance_block_reduction", base)), base)
	return base


func _on_skill_action_started(def: Dictionary) -> void:
	## Orientar hacia la direccion de entrada para las tecnicas que avanzan
	## (Carga del Mambi y Huracan van de frente).
	var kind := String(def.get("kind", ""))
	if kind == "dash" or kind == "spin":
		_player.orient_to_input_or_forward()


func _on_attack_window_opened(def: Dictionary) -> void:
	## La ventana activa empieza: abrir la geometria real del golpe.
	var reach := float(def.get("range", 2.6))
	var arc := float(def.get("arc_deg", 100.0))
	if reach > 0.0 and arc > 0.0:
		_player.hitbox.open(reach, arc)


func _on_attack_window_tick(delta: float) -> void:
	## Cada frame de ventana activa: resolver impactos nuevos (golpe unico por
	## swing; el Huracan rearma los objetivos por tick).
	var def := _player.skills.current_def()
	if def.is_empty() or not _player.hitbox.is_open():
		return
	if String(def.get("kind", "")) == "spin":
		_process_spin_tick(delta)
		return
	for body: Node in _player.hitbox.collect_new_hits():
		_player.resolve_strike(body, def)


func _process_spin_tick(delta: float) -> void:
	## Huracan de Machetes: N ticks de golpe en 360 grados; cada tick puede
	## golpear a cada enemigo una vez. El ultimo tick es el remate.
	var def := _player.skills.current_def()
	var spin_span := maxf(float(def.get("active_until", 1.85)) - float(def.get("windup", 0.25)), 0.1)
	var spin_interval := spin_span / maxf(_pending_spin_ticks, 1)
	_spin_tick_timer += delta
	var tick_index := clampi(int(_spin_tick_timer / maxf(spin_interval, 0.05)), 0, _pending_spin_ticks - 1)
	if tick_index >= _spin_hit_sets.size():
		return
	_player.hitbox.reset_swing()
	var is_finisher: bool = tick_index == _pending_spin_ticks - 1
	for body: Node in _player.hitbox.collect_new_hits():
		if body in _spin_hit_sets[tick_index]:
			continue
		_spin_hit_sets[tick_index].append(body)
		var tick_def := def.duplicate()
		if is_finisher:
			tick_def["damage_coeff"] = float(def.get("finisher_damage_coeff", 1.8))
			tick_def["on_hit_status"] = def.get("finisher_status", {})
		else:
			tick_def["damage_coeff"] = float(def.get("tick_damage_coeff", 0.8))
			tick_def.erase("on_hit_status")
		_player.resolve_strike(body, tick_def)

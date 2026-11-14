# gdlint: ignore=max-public-methods
class_name MacheteroKit
extends Node
## Controlador del kit del Machetero (Fase 5; prompt: AttackController +
## SkillController): ejecuta combo ligero, ataque pesado, las 4 habilidades y
## la definitiva con las ventanas reales del SkillController compartido y el
## buffer de entrada. Posee el estado del kit (combo, bloqueo, guardia, carga
## de definitiva) y lo expone por señales; el jugador delega aquí sus acciones
## ofensivas/defensivas para mantener el archivo principal acotado.
##
## El kit NO conoce el HUD: emite señales a través del jugador (fachada) y el
## HUD sigue escuchando al jugador como en fases anteriores.

signal kit_action_started(kind: String)
signal kit_skill_cast(skill_id: String)
signal kit_ultimate_cast
signal kit_charge_changed(current: float, maximum: float)
signal kit_blocking_changed(is_blocking: bool)
signal kit_combo_step_changed(step: int)

const COMBO_RESET_TIME := 1.2

var _player: ArpgPlayer = null
var _class_data: Dictionary = {}
var _charge_gain := {}
var _ultimate_max := 100.0
var _ultimate_charge := 0.0
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


func setup(player: ArpgPlayer) -> void:
	_player = player
	_class_data = player.class_data
	_charge_gain = _class_data.get("ultimate_charge", {})
	_ultimate_max = float(_charge_gain.get("max", 100.0))
	player.skills.window_opened.connect(_on_attack_window_opened)
	player.skills.window_tick.connect(_on_attack_window_tick)
	player.skills.action_started.connect(_on_skill_action_started)
	player.skills.action_finished.connect(_on_skill_action_finished)
	player.skills.action_interrupted.connect(_on_skill_action_interrupted)
	player.combatant_damaged.connect(_on_player_damaged)


func _on_player_damaged(_amount: float) -> void:
	gain_ultimate_charge(float(_charge_gain.get("per_hit_taken", 0.0)))


# ---------------------------------------------------------------------------
# Consultas (el jugador las expone al HUD)
# ---------------------------------------------------------------------------


func is_blocking() -> bool:
	return _blocking


func get_ultimate_charge() -> float:
	return _ultimate_charge


func get_ultimate_max() -> float:
	return _ultimate_max


func get_ultimate_charge_fraction() -> float:
	return clampf(_ultimate_charge / _ultimate_max, 0.0, 1.0) if _ultimate_max > 0.0 else 0.0


func is_ultimate_ready() -> bool:
	return _ultimate_charge >= _ultimate_max and _player.is_skill_def_unlocked(_class_data.get("ultimate", {}))


func get_combo_step() -> int:
	return _combo_index


func parry_window_elapsed() -> float:
	## Tiempo desde el arranque del bloqueo actual (ventana de parada perfecta).
	return _block_time


func set_charge(value: float) -> void:
	## Carga de definitiva desde el guardado (restauración de partida).
	_ultimate_charge = clampf(value, 0.0, _ultimate_max)
	kit_charge_changed.emit(_ultimate_charge, _ultimate_max)


# ---------------------------------------------------------------------------
# Acciones
# ---------------------------------------------------------------------------


func try_attack() -> bool:
	## Ataque ligero: encadena el combo de 3 pasos si se pulsa durante la acción
	## (buffer de entrada). El combo caduta si se deja de atacar.
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
	## Ataque pesado: lento, más daño, empuje y parte de la armadura ignorada.
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
	## recarga. Durante otra acción se encola en el buffer.
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


func _skill_blocked(def: Dictionary) -> bool:
	## Razones por las que una habilidad no puede lanzarse ahora (desbloqueo,
	## recarga o recurso). Un solo punto de verdad para acción y HUD.
	return (
		def.is_empty()
		or not _player.is_skill_def_unlocked(def)
		or _player.cooldowns.left(String(def.get("id", ""))) > 0.0
		or _player.vigor < float(def.get("resource_cost", 0))
	)


func try_ultimate() -> bool:
	## Definitiva: requiere nivel de desbloqueo y carga completa; consume toda
	## la carga al lanzarse (Huracán de Machetes: giro + avance + ruptura).
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
	## Bloqueo mantenido (botón táctil o tecla). Se puede ENGANCHAR durante una
	## acción, pero solo protege cuando no hay acción en curso (regla ARPG:
	## no se bloquea en mitad del tajo). La ventana de parada se rearma al
	## pulsar de nuevo y al empezar cada acción. Devuelve si cambió.
	if _player.is_dead() or active == _blocking:
		return false
	if active and (_player.is_dodging or not _player.statuses.can_act()):
		return false
	_blocking = active
	_block_time = 0.0
	kit_blocking_changed.emit(_blocking)
	return true


func try_dodge() -> bool:
	## Esquiva: dirección de entrada (o frontal), coste de vigor, recarga y
	## cancelación de la recuperación de la acción en curso.
	if _player.is_dead() or not _player.statuses.can_act() or _player.is_dodging:
		return false
	if _blocking:
		set_blocking(false)
	if _player.cooldowns.left("dodge") > 0.0:
		return false
	# La esquiva puede cancelar la RECUPERACIÓN de una acción (no el windup).
	if _player.skills.is_busy():
		if not _player.skills.try_cancel_with_dodge():
			return false
	var dodge: Dictionary = _class_data.get("dodge", {})
	var cost := float(dodge.get("cost", 15))
	if _player.vigor < cost:
		return false
	_player.begin_dodge(dodge)
	_guardia_left = 0.0
	_player.vigor -= cost
	_player.cooldowns.start("dodge", float(dodge.get("cooldown", 1.2)))
	_player.stats_changed.emit()
	ArpgArtKit.dust_burst(_player, _player.global_position + Vector3(0, 0.1, 0))
	return true


func parry_triggered(attacker_stun_duration: float, attacker: Node3D) -> void:
	## Pulso de monte conectado: el jugador resolvió la parada; el kit registra
	## la potenciación, la carga y el aturdimiento del atacante con la Guardia.
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
		if _guardia_left <= 0.0:
			_player.stats.block_reduction = effective_block_reduction()
	_player.stats.block_reduction = effective_block_reduction()
	if _player.is_dodging:
		_action_timer += delta
		var duration := maxf(float(_action_params.get("duration", 0.3)), 0.05)
		if _action_timer >= duration:
			end_action()


func gain_ultimate_charge(amount: float) -> void:
	if amount <= 0.0:
		return
	_ultimate_charge = clampf(_ultimate_charge + amount, 0.0, _ultimate_max)
	kit_charge_changed.emit(_ultimate_charge, _ultimate_max)


func end_action() -> void:
	_action = "none"
	_action_params = {}
	_action_timer = 0.0
	_player.is_dodging = false
	_player.hitbox.close()
	_pending_spin_ticks = 0


# ---------------------------------------------------------------------------
# Internos: arranque de acciones, buffer y ventanas
# ---------------------------------------------------------------------------


func _start_attack_action(params: Dictionary, kind: String, def: Dictionary = {}) -> bool:
	## Arranca una acción ofensiva por el SkillController (ventanas reales).
	var attack_cooldown := float(params.get("cooldown", _class_data.get("basic_attack", {}).get("cooldown", 0.55)))
	if kind == "attack" and _player.cooldowns.left("attack") > 0.0:
		return false
	if kind == "heavy" and _player.cooldowns.left("heavy") > 0.0:
		return false
	_action = kind
	_action_timer = 0.0
	_action_params = def if not def.is_empty() else params
	_player.hitbox.reset_swing()
	# La ventana de parada se rearma al empezar una acción: el bloqueo previo
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
	## Guardia del Bohío: postura sin ventana de golpe; activa el bloqueo
	## reforzado durante su duración.
	_guardia_def = def
	_guardia_left = float(def.get("stance_duration", 4.0))
	_player.stats.block_reduction = effective_block_reduction()
	set_blocking(true)
	_player.stats_changed.emit()
	return true


func effective_block_reduction() -> float:
	## Reducción de bloqueo actual: la Guardia del Bohío pisa la base mientras
	## la postura está activa.
	var base := float(_class_data.get("base_stats", {}).get("block_reduction", 0.5))
	if _guardia_left > 0.0 and not _guardia_def.is_empty():
		return maxf(float(_guardia_def.get("stance_block_reduction", base)), base)
	return base


func _on_skill_action_started(def: Dictionary) -> void:
	## Orientar hacia la dirección de entrada para las técnicas que avanzan
	## (Carga del Mambí y Huracán van de frente).
	var kind := String(def.get("kind", ""))
	if kind == "dash" or kind == "spin":
		_player.orient_to_input_or_forward()


func _on_skill_action_finished(_def: Dictionary) -> void:
	end_action()
	_consume_buffered_input()


func _on_skill_action_interrupted(_def: Dictionary, _reason: String) -> void:
	end_action()


func _consume_buffered_input() -> void:
	## Buffer de entrada: al terminar una acción se ejecuta la intención
	## encolada si sigue viva (cadenas de combo fluidas).
	var buffered := _player.skills.take_buffered()
	if buffered.is_empty():
		return
	match buffered:
		"attack":
			try_attack()
		"heavy":
			try_heavy_attack()
		_:
			var index := _player.get_skill_index_by_id(buffered)
			if index >= 0:
				try_skill_index(index)


func _on_attack_window_opened(def: Dictionary) -> void:
	## La ventana activa empieza: abrir la geometría real del golpe.
	var reach := float(def.get("range", 2.6))
	var arc := float(def.get("arc_deg", 100.0))
	if reach > 0.0 and arc > 0.0:
		_player.hitbox.open(reach, arc)


func _on_attack_window_tick(delta: float) -> void:
	## Cada frame de ventana activa: resolver impactos nuevos (golpe único por
	## swing; el Huracán rearma los objetivos por tick).
	var def := _player.skills.current_def()
	if def.is_empty() or not _player.hitbox.is_open():
		return
	if String(def.get("kind", "")) == "spin":
		_process_spin_tick(delta)
		return
	for body: Node in _player.hitbox.collect_new_hits():
		_player.resolve_strike(body, def)


func _process_spin_tick(delta: float) -> void:
	## Huracán de Machetes: N ticks de golpe en 360°; cada tick puede golpear a
	## cada enemigo una vez. El último tick es el remate (rompe armadura).
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


func stop_on_death() -> void:
	## Muerte del jugador: el kit suelta bloqueo, acción y carga pendiente.
	_blocking = false
	kit_blocking_changed.emit(false)
	end_action()

# gdlint: ignore=max-public-methods
class_name ClassKit
extends Node
## Base comun de los kits de clase (Fase 2, ADR del motor comun): senales,
## estado de definitiva, validacion de habilidades y esquiva. Cada clase
## (Machetero, Bruja...) extiende este kit con su identidad mecanica; el
## jugador y el HUD dependen SOLO de esta interfaz, nunca del tipo concreto.
##
## Convenciones:
## - El kit NO conoce el HUD: emite senales a traves del jugador (fachada).
## - El recurso del jugador se llama "vigor" en el motor (Vigor, Esencia,
##   Ceniza... segun la clase); es un dato de class_data["resource"].
## - Las clases sin bloqueo (p. ej. la Bruja) dejan set_blocking sin efecto.

signal kit_action_started(kind: String)
signal kit_skill_cast(skill_id: String)
signal kit_ultimate_cast
signal kit_charge_changed(current: float, maximum: float)
signal kit_blocking_changed(is_blocking: bool)
signal kit_combo_step_changed(step: int)

var _player: ArpgPlayer = null
var _class_data: Dictionary = {}
var _charge_gain := {}
var _ultimate_max := 100.0
var _ultimate_charge := 0.0


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
	_on_setup()


func _on_setup() -> void:
	## Hook de la clase tras el setup base.
	pass


func _on_player_damaged(_amount: float) -> void:
	gain_ultimate_charge(float(_charge_gain.get("per_hit_taken", 0.0)))


# ---------------------------------------------------------------------------
# Consultas comunes (el jugador las expone al HUD)
# ---------------------------------------------------------------------------


func is_blocking() -> bool:
	return false


func can_block() -> bool:
	## Clases sin "block" en sus datos no bloquean (identidad de clase).
	return not _class_data.get("block", {}).is_empty()


func get_ultimate_charge() -> float:
	return _ultimate_charge


func get_ultimate_max() -> float:
	return _ultimate_max


func get_ultimate_charge_fraction() -> float:
	return clampf(_ultimate_charge / _ultimate_max, 0.0, 1.0) if _ultimate_max > 0.0 else 0.0


func is_ultimate_ready() -> bool:
	return _ultimate_charge >= _ultimate_max and _player.is_skill_def_unlocked(_class_data.get("ultimate", {}))


func get_combo_step() -> int:
	return 0


func parry_window_elapsed() -> float:
	## Tiempo desde el arranque del bloqueo actual (ventana de parada perfecta).
	## Solo lo implementan las clases con parada (Machetero).
	return 0.0


func effective_block_reduction() -> float:
	return 0.0


func resource_regen_multiplier() -> float:
	## Multiplicador de la regeneracion de recurso de la clase (pasivas de
	## reposo como el Oido de la Manigua de la Bruja). 1.0 = sin cambio.
	return 1.0


func set_charge(value: float) -> void:
	## Carga de definitiva desde el guardado (restauracion de partida).
	_ultimate_charge = clampf(value, 0.0, _ultimate_max)
	kit_charge_changed.emit(_ultimate_charge, _ultimate_max)


func gain_ultimate_charge(amount: float) -> void:
	if amount <= 0.0:
		return
	_ultimate_charge = clampf(_ultimate_charge + amount, 0.0, _ultimate_max)
	kit_charge_changed.emit(_ultimate_charge, _ultimate_max)


# ---------------------------------------------------------------------------
# Acciones: esquiva comun (identica en todas las clases por datos) y
# virtuales de clase.
# ---------------------------------------------------------------------------


func try_dodge() -> bool:
	## Esquiva: direccion de entrada (o frontal), coste de recurso, recarga y
	## cancelacion de la recuperacion de la accion en curso.
	if _player.is_dead() or not _player.statuses.can_act() or _player.is_dodging:
		return false
	if is_blocking():
		set_blocking(false)
	if _player.cooldowns.left("dodge") > 0.0:
		return false
	# La esquiva puede cancelar la RECUPERACION de una accion (no el windup).
	if _player.skills.is_busy():
		if not _player.skills.try_cancel_with_dodge():
			return false
	var dodge: Dictionary = _class_data.get("dodge", {})
	var cost := float(dodge.get("cost", 15))
	if _player.vigor < cost:
		return false
	_player.begin_dodge(dodge)
	_on_dodge_started()
	_player.vigor -= cost
	_player.cooldowns.start("dodge", float(dodge.get("cooldown", 1.2)))
	_player.stats_changed.emit()
	return true


func _on_dodge_started() -> void:
	## Hook visual/logico de la clase al esquivar (VFX, posturas...).
	pass


func try_attack() -> bool:
	return false


func try_heavy_attack() -> bool:
	return false


func try_skill_index(_index: int) -> bool:
	return false


func try_ultimate() -> bool:
	return false


func set_blocking(_active: bool) -> bool:
	## Clases sin bloqueo: la orden se ignora (y el HUD lo oculta con can_block).
	return false


func tick(_delta: float) -> void:
	## Relojes del kit (llamado desde _physics_process del jugador).
	pass


func stop_on_death() -> void:
	## Muerte del jugador: el kit suelta bloqueo y estado pendiente.
	kit_blocking_changed.emit(false)
	end_action()


func end_action() -> void:
	pass


# ---------------------------------------------------------------------------
# Valores y validaciones compartidas
# ---------------------------------------------------------------------------


func _skill_blocked(def: Dictionary) -> bool:
	## Razones por las que una habilidad no puede lanzarse ahora (desbloqueo,
	## recarga o recurso). Un solo punto de verdad para accion y HUD.
	return (
		def.is_empty()
		or not _player.is_skill_def_unlocked(def)
		or _player.cooldowns.left(String(def.get("id", ""))) > 0.0
		or _player.vigor < float(def.get("resource_cost", 0))
	)


func _consume_buffered_input() -> void:
	## Buffer de entrada: al terminar una accion se ejecuta la intencion
	## encolada si sigue viva (cadenas fluidas).
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


# ---------------------------------------------------------------------------
# Ventanas del SkillController (cada clase interpreta la suya)
# ---------------------------------------------------------------------------


func _on_attack_window_opened(_def: Dictionary) -> void:
	pass


func _on_attack_window_tick(_delta: float) -> void:
	pass


func _on_skill_action_started(_def: Dictionary) -> void:
	pass


func _on_skill_action_finished(_def: Dictionary) -> void:
	end_action()
	_consume_buffered_input()


func _on_skill_action_interrupted(_def: Dictionary, _reason: String) -> void:
	end_action()

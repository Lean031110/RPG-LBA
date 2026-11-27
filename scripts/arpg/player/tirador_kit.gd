class_name TiradorKit
extends ClassKit
## Primer incremento jugable del Tirador del Malecón: ataque básico físico a
## distancia. Usa el controlador común de ventanas, las estadísticas del jugador
## y ArpgProjectile; la clase sigue incompleta hasta implementar su kit canónico.

var _pending_shots := 0
var _shot_interval := 0.0
var _shot_timer := 0.0
var _volley_index := 0
var _volley_count := 0
var _volley_def: Dictionary = {}
var _volley_origin := Vector3.ZERO
var _volley_direction := Vector3.FORWARD
var _volley_lateral := Vector3.RIGHT
var _volley_spread_degrees := 0.0


func try_attack() -> bool:
	if _player.is_dead() or not _player.statuses.can_act():
		return false
	var basic: Dictionary = _class_data.get("basic_attack", {})
	if basic.is_empty() or not bool(basic.get("implemented", false)):
		return false
	if _player.cooldowns.left("attack") > 0.0:
		return false
	if _player.skills.is_busy():
		_player.skills.buffer_input("attack")
		return false
	if not _player.skills.begin(basic):
		return false
	_player.cooldowns.start("attack", float(basic.get("cooldown", 0.75)))
	kit_action_started.emit("attack")
	return true


func try_skill_index(index: int) -> bool:
	## Lanza una tecnica del Tirador con el mismo contrato de desbloqueo, coste,
	## recarga y buffer que las demas clases.
	if _player.is_dead() or not _player.statuses.can_act():
		return false
	var def := _player.get_skill_def(index)
	if _skill_blocked(def):
		return false
	if _player.skills.is_busy():
		_player.skills.buffer_input(String(def.get("id", "")))
		return false
	if not _player.skills.begin(def):
		return false
	_player.vigor -= float(def.get("resource_cost", 0.0))
	_player.cooldowns.start(String(def.get("id", "")), float(def.get("cooldown", 5.0)))
	_player.stats_changed.emit()
	kit_skill_cast.emit(String(def.get("id", "")))
	kit_action_started.emit("skill")
	return true


func _on_skill_action_started(_def: Dictionary) -> void:
	_player.orient_to_input_or_forward()


func _on_attack_window_opened(def: Dictionary) -> void:
	if String(def.get("kind", "")) != "projectile":
		return
	_spawn_projectile(def)


func _on_attack_window_tick(delta: float) -> void:
	if _pending_shots <= 0:
		return
	_shot_timer += delta
	if _shot_timer < _shot_interval:
		return
	if _player.skills.phase_name() != "active":
		_clear_pending_shots()
		return
	_shot_timer = 0.0
	if not _fire_volley_shot():
		_clear_pending_shots()
		return
	_pending_shots -= 1
	_volley_index += 1
	if _pending_shots <= 0:
		_clear_pending_shots()


func _on_skill_action_finished(def: Dictionary) -> void:
	_clear_pending_shots()
	super._on_skill_action_finished(def)


func _on_skill_action_interrupted(def: Dictionary, reason: String) -> void:
	_clear_pending_shots()
	super._on_skill_action_interrupted(def, reason)


func stop_on_death() -> void:
	_clear_pending_shots()
	super.stop_on_death()


func _spawn_projectile(def: Dictionary) -> void:
	_clear_pending_shots()
	var parent := _player.get_parent()
	if parent == null:
		return
	var origin := _player.global_position + Vector3(0.0, 1.0, 0.0)
	var direction := _player.global_transform.basis.z
	if _player.targeting.has_target():
		var target := _player.targeting.current()
		if target != null and is_instance_valid(target):
			direction = (target.global_position + Vector3(0.0, 1.0, 0.0) - origin).normalized()
	var projectile_data: Dictionary = def.get("projectile", {})
	var shot_count := clampi(int(projectile_data.get("shot_count", 1)), 1, 4)
	_volley_def = def
	_volley_origin = origin
	_volley_direction = direction
	_volley_lateral = direction.cross(Vector3.UP).normalized()
	if _volley_lateral.is_zero_approx():
		_volley_lateral = Vector3.RIGHT
	_volley_spread_degrees = clampf(float(projectile_data.get("spread_deg", 0.0)), 0.0, 30.0)
	_volley_count = shot_count
	_volley_index = 0
	if not _fire_volley_shot():
		return
	_pending_shots = shot_count - 1
	_shot_interval = maxf(float(projectile_data.get("shot_interval", 0.1)), 0.05)
	_shot_timer = 0.0


func _fire_volley_shot() -> bool:
	var parent := _player.get_parent()
	if parent == null:
		return false
	var spread_offset := float(_volley_index) - float(_volley_count - 1) * 0.5
	var shot_direction := (
		_volley_direction.rotated(Vector3.UP, deg_to_rad(_volley_spread_degrees * spread_offset)).normalized()
	)
	var shot_origin := _volley_origin + _volley_lateral * spread_offset * 0.1
	var projectile := ArpgProjectile.make(
		_player, _volley_def, shot_direction, shot_origin, _player.HITBOX_LAYER, _player.HITBOX_MASK, ArpgLayers.WORLD
	)
	parent.add_child(projectile)
	return true


func _clear_pending_shots() -> void:
	_pending_shots = 0
	_shot_interval = 0.0
	_shot_timer = 0.0
	_volley_index = 0
	_volley_count = 0
	_volley_def = {}

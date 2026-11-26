class_name TiradorKit
extends ClassKit
## Primer incremento jugable del Tirador del Malecón: ataque básico físico a
## distancia. Usa el controlador común de ventanas, las estadísticas del jugador
## y ArpgProjectile; la clase sigue incompleta hasta implementar su kit canónico.


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


func _on_skill_action_started(_def: Dictionary) -> void:
	_player.orient_to_input_or_forward()


func _on_attack_window_opened(def: Dictionary) -> void:
	if String(def.get("kind", "")) != "projectile":
		return
	_spawn_projectile(def)


func _spawn_projectile(def: Dictionary) -> void:
	var parent := _player.get_parent()
	if parent == null:
		return
	var origin := _player.global_position + Vector3(0.0, 1.0, 0.0)
	var direction := _player.global_transform.basis.z
	if _player.targeting.has_target():
		var target := _player.targeting.current()
		if target != null and is_instance_valid(target):
			direction = (target.global_position + Vector3(0.0, 1.0, 0.0) - origin).normalized()
	var projectile := ArpgProjectile.make(
		_player, def, direction, origin, _player.HITBOX_LAYER, _player.HITBOX_MASK, ArpgLayers.WORLD
	)
	parent.add_child(projectile)

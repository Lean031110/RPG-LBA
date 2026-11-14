class_name ArpgCombatant
extends CharacterBody3D
## Base de combate compartida (Fase 5): jugador y enemigos heredan de aquí y
## usan EL MISMO motor — componentes de recarga/estados/hitbox/habilidades,
## misma resolución de daño (DamageSystem) y mismos eventos (CombatEvents).
## Requisito del prompt: "Los enemigos deben participar en el mismo motor de
## combate que utiliza el jugador".
##
## Los combatientes específicos personalizan mediante métodos virtuales:
##   _resolve_special_defense(amount, context) -> Dictionary (parada/bloqueo/esquiva)
##   _apply_reactions(context)                  (empujes y estados al recibir)
##   _on_combatant_died()                       (presentación de la muerte)

signal combatant_died
signal combatant_damaged(amount: float)

const HURT_GRACE_TIME := 0.25
const KNOCKBACK_DECAY := 8.0

var stats: CombatStats = null
var cooldowns := CooldownController.new()
var statuses := StatusEffectController.new()
var skills := SkillController.new()
var hitbox := HitboxController.new()
var hp := 1.0
var max_hp := 1.0

var _dead := false
var _hurt_grace_left := 0.0
var _knockback_velocity := Vector3.ZERO
var _rng := RandomNumberGenerator.new()


func mount_combat(hitbox_layer: int, hitbox_mask: int) -> void:
	## Monta los componentes compartidos como hijos del cuerpo y prepara la
	## hitbox con el dueño correcto (capas y máscara por combatiente).
	add_child(skills)
	add_child(hitbox)
	hitbox.setup(self, hitbox_layer, hitbox_mask, ArpgLayers.WORLD)
	skills.window_closed.connect(func(_def: Dictionary) -> void: hitbox.close())
	statuses.periodic_tick.connect(_on_status_periodic_tick)


func tick_combat(delta: float) -> void:
	## Relojes comunes de combate (llamar desde _physics_process del hijo).
	cooldowns.tick(delta)
	statuses.tick(delta)
	_hurt_grace_left = maxf(_hurt_grace_left - delta, 0.0)
	if _knockback_velocity.length() > 0.001:
		_knockback_velocity = _knockback_velocity.move_toward(
			Vector3.ZERO, KNOCKBACK_DECAY * _knockback_velocity.length() * delta
		)


func is_dead() -> bool:
	return _dead


func revive_combatant() -> void:
	## Devuelve al combatiente a la vida con recursos llenos y estados limpios.
	## La posición y la presentación las decide el hijo (revive/respawn).
	if not _dead:
		return
	_dead = false
	hp = max_hp
	_hurt_grace_left = 0.0
	_knockback_velocity = Vector3.ZERO
	statuses.clear()
	cooldowns.clear()


func get_combat_stats() -> CombatStats:
	return stats


func get_status_controller() -> StatusEffectController:
	return statuses


func get_status_ids() -> Array[String]:
	## Estados activos (chips del HUD del jugador y del marco de objetivo).
	return statuses.active_ids()


func apply_status(id: String, duration: float, params: Dictionary = {}) -> void:
	## API de estados alterados (la usan las habilidades y otros combatientes).
	if _dead or duration <= 0.0:
		return
	statuses.apply(id, duration, params)


func apply_stun(duration: float) -> void:
	## Aturdimiento: interrumpe la acción en curso y bloquea nuevas acciones
	## hasta que expire (un aturdido no ataca ni esquiva).
	if _dead or duration <= 0.0:
		return
	statuses.apply("stun", duration)
	skills.interrupt("stunned")


func heal(amount: float) -> float:
	var before := hp
	hp = minf(hp + amount, max_hp)
	return hp - before


# ---------------------------------------------------------------------------
# Daño entrante (canal único para TODOS los combatientes)
# ---------------------------------------------------------------------------


func take_damage(amount: float, context: Dictionary = {}) -> bool:
	## Pipeline compartido: muerte/inmune → defensa especial (virtual) → gracia
	## de golpe → aplicación → reacciones (virtual) → muerte.
	## Devuelve true si el daño se aplicó (aunque fuese reducido).
	if _dead or amount <= 0.0:
		return false
	if statuses.is_invulnerable():
		return false
	var special := _resolve_special_defense(amount, context)
	if bool(special.get("handled", false)):
		return bool(special.get("applied", false))
	var final_amount := float(special.get("modified_amount", amount))
	if _hurt_grace_left > 0.0 and not bool(context.get("bypass_grace", false)):
		return false
	hp = maxf(hp - final_amount, 0.0)
	_hurt_grace_left = HURT_GRACE_TIME
	_apply_reactions(context)
	combatant_damaged.emit(final_amount)
	if hp <= 0.0:
		_dead = true
		statuses.clear()
		skills.interrupt("died")
		hitbox.close()
		_knockback_velocity = Vector3.ZERO
		_on_combatant_died()
		combatant_died.emit()
	return true


func _resolve_special_defense(_amount: float, _context: Dictionary) -> Dictionary:
	## Virtual: esquiva, parada, bloqueo... Por defecto nada especial.
	return {"handled": false, "modified_amount": _amount}


func _apply_reactions(context: Dictionary) -> void:
	## Virtual: empuje y demás reacciones al recibir daño. Por defecto aplica
	## el empuje del contexto reducido por la resistencia del combatiente.
	var knockback := float(context.get("knockback", 0.0))
	if knockback <= 0.0 or stats == null:
		return
	knockback *= clampf(1.0 - stats.knockback_resistance, 0.0, 1.0)
	var source := context.get("source") as Node3D
	var direction := Vector3.FORWARD
	if source != null:
		direction = global_position - source.global_position
		direction.y = 0.0
		if direction.length() > 0.05:
			direction = direction.normalized()
	_knockback_velocity = direction * knockback


func _on_combatant_died() -> void:
	## Virtual: presentación de la muerte (la lógica ya se aplicó).
	pass


func _on_status_periodic_tick(_id: String, _payload: Dictionary) -> void:
	## Virtual: daños periódicos (sangrado). El hijo decide cómo aplicarlos.
	pass


func consume_knockback() -> Vector3:
	## Velocidad de empuje pendiente (el hijo la mezcla en su locomoción).
	return _knockback_velocity


# ---------------------------------------------------------------------------
# Golpes salientes (canal único para TODOS los combatientes)
# ---------------------------------------------------------------------------


func resolve_strike(target: Node, def: Dictionary) -> void:
	## Golpe confirmado sobre un objetivo: cálculo por DamageSystem con las
	## estadísticas reales de ambos, estados alterados, y eventos para el HUD.
	## Los modificadores específicos (empoderar, perforar armadura) los añade
	## el hijo en _attacker_stats_for_strike / _pierce_for_strike.
	if target == null or not target.has_method("take_damage"):
		return

		# Estados de la técnica (sangrado, rotura, resina...): regla compartida por
		# jugador y enemigos (mismo motor, mismas consecuencias).
	var target_stats := _target_stats(target)
	if target_stats == null:
		return

		# Estados de la técnica (sangrado, rotura, resina...): regla compartida por
		# jugador y enemigos (mismo motor, mismas consecuencias).
	var attacker_stats := _attacker_stats_for_strike()
	var pierce := _pierce_for_strike(def)
	if pierce > 0.0:
		target_stats.armor *= clampf(1.0 - pierce, 0.0, 1.0)

		# Estados de la técnica (sangrado, rotura, resina...): regla compartida por
		# jugador y enemigos (mismo motor, mismas consecuencias).
	var result := DamageSystem.resolve(attacker_stats, target_stats, def, _rng, _target_statuses(target))
	if bool(result["immune"]):
		return

		# Estados de la técnica (sangrado, rotura, resina...): regla compartida por
		# jugador y enemigos (mismo motor, mismas consecuencias).
	var amount := float(result["amount"])
	target.take_damage(amount, _strike_context(def, bool(result["crit"])))
	# Estados de la técnica (sangrado, rotura, resina...): regla compartida por
	# jugador y enemigos (mismo motor, mismas consecuencias).
	_apply_strike_status(target, def)
	if target is Node3D:
		CombatEvents.damage_dealt.emit(target, amount, bool(result["crit"]), (target as Node3D).global_position)
	_on_strike_landed(target, amount, bool(result["crit"]), def)


func _attacker_stats_for_strike() -> CombatStats:
	## Virtual: estadísticas del atacante para el golpe (el jugador añade
	## empowered). Por defecto, las estadísticas actuales.
	return stats


func _pierce_for_strike(_def: Dictionary) -> float:
	## Virtual: perforación de armadura de la técnica (por defecto ninguna).
	return 0.0


func _strike_context(def: Dictionary, is_crit: bool) -> Dictionary:
	## Contexto estándar de un golpe: origen, crítico, empuje y aturdimiento.
	return {
		"source": self,
		"is_crit": is_crit,
		"knockback": float(def.get("knockback", 0.0)),
		"stun_duration": _stun_from_def(def),
	}


func _stun_from_def(def: Dictionary) -> float:
	var status_data: Dictionary = def.get("on_hit_status", {})
	if String(status_data.get("id", "")) == "stun":
		return float(status_data.get("duration", 0.0))
	return 0.0


func _apply_strike_status(target: Node, def: Dictionary) -> void:
	## Estados que la técnica aplica al objetivo (sangrado, rotura...).
	var status_data: Dictionary = def.get("on_hit_status", {})
	var status_id := String(status_data.get("id", ""))
	if status_id.is_empty() or status_id == "stun":
		return
	if target != null and target.has_method("apply_status"):
		var params: Dictionary = status_data.get("params", {})
		params["source_id"] = name
		target.apply_status(status_id, float(status_data.get("duration", 0.0)), params)


func _on_strike_landed(_target: Node, _amount: float, _is_crit: bool, _def: Dictionary) -> void:
	## Virtual: reacción del atacante al conectar (carga de definitiva, etc.).
	pass


func _target_stats(body: Node) -> CombatStats:
	if body == null:
		return null
	if body.has_method("get_combat_stats"):
		return body.get_combat_stats()
	var enemy_data: Dictionary = body.get("enemy_data") if body.get("enemy_data") != null else {}
	var fallback := CombatStats.new()
	fallback.armor = float(enemy_data.get("armor", 2))
	fallback.resistance = float(enemy_data.get("resistance", 2))
	fallback.primary_attribute = float(enemy_data.get("attribute_value", 10))
	return fallback


func _target_statuses(body: Node) -> StatusEffectController:
	if body != null and body.has_method("get_status_controller"):
		return body.get_status_controller()
	return null

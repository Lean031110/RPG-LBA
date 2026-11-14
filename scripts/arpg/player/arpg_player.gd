# gdlint: ignore=max-public-methods
# (Fase 5: el jugador es la fachada del Machetero — exposición completa del kit,
# consulta del HUD, progresión y persistencia — sobre la base compartida
# ArpgCombatant y el controlador MacheteroKit. La excepción está acotada a este
# archivo y documentada en docs/reportes/FASE_05_AUDITORIA.md.)
class_name ArpgPlayer
extends ArpgCombatant
## Jugador de la vertical slice: Machetero de la Sierra (única clase jugable).
## Definición 100% dirigida por datos (game/data/classes.json). Arquitectura
## Fase 5 (todo desacoplado, sin lógica gigante en un archivo):
##   - ArpgCombatant: motor de combate compartido con los enemigos.
##   - MacheteroKit: ejecución del kit (combo, pesado, 4 habilidades,
##     definitiva, bloqueo/parada, esquiva).
##   - PlayerInputProvider: entrada (teclado + joystick + marco de cámara).
##   - PlayerEquipment: puente con el inventario de equipo.
##   - PlayerSaveCodec: persistencia versionada.
##   - MacheteroPuppet: montaje visual y resolución de poses por estado.
## Este archivo coordina: progresión, atributos, locomoción y defensa.
##
## La animación jamás es fuente de verdad del daño: la hitbox solo está activa
## en su ventana. Lógica desacoplada de la UI: el HUD escucha señales.

signal leveled_up(new_level: int)
signal died
signal dodged
signal hit_landed(target: Node, amount: float, is_crit: bool)
signal potion_used(healed: float)
signal attack_started(kind: String)
signal action_started(kind: String)
signal skill_cast(skill_id: String)
signal ultimate_cast
signal ultimate_charge_changed(current: float, maximum: float)
signal blocking_changed(is_blocking: bool)
signal combo_step_changed(step: int)
signal stats_changed

const GRAVITY := 18.0
const DEFAULT_MOVE_ACCEL := 24.0
const DEFAULT_MOVE_DECEL := 30.0
const RUN_INPUT_THRESHOLD := 0.6
const DEFAULT_RUN_MULTIPLIER := 1.55
const FLOOR_SNAP := 0.25
const BODY_LAYER := ArpgLayers.PLAYER
const BODY_MASK := ArpgLayers.WORLD
const HITBOX_LAYER := ArpgLayers.HITBOX_PLAYER
const HITBOX_MASK := ArpgLayers.ENEMY

var class_id := "machetero"
var class_data: Dictionary = {}
var level := 1
var xp_into_level := 0
var attribute_points := 0
var vigor := 1.0
var max_vigor := 1.0
var potions := 1
var move_tier := "idle"
var inventory: PlayerInventory = null
var is_dodging := false

## Contrato público de fases anteriores (HUD y slice asignan directo); la
## lectura de la entrada vive en PlayerInputProvider.
var camera_source: Node3D = null:
	set(value):
		camera_source = value
		input.camera_source = value
var joystick_vector := Vector2.ZERO:
	set(value):
		joystick_vector = value
		input.joystick_vector = value

var kit := MacheteroKit.new()
var input := PlayerInputProvider.new()
var equipment := PlayerEquipment.new()
var targeting := TargetingSystem.new()

var _puppet: MacheteroPuppet = null
var _attributes := {}
var _walk_phase := 0.0
var _run_blend := 0.0
var _dodge_direction := Vector3.FORWARD
var _action_params: Dictionary = {}
var _vigor_regen := 0.0


func setup(new_class_id: String) -> void:
	class_id = new_class_id
	class_data = RpgDB.get_class_data(class_id)
	if class_data.is_empty():
		push_error("ArpgPlayer: clase desconocida %s" % class_id)
		return
	collision_layer = BODY_LAYER
	collision_mask = BODY_MASK
	_build_body_shape()
	floor_snap_length = FLOOR_SNAP
	_reset_stats()
	mount_combat(HITBOX_LAYER, HITBOX_MASK)
	add_child(targeting)
	targeting.setup(self, ArpgLayers.WORLD)
	add_child(kit)
	kit.setup(self)
	_wire_player_signals()
	_build_visual()
	inventory = PlayerInventory.new()
	equipment.setup(self)


func _build_body_shape() -> void:
	## Cápsula de colisión del cuerpo: sin ella no hay física de jugador (suelo,
	## muros, áreas enemigas). El error fue detectado por las pruebas de integración.
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	shape.position = Vector3(0, 0.95, 0)
	add_child(shape)


func _wire_player_signals() -> void:
	## El kit emite sus señales; el jugador las replica para mantener el
	## contrato del HUD de fases anteriores (fachada estable). El daño y la
	## curación (base ArpgCombatant) también avisan al HUD vía stats_changed.
	combatant_damaged.connect(func(_amount: float) -> void: stats_changed.emit())
	kit.kit_action_started.connect(
		func(kind: String) -> void:
			attack_started.emit(kind)
			action_started.emit(kind)
	)
	kit.kit_skill_cast.connect(func(skill_id: String) -> void: skill_cast.emit(skill_id))
	kit.kit_ultimate_cast.connect(func() -> void: ultimate_cast.emit())
	kit.kit_charge_changed.connect(
		func(current: float, maximum: float) -> void: ultimate_charge_changed.emit(current, maximum)
	)
	kit.kit_blocking_changed.connect(func(is_blocking: bool) -> void: blocking_changed.emit(is_blocking))
	kit.kit_combo_step_changed.connect(func(step: int) -> void: combo_step_changed.emit(step))


func _reset_stats() -> void:
	level = 1
	xp_into_level = 0
	attribute_points = 0
	_attributes = {}
	for attribute: String in ["fuerza", "destreza", "intelecto", "espiritu"]:
		_attributes[attribute] = float(class_data.get("base_stats", {}).get(attribute, 10))
	var resource: Dictionary = class_data.get("resource", {})
	max_hp = float(class_data.get("base_stats", {}).get("hp", 100))
	hp = max_hp
	max_vigor = float(resource.get("base", 100))
	vigor = max_vigor
	potions = 1
	_recalculate_from_level()


func _recalculate_from_level() -> void:
	## Crecimiento automático por clase (docs/diseno/02) + reconstrucción de las
	## estadísticas de combate (única fuente de verdad para HUD y DamageSystem).
	var growth: Dictionary = class_data.get("growth", {})
	var resource: Dictionary = class_data.get("resource", {})
	var levels_from_base := maxi(level - 1, 0)
	max_hp = (
		float(class_data["base_stats"].get("hp", 100)) + float(growth.get("hp_per_level", 0.0)) * levels_from_base
	)
	max_vigor = (float(resource.get("base", 100)) + float(resource.get("per_level", 0)) * levels_from_base)
	_vigor_regen = (
		float(resource.get("regen_per_second", 0.0)) + float(resource.get("regen_per_level", 0.0)) * levels_from_base
	)
	stats = CombatStats.from_class_data(class_data, level, get_attribute("fuerza"))
	stats.armor += equipment.armor_bonus()
	stats.attack_power += equipment.potency_bonus()
	stats.crit_chance += equipment.crit_bonus()
	stats.block_reduction = kit_block_reduction()
	hp = minf(hp, max_hp)
	vigor = minf(vigor, max_vigor)
	skills.set_attack_speed(stats.attack_speed)


func kit_block_reduction() -> float:
	## Puente para el cálculo del kit (guardia activa) sin romper el encapsulado.
	return (
		kit.effective_block_reduction()
		if kit != null
		else float(class_data.get("base_stats", {}).get("block_reduction", 0.5))
	)


# ---------------------------------------------------------------------------
# Consultas públicas (HUD y tests)
# ---------------------------------------------------------------------------


func get_class_name() -> String:
	return RpgDB.get_text(String(class_data.get("name_key", "")), "es")


func get_resource_name() -> String:
	return RpgDB.get_text(String(class_data.get("resource", {}).get("name_key", "")), "es")


func get_attribute(attribute: String) -> float:
	## Atributo actual = base de clase + puntos gastados (Fase 5: progresión canon).
	return float(_attributes.get(attribute, 10.0))


func spend_attribute_point(attribute: String, points := 1) -> bool:
	## Gasta puntos de atributo ganados al subir de nivel (canon: 5 por nivel).
	if attribute_points < points or not _attributes.has(attribute):
		return false
	attribute_points -= points
	_attributes[attribute] = float(_attributes[attribute]) + points
	_recalculate_from_level()
	stats_changed.emit()
	return true


func get_hp_fraction() -> float:
	return clampf(hp / max_hp, 0.0, 1.0) if max_hp > 0.0 else 0.0


func get_vigor_fraction() -> float:
	return clampf(vigor / max_vigor, 0.0, 1.0) if max_vigor > 0.0 else 0.0


func get_xp_fraction() -> float:
	return ProgressionService.xp_bar_fraction(level, xp_into_level, RpgDB.get_progression())


func get_level() -> int:
	return level


func get_potions() -> int:
	return potions


func is_blocking() -> bool:
	return kit.is_blocking()


func get_ultimate_charge() -> float:
	return kit.get_ultimate_charge()


func get_ultimate_charge_fraction() -> float:
	return kit.get_ultimate_charge_fraction()


func get_ultimate_max() -> float:
	return kit.get_ultimate_max()


func is_ultimate_ready() -> bool:
	return kit.is_ultimate_ready()


func get_skill_count() -> int:
	return class_data.get("skills", []).size()


func get_skill_def(index: int) -> Dictionary:
	var skill_list: Array = class_data.get("skills", [])
	if index < 0 or index >= skill_list.size():
		return {}
	return skill_list[index]


func get_ultimate_def() -> Dictionary:
	return class_data.get("ultimate", {})


func get_skill_index_by_id(skill_id: String) -> int:
	for index: int in get_skill_count():
		if String(get_skill_def(index).get("id", "")) == skill_id:
			return index
	return -1


func is_skill_unlocked(index: int) -> bool:
	return is_skill_def_unlocked(get_skill_def(index))


func is_skill_def_unlocked(def: Dictionary) -> bool:
	## Desbloqueo por nivel (S1:1, S2:2, S3:2, S4:3, Definitiva:3; datos).
	if def.is_empty():
		return false
	if not bool(def.get("implemented", true)):
		return false
	return level >= int(def.get("unlock_level", 1))


## Recargas restantes y totales (HUD: indicadores radiales). Fase 5: por
## identificador, con compatibilidad para las consultas de la Fase 3.


func get_skill_cooldown_left() -> float:
	return cooldowns.left(_skill_id_at(0))


func get_skill_cooldown_total() -> float:
	return _cooldown_total_or_data(_skill_id_at(0), get_skill_def(0).get("cooldown", 0.0))


func get_skill_cooldown_left_at(index: int) -> float:
	return cooldowns.left(_skill_id_at(index))


func get_skill_cooldown_total_at(index: int) -> float:
	return _cooldown_total_or_data(_skill_id_at(index), get_skill_def(index).get("cooldown", 0.0))


func get_dodge_cooldown_left() -> float:
	return cooldowns.left("dodge")


func get_dodge_cooldown_total() -> float:
	return _cooldown_total_or_data("dodge", float(class_data.get("dodge", {}).get("cooldown", 1.2)))


func get_heavy_cooldown_left() -> float:
	return cooldowns.left("heavy")


func get_heavy_cooldown_total() -> float:
	return _cooldown_total_or_data("heavy", float(class_data.get("heavy_attack", {}).get("cooldown", 4.0)))


func _cooldown_total_or_data(id: String, data_value: float) -> float:
	## Total registrado si hay recarga en curso; si no, el valor de datos
	## (el HUD necesita el total también antes del primer uso).
	if id.is_empty():
		return maxf(data_value, 0.0)
	var recorded := cooldowns.total(id)
	return recorded if recorded > 0.0 else maxf(data_value, 0.0)


func _skill_id_at(index: int) -> String:
	var def := get_skill_def(index)
	return String(def.get("id", "")) if not def.is_empty() else ""


# ---------------------------------------------------------------------------
# Progresión
# ---------------------------------------------------------------------------


func add_xp(amount: int) -> void:
	if amount <= 0 or is_dead():
		return

		# Diseño de la rebanada: al subir de nivel se restaura por completo (documentado).
	var result := ProgressionService.add_xp(level, xp_into_level, amount, RpgDB.get_progression())
	xp_into_level = int(result["xp_into_level"])
	attribute_points += int(result["points_gained"])
	if int(result["levels_gained"]) > 0:
		level = int(result["level"])
		_recalculate_from_level()
		# Diseño de la rebanada: al subir de nivel se restaura por completo (documentado).
		hp = max_hp
		vigor = max_vigor
		leveled_up.emit(level)
	stats_changed.emit()


# ---------------------------------------------------------------------------
# Defensa especial del jugador: esquiva, parada (Pulso de monte) y bloqueo
# ---------------------------------------------------------------------------


func _resolve_special_defense(amount: float, context: Dictionary) -> Dictionary:
	## Orden de resolución: esquiva (invulnerable durante toda la acción) →
	## parada perfecta (ventana inicial del bloqueo) → bloqueo (reducción).
	var unblockable := bool(context.get("unblockable", false))
	if is_dodging:
		dodged.emit()
		CombatEvents.attack_evaded.emit(self)
		return {"handled": true, "applied": false}
	if unblockable:
		return {"handled": false, "modified_amount": amount}
	var attacker := context.get("source") as Node3D
	if _try_parry(attacker):
		return {"handled": true, "applied": false}
	if kit.is_blocking() and not skills.is_busy() and _attacker_in_front(attacker):
		var pass_factor := CombatService.block_factor(stats.block_reduction)
		return {"handled": false, "modified_amount": amount * pass_factor}
	return {"handled": false, "modified_amount": amount}


func _try_parry(attacker: Node3D) -> bool:
	## Pulso de monte (pasiva canon): bloquear JUSTO cuando llega el golpe
	## anula el daño, restaura vigor y potencia el siguiente golpe. Con la
	## Guardia del Bohío activa, además aturde al atacante (lo aplica el kit).
	var block: Dictionary = class_data.get("block", {})
	var window := float(block.get("parry_window", 0.2))
	if not kit.is_blocking() or kit.parry_window_elapsed() > window:
		return false
	if attacker != null and not _attacker_in_front(attacker):
		return false
	kit.parry_triggered(float(_guardia_def_stun()), attacker)
	CombatEvents.attack_parried.emit(self)
	stats_changed.emit()
	return true


func _guardia_def_stun() -> float:
	if class_data.get("skills", []).is_empty():
		return 1.0
	for def: Dictionary in class_data.get("skills", []):
		if String(def.get("id", "")) == "guardia_del_bohio":
			return float(def.get("stance_parry_stun", 1.0))
	return 1.0


func _attacker_in_front(attacker: Node3D) -> bool:
	## El bloqueo/parada protegen el frontal (arco de 150°).
	if attacker == null:
		return true
	var to_attacker := attacker.global_position - global_position
	to_attacker.y = 0.0
	if to_attacker.length() < 0.05:
		return true
	var forward := Vector3(transform.basis.z.x, 0.0, transform.basis.z.z).normalized()
	return forward.dot(to_attacker.normalized()) >= -0.26


func _on_combatant_died() -> void:
	## Muerte del jugador: el kit suelta todo, presentación y señal del slice.
	kit.stop_on_death()
	if _puppet != null:
		_puppet.play_death()
	died.emit()


func _on_status_periodic_tick(id: String, payload: Dictionary) -> void:
	## Sangrado y demás daños periódicos: no esquivables ni bloqueables.
	if id == "bleed":
		take_damage(
			float(payload.get("damage_per_tick", 0.0)), {"source": null, "unblockable": true, "bypass_grace": true}
		)


# ---------------------------------------------------------------------------
# Golpes del jugador (extensiones del canal heredado)
# ---------------------------------------------------------------------------


func _attacker_stats_for_strike() -> CombatStats:
	## El golpe consume "empowered" (Pulso de monte) si está activo.
	return DamageSystem.resolve_attacker_empowered(statuses, stats)


func _pierce_for_strike(def: Dictionary) -> float:
	## El ataque pesado ignora parte de la armadura (dato de la técnica).
	return float(def.get("armor_pierce", 0.0))


func _on_strike_landed(target: Node, amount: float, is_crit: bool, _def: Dictionary) -> void:
	## Golpe conectado: carga de definitiva, señal del slice y foco de objetivo
	## para el HUD (los estados de la técnica los aplica la base compartida).
	kit.gain_ultimate_charge(float(class_data.get("ultimate_charge", {}).get("per_hit_dealt", 0.0)))
	hit_landed.emit(target, amount, is_crit)
	targeting.notify_hit(target as Node3D)
	if target is Node3D:
		var impact_color := Color(1.0, 0.72, 0.35) if is_crit else Color(0.95, 0.85, 0.6)
		ArpgArtKit.hit_spark(self, (target as Node3D).global_position + Vector3(0, 1.2, 0), impact_color)


# ---------------------------------------------------------------------------
# Acciones de combate (delegación al kit; fachada estable para HUD y slice)
# ---------------------------------------------------------------------------


func try_attack() -> bool:
	return kit.try_attack()


func try_heavy_attack() -> bool:
	return kit.try_heavy_attack()


func try_skill() -> bool:
	return kit.try_skill_index(0)


func try_skill_index(index: int) -> bool:
	return kit.try_skill_index(index)


func try_ultimate() -> bool:
	return kit.try_ultimate()


func set_blocking(active: bool) -> void:
	kit.set_blocking(active)


func try_dodge() -> bool:
	return kit.try_dodge()


func begin_dodge(dodge: Dictionary) -> void:
	## Arranque físico de la esquiva (lo llama el kit tras validar coste/recarga).
	var direction := _input_direction()
	_dodge_direction = direction if direction.length() > 0.1 else transform.basis.z
	is_dodging = true
	_action_params = dodge


func orient_to_input_or_forward() -> void:
	## Orientación de las técnicas con avance (Carga/Huracán): de frente a la
	## dirección de entrada, o al frente actual si no hay entrada.
	var direction := _input_direction()
	_face_towards(direction if direction.length() > 0.1 else transform.basis.z, 1.0)


func heal(amount: float) -> float:
	## Curación con aviso al HUD (la base no conoce las señales del jugador).
	var healed := super(amount)
	if healed > 0.0:
		stats_changed.emit()
	return healed


func try_potion() -> bool:
	if is_dead() or potions <= 0 or hp >= max_hp:
		return false
	var item := RpgDB.get_item("pocion_curativa")
	var heal_amount := float(item.get("heal_amount", 40))
	potions -= 1
	var healed := heal(heal_amount)
	potion_used.emit(healed)
	stats_changed.emit()
	return true


func add_potion(count := 1) -> void:
	potions += count
	stats_changed.emit()


func receive_item(item_id: String, count := 1) -> bool:
	## Guarda un objeto de equipo/misión en el inventario propio (delega en
	## PlayerEquipment). Las pociones siguen en el contador rápido (decisión
	## documentada de la rebanada).
	return equipment.receive_item(item_id, count)


func try_equip_weapon(slot_index := -1) -> bool:
	## Equipa/desequipa el arma del hueco (delega en PlayerEquipment; valida
	## kind=weapon y restricción de clase, y aplica bonuses a las estadísticas).
	return equipment.try_equip_weapon(slot_index)


# ---------------------------------------------------------------------------
# Entrada y movimiento
# ---------------------------------------------------------------------------


func _input_direction() -> Vector3:
	## Dirección de movimiento en XZ (teclado + joystick, marco de la cámara).
	return input.direction()


func _raw_input() -> Vector3:
	## Entrada combinada sin normalizar (magnitud = caminar/correr).
	return input.raw_input()


func _physics_process(delta: float) -> void:
	if class_data.is_empty():
		return
	tick_combat(delta)
	targeting.tick(delta)
	kit.tick(delta)
	if is_dead():
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		move_and_slide()
		return
	if not statuses.can_move():
		kit.end_action()
		kit.set_blocking(false)
	skills.advance(delta)
	_update_run_blend(delta)
	_apply_motion(delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	_animate_action(delta)


func _apply_motion(delta: float) -> void:
	## Movimiento por capas: acción especial (esquiva/carga/huracán) > empuje
	## recibido > bloqueo > locomoción normal por tiers.
	var special := _special_motion()
	if special != Vector3.INF:
		velocity.x = special.x
		velocity.z = special.z
		_face_motion(velocity, delta)
		return
	var knockback := consume_knockback()
	if knockback.length() > 0.05:
		velocity.x = knockback.x
		velocity.z = knockback.z
		_face_motion(velocity, delta)
		return
	if kit.is_blocking():
		_animate_walk(_walk_phase)
		var block_speed := float(class_data.get("block", {}).get("move_speed_multiplier", 0.55))
		var direction := _input_direction()
		var target := direction * stats.move_speed * block_speed * statuses.move_speed_multiplier()
		var planar := Vector3(velocity.x, 0, velocity.z).move_toward(target, DEFAULT_MOVE_DECEL * delta)
		velocity.x = planar.x
		velocity.z = planar.z
		if planar.length() > 0.05:
			_face_towards(planar.normalized(), delta)
		return
	if skills.is_busy() and not is_dodging:
		_animate_walk(_walk_phase)
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var direction := _input_direction()
	var target := direction * _tier_target_speed() * statuses.move_speed_multiplier()
	var accel := float(class_data.get("move_accel", DEFAULT_MOVE_ACCEL))
	var decel := float(class_data.get("move_decel", DEFAULT_MOVE_DECEL))
	var rate := decel if target.length() < 0.05 else accel
	var planar := Vector3(velocity.x, 0, velocity.z).move_toward(target, rate * delta)
	velocity.x = planar.x
	velocity.z = planar.z
	var planar_speed := planar.length()
	if planar_speed > 0.05:
		_face_towards(planar.normalized(), delta)
		_walk_phase += delta * planar_speed * (2.4 + _run_blend * 0.8)
		_animate_walk(_walk_phase)
	else:
		_animate_idle(delta)
	if _vigor_regen > 0.0 and vigor < max_vigor:
		vigor = minf(vigor + _vigor_regen * delta, max_vigor)
		stats_changed.emit()


func _face_motion(motion: Vector3, delta: float) -> void:
	var planar := Vector3(motion.x, 0, motion.z)
	if planar.length() > 0.05:
		_face_towards(planar.normalized(), delta)


func _special_motion() -> Vector3:
	## Movimiento de acciones especiales: esquiva (toda su duración), Carga del
	## Mambí y avance del Huracán (solo durante su ventana ACTIVA; el windup
	## frena el cuerpo). Vector3.INF = sin movimiento especial.
	if is_dodging:
		var duration := maxf(float(_action_params.get("duration", 0.3)), 0.05)
		var dodge_speed := float(_action_params.get("distance", 4.0)) / duration
		return _dodge_direction * dodge_speed
	var def := skills.current_def()
	if def.is_empty():
		return Vector3.INF
	var kind := String(def.get("kind", ""))
	if kind == "dash" or kind == "spin":
		if skills.phase_name() != "active":
			return Vector3.ZERO
		var motion_duration := maxf(float(def.get("dash_duration", def.get("spin_duration", 0.35))), 0.05)
		var motion_distance := float(def.get("dash_distance", def.get("spin_advance", 7.0)))
		return transform.basis.z * (motion_distance / motion_duration)
	return Vector3.INF


func _update_run_blend(delta: float) -> void:
	_run_blend = move_toward(_run_blend, 1.0 if move_tier == "run" else 0.0, delta * 4.0)


func _tier_target_speed() -> float:
	## Velocidad objetivo según el tier. Caminar: base; correr: base x mult.
	var raw_magnitude := _raw_input().length()
	var base_speed := stats.move_speed if stats != null else float(class_data.get("move_speed", 4.0))
	if raw_magnitude >= RUN_INPUT_THRESHOLD:
		move_tier = "run"
		return base_speed * float(class_data.get("run_multiplier", DEFAULT_RUN_MULTIPLIER))
	if raw_magnitude > 0.05:
		move_tier = "walk"
		return base_speed
	move_tier = "idle"
	return 0.0


func _face_towards(direction: Vector3, delta: float) -> void:
	if direction.length() < 0.05:
		return
	var target_yaw := atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(delta * 12.0, 1.0))


func revive(at_position: Vector3) -> void:
	## Respawn tras derrota en la rebanada: conservar progreso de misión y XP.
	if not is_dead():
		return
	revive_combatant()
	vigor = max_vigor
	kit.stop_on_death()
	global_position = at_position
	if _puppet != null:
		_puppet.reset_pose()
	stats_changed.emit()


# ---------------------------------------------------------------------------
# Persistencia (códec versionado en PlayerSaveCodec)
# ---------------------------------------------------------------------------


func serialize() -> Dictionary:
	return PlayerSaveCodec.serialize(self)


func restore(data: Dictionary) -> void:
	PlayerSaveCodec.restore(self, data)


# ---------------------------------------------------------------------------
# Puentes públicos para los componentes extraídos (equipo y guardado usan
# solo esta superficie; la lógica vive en sus archivos).
# ---------------------------------------------------------------------------


func recalculate_stats() -> void:
	_recalculate_from_level()


func notify_equipment_changed() -> void:
	_update_weapon_visual()
	stats_changed.emit()


func load_class_data() -> void:
	class_data = RpgDB.get_class_data(class_id)


func reset_for_restore() -> void:
	_reset_stats()


func restore_spent_attributes(spent: Dictionary) -> void:
	for attribute: String in _attributes.keys():
		_attributes[attribute] = float(_attributes[attribute]) + float(spent.get(attribute, 0.0))


func spent_attributes() -> Dictionary:
	var spent := {}
	for attribute: String in _attributes.keys():
		var base := float(class_data.get("base_stats", {}).get(attribute, 10))
		spent[attribute] = float(_attributes[attribute]) - base
	return spent


func set_ultimate_charge(value: float) -> void:
	kit.set_charge(value)


# ---------------------------------------------------------------------------
# Presentación: la marioneta visual (montaje y poses) está desacoplada en
# MacheteroPuppet. Aquí solo la delegación por estado REAL del combate.
# ---------------------------------------------------------------------------


func _build_visual() -> void:
	_puppet = MacheteroPuppet.new()
	add_child(_puppet)


func _animate_walk(phase: float) -> void:
	if _puppet != null:
		_puppet.animate_walk(phase, _run_blend)


func _animate_idle(delta: float) -> void:
	if _puppet != null:
		_puppet.animate_idle(delta)


func _animate_action(delta: float) -> void:
	## El jugador SOLO describe su estado real; la marioneta decide la pose
	## (sistema de estados y sistema visual desacoplados; mismo mapa servirá
	## para un AnimationPlayer futuro sin tocar la lógica).
	if _puppet == null:
		return
	var def := skills.current_def()
	(
		_puppet
		. animate_combat_state(
			delta,
			{
				"blocking": kit.is_blocking(),
				"action_kind": String(def.get("kind", "")),
				"phase": skills.phase_name(),
				"progress": clampf(skills.elapsed() / maxf(float(def.get("total_time", 0.55)), 0.05), 0.0, 1.0),
				"dodging": is_dodging,
				"busy": skills.is_busy(),
			}
		)
	)


func _update_weapon_visual() -> void:
	if _puppet != null:
		_puppet.set_blade_glow(equipment.potency_bonus() > 0.0)

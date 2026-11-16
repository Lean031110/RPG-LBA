# gdlint: ignore=max-public-methods
class_name ArpgEnemy
extends ArpgCombatant
## Enemigo ARPG reutilizable (Fase 5): FSM completa dirigida por datos
## (game/data/enemies.json) que usa EL MISMO motor de combate que el jugador
## (heredado de ArpgCombatant): mismas ventanas, mismas hitboxes con línea de
## visión, mismo procesamiento de daño y mismos estados alterados.
##
## Estados: IDLE → PATROL → CHASE → WINDUP → STRIKE → RECOVER → HURT → STUNNED
## → DEAD, con transiciones por datos (radios, tiempos) y ganchos virtuales
## para el comportamiento específico de cada especie (_process_behavior_*).
##
## El telegráfico (windup legible) es obligatorio: ningún daño sin ventana.

signal enemy_died(enemy_id: String, death_position: Vector3)
signal telegraph_changed(active: bool, progress: float)

enum InternalState { IDLE, PATROL, CHASE, WINDUP, STRIKE, RECOVER, HURT, STUNNED, DEAD }

const STATE_NAMES := {
	InternalState.IDLE: "idle",
	InternalState.PATROL: "patrol",
	InternalState.CHASE: "chase",
	InternalState.WINDUP: "windup",
	InternalState.STRIKE: "strike",
	InternalState.RECOVER: "recover",
	InternalState.HURT: "hurt",
	InternalState.STUNNED: "stunned",
	InternalState.DEAD: "dead",
}

const GRAVITY := 18.0
const HURT_STATE_TIME := 0.22
const DEFAULT_BODY_RADIUS := 0.45
const DEFAULT_BODY_HEIGHT := 2.2
const DETECTION_LOSS_GRACE := 0.6

var enemy_data: Dictionary = {}
var enemy_id := ""
var state: InternalState = InternalState.IDLE
var state_time := 0.0

var _target: Node3D = null
var _spawn_position := Vector3.ZERO
var _detection_raycast: RayCast3D = null
var _strike_done := false
var _target_lost_timer := 0.0
var _patrol_direction := Vector3.ZERO
var _patrol_timer := 0.0
var _home_target: Node3D = null
var _summon_check_left := 0.0


func setup(new_enemy_id: String) -> void:
	enemy_id = new_enemy_id
	enemy_data = RpgDB.get_enemy(enemy_id)
	if enemy_data.is_empty():
		push_error("ArpgEnemy: enemigo desconocido %s" % enemy_id)
		return
	collision_layer = ArpgLayers.ENEMY
	collision_mask = ArpgLayers.WORLD
	add_to_group("arpg_enemies")
	_build_body_shape()
	stats = CombatStats.from_enemy_data(enemy_data)
	max_hp = float(enemy_data.get("hp", 45))
	hp = max_hp
	_spawn_position = global_position
	mount_combat(ArpgLayers.HITBOX_ENEMY, ArpgLayers.PLAYER)
	_setup_detection()
	skills.window_opened.connect(_on_strike_window_opened)
	skills.window_tick.connect(_on_strike_window_tick)
	skills.action_finished.connect(_on_strike_finished)
	_build_visual()


func _build_body_shape() -> void:
	## Cápsula de colisión: sin ella no hay física (suelo, hitbox del jugador).
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = float(enemy_data.get("body_radius", DEFAULT_BODY_RADIUS))
	capsule.height = float(enemy_data.get("body_height", DEFAULT_BODY_HEIGHT))
	shape.shape = capsule
	shape.position = Vector3(0, capsule.height * 0.5, 0)
	add_child(shape)


func _setup_detection() -> void:
	## Raycast de línea de visión para detectar/persiguir: un enemigo no ve al
	## jugador a través de muros (corrección Fase 5 del sistema de colisiones).
	_detection_raycast = RayCast3D.new()
	_detection_raycast.name = "DetectionLosRay"
	_detection_raycast.collision_mask = ArpgLayers.WORLD | ArpgLayers.PLAYER
	_detection_raycast.enabled = false
	_detection_raycast.hit_from_inside = false
	add_child(_detection_raycast)


func set_target(target: Node3D) -> void:
	## Objetivo de la FSM. El PRIMER objetivo registrado es el "hogar" (el
	## jugador de la escena): si la bandera engage_summons le roba la atencion
	## a un eco, al perderlo el enemigo vuelve al hogar (nunca queda sin meta).
	if _home_target == null:
		_home_target = target
	_target = target


func get_display_name() -> String:
	## Nombre legible para el marco de objetivo del HUD.
	return RpgDB.get_text(String(enemy_data.get("name_key", "")), "es")


func get_level() -> int:
	return int(enemy_data.get("level", 1))


func get_hp_fraction() -> float:
	return clampf(hp / max_hp, 0.0, 1.0) if max_hp > 0.0 else 0.0


func get_state_name() -> String:
	## Nombre del estado para HUD, pruebas y depuración.
	return String(STATE_NAMES.get(state, "idle"))


func distance_to_player() -> float:
	if _target == null:
		return INF
	return global_position.distance_to(_target.global_position)


# ---------------------------------------------------------------------------
# FSM
# ---------------------------------------------------------------------------


func _physics_process(delta: float) -> void:
	if enemy_data.is_empty():
		return

		# El aturdimiento interrumpe cualquier acción y bloquea la FSM.

		# El aturdimiento interrumpe cualquier acción y bloquea la FSM.

		# El aturdimiento interrumpe cualquier acción y bloquea la FSM.
	if state == InternalState.DEAD:
		return

		# El aturdimiento interrumpe cualquier acción y bloquea la FSM.

		# El aturdimiento interrumpe cualquier acción y bloquea la FSM.
	# Contencion de amenazas (Fase 2, Sepulturero): con la bandera de datos
	# engage_summons, el enemigo reparte su atencion entre el jugador y los ecos
	# invocados (grupo arpg_summons). Sin ecos en escena — o sin bandera — la
	# FSM se comporta EXACTAMENTE como antes (regla del motor comun: ningun
	# cambio de comportamiento para las clases y escenas ya existentes).
	var engage_summons := bool(enemy_data.get("engage_summons", false))
	if _summon_check_left > 0.0:
		_summon_check_left -= delta
	elif engage_summons and state in [InternalState.IDLE, InternalState.PATROL, InternalState.CHASE]:
		_summon_check_left = 0.4
		_consider_summon_threats()
	tick_combat(delta)
	skills.advance(delta)
	state_time += delta
	_animate(delta)
	# El aturdimiento interrumpe cualquier acción y bloquea la FSM.
	if statuses.has("stun") and state != InternalState.STUNNED:
		skills.interrupt("stunned")
		_enter(InternalState.STUNNED)
	match state:
		InternalState.IDLE:
			_process_idle(delta)
		InternalState.PATROL:
			_process_patrol(delta)
		InternalState.CHASE:
			_process_chase(delta)
		InternalState.WINDUP:
			_process_windup(delta)
		InternalState.STRIKE:
			_process_strike(delta)
		InternalState.RECOVER:
			_process_recover(delta)
		InternalState.HURT:
			_process_hurt(delta)
		InternalState.STUNNED:
			_process_stunned(delta)
		InternalState.DEAD:
			return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()


func _process_idle(delta: float) -> void:
	## En reposo: espera a que el jugador entre en el radio de detección CON
	## línea de visión. Especies con patrulla lo sobreescriben.
	velocity.x = move_toward(velocity.x, 0.0, 24.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 24.0 * delta)
	if _player_detected():
		_enter(InternalState.CHASE)


func _delta_safe() -> float:
	return maxf(get_physics_process_delta_time(), 0.016)


func _process_patrol(delta: float) -> void:
	## Patrulla por defecto: rondas lentas alrededor del punto de aparición.
	## Las especies sin patrulla (datos) usan IDLE en su lugar.
	var patrol_radius := float(enemy_data.get("patrol_radius", 3.0))
	_patrol_timer -= delta
	if _patrol_timer <= 0.0:
		_patrol_timer = randf_range(1.5, 3.5)
		var angle := randf() * TAU
		_patrol_direction = Vector3(cos(angle), 0, sin(angle))
	var to_spawn := _spawn_position - global_position
	to_spawn.y = 0.0
	if to_spawn.length() > patrol_radius:
		_patrol_direction = to_spawn.normalized()
	var speed := float(enemy_data.get("patrol_speed", 1.2))
	velocity.x = _patrol_direction.x * speed
	velocity.z = _patrol_direction.z * speed
	_face_towards(_patrol_direction, delta)
	if _player_detected():
		_enter(InternalState.CHASE)


func _process_chase(delta: float) -> void:
	## Persecución: persigue mientras esté en el radio de pérdida (con gracia
	## breve si pierde la línea de visión); ataca al entrar en rango de golpe.
	if _target == null or not is_instance_valid(_target):
		_enter(InternalState.IDLE)
		return
	var dist := distance_to_player()
	var lose := float(enemy_data.get("lose_radius", 16.0))
	var attack_range := float(enemy_data.get("attack_range", 2.2))
	if dist > lose:
		_enter(InternalState.IDLE)
		return
	if dist <= attack_range:
		if _has_line_of_sight_to_player():
			_begin_strike()
		return
	if not _has_line_of_sight_to_player():
		_target_lost_timer += delta
		if _target_lost_timer > DETECTION_LOSS_GRACE:
			_enter(InternalState.IDLE)
			return
	else:
		_target_lost_timer = 0.0
	var direction := _target.global_position - global_position
	direction.y = 0.0
	if direction.length() < 0.05:
		return
	direction = direction.normalized()
	var speed := _chase_speed()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	_face_towards(direction, delta)
	_process_chase_behavior(delta, direction)


func _chase_speed() -> float:
	## Velocidad de persecución (gancho: los perros rodean, el guarapo es lento).
	return float(enemy_data.get("move_speed", 3.6)) * statuses.move_speed_multiplier()


func _process_chase_behavior(_delta: float, _direction: Vector3) -> void:
	## Gancho virtual: comportamiento extra durante la persecución (rodear,
	## mantener distancia...). Por defecto nada.
	pass


func _process_windup(delta: float) -> void:
	## Telegraph: se frena, gira hacia el objetivo y hace legible el golpe.
	velocity.x = move_toward(velocity.x, 0.0, 24.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 24.0 * delta)
	if _target == null or not is_instance_valid(_target):
		_enter(InternalState.IDLE)
		return
	if distance_to_player() > float(enemy_data.get("lose_radius", 16.0)):
		_enter(InternalState.IDLE)
		return
	var windup_time := maxf(float(enemy_data.get("windup_time", 0.75)), 0.05)
	var progress := clampf(state_time / windup_time, 0.0, 1.0)
	_visual_telegraph(progress)
	telegraph_changed.emit(true, progress)
	var direction := _target.global_position - global_position
	direction.y = 0.0
	if direction.length() > 0.05:
		_face_towards(direction.normalized(), delta)


func _process_strike(_delta: float) -> void:
	## Golpe: embestida corta hacia delante; el daño sale de la hitbox con las
	## MISMAS reglas que el jugador (ventana + LOS + golpe único).
	velocity.x = 0.0
	velocity.z = 0.0
	_visual_telegraph(1.0)
	telegraph_changed.emit(true, 1.0)


func _process_recover(_delta: float) -> void:
	## Recuperación tras el golpe: ventana de castigo del jugador.
	velocity.x = 0.0
	velocity.z = 0.0
	_visual_telegraph(0.0)
	telegraph_changed.emit(false, 0.0)
	if state_time >= float(enemy_data.get("recover_time", 1.1)):
		_enter(InternalState.CHASE)


func _process_hurt(delta: float) -> void:
	## Reacción al daño: breve pausa (retroceso lo aplica el empuje heredado).
	velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 30.0 * delta)
	if state_time >= HURT_STATE_TIME and statuses.can_act():
		_enter(InternalState.CHASE)


func _process_stunned(delta: float) -> void:
	## Aturdido: nada de acciones hasta que expire (mismo control que el jugador).
	velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 30.0 * delta)
	if not statuses.has("stun"):
		_enter(InternalState.CHASE)


func _enter(new_state: InternalState) -> void:
	state = new_state
	state_time = 0.0
	if new_state != InternalState.WINDUP and new_state != InternalState.STRIKE:
		velocity.x = 0.0
		velocity.z = 0.0
		_visual_telegraph(0.0)
		telegraph_changed.emit(false, 0.0)


func _face_towards(direction: Vector3, delta: float) -> void:
	if direction.length() < 0.05:
		return
	var target_yaw := atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(delta * 10.0, 1.0))


# ---------------------------------------------------------------------------
# Detección con línea de visión
# ---------------------------------------------------------------------------


func _player_detected() -> bool:
	if _target == null or not is_instance_valid(_target):
		return false
	if distance_to_player() > float(enemy_data.get("detect_radius", 9.0)):
		return false
	return _has_line_of_sight_to_player()


func _has_line_of_sight_to_player() -> bool:
	if _target == null:
		return false
	var from := global_position + Vector3(0, 1.4, 0)
	var to := _target.global_position + Vector3(0, 1.0, 0)
	_detection_raycast.global_position = from
	_detection_raycast.target_position = _detection_raycast.to_local(to)
	_detection_raycast.enabled = true
	_detection_raycast.force_raycast_update()
	var collider := _detection_raycast.get_collider()
	_detection_raycast.enabled = false
	if collider == null:
		return true
	return collider == _target or collider.is_ancestor_of(_target)


# ---------------------------------------------------------------------------
# Contencion de amenazas (Fase 2, Sepulturero)
# ---------------------------------------------------------------------------


func _consider_summon_threats() -> void:
	## Con engage_summons, el enemigo reparte su atencion entre el hogar (el
	## jugador) y los ecos vivos del grupo arpg_summons: persigue al VALIDO
	## mas cercano con linea de vision. Sin ecos, la lista de candidatos es solo
	## el hogar y el comportamiento es el de siempre.
	var candidates: Array[Node3D] = []
	if _home_target != null and is_instance_valid(_home_target):
		candidates.append(_home_target)
	for body: Node in get_tree().get_nodes_in_group("arpg_summons"):
		var node := body as Node3D
		if node == null or not is_instance_valid(node):
			continue
		if not node.has_method("take_damage"):
			continue
		if node.has_method("is_dead") and bool(node.call("is_dead")):
			continue
		candidates.append(node)
	var best: Node3D = null
	var best_dist := INF
	for node: Node3D in candidates:
		var dist := global_position.distance_to(node.global_position)
		if dist > float(enemy_data.get("detect_radius", 9.0)) * 1.2:
			continue
		if not _has_line_of_sight_to_node(node):
			continue
		if dist < best_dist:
			best_dist = dist
			best = node
	if best != null and best != _target:
		_target = best


func _has_line_of_sight_to_node(node: Node3D) -> bool:
	## Linea de vision generica (el _detection_raycast es de escena/muros).
	if node == null or _detection_raycast == null:
		return false
	var from := global_position + Vector3(0, 1.4, 0)
	var to := node.global_position + Vector3(0, 1.0, 0)
	_detection_raycast.global_position = from
	_detection_raycast.target_position = _detection_raycast.to_local(to)
	_detection_raycast.enabled = true
	_detection_raycast.force_raycast_update()
	var collider := _detection_raycast.get_collider()
	_detection_raycast.enabled = false
	if collider == null:
		return true
	return collider == node or collider.is_ancestor_of(node)


# ---------------------------------------------------------------------------
# Golpes del enemigo: mismas reglas que el jugador
# ---------------------------------------------------------------------------


func _begin_strike() -> void:
	## Arranca el ciclo windup→strike→recover por el SkillController con los
	## datos del enemigo (ventanas reales, no daño instantáneo).
	_strike_done = false
	var windup := maxf(float(enemy_data.get("windup_time", 0.75)), 0.05)
	var window := maxf(float(enemy_data.get("attack_window", 0.25)), 0.05)
	var strike_def := {
		"id": "enemy_strike",
		"kind": "enemy_strike",
		"damage_coeff": float(enemy_data.get("damage_coeff", 1.0)),
		"potency": float(enemy_data.get("potency", 9.0)),
		"damage_type": String(enemy_data.get("damage_type", "physical")),
		# La acción cubre windup + ventana; la RECUPERACIÓN la gobierna la FSM
		# (con su propio reloj), sin doblarla dentro de la acción.
		"windup": windup,
		"active_until": windup + window,
		"total_time": windup + window,
		"range": float(enemy_data.get("strike_range", enemy_data.get("attack_range", 2.2))),
		"arc_deg": float(enemy_data.get("strike_arc_deg", 80.0)),
		"knockback": float(enemy_data.get("knockback", 0.0)),
	}
	if enemy_data.has("on_hit_status"):
		strike_def["on_hit_status"] = enemy_data.get("on_hit_status")
	_enter(InternalState.WINDUP)
	skills.begin(strike_def)


func _on_strike_window_opened(def: Dictionary) -> void:
	## La ventana de golpe del enemigo abre su hitbox con la geometría de sus
	## datos (mismas reglas que el jugador: geometría real, no distancia suelta).
	_enter(InternalState.STRIKE)
	var reach := float(def.get("range", 2.2))
	var arc := float(def.get("arc_deg", 80.0))
	if reach > 0.0 and arc > 0.0:
		hitbox.open(reach, arc)
	_strike_visual_start()


func _on_strike_window_tick(_delta: float) -> void:
	## Ventana activa: golpear a los objetivos nuevos con línea de visión.
	for body: Node in hitbox.collect_new_hits():
		resolve_strike(body, skills.current_def())


func _on_strike_finished(_def: Dictionary) -> void:
	if state != InternalState.DEAD:
		_enter(InternalState.RECOVER)


func _strike_visual_start() -> void:
	## Gancho visual del inicio del golpe (embestida, zarpazo...).
	pass


# ---------------------------------------------------------------------------
# Reacciones al daño y muerte
# ---------------------------------------------------------------------------


func take_damage(amount: float, context: Dictionary = {}) -> bool:
	## El daño recibido interrumpe la preparación (los enemigos no son de goma):
	## pasa a HURT salvo que ya esté muerto. El cálculo lo hace la base.
	var was_alive := not is_dead()
	var applied := super(amount, context)
	if applied and was_alive and not is_dead() and state != InternalState.STUNNED:
		if statuses.has("stun"):
			_enter(InternalState.STUNNED)
		else:
			_enter(InternalState.HURT)
	return applied


func _on_combatant_died() -> void:
	## Muerte: cuerpo detenido del todo (también la caída), colisiones fuera,
	## recompensas por señal y disolución visual.
	velocity = Vector3.ZERO
	_enter(InternalState.DEAD)
	collision_layer = 0
	collision_mask = 0
	enemy_died.emit(enemy_id, global_position)
	CombatEvents.enemy_killed.emit(self)
	_visual_dissolve()


func get_xp_reward(is_first_kill: bool) -> int:
	## XP según datos (primera victoria vs repetible); la otorga la escena.
	return int(enemy_data.get("xp_first_kill" if is_first_kill else "xp_repeat", 0))


func get_drops() -> Array:
	return enemy_data.get("drops", [])


# ---------------------------------------------------------------------------
# Ganchos visuales (las especies los implementan)
# ---------------------------------------------------------------------------


func _build_visual() -> void:
	pass


func _animate(_delta: float) -> void:
	pass


func _visual_telegraph(_progress: float) -> void:
	pass


func _visual_dissolve() -> void:
	## Disolución por defecto: encoger y liberar.
	var puppet := _visual_root()
	if puppet == null:
		queue_free()
		return
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(puppet, "scale", Vector3(0.05, 0.02, 0.05), 0.55)
	tween.parallel().tween_property(puppet, "position:y", 0.05, 0.55)
	tween.chain().tween_callback(queue_free)


func _visual_root() -> Node3D:
	return null

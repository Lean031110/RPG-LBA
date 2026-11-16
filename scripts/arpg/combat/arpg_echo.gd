# gdlint: ignore=max-public-methods
class_name ArpgEcho
extends ArpgCombatant
## Eco invocado del Sepulturero de Guanabacoa (Fase 2, tercera clase): un
## combatiente aliado REAL del motor de combate, no un adorno visual. Hereda
## de ArpgCombatant para que los enemigos puedan golpearlo (mismo pipeline de
## take_damage/estados) y su propio ataque se resuelve SIEMPRE a traves del
## dueno (resolve_strike del Sepulturero: el dano escala con el intelecto del
## jugador, nunca con atributos propios del eco).
##
## Ciclo de vida (regla canon: presupuesto compartido de entidades activas):
##   invocacion (cap limitado por el kit) → seguimiento/combate → fin por
##   duracion agotada (señal echo_expired: onda de la pasiva Último encargo,
##   decidida por el kit, no por el eco) o por muerte en combate (sin onda).
##
## Seguridad estructural:
## - Nunca dania al dueno ni a otros ecos: su adquisicion de objetivos solo
##   consulta la capa ENEMY y sus golpes van a un unico objetivo validado.
## - Capa PLAYER para el cuerpo: los golpes enemigos (mascara PLAYER) lo
##   alcanzan; los golpes del propio jugador (mascara ENEMY) jamas lo tocan;
##   los recogibles lo ignoran (exigen add_potion, API exclusiva del jugador).
## - Limpieza sin fugas: al morir/expirar se desregistra del grupo, corta las
##   senales y se disuelve; los restos nunca atacan (FSM con estado DEAD).

signal echo_expired(world_position: Vector3)
signal echo_died

enum State { FOLLOW, ENGAGE, WINDUP, STRIKE, RECOVER, CHARGE }

const BODY_RADIUS := 0.38
const BODY_HEIGHT := 1.7
const GRAVITY := 18.0
const FACE_TURN_SPEED := 10.0
const STRIKE_ID := "echo_strike"
const GROUP_SUMMONS := "arpg_summons"

var owner_player: ArpgPlayer = null
var echo_kind := "guardian"
var echo_data: Dictionary = {}

var _state: State = State.FOLLOW
var _state_time := 0.0
var _target: Node3D = null
var _time_left := 10.0
var _retarget_left := 0.0
var _charge_dir := Vector3.ZERO
var _charge_hits: Array[Node] = []
var _charge_data: Dictionary = {}
var _visual_root: Node3D = null
var _lantern_material: StandardMaterial3D = null
var _sense_area: Area3D = null
var _los_ray: RayCast3D = null


static func make(owner: ArpgPlayer, kind: String, data: Dictionary, spawn_position: Vector3) -> ArpgEcho:
	## Fabrica del eco: data es la seccion "summons" de la clase (guardian/patio)
	## junto a los parametros compartidos del kit (sight_radius, retarget).
	var echo := ArpgEcho.new()
	echo.name = "Eco_" + kind
	echo.owner_player = owner
	echo.echo_kind = kind
	echo.echo_data = data
	echo.position = spawn_position
	echo._configure_body()
	return echo


func _configure_body() -> void:
	collision_layer = ArpgLayers.PLAYER
	collision_mask = ArpgLayers.WORLD
	add_to_group(GROUP_SUMMONS)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = BODY_RADIUS
	capsule.height = BODY_HEIGHT
	shape.shape = capsule
	shape.position = Vector3(0, capsule.height * 0.5, 0)
	add_child(shape)
	stats = CombatStats.new()
	stats.armor = float(echo_data.get("armor", 2.0))
	stats.resistance = float(echo_data.get("resistance", 2.0))
	stats.move_speed = float(echo_data.get("move_speed", 3.4))
	max_hp = maxf(float(echo_data.get("hp", 50.0)), 1.0)
	hp = max_hp
	_time_left = maxf(float(echo_data.get("duration", 12.0)), 0.5)
	# El eco ataca con las ventanas del SkillController (mismo motor que
	# jugador y enemigos) pero SIN hitbox propia: su golpe es un duelo directo
	# contra su objetivo, resuelto por el dueno con linea de vision.
	# La base ArpgCombatant instancia hitbox/cooldowns por defecto y su contrato
	# (take_damage al morir llama hitbox.close) exige una hitbox VALIDA. El eco
	# no golpea por hitbox: se monta INERTE (capa/mascara 0, nunca colisiona)
	# como hija del eco, cumpliendo el contrato sin geometria activa.
	add_child(skills)
	add_child(hitbox)
	hitbox.setup(self, 0, 0, ArpgLayers.WORLD)
	skills.window_opened.connect(_on_strike_window_opened)
	skills.action_finished.connect(_on_strike_finished)
	skills.action_interrupted.connect(func(_def: Dictionary, _reason: String) -> void: _enter(State.ENGAGE))
	statuses.periodic_tick.connect(_on_status_periodic_tick)
	_build_sense()
	_build_visual()


func _build_sense() -> void:
	## Percepcion del eco: un Area3D sobre la capa ENEMY (solo enemigos) y un
	## raycast de linea de vision contra el mundo (nada de atravesar muros).
	_sense_area = Area3D.new()
	_sense_area.name = "SentirEco"
	_sense_area.collision_layer = 0
	_sense_area.collision_mask = ArpgLayers.ENEMY
	_sense_area.monitoring = true
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = float(echo_data.get("sight_radius", 10.0))
	shape.shape = sphere
	_sense_area.add_child(shape)
	add_child(_sense_area)
	_los_ray = RayCast3D.new()
	_los_ray.name = "EcoLosRay"
	_los_ray.collision_mask = ArpgLayers.WORLD
	_los_ray.enabled = false
	_los_ray.hit_from_inside = false
	add_child(_los_ray)


func remaining_time() -> float:
	return maxf(_time_left, 0.0)


func consume_time(fraction: float) -> float:
	## Vela de los Ausentes: el dueno sacrifica parte de la duracion RESTANTE.
	## Devuelve el tiempo consumido; nunca llega a 0 (minimo 0.05s) para que el
	## eco no muera por la vela: la expiracion natural siempre es por su cuenta.
	if is_dead() or fraction <= 0.0:
		return 0.0
	var before := _time_left
	_time_left = maxf(_time_left * (1.0 - clampf(fraction, 0.0, 0.9)), 0.05)
	return before - _time_left


func get_echo_kind() -> String:
	return echo_kind


# ---------------------------------------------------------------------------
# FSM del eco
# ---------------------------------------------------------------------------


func _physics_process(delta: float) -> void:
	if owner_player == null or is_dead():
		return
	tick_combat(delta)
	_state_time += delta
	_time_left -= delta
	if _time_left <= 0.0:
		_expire_naturally()
		return
	_retarget_left -= delta
	if _target != null and (not is_instance_valid(_target) or _target is Node3D and _target_is_dead(_target)):
		_target = null
		if _state != State.CHARGE:
			_enter(State.FOLLOW)
	match _state:
		State.FOLLOW:
			_process_follow(delta)
		State.ENGAGE:
			_process_engage(delta)
		State.WINDUP:
			_process_windup(delta)
		State.STRIKE:
			velocity.x = 0.0
			velocity.z = 0.0
		State.RECOVER:
			velocity.x = 0.0
			velocity.z = 0.0
			if _state_time >= float(_attack().get("recover", 0.9)) and statuses.can_act():
				_enter(State.ENGAGE)
		State.CHARGE:
			_process_charge(delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	var knockback := consume_knockback()
	if knockback.length() > 0.001:
		velocity += knockback
	move_and_slide()
	_animate(delta)


func _process_follow(delta: float) -> void:
	## Sin objetivo: escolta al dueno a distancia de guardia (follow_distance).
	velocity.x = move_toward(velocity.x, 0.0, 24.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 24.0 * delta)
	if owner_player == null or not is_instance_valid(owner_player):
		return
	var to_owner := owner_player.global_position - global_position
	to_owner.y = 0.0
	var guard := float(echo_data.get("follow_distance", 2.2))
	if to_owner.length() > guard:
		var direction := to_owner.normalized()
		velocity.x = direction.x * _move_speed()
		velocity.z = direction.z * _move_speed()
		_face(direction, delta)
	if _retarget_left <= 0.0:
		_try_acquire_target()


func _process_engage(delta: float) -> void:
	## Con objetivo: acorralar hasta el rango de golpe y descargar el eco.
	if _target == null:
		_enter(State.FOLLOW)
		return

		## Correa: el eco nunca abandona a su dueno por perseguir lejanos.
	var to_target := _target.global_position - global_position
	to_target.y = 0.0
	var dist := to_target.length()
	var attack_range := float(_attack().get("range", 1.7))
	var leash := float(echo_data.get("leash_radius", 18.0))
	if owner_player != null:
		var to_owner := owner_player.global_position - global_position
		to_owner.y = 0.0
		if to_owner.length() > leash:
			## Correa: el eco nunca abandona a su dueno por perseguir lejanos.
			_target = null
			_enter(State.FOLLOW)
			return
	if dist > float(echo_data.get("sight_radius", 10.0)) * 1.6:
		_target = null
		_enter(State.FOLLOW)
		return
	if dist <= attack_range:
		if _has_los_to(_target):
			_begin_echo_strike()
		return
	if not statuses.can_act():
		return
	var direction := to_target.normalized()
	velocity.x = direction.x * _move_speed()
	velocity.z = direction.z * _move_speed()
	_face(direction, delta)
	if _retarget_left <= 0.0:
		_try_acquire_target()


func _process_windup(delta: float) -> void:
	## Telegraph del eco: frena y gira hacia su objetivo (golpe legible).
	velocity.x = move_toward(velocity.x, 0.0, 24.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 24.0 * delta)
	if _target == null or not is_instance_valid(_target):
		skills.interrupt("target_lost")
		return
	var direction := _target.global_position - global_position
	direction.y = 0.0
	if direction.length() > 0.05:
		_face(direction.normalized(), delta)


func _begin_echo_strike() -> void:
	## Arranca el ciclo windup→strike→recover con las ventanas del SkillController
	## (mismo motor que el resto de combatientes; nada de dano instantaneo).
	var atk := _attack()
	var strike_def := {
		"id": STRIKE_ID,
		"kind": "echo_strike",
		"damage_coeff": float(atk.get("damage_coeff", 0.6)),
		"potency": float(atk.get("potency", 6.0)),
		"damage_type": String(atk.get("damage_type", "arcane")),
		"attribute": String(atk.get("attribute", "intelecto")),
		"windup": maxf(float(atk.get("windup", 0.5)), 0.05),
		"active_until": maxf(float(atk.get("windup", 0.5)), 0.05) + maxf(float(atk.get("window", 0.22)), 0.05),
		"total_time":
		(
			maxf(float(atk.get("windup", 0.5)), 0.05)
			+ maxf(float(atk.get("window", 0.22)), 0.05)
			+ float(atk.get("recover", 0.9))
		),
		"knockback": 1.2,
	}
	_enter(State.WINDUP)
	skills.begin(strike_def)


func _on_strike_window_opened(_def: Dictionary) -> void:
	## Ventana activa: resolver el golpe REAL contra el objetivo por conducto
	## del dueno (el eco no golpea con sus propias estadisticas).
	_enter(State.STRIKE)
	if _target == null or not is_instance_valid(_target) or owner_player == null:
		return
	if not _has_los_to(_target):
		return
	owner_player.resolve_strike(_target, skills.current_def())


func _on_strike_finished(_def: Dictionary) -> void:
	if not is_dead():
		_enter(State.RECOVER)


func _try_acquire_target() -> void:
	## Adquisicion (con acelerador de retarget_interval): el enemigo VALIDO mas
	## cercano a la vista. Solo capa ENEMY: el dueno y otros ecos no entran.
	_retarget_left = maxf(float(echo_data.get("retarget_interval", 0.35)), 0.1)
	var best: Node3D = null
	var best_dist := INF
	for body: Node in _sense_area.get_overlapping_bodies():
		if body == null or not body.has_method("take_damage"):
			continue
		var node := body as Node3D
		if node == null or _target_is_dead(node):
			continue
		if not _has_los_to(node):
			continue
		var dist := global_position.distance_to(node.global_position)
		if dist < best_dist:
			best_dist = dist
			best = node
	if best != null and best != _target:
		_target = best
		if _state == State.FOLLOW:
			_enter(State.ENGAGE)


func _has_los_to(node: Node3D) -> bool:
	if node == null:
		return false
	var from := global_position + Vector3(0, 1.2, 0)
	var to := node.global_position + Vector3(0, 1.0, 0)
	_los_ray.global_position = from
	_los_ray.target_position = _los_ray.to_local(to)
	_los_ray.enabled = true
	_los_ray.force_raycast_update()
	var collider := _los_ray.get_collider()
	_los_ray.enabled = false
	if collider == null:
		return true
	return collider == node or collider.is_ancestor_of(node) or node.is_ancestor_of(collider)


func _target_is_dead(node: Node3D) -> bool:
	if node.has_method("is_dead"):
		return bool(node.call("is_dead"))
	return false


# ---------------------------------------------------------------------------
# Orden de carga (Procesion de Hueso y Bronce): el kit la dicta, el eco la ejecuta
# ---------------------------------------------------------------------------


func begin_charge(direction: Vector3, charge_data: Dictionary) -> void:
	## El eco embiste en linea: dano y empuje contra lo que encuentre (una vez
	## por enemigo por carga), resuelto por el dueno. La carga NO consume el eco.
	if is_dead() or direction.length() < 0.05:
		return
	skills.interrupt("charge_ordered")
	_charge_dir = direction.normalized()
	_charge_data = charge_data
	_charge_hits = []
	_enter(State.CHARGE)
	_face(_charge_dir, 1.0)


func _process_charge(_delta: float) -> void:
	var speed := float(_charge_data.get("speed", 9.0))
	velocity.x = _charge_dir.x * speed
	velocity.z = _charge_dir.z * speed
	var width := float(_charge_data.get("hit_width", 2.4))
	var charge_def: Dictionary = _charge_data.get("strike_def", {})
	for body: Node in _sense_area.get_overlapping_bodies():
		if body == null or body in _charge_hits:
			continue
		if not body.has_method("take_damage"):
			continue
		var node := body as Node3D
		if node == null or _target_is_dead(node):
			continue
		var to_body := node.global_position - global_position
		to_body.y = 0.0
		if to_body.length() > width * 0.5 + 0.9:
			continue
		var forward_dot := to_body.normalized().dot(_charge_dir)
		if forward_dot < 0.35:
			continue
		if not _has_los_to(node):
			continue
		_charge_hits.append(body)
		if owner_player != null and not charge_def.is_empty():
			owner_player.resolve_strike(node, charge_def)
	if _state_time >= float(_charge_data.get("duration", 0.8)):
		_charge_data = {}
		_charge_hits = []
		_enter(State.FOLLOW)


func is_charging() -> bool:
	return _state == State.CHARGE


# ---------------------------------------------------------------------------
# Fin del eco: expiracion natural (onda) y muerte en combate (sin onda)
# ---------------------------------------------------------------------------


func _expire_naturally() -> void:
	## La duracion se agoto: el eco se disuelve y AVISA (la onda de Último
	## encargo la materializa el kit como zona del dueno). Sin ataques posteriores.
	if is_dead():
		return
	_die_common(false)


func expire_silently() -> void:
	## Fin impuesto por el dueno (muerte del jugador o limpieza de escena):
	## se disuelve SIN onda y sin senales (no es un fin natural por duracion).
	if is_dead():
		return
	_dead = true
	remove_from_group(GROUP_SUMMONS)
	_target = null
	skills.interrupt("echo_gone")
	velocity = Vector3.ZERO
	_dissolve()


func _on_combatant_died() -> void:
	## Cae en combate: sin onda (el canon la reserva para el fin de duracion).
	echo_died.emit()
	_die_common(true)


func _die_common(from_combat: bool) -> void:
	## Ruta comun de fin: marcar muerto, avisar (solo expiracion), desregistrarse
	## y disolverse. Nunca queda un cuerpo activo atacando o colisionando.
	_dead = true
	if not from_combat:
		echo_expired.emit(global_position)
	remove_from_group(GROUP_SUMMONS)
	_target = null
	skills.interrupt("echo_gone")
	velocity = Vector3.ZERO
	_dissolve()


func _dissolve() -> void:
	## Disolucion espectral: encoger hacia el suelo y liberar. Sin cuerpos ni
	## colisiones fantasma tras la muerte.
	collision_layer = 0
	collision_mask = 0
	if _sense_area != null:
		_sense_area.set_deferred("monitoring", false)
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(_visual_root, "scale", Vector3(0.05, 0.02, 0.05), 0.5)
	tween.parallel().tween_property(_visual_root, "position:y", 0.04, 0.5)
	if _lantern_material != null:
		tween.parallel().tween_property(_lantern_material, "emission_energy_multiplier", 0.0, 0.4).from(0.9)
	tween.chain().tween_callback(queue_free)


# ---------------------------------------------------------------------------
# Reacciones y presentacion
# ---------------------------------------------------------------------------


func take_damage(amount: float, context: Dictionary = {}) -> bool:
	## El eco recibe golpes con el pipeline comun; ademas pierde el objetivo si
	## estaba en windup (el canon no quiere ecos de goma).
	var applied := super(amount, context)
	if applied and not is_dead() and _state == State.WINDUP:
		skills.interrupt("hurt")
	return applied


func _attack() -> Dictionary:
	return echo_data.get("attack", {})


func _move_speed() -> float:
	return float(echo_data.get("move_speed", 3.4)) * statuses.move_speed_multiplier()


func _face(direction: Vector3, delta: float) -> void:
	if direction.length() < 0.05:
		return
	var target_yaw := atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(delta * FACE_TURN_SPEED, 1.0))


func _enter(new_state: State) -> void:
	_state = new_state
	_state_time = 0.0
	if new_state != State.WINDUP and new_state != State.STRIKE and new_state != State.CHARGE:
		velocity.x = 0.0
		velocity.z = 0.0


func _animate(delta: float) -> void:
	## Flotacion espectral suave (los ecos no caminan: se deslizan).
	if _visual_root == null:
		return
	if _state == State.FOLLOW or _state == State.ENGAGE:
		if velocity.length() > 0.2:
			_visual_root.position.y = 0.08 + sin(_state_time * 7.0) * 0.045
		else:
			_visual_root.position.y = lerpf(_visual_root.position.y, 0.08, 8.0 * delta)


func _build_visual() -> void:
	## Silueta de eco: figura translucida gris-ceniza con farol ambar (ceniza
	## viva). Distinguible del jugador (sombrero) y de los enemigos (sombras).
	_visual_root = Node3D.new()
	_visual_root.name = "EcoVisual"
	add_child(_visual_root)
	var body_mat := VisualKit.flat_material(Color(0.42, 0.44, 0.50), Color(0.42, 0.50, 0.72), 0.95)
	body_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	body_mat.albedo_color = Color(0.52, 0.56, 0.68, 0.78)
	VisualKit.add_cylinder(_visual_root, 0.34, 1.05, Vector3(0, 0.62, 0), body_mat, 10)
	VisualKit.add_sphere(_visual_root, 0.17, Vector3(0, 1.28, 0.02), body_mat)
	# Banda de pecho de bronce (banda del gremio): fina y pegada al cuerpo; la
	# version anterior (placa ancha 0.5) leia como geometria residual flotante.
	var bronze := VisualKit.flat_material(VisualKit.MAT_BRONZE, VisualKit.MAT_BRONZE_GLOW, 0.4)
	VisualKit.add_box(_visual_root, Vector3(0.30, 0.06, 0.05), Vector3(0, 0.92, 0.20), bronze)
	# Farol de mano: llama de ceniza al costado (sin poste: la revision artistica
	# leia el poste como una viga incrustada). Cuelga del costado del eco.
	_lantern_material = VisualKit.flat_material(Color(0.95, 0.62, 0.25), Color(1.0, 0.62, 0.22), 1.1)
	VisualKit.add_sphere(_visual_root, 0.09, Vector3(0.34, 0.72, 0.10), _lantern_material)
	# Anillo de suelo ambar: marca de ALIADO invocado (legibilidad movil: separa
	# al eco del fondo y lo identifica como invocacion propia).
	var ring_mat := VisualKit.flat_material(Color(0.72, 0.55, 0.30), Color(1.0, 0.62, 0.22), 0.35)
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.albedo_color = Color(0.72, 0.55, 0.30, 0.45)
	var ring := VisualKit.add_cylinder(_visual_root, 0.55, 0.02, Vector3(0, 0.02, 0), ring_mat, 18)
	ring.set_meta("ring", true)
	_visual_root.position.y = 0.08

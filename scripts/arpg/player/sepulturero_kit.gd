# gdlint: ignore=max-public-methods
class_name SepultureroKit
extends ClassKit
## Kit del Sepulturero de Guanabacoa (Fase 2, tercera clase jugable): el Pastor
## de los Ecos. Identidad mecanica propia, NO una copia de la Bruja ni del
## Machetero:
## - Combate a CORTA distancia con el farol (basico melee arcano corto) y un
##   ejercito de ecos: el dano personal es bajo, el ritmo lo marcan las
##   invocaciones (presupuesto compartido, canon de la Fase 2).
## - Gestiona la vida de sus ecos: invoca (Llamada del Osario), los empuja a
##   cargar en linea (Procesion), los sacrifica para sostenerse (Vela) y los
##   hace caer en oleada con la definitiva (El Patio de los que Vuelven).
## - Marca a sus presas (Marca del Ultimo Nombre): debilitadas, entregan
##   fragmentos de ceniza al caer (pasiva Nombre prestado).
## - Cuando un eco termina su duracion deja una onda breve (pasiva Ultimo
##   encargo): ralentiza y dania alrededor; nunca encadena (una onda no es un
##   eco y no genera otra).
## - SIN bloqueo: su defensa es la planificacion (como la Bruja, armadura 6).

const MARK_STATUS_ID := "vulnerable"
const MARK_SOURCE := "marca_del_ultimo_nombre"

var _action := "none"
var _action_timer := 0.0
var _action_params: Dictionary = {}
var _echoes: Array[ArpgEcho] = []
var _marks: Array[Dictionary] = []
var _wave_left := 0.0

# ---------------------------------------------------------------------------
# Consultas del kit
# ---------------------------------------------------------------------------


func active_echo_count() -> int:
	_prune_invalid_echoes()
	return _echoes.size()


func active_echoes() -> Array[ArpgEcho]:
	_prune_invalid_echoes()
	return _echoes.duplicate()


func has_marked_targets() -> bool:
	return not _marks.is_empty()


# ---------------------------------------------------------------------------
# Acciones
# ---------------------------------------------------------------------------


func try_attack() -> bool:
	## Barrido de Farol: golpe melee arcano corto (ventana + hitbox real, como
	## el Machetero pero con la geometria propia del farol: menos alcance).
	if _player.is_dead() or not _player.statuses.can_act():
		return false
	var basic: Dictionary = _class_data.get("basic_attack", {})
	if basic.is_empty():
		return false
	if _player.cooldowns.left("attack") > 0.0:
		return false
	if _player.skills.is_busy():
		_player.skills.buffer_input("attack")
		return false
	return _begin_strike_action(basic, "attack")


func try_skill_index(index: int) -> bool:
	## Habilidad del hueco index (0..3). Validacion comun (desbloqueo, coste,
	## recarga) + regla propia de cada tecnica (cap de ecos, necesidad de ecos
	## activos). Sin cumplirse la propia, el lanzamiento falla aqui.
	if _player.is_dead() or not _player.statuses.can_act():
		return false
	var def := _player.get_skill_def(index)
	if _skill_blocked(def):
		return false
	if not _skill_requirements_met(def):
		return false
	if _player.skills.is_busy():
		_player.skills.buffer_input(String(def.get("id", "")))
		return false
	_player.vigor -= float(def.get("resource_cost", 0))
	_player.cooldowns.start(String(def.get("id", "")), float(def.get("cooldown", 5.0)))
	_player.stats_changed.emit()
	kit_skill_cast.emit(String(def.get("id", "")))
	return _begin_cast_action(def, "skill")


func try_ultimate() -> bool:
	## El Patio de los que Vuelven: llena el presupuesto de ecos con la procesion
	## de la definitiva. Requiere carga completa y un hueco libre en el tope.
	if _player.is_dead() or not _player.statuses.can_act() or _player.skills.is_busy():
		return false
	var def: Dictionary = _class_data.get("ultimate", {})
	if def.is_empty() or not _player.is_skill_def_unlocked(def) or _ultimate_charge < _ultimate_max:
		return false
	if active_echo_count() >= int(_summons().get("max_active", 3)):
		return false
	_ultimate_charge = 0.0
	kit_charge_changed.emit(_ultimate_charge, _ultimate_max)
	kit_ultimate_cast.emit()
	_player.cooldowns.start("ultimate", float(def.get("cooldown", 1.0)))
	return _begin_cast_action(def, "ultimate")


func tick(delta: float) -> void:
	## Relojes del kit: duracion de la esquiva, caducidad de las marcas y poda
	## de referencias muertas (ecos liberados por la escena o el diseno).
	if _player.is_dodging:
		_action_timer += delta
		var duration := maxf(float(_action_params.get("duration", 0.3)), 0.05)
		if _action_timer >= duration:
			end_action()
	if not _marks.is_empty():
		var live_marks: Array[Dictionary] = []
		for entry: Dictionary in _marks:
			entry["time_left"] = maxf(float(entry.get("time_left", 0.0)) - delta, 0.0)
			var node := entry.get("node", null) as Node3D
			if float(entry.get("time_left", 0.0)) > 0.0 and node != null and is_instance_valid(node):
				live_marks.append(entry)
		_marks = live_marks
	_prune_invalid_echoes()


func end_action() -> void:
	_action = "none"
	_action_params = {}
	_action_timer = 0.0
	_player.is_dodging = false
	_player.hitbox.close()


func stop_on_death() -> void:
	## Muerte del Sepulturero: los ecos se disuelven al romperse el vinculo.
	## Sin ondas (no es un fin natural por duracion) y sin restos activos.
	super.stop_on_death()
	_wave_left = 0.0
	dissolve_all_echoes()


# ---------------------------------------------------------------------------
# Internos: arranque de acciones (melee con hitbox y cast sin hitbox)
# ---------------------------------------------------------------------------


func _begin_strike_action(params: Dictionary, kind: String) -> bool:
	## Accion con ventana melee (Barrido de Farol): geometria real de hitbox.
	_action = kind
	_action_timer = 0.0
	_action_params = params
	_player.hitbox.reset_swing()
	if not _player.skills.begin(params):
		return false
	if kind == "attack":
		_player.cooldowns.start("attack", float(params.get("cooldown", 0.55)))
	kit_action_started.emit(kind)
	return true


func _begin_cast_action(params: Dictionary, kind: String) -> bool:
	## Accion de invocacion/orden (sin hitbox): el efecto se materializa en la
	## ventana activa del SkillController, como los casts de la Bruja.
	_action = kind
	_action_timer = 0.0
	_action_params = params
	if not _player.skills.begin(params):
		return false
	kit_action_started.emit(kind)
	return true


func _on_skill_action_started(_def: Dictionary) -> void:
	## Las tecnicas del Sepulturero avanzan mirando a donde mira el jugador:
	## la Procesion carga en esa direccion y las invocaciones nacen delante.
	_player.orient_to_input_or_forward()


func _skill_requirements_met(def: Dictionary) -> bool:
	## Reglas propias mas alla de la validacion comun (por habilidad):
	## - Llamada del Osario: un hueco en el tope de ecos.
	## - Procesion / Vela: al menos un eco activo (ordenan o sacrifican ecos).
	match String(def.get("kind", "")):
		"summon":
			return active_echo_count() < int(_summons().get("max_active", 3))
		"procession", "veil":
			return active_echo_count() > 0
		_:
			return true


# ---------------------------------------------------------------------------
# Materializacion de las tecnicas en la ventana activa
# ---------------------------------------------------------------------------


func _on_attack_window_opened(def: Dictionary) -> void:
	## Ventana activa: materializar la tecnica REAL segun su kind.
	var kind := String(def.get("kind", ""))
	match kind:
		"strike":
			var reach := float(def.get("range", 2.0))
			var arc := float(def.get("arc_deg", 72.0))
			if reach > 0.0 and arc > 0.0:
				_player.hitbox.open(reach, arc)
		"summon":
			_spawn_echo(String(def.get("summon_kind", "guardian")))
		"mark":
			_apply_mark(def.get("mark", {}))
		"procession":
			_order_procession(def.get("charge", {}))
		"veil":
			_apply_veil(def.get("veil", {}))
		"patio":
			_fill_patio()
		_:
			pass


func _on_attack_window_tick(_delta: float) -> void:
	## Tick de la ventana melee (Barrido de Farol): golpes nuevos por hitbox.
	var def := _player.skills.current_def()
	if def.is_empty() or not _player.hitbox.is_open():
		return
	if String(def.get("kind", "")) != "strike":
		return
	for body: Node in _player.hitbox.collect_new_hits():
		_player.resolve_strike(body, def)


# ---------------------------------------------------------------------------
# Ecos: invocacion, presupuesto compartido y ordenes
# ---------------------------------------------------------------------------


func _summons() -> Dictionary:
	return _class_data.get("summons", {})


func _spawn_echo(kind: String) -> void:
	## Invoca UN eco delante del Sepulturero (respeta el tope: quien invoca
	## valida antes de gastar; aqui ya hay hueco garantizado).
	if active_echo_count() >= int(_summons().get("max_active", 3)):
		return
	var data: Dictionary = (_summons().get(kind, {})).duplicate()
	data["sight_radius"] = float(_summons().get("sight_radius", 10.0))
	data["retarget_interval"] = float(_summons().get("retarget_interval", 0.35))
	var forward := _player.global_transform.basis.z
	var spawn := _player.global_position + forward * 1.6
	var echo := ArpgEcho.make(_player, kind, data, Vector3(spawn.x, _player.global_position.y, spawn.z))
	_player.get_parent().add_child(echo)
	echo.global_position = Vector3(spawn.x, maxf(_player.global_position.y, 0.5), spawn.z)
	echo.echo_expired.connect(_on_echo_expired)
	_echoes.append(echo)


func _fill_patio() -> void:
	## Definitiva: llena hasta el tope con ecos de procesion (vida corta y
	## paso rapido) en anillo alrededor del Sepulturero. Cada uno con su
	## salud, su objetivo y sus reglas (canon del Patio).
	var cap := int(_summons().get("max_active", 3))
	var missing := cap - active_echo_count()
	if missing <= 0:
		return
	for index: int in missing:
		var angle := TAU * float(index) / float(missing) + PI * 0.25
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * 2.0
		var data: Dictionary = (_summons().get("patio", {})).duplicate()
		data["sight_radius"] = float(_summons().get("sight_radius", 10.0))
		data["retarget_interval"] = float(_summons().get("retarget_interval", 0.35))
		var spawn := _player.global_position + offset
		var echo := ArpgEcho.make(_player, "patio", data, Vector3(spawn.x, _player.global_position.y, spawn.z))
		_player.get_parent().add_child(echo)
		echo.global_position = Vector3(spawn.x, maxf(_player.global_position.y, 0.5), spawn.z)
		echo.echo_expired.connect(_on_echo_expired)
		_echoes.append(echo)


func _order_procession(charge: Dictionary) -> void:
	## Procesion de Hueso y Bronce: TODOS los ecos activos embisten en linea en
	## la direccion mirada. El dano y el empuje salen del dueno (strike_def),
	## una vez por enemigo por carga; la carga no consume los ecos.
	if charge.is_empty():
		return
	var direction := _player.global_transform.basis.z
	if direction.length() < 0.05:
		return
	var strike_def := {
		"id": "procesion_hueso_bronce",
		"damage_coeff": float(charge.get("damage_coeff", 0.9)),
		"potency": float(charge.get("potency", 8.0)),
		"damage_type": "arcane",
		"attribute": "intelecto",
		"knockback": float(charge.get("knockback", 4.5)),
	}
	var charge_data := {
		"speed": float(charge.get("speed", 9.0)),
		"duration": float(charge.get("duration", 0.8)),
		"hit_width": float(charge.get("hit_width", 2.4)),
		"strike_def": strike_def,
	}
	for echo: ArpgEcho in active_echoes():
		echo.begin_charge(direction, charge_data)


func dissolve_all_echoes() -> void:
	## Fin controlado de todos los ecos (muerte del dueno o limpieza de escena):
	## disolucion silenciosa, sin ondas (nunca son fins naturales por duracion).
	for echo: ArpgEcho in active_echoes():
		if echo != null and is_instance_valid(echo):
			echo.expire_silently()
	_echoes.clear()


func _prune_invalid_echoes() -> void:
	## Poda de referencias muertas (evita conteos falsos y fugas de memoria).
	## Bucle manual tipado: Array.filter devuelve Array sin tipo y la lista es
	## Array[ArpgEcho] (asignar un filter provoca error de tipos en Godot 4).
	if _echoes.is_empty():
		return
	var kept: Array[ArpgEcho] = []
	for echo: ArpgEcho in _echoes:
		if echo != null and is_instance_valid(echo):
			kept.append(echo)
	_echoes = kept


func _on_echo_expired(world_position: Vector3) -> void:
	## Pasiva Ultimo encargo: al terminar su duracion, el eco deja una onda
	## breve (zona del dueno) que ralentiza y dania. Una onda no es un eco: no
	## puede engendrar mas ondas ni ecos (regla anti-cadena del canon).
	var passive: Dictionary = _class_data.get("passives", {}).get("ultimo_encargo", {})
	if passive.is_empty():
		return
	var wave_def := {
		"id": "ultimo_encargo",
		"zone":
		{
			"radius": float(passive.get("wave_radius", 2.5)),
			"duration": float(passive.get("wave_duration", 0.45)),
			"tick_interval": maxf(float(passive.get("wave_duration", 0.45)) * 0.9, 0.1),
			"color": [0.55, 0.58, 0.66],
			"alpha": 0.5,
		},
		"zone_tick":
		{
			"id": "ultimo_encargo_tick",
			"damage_coeff": float(passive.get("wave_damage_coeff", 0.4)),
			"potency": float(passive.get("wave_potency", 5.0)),
			"damage_type": "arcane",
			"attribute": "intelecto",
		},
		"zone_status":
		{
			"id": "slow",
			"duration": float(passive.get("wave_slow_duration", 1.2)),
			"params": {"slow_fraction": float(passive.get("wave_slow_fraction", 0.35))},
		},
	}
	var zone := ArpgAreaEffect.make(
		_player,
		wave_def,
		Vector3(world_position.x, 0.0, world_position.z),
		_player.HITBOX_LAYER,
		_player.HITBOX_MASK,
		ArpgLayers.WORLD,
		false
	)
	_player.get_parent().add_child(zone)


# ---------------------------------------------------------------------------
# Marca del Ultimo Nombre + pasiva Nombre prestado
# ---------------------------------------------------------------------------


func _apply_mark(mark: Dictionary) -> void:
	## Debilita (vulnerable +30%) y marca al objetivo actual (o al mas cercano
	## en cono frontal). La marca caduca sola; la pasiva consulta el registro.
	if mark.is_empty():
		return
	var target := _player.targeting.current() if _player.targeting.has_target() else null
	if target == null or not is_instance_valid(target):
		target = _nearest_in_cone(float(mark.get("range", 12.0)), float(mark.get("arc_deg", 55.0)))
	if target == null:
		return
	var duration := float(mark.get("duration", 6.0))
	if target.has_method("apply_status"):
		target.apply_status(MARK_STATUS_ID, duration, {"multiplier": float(mark.get("vulnerability_multiplier", 1.3))})
	for entry: Dictionary in _marks:
		if entry.get("node", null) == target:
			entry["time_left"] = duration
			return
	_marks.append({"node": target, "time_left": duration})


func _nearest_in_cone(range: float, arc_deg: float) -> Node3D:
	## Busqueda de respaldo cuando no hay objetivo del TargetingSystem: el
	## enemigo mas cercano dentro del cono frontal (grupo arpg_enemies).
	var best: Node3D = null
	var best_score := INF
	var forward := _player.global_transform.basis.z
	var half_arc := deg_to_rad(arc_deg) * 0.5
	for body: Node in _player.get_tree().get_nodes_in_group("arpg_enemies"):
		var node := body as Node3D
		if node == null or not is_instance_valid(node):
			continue
		if not node.has_method("take_damage"):
			continue
		var to_node := node.global_position - _player.global_position
		to_node.y = 0.0
		var dist := to_node.length()
		if dist > range or dist < 0.05:
			continue
		if to_node.normalized().dot(forward) < cos(half_arc):
			continue
		if dist < best_score:
			best_score = dist
			best = node
	return best


func _on_enemy_killed(enemy: Node) -> void:
	## Pasiva Nombre prestado: derrotar a un enemigo marcado entrega fragmentos
	## de ceniza. Tope de acumulacion = el maximo del recurso (nunca por encima).
	var passive: Dictionary = _class_data.get("passives", {}).get("nombre_prestado", {})
	if passive.is_empty() or _player == null:
		return
	for index: int in _marks.size():
		if _marks[index].get("node", null) == enemy:
			_marks.remove_at(index)
			var gain := float(passive.get("fragment_gain", 8.0))
			_player.vigor = minf(_player.vigor + gain, _player.max_vigor)
			_player.stats_changed.emit()
			return


# ---------------------------------------------------------------------------
# Vela de los Ausentes
# ---------------------------------------------------------------------------


func _apply_veil(veil: Dictionary) -> void:
	## Sacrifica parte de la duracion RESTANTE del eco mas antiguo para curar
	## al Sepulturero y recuperar ceniza. Sin ecos validos no ocurre nada (la
	## validacion de lanzamiento ya exige un eco activo).
	if veil.is_empty():
		return
	var echoes := active_echoes()
	if echoes.is_empty():
		return
	var oldest: ArpgEcho = echoes[0]
	if oldest == null or not is_instance_valid(oldest):
		return
	oldest.consume_time(float(veil.get("duration_sacrifice_fraction", 0.5)))
	var healed := _player.heal(float(veil.get("heal_fraction", 0.15)) * _player.max_hp)
	_player.vigor = minf(_player.vigor + float(veil.get("resource_restore", 25.0)), _player.max_vigor)
	_player.stats_changed.emit()
	if healed > 0.0:
		_player.potion_used.emit(healed)


# ---------------------------------------------------------------------------
# Setup: conexiones del kit
# ---------------------------------------------------------------------------


func _on_setup() -> void:
	CombatEvents.enemy_killed.connect(_on_enemy_killed)

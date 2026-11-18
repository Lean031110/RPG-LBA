# gdlint: ignore=max-public-methods
class_name BrujaKit
extends ClassKit
## Kit de la Bruja de la Manigua (Fase 2, segunda clase jugable): hechicera de
## control a distancia. Identidad mecanica propia, NO una copia del Machetero:
## - Ataque basico y habilidades a DISTANCIA (proyectiles y zonas), sin melee.
## - Control de masas: ralentizacion (Niebla), inmovilizacion (Raices) y marca
##   (Mariposa) en vez de sangrado/rotura de armadura.
## - SIN bloqueo ni parada: su defensa es el posicionamiento (armadura 4).
## - Definitiva de ZONA persistente alrededor de la bruja (Manigua Despierta),
##   no un giro movil.
## - Pasiva Raiz Persistente: los controles duran mas sobre objetivos ya
##   afectados por naturaleza (slow/root), con limite contra jefes.
## - Pasiva Oido de la Manigua: tras permanecer quieta, recupera Esencia mas
##   rapido (la manigua responde al reposo).

const PASSIVE_STILL_TIME := 1.5
const ROOT_STATUS_IDS := ["slow", "root", "resin"]

var _action := "none"
var _action_timer := 0.0
var _action_params: Dictionary = {}
var _still_time := 0.0

# ---------------------------------------------------------------------------
# Consultas propias
# ---------------------------------------------------------------------------


func is_still_listening() -> bool:
	## Oido de la Manigua activo: la bruja lleva quieta el tiempo de sintonia.
	return _still_time >= PASSIVE_STILL_TIME


# ---------------------------------------------------------------------------
# Acciones
# ---------------------------------------------------------------------------


func try_attack() -> bool:
	## Espina menor: proyectil arcano basico sin coste. El combo del Machetero
	## no aplica: la bruja encadena a distancia con cadencia y posicion.
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
	return _begin_cast_action(basic, "attack")


func try_skill_index(index: int) -> bool:
	## Lanza la habilidad del hueco index (0..3). Las cuatro son tecnicas de
	## zona/proyectil: se validan igual (desbloqueo, coste, recarga) y su
	## efecto real se materializa en la ventana activa del SkillController.
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
	return _begin_cast_action(def, "skill")


func try_ultimate() -> bool:
	## Manigua Despierta: tormenta de zona alrededor de la bruja que danara y
	## ralentizara por ticks mientras dure. Consume toda la carga.
	if _player.is_dead() or not _player.statuses.can_act() or _player.skills.is_busy():
		return false
	var def: Dictionary = _class_data.get("ultimate", {})
	if def.is_empty() or not _player.is_skill_def_unlocked(def) or _ultimate_charge < _ultimate_max:
		return false
	_ultimate_charge = 0.0
	kit_charge_changed.emit(_ultimate_charge, _ultimate_max)
	kit_ultimate_cast.emit()
	_player.cooldowns.start("ultimate", float(def.get("cooldown", 1.0)))
	return _begin_cast_action(def, "ultimate")


func tick(delta: float) -> void:
	## Relojes del kit: duracion de la esquiva y sintonia de la pasiva Oido de
	## la Manigua (Esencia acelerada en reposo; la manigua responde al reposo).
	if _player.is_dodging:
		_action_timer += delta
		var duration := maxf(float(_action_params.get("duration", 0.3)), 0.05)
		if _action_timer >= duration:
			end_action()
	var moving := _player.velocity.length() > 0.35 or _player.skills.is_busy()
	if moving:
		_still_time = 0.0
	else:
		_still_time += delta


func end_action() -> void:
	_action = "none"
	_action_params = {}
	_action_timer = 0.0
	_player.is_dodging = false


# ---------------------------------------------------------------------------
# Materializacion de las tecnicas en la ventana activa
# ---------------------------------------------------------------------------


func _begin_cast_action(params: Dictionary, kind: String) -> bool:
	## Arranca el lanzamiento por el SkillController: windup (gesto) y en la
	## ventana activa se materializa el proyectil o la zona. Sin hitbox melee.
	_action = kind
	_action_timer = 0.0
	_action_params = params
	if not _player.skills.begin(params):
		return false
	if kind == "attack":
		_player.cooldowns.start("attack", float(params.get("cooldown", 0.7)))
	kit_action_started.emit(kind)
	return true


func _on_skill_action_started(_def: Dictionary) -> void:
	## La bruja orienta el lanzamiento hacia la direccion de entrada.
	_player.orient_to_input_or_forward()


func _on_attack_window_opened(def: Dictionary) -> void:
	## Ventana activa: materializar la tecnica REAL segun su kind.
	var kind := String(def.get("kind", ""))
	match kind:
		"projectile":
			_spawn_projectile(def, null)
		"familiar":
			_spawn_familiar(def)
		"zone":
			_spawn_zone(def, _zone_origin(def))
		"storm":
			_spawn_zone(def, _player.global_position, true)
		_:
			pass


func _on_attack_window_tick(_delta: float) -> void:
	## Las tecnicas de la bruja no mantienen ventana melee: el tick no hace
	## falta (proyectiles y zonas viven en el arbol con su propia fisica).
	pass


func _zone_origin(def: Dictionary) -> Vector3:
	## Origen de una zona lanzada: a distancia fija en la direccion mirada
	## (niebla delante para controlar el pasillo, raices bajo los pies si la
	## tecnica lo pide con zone_on_self).
	if bool(def.get("zone_on_self", false)):
		return _player.global_position
	var forward := _player.global_transform.basis.z
	var distance := float(def.get("zone", {}).get("cast_distance", 5.0))
	return _player.global_position + forward * distance


func _spawn_projectile(def: Dictionary, homing_target: Node3D) -> void:
	## Proyectil de la bruja: nace del plexo y viaja hacia donde mira la bruja
	## (o persigue al objetivo marcado si es familiar/homing).
	var origin := _player.global_position + Vector3(0, 1.0, 0)
	var direction := _player.global_transform.basis.z
	if homing_target == null and _player.targeting.has_target():
		var aim := _player.targeting.current()
		if aim != null and is_instance_valid(aim):
			direction = (aim.global_position + Vector3(0, 1.0, 0) - origin).normalized()
	var projectile := ArpgProjectile.make(
		_player, def, direction, origin, _player.HITBOX_LAYER, _player.HITBOX_MASK, ArpgLayers.WORLD, homing_target
	)
	_player.get_parent().add_child(projectile)


func _spawn_familiar(def: Dictionary) -> void:
	## Mariposa de Ceniza: proyectil guiado hacia el objetivo actual que lo
	## hostiga con pulsos de dano mientras viva. Sin objetivo: vuela de frente.
	var target: Node3D = _player.targeting.current() if _player.targeting.has_target() else null
	if target == null or not is_instance_valid(target):
		_spawn_projectile(def, null)
		return
	_spawn_projectile(def, target)


func _spawn_zone(def: Dictionary, position: Vector3, follow_shooter: bool = false) -> void:
	## Zona persistente (niebla/raices/manigua): la crea el motor de zonas con
	## las capas de combate del jugador.
	var zone := ArpgAreaEffect.make(
		_player,
		def,
		Vector3(position.x, 0.0, position.z),
		_player.HITBOX_LAYER,
		_player.HITBOX_MASK,
		ArpgLayers.WORLD,
		follow_shooter
	)
	_player.get_parent().add_child(zone)


# ---------------------------------------------------------------------------
# Pasivas
# ---------------------------------------------------------------------------


func resource_regen_multiplier() -> float:
	## Oido de la Manigua: en reposo sintonizado la Esencia fluye mas rapido.
	## El jugador consulta este multiplicador en su regeneracion de recurso.
	if is_still_listening():
		return float(_class_data.get("passives", {}).get("oido_manigua", {}).get("regen_multiplier", 2.0))
	return 1.0


func control_duration_multiplier(target: Node) -> float:
	## Raiz Persistente: los controles (slow/root/resina) duran MAS sobre un
	## objetivo ya afectado por naturaleza; contra jefes el aumento se recorta
	## (limite documentado del canon: no se encadena control infinito a un jefe).
	var data: Dictionary = _class_data.get("passives", {}).get("raiz_persistente", {})
	if data.is_empty():
		return 1.0
	var boost := float(data.get("control_duration_multiplier", 1.5))
	var boss_cap := float(data.get("boss_control_duration_multiplier", 1.15))
	if _target_is_boss(target):
		return boss_cap
	return boost


func _target_is_boss(target: Node) -> bool:
	## Un jefe se declara por propiedad o por datos (enemy_data.is_boss); los
	## enemigos actuales de la slice no son jefes, pero los 5 jefes de la Fase
	## oficial 5 usaran esta marca.
	if target == null:
		return false
	if "is_boss" in target:
		return bool(target.get("is_boss"))
	var enemy_data: Dictionary = target.get("enemy_data") if "enemy_data" in target else {}
	return bool(enemy_data.get("is_boss", false))


func boosted_control_status(status: Dictionary, target: Node) -> Dictionary:
	## Aplica Raiz Persistente a un status de control antes de aplicarlo: si el
	## objetivo ya tiene un control de naturaleza activo, la duracion se alarga
	## por el multiplicador de la pasiva.
	var id := String(status.get("id", ""))
	if id == "" or not ROOT_STATUS_IDS.has(id) or target == null:
		return status
	if not target.has_method("get_status_controller"):
		return status
	var statuses: StatusEffectController = target.get_status_controller()
	if statuses == null:
		return status
	for control_id: String in ROOT_STATUS_IDS:
		if statuses.has(control_id) and statuses.time_left(control_id) > 0.0:
			var boosted: Dictionary = status.duplicate(true)
			boosted["duration"] = float(status.get("duration", 1.0)) * control_duration_multiplier(target)
			return boosted
	return status

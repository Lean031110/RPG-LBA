class_name TargetingSystem
extends Node
## Selección de objetivo de combate (Fase 5): mantiene el enemigo enfocado que
## el HUD muestra (nombre, nivel, vida) y que las habilidades direccionales
## usan para orientarse. Escanea el grupo "arpg_enemies" con línea de visión y
## prioriza lo que el jugador tiene delante y más cerca.

signal target_changed(target: Node)

const RESCAN_INTERVAL := 0.25
const DEFAULT_MAX_RANGE := 14.0
const FRONT_DOT := 0.25

var max_range := DEFAULT_MAX_RANGE

var _target: Node3D = null
var _rescan_timer := 0.0
var _raycast: RayCast3D = null
var _los_mask := 0
var _viewer: Node3D = null


func setup(viewer: Node3D, los_mask: int) -> void:
	## viewer: el cuerpo del jugador (origen de distancias y dirección frontal).
	_viewer = viewer
	_los_mask = los_mask
	_raycast = RayCast3D.new()
	_raycast.name = "TargetLosRay"
	_raycast.collision_mask = los_mask
	_raycast.enabled = false
	_raycast.hit_from_inside = false
	add_child(_raycast)


func current() -> Node3D:
	return _target


func has_target() -> bool:
	return _target != null and is_instance_valid(_target) and _is_alive(_target)


func clear() -> void:
	if _target != null:
		_target = null
		target_changed.emit(null)


func tick(delta: float) -> void:
	## Revalidación continua: el objetivo muerto o liberado se descarta al
	## instante; el reescaneo periódico solo promociona un objetivo MEJOR
	## (más cercano y frontal) para evitar parpadeos del marco del HUD.
	if _target != null and (not is_instance_valid(_target) or not _is_alive(_target)):
		_target = null
		target_changed.emit(null)
	_rescan_timer -= delta
	if _rescan_timer <= 0.0:
		_rescan_timer = RESCAN_INTERVAL
		_promote_better_target()


func force_rescan() -> void:
	## Escaneo inmediato (p. ej. tras un golpe: el objetivo pasa a ser a quien
	## acabo de pegar si no tenía ninguno).
	_rescan_timer = RESCAN_INTERVAL
	_promote_better_target()


func notify_hit(enemy: Node3D) -> void:
	## Golpear a un enemigo lo convierte en objetivo si no hay uno ya (regla
	## ARPG móvil: la info del enemigo golpeado aparece en el marco).
	if _target == enemy:
		return
	if _target == null or not is_instance_valid(_target) or not _is_alive(_target):
		_target = enemy
		target_changed.emit(enemy)


func _is_alive(enemy: Node3D) -> bool:
	if enemy == null:
		return false
	if enemy.has_method("is_dead"):
		return not enemy.is_dead()
	return true


func _promote_better_target() -> void:
	if _viewer == null:
		return
	var candidates := get_tree().get_nodes_in_group("arpg_enemies")
	var best: Node3D = null
	var best_score := -1.0
	var forward := Vector3(_viewer.global_transform.basis.z.x, 0.0, _viewer.global_transform.basis.z.z).normalized()
	for node: Node in candidates:
		var enemy := node as Node3D
		if enemy == null or not is_instance_valid(enemy) or not _is_alive(enemy):
			continue
		var offset := enemy.global_position - _viewer.global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance > max_range:
			continue
		if not _has_line_of_sight(enemy):
			continue
		var dot := forward.dot(offset.normalized()) if distance > 0.05 else 1.0
		if dot < FRONT_DOT:
			continue
		## Puntuación: cercanía + frontalidad (el frontal más cercano gana).
		var score := (1.0 - clampf(distance / max_range, 0.0, 1.0)) * 0.7 + maxf(dot, 0.0) * 0.3
		if score > best_score:
			best_score = score
			best = enemy
	if best != _target:
		_target = best
		target_changed.emit(best)


func _has_line_of_sight(enemy: Node3D) -> bool:
	if _raycast == null:
		return true
	var from := _viewer.global_position + Vector3(0, 1.2, 0)
	var to := enemy.global_position + Vector3(0, 1.0, 0)
	_raycast.global_position = from
	_raycast.target_position = _raycast.to_local(to)
	_raycast.enabled = true
	_raycast.force_raycast_update()
	var collider := _raycast.get_collider()
	_raycast.enabled = false
	if collider == null:
		return true
	return collider == enemy or collider.is_ancestor_of(enemy) or enemy.is_ancestor_of(collider)

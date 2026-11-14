class_name HitboxController
extends Node3D
## Hitbox de ataque reutilizable (Fase 5): la usan el jugador y los enemigos,
## de modo que todos los golpes siguen LAS MISMAS reglas — ventana activa,
## golpes únicos por swing (sin dobles daños) y trayectoria libre (LOS): un
## enemigo tras un muro fino dentro del área del golpe NO recibe daño.
##
## La animación nunca es fuente de verdad: la colisión solo existe entre
## open() y close().

signal window_opened
signal window_closed

const MIN_CHORD := 1.2
const BODY_Y := 1.0
const LOS_FROM_HEIGHT := 1.2
const LOS_TO_HEIGHT := 1.0

var _area: Area3D = null
var _shape: CollisionShape3D = null
var _box: BoxShape3D = null
var _raycast: RayCast3D = null
var _window_open := false
var _hits_this_swing: Array[Node] = []
var _owner_body: Node3D = null
var _los_mask := 0


func setup(owner_body: Node3D, layer: int, mask: int, los_mask: int) -> void:
	## owner_body: el CharacterBody3D dueño del golpe (para excluirlo del LOS y
	## de los objetivos). los_mask: capas que BLOQUEAN la trayectoria (muros).
	_owner_body = owner_body
	_los_mask = los_mask
	_area = Area3D.new()
	_area.name = "AttackHitbox"
	_area.collision_layer = layer
	_area.collision_mask = mask
	_area.monitoring = true
	_box = BoxShape3D.new()
	_box.size = Vector3(2.0, 2.2, 2.4)
	_shape = CollisionShape3D.new()
	_shape.shape = _box
	_shape.disabled = true
	_shape.position = Vector3(0, BODY_Y, 1.4)
	_area.add_child(_shape)
	add_child(_area)
	_raycast = RayCast3D.new()
	_raycast.name = "LosRay"
	_raycast.collision_mask = los_mask
	_raycast.enabled = false
	_raycast.hit_from_inside = false
	add_child(_raycast)


func open(reach: float, arc_deg: float, height := 2.2) -> void:
	## Activa la ventana con la geometría del golpe: cuerda del arco de ancho,
	## alcance de profundidad, alto configurable. Un arco de 360° no tiene
	## cuerda útil: la caja se CENTRA en el atacante (alcanza todo el radio;
	## golpes de área como el Guarapo, la Carga que atraviesa y el Huracán).
	var centered := arc_deg >= 359.0
	var chord := 2.0 * reach * sin(deg_to_rad(arc_deg) * 0.5)
	var depth := maxf(reach, 0.5)
	if centered:
		## Área completa: la caja cubre el radio en TODAS direcciones
		## (alcance a reach metros en x y en z, no la mitad).
		chord = reach * 2.0
		depth = reach * 2.0
	_box.size = Vector3(maxf(chord, MIN_CHORD), height, depth)
	var z_offset := 0.0 if centered else depth * 0.5
	_shape.position = Vector3(0, BODY_Y, z_offset)
	_shape.disabled = false
	_window_open = true
	window_opened.emit()


func close() -> void:
	if _shape != null and not _shape.disabled:
		_shape.disabled = true
	if _window_open:
		_window_open = false
		window_closed.emit()


func reset_swing() -> void:
	## Nuevo swing: los objetivos golpeados en el swing anterior vuelven a ser
	## válidos (cada golpe cuenta una vez por swing, no por batalla).
	_hits_this_swing.clear()


func is_open() -> bool:
	return _window_open


func collect_new_hits() -> Array[Node]:
	## Objetivos válidos del frame: dentro del área, no golpeados aún en este
	## swing, con trayectoria libre hasta ellos (LOS contra muros).
	if not _window_open or _area == null:
		return []
	var fresh: Array[Node] = []
	for body: Node in _area.get_overlapping_bodies():
		if body == _owner_body or body == null:
			continue
		if body in _hits_this_swing:
			continue
		if not body.has_method("take_damage"):
			continue
		if not _has_line_of_sight(body as Node3D):
			continue
		_hits_this_swing.append(body)
		fresh.append(body)
	return fresh


func _has_line_of_sight(target: Node3D) -> bool:
	## Rayo desde el pecho del atacante al del objetivo: si un muro lo corta
	## antes, el golpe no conecta. El propio dueño se excluye para no golpearse.
	if target == null or _owner_body == null:
		return false
	var from := _owner_body.global_position + Vector3(0, LOS_FROM_HEIGHT, 0)
	var to := target.global_position + Vector3(0, LOS_TO_HEIGHT, 0)
	_raycast.global_position = from
	_raycast.target_position = _raycast.to_local(to)
	_raycast.enabled = true
	_raycast.force_raycast_update()
	var collider := _raycast.get_collider()
	_raycast.enabled = false
	if collider == null:
		return true
	return collider == target or collider.is_ancestor_of(target) or target.is_ancestor_of(collider)

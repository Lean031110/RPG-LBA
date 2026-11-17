class_name ArpgAreaEffect
extends Node3D
## Zona persistente de combate (Fase 2, Bruja): nieblas, raices y tormentas.
## Cada tick aplica dano real (resolve_strike del dueno) y/o un estado (slow,
## root) a los enemigos dentro del radio, con LOS contra muros. La zona es
## puramente logica + un disco visual translucido; la vida la gestiona el
## motor (nada de estados fantasma tras expirar).

signal area_expired

const TICK_EPSILON := 0.001

var _shooter: Node3D = null
var _def: Dictionary = {}
var _radius := 1.0
var _duration := 1.0
var _tick_interval := 0.5
var _tick_def: Dictionary = {}
var _status: Dictionary = {}
var _time_left := 0.0
var _tick_timer := 0.0
var _area: Area3D = null
var _shape: CollisionShape3D = null
var _cylinder: CylinderShape3D = null
var _raycast: RayCast3D = null
var _owner_body: Node3D = null
var _los_mask := 0
var _alive := false
var _follow_shooter := false


static func make(
	shooter: Node3D,
	def: Dictionary,
	zone_position: Vector3,
	layer: int,
	mask: int,
	los_mask: int,
	follow_shooter: bool = false
) -> ArpgAreaEffect:
	## Fabrica una zona lista para add_child: def con seccion "zone"
	## (radius, duration, tick_interval, tick_status) y tick_def/tick_status.
	var zone := ArpgAreaEffect.new()
	zone.name = String(def.get("id", "zona"))
	zone._configure(shooter, def, zone_position, layer, mask, los_mask, follow_shooter)
	return zone


func _configure(
	shooter: Node3D, def: Dictionary, zone_position: Vector3, layer: int, mask: int, los_mask: int, follow_shooter: bool
) -> void:
	_shooter = shooter
	_owner_body = shooter
	_def = def
	_los_mask = los_mask
	_follow_shooter = follow_shooter
	var zone_def: Dictionary = def.get("zone", {})
	_radius = maxf(float(zone_def.get("radius", 3.0)), 0.5)
	_duration = maxf(float(zone_def.get("duration", 4.0)), 0.2)
	_tick_interval = maxf(float(zone_def.get("tick_interval", 0.5)), 0.05)
	_tick_def = def.get("zone_tick", {})
	_status = def.get("zone_status", {})
	_time_left = _duration
	position = zone_position
	# Visual: disco translucido + anillo de la paleta de la tecnica.
	var visual := MeshInstance3D.new()
	visual.name = "ZonaVisual"
	var disc := CylinderMesh.new()
	disc.top_radius = _radius
	disc.bottom_radius = _radius
	disc.height = 0.18
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var tone := _color_from_data(zone_def.get("color", Color(0.3, 0.55, 0.4)))
	material.albedo_color = Color(tone, float(zone_def.get("alpha", 0.35)))
	disc.material = material
	visual.mesh = disc
	visual.position = Vector3(0, 0.12, 0)
	add_child(visual)
	_area = Area3D.new()
	_area.name = "ZonaArea"
	_area.collision_layer = layer
	_area.collision_mask = mask
	_area.monitoring = true
	_cylinder = CylinderShape3D.new()
	_cylinder.radius = _radius
	_cylinder.height = 2.4
	_shape = CollisionShape3D.new()
	_shape.shape = _cylinder
	_shape.position = Vector3(0, 1.2, 0)
	_area.add_child(_shape)
	add_child(_area)
	_raycast = RayCast3D.new()
	_raycast.name = "ZonaLosRay"
	_raycast.collision_mask = los_mask
	_raycast.enabled = false
	_raycast.hit_from_inside = false
	add_child(_raycast)
	_alive = true


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_expire()
		return
	if _follow_shooter and _owner_body != null and is_instance_valid(_owner_body):
		global_position = Vector3(_owner_body.global_position.x, global_position.y, _owner_body.global_position.z)
	_tick_timer += delta
	if _tick_timer + TICK_EPSILON >= _tick_interval:
		_tick_timer = 0.0
		_apply_tick()


func _apply_tick() -> void:
	## Pulso de zona: a cada enemigo dentro del radio con LOS se le aplica el
	## dano por tick (zone_tick) y/o el estado (zone_status) con su duracion.
	for body: Node in _area.get_overlapping_bodies():
		if body == _owner_body or body == null:
			continue
		if not body.has_method("take_damage"):
			continue
		if not _has_line_of_sight(body as Node3D):
			continue
		if not _tick_def.is_empty():
			_shooter.resolve_strike(body, _tick_def)
		if not _status.is_empty() and body.has_method("apply_status"):
			var params: Dictionary = _status.get("params", {})
			params["source_id"] = name
			body.apply_status(String(_status.get("id", "")), float(_status.get("duration", 1.0)), params)


func remaining_time() -> float:
	return maxf(_time_left, 0.0)


func _has_line_of_sight(target: Node3D) -> bool:
	if target == null:
		return false
	var from := global_position + Vector3(0, 1.2, 0)
	var to := target.global_position + Vector3(0, 1.0, 0)
	_raycast.global_position = from
	_raycast.target_position = _raycast.to_local(to)
	_raycast.enabled = true
	_raycast.force_raycast_update()
	var collider := _raycast.get_collider()
	_raycast.enabled = false
	if collider == null:
		return true
	return collider == target or collider.is_ancestor_of(target) or target.is_ancestor_of(collider)


func _expire() -> void:
	if not _alive:
		return
	_alive = false
	area_expired.emit()
	queue_free()


static func _color_from_data(value: Variant) -> Color:
	## Los datos JSON traen el color como array [r, g, b]; los internos, Color.
	if value is Color:
		return value
	if value is Array and (value as Array).size() >= 3:
		var values := value as Array
		return Color(float(values[0]), float(values[1]), float(values[2]))
	return Color(0.3, 0.55, 0.4)

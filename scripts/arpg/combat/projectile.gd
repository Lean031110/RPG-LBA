class_name ArpgProjectile
extends Node3D
## Proyectil de combate (Fase 2, clases a distancia): viaja en linea recta o
## persigue un objetivo (familiar), danando con las reglas REALES del motor
## (resolve_strike del dueno: estadisticas, estados, critico). La colision es
## por Area3D con LOS, igual que el hitbox melee: nada de danos a traves de
## muros. Un proyectil atraviesa N objetivos segun su penetracion y se
## destruye al agotar vida/penetracion/objetivo.
##
## El dueno pasa: shooter (Node3D con resolve_strike), def de tecnica con
## seccion "projectile", y layer/mask/los_mask de combate.

signal projectile_expired

const BODY_Y := 1.0
const HIT_CHECK_INTERVAL := 0.05

var _shooter: Node3D = null
var _def: Dictionary = {}
var _p_def: Dictionary = {}
var _velocity := Vector3.ZERO
var _lifetime := 0.0
var _max_targets := 1
var _homing_target: Node3D = null
var _homing_turn_rate := 0.0
var _tick_interval := 0.0
var _tick_timer := 0.0
var _tick_def: Dictionary = {}
var _mesh: MeshInstance3D = null
var _area: Area3D = null
var _shape: CollisionShape3D = null
var _sphere: SphereShape3D = null
var _raycast: RayCast3D = null
var _owner_body: Node3D = null
var _los_mask := 0
var _alive := false
var _hit_bodies: Array[Node] = []


static func make(
	shooter: Node3D,
	def: Dictionary,
	direction: Vector3,
	origin: Vector3,
	layer: int,
	mask: int,
	los_mask: int,
	homing_target: Node3D = null
) -> ArpgProjectile:
	## Fabrica un proyectil listo para add_child al arbol de la escena. El
	## origen se fija como posicion LOCAL antes de entrar al arbol (asignar
	## global_position fuera del arbol es un error de Godot).
	var projectile := ArpgProjectile.new()
	projectile.name = String(def.get("id", "proyectil"))
	projectile._configure(shooter, def, direction, layer, mask, los_mask, homing_target)
	projectile.position = origin
	return projectile


func _configure(
	shooter: Node3D, def: Dictionary, direction: Vector3, layer: int, mask: int, los_mask: int, homing_target: Node3D
) -> void:
	_shooter = shooter
	_owner_body = shooter
	_def = def
	_p_def = def.get("projectile", {})
	_los_mask = los_mask
	_homing_target = homing_target
	_homing_turn_rate = float(_p_def.get("homing_turn_rate", 0.0))
	var speed := maxf(float(_p_def.get("speed", 18.0)), 1.0)
	_velocity = direction.normalized() * speed
	_lifetime = maxf(float(_p_def.get("lifetime", 1.5)), 0.1)
	## pierce = TOTAL de enemigos que el proyectil puede danar (1 = sin
	## penetracion; la Espina de Jucaro cruza 3). Tope duro 64 por sanidad.
	_max_targets = clampi(int(_p_def.get("pierce", 1)), 1, 64)
	_tick_interval = maxf(float(_p_def.get("tick_interval", 0.0)), 0.0)
	_tick_def = def.get("projectile_tick", {})
	# Visual: esfera compuesta de la paleta de la tecnica (verde manigua, etc.).
	var radius := maxf(float(_p_def.get("radius", 0.45)), 0.15)
	_mesh = MeshInstance3D.new()
	_mesh.name = "ProyectilVisual"
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
	var material := StandardMaterial3D.new()
	var tone := _color_from_data(_p_def.get("color", Color(0.35, 0.75, 0.45)))
	material.albedo_color = tone
	material.emission_enabled = true
	material.emission = tone
	material.emission_energy_multiplier = 1.4
	sphere_mesh.material = material
	_mesh.mesh = sphere_mesh
	_mesh.position = Vector3.ZERO
	add_child(_mesh)
	# Deteccion: Area3D esferica con la MISMA mascara de combate del dueno.
	_area = Area3D.new()
	_area.name = "ProyectilArea"
	_area.collision_layer = layer
	_area.collision_mask = mask
	_area.monitoring = true
	_sphere = SphereShape3D.new()
	_sphere.radius = radius + 0.35
	_shape = CollisionShape3D.new()
	_shape.shape = _sphere
	_shape.position = Vector3.ZERO
	_area.add_child(_shape)
	add_child(_area)
	_raycast = RayCast3D.new()
	_raycast.name = "ProyectilLosRay"
	_raycast.collision_mask = los_mask
	_raycast.enabled = false
	_raycast.hit_from_inside = false
	add_child(_raycast)
	_alive = true


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_lifetime -= delta
	if _lifetime <= 0.0:
		_expire()
		return
	if _homing_target != null and is_instance_valid(_homing_target):
		_steer_toward(_homing_target.global_position + Vector3(0, BODY_Y, 0), delta)
	translate(_velocity * delta)
	if _tick_interval > 0.0 and not _tick_def.is_empty():
		_tick_timer += delta
		if _tick_timer >= _tick_interval:
			_tick_timer = 0.0
			_resolve_area_tick()
	_resolve_hits()


func _steer_toward(point: Vector3, delta: float) -> void:
	## Guiado del familiar: rota la velocidad hacia el objetivo con tope de
	## giro (no teleporta direccion: la mariposa vuela, no se teletransporta).
	var desired := (point - global_position).normalized() * _velocity.length()
	_homing_turn_rate = maxf(_homing_turn_rate, 1.0)
	_velocity = _velocity.lerp(desired, clampf(_homing_turn_rate * delta, 0.0, 1.0))


func _resolve_hits() -> void:
	## Objetivos tocados por el proyectil este frame: dano real por
	## resolve_strike del dueno, con LOS (nada de atravesar muros) y sin repetir
	## objetivo (pierce = total de enemigos que atraviesa; los cuerpos
	## ya golpeados se excluyen LOGICAMENTE, sin tocar la fisica del area).
	for body: Node in _area.get_overlapping_bodies():
		if body == _owner_body or body == null:
			continue
		if body in _hit_bodies:
			continue
		if not body.has_method("take_damage"):
			continue
		if not _has_line_of_sight(body as Node3D):
			continue
		if _hit_bodies.size() >= _max_targets:
			_expire()
			return
		_hit_bodies.append(body)
		_shooter.resolve_strike(body, _def)


func _resolve_area_tick() -> void:
	## Pulsos del familiar alrededor de su objetivo marcado (hostigar): dano
	## menor en radio corto usando la def projectile_tick.
	var radius := float(_tick_def.get("radius", 1.2))
	var hits := 0
	for body: Node in _area.get_overlapping_bodies():
		if body == _owner_body or body == null or not body.has_method("take_damage"):
			continue
		_shooter.resolve_strike(body, _tick_def)
		hits += 1
	if hits == 0 and _homing_target != null and is_instance_valid(_homing_target):
		var distance := global_position.distance_to(_homing_target.global_position)
		if distance <= radius:
			_shooter.resolve_strike(_homing_target, _tick_def)


func _has_line_of_sight(target: Node3D) -> bool:
	if target == null or _owner_body == null:
		return false
	var from := global_position
	var to := target.global_position + Vector3(0, BODY_Y, 0)
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
	projectile_expired.emit()
	queue_free()


static func _color_from_data(value: Variant) -> Color:
	## Los datos JSON traen el color como array [r, g, b]; los internos, Color.
	if value is Color:
		return value
	if value is Array and (value as Array).size() >= 3:
		var values := value as Array
		return Color(float(values[0]), float(values[1]), float(values[2]))
	return Color(0.35, 0.75, 0.45)

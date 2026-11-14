class_name PerroDeCeniza
extends ArpgEnemy
## Especie: Perro de ceniza (monstruario canon §8). Comportamiento de manada:
## rápido y débil, RODEA al objetivo en círculo mientras persigue (en vez de
## ir en línea recta como la Sombra) y su aullido (a intervalos) le da prisa a
## él y a los demás perros cercanos. Muerde rápido: windup corto y daño bajo.

const CIRCLE_DIRECTION_RANDOM_CHANCE := 0.3
const HOWL_INTERVAL := 6.0
const HOWL_RADIUS := 8.0
const HOWL_HASTE_DURATION := 3.0
const HOWL_HASTE_MULTIPLIER := 1.35

var _circle_side := 1.0
var _howl_timer := 0.0
var _puppet: Node3D = null
var _body_mesh: MeshInstance3D = null
var _tail: MeshInstance3D = null
var _leg_phase := 0.0
var _leg_l: MeshInstance3D = null
var _leg_r: MeshInstance3D = null


func _build_visual() -> void:
	## Sabueso espectral: cuadrúpedo gris ceniza con ojos brasa y cola errante.
	_puppet = Node3D.new()
	_puppet.name = "AshHoundPuppet"
	add_child(_puppet)
	var ash_mat := VisualKit.noise_material(Color(0.42, 0.4, 0.44), 0.35, 5)
	var dark_mat := VisualKit.flat_material(Color(0.16, 0.15, 0.18))
	# Cuerpo horizontal bajo (cuadrúpedo).
	_body_mesh = VisualKit.add_box(_puppet, Vector3(0.42, 0.38, 0.92), Vector3(0, 0.62, 0), ash_mat)
	# Cabeza con hocico.
	VisualKit.add_box(_puppet, Vector3(0.3, 0.28, 0.34), Vector3(0, 0.78, 0.58), ash_mat)
	VisualKit.add_box(_puppet, Vector3(0.18, 0.16, 0.22), Vector3(0, 0.7, 0.82), dark_mat)
	# Orejas puntiagudas.
	VisualKit.add_cone(_puppet, 0.07, 0.2, Vector3(-0.1, 0.98, 0.52), dark_mat)
	VisualKit.add_cone(_puppet, 0.07, 0.2, Vector3(0.1, 0.98, 0.52), dark_mat)
	# Ojos brasa.
	var ember := VisualKit.flat_material(Color(1.0, 0.45, 0.15), Color(1.0, 0.45, 0.15), 2.4)
	VisualKit.add_sphere(_puppet, 0.045, Vector3(-0.08, 0.82, 0.74), ember)
	VisualKit.add_sphere(_puppet, 0.045, Vector3(0.08, 0.82, 0.74), ember)
	# Patas con pivote para el galope.
	var leg_l_node := Node3D.new()
	leg_l_node.position = Vector3(-0.16, 0.5, 0.3)
	_puppet.add_child(leg_l_node)
	_leg_l = VisualKit.add_box(leg_l_node, Vector3(0.1, 0.5, 0.12), Vector3(0, -0.25, 0), ash_mat)
	var leg_r_node := Node3D.new()
	leg_r_node.position = Vector3(0.16, 0.5, 0.3)
	_puppet.add_child(leg_r_node)
	_leg_r = VisualKit.add_box(leg_r_node, Vector3(0.1, 0.5, 0.12), Vector3(0, -0.25, 0), ash_mat)
	VisualKit.add_box(_puppet, Vector3(0.1, 0.44, 0.12), Vector3(-0.16, 0.28, -0.32), ash_mat)
	VisualKit.add_box(_puppet, Vector3(0.1, 0.44, 0.12), Vector3(0.16, 0.28, -0.32), ash_mat)
	# Cola: estela de ceniza.
	_tail = VisualKit.add_box(_puppet, Vector3(0.08, 0.08, 0.5), Vector3(0, 0.72, -0.62), dark_mat)


func _animate(delta: float) -> void:
	if state == InternalState.DEAD:
		return
	## El aullido de caza es continuo mientras viva (canon: marcan y llaman),
	## no solo en la persecución: el timer corre desde que detecta.
	if state != InternalState.IDLE:
		_update_howl(delta)
	_leg_phase += delta * (8.0 if state == InternalState.CHASE else 2.0)
	if _leg_l != null:
		_leg_l.rotation.x = sin(_leg_phase) * 0.7
		_leg_r.rotation.x = -sin(_leg_phase) * 0.7
	if _tail != null:
		_tail.rotation.y = sin(_leg_phase * 0.6) * 0.5


func _process_chase_behavior(_delta: float, direction: Vector3) -> void:
	## Rodeo de manada: en vez de la línea recta, el perro orbita al objetivo
	## (componente lateral según su lado de círculo). El lado se re-sortea de
	## vez en cuando para que la manada no gire todas al mismo lado.
	if randf() < CIRCLE_DIRECTION_RANDOM_CHANCE * _delta_safe_factor():
		_circle_side = -_circle_side
	var lateral := Vector3(-direction.z, 0, direction.x) * _circle_side
	var orbit_blend := float(enemy_data.get("circle_blend", 0.45))
	var base_speed := float(enemy_data.get("move_speed", 4.6)) * statuses.move_speed_multiplier()
	var heading := (direction + lateral * orbit_blend).normalized()
	velocity.x = heading.x * base_speed
	velocity.z = heading.z * base_speed
	_face_towards(direction, _delta_safe_factor())


func _delta_safe_factor() -> float:
	return maxf(get_physics_process_delta_time(), 0.016)


func _update_howl(delta: float) -> void:
	## Aullido de caza (canon: "marcan y llaman refuerzos"): prisa para él y
	## para los demás perros de ceniza cercanos. Es un estado alterado real
	## (haste) con duración, no un multiplicador oculto.
	_howl_timer += delta
	if _howl_timer < HOWL_INTERVAL:
		return
	_howl_timer = 0.0
	_visual_howl()
	for node: Node in get_tree().get_nodes_in_group("arpg_enemies"):
		var other := node as Node3D
		if other == null or not is_instance_valid(other):
			continue
		if not (other is PerroDeCeniza):
			continue
		if other.global_position.distance_to(global_position) > HOWL_RADIUS:
			continue
		if other.has_method("apply_status"):
			other.apply_status("haste", HOWL_HASTE_DURATION, {"multiplier": HOWL_HASTE_MULTIPLIER})


func _visual_howl() -> void:
	## Aullido visible: la cabeza se alza un instante (sin partículas nuevas).
	if _puppet == null:
		return
	var tween := create_tween()
	tween.tween_property(_puppet, "rotation:x", -0.25, 0.12)
	tween.tween_property(_puppet, "rotation:x", 0.0, 0.2)


func _visual_telegraph(progress: float) -> void:
	## El telégrafo del perro: agacharse antes de saltar a morder.
	if _puppet == null:
		return
	_puppet.rotation.x = -0.18 * progress


func _visual_root() -> Node3D:
	return _puppet

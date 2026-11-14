class_name ArpgOcclusionManager
extends Node3D
## Oclusión de cámara estilo ARPG (iteración 4C): cuando un edificio o muro del
## grupo "arpg_occluders" se interpone entre la cámara isométrica y el jugador,
## su material pasa a semitransparente de forma temporal y reversible. No se
## elimina ni se mueve geometría: solo se desvanece y se restaura.
##
## Referencias: Diablo Immortal / Mobile Legends (silueta del héroe siempre
## visible tras paredes). Coste: 3 raycasts por frame de física + tween por
## cambio de estado, sin asignaciones por frame.

const GROUP := "arpg_occluders"
const OCCLUDED_ALPHA := 0.24
const FADE_TIME := 0.18
## Histéresis: un muro solo se RESTAURA tras N frames seguidos sin ocluir;
## evita el parpadeo al rozar el borde de un muro (y los micro-miss del raycast).
const RESTORE_AFTER_CLEAR_FRAMES := 3

@export var occlusion_mask := 0  # 0 = usar la capa WORLD de ArpgLayers.

var _camera: Camera3D = null
var _target: Node3D = null
var _fading: Dictionary = {}  # MeshInstance3D -> {"material": StandardMaterial3D, "tween": Tween}
var _clear_streak: Dictionary = {}  # MeshInstance3D -> frames seguidos sin ocluir
var _space: PhysicsDirectSpaceState3D = null


func setup(camera: Camera3D, target: Node3D) -> void:
	_camera = camera
	_target = target


func _physics_process(_delta: float) -> void:
	if _camera == null or _target == null or not is_instance_valid(_target):
		return
	_space = get_world_3d().direct_space_state
	var from := _camera.global_position
	var occluders := {}
	# Tres sondas (pies, torso, cabeza): basta con que una línea libre para
	# considerar visible esa porción; un muro que tape TODO activa el fundido.
	for offset: float in [0.15, 0.9, 1.6]:
		var to := _target.global_position + Vector3(0, offset, 0)
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_areas = false
		query.collision_mask = ArpgLayers.WORLD if occlusion_mask == 0 else occlusion_mask
		var hits := _cast_all(query)
		for mesh: MeshInstance3D in hits:
			if mesh.is_in_group(GROUP):
				occluders[mesh] = true
	_update_fades(occluders)


func _cast_all(query: PhysicsRayQueryParameters3D) -> Array:
	## Todos los impactos del segmento (no solo el primero): un edificio alto
	## puede estar detrás de un muro bajo y ambos cuentan como oclusores.
	var hits: Array = []
	var max_iterations := 8
	for index: int in max_iterations:
		var result := _space.intersect_ray(query)
		if result.is_empty():
			break
		var collider: Object = result.get("collider")
		var mesh := _mesh_for(collider)
		if mesh != null:
			hits.append(mesh)
		# Continuar justo después del impacto.
		var next_from: Vector3 = result.get("position") + (query.to - query.from).normalized() * 0.05
		if next_from.distance_to(query.to) < 0.1:
			break
		var next_query := PhysicsRayQueryParameters3D.create(next_from, query.to)
		next_query.collide_with_areas = false
		next_query.collision_mask = ArpgLayers.WORLD if occlusion_mask == 0 else occlusion_mask
		query = next_query
	return hits


func _mesh_for(collider: Object) -> MeshInstance3D:
	## El StaticBody3D de un muro/casa puede ser el padre de la malla o colgar
	## de ella; se busca la MeshInstance3D del grupo de oclusores.
	if collider == null:
		return null
	if collider is MeshInstance3D and collider.is_in_group(GROUP):
		return collider
	if collider is Node3D:
		for child: Node in (collider as Node3D).get_children():
			if child is MeshInstance3D and child.is_in_group(GROUP):
				return child
		var parent := (collider as Node3D).get_parent()
		if parent is MeshInstance3D and parent.is_in_group(GROUP):
			return parent
	return null


func _update_fades(occluders: Dictionary) -> void:
	# Nuevos oclusores: fundir hacia transparente (y rompe su racha limpia).
	for mesh: MeshInstance3D in occluders:
		_clear_streak.erase(mesh)
		if not _fading.has(mesh):
			_fade_to(mesh, OCCLUDED_ALPHA)
	# Los que ya no ocluyen: restaurar solo tras N frames seguidos libres.
	var restored: Array = []
	for mesh: Variant in _fading:
		if occluders.has(mesh):
			continue
		var streak: int = int(_clear_streak.get(mesh, 0)) + 1
		_clear_streak[mesh] = streak
		if streak >= RESTORE_AFTER_CLEAR_FRAMES:
			restored.append(mesh)
	for mesh: Variant in restored:
		_clear_streak.erase(mesh)
		_fade_to(mesh, 1.0, true)


func _fade_to(mesh: MeshInstance3D, alpha: float, restore := false) -> void:
	var entry: Dictionary = _fading.get(mesh, {})
	var material: StandardMaterial3D = entry.get("material")
	if material == null:
		# Primera vez: material propio (duplicado) para no desvanecer objetos
		# que comparten el original (materiales compartidos del builder).
		var base: Material = mesh.material_override
		if base == null:
			return
		if base is StandardMaterial3D:
			material = (base as StandardMaterial3D).duplicate() as StandardMaterial3D
		else:
			return
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh.material_override = material
		_fading[mesh] = {"material": material, "tween": null}
	if entry.has("tween") and entry["tween"] is Tween and (entry["tween"] as Tween).is_valid():
		(entry["tween"] as Tween).kill()
	var tween := create_tween()
	tween.tween_property(material, "albedo_color:a", alpha, FADE_TIME)
	_fading[mesh]["tween"] = tween
	if restore:
		tween.finished.connect(
			func() -> void:
				if is_instance_valid(mesh) and _fading.has(mesh):
					var data: Dictionary = _fading[mesh]
					var restored_material: StandardMaterial3D = data["material"]
					restored_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
					restored_material.albedo_color.a = 1.0
					_fading.erase(mesh)
		)

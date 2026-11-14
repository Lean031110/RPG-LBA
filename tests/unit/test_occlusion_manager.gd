class_name TestOcclusionManager
extends GdUnitTestSuite
## Iteración 4C: oclusión de cámara ARPG. Un muro del grupo "arpg_occluders"
## interpuesto entre la cámara y el jugador se vuelve semitransparente de forma
## reversible; la geometría nunca se elimina ni se mueve.


func _frames(count: int) -> void:
	for index: int in count:
		await get_tree().physics_frame


func _make_scene() -> Dictionary:
	## Escena mínima: cámara alta mirando al jugador con un muro en medio.
	var holder: Node3D = auto_free(Node3D.new())
	add_child(holder)
	var camera: Camera3D = auto_free(Camera3D.new())
	camera.position = Vector3(0, 14.5, 10)
	holder.add_child(camera)
	var player: Node3D = auto_free(CharacterBody3D.new())
	player.position = Vector3(0, 0, -6)
	holder.add_child(player)
	var wall_body := StaticBody3D.new()
	wall_body.collision_layer = ArpgLayers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(8, 3, 0.8)
	shape.shape = box
	wall_body.add_child(shape)
	wall_body.position = Vector3(0, 1.5, -5)
	holder.add_child(wall_body)
	var wall_mesh := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box.size
	wall_mesh.mesh = mesh
	wall_mesh.material_override = VisualKit.noise_material(Color(0.44, 0.4, 0.34), 0.15, 3)
	wall_mesh.add_to_group("arpg_occluders")
	wall_body.add_child(wall_mesh)
	var manager: ArpgOcclusionManager = auto_free(ArpgOcclusionManager.new())
	holder.add_child(manager)
	manager.setup(camera, player)
	return {"manager": manager, "wall": wall_mesh, "player": player, "camera": camera}


func test_wall_between_camera_and_player_fades() -> void:
	var scene := _make_scene()
	var manager: ArpgOcclusionManager = scene["manager"]
	var wall: MeshInstance3D = scene["wall"]
	# La animación dura 0.18 s (~11 frames físicos); esperar 40 deja margen
	# para el intercalado proceso/física de headless (corrida report_8: fallaba
	# midiendo a los 8 frames con el fundido a medio camino).
	await _frames(40)
	# El muro está en el diccionario de fundido y su material se duplicó
	# (el original compartido queda intacto para el resto del mundo).
	assert_bool(manager._fading.has(wall)).is_true()
	var material: StandardMaterial3D = manager._fading[wall]["material"]
	assert_int(material.transparency).is_equal(BaseMaterial3D.TRANSPARENCY_ALPHA)
	assert_float(material.albedo_color.a).is_less(0.5)


func test_clear_line_keeps_wall_opaque() -> void:
	var scene := _make_scene()
	var manager: ArpgOcclusionManager = scene["manager"]
	var wall: MeshInstance3D = scene["wall"]
	var player: Node3D = scene["player"]
	# El jugador se aparta del muro: línea cámara-jugador libre.
	player.position = Vector3(0, 0, 12)
	await _frames(10)
	assert_bool(manager._fading.has(wall)).is_false()


func test_original_shared_material_is_never_mutated() -> void:
	var shared := VisualKit.noise_material(Color(0.44, 0.4, 0.34), 0.15, 3)
	var holder: Node3D = auto_free(Node3D.new())
	add_child(holder)
	var player: Node3D = auto_free(CharacterBody3D.new())
	player.position = Vector3(0, 0, -6)
	holder.add_child(player)
	var wall_body := StaticBody3D.new()
	wall_body.collision_layer = ArpgLayers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(8, 3, 0.8)
	shape.shape = box
	wall_body.add_child(shape)
	wall_body.position = Vector3(0, 1.5, -5)
	holder.add_child(wall_body)
	var wall_mesh := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box.size
	wall_mesh.mesh = mesh
	wall_mesh.material_override = shared
	wall_mesh.add_to_group("arpg_occluders")
	wall_body.add_child(wall_mesh)
	var camera: Camera3D = auto_free(Camera3D.new())
	camera.position = Vector3(0, 14.5, 10)
	holder.add_child(camera)
	var manager: ArpgOcclusionManager = auto_free(ArpgOcclusionManager.new())
	holder.add_child(manager)
	manager.setup(camera, player)
	await _frames(40)
	# El material del mundo sigue opaco; el fundido usa una copia.
	assert_int(shared.transparency).is_equal(BaseMaterial3D.TRANSPARENCY_DISABLED)
	assert_float(shared.albedo_color.a).is_equal_approx(1.0, 0.001)
	assert_bool(wall_mesh.material_override != shared).is_true()

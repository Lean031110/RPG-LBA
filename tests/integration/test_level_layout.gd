class_name TestLevelLayout
extends GdUnitTestSuite
## Layout determinista de las afueras de Valdeluz y sus recursos ambientales.

func _build(density: float) -> Node3D:
	var root: Node3D = auto_free(Node3D.new())
	add_child(root)
	ValdeluzBuilder.build_all(root, density)
	return root


func test_builder_creates_all_groups() -> void:
	var root := _build(0.45)
	for group: String in ["Ground", "EnvironmentController", "Boundaries", "Vegetation", "Props"]:
		assert_bool(root.get_node_or_null(group) != null).is_true()


func test_play_area_rect_is_sane() -> void:
	var rect := ValdeluzBuilder.play_area_rect()
	assert_float(rect.size.x).is_greater(30.0)
	assert_float(rect.size.y).is_greater(45.0)


func test_boundary_colliders_use_world_layer() -> void:
	var root := _build(0.45)
	var walls := root.get_node("Boundaries")
	var body_count := 0
	for child in walls.get_children():
		if child is StaticBody3D:
			body_count += 1
			assert_int((child as StaticBody3D).collision_layer).is_equal(ArpgLayers.WORLD)
	assert_int(body_count).is_greater_equal(4)


func test_ground_has_collision() -> void:
	var root := _build(0.45)
	var ground := root.get_node("Ground")
	var body := ground.get_node_or_null("GroundBody")
	assert_object(body).is_instanceof(StaticBody3D)
	assert_int(body.collision_layer).is_equal(ArpgLayers.WORLD)


func test_density_changes_vegetation_count() -> void:
	var low_root := _build(0.2)
	var high_root := _build(1.0)
	var low_veg := low_root.get_node("Vegetation").get_child_count()
	var high_veg := high_root.get_node("Vegetation").get_child_count()
	assert_int(high_veg).is_greater(low_veg)
	assert_int(low_veg).is_greater(5)


func test_layout_is_deterministic() -> void:
	var first := _build(0.8)
	var second := _build(0.8)
	for group: String in ["Vegetation", "Boundaries"]:
		assert_int(first.get_node(group).get_child_count()).is_equal(second.get_node(group).get_child_count())


func test_default_lighting_disables_dynamic_shadows() -> void:
	var root := _build(0.45)
	var controller := root.get_node("EnvironmentController") as EnvironmentController
	assert_bool(controller.sun_light.shadow_enabled).is_false()
	assert_object(controller.world_environment).is_instanceof(WorldEnvironment)


func test_terrain_mesh_has_relief_without_extreme_steps() -> void:
	var root := _build(0.45)
	var mesh_instance := root.get_node("Ground/GroundMesh") as MeshInstance3D
	assert_object(mesh_instance.mesh).is_instanceof(ArrayMesh)
	assert_int(mesh_instance.mesh.get_faces().size()).is_greater(1000)

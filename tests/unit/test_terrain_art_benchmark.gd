class_name TestTerrainArtBenchmark
extends GdUnitTestSuite
## La escena aislada consume la paleta y el controlador regional existentes.


func test_scene_loads_and_reuses_valdeluz_materials() -> void:
	var packed := load("res://scenes/dev/art_benchmark/terrain_benchmark.tscn") as PackedScene
	assert_object(packed).is_not_null()
	if packed == null:
		return

	var benchmark := packed.instantiate() as TerrainArtBenchmark
	assert_object(benchmark).is_not_null()
	if benchmark == null:
		return
	auto_free(benchmark)
	add_child(benchmark)
	await get_tree().process_frame

	var expected_materials := {
		"Grass": "grass",
		"RedDirt": "red_dirt",
		"Limestone": "limestone",
		"Mud": "mud",
		"WetMud": "puddle_wet",
	}
	assert_int(benchmark.palette.size()).is_greater_equal(expected_materials.size())
	for sample_name: String in expected_materials:
		var sample := benchmark.get_node_or_null("MaterialSamples/%s" % sample_name)
		assert_object(sample).is_not_null()
		if sample == null:
			continue
		var surface := sample.get_node_or_null("Surface") as MeshInstance3D
		assert_object(surface).is_not_null()
		if surface == null:
			continue
		var material_key: String = expected_materials[sample_name]
		assert_bool(surface.material_override == benchmark.palette[material_key]).is_true()

	var backing_ground := benchmark.get_node_or_null("BackingGround") as MeshInstance3D
	assert_object(backing_ground).is_not_null()
	if backing_ground != null:
		assert_bool(backing_ground.material_override == benchmark.palette["grass"]).is_false()
	assert_bool(benchmark.environment_controller.active_environment.fog_enabled).is_false()
	assert_object(benchmark.get_node_or_null("EnvironmentController")).is_instanceof(EnvironmentController)
	assert_bool(benchmark.get_node_or_null("BenchmarkCamera") is Camera3D).is_true()
	assert_int(benchmark.get_node("MaterialSamples").get_child_count()).is_equal(expected_materials.size())

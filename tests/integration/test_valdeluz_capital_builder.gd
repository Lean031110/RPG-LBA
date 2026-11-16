class_name TestValdeluzCapitalBuilder
extends GdUnitTestSuite
## Regresión estructural del mapa capital, sin depender de capturas ni GPU.


func test_build_creates_required_city_zones() -> void:
	var root: Node3D = auto_free(Node3D.new())
	add_child(root)
	ValdeluzCapitalBuilder.build(root, 0.75)
	assert_object(root.get_node_or_null("CityGround")).is_not_null()
	assert_object(root.get_node_or_null("RoadNetwork")).is_not_null()
	assert_object(root.get_node_or_null("PlazaMayor")).is_not_null()
	assert_object(root.get_node_or_null("Districts")).is_not_null()
	assert_object(root.get_node_or_null("StreetFurniture")).is_not_null()
	assert_object(root.get_node_or_null("Greenery")).is_not_null()
	assert_object(root.get_node_or_null("CityEdgeAndEntrances")).is_not_null()


func test_city_contains_landmarks_and_modular_houses() -> void:
	var root: Node3D = auto_free(Node3D.new())
	add_child(root)
	ValdeluzCapitalBuilder.build(root, 0.5)
	var districts := root.get_node("Districts")
	assert_object(districts.get_node_or_null("CasaDeCabildo")).is_not_null()
	assert_object(districts.get_node_or_null("MercadoDelPuerto")).is_not_null()
	assert_object(districts.get_node_or_null("SantuarioDeLasCampanas")).is_not_null()
	assert_int(districts.get_child_count()).is_greater_equal(19)


func test_density_is_clamped_and_scene_remains_deterministic() -> void:
	var first: Node3D = auto_free(Node3D.new())
	var second: Node3D = auto_free(Node3D.new())
	add_child(first)
	add_child(second)
	ValdeluzCapitalBuilder.build(first, -10.0)
	ValdeluzCapitalBuilder.build(second, 10.0)
	assert_int(first.get_node("Districts").get_child_count()).is_equal(second.get_node("Districts").get_child_count())


func test_preview_scene_loads_and_builds_city() -> void:
	var packed_scene := load("res://scenes/arpg/valdeluz/valdeluz_capital_preview.tscn") as PackedScene
	assert_object(packed_scene).is_not_null()
	var preview := packed_scene.instantiate() as Node3D
	add_child(preview)
	assert_object(preview.get_node_or_null("PreviewCamera")).is_not_null()
	assert_object(preview.get_node_or_null("Districts")).is_not_null()
	assert_object(preview.get_node_or_null("EnvironmentController")).is_not_null()

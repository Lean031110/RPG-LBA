class_name TestProjectSettings
extends GdUnitTestSuite
## Contrato de configuración del proyecto (regresión): orientación horizontal
## obligatoria en Android, stretch landscape, renderer móvil y acciones de entrada.


func test_orientation_is_landscape_locked() -> void:
	# 4 = sensor_landscape: SOLO horizontal (gira entre las dos horizontales, nunca vertical).
	var orientation := int(ProjectSettings.get_setting("display/window/handheld/orientation"))
	assert_int(orientation).is_equal(4)


func test_stretch_is_canvas_items_expand() -> void:
	# canvas_items + expand: el HUD se re-coloca en 16:9 y 20:9 landscape (objetivo Fase 2/3).
	assert_str(String(ProjectSettings.get_setting("display/window/stretch/mode"))).is_equal("canvas_items")
	assert_str(String(ProjectSettings.get_setting("display/window/stretch/aspect"))).is_equal("expand")


func test_renderer_is_compatibility_everywhere() -> void:
	# ADR-002: Compatibility Renderer también en móvil (rendimiento en gama baja).
	assert_str(String(ProjectSettings.get_setting("rendering/renderer/rendering_method"))).is_equal("gl_compatibility")
	assert_str(String(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile"))).is_equal(
		"gl_compatibility"
	)


func test_main_scene_exists() -> void:
	var main_scene := String(ProjectSettings.get_setting("application/run/main_scene"))
	assert_bool(ResourceLoader.exists(main_scene)).is_true()


func test_arpg_input_actions_exist() -> void:
	for action: String in [
		"move_forward",
		"move_backward",
		"move_left",
		"move_right",
		"arpg_interact",
		"arpg_attack",
		"arpg_skill",
		"arpg_dodge",
		"arpg_potion",
		"arpg_pause",
		"arpg_inventory",
	]:
		assert_bool(InputMap.has_action(action)).is_true()


func test_physics_layers_named_for_masks() -> void:
	# Las capas son el contrato de las máscaras (ArpgLayers); renombrarlas en seco rompe todo.
	assert_str(String(ProjectSettings.get_setting("layer_names/3d_physics/layer_3"))).is_equal("arpg_player")
	assert_str(String(ProjectSettings.get_setting("layer_names/3d_physics/layer_4"))).is_equal("arpg_world")
	assert_str(String(ProjectSettings.get_setting("layer_names/3d_physics/layer_5"))).is_equal("arpg_enemy")
	assert_str(String(ProjectSettings.get_setting("layer_names/3d_physics/layer_6"))).is_equal("arpg_pickup")

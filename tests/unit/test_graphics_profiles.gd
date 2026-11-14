class_name TestGraphicsProfiles
extends GdUnitTestSuite
## Perfiles de calidad desde config/quality_profiles.json. Low es la referencia
## de diseño y el estado por defecto. Sin promesas de FPS sin medir en hardware.

var _original_profile := ""


func before_test() -> void:
	_original_profile = GraphicsSettings.active_profile


func after_test() -> void:
	GraphicsSettings.apply_profile(_original_profile)


func test_profiles_loaded_from_json() -> void:
	for profile_id: String in ["low", "medium", "high"]:
		assert_dict(GraphicsSettings.get_profile(profile_id)).is_not_empty()


func test_low_is_default_profile_id() -> void:
	assert_str(GraphicsSettings.DEFAULT_PROFILE).is_equal("low")


func test_apply_profile_updates_state() -> void:
	assert_bool(GraphicsSettings.apply_profile("medium")).is_true()
	assert_str(GraphicsSettings.active_profile).is_equal("medium")
	assert_bool(GraphicsSettings.apply_profile("high")).is_true()
	assert_str(GraphicsSettings.active_profile).is_equal("high")
	assert_bool(GraphicsSettings.apply_profile("bogus")).is_false()
	assert_str(GraphicsSettings.active_profile).is_equal("high")


func test_density_matches_json() -> void:
	GraphicsSettings.apply_profile("low")
	assert_float(GraphicsSettings.vegetation_density()).is_equal_approx(0.45, 0.001)
	GraphicsSettings.apply_profile("high")
	assert_float(GraphicsSettings.vegetation_density()).is_equal_approx(1.0, 0.001)


func test_particles_and_shadows_from_json() -> void:
	GraphicsSettings.apply_profile("low")
	assert_int(GraphicsSettings.max_visible_particles()).is_equal(40)
	assert_bool(GraphicsSettings.dynamic_shadows_enabled()).is_false()
	GraphicsSettings.apply_profile("high")
	assert_int(GraphicsSettings.max_visible_particles()).is_equal(140)


func test_serialize_roundtrip() -> void:
	GraphicsSettings.apply_profile("medium")
	var data := GraphicsSettings.serialize()
	assert_str(String(data["quality_profile"])).is_equal("medium")
	GraphicsSettings.restore({"quality_profile": "low"})
	assert_str(GraphicsSettings.active_profile).is_equal("low")


func test_render_scale_is_clamped() -> void:
	## El viewport nunca baja de 0.5 ni sube de 1.0 aunque el JSON cambie.
	GraphicsSettings.apply_profile("low")
	var viewport := GraphicsSettings.get_tree().root
	assert_float(viewport.scaling_3d_scale).is_greater_equal(0.5)
	assert_float(viewport.scaling_3d_scale).is_less_equal(1.0)
	GraphicsSettings.apply_profile("high")
	assert_float(GraphicsSettings.get_tree().root.scaling_3d_scale).is_equal_approx(1.0, 0.001)

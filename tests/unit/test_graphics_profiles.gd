class_name TestGraphicsProfiles
extends GdUnitTestSuite
## Perfiles de calidad (esquema v2), matriz de compatibilidad (docs/16) y
## resolucion dinamica. Low es la referencia de diseño. Sin promesas de FPS
## sin medir en hardware (AGENTS.md §7): target_fps es un tope.

var _original_profile := ""
var _original_dynamic := true


func before_test() -> void:
	_original_profile = GraphicsSettings.active_profile
	_original_dynamic = GraphicsSettings.dynamic_resolution


func after_test() -> void:
	GraphicsSettings.set_dynamic_resolution_enabled(_original_dynamic)
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


func test_particles_and_shadow_modes_from_json() -> void:
	GraphicsSettings.apply_profile("low")
	assert_int(GraphicsSettings.max_visible_particles()).is_equal(40)
	assert_str(GraphicsSettings.shadow_mode()).is_equal("player_only")
	assert_float(GraphicsSettings.shadow_max_distance()).is_equal_approx(14.0, 0.001)
	GraphicsSettings.apply_profile("medium")
	assert_str(GraphicsSettings.shadow_mode()).is_equal("one_directional")
	GraphicsSettings.apply_profile("high")
	assert_int(GraphicsSettings.max_visible_particles()).is_equal(140)
	assert_str(GraphicsSettings.shadow_mode()).is_equal("high_quality")


func test_enemy_caps_by_profile() -> void:
	## Matriz Redmi 9C: enemigos simultaneos limitados en LOW.
	GraphicsSettings.apply_profile("low")
	assert_int(GraphicsSettings.max_active_enemies()).is_equal(4)
	GraphicsSettings.apply_profile("medium")
	assert_int(GraphicsSettings.max_active_enemies()).is_equal(6)
	GraphicsSettings.apply_profile("high")
	assert_int(GraphicsSettings.max_active_enemies()).is_equal(8)


func test_target_fps_installs_engine_cap() -> void:
	GraphicsSettings.apply_profile("low")
	assert_int(GraphicsSettings.target_fps_cap()).is_equal(30)
	assert_int(Engine.max_fps).is_equal(30)
	GraphicsSettings.apply_profile("high")
	assert_int(GraphicsSettings.target_fps_cap()).is_equal(60)
	assert_int(Engine.max_fps).is_equal(60)


func test_serialize_roundtrip() -> void:
	GraphicsSettings.apply_profile("medium")
	var data := GraphicsSettings.serialize()
	assert_str(String(data["quality_profile"])).is_equal("medium")
	assert_bool(bool(data["dynamic_resolution"])).is_true()
	GraphicsSettings.restore({"quality_profile": "low", "dynamic_resolution": false})
	assert_str(GraphicsSettings.active_profile).is_equal("low")
	assert_bool(GraphicsSettings.dynamic_resolution).is_false()


func test_render_scale_is_clamped() -> void:
	## El viewport nunca baja de 0.5 ni sube de 1.0 aunque el JSON cambie.
	GraphicsSettings.apply_profile("low")
	var viewport := GraphicsSettings.get_tree().root
	assert_float(viewport.scaling_3d_scale).is_greater_equal(0.5)
	assert_float(viewport.scaling_3d_scale).is_less_equal(1.0)
	GraphicsSettings.apply_profile("high")
	assert_float(GraphicsSettings.get_tree().root.scaling_3d_scale).is_equal_approx(1.0, 0.001)


# ---------------------------------------------------------------------------
# Matriz de compatibilidad (docs/16): funcion pura, sin hardware.
# ---------------------------------------------------------------------------


func test_matrix_redmi_9c_variants_suggest_low() -> void:
	## Redmi 9C: Helio G35 (PowerVR GE8320), 720x1600. Variantes 2/3/4 GB:
	## la GPU de gama baja domina aunque la variante traiga mas RAM.
	for ram_gb: float in [2.0, 3.0, 3.6]:
		var hw := _fake_hw(ram_gb, "PowerVR Rogue GE8320", 1600)
		assert_str(GraphicsSettings.suggest_profile_for(hw)).is_equal("low").override_failure_message(
			"Redmi 9C (%.1f GB) deberia ser LOW" % ram_gb
		)


func test_matrix_s22_ultra_suggests_high() -> void:
	## S22 Ultra: Adreno 730 (Snapdragon) o Xclipse 920 (Exynos), 8-12 GB, 1440p+.
	for gpu: String in ["Adreno (TM) 730", "Xclipse 920"]:
		var hw := _fake_hw(7.2, gpu, 3080)
		assert_str(GraphicsSettings.suggest_profile_for(hw)).is_equal("high").override_failure_message(
			"S22 Ultra (%s) deberia ser HIGH" % gpu
		)


func test_matrix_mid_arm64_suggests_medium() -> void:
	var hw := _fake_hw(3.6, "Adreno (TM) 612", 2340)
	assert_str(GraphicsSettings.suggest_profile_for(hw)).is_equal("medium")
	var hw2 := _fake_hw(7.2, "Adreno (TM) 640", 2400)
	assert_str(GraphicsSettings.suggest_profile_for(hw2)).is_equal("medium")


func test_matrix_desktop_stays_low() -> void:
	var hw := _fake_hw(32.0, "NVIDIA GeForce RTX 4090", 3840)
	hw["platform"] = "Linux"
	assert_str(GraphicsSettings.suggest_profile_for(hw)).is_equal("low")


func test_matrix_emulator_software_gpu_suggests_low() -> void:
	var hw := _fake_hw(16.0, "SwiftShader", 1920)
	hw["platform"] = "Android"
	assert_str(GraphicsSettings.suggest_profile_for(hw)).is_equal("low")


func _fake_hw(ram_gb: float, gpu: String, long_px: int) -> Dictionary:
	return {
		"platform": "Android",
		"model": "fake",
		"ram_total_gb": ram_gb,
		"gpu": gpu,
		"screen_long_px": long_px,
		"api_level": 35,
		"abis": ["arm64-v8a"],
	}


# ---------------------------------------------------------------------------
# Resolucion dinamica: histeresis pura (AdaptiveController).
# ---------------------------------------------------------------------------


func _controller(target_fps: int) -> ArpgAdaptiveController:
	var c := ArpgAdaptiveController.new()
	c.configure({"min": 0.5, "max": 0.75, "step": 0.05, "down_after_s": 2.0, "up_after_s": 6.0}, target_fps, 0.7, true)
	return c


func test_adaptive_holds_on_stable_frames() -> void:
	var c := _controller(30)
	# 30 FPS => 33.3 ms; zona estable entre 23.3 y 43.3 ms.
	for i: int in 20:
		assert_str(c.note_frame(30.0, 0.5)).is_equal("hold")
	assert_float(c.current).is_equal_approx(0.7, 0.001)


func test_adaptive_downshifts_after_sustained_slowness() -> void:
	var c := _controller(30)
	for i: int in 3:
		c.note_frame(60.0, 0.5)  # 60 ms >> 130% de 33.3 ms: lento sostenido.
		# La cuarta nota acumula 2.0 s de lentitud y dispara la bajada.

		# La histeresis no deja encadenar bajadas sin acumular de nuevo.
	assert_str(c.note_frame(60.0, 0.5)).is_equal("down")
	assert_float(c.current).is_equal_approx(0.65, 0.001)
	# La histeresis no deja encadenar bajadas sin acumular de nuevo.
	assert_str(c.note_frame(60.0, 0.5)).is_equal("hold")


func test_adaptive_upshifts_after_sustained_headroom() -> void:
	var c := _controller(30)
	c.current = 0.55
	for i: int in 12:
		var action := c.note_frame(15.0, 0.5)  # 15 ms << 70% de 33.3 ms: sobra.
		if action == "up":
			break
	assert_float(c.current).is_equal_approx(0.6, 0.001)


func test_adaptive_disabled_stays_silent() -> void:
	var c := _controller(30)
	c.set_enabled(false)
	for i: int in 10:
		assert_str(c.note_frame(90.0, 0.5)).is_equal("hold")
	assert_float(c.current).is_equal_approx(0.7, 0.001)

class_name TestEnvironmentController
extends GdUnitTestSuite
## Integración del reloj, cielo, clima y luces locales en el bosque.

func _build_controller() -> EnvironmentController:
	var root: Node3D = auto_free(Node3D.new())
	add_child(root)
	var controller := EnvironmentController.new()
	controller.auto_advance = false
	controller.start_time_hours = 12.0
	root.add_child(controller)
	return controller


func test_controller_creates_sky_and_low_cost_sun() -> void:
	var controller := _build_controller()
	assert_object(controller.world_environment).is_instanceof(WorldEnvironment)
	assert_object(controller.active_environment.sky).is_instanceof(Sky)
	assert_object(controller.sun_light).is_instanceof(DirectionalLight3D)
	assert_bool(controller.sun_light.shadow_enabled).is_false()


func test_time_api_updates_period_without_scene_dependency() -> void:
	var controller := _build_controller()
	controller.set_world_time_hours(5.75)
	assert_int(controller.get_day_period()).is_equal(DayNightCycle.Period.DAWN)
	assert_str(controller.get_day_period_name()).is_equal("Amanecer")
	controller.set_world_time_hours(22.0)
	assert_int(controller.get_day_period()).is_equal(DayNightCycle.Period.NIGHT)
	assert_str(controller.get_clock_label()).is_equal("22:00")


func test_weather_can_be_changed_and_toggled() -> void:
	var controller := _build_controller()
	assert_bool(controller.set_weather_by_name("lluvia", true)).is_true()
	assert_str(controller.get_weather_name()).is_equal("Lluvia")
	assert_float(controller.get_weather_weight(WeatherController.Weather.RAIN)).is_equal_approx(1.0, 0.001)
	assert_bool(controller.set_weather_by_name("tormenta")).is_false()


func test_farol_only_uses_a_single_non_shadowed_local_light() -> void:
	var controller := _build_controller()
	var lantern := OmniLight3D.new()
	lantern.light_energy = 0.9
	controller.add_child(lantern)
	controller.register_night_light(lantern)
	controller.set_world_time_hours(12.0)
	assert_bool(lantern.visible).is_false()
	controller.set_world_time_hours(22.0)
	assert_bool(lantern.visible).is_true()
	assert_bool(lantern.shadow_enabled).is_false()

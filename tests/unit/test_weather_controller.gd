class_name TestWeatherController
extends GdUnitTestSuite
## La mezcla climática siempre conserva pesos normalizados y transiciones suaves.


func test_instant_weather_change() -> void:
	var weather := WeatherController.new()
	assert_bool(weather.set_weather(WeatherController.Weather.RAIN, true)).is_true()
	assert_float(weather.get_weight(WeatherController.Weather.RAIN)).is_equal_approx(1.0, 0.001)
	assert_str(weather.get_weather_name()).is_equal("Lluvia")


func test_weather_transition_is_gradual_and_normalized() -> void:
	var weather := WeatherController.new()
	weather.transition_seconds = 10.0
	assert_bool(weather.set_weather(WeatherController.Weather.FOG)).is_true()
	weather.advance(2.5)
	assert_float(weather.get_weight(WeatherController.Weather.FOG)).is_greater(0.0)
	assert_float(weather.get_weight(WeatherController.Weather.FOG)).is_less(1.0)
	var total := 0.0
	for weight in weather.get_weights():
		total += weight
	assert_float(total).is_equal_approx(1.0, 0.001)


func test_invalid_weather_is_rejected() -> void:
	var weather := WeatherController.new()
	assert_bool(weather.set_weather(99)).is_false()
	assert_float(weather.get_weight(WeatherController.Weather.CLEAR)).is_equal_approx(1.0, 0.001)


func test_retargeting_during_transition_stays_stable() -> void:
	var weather := WeatherController.new()
	weather.transition_seconds = 8.0
	weather.set_weather(WeatherController.Weather.OVERCAST)
	weather.advance(2.0)
	weather.set_weather(WeatherController.Weather.RAIN)
	weather.advance(3.0)
	var total := 0.0
	for weight in weather.get_weights():
		total += weight
	assert_float(total).is_equal_approx(1.0, 0.001)
	assert_bool(weather.is_transitioning()).is_true()

class_name TestDayNightCycle
extends GdUnitTestSuite
## Pruebas del reloj independiente del árbol de escenas.

func test_periods_cover_all_six_day_parts() -> void:
	var clock := DayNightCycle.new()
	clock.set_time_hours(6.0)
	assert_int(clock.get_period()).is_equal(DayNightCycle.Period.DAWN)
	clock.set_time_hours(8.0)
	assert_int(clock.get_period()).is_equal(DayNightCycle.Period.MORNING)
	clock.set_time_hours(13.0)
	assert_int(clock.get_period()).is_equal(DayNightCycle.Period.MIDDAY)
	clock.set_time_hours(17.0)
	assert_int(clock.get_period()).is_equal(DayNightCycle.Period.DUSK)
	clock.set_time_hours(18.5)
	assert_int(clock.get_period()).is_equal(DayNightCycle.Period.EVENING)
	clock.set_time_hours(22.0)
	assert_int(clock.get_period()).is_equal(DayNightCycle.Period.NIGHT)


func test_clock_wraps_at_midnight() -> void:
	var clock := DayNightCycle.new(23.5)
	clock.advance(60.0)
	assert_float(clock.time_hours).is_equal_approx(0.5, 0.001)
	assert_str(clock.get_period_name()).is_equal("Noche")


func test_day_length_controls_time_speed() -> void:
	var clock := DayNightCycle.new(6.0)
	clock.configure(1440.0, 6.0)
	clock.advance(60.0)
	assert_float(clock.time_hours).is_equal_approx(7.0, 0.001)
	assert_str(clock.get_time_label()).is_equal("07:00")


func test_negative_and_zero_delta_do_not_rewind_time() -> void:
	var clock := DayNightCycle.new(12.0)
	clock.advance(0.0)
	clock.advance(-10.0)
	assert_float(clock.time_hours).is_equal_approx(12.0, 0.001)

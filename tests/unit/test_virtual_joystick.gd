class_name TestVirtualJoystick
extends GdUnitTestSuite
## Fase 2: lógica pura del joystick (sin hardware). Factor de normalización idéntico
## al HUD de la Fase 1 (radius - knob*0.5), zona muerta, recorte del recorrido y signos.
## El comportamiento multitáctil real (dedo, liberación fuera del área) requiere
## hardware/emulación de eventos: NO PROBADO aquí, cubierto por diseño en _input.


func test_center_is_zero() -> void:
	var value := ArpgVirtualJoystick.value_from_offset(Vector2.ZERO, 92.0, 38.0, 0.12)
	assert_vector(value).is_equal(Vector2.ZERO)


func test_full_right_is_one() -> void:
	var value := ArpgVirtualJoystick.value_from_offset(Vector2(200, 0), 92.0, 38.0, 0.12)
	assert_float(value.x).is_greater(0.99)
	assert_float(value.x).is_less_equal(1.0)
	assert_float(absf(value.y)).is_less(0.01)


func test_beyond_radius_is_clamped_with_signs() -> void:
	var value := ArpgVirtualJoystick.value_from_offset(Vector2(-500, 400), 92.0, 38.0, 0.12)
	assert_float(value.length()).is_less_equal(1.0)
	assert_float(value.x).is_less(0.0)
	assert_float(value.y).is_greater(0.0)


func test_dead_zone_blocks_tiny_offsets() -> void:
	# 8 px con radio 92: 8/73 ≈ 0.11 < zona muerta 0.12 -> cero (sin deriva).
	var blocked := ArpgVirtualJoystick.value_from_offset(Vector2(8, 0), 92.0, 38.0, 0.12)
	assert_vector(blocked).is_equal(Vector2.ZERO)
	# 12 px ≈ 0.16 > zona muerta: pasa.
	var allowed := ArpgVirtualJoystick.value_from_offset(Vector2(12, 0), 92.0, 38.0, 0.12)
	assert_float(allowed.x).is_greater(0.12)


func test_offset_matches_fase1_factor() -> void:
	# Mismo factor de la Fase 1: offset (40,0) con radius 92/knob 38 ≈ 0.548.
	var value := ArpgVirtualJoystick.value_from_offset(Vector2(40, 0), 92.0, 38.0, 0.12)
	assert_float(value.x).is_greater(0.35)
	assert_float(value.x).is_less_equal(1.0)


func test_control_applies_and_emits() -> void:
	var joy: ArpgVirtualJoystick = auto_free(ArpgVirtualJoystick.new())
	add_child(joy)
	var received: Array = []
	joy.value_changed.connect(func(value: Vector2) -> void: received.append(value))
	joy.set_value_from_offset(Vector2(60, 0))
	assert_int(received.size()).is_equal(1)
	assert_float(joy.get_value().x).is_greater(0.7)
	joy.set_value_from_offset(Vector2(3, 0))
	assert_float(joy.get_value().length()).is_equal_approx(0.0, 0.001)
	assert_int(received.size()).is_equal(2)

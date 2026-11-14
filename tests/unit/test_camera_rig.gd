class_name TestCameraRig
extends GdUnitTestSuite
## Fase 2: parámetros configurables de la cámara isométrica, seguimiento suave
## y regla de oro del ARPG: la cámara NUNCA rota por los controles de movimiento.


func _make_target() -> Node3D:
	var target: Node3D = auto_free(Node3D.new())
	add_child(target)
	return target


func _make_rig(target: Node3D) -> IsoCameraRig:
	var rig: IsoCameraRig = auto_free(IsoCameraRig.new())
	add_child(rig)
	rig.setup(target)
	return rig


func _frames(count: int) -> void:
	for index: int in count:
		await get_tree().physics_frame


func test_defaults_match_fase1() -> void:
	var rig := _make_rig(_make_target())
	assert_float(rig.pitch_degrees).is_equal_approx(55.0, 0.01)
	assert_vector(rig.follow_offset).is_equal(Vector3(0, 14.5, 10))
	assert_float(rig.follow_smoothing).is_equal_approx(6.5, 0.01)
	assert_float(rig.zoom_min).is_equal_approx(5.5, 0.01)
	assert_float(rig.zoom_max).is_equal_approx(10.0, 0.01)
	assert_float(rig.ortho_size).is_equal_approx(7.5, 0.01)
	assert_bool(rig.get_camera().projection == Camera3D.PROJECTION_ORTHOGONAL).is_true()
	assert_float(rig.get_camera().size).is_equal_approx(7.5, 0.01)


func test_zoom_clamps_to_bounds() -> void:
	var rig := _make_rig(_make_target())
	rig.set_zoom(2.0)
	assert_float(rig.ortho_size).is_equal_approx(5.5, 0.01)
	rig.set_zoom(50.0)
	assert_float(rig.ortho_size).is_equal_approx(10.0, 0.01)
	rig.set_zoom(8.0)
	assert_float(rig.ortho_size).is_equal_approx(8.0, 0.01)


func test_follow_converges_smoothly() -> void:
	var target := _make_target()
	var rig := _make_rig(target)
	target.global_position = Vector3(10, 0, 4)
	await _frames(30)
	var desired := target.global_position + rig.follow_offset
	var distance := rig.global_position.distance_to(desired)
	# Converge (lerp 6.5) pero no teletransporta: suavizado real.
	assert_float(distance).is_less(1.0)
	assert_float(distance).is_greater(0.0)


func test_movement_input_does_not_rotate_camera() -> void:
	var target := _make_target()
	var rig := _make_rig(target)
	Input.action_press("move_forward")
	Input.action_press("move_right")
	await _frames(20)
	Input.action_release("move_forward")
	Input.action_release("move_right")
	assert_float(rig.rotation_degrees.y).is_equal_approx(0.0, 0.01)
	assert_float(rig.rotation_degrees.x).is_equal_approx(-55.0, 0.01)
	assert_float(rig.rotation_degrees.z).is_equal_approx(0.0, 0.01)


func test_configuration_changes_apply() -> void:
	var target := _make_target()
	var rig := _make_rig(target)
	rig.pitch_degrees = 60.0
	rig.follow_offset = Vector3(0, 16, 8)
	rig.ortho_size = 9.0
	rig.setup(target)
	assert_float(rig.rotation_degrees.x).is_equal_approx(-60.0, 0.01)
	assert_vector(rig.global_position - target.global_position).is_equal(Vector3(0, 16, 8))
	assert_float(rig.get_camera().size).is_equal_approx(9.0, 0.01)

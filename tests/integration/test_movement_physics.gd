class_name TestMovementPhysics
extends GdUnitTestSuite
## Fase 2: física del movimiento con aceleración/desaceleración, gravedad con
## aterrizaje, marco de referencia de la cámara y las ocho direcciones de teclado.


func _make_player() -> ArpgPlayer:
	var player: ArpgPlayer = auto_free(ArpgPlayer.new())
	add_child(player)
	player.setup("machetero")
	player.global_position = Vector3(0, 0.5, 0)
	return player


func _frames(count: int) -> void:
	for index: int in count:
		await get_tree().physics_frame


func _planar_speed(player: ArpgPlayer) -> float:
	## Velocidad en el plano XZ: la caída libre no contamina las pruebas de movimiento.
	return Vector2(player.velocity.x, player.velocity.z).length()


func _add_floor() -> void:
	## Suelo temporal en capa WORLD para las pruebas que necesitan apoyo real.
	var body := StaticBody3D.new()
	body.collision_layer = ArpgLayers.WORLD
	auto_free(body)
	add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 0.4, 60)
	shape.shape = box
	body.add_child(shape)
	body.position = Vector3(0, -0.2, 0)


func test_acceleration_ramps_up() -> void:
	_add_floor()
	var player := _make_player()
	player.global_position = Vector3(0, 1.0, 0)
	player.joystick_vector = Vector2(0, 1)
	await _frames(5)
	# 0.083 s: en plena rampa de aceleración (24 m/s²): aún lejos del tope 4.2.
	assert_float(_planar_speed(player)).is_greater(1.0)
	assert_float(_planar_speed(player)).is_less(3.4)
	await _frames(26)
	assert_float(_planar_speed(player)).is_greater(3.8)
	assert_float(_planar_speed(player)).is_less(4.6)


func test_deceleration_stops_smoothly() -> void:
	_add_floor()
	var player := _make_player()
	player.global_position = Vector3(0, 1.0, 0)
	player.joystick_vector = Vector2(0, 1)
	await _frames(26)
	var speed_before := _planar_speed(player)
	player.joystick_vector = Vector2.ZERO
	await _frames(3)
	# 0.05 s tras soltar: aún se desliza, pero ya perdió velocidad.
	assert_float(_planar_speed(player)).is_greater(0.4)
	assert_float(_planar_speed(player)).is_less(speed_before)
	await _frames(25)
	# 4.2 / 30 = 0.14 s para frenar del todo.
	assert_float(_planar_speed(player)).is_less(0.05)


func test_gravity_falls_and_lands() -> void:
	_add_floor()
	var player := _make_player()
	player.global_position = Vector3(0, 3.0, 0)
	# Caída de ~3.05 m a 18 m/s²: ~0.58 s ≈ 35 fotogramas; 60 da margen.
	await _frames(60)
	assert_bool(player.is_on_floor()).is_true()
	assert_float(player.velocity.y).is_equal_approx(0.0, 0.01)


func test_movement_frame_follows_camera_yaw() -> void:
	var player := _make_player()
	# Sin cámara asignada: identidad (eje mundial), igual que la Fase 1.
	player.joystick_vector = Vector2(1, 0)
	await _frames(26)
	assert_float(player.velocity.x).is_greater(3.8)
	# Cámara con yaw 90°: "derecha en pantalla" pasa a ser -Z del mundo.
	var camera: Node3D = auto_free(Node3D.new())
	add_child(camera)
	camera.rotation_degrees = Vector3(-55.0, 90.0, 0.0)
	player.camera_source = camera
	player.velocity = Vector3.ZERO
	player.joystick_vector = Vector2(1, 0)
	await _frames(26)
	assert_float(player.velocity.z).is_less(-3.8)
	assert_float(absf(player.velocity.x)).is_less(0.5)


func test_eight_keyboard_directions() -> void:
	_add_floor()
	var player := _make_player()
	player.global_position = Vector3(0, 1.0, 0)
	var cases := [
		[["move_forward"], Vector3(0, 0, -1)],
		[["move_backward"], Vector3(0, 0, 1)],
		[["move_left"], Vector3(-1, 0, 0)],
		[["move_right"], Vector3(1, 0, 0)],
		[["move_forward", "move_right"], Vector3(1, 0, -1).normalized()],
		[["move_forward", "move_left"], Vector3(-1, 0, -1).normalized()],
		[["move_backward", "move_right"], Vector3(1, 0, 1).normalized()],
		[["move_backward", "move_left"], Vector3(-1, 0, 1).normalized()],
	]
	for case: Array in cases:
		var actions: Array = case[0]
		var expected: Vector3 = case[1]
		for action: String in actions:
			Input.action_press(action)
		await _frames(26)
		var velocity := player.velocity
		assert_float(velocity.length()).is_greater(3.8)
		assert_float(velocity.length()).is_less(4.6)
		var deviation := velocity.normalized().dot(expected)
		assert_float(deviation).is_greater(0.97)
		for action_to_release: String in actions:
			Input.action_release(action_to_release)
		await _frames(30)
		assert_float(player.velocity.length()).is_less(0.05)

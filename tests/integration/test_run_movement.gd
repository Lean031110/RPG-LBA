class_name TestRunMovement
extends GdUnitTestSuite
## Tiers de locomoción Fase 3: caminar (deflexión baja del joystick) vs correr
## (deflexión alta o teclado, x1.55 por dato de clase). La aceleración de la Fase 2
## sigue persiguiendo la velocidad objetivo del tier.

const WALK_SPEED := 4.2
const RUN_SPEED := 4.2 * 1.55


func _frames(count: int) -> void:
	for index: int in count:
		await get_tree().physics_frame


func _make_player() -> ArpgPlayer:
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = ArpgLayers.WORLD
	floor_body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(160, 1, 160)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0, -0.55, 0)
	add_child(auto_free(floor_body))
	var player: ArpgPlayer = auto_free(ArpgPlayer.new())
	add_child(player)
	player.setup("machetero")
	player.global_position = Vector3(0, 0.5, 0)
	return player


func _planar_speed(player: ArpgPlayer) -> float:
	return Vector3(player.velocity.x, 0, player.velocity.z).length()


func test_low_deflection_walks() -> void:
	var player := _make_player()
	player.joystick_vector = Vector2(0.45, 0)
	await _frames(40)
	assert_str(player.move_tier).is_equal("walk")
	# Caminar analógico: magnitud x velocidad de clase (4.2 x 0.45 ~ 1.89).
	assert_float(_planar_speed(player)).is_between(1.5, 2.3)
	player.joystick_vector = Vector2.ZERO
	await _frames(40)
	assert_str(player.move_tier).is_equal("idle")


func test_full_deflection_runs() -> void:
	var player := _make_player()
	player.joystick_vector = Vector2(1, 0)
	await _frames(45)
	assert_str(player.move_tier).is_equal("run")
	assert_float(_planar_speed(player)).is_between(RUN_SPEED - 0.4, RUN_SPEED + 0.4)


func test_walk_is_slower_than_run() -> void:
	var player := _make_player()
	player.joystick_vector = Vector2(0.45, 0)
	await _frames(45)
	var walk_speed := _planar_speed(player)
	player.joystick_vector = Vector2(1, 0)
	await _frames(45)
	var run_speed := _planar_speed(player)
	assert_float(run_speed).is_greater(walk_speed * 1.8)


func test_keyboard_runs_by_default() -> void:
	# Estándar ARPG: el teclado entrega magnitud completa -> corre (decisión documentada).
	var player := _make_player()
	Input.action_press("move_right")
	await _frames(45)
	Input.action_release("move_right")
	assert_str(player.move_tier).is_equal("run")
	assert_float(_planar_speed(player)).is_between(RUN_SPEED - 0.4, RUN_SPEED + 0.4)


func test_run_multiplier_comes_from_class_data() -> void:
	# Dato por clase (los datos mandan sobre el default): machetero trae 1.55.
	var player := _make_player()
	assert_float(float(player.class_data.get("run_multiplier", 0.0))).is_equal_approx(1.55, 0.001)


func test_run_blend_grows_while_running() -> void:
	# El fundido visual caminar<->correr sube hacia 1 en carrera y baja al parar.
	var player := _make_player()
	player.joystick_vector = Vector2(1, 0)
	await _frames(45)
	assert_float(player._run_blend).is_greater(0.9)
	player.joystick_vector = Vector2.ZERO
	await _frames(60)
	assert_float(player._run_blend).is_less(0.1)

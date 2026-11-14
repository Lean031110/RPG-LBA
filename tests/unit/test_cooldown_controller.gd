class_name TestCooldownController
extends GdUnitTestSuite
## CooldownController (Fase 5): recargas por identificador con señales para el
## HUD (radiales), reducción externa y limpieza. Sustituye a los tres
## temporizadores sueltos del jugador de la Fase 1-4.


func test_start_and_ready() -> void:
	var cooldowns := CooldownController.new()
	assert_bool(cooldowns.is_ready("attack")).is_true()
	cooldowns.start("attack", 1.0)
	assert_bool(cooldowns.is_ready("attack")).is_false()
	assert_float(cooldowns.left("attack")).is_equal(1.0)
	assert_float(cooldowns.total("attack")).is_equal(1.0)


func test_tick_expires_and_signals() -> void:
	var cooldowns := CooldownController.new()
	var ended: Array = []
	cooldowns.cooldown_ended.connect(func(id: String) -> void: ended.append(id))
	cooldowns.start("dodge", 0.3)
	cooldowns.tick(0.35)
	assert_bool(cooldowns.is_ready("dodge")).is_true()
	assert_int(ended.size()).is_equal(1)
	assert_str(String(ended[0])).is_equal("dodge")


func test_progress_ratio_for_hud() -> void:
	var cooldowns := CooldownController.new()
	cooldowns.start("skill", 2.0)
	assert_float(cooldowns.progress_ratio("skill")).is_equal_approx(0.0, 0.001)
	cooldowns.tick(1.0)
	assert_float(cooldowns.progress_ratio("skill")).is_equal_approx(0.5, 0.001)
	cooldowns.tick(1.0)
	assert_float(cooldowns.progress_ratio("skill")).is_equal(1.0)


func test_reduce_shortens_cooldown() -> void:
	var cooldowns := CooldownController.new()
	cooldowns.start("skill", 4.0)
	cooldowns.reduce("skill", 3.9)
	assert_float(cooldowns.left("skill")).is_equal_approx(0.1, 0.001)
	## Reducir de más expira con señal.
	var ended: Array = []
	cooldowns.cooldown_ended.connect(func(id: String) -> void: ended.append(id))
	cooldowns.reduce("skill", 1.0)
	assert_bool(cooldowns.is_ready("skill")).is_true()
	assert_int(ended.size()).is_equal(1)


func test_independent_ids() -> void:
	var cooldowns := CooldownController.new()
	cooldowns.start("skill", 1.0)
	cooldowns.start("dodge", 1.0)
	cooldowns.tick(0.5)
	assert_float(cooldowns.left("skill")).is_equal(0.5)
	assert_float(cooldowns.left("dodge")).is_equal(0.5)
	cooldowns.clear_one("dodge")
	assert_bool(cooldowns.is_ready("dodge")).is_true()
	assert_bool(cooldowns.is_ready("skill")).is_false()


func test_zero_duration_is_ignored() -> void:
	var cooldowns := CooldownController.new()
	cooldowns.start("attack", 0.0)
	assert_bool(cooldowns.is_ready("attack")).is_true()

class_name TestStatusEffects
extends GdUnitTestSuite
## StatusEffectController (Fase 5): aplicación, refresco sin apilar, expiración,
## consultas derivadas (aturdimiento, ralentización, armadura) y sangrado periódico.


func _controller() -> StatusEffectController:
	return StatusEffectController.new()


func test_apply_and_expire() -> void:
	var statuses := _controller()
	statuses.apply("stun", 0.2)
	assert_bool(statuses.has("stun")).is_true()
	assert_bool(statuses.can_act()).is_false()
	statuses.tick(0.25)
	assert_bool(statuses.has("stun")).is_false()
	assert_bool(statuses.can_act()).is_true()


func test_same_id_refreshes_not_stacks() -> void:
	var statuses := _controller()
	statuses.apply("slow", 1.0, {"slow_fraction": 0.3})
	statuses.apply("slow", 2.0, {"slow_fraction": 0.5})
	assert_int(statuses.active_ids().size()).is_equal(1)
	## El parámetro más fuerte gana; la duración la mayor.
	assert_float(float(statuses.get_param("slow", "slow_fraction", 0.0))).is_equal(0.5)
	assert_float(statuses.time_left("slow")).is_equal(2.0)


func test_different_ids_coexist() -> void:
	var statuses := _controller()
	statuses.apply("stun", 1.0)
	statuses.apply("slow", 1.0, {"slow_fraction": 0.3})
	statuses.apply("vulnerable", 1.0, {"multiplier": 1.3})
	assert_int(statuses.active_ids().size()).is_equal(3)


func test_move_speed_multiplier() -> void:
	var statuses := _controller()
	assert_float(statuses.move_speed_multiplier()).is_equal(1.0)
	statuses.apply("resin", 2.0, {"slow_fraction": 0.45})
	assert_float(statuses.move_speed_multiplier()).is_equal_approx(0.55, 0.001)
	statuses.apply("haste", 2.0, {"multiplier": 1.3})
	assert_float(statuses.move_speed_multiplier()).is_equal_approx(0.715, 0.001)


func test_armor_break_multiplier() -> void:
	var statuses := _controller()
	assert_float(statuses.armor_multiplier()).is_equal(1.0)
	statuses.apply("armor_break", 3.0, {"reduction": 0.5})
	assert_float(statuses.armor_multiplier()).is_equal(0.5)


func test_bleed_ticks_periodically() -> void:
	var statuses := _controller()
	var ticks: Array = []
	statuses.periodic_tick.connect(func(id: String, payload: Dictionary) -> void: ticks.append([id, payload]))
	statuses.apply("bleed", 3.0, {"damage_per_tick": 4.0, "interval": 1.0})
	## 2.05 s de sangrado con intervalo de 1 s: al menos 2 ticks completos.
	for frame: int in 130:
		statuses.tick(0.016)
	assert_int(ticks.size()).is_greater_equal(2)
	assert_str(String(ticks[0][0])).is_equal("bleed")
	assert_float(float(ticks[0][1]["damage_per_tick"])).is_equal(4.0)


func test_consume_removes_single_use() -> void:
	var statuses := _controller()
	statuses.apply("empowered", 10.0, {"multiplier": 1.5})
	statuses.consume("empowered")
	assert_bool(statuses.has("empowered")).is_false()


func test_signals_fire_on_add_and_remove() -> void:
	var statuses := _controller()
	var events: Array = []
	statuses.status_added.connect(func(id: String, _duration: float) -> void: events.append("+" + id))
	statuses.status_removed.connect(func(id: String) -> void: events.append("-" + id))
	statuses.apply("stun", 0.1)
	statuses.tick(0.15)
	assert_int(events.size()).is_equal(2)
	assert_str(String(events[0])).is_equal("+stun")
	assert_str(String(events[1])).is_equal("-stun")

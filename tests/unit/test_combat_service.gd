class_name TestCombatService
extends GdUnitTestSuite
## Servicio único de daño (AGENTS.md §6). Los valores son hipótesis de diseño
## documentadas; esta prueba fija el comportamiento del servicio, no el balance final.


func test_attribute_modifier() -> void:
	assert_float(CombatService.attribute_modifier(10)).is_equal_approx(1.0, 0.0001)
	assert_float(CombatService.attribute_modifier(18)).is_equal_approx(1.4, 0.0001)
	assert_float(CombatService.attribute_modifier(7)).is_equal_approx(0.85, 0.0001)


func test_physical_damage_formula() -> void:
	## potencia 8 x coeff 1.0 x mod 1.4 (fuerza 18) x armor_factor(2).
	var damage := CombatService.physical_damage(8.0, 1.0, 18.0, 2.0)
	var expected := 8.0 * 1.0 * 1.4 * (1.0 - 2.0 / 102.0)
	assert_float(damage).is_equal_approx(expected, 0.001)


func test_arcane_damage_formula() -> void:
	var damage := CombatService.arcane_damage(9.0, 1.8, 20.0, 1.0)
	# attribute_modifier(20) = 1.5 (no 2.0); resistencia 1 -> factor 100/101.
	var expected := 9.0 * 1.8 * 1.5 * (100.0 / 101.0)
	assert_float(damage).is_equal_approx(expected, 0.001)


func test_damage_from_data_dispatch() -> void:
	var physical_skill := {"potency": 8.0, "damage_coeff": 1.0, "damage_type": "physical"}
	var arcane_skill := {"potency": 9.0, "damage_coeff": 1.0, "damage_type": "arcane"}
	assert_float(CombatService.damage_from_data(physical_skill, 18.0, 2.0)).is_equal_approx(
		CombatService.physical_damage(8.0, 1.0, 18.0, 2.0), 0.001
	)
	assert_float(CombatService.damage_from_data(arcane_skill, 20.0, 1.0)).is_equal_approx(
		CombatService.arcane_damage(9.0, 1.0, 20.0, 1.0), 0.001
	)


func test_mitigation_caps() -> void:
	## Tope global de mitigación 0.75: la armadura extrema no anula el daño.
	assert_float(CombatService.armor_factor(100000.0)).is_equal_approx(0.25, 0.0001)
	assert_float(CombatService.resistance_factor(100000.0)).is_equal_approx(0.25, 0.0001)
	assert_float(CombatService.armor_factor(0.0)).is_equal_approx(1.0, 0.0001)


func test_crit_chance_cap() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var crits := 0
	for index: int in 1000:
		var roll := CombatService.crit_roll(10.0, 0.9, rng)
		# 0.9 se recorta al tope 0.5 -> ~500 criticos de 1000.
		if bool(roll["crit"]):
			crits += 1
		assert_float(float(roll["damage"])).is_greater(0.0)
	assert_int(crits).is_greater(400)
	assert_int(crits).is_less(600)


func test_telegraph_window() -> void:
	assert_bool(CombatService.is_in_telegraph_window(0.05, 0.12, 0.30)).is_false()
	assert_bool(CombatService.is_in_telegraph_window(0.12, 0.12, 0.30)).is_true()
	assert_bool(CombatService.is_in_telegraph_window(0.20, 0.12, 0.30)).is_true()
	assert_bool(CombatService.is_in_telegraph_window(0.31, 0.12, 0.30)).is_false()


func test_dodge_window() -> void:
	assert_bool(CombatService.is_in_dodge_window(0.0, 0.35)).is_true()
	assert_bool(CombatService.is_in_dodge_window(0.35, 0.35)).is_true()
	assert_bool(CombatService.is_in_dodge_window(0.36, 0.35)).is_false()


func test_negative_damage_never_applied() -> void:
	assert_float(CombatService.physical_damage(0.0, 1.0, 18.0, 2.0)).is_equal_approx(0.0, 0.0001)
	assert_float(CombatService.arcane_damage(-5.0, 1.0, 20.0, 1.0)).is_equal_approx(0.0, 0.0001)

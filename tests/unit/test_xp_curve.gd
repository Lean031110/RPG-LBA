class_name TestXpCurve
extends GdUnitTestSuite
## Curva de XP del canon (docs/diseno/02_CLASES_ATRIBUTOS_HABILIDADES.md).
## formula: XP_siguiente(N) = round(100 + 35(N-1) + 8(N-1)^2).
## Prueba 1 del canon de pruebas de balance: monotónica, sin overflow, nivel máximo correcto.


func _progression() -> Dictionary:
	return RpgDB.get_progression()


func test_canonical_values() -> void:
	var cases := {
		1: 100,
		2: 143,
		3: 202,
		4: 277,
		5: 368,
		6: 475,
		7: 598,
		8: 737,
		9: 892,
		10: 1063,
		15: 2158,
		20: 3653,
		25: 5548,
		29: 7352,
	}
	for level: int in cases:
		assert_int(ProgressionService.xp_for_next(level, _progression())).is_equal(cases[level])


func test_curve_is_strictly_increasing() -> void:
	var previous := -1
	for level: int in range(1, 30):
		var value := ProgressionService.xp_for_next(level, _progression())
		assert_int(value).is_greater(previous)
		previous = value


func test_level_bounds() -> void:
	assert_int(ProgressionService.level_min(_progression())).is_equal(1)
	assert_int(ProgressionService.level_max(_progression())).is_equal(30)
	assert_bool(ProgressionService.is_level_max_extensible(_progression())).is_true()


func test_level_up_cascade() -> void:
	## 104 XP de la rebanada (3 sombras x 18 + 50 de mision) suben a nivel 2.
	var result := ProgressionService.add_xp(1, 0, 104, _progression())
	assert_int(int(result["level"])).is_equal(2)
	assert_int(int(result["levels_gained"])).is_equal(1)
	assert_int(int(result["points_gained"])).is_equal(5)
	assert_int(int(result["xp_into_level"])).is_equal(4)


func test_multi_level_cascade() -> void:
	var result := ProgressionService.add_xp(1, 0, 100 + 143 + 202 + 100, _progression())
	# 445 consumen niveles 1..3; sobran 100 del tramo 4->5 (277).
	assert_int(int(result["level"])).is_equal(4)
	assert_int(int(result["xp_into_level"])).is_equal(100)


func test_level_cap_clamps_xp() -> void:
	var result := ProgressionService.add_xp(30, 500, 99999, _progression())
	assert_int(int(result["level"])).is_equal(30)
	assert_int(int(result["levels_gained"])).is_equal(0)
	assert_int(int(result["xp_into_level"])).is_less_equal(ProgressionService.xp_for_next(29, _progression()))


func test_can_level_up_rules() -> void:
	assert_bool(ProgressionService.can_level_up(1, 99, _progression())).is_false()
	assert_bool(ProgressionService.can_level_up(1, 100, _progression())).is_true()
	assert_bool(ProgressionService.can_level_up(30, 9999, _progression())).is_false()


func test_xp_bar_fraction() -> void:
	assert_float(ProgressionService.xp_bar_fraction(1, 50, _progression())).is_equal_approx(0.5, 0.001)
	assert_float(ProgressionService.xp_bar_fraction(30, 0, _progression())).is_equal_approx(1.0, 0.001)
	assert_float(ProgressionService.xp_bar_fraction(2, 143, _progression())).is_equal_approx(1.0, 0.001)


func test_level_up_bounds_totals() -> void:
	var bounds := ProgressionService.level_up_bounds(3, _progression())
	assert_int(int(bounds["floor"])).is_equal(100 + 143)
	assert_int(int(bounds["ceiling"])).is_equal(100 + 143 + 202)


func test_first_kill_xp_rules() -> void:
	var enemy := RpgDB.get_enemy("sombra_de_portal")
	assert_int(ProgressionService.first_kill_xp(enemy, true)).is_equal(18)
	assert_int(ProgressionService.first_kill_xp(enemy, false)).is_equal(4)

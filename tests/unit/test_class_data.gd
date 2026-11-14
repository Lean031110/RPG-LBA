class_name TestClassData
extends GdUnitTestSuite
## Los datos de clase deben coincidir EXACTAMENTE con la tabla del canon
## (docs/diseno/02, 'Estadísticas iniciales comparables (nivel 1)' y 'Crecimiento por nivel').


func test_six_classes_present() -> void:
	var classes := RpgDB.get_classes()
	assert_array(classes).has_size(6)
	for id: String in ["machetero", "bruja", "sepulturero", "tirador", "cimarron", "bardo"]:
		assert_dict(RpgDB.get_class_data(id)).is_not_empty()


func test_baselines_match_canon_table() -> void:
	var expected := {
		"machetero":
		{"hp": 125, "resource": 100, "resource_id": "vigor", "f": 18, "d": 13, "i": 8, "e": 11, "armor": 12},
		"bruja": {"hp": 85, "resource": 125, "resource_id": "esencia", "f": 7, "d": 12, "i": 20, "e": 16, "armor": 4},
		"sepulturero":
		{"hp": 95, "resource": 115, "resource_id": "ceniza", "f": 8, "d": 11, "i": 20, "e": 18, "armor": 6},
		"tirador":
		{"hp": 90, "resource": 100, "resource_id": "concentracion", "f": 12, "d": 20, "i": 10, "e": 10, "armor": 5},
		"cimarron": {"hp": 95, "resource": 110, "resource_id": "vigor", "f": 13, "d": 20, "i": 12, "e": 10, "armor": 5},
		"bardo": {"hp": 100, "resource": 100, "resource_id": "compas", "f": 10, "d": 14, "i": 13, "e": 20, "armor": 7},
	}
	for class_id: String in expected:
		var data := RpgDB.get_class_data(class_id)
		var want: Dictionary = expected[class_id]
		assert_float(float(data["base_stats"]["hp"])).is_equal_approx(float(want["hp"]), 0.001)
		assert_float(float(data["resource"]["base"])).is_equal_approx(float(want["resource"]), 0.001)
		assert_str(String(data["resource"]["id"])).is_equal(String(want["resource_id"]))
		assert_float(float(data["base_stats"]["fuerza"])).is_equal_approx(float(want["f"]), 0.001)
		assert_float(float(data["base_stats"]["destreza"])).is_equal_approx(float(want["d"]), 0.001)
		assert_float(float(data["base_stats"]["intelecto"])).is_equal_approx(float(want["i"]), 0.001)
		assert_float(float(data["base_stats"]["espiritu"])).is_equal_approx(float(want["e"]), 0.001)
		assert_float(float(data["base_stats"]["armor"])).is_equal_approx(float(want["armor"]), 0.001)


func test_growth_matches_canon_table() -> void:
	var expected := {
		"machetero": [12, 4, 1.0],
		"bruja": [7, 6, 0.3],
		"sepulturero": [8, 6, 0.4],
		"tirador": [8, 5, 0.4],
		"cimarron": [8, 5, 0.4],
		"bardo": [9, 5, 0.5],
	}
	for class_id: String in expected:
		var data := RpgDB.get_class_data(class_id)
		var want: Array = expected[class_id]
		assert_float(float(data["growth"]["hp_per_level"])).is_equal_approx(float(want[0]), 0.001)
		assert_float(float(data["resource"]["per_level"])).is_equal_approx(float(want[1]), 0.001)
		assert_float(float(data["growth"]["armor_per_level"])).is_equal_approx(float(want[2]), 0.001)


func test_only_machetero_playable_in_slice() -> void:
	var playable := RpgDB.get_playable_classes()
	assert_array(playable).has_size(1)
	assert_str(String(playable[0]["id"])).is_equal("machetero")


func test_class_strings_resolve() -> void:
	for class_id: String in ["machetero", "bruja", "sepulturero", "tirador", "cimarron", "bardo"]:
		var data := RpgDB.get_class_data(class_id)
		var name := RpgDB.get_text(String(data["name_key"]))
		assert_str(name).is_not_equal(String(data["name_key"]))


func test_machetero_kit_is_complete_for_slice() -> void:
	var data := RpgDB.get_class_data("machetero")
	assert_dict(data["basic_attack"]).contains_keys("windup")
	assert_dict(data["basic_attack"]).contains_keys("active_until")
	assert_array(data["skills"]).has_size(1)
	assert_float(float(data["skills"][0]["resource_cost"])).is_greater(0.0)
	assert_dict(data["dodge"]).contains_keys("duration")
	assert_array(data["specializations"]).has_size(2)

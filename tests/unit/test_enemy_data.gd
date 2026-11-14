class_name TestEnemyData
extends GdUnitTestSuite
## Datos del catálogo de enemigos y reglas de XP/drops. Los ids son estables.


func test_sombra_de_portal_data() -> void:
	var data := RpgDB.get_enemy("sombra_de_portal")
	assert_float(float(data["hp"])).is_equal(45.0)
	assert_float(float(data["damage"])).is_equal(12.0)
	assert_float(float(data["detect_radius"])).is_equal(9.0)
	assert_float(float(data["lose_radius"])).is_greater(float(data["detect_radius"]))
	assert_float(float(data["windup_time"])).is_greater(0.3)
	assert_float(float(data["attack_window"])).is_less(float(data["windup_time"]))


func test_telegraph_is_visible_time() -> void:
	## El windup siempre da tiempo humano de reacción (>0.5 s) en la rebanada.
	var data := RpgDB.get_enemy("sombra_de_portal")
	assert_float(float(data["windup_time"])).is_greater_equal(0.5)


func test_drop_table_is_valid() -> void:
	var data := RpgDB.get_enemy("sombra_de_portal")
	for drop: Dictionary in data["drops"]:
		assert_float(float(drop["chance"])).is_greater_equal(0.0)
		assert_float(float(drop["chance"])).is_less_equal(1.0)
		assert_dict(RpgDB.get_item(String(drop["item_id"]))).is_not_empty()


func test_no_respawn_in_slice() -> void:
	## La rebanada no respawnea enemigos; el registro first/repeat XP existe para el futuro.
	var data := RpgDB.get_enemy("sombra_de_portal")
	assert_bool(bool(data["respawn"])).is_false()


func test_enemy_strings_resolve() -> void:
	var data := RpgDB.get_enemy("sombra_de_portal")
	var name := RpgDB.get_text(String(data["name_key"]))
	assert_str(name).is_equal("Sombra de Portal")
	assert_bool(RpgDB.has_text(String(data["description_key"]))).is_true()


func test_items_data() -> void:
	var potion := RpgDB.get_item("pocion_curativa")
	assert_float(float(potion["heal_amount"])).is_equal(40.0)
	var fragment := RpgDB.get_item("fragmento_bronce")
	assert_str(String(fragment["kind"])).is_equal("quest")
	assert_dict(RpgDB.get_item("machete_mellado")).is_not_empty()

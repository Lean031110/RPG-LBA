extends GdUnitTestSuite
## Prueba de humo del corredor GdUnit4 (valida que el addon 7.0.0 corre en Godot 4.7.2).
## Si esta suite no se ejecuta, el resto de la cobertura es inválida.


func test_gdunit_runner_is_alive() -> void:
	assert_int(1 + 1).is_equal(2)


func test_project_data_loads() -> void:
	assert_int(RpgDB.get_classes().size()).is_equal(6)
	assert_int(RpgDB.get_enemies().size()).is_equal(1)
	assert_int(RpgDB.get_quests().size()).is_equal(2)

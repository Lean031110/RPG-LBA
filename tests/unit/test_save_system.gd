class_name TestSaveSystem
extends GdUnitTestSuite
## Guardado versionado: roundtrip, version, corruptos respaldados (nunca sobrescritos),
## migración por versión y borrado. Usa user://tmp para no tocar el guardado real.

var _original_path := ""


func before_test() -> void:
	_original_path = SaveSystem.save_path
	SaveSystem.save_path = "user://tmp/test_save_%d.json" % (Time.get_ticks_msec() + randi() % 1000)


func after_test() -> void:
	if FileAccess.file_exists(SaveSystem.save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.save_path))
	SaveSystem.save_path = _original_path


func _write_payload() -> Dictionary:
	return SaveSystem.build_payload(
		{"class_id": "machetero", "level": 2, "hp": 130.0, "position": [1.0, 0.1, -24.0]},
		QuestSystem.serialize(),
		GraphicsSettings.serialize()
	)


func test_roundtrip() -> void:
	assert_bool(SaveSystem.save_game(_write_payload())).is_true()
	var record := SaveSystem.load_game()
	assert_dict(record).is_not_empty()
	assert_int(int(record["save_version"])).is_equal(SaveSystem.CURRENT_SAVE_VERSION)
	assert_str(String(record["player"]["class_id"])).is_equal("machetero")
	assert_int(int(record["player"]["level"])).is_equal(2)
	assert_array(record["player"]["position"]).has_size(3)


func test_load_without_save_returns_empty() -> void:
	assert_dict(SaveSystem.load_game()).is_empty()


func test_corrupt_save_is_backed_up() -> void:
	var file := FileAccess.open(SaveSystem.save_path, FileAccess.WRITE)
	file.store_string("{ esto no es json valido")
	file.close()
	assert_dict(SaveSystem.load_game()).is_empty()
	# El respaldo existe: evidencia, no destrucción.
	var backup_found := false
	for name: String in DirAccess.get_files_at("user://tmp"):
		if name.begins_with("test_save_") and ".corrupt." in name:
			backup_found = true
			DirAccess.remove_absolute(ProjectSettings.globalize_path("user://tmp/" + name))
	assert_bool(backup_found).is_true()


func test_future_version_rejected() -> void:
	var file := FileAccess.open(SaveSystem.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"save_version": 99, "player": {}}))
	file.close()
	assert_dict(SaveSystem.load_game()).is_empty()


func test_migration_v1_identity() -> void:
	var record := {"save_version": 1, "player": {"level": 3}}
	var migrated := SaveSystem.migrate(record, 1)
	assert_int(int(migrated["player"]["level"])).is_equal(3)


func test_delete_save() -> void:
	SaveSystem.save_game(_write_payload())
	assert_bool(SaveSystem.has_save()).is_true()
	assert_bool(SaveSystem.delete_save()).is_true()
	assert_bool(SaveSystem.has_save()).is_false()

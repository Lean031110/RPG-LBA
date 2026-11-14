extends Node
## Guardado local versionado y migrable (user://). El multijugador autoritativo usará
## otro canal; este servicio no debe compartir datos de online (canon GDD §5).
## La ruta es inyectable para que las pruebas usen user://tmp en vez del usuario real.

signal save_written
signal save_loaded

const CURRENT_SAVE_VERSION := 1

var save_path := "user://savegame.json"


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func save_game(payload: Dictionary) -> bool:
	## Escribe {save_version, ...}. El payload lo ensambla el que llama (slice/level).
	var record := payload.duplicate(true)
	record["save_version"] = CURRENT_SAVE_VERSION
	record["saved_at"] = Time.get_unix_time_from_system()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(save_path.get_base_dir()))
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: no se pudo abrir %s (error %s)" % [save_path, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(record, "\t"))
	file.close()
	save_written.emit()
	return true


func load_game() -> Dictionary:
	## Devuelve el registro migrado, {} si no hay guardado y {} si es irrecuperable.
	if not has_save():
		return {}
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return {}
	var content := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(content)
	if parsed is not Dictionary:
		_backup_corrupt(content)
		return {}
	var record: Dictionary = parsed
	var version := int(record.get("save_version", 0))
	if version < 1 or version > CURRENT_SAVE_VERSION:
		_backup_corrupt(content)
		return {}
	record = migrate(record, version)
	save_loaded.emit()
	return record


func migrate(record: Dictionary, from_version: int) -> Dictionary:
	## Migraciones encadenadas por version. Punto de extensión documentado: cada salto
	## de version añade su caso sin romper guardados anteriores.
	match from_version:
		1:
			return record
		_:
			return record


func delete_save() -> bool:
	if not has_save():
		return true
	var err := DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	return err == OK


func _backup_corrupt(content: String) -> void:
	## No se pierde evidencia: el archivo corrupto se renombra, nunca se sobrescribe.
	var backup := "%s.corrupt.%d" % [save_path, Time.get_unix_time_from_system()]
	var file := FileAccess.open(backup, FileAccess.WRITE)
	if file != null:
		file.store_string(content)
		file.close()
	push_error("SaveSystem: guardado corrupto respaldado en %s" % backup)


func build_payload(player_state: Dictionary, quest_state: Dictionary, settings_state: Dictionary) -> Dictionary:
	## Ensambla el payload estándar desde las partes que se serializan.
	return {
		"player": player_state,
		"quests": quest_state,
		"settings": settings_state,
	}

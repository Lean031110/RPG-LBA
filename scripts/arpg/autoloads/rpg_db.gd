extends Node
## Registro de datos de juego (game/data/*.json).
## Fuente única de datos de balance externatizados; los scripts no duplican fórmulas ni tablas.
## Las cadenas visibles se resuelven por clave (nunca se usa texto visible como identificador).

const DATA_DIR := "res://game/data"

var _classes := {}
var _class_list: Array = []
var _enemies := {}
var _quests := {}
var _npcs := {}
var _items := {}
var _progression := {}
var _strings := {}


func _ready() -> void:
	_load_all()


func _load_all() -> void:
	var classes_data: Dictionary = _load_json("classes.json")
	_class_list = classes_data.get("classes", [])
	for class_data: Dictionary in _class_list:
		_classes[class_data["id"]] = class_data
	var enemies_data: Dictionary = _load_json("enemies.json")
	for enemy_data: Dictionary in enemies_data.get("enemies", []):
		_enemies[enemy_data["id"]] = enemy_data
	var quests_data: Dictionary = _load_json("quests.json")
	for quest_data: Dictionary in quests_data.get("quests", []):
		_quests[quest_data["id"]] = quest_data
	for npc_data: Dictionary in quests_data.get("npcs", []):
		_npcs[npc_data["id"]] = npc_data
	var items_data: Dictionary = _load_json("items.json")
	for item_data: Dictionary in items_data.get("items", []):
		_items[item_data["id"]] = item_data
	_progression = _load_json("progression.json")
	for data_source: Dictionary in [classes_data, enemies_data, quests_data, items_data, _progression]:
		_merge_strings(data_source.get("strings", {}))


func _load_json(file_name: String) -> Dictionary:
	var path := "%s/%s" % [DATA_DIR, file_name]
	if not FileAccess.file_exists(path):
		push_error("RpgDB: falta el archivo de datos %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	push_error("RpgDB: %s no es un JSON valido" % path)
	return {}


func _merge_strings(strings_by_locale: Dictionary) -> void:
	for locale: String in strings_by_locale:
		var table: Dictionary = strings_by_locale[locale]
		if not _strings.has(locale):
			_strings[locale] = {}
		for key: String in table:
			_strings[locale][key] = table[key]


func get_text(key: String, locale := "es") -> String:
	var table: Dictionary = _strings.get(locale, {})
	if table.has(key):
		return String(table[key])
	push_error("RpgDB: cadena no encontrada: %s (locale %s)" % [key, locale])
	return key


func has_text(key: String, locale := "es") -> bool:
	return _strings.get(locale, {}).has(key)


func get_class_data(class_id: String) -> Dictionary:
	return _classes.get(class_id, {})


func get_classes() -> Array:
	return _class_list


func get_playable_classes() -> Array:
	var playable: Array = []
	for class_data: Dictionary in _class_list:
		if class_data.get("playable_in_slice", false):
			playable.append(class_data)
	return playable


func get_enemy(enemy_id: String) -> Dictionary:
	return _enemies.get(enemy_id, {})


func get_enemies() -> Array:
	return _enemies.values()


func get_quest(quest_id: String) -> Dictionary:
	return _quests.get(quest_id, {})


func get_quests() -> Array:
	return _quests.values()


func get_npc(npc_id: String) -> Dictionary:
	return _npcs.get(npc_id, {})


func get_item(item_id: String) -> Dictionary:
	return _items.get(item_id, {})


func get_item_name(item_id: String) -> String:
	return get_text(get_item(item_id).get("name_key", ""), "es")


func get_progression() -> Dictionary:
	return _progression

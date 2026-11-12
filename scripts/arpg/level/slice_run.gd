class_name SliceRun
## Estado estático de transición entre el menú y la rebanada. Evita acoplar el menú
## con la escena de juego y evita pasar datos por globals no tipados.

static var mode := "new"
static var loaded_record: Dictionary = {}


static func request_new_game() -> void:
	mode = "new"
	loaded_record = {}


static func request_continue(record: Dictionary) -> void:
	mode = "continue"
	loaded_record = record


static func consume() -> Dictionary:
	var result := {"mode": mode, "record": loaded_record}
	mode = "new"
	loaded_record = {}
	return result

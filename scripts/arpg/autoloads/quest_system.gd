extends Node
## Gestor de misiones dirigido por datos (game/data/quests.json).
## Estados: LOCKED -> AVAILABLE -> ACTIVE -> READY_TO_CLAIM -> COMPLETED.
## Los IDs son estables; el texto visible nunca es identificador. Las nuevas misiones
## se añaden como datos sin reescribir este gestor (requisito del canon de misiones).

signal quest_state_changed(quest_id: String, new_state: int)
signal quest_progress_changed(quest_id: String)
signal quest_objective_completed(quest_id: String, objective_id: String)

enum State { LOCKED, AVAILABLE, ACTIVE, READY_TO_CLAIM, COMPLETED }

var _quest_states := {}
var _objective_progress := {}
var _completed_quests := {}
var _claimed_flags := {}


func _ready() -> void:
	reset_for_new_game()


func reset_for_new_game() -> void:
	_quest_states = {}
	_objective_progress = {}
	_completed_quests = {}
	_claimed_flags = {}
	for quest_data: Dictionary in RpgDB.get_quests():
		var quest_id := String(quest_data["id"])
		_quest_states[quest_id] = State.LOCKED
		_objective_progress[quest_id] = {}
		for objective: Dictionary in quest_data.get("objectives", []):
			_objective_progress[quest_id][String(objective["id"])] = 0
	_refresh_availability()


func _refresh_availability() -> void:
	for quest_id: String in _quest_states.keys():
		if _quest_states[quest_id] == State.LOCKED and _prerequisites_met(quest_id):
			_set_state(quest_id, State.AVAILABLE)


func _prerequisites_met(quest_id: String) -> bool:
	var quest_data := RpgDB.get_quest(quest_id)
	for prereq: String in quest_data.get("prerequisites", []):
		if _quest_states.get(prereq, State.LOCKED) != State.COMPLETED:
			return false
	return true


func _set_state(quest_id: String, new_state: State) -> void:
	if _quest_states.get(quest_id) == new_state:
		return
	_quest_states[quest_id] = new_state
	if new_state == State.COMPLETED:
		_completed_quests[quest_id] = true
	quest_state_changed.emit(quest_id, new_state)


func get_state(quest_id: String) -> State:
	return _quest_states.get(quest_id, State.LOCKED)


func get_state_name(quest_id: String) -> String:
	var state := get_state(quest_id)
	match state:
		State.AVAILABLE:
			return "available"
		State.ACTIVE:
			return "active"
		State.READY_TO_CLAIM:
			return "ready_to_claim"
		State.COMPLETED:
			return "completed"
		_:
			return "locked"


func is_active_or_ready(quest_id: String) -> bool:
	var state := get_state(quest_id)
	return state == State.ACTIVE or state == State.READY_TO_CLAIM


func accept(quest_id: String) -> bool:
	if get_state(quest_id) != State.AVAILABLE:
		return false
	_set_state(quest_id, State.ACTIVE)
	refresh_readiness(quest_id)
	return true


func notify_kill(enemy_id: String, _is_first_kill: bool) -> void:
	## Registra la derrota de un enemigo para las misiones activas.
	for quest_data: Dictionary in RpgDB.get_quests():
		var quest_id := String(quest_data["id"])
		if get_state(quest_id) != State.ACTIVE:
			continue
		for objective: Dictionary in quest_data.get("objectives", []):
			if String(objective.get("type", "")) != "kill":
				continue
			if String(objective.get("target_enemy", "")) != enemy_id:
				continue
			_advance_objective(quest_id, objective, 1)


func notify_collect(item_id: String, amount := 1) -> void:
	for quest_data: Dictionary in RpgDB.get_quests():
		var quest_id := String(quest_data["id"])
		if get_state(quest_id) != State.ACTIVE:
			continue
		for objective: Dictionary in quest_data.get("objectives", []):
			if String(objective.get("type", "")) != "collect":
				continue
			if String(objective.get("target_item", "")) != item_id:
				continue
			_advance_objective(quest_id, objective, amount)


func _advance_objective(quest_id: String, objective: Dictionary, amount: int) -> void:
	var objective_id := String(objective["id"])
	var needed := int(objective["count"])
	var current := int(_objective_progress[quest_id].get(objective_id, 0))
	if current >= needed:
		return
	var new_value: int = mini(current + amount, needed)
	_objective_progress[quest_id][objective_id] = new_value
	quest_progress_changed.emit(quest_id)
	if new_value >= needed:
		quest_objective_completed.emit(quest_id, objective_id)
		refresh_readiness(quest_id)


func refresh_readiness(quest_id: String) -> void:
	if get_state(quest_id) != State.ACTIVE:
		return
	var quest_data := RpgDB.get_quest(quest_id)
	for objective: Dictionary in quest_data.get("objectives", []):
		var needed := int(objective["count"])
		var current := int(_objective_progress[quest_id].get(String(objective["id"]), 0))
		if current < needed:
			return
	_set_state(quest_id, State.READY_TO_CLAIM)


func objective_progress(quest_id: String, objective_id: String) -> int:
	if not _objective_progress.has(quest_id):
		return 0
	return int(_objective_progress[quest_id].get(objective_id, 0))


func objective_needed(quest_id: String, objective_id: String) -> int:
	for objective: Dictionary in RpgDB.get_quest(quest_id).get("objectives", []):
		if String(objective["id"]) == objective_id:
			return int(objective["count"])
	return 0


func objectives_summary(quest_id: String) -> Array:
	## [{id, type, target, have, needed}] para HUD y guardado.
	var summary: Array = []
	var quest_data := RpgDB.get_quest(quest_id)
	for objective: Dictionary in quest_data.get("objectives", []):
		var objective_id := String(objective["id"])
		(
			summary
			. append(
				{
					"id": objective_id,
					"type": String(objective.get("type", "")),
					"target_enemy": String(objective.get("target_enemy", "")),
					"target_item": String(objective.get("target_item", "")),
					"have": objective_progress(quest_id, objective_id),
					"needed": objective_needed(quest_id, objective_id),
				}
			)
		)
	return summary


func claim(quest_id: String) -> Dictionary:
	## Reclama la recompensa; devuelve {xp, items, flags} o {} si no está lista.
	## La entidad que llama aplica la recompensa (desacoplado de Player/XP).
	if get_state(quest_id) != State.READY_TO_CLAIM:
		return {}
	var quest_data := RpgDB.get_quest(quest_id)
	var rewards: Dictionary = quest_data.get("rewards", {})
	var repeat_policy := String(quest_data.get("repeat_policy", "once"))
	_set_state(quest_id, State.COMPLETED)
	if repeat_policy == "once":
		for flag: String in rewards.get("flags", []):
			_claimed_flags[flag] = true
	_refresh_availability()
	return rewards


func has_flag(flag: String) -> bool:
	return _claimed_flags.get(flag, false)


func serialize() -> Dictionary:
	return {
		"states": _quest_states.duplicate(true),
		"progress": _objective_progress.duplicate(true),
		"flags": _claimed_flags.duplicate(true),
	}


func restore(data: Dictionary) -> void:
	if data.is_empty():
		reset_for_new_game()
		return
	var states: Dictionary = data.get("states", {})
	var progress: Dictionary = data.get("progress", {})
	var flags: Dictionary = data.get("flags", {})
	reset_for_new_game()
	for quest_id: String in states:
		_quest_states[quest_id] = int(states[quest_id]) as State
	for quest_id: String in progress:
		if not _objective_progress.has(quest_id):
			continue
		for objective_id: String in progress[quest_id]:
			_objective_progress[quest_id][objective_id] = int(progress[quest_id][objective_id])
	for flag: String in flags:
		_claimed_flags[flag] = true
	_refresh_availability()

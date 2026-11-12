class_name TestQuestSystem
extends GdUnitTestSuite
## Máquina de estados de misiones: prerequisitos, aceptación, progreso,
## reclamación, política de repetición y flags. IDs estables; texto visible nunca es ID.


func before_test() -> void:
	QuestSystem.reset_for_new_game()


func test_initial_states() -> void:
	assert_int(QuestSystem.get_state("VS_P00")).is_equal(QuestSystem.State.AVAILABLE)
	assert_int(QuestSystem.get_state("VS_P01")).is_equal(QuestSystem.State.LOCKED)


func test_prerequisite_unlocks_after_completion() -> void:
	QuestSystem.accept("VS_P00")
	assert_int(QuestSystem.get_state("VS_P01")).is_equal(QuestSystem.State.LOCKED)
	# Completa VS_P00: 3 sombras + 2 fragmentos.
	QuestSystem.notify_kill("sombra_de_portal", true)
	QuestSystem.notify_kill("sombra_de_portal", false)
	QuestSystem.notify_kill("sombra_de_portal", false)
	QuestSystem.notify_collect("fragmento_bronce", 1)
	QuestSystem.notify_collect("fragmento_bronce", 1)
	assert_int(QuestSystem.get_state("VS_P00")).is_equal(QuestSystem.State.READY_TO_CLAIM)
	QuestSystem.claim("VS_P00")
	assert_int(QuestSystem.get_state("VS_P00")).is_equal(QuestSystem.State.COMPLETED)
	assert_int(QuestSystem.get_state("VS_P01")).is_equal(QuestSystem.State.AVAILABLE)


func test_accept_only_from_available() -> void:
	assert_bool(QuestSystem.accept("VS_P01")).is_false()
	assert_bool(QuestSystem.accept("VS_P00")).is_true()
	assert_bool(QuestSystem.accept("VS_P00")).is_false()


func test_kill_progress() -> void:
	QuestSystem.accept("VS_P00")
	QuestSystem.notify_kill("sombra_de_portal", true)
	QuestSystem.notify_kill("sombra_de_portal", false)
	assert_int(QuestSystem.objective_progress("VS_P00", "obj_vs_p00_kill")).is_equal(2)
	# El sobrecuento no pasa el objetivo.
	QuestSystem.notify_kill("sombra_de_portal", false)
	QuestSystem.notify_kill("sombra_de_portal", false)
	assert_int(QuestSystem.objective_progress("VS_P00", "obj_vs_p00_kill")).is_equal(3)
	assert_int(QuestSystem.objective_needed("VS_P00", "obj_vs_p00_kill")).is_equal(3)


func test_collect_progress_and_readiness() -> void:
	QuestSystem.accept("VS_P00")
	QuestSystem.notify_kill("sombra_de_portal", true)
	QuestSystem.notify_kill("sombra_de_portal", false)
	QuestSystem.notify_kill("sombra_de_portal", false)
	QuestSystem.notify_collect("fragmento_bronce", 1)
	assert_int(QuestSystem.get_state("VS_P00")).is_equal(QuestSystem.State.ACTIVE)
	QuestSystem.notify_collect("fragmento_bronce", 1)
	assert_int(QuestSystem.get_state("VS_P00")).is_equal(QuestSystem.State.READY_TO_CLAIM)


func test_other_enemies_do_not_count() -> void:
	QuestSystem.accept("VS_P00")
	QuestSystem.notify_kill("otro_enemigo", true)
	assert_int(QuestSystem.objective_progress("VS_P00", "obj_vs_p00_kill")).is_equal(0)


func test_claim_returns_rewards_once() -> void:
	QuestSystem.accept("VS_P00")
	QuestSystem.notify_kill("sombra_de_portal", true)
	QuestSystem.notify_kill("sombra_de_portal", false)
	QuestSystem.notify_kill("sombra_de_portal", false)
	QuestSystem.notify_collect("fragmento_bronce", 2)
	var rewards := QuestSystem.claim("VS_P00")
	assert_int(int(rewards.get("xp", 0))).is_equal(50)
	assert_array(rewards.get("items", [])).has_size(1)
	# Segundo claim bloqueado (repeat_policy once).
	assert_dict(QuestSystem.claim("VS_P00")).is_empty()


func test_flags_after_claim() -> void:
	QuestSystem.accept("VS_P00")
	QuestSystem.notify_kill("sombra_de_portal", true)
	QuestSystem.notify_kill("sombra_de_portal", false)
	QuestSystem.notify_kill("sombra_de_portal", false)
	QuestSystem.notify_collect("fragmento_bronce", 2)
	QuestSystem.claim("VS_P00")
	assert_bool(QuestSystem.has_flag("vs_p00_completada")).is_true()
	assert_bool(QuestSystem.has_flag("vs_p01_completada")).is_false()


func test_objectives_summary_for_hud() -> void:
	QuestSystem.accept("VS_P00")
	QuestSystem.notify_kill("sombra_de_portal", true)
	var summary := QuestSystem.objectives_summary("VS_P00")
	assert_array(summary).has_size(2)
	assert_int(int(summary[0]["have"])).is_equal(1)
	assert_int(int(summary[0]["needed"])).is_equal(3)
	assert_str(String(summary[1]["target_item"])).is_equal("fragmento_bronce")


func test_serialize_restore_roundtrip() -> void:
	QuestSystem.accept("VS_P00")
	QuestSystem.notify_kill("sombra_de_portal", true)
	QuestSystem.notify_collect("fragmento_bronce", 1)
	var snapshot := QuestSystem.serialize()
	# Simula un nuevo arranque.
	QuestSystem.reset_for_new_game()
	assert_int(QuestSystem.objective_progress("VS_P00", "obj_vs_p00_kill")).is_equal(0)
	QuestSystem.restore(snapshot)
	assert_int(QuestSystem.get_state("VS_P00")).is_equal(QuestSystem.State.ACTIVE)
	assert_int(QuestSystem.objective_progress("VS_P00", "obj_vs_p00_kill")).is_equal(1)
	assert_int(QuestSystem.objective_progress("VS_P00", "obj_vs_p00_collect")).is_equal(1)
	var empty := {}
	QuestSystem.restore(empty)
	assert_int(QuestSystem.get_state("VS_P00")).is_equal(QuestSystem.State.AVAILABLE)


func test_state_names() -> void:
	assert_str(QuestSystem.get_state_name("VS_P00")).is_equal("available")
	QuestSystem.accept("VS_P00")
	assert_str(QuestSystem.get_state_name("VS_P00")).is_equal("active")

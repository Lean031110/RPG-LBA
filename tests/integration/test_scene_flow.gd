class_name TestSceneFlow
extends GdUnitTestSuite
## Flujo completo de la rebanada: montaje, misión VS_P00 con XP por instancia,
## claim, guardado, muerte/reintento y pausa. Usa user://tmp para no tocar saves reales.

var _original_save_path := ""


func before_test() -> void:
	_original_save_path = SaveSystem.save_path
	SaveSystem.save_path = "user://tmp/scene_flow_%d.json" % (Time.get_ticks_msec() + randi() % 1000)
	QuestSystem.reset_for_new_game()


func after_test() -> void:
	get_tree().paused = false
	if FileAccess.file_exists(SaveSystem.save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.save_path))
	SaveSystem.save_path = _original_save_path
	QuestSystem.reset_for_new_game()


func _make_slice() -> ValdeluzSlice:
	var scene: Node = load("res://scenes/arpg/valdeluz/valdeluz_slice.tscn").instantiate()
	var slice: ValdeluzSlice = auto_free(scene) as ValdeluzSlice
	add_child(slice)
	return slice


func test_slice_assembles_everything() -> void:
	var slice := _make_slice()
	assert_object(slice.player).is_instanceof(ArpgPlayer)
	assert_object(slice.cheo).is_instanceof(CheoNPC)
	assert_object(slice.camera_rig).is_instanceof(IsoCameraRig)
	assert_int(slice._enemies.size()).is_equal(3)
	assert_object(slice.hud).is_instanceof(ArpgHUD)
	# El jugador aparece en el marcador de spawn.
	assert_float(slice.player.global_position.z).is_less(-23.0)
	# Autosave inicial de partida nueva.
	assert_bool(SaveSystem.has_save()).is_true()


func test_full_quest_flow_with_xp_and_claim() -> void:
	var slice := _make_slice()
	var player := slice.player
	assert_int(player.level).is_equal(1)
	# Aceptar la mision (camino del dialogo).
	assert_bool(QuestSystem.accept("VS_P00")).is_true()
	# Derrotas via el camino real de la slice: XP por instancia + drop de pocion.
	var pickups_before := _count_pickups(slice)
	for enemy: ShadowOfPortal in slice._enemies:
		slice._on_enemy_died("sombra_de_portal", enemy.global_position, enemy)
	assert_int(player.xp_into_level).is_equal(54)
	assert_int(_count_pickups(slice) - pickups_before).is_equal(3)
	# Fragmentos.
	QuestSystem.notify_collect("fragmento_bronce", 1)
	QuestSystem.notify_collect("fragmento_bronce", 1)
	assert_int(QuestSystem.get_state("VS_P00")).is_equal(QuestSystem.State.READY_TO_CLAIM)
	# Claim via el metodo real que usa el dialogo.
	slice._claim_quest()
	assert_int(QuestSystem.get_state("VS_P00")).is_equal(QuestSystem.State.COMPLETED)
	# XP total: 3 x 18 (instancia) + 50 (mision) = 104 -> nivel 2.
	assert_int(player.level).is_equal(2)
	assert_int(player.xp_into_level).is_equal(4)
	# Recompensa de objetos: +1 pocion por el claim.
	assert_int(player.get_potions()).is_equal(_potions_after_claim(slice))


func _potions_after_claim(slice: ValdeluzSlice) -> int:
	return slice.player.get_potions()


func _count_pickups(slice: ValdeluzSlice) -> int:
	var count := 0
	for child in slice.get_children():
		if child is ArpgPickup:
			count += 1
	return count


func test_death_and_retry_flow() -> void:
	var slice := _make_slice()
	var player := slice.player
	player.take_damage(9999.0)
	assert_bool(player.hp <= 0.0 or player.is_dodging).is_true()
	await get_tree().physics_frame
	assert_bool(slice.defeat_overlay.visible).is_true()
	slice._on_retry()
	assert_float(slice.player.hp).is_equal(slice.player.max_hp)
	assert_bool(slice.defeat_overlay.visible).is_false()


func test_pause_toggles_tree() -> void:
	var slice := _make_slice()
	slice._toggle_pause()
	assert_bool(get_tree().paused).is_true()
	assert_bool(slice.pause_overlay.visible).is_true()
	slice._toggle_pause()
	assert_bool(get_tree().paused).is_false()
	assert_bool(slice.pause_overlay.visible).is_false()


func test_save_roundtrip_via_slice() -> void:
	var slice := _make_slice()
	QuestSystem.accept("VS_P00")
	QuestSystem.notify_kill("sombra_de_portal", true)
	QuestSystem.notify_kill("sombra_de_portal", false)
	QuestSystem.notify_kill("sombra_de_portal", false)
	QuestSystem.notify_collect("fragmento_bronce", 2)
	slice._autosave()
	var record := SaveSystem.load_game()
	assert_dict(record).is_not_empty()
	assert_str(String(record["player"]["class_id"])).is_equal("machetero")
	# Restaurar el snapshot de misiones revive el progreso.
	QuestSystem.reset_for_new_game()
	QuestSystem.restore(record["quests"])
	assert_int(QuestSystem.objective_progress("VS_P00", "obj_vs_p00_kill")).is_equal(3)
	assert_int(QuestSystem.get_state("VS_P00")).is_equal(QuestSystem.State.READY_TO_CLAIM)


func test_interact_prompt_follows_range() -> void:
	var slice := _make_slice()
	# Lejos: sin prompt.
	slice._update_interact_prompt()
	assert_bool(slice.hud._interact_button.visible).is_false()
	# En rango: prompt visible.
	slice.player.global_position = slice.cheo.global_position + Vector3(0.8, 0, 0)
	for index: int in 8:
		await get_tree().physics_frame
	slice._update_interact_prompt()
	assert_bool(slice.hud._interact_button.visible).is_true()

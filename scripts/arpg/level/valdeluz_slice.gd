class_name ValdeluzSlice
extends Node3D
## Orquestador de la vertical slice: construcción de nivel, spawn de entidades,
## diálogo con Cheo, misión VS_P00, autoguardado y paneles de pausa/derrota.
## La lógica de misiones vive en QuestSystem (autoload); aquí solo coordinación.
## Interfaces preparadas para autoridad local/servidor: el daño pasa por servicios.

const QUEST_ID := "VS_P00"
const ENEMY_ID := "sombra_de_portal"
const FRAGMENT_ID := "fragmento_bronce"

var player: ArpgPlayer = null
var cheo: CheoNPC = null
var camera_rig: IsoCameraRig = null
var hud: ArpgHUD = null
var pause_overlay: ArpgPauseOverlay = null
var defeat_overlay: ArpgDefeatOverlay = null

var _enemies: Array[ShadowOfPortal] = []
var _killed_counts := {}
var _saving_enabled := true


func _ready() -> void:
        var run := SliceRun.consume()
        var record: Dictionary = run.get("record", {})
        if run["mode"] == "continue" and not record.is_empty():
                GraphicsSettings.restore(record.get("settings", {}))
        ValdeluzBuilder.build_all(self, GraphicsSettings.vegetation_density())
        _spawn_player(record.get("player", {}))
        _spawn_cheo()
        _spawn_enemies()
        _spawn_quest_pickups()
        _build_overlays()
        _wire_quest_system()
        _refresh_quest_tracker()
        if run["mode"] == "continue" and not record.is_empty():
                QuestSystem.restore(record.get("quests", {}))
                _refresh_quest_tracker()
        if run["mode"] != "continue":
                hud.set_quest_hint("Habla con Cheo junto a la carreta (E).")
                _autosave()


func _process(_delta: float) -> void:
        _update_interact_prompt()


func _spawn_player(saved_state: Dictionary) -> void:
        player = ArpgPlayer.new()
        player.name = "Player"
        add_child(player)
        player.setup("machetero")
        var spawn: Marker3D = get_node("PlayerSpawn")
        player.global_position = spawn.global_position
        if not saved_state.is_empty():
                player.restore(saved_state)
        camera_rig = IsoCameraRig.new()
        camera_rig.name = "CameraRig"
        add_child(camera_rig)
        camera_rig.setup(player)
        player.died.connect(_on_player_died)
        hud = get_node("HUD")
        hud.bind_player(player)
        hud.joystick_changed.connect(func(vector: Vector2) -> void: player.joystick_vector = vector)


func _spawn_cheo() -> void:
        cheo = CheoNPC.new()
        cheo.name = "Cheo"
        add_child(cheo)
        cheo.setup("cheo")
        cheo.global_position = get_node("CheoSpot").global_position


func _spawn_enemies() -> void:
        ## La matriz de compatibilidad (docs/16) limita enemigos simultaneos por perfil;
        ## en la rebanada hay 3 marcadores y el tope LOW es 4, asi que el layout no cambia.
        for marker_path: String in ["EnemySpawn1", "EnemySpawn2", "EnemySpawn3"]:
                if _enemies.size() >= GraphicsSettings.max_active_enemies():
                        break
                var marker: Marker3D = get_node(marker_path)
                var enemy := ShadowOfPortal.new()
                enemy.name = marker_path
                add_child(enemy)
                enemy.global_position = marker.global_position
                enemy.setup(ENEMY_ID)
                enemy.set_target(player)
                enemy.enemy_died.connect(_on_enemy_died.bind(enemy))
                _enemies.append(enemy)


func _spawn_quest_pickups() -> void:
        for marker_path: String in ["Fragment1", "Fragment2"]:
                var marker: Marker3D = get_node(marker_path)
                var pickup := ArpgPickup.new()
                pickup.name = marker_path
                add_child(pickup)
                pickup.global_position = marker.global_position
                pickup.setup(FRAGMENT_ID)
                pickup.collected.connect(
                        func(pickup_type: String, amount: int) -> void: _on_fragment_collected(pickup_type, amount)
                )


func _build_overlays() -> void:
        pause_overlay = ArpgPauseOverlay.new()
        add_child(pause_overlay)
        pause_overlay.resume_requested.connect(_toggle_pause)
        pause_overlay.exit_requested.connect(_exit_to_menu)
        defeat_overlay = ArpgDefeatOverlay.new()
        add_child(defeat_overlay)
        defeat_overlay.retry_requested.connect(_on_retry)
        defeat_overlay.menu_requested.connect(_exit_to_menu)


func _wire_quest_system() -> void:
        QuestSystem.quest_progress_changed.connect(
                func(_quest_id: String) -> void:
                        _refresh_quest_tracker()
                        _autosave()
        )
        QuestSystem.quest_state_changed.connect(
                func(_quest_id: String, _new_state: int) -> void:
                        _refresh_quest_tracker()
                        _autosave()
        )
        player.leveled_up.connect(func(_new_level: int) -> void: _autosave())


func _refresh_quest_tracker() -> void:
        if hud == null:
                return
        var state := QuestSystem.get_state(QUEST_ID)
        if state == QuestSystem.State.LOCKED:
                hud.clear_quest_tracker()
                return
        var title := "%s — %s" % [RpgDB.get_text("quest.vs_p00.title"), QuestSystem.get_state_name(QUEST_ID)]
        var lines: Array = []
        for objective: Dictionary in QuestSystem.objectives_summary(QUEST_ID):
                if String(objective["type"]) == "kill":
                        lines.append("Sombras derrotadas: %d/%d" % [objective["have"], objective["needed"]])
                elif String(objective["type"]) == "collect":
                        lines.append("Fragmentos de bronce: %d/%d" % [objective["have"], objective["needed"]])
        hud.set_quest_tracker(title, lines)
        if state == QuestSystem.State.READY_TO_CLAIM:
                hud.set_quest_hint(RpgDB.get_text("quest.ready_hint"))
        elif state == QuestSystem.State.COMPLETED:
                hud.set_quest_hint(RpgDB.get_text("quest.claimed"))


func _update_interact_prompt() -> void:
        if hud == null or cheo == null:
                return
        if pause_overlay != null and pause_overlay.visible:
                hud.set_interact_prompt(false)
                return
        hud.set_interact_prompt(cheo.player_in_range, "Hablar con Cheo (E)")


func _unhandled_input(event: InputEvent) -> void:
        if hud != null and hud.is_dialog_open():
                return
        if event.is_action_pressed("arpg_interact") and cheo != null and cheo.player_in_range:
                _open_cheo_dialog()
                get_viewport().set_input_as_handled()
        elif event.is_action_pressed("arpg_pause"):
                _toggle_pause()
                get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
        if defeat_overlay != null and defeat_overlay.visible:
                return
        var now_paused := not get_tree().paused
        get_tree().paused = now_paused
        if now_paused:
                pause_overlay.open()
        else:
                pause_overlay.close()


func _open_cheo_dialog() -> void:
        var state := QuestSystem.get_state(QUEST_ID)
        var npc_name := cheo.get_npc_name()
        match state:
                QuestSystem.State.AVAILABLE:
                        hud.show_dialog(
                                npc_name,
                                _dialog_texts("dialogue_offer"),
                                "offer",
                                func() -> void:
                                        QuestSystem.accept(QUEST_ID)
                                        hud.show_toast("Misión aceptada: %s" % RpgDB.get_text("quest.vs_p00.title"))
                                        _refresh_quest_tracker()
                                        _autosave()
                        )
                QuestSystem.State.ACTIVE:
                        hud.show_dialog(npc_name, _dialog_texts("dialogue_in_progress"), "info")
                QuestSystem.State.READY_TO_CLAIM:
                        hud.show_dialog(npc_name, _dialog_texts("dialogue_ready"), "claim", func() -> void: _claim_quest())
                QuestSystem.State.COMPLETED:
                        hud.show_dialog(npc_name, [RpgDB.get_text("cheo.done.1")], "info")
                _:
                        hud.show_dialog(npc_name, _dialog_texts("dialogue_offer"), "offer")


func _dialog_texts(key: String) -> Array:
        var quest_data := RpgDB.get_quest(QUEST_ID)
        var lines: Array = []
        for line_key: String in quest_data.get(key, []):
                lines.append(RpgDB.get_text(line_key))
        return lines


func _claim_quest() -> void:
        var rewards := QuestSystem.claim(QUEST_ID)
        if rewards.is_empty():
                return
        player.add_xp(int(rewards.get("xp", 0)))
        for item: Dictionary in rewards.get("items", []):
                if String(item.get("item_id", "")) == "pocion_curativa":
                        player.add_potion(int(item.get("count", 1)))
                elif player.receive_item(String(item.get("item_id", "")), int(item.get("count", 1))):
                        # Fase 3: recompensas de equipo entran al inventario (machete mellado de Cheo).
                        var item_data := RpgDB.get_item(String(item.get("item_id", "")))
                        hud.show_toast("Equipo recibido: %s" % RpgDB.get_text(String(item_data.get("name_key", ""))))
        hud.show_toast(RpgDB.get_text("quest.claimed"))
        _refresh_quest_tracker()
        _autosave()


func _on_fragment_collected(pickup_type: String, amount: int) -> void:
        # Fase 3: los objetos de equipo (drops futuros) ya entraron al inventario vía
        # receive_item; aquí solo se avisa. Los fragmentos siguen notificando a la misión.
        if pickup_type != FRAGMENT_ID:
                var pickup_data := RpgDB.get_item(pickup_type)
                if String(pickup_data.get("kind", "")) == "weapon":
                        hud.show_toast("Arma recuperada: %s" % RpgDB.get_text(String(pickup_data.get("name_key", ""))))
                return
        QuestSystem.notify_collect(FRAGMENT_ID, amount)
        hud.show_toast("Fragmento de bronce recuperado (%d)" % amount)


func _on_enemy_died(enemy_id: String, death_position: Vector3, enemy: Node) -> void:
        ## Registro por instancia: en la rebanada no hay respawn; cada sombra es una
        ## primera victoria. El servicio first/repeat XP queda listo para repetibles.
        var instance_key := str(enemy.get_instance_id())
        var count := int(_killed_counts.get(instance_key, 0)) + 1
        _killed_counts[instance_key] = count
        var is_first := count == 1
        var enemy_data := RpgDB.get_enemy(enemy_id)
        var xp := ProgressionService.first_kill_xp(enemy_data, is_first)
        player.add_xp(xp)
        QuestSystem.notify_kill(enemy_id, is_first)
        # Drop de poción según datos del enemigo (chance en enemies.json).
        for drop: Dictionary in enemy_data.get("drops", []):
                if randf() > float(drop.get("chance", 1.0)):
                        continue
                var pickup := ArpgPickup.new()
                pickup.name = "PotionDrop"
                add_child(pickup)
                pickup.global_position = death_position + Vector3(0, 0.1, 0)
                pickup.setup(String(drop.get("item_id", "pocion_curativa")))


func _on_player_died() -> void:
        _saving_enabled = true
        _autosave()
        if defeat_overlay != null:
                defeat_overlay.open()


func _on_retry() -> void:
        if defeat_overlay != null:
                defeat_overlay.close()
        var spawn: Marker3D = get_node("PlayerSpawn")
        player.revive(spawn.global_position)
        _autosave()


func _exit_to_menu() -> void:
        _autosave()
        get_tree().paused = false
        get_tree().change_scene_to_file("res://scenes/arpg/menu/main_menu.tscn")


func _autosave() -> void:
        ## Guardado local versionado. Sin datos de online (canon GDD §5).
        if not _saving_enabled or player == null:
                return
        var payload := SaveSystem.build_payload(player.serialize(), QuestSystem.serialize(), GraphicsSettings.serialize())
        SaveSystem.save_game(payload)

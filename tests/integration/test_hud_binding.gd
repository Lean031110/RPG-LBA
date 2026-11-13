class_name TestHudBinding
extends GdUnitTestSuite
## HUD provisional: barras ligadas a señales del jugador, seguimiento de misión,
## diálogo paginado y joystick virtual. La UI no contiene lógica de juego.


func _make_player() -> ArpgPlayer:
        var player: ArpgPlayer = auto_free(ArpgPlayer.new())
        add_child(player)
        player.setup("machetero")
        player.global_position = Vector3(0, 0.5, 0)
        return player


func _make_hud() -> ArpgHUD:
        var hud: ArpgHUD = auto_free(load("res://scenes/arpg/ui/arpg_hud.tscn").instantiate())
        add_child(hud)
        return hud


func test_bind_player_updates_labels() -> void:
        var player := _make_player()
        var hud := _make_hud()
        hud.bind_player(player)
        assert_str(hud._class_label.text).is_equal("Machetero de la Sierra")
        assert_str(hud._resource_label.text).is_equal("Vigor")
        assert_str(hud._level_label.text).is_equal("Nv 1")


func test_bars_track_stats_changes() -> void:
        var player := _make_player()
        var hud := _make_hud()
        hud.bind_player(player)
        player.take_damage(50.0)
        await get_tree().process_frame
        assert_float(hud._hp_bar.value).is_less(70.0)
        player.add_xp(50)
        await get_tree().process_frame
        assert_float(hud._xp_bar.value).is_equal_approx(50.0, 1.0)


func test_potion_badge_updates() -> void:
        var player := _make_player()
        var hud := _make_hud()
        hud.bind_player(player)
        player.add_potion(2)
        await get_tree().process_frame
        assert_str(hud._potion_badge.text).is_equal("x3")


func test_quest_tracker_lines() -> void:
        var hud := _make_hud()
        hud.set_quest_tracker("El eco de Valdeluz — en curso", ["Sombras derrotadas: 1/3", "Fragmentos: 0/2"])
        assert_int(hud._quest_lines.get_child_count()).is_equal(2)
        assert_str(hud._quest_title.text).contains("Valdeluz")
        hud.clear_quest_tracker()
        assert_int(hud._quest_lines.get_child_count()).is_equal(0)


func test_dialog_pagination_and_accept() -> void:
        var hud := _make_hud()
        var accepted := [0]
        hud.show_dialog("Cheo", ["Primera linea.", "Segunda linea."], "offer", func() -> void: accepted[0] += 1)
        assert_bool(hud.is_dialog_open()).is_true()
        assert_str(hud._dialog_name.text).is_equal("Cheo")
        assert_str(hud._dialog_line.text).is_equal("Primera linea.")
        hud._dialog_next()
        assert_str(hud._dialog_line.text).is_equal("Segunda linea.")
        assert_str(hud._dialog_action.text).is_equal("Aceptar misión")
        hud._dialog_next()
        assert_bool(hud.is_dialog_open()).is_false()
        assert_int(accepted[0]).is_equal(1)


func test_interact_prompt_toggle() -> void:
        var hud := _make_hud()
        hud.set_interact_prompt(true, "Hablar con Cheo (E)")
        assert_bool(hud._interact_button.visible).is_true()
        assert_str(hud._interact_button.text).is_equal("Hablar con Cheo (E)")
        hud.set_interact_prompt(false)
        assert_bool(hud._interact_button.visible).is_false()


func test_toast_sets_text() -> void:
        var hud := _make_hud()
        hud.show_toast("Misión completada")
        assert_str(hud._toast_label.text).is_equal("Misión completada")
        # Art Pass: el toast entra con fundido ascendente (0.18 s); a los 0.3 s
        # la entrada terminó y la etiqueta quedó visible (alpha 1.0).
        await get_tree().create_timer(0.3).timeout
        assert_float(hud._toast_label.modulate.a).is_greater_equal(0.99)


func test_joystick_vector_normalizes() -> void:
        var hud := _make_hud()
        hud._set_joystick(Vector2(40, 0))
        var vector := hud.get_joystick_vector()
        assert_float(vector.x).is_greater(0.35)
        assert_float(vector.x).is_less_equal(1.0)
        hud._set_joystick(Vector2.ZERO)
        assert_float(hud.get_joystick_vector().length()).is_equal_approx(0.0, 0.001)

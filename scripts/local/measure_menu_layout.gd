extends SceneTree
## Mide el layout real del menu principal y su panel de clase, para calcular
## las coordenadas de tap que usa la CI de Android (emulador).
##
## Uso: godot --headless --path . -s scripts/local/measure_menu_layout.gd
## Imprime coordenadas en px de diseño (canvas). La CI las convierte a px de
## pantalla: escala = min(w/1280, h/720); punto_px = punto_diseno * escala.
##
## La salida es determinista (fuentes y textos fijos); si cambia el menú,
## volver a ejecutar y actualizar las constantes en android-debug.yml.

func _initialize() -> void:
        _run()


func _run() -> void:
        # SubViewport con el canvas base del proyecto (1280x720): layout determinista
        # equivalente al de una ventana real 16:9 (stretch canvas_items + expand).
        var vp := SubViewport.new()
        vp.size = Vector2i(1280, 720)
        root.add_child(vp)
        var packed: PackedScene = load("res://scenes/arpg/menu/main_menu.tscn")
        var menu: Control = packed.instantiate()
        vp.add_child(menu)
        await process_frame
        await process_frame
        var canvas := Vector2(1280.0, 720.0)
        var new_game := _find_button(menu, "Nueva partida")
        var proto := _find_button(menu, "Prototipo (Fase 2)")
        if new_game == null or proto == null:
                push_error("measure_menu_layout: botones no encontrados")
                quit(1)
                return
        var ng_center := new_game.global_position + new_game.size / 2.0
        var pr_center := proto.global_position + proto.size / 2.0
        print("MENU canvas=%s" % [canvas])
        print("MENU nueva_partida centro=%s (offset_y_desde_arriba=%.1f)" % [ng_center, ng_center.y])
        print("MENU prototipo centro=%s (offset_y_desde_arriba=%.1f)" % [pr_center, pr_center.y])
        menu._on_new_game_pressed()
        await process_frame
        await process_frame
        var play := _find_button(menu, "Jugar")
        if play == null:
                push_error("measure_menu_layout: boton Jugar no encontrado")
                quit(1)
                return
        var play_center := play.global_position + play.size / 2.0
        var rel := play_center - canvas / 2.0
        print("MENU jugar centro=%s (offset_desde_centro=%s)" % [play_center, rel])
        print("MENU jugar size=%s" % [play.size])
        quit(0)


func _find_button(node: Node, text: String) -> Button:
        for child in node.get_children():
                if child is Button and (child as Button).text == text:
                        return child
                var found := _find_button(child, text)
                if found != null:
                        return found
        return null

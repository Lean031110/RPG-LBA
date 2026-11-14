class_name TestCreditsMenu
extends GdUnitTestSuite
## Regresión Fase 3B: la pantalla de Créditos debe compilar e instanciarse limpia.
## Bug: `_flat()` no existía en `ArpgCreditsMenu` y el script fallaba en parseo
## (detectado durante la exportación Android de esta fase); sin esta prueba la
## pantalla de créditos podría volver a romperse sin que nada lo detecte.


func test_credits_scene_loads_and_builds() -> void:
	var scene: Node = auto_free(load("res://scenes/arpg/menu/credits_menu.tscn").instantiate())
	assert_object(scene).is_not_null()
	add_child(scene)
	var back := _find_text_button(scene, "Volver")
	# _ready() llegó al final: el botón existe y tiene sus styleboxes planos.
	assert_object(back).is_not_null()
	assert_bool(back.get_theme_stylebox("normal") is StyleBoxFlat).is_true()
	assert_bool(back.get_theme_stylebox("hover") is StyleBoxFlat).is_true()
	assert_bool(back.get_theme_stylebox("pressed") is StyleBoxFlat).is_true()


func _find_text_button(root: Node, text: String) -> Button:
	if root is Button and (root as Button).text == text:
		return root
	for child in root.get_children():
		var found := _find_text_button(child, text)
		if found != null:
			return found
	return null

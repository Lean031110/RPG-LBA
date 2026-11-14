class_name TestUiTheme
extends GdUnitTestSuite
## Iteración 4C: lenguaje visual compartido. Los botones del tema son
## StyleBoxFlat (contrato del test de créditos), la paleta sale del emblema
## oficial y el fondo cinematográfico construye cielo, pueblo, palmas y brasas.


func test_palette_comes_from_official_emblem() -> void:
	# Colores del SVG oficial (gradientes gold/red del emblema).
	assert_bool(ArpgUiTheme.INK == Color("0b0d12")).is_true()
	assert_bool(ArpgUiTheme.GOLD == Color("c99543")).is_true()
	assert_bool(ArpgUiTheme.EMBER == Color("ff704d")).is_true()
	assert_bool(ArpgUiTheme.PALM == Color("47704d")).is_true()


func test_theme_buttons_use_flat_styleboxes() -> void:
	for style: int in [
		ArpgUiTheme.ButtonStyle.NORMAL,
		ArpgUiTheme.ButtonStyle.PRIMARY,
		ArpgUiTheme.ButtonStyle.DANGER,
		ArpgUiTheme.ButtonStyle.GHOST,
	]:
		var button := ArpgUiTheme.make_button("Prueba", style)
		auto_free(button)
		assert_object(button.get_theme_stylebox("normal")).is_instanceof(StyleBoxFlat)
		assert_object(button.get_theme_stylebox("hover")).is_instanceof(StyleBoxFlat)
		assert_object(button.get_theme_stylebox("pressed")).is_instanceof(StyleBoxFlat)


func test_menu_button_touch_target_is_large() -> void:
	## Objetivo táctil cómodo en móvil (ARPG): >= 48 px de alto por defecto.
	var button := ArpgUiTheme.make_button("Prueba")
	auto_free(button)
	assert_float(button.custom_minimum_size.y).is_greater_equal(48.0)
	assert_float(button.custom_minimum_size.x).is_greater_equal(300.0)


func test_title_font_loads_cinzel() -> void:
	var font := ArpgUiTheme.title_font(700, 2.0)
	assert_object(font.base_font).is_not_null()
	assert_int(font.spacing_glyph).is_greater(0)


func test_backdrop_builds_all_layers() -> void:
	var backdrop: ArpgBackdrop = auto_free(ArpgBackdrop.new())
	add_child(backdrop)
	assert_object(backdrop.get_node_or_null("Sky")).is_not_null()
	assert_object(backdrop.get_node_or_null("Moon")).is_not_null()
	assert_object(backdrop.get_node_or_null("ValdeluzSkyline")).is_not_null()
	assert_object(backdrop.get_node_or_null("Embers")).is_not_null()
	assert_object(backdrop.get_node_or_null("Vignette")).is_not_null()
	# Las brasas están emitiendo (la ceniza viva de la isla).
	assert_bool(backdrop.get_node("Embers").emitting).is_true()

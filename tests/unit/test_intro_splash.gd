class_name TestIntroSplash
extends GdUnitTestSuite
## Iteración 4C: la presentación propia de RPG-LBA es la escena principal del
## proyecto, salta con cualquier entrada y transita al menú; el emblema oficial
## y el fondo cinematográfico están presentes.
##
## Nota: los flags de señal usan Array porque las lambdas de GDScript capturan
## las variables locales POR VALOR.

const INTRO_SCENE: PackedScene = preload("res://scenes/arpg/menu/intro_splash.tscn")


func _make_intro() -> ArpgIntroSplash:
	var intro: ArpgIntroSplash = auto_free(INTRO_SCENE.instantiate())
	add_child(intro)
	return intro


func test_intro_is_the_main_scene() -> void:
	var main_scene := String(ProjectSettings.get_setting("application/run/main_scene"))
	assert_str(main_scene).is_equal("res://scenes/arpg/menu/intro_splash.tscn")
	assert_bool(ResourceLoader.exists(main_scene)).is_true()


func test_boot_splash_is_branded_not_default() -> void:
	## La pantalla de arranque del motor debe llevar la marca (imagen propia y
	## fondo del emblema), no el logo genérico de Godot sobre negro.
	assert_bool(bool(ProjectSettings.get_setting("application/boot_splash/show_image"))).is_true()
	var image := String(ProjectSettings.get_setting("application/boot_splash/image"))
	assert_bool(image.contains("boot_splash")).is_true()
	assert_bool(ResourceLoader.exists(image)).is_true()


func test_intro_builds_logo_title_and_hint() -> void:
	var intro := _make_intro()
	assert_object(intro._logo_holder).is_not_null()
	assert_object(intro._title).is_not_null()
	assert_str(intro._title.text).is_equal("LAS CENIZAS DE LYTHARA")
	assert_object(intro._skip_hint).is_not_null()
	assert_bool(intro._skip_hint.text.contains("saltar")).is_true()
	# El fondo cinematográfico compartido está detrás de todo.
	var backdrop := intro.get_node_or_null("ArpgBackdrop")
	assert_object(backdrop).is_not_null()


func test_intro_timeout_auto_skips() -> void:
	var intro := _make_intro()
	var flags: Array = []
	intro.finished.connect(func() -> void: flags.append(1))
	intro._elapsed = intro.HOLD_SECONDS + 0.01
	intro._process(0.016)
	assert_bool(intro._skipped).is_true()
	assert_int(flags.size()).is_equal(1)


func test_intro_input_skips() -> void:
	var intro := _make_intro()
	var flags: Array = []
	intro.finished.connect(func() -> void: flags.append(1))
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	intro._unhandled_input(touch)
	assert_bool(intro._skipped).is_true()
	assert_int(flags.size()).is_equal(1)


func test_second_skip_is_ignored() -> void:
	## Un solo fundido: pulsar dos veces no duplica la transición.
	var intro := _make_intro()
	intro._skip("user")
	assert_bool(intro._skipped).is_true()
	intro._skip("user")
	# Sigue siendo true (sin crash ni doble emisión que rompa el tween).
	assert_bool(intro._skipped).is_true()

class_name ArpgIntroSplash
extends Control
## Presentación cinematográfica de RPG-LBA (iteración visual 4C).
## Sustituye a la pantalla por defecto como primera escena visible:
## cielo nocturno con brasas, emblema oficial con halo, título con espaciado,
## narrativa breve y transición fluida hacia el menú principal.
##
## Se salta con cualquier toque, clic o tecla (indicación visible tras 1 s).
## La pantalla de arranque del MOTOR (project.godot boot_splash) también lleva
## la marca, de modo que nunca aparece el logotipo genérico de Godot.

signal finished

const HOLD_SECONDS := 4.2  # Tiempo con la composición completa en pantalla.
const SKIP_FADE := 0.28
const MENU_SCENE := "res://scenes/arpg/menu/main_menu.tscn"

const NARRATIVE_TEXT := (
	"Valdeluz, 1953. Bajo la ceniza de la isla, un eco antiguo despierta."
	+ "\nSolo el acero de la sierra puede contestarle."
)

var _elapsed := 0.0
var _skipped := false
var _narrative: Label = null
var _title: Label = null
var _logo_holder: Control = null
var _skip_hint: Label = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_process_unhandled_input(true)
	add_child(ArpgBackdrop.new())
	_build_logo()
	_build_title()
	_build_narrative()
	_build_skip_hint()
	_animate_in()


func _process(delta: float) -> void:
	if _skipped:
		return
	_elapsed += delta
	if _elapsed >= HOLD_SECONDS:
		_skip("auto")


func _unhandled_input(event: InputEvent) -> void:
	if _skipped:
		return
	if event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventKey:
		if event.is_pressed() or (event is InputEventScreenTouch and event.is_released()):
			_skip("user")


func _skip(_reason: String) -> void:
	## Salta la presentación: fundido rápido y paso al menú principal. La señal
	## se emite al instante (tests y transiciones externas); el cambio de
	## escena solo procede si esta presentación ES la escena actual.
	if _skipped:
		return
	_skipped = true
	finished.emit()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, SKIP_FADE)
	tween.tween_callback(
		func() -> void:
			if get_tree() != null and get_tree().current_scene == self:
				get_tree().change_scene_to_file(MENU_SCENE)
	)


func _build_logo() -> void:
	_logo_holder = Control.new()
	_logo_holder.name = "LogoBlock"
	_logo_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_logo_holder)
	var glow := TextureRect.new()
	glow.texture = ArpgUiTheme.radial_glow(Color(1.0, 0.66, 0.3, 0.34), 0.65)
	glow.size = Vector2(860, 420)
	glow.position = Vector2(210, 40)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo_holder.add_child(glow)
	var logo := ArpgUiTheme.logo_texture(620.0)
	logo.position = Vector2(330, 108)
	_logo_holder.add_child(logo)


func _build_title() -> void:
	_title = ArpgUiTheme.make_title("LAS CENIZAS DE LYTHARA", 30, Color("e8d2a4"))
	_title.position = Vector2(0, 346)
	_title.size = Vector2(1280, 40)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)


func _build_narrative() -> void:
	_narrative = ArpgUiTheme.make_body(NARRATIVE_TEXT, 16, Color("c9c2ae"))
	_narrative.position = Vector2(240, 400)
	_narrative.size = Vector2(800, 70)
	_narrative.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_narrative)


func _build_skip_hint() -> void:
	_skip_hint = ArpgUiTheme.make_dim("Toca la pantalla para saltar", 13)
	_skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_skip_hint.position = Vector2(880, 684)
	_skip_hint.size = Vector2(380, 24)
	_skip_hint.modulate.a = 0.0
	add_child(_skip_hint)


func _animate_in() -> void:
	## Aparición: halo y emblema crecen suave, título y narrativa encadenados.
	_logo_holder.modulate.a = 0.0
	_logo_holder.scale = Vector2(0.94, 0.94)
	_logo_holder.pivot_offset = Vector2(640, 220)
	_title.modulate.a = 0.0
	_narrative.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_logo_holder, "modulate:a", 1.0, 1.1)
	tween.tween_property(_logo_holder, "scale", Vector2.ONE, 1.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_title, "modulate:a", 1.0, 0.8).set_delay(0.9)
	tween.tween_property(_narrative, "modulate:a", 1.0, 0.9).set_delay(1.6)
	var hint_tween := create_tween()
	hint_tween.tween_interval(1.0)
	hint_tween.tween_property(_skip_hint, "modulate:a", 0.85, 0.5)

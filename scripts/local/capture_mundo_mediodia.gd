extends SceneTree
## Herramienta local de evidencia (entrega 2026-11-18, mandato §10.8):
## captura del ENTORNO de Valdeluz (afueras integradas en main) a MEDIODÍA
## forzado (set_world_time_hours) para mostrar la escena de mundo disponible
## con iluminación plena, distinta de la toma estándar de la mañana (7:25).
## Uso: godot --path . --script res://scripts/local/capture_mundo_mediodia.gd -- <salida.png> [anchoxalto]

var _frames := 0
var _scene_root: Node = null
var _output := ""
var _resolution := Vector2i(1280, 720)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 1:
		_output = String(args[0])
	if args.size() >= 2:
		var parts := String(args[1]).split("x")
		if parts.size() == 2:
			_resolution = Vector2i(int(parts[0]), int(parts[1]))
	DisplayServer.window_set_size(_resolution)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 5 and _scene_root == null:
		var packed: PackedScene = load("res://scenes/arpg/valdeluz/valdeluz_slice.tscn")
		if packed == null:
			print("CAPTURE_FAILED missing scene")
			return true
		_scene_root = packed.instantiate()
		root.add_child(_scene_root)
		return false

		# Mediodía pleno + clima despejado instantáneo para la vista de entorno.
	if _frames == 45:
		# Mediodía pleno + clima despejado instantáneo para la vista de entorno.
		var env: Node = _scene_root.get_node_or_null("EnvironmentController")
		if env != null:
			if env.has_method("set_world_time_hours"):
				env.set_world_time_hours(12.5)
			if env.has_method("set_weather_by_name"):
				env.set_weather_by_name("clear", true)
			print("MUNDO_MEDIODIA ambiente aplicado")
		else:
			print("MUNDO_MEDIODIA sin EnvironmentController (se usa iluminación por defecto)")
		return false
	if _frames == 100:
		if _output != "":
			var image := root.get_viewport().get_texture().get_image()
			image.save_png(ProjectSettings.globalize_path(_output))
			print("CAPTURED ", _output, " ", image.get_size())
		return true
	return false

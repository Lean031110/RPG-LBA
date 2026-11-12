extends SceneTree
## Herramienta de desarrollo (Fase 3): captura pantallas REALES del juego para la
## verificación visual del HUD (AGENTS.md §10 pide revisión humana de capturas).
## Requiere servidor X (o xvfb); en headless no produce nada útil.
## Uso:
##   godot --path . --script res://scripts/local/capture_hud.gd -- \
##         <escena.tscn> <ancho>x<alto> <salida.png> [inventory]

var _frames := 0
var _scene_path := ""
var _resolution := Vector2i(1280, 720)
var _output := ""
var _open_inventory := false
var _scene_root: Node = null


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 1:
		_scene_path = String(args[0])
	if args.size() >= 2:
		var parts := String(args[1]).split("x")
		if parts.size() == 2:
			_resolution = Vector2i(int(parts[0]), int(parts[1]))
	if args.size() >= 3:
		_output = String(args[2])
	if args.size() >= 4:
		_open_inventory = String(args[3]) == "inventory"
	DisplayServer.window_set_size(_resolution)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 5 and _scene_root == null and _scene_path != "":
		var packed: PackedScene = load(_scene_path)
		if packed == null:
			print("CAPTURE_FAILED missing scene: ", _scene_path)
			return true
		_scene_root = packed.instantiate()
		root.add_child(_scene_root)
		return false
	if _frames == 40 and _open_inventory and _scene_root != null:
		var hud = _scene_root.get("hud")
		var player = _scene_root.get("player")
		if hud != null and player != null:
			player.receive_item("machete_mellado")
			hud.toggle_inventory()
	if _frames == 80:
		if _output != "":
			var image := root.get_viewport().get_texture().get_image()
			image.save_png(ProjectSettings.globalize_path(_output))
			print("CAPTURED ", _output, " ", image.get_size())
		return true
	return false

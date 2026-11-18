extends SceneTree
## Captura de evidencia a nivel de calle para la revision artistica de la capital.
## Reposiciona la PreviewCamera de la escena de la capital a ras de suelo para
## validar iluminacion, sombras, escala humana y edificios singulares.
## Uso: godot --path . --script res://scripts/local/capture_capital_street.gd -- <salida.png>

var _frames := 0
var _scene_root: Node = null
var _output := ""
var _view := "plaza"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 1:
		_output = String(args[0])
	if args.size() >= 2:
		_view = String(args[1])
	DisplayServer.window_set_size(Vector2i(1280, 720))


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 5 and _scene_root == null:
		var packed: PackedScene = load("res://scenes/arpg/valdeluz/valdeluz_capital_preview.tscn")
		if packed == null:
			print("CAPTURE_FAILED missing scene")
			return true
		_scene_root = packed.instantiate()
		root.add_child(_scene_root)
		return false
	if _frames == 30:
		var camera := _scene_root.get_node_or_null("PreviewCamera") as Camera3D
		if camera != null:
			camera.projection = Camera3D.PROJECTION_PERSPECTIVE
			camera.fov = 55.0
			camera.size = 1.0
			if _view == "mercado":
				# Camara al ESTE de los puestos mirando al OESTE: el sol poniente
				# (yaw fijo del juego) queda detras de la camara e ilumina los toldos.
				camera.global_position = Vector3(45.5, 3.1, -12.0)
				camera.look_at(Vector3(35.0, 1.4, -6.0), Vector3.UP)
			else:
				camera.global_position = Vector3(2.5, 1.7, 14.0)
				camera.look_at(Vector3(0.0, 3.2, 0.0), Vector3.UP)
	if _frames == 90:
		if _output != "":
			var image := root.get_viewport().get_texture().get_image()
			image.save_png(ProjectSettings.globalize_path(_output))
			print("CAPTURED ", _output, " ", image.get_size())
		return true
	return false

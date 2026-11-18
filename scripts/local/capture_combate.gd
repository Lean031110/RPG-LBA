extends SceneTree
## Herramienta local de evidencia (entrega 2026-11-18, mandato §10.5):
## captura de COMBATE REAL del slice de Valdeluz. La escena spawnea jugador,
## 3 Sombras de Portal + manadas + Guarapo, HUD y misión VS_P00 tal cual el
## juego. Este script acerca al jugador al enemigo vivo más cercano, lo encara,
## lanza la primera habilidad del kit y captura durante el intercambio.
## Uso: godot --path . --script res://scripts/local/capture_combate.gd -- <salida.png> [anchoxalto]

var _frames := 0
var _scene_root: Node = null
var _output := ""
var _resolution := Vector2i(1280, 720)
var _attacked := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 1:
		_output = String(args[0])
	if args.size() >= 2:
		var parts := String(args[1]).split("x")
		if parts.size() == 2:
			_resolution = Vector2i(int(parts[0]), int(parts[1]))
	DisplayServer.window_set_size(_resolution)


func _nearest_enemy(player: Node3D) -> Node3D:
	var enemies = _scene_root.get("_enemies")
	if enemies == null or not (enemies is Array) or enemies.is_empty():
		return null
	var nearest: Node3D = null
	var best := 1e9
	for e in enemies:
		if e is Node3D and e.has_method("is_dead") and not e.is_dead():
			var d: float = e.global_position.distance_to(player.global_position)
			if d < best:
				best = d
				nearest = e
	return nearest


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

		# Acercar al JUGADOR al spawn del enemigo (así la FSM de la Sombra lo
		# detecta y combate de verdad, como en el juego). 3 m de distancia.
	if _frames == 40:
		var player: Node = _scene_root.get("player")
		var enemy := _nearest_enemy(player)
		if player != null and enemy != null:
			# Acercar al JUGADOR al spawn del enemigo (así la FSM de la Sombra lo
			# detecta y combate de verdad, como en el juego). 3 m de distancia.
			var dir: Vector3 = player.global_position - enemy.global_position
			dir.y = 0.0
			dir = dir.normalized() if dir.length() > 0.01 else Vector3.BACK
			player.global_position = enemy.global_position + dir * 3.0 + Vector3(0, 0.6, 0)
			var look_target: Vector3 = enemy.global_position
			look_target.y = player.global_position.y
			player.look_at(look_target, Vector3.UP)
			print("COMBAT_SETUP jugador llevado al spawn del enemigo")
		else:
			print("COMBAT_SETUP sin jugador o sin enemigos vivos")
		return false
	if _frames == 108 and not _attacked:
		var player: Node = _scene_root.get("player")
		if player != null and player.get("kit") != null:
			player.kit.try_skill_index(0)
			_attacked = true
			print("COMBAT_ATTACK lanzada habilidad 0 del kit")
	if _frames == 124:
		var player: Node = _scene_root.get("player")
		var enemy := _nearest_enemy(player)
		if player != null and enemy != null:
			print(
				"COMBAT_DEBUG dist=",
				player.global_position.distance_to(enemy.global_position),
				" player_hp=",
				player.get("health")
			)
			return false
	if _frames == 130:
		if _output != "":
			var image := root.get_viewport().get_texture().get_image()
			image.save_png(ProjectSettings.globalize_path(_output))
			print("CAPTURED ", _output, " ", image.get_size())
		return true
	return false

class_name PrototypeGround
extends Node3D
## Escenario de pruebas de la Fase 2 (prompt FASE 2 §8): jugador controlable, cámara
## isométrica, HUD táctil y pausa. Sin combate, sin misiones y sin guardado: es una
## base técnica, no contenido del juego (la campaña vive en la vertical slice).

var player: ArpgPlayer = null
var camera_rig: IsoCameraRig = null
var hud: ArpgHUD = null
var pause_overlay: ArpgPauseOverlay = null


func _ready() -> void:
	PrototypeGroundBuilder.build_all(self)
	_spawn_player()
	_build_overlays()
	hud.set_quest_tracker(
		"Prototipo de movimiento — Fase 2",
		["WASD o joystick: mover en ocho direcciones", "Rueda: zoom de cámara", "Esc: pausa"]
	)


func _spawn_player() -> void:
	player = ArpgPlayer.new()
	player.name = "Player"
	add_child(player)
	player.setup("machetero")
	var spawn: Marker3D = get_node("PlayerSpawn")
	player.global_position = spawn.global_position
	camera_rig = IsoCameraRig.new()
	camera_rig.name = "CameraRig"
	add_child(camera_rig)
	camera_rig.setup(player)
	# Fase 2: el movimiento y la esquiva se interpretan en el marco de la cámara.
	player.camera_source = camera_rig
	hud = get_node("HUD")
	hud.bind_player(player)
	hud.joystick_changed.connect(func(vector: Vector2) -> void: player.joystick_vector = vector)


func _build_overlays() -> void:
	pause_overlay = ArpgPauseOverlay.new()
	add_child(pause_overlay)
	pause_overlay.resume_requested.connect(_toggle_pause)
	pause_overlay.exit_requested.connect(_exit_to_menu)


func _unhandled_input(event: InputEvent) -> void:
	if hud != null and hud.is_dialog_open():
		return
	if event.is_action_pressed("arpg_pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	var now_paused := not get_tree().paused
	get_tree().paused = now_paused
	if now_paused:
		pause_overlay.open()
	else:
		pause_overlay.close()


func _exit_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/arpg/menu/main_menu.tscn")

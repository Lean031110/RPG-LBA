class_name IsoCameraRig
extends Node3D
## Cámara isométrica elevada del ARPG (GDD §3: ortográfica primero, 50–58°,
## seguimiento suave, zoom limitado). Sin rotación por controles de movimiento.
## Fase 2: parámetros configurables por instancia sin cambiar el comportamiento
## por defecto de la Fase 1 (mismos valores): ángulo (pitch_degrees), altura/distancia
## (follow_offset), suavidad (follow_smoothing) y límites de zoom.
## Limitación conocida y documentada: sin manejo de oclusión; con el ángulo alto y el
## offset actual el caso es raro. Un SpringArm3D/oclusión se evaluará cuando el arte
## final introduzca interiores o vegetación densa sobre el camino.

@export_range(30.0, 70.0, 0.5) var pitch_degrees := 55.0
## Offset respecto al jugador. Y = altura de cámara; Z = retroceso hacia el jugador
## (distancia en pantalla); X = deriva lateral. La distancia total es |follow_offset|.
@export var follow_offset := Vector3(0.0, 14.5, 10.0)
@export_range(1.0, 30.0, 0.1) var follow_smoothing := 6.5
@export_range(2.0, 20.0, 0.1) var zoom_min := 5.5
@export_range(2.0, 20.0, 0.1) var zoom_max := 10.0
@export_range(0.05, 2.0, 0.05) var zoom_step := 0.6
@export_range(2.0, 20.0, 0.1) var ortho_size := 7.5

var _target: Node3D = null
var _camera: Camera3D = null


func setup(target: Node3D) -> void:
	_target = target
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = ortho_size
	_camera.near = 0.5
	_camera.far = 80.0
	add_child(_camera)
	rotation_degrees = Vector3(-pitch_degrees, 0.0, 0.0)
	if _target != null:
		global_position = _target.global_position + follow_offset


func set_zoom(new_size: float) -> void:
	ortho_size = clampf(new_size, zoom_min, zoom_max)
	if _camera != null:
		_camera.size = ortho_size


func get_camera() -> Camera3D:
	## Acceso para futuras features (shake, transiciones). No usado aún.
	return _camera


func _physics_process(delta: float) -> void:
	if _target == null or _camera == null:
		return
	var desired := _target.global_position + follow_offset
	global_position = global_position.lerp(desired, minf(delta * follow_smoothing, 1.0))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and _camera != null:
		var button := event as InputEventMouseButton
		if button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_zoom(ortho_size - zoom_step)
		elif button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_zoom(ortho_size + zoom_step)

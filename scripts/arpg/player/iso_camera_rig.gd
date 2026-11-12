class_name IsoCameraRig
extends Node3D
## Cámara isométrica elevada de la vertical slice (GDD §3: ortográfica primero,
## 50–58°, seguimiento suave, zoom limitado). Sin rotación en la primera versión.

const FOLLOW_LERP := 6.5
const PITCH_DEGREES := 55.0
const OFFSET := Vector3(0, 14.5, 10.0)
const ZOOM_MIN := 5.5
const ZOOM_MAX := 10.0
const ZOOM_STEP := 0.6
const DEFAULT_ORTHO_SIZE := 7.5

var ortho_size := DEFAULT_ORTHO_SIZE
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
	rotation_degrees = Vector3(-PITCH_DEGREES, 0.0, 0.0)
	if _target != null:
		global_position = _target.global_position + OFFSET


func set_zoom(new_size: float) -> void:
	ortho_size = clampf(new_size, ZOOM_MIN, ZOOM_MAX)
	if _camera != null:
		_camera.size = ortho_size


func _physics_process(delta: float) -> void:
	if _target == null or _camera == null:
		return
	var desired := _target.global_position + OFFSET
	global_position = global_position.lerp(desired, minf(delta * FOLLOW_LERP, 1.0))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and _camera != null:
		var button := event as InputEventMouseButton
		if button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_zoom(ortho_size - ZOOM_STEP)
		elif button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_zoom(ortho_size + ZOOM_STEP)

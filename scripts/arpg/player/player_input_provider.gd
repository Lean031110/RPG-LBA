class_name PlayerInputProvider
extends RefCounted
## Entrada del jugador separada de la lógica del personaje (requisito Fase 5:
## "Separa la entrada del jugador de la lógica interna"). Reúne teclado y
## joystick virtual, normaliza diagonales y proyecta al marco de la cámara.
## Así se pueden cambiar los controles sin reescribir el combate.

var camera_source: Node3D = null
var joystick_vector := Vector2.ZERO


func raw_input() -> Vector3:
	## Entrada combinada SIN normalizar: su magnitud separa caminar de correr.
	var keyboard := Vector3(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		0,
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)
	return keyboard + Vector3(joystick_vector.x, 0, joystick_vector.y)


func direction() -> Vector3:
	## Dirección de movimiento en XZ: diagonal normalizada y en el marco de la
	## cámara. Sin cámara asignada (tests, escenas mínimas) es el eje mundial.
	var combined := raw_input()
	if combined.length() > 1.0:
		combined = combined.normalized()
	return to_camera_space(combined)


func to_camera_space(direction: Vector3) -> Vector3:
	## Proyecta la base de la cámara al plano XZ. Pitch no afecta (se aplana).
	if camera_source == null or not is_instance_valid(camera_source):
		return direction
	var basis := camera_source.global_transform.basis
	var right := Vector3(basis.x.x, 0.0, basis.x.z)
	var back := Vector3(basis.z.x, 0.0, basis.z.z)
	if right.length_squared() < 0.001 or back.length_squared() < 0.001:
		return direction
	return right.normalized() * direction.x + back.normalized() * direction.z

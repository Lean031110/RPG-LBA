# gdlint: ignore=max-public-methods
class_name BrujaPuppet
extends ClassPuppet
## Marioneta procedural de la Bruja de la Manigua (Fase 2): tunica conica de
## tonos verde manigua, cabeza con panuelo y el Orbe de Esencia flotando en
## orbita — su "arma" visible. Misma interfaz que el resto de clases; la
## animacion es procedural pura (sin AnimationPlayer todavia).

const WALK_SMOOTH := 0.15
const ORBE_HEIGHT := 1.45
const ORBE_RADIUS := 0.55

var _parts := {}
var _walk_phase := 0.0
var _run_blend := 0.0
var _orbe_angle := 0.0
var _cast_left := 0.0
var _orbe_material: StandardMaterial3D = null


func _ready() -> void:
	_build()


func animate_walk(phase: float, run_blend: float) -> void:
	## Ciclo caminar/correr: balanceo suave de la tunica y del panuelo.
	_run_blend = run_blend
	var swing := sin(phase) * lerpf(0.18, 0.3, _run_blend)
	var root := _parts["root"] as Node3D
	root.rotation.z = lerpf(root.rotation.z, swing * 0.4, WALK_SMOOTH)
	root.position.y = absf(sin(phase)) * 0.04 * lerpf(0.6, 1.0, _run_blend)
	var tunic := _parts["tunica"] as Node3D
	tunic.rotation.x = lerpf(tunic.rotation.x, 0.12 * _run_blend, WALK_SMOOTH)
	(_parts["panuelo"] as Node3D).rotation.z = lerpf(
		(_parts["panuelo"] as Node3D).rotation.z, -swing * 0.8, WALK_SMOOTH
	)
	_walk_phase = phase


func animate_idle(delta: float) -> void:
	## Reposo: la tunica se aquieta y el orbe baja a su altura de escucha
	## (la manigua responde al reposo: pasiva Oido de la Manigua).
	var root := _parts["root"] as Node3D
	root.rotation.z = lerpf(root.rotation.z, 0.0, WALK_SMOOTH)
	root.position.y = lerpf(root.position.y, 0.0, WALK_SMOOTH)
	(_parts["tunica"] as Node3D).rotation.x = lerpf((_parts["tunica"] as Node3D).rotation.x, 0.0, WALK_SMOOTH)
	(_parts["panuelo"] as Node3D).rotation.z = lerpf(
		(_parts["panuelo"] as Node3D).rotation.z, sin(_walk_phase + delta * 2.0) * 0.05, WALK_SMOOTH
	)
	_orbit_orbe(delta, ORBE_HEIGHT)


func animate_combat_state(delta: float, state: Dictionary) -> void:
	## Estados de la bruja: lanzar (windup recoge el orbe; activa lo proyecta),
	## esquiva (el orbe se pega al cuerpo) y reposo.
	_orbit_orbe(delta, ORBE_HEIGHT + (0.25 if bool(state.get("dodging", false)) else 0.0))
	var casting := bool(state.get("busy", false)) and String(state.get("phase", "")) != "recover"
	if casting:
		_cast_left = 0.45
	if _cast_left > 0.0:
		_cast_left = maxf(_cast_left - delta, 0.0)
		var tunic := _parts["tunica"] as Node3D
		tunic.rotation.x = lerpf(tunic.rotation.x, -0.22, 0.25)
		(_parts["brazo"] as Node3D).rotation.x = lerpf((_parts["brazo"] as Node3D).rotation.x, -1.1, 0.3)
	else:
		(_parts["brazo"] as Node3D).rotation.x = lerpf((_parts["brazo"] as Node3D).rotation.x, 0.0, WALK_SMOOTH)


func play_death() -> void:
	## Caida: la tunica se pliega y el orbe se apaga.
	var root := _parts["root"] as Node3D
	root.rotation.x = 1.35
	root.position.y = -0.25
	if _orbe_material != null:
		_orbe_material.emission_energy_multiplier = 0.0


func reset_pose() -> void:
	var root := _parts["root"] as Node3D
	root.rotation = Vector3.ZERO
	root.position = Vector3.ZERO
	(_parts["tunica"] as Node3D).rotation = Vector3.ZERO
	(_parts["brazo"] as Node3D).rotation = Vector3.ZERO
	(_parts["panuelo"] as Node3D).rotation = Vector3.ZERO
	if _orbe_material != null:
		_orbe_material.emission_energy_multiplier = 1.6


func set_blade_glow(active: bool) -> void:
	## El orbe arde mas intenso cuando el equipo otorga potencia arcana.
	if _orbe_material != null:
		_orbe_material.emission_energy_multiplier = 2.6 if active else 1.6


func _orbit_orbe(delta: float, height: float) -> void:
	## El Orbe de Esencia orbita lento alrededor de la bruja.
	_orbe_angle += delta * 1.4
	var orbe := _parts["orbe"] as Node3D
	orbe.position = Vector3(
		cos(_orbe_angle) * ORBE_RADIUS, height + sin(_orbe_angle * 2.0) * 0.08, sin(_orbe_angle) * ORBE_RADIUS
	)


func _build() -> void:
	## Montaje procedural: paleta verde manigua + crema de la direccion
	## artistica (VALDELUZ_WORLD_ART_BIBLE: yesos y vegetacion de la manigua).
	var root := Node3D.new()
	root.name = "BrujaRoot"
	add_child(root)
	_parts["root"] = root

	var tunic_material := StandardMaterial3D.new()
	tunic_material.albedo_color = Color(0.16, 0.34, 0.24)
	var tunic := MeshInstance3D.new()
	tunic.name = "Tunica"
	var tunic_mesh := CylinderMesh.new()
	tunic_mesh.top_radius = 0.22
	tunic_mesh.bottom_radius = 0.42
	tunic_mesh.height = 1.25
	tunic_mesh.material = tunic_material
	tunic.mesh = tunic_mesh
	tunic.position = Vector3(0, 0.62, 0)
	root.add_child(tunic)
	_parts["tunica"] = tunic

	var head := MeshInstance3D.new()
	head.name = "Cabeza"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.19
	head_mesh.height = 0.38
	var head_material := StandardMaterial3D.new()
	head_material.albedo_color = Color(0.62, 0.47, 0.36)
	head_mesh.material = head_material
	head.mesh = head_mesh
	head.position = Vector3(0, 1.36, 0)
	root.add_child(head)
	_parts["cabeza"] = head

	var panuelo := MeshInstance3D.new()
	panuelo.name = "Panuelo"
	var panuelo_mesh := BoxMesh.new()
	panuelo_mesh.size = Vector3(0.34, 0.1, 0.34)
	var panuelo_material := StandardMaterial3D.new()
	panuelo_material.albedo_color = Color(0.72, 0.24, 0.3)
	panuelo_mesh.material = panuelo_material
	panuelo.mesh = panuelo_mesh
	panuelo.position = Vector3(0, 1.5, 0)
	root.add_child(panuelo)
	_parts["panuelo"] = panuelo

	var brazo := MeshInstance3D.new()
	brazo.name = "BrazoDeLanzar"
	var brazo_mesh := BoxMesh.new()
	brazo_mesh.size = Vector3(0.11, 0.5, 0.11)
	var brazo_material := StandardMaterial3D.new()
	brazo_material.albedo_color = Color(0.62, 0.47, 0.36)
	brazo_mesh.material = brazo_material
	brazo.mesh = brazo_mesh
	brazo.position = Vector3(0.3, 1.05, 0)
	root.add_child(brazo)
	_parts["brazo"] = brazo

	var orbe := MeshInstance3D.new()
	orbe.name = "OrbeEsencia"
	var orbe_mesh := SphereMesh.new()
	orbe_mesh.radius = 0.13
	orbe_mesh.height = 0.26
	_orbe_material = StandardMaterial3D.new()
	_orbe_material.albedo_color = Color(0.42, 0.85, 0.55)
	_orbe_material.emission_enabled = true
	_orbe_material.emission = Color(0.35, 0.8, 0.45)
	_orbe_material.emission_energy_multiplier = 1.6
	orbe_mesh.material = _orbe_material
	orbe.mesh = orbe_mesh
	orbe.position = Vector3(ORBE_RADIUS, ORBE_HEIGHT, 0)
	root.add_child(orbe)
	_parts["orbe"] = orbe

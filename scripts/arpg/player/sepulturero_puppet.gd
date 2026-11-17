# gdlint: ignore=max-public-methods
class_name SepultureroPuppet
extends ClassPuppet
## Marioneta procedural del Sepulturero de Guanabacoa (Fase 2): silueta de
## camposanto criollo — sombrero de yarey de ala ancha, ropa de trabajo de
## piedra y el FAROL DE CENIZA como arma visible (la llama ambar cuelga de su
## mano, como el orbe de la Bruja o el machete del Machetero). Misma interfaz
## que el resto de clases; animacion procedural pura.

const WALK_SMOOTH := 0.15
const FAROL_HEIGHT := 0.95
const FAROL_RADIUS := 0.5
const FAROL_SWING := 0.35

var _parts := {}
var _walk_phase := 0.0
var _run_blend := 0.0
var _cast_left := 0.0
var _farol_angle := 0.0
var _farol_material: StandardMaterial3D = null
var _flame_material: StandardMaterial3D = null


func _ready() -> void:
	_build()


func animate_walk(phase: float, run_blend: float) -> void:
	## Ciclo caminar/correr: paso sobrio de camposanto; el farol acompania el
	## paso sin brusquedades (el Sepulturero no corre: se mueve con proposito).
	_run_blend = run_blend
	var swing := sin(phase) * lerpf(0.10, 0.18, _run_blend)
	var root := _parts["root"] as Node3D
	root.rotation.z = lerpf(root.rotation.z, swing * 0.35, WALK_SMOOTH)
	root.position.y = absf(sin(phase)) * 0.03 * lerpf(0.6, 1.0, _run_blend)
	(_parts["tunica"] as Node3D).rotation.x = lerpf(
		(_parts["tunica"] as Node3D).rotation.x, 0.08 * _run_blend, WALK_SMOOTH
	)
	_farol_angle = swing * FAROL_SWING
	(_parts["brazo_farol"] as Node3D).rotation.z = _farol_angle * 0.6
	_walk_phase = phase


func animate_idle(delta: float) -> void:
	## Reposo: la ropa se aquieta; el farol cuelga y la llama respira lento
	## (los muertos esperan: el Sepulturero tambien).
	var root := _parts["root"] as Node3D
	root.rotation.z = lerpf(root.rotation.z, 0.0, WALK_SMOOTH)
	root.position.y = lerpf(root.position.y, 0.0, WALK_SMOOTH)
	(_parts["tunica"] as Node3D).rotation.x = lerpf((_parts["tunica"] as Node3D).rotation.x, 0.0, WALK_SMOOTH)
	(_parts["brazo_farol"] as Node3D).rotation.z = lerpf(
		(_parts["brazo_farol"] as Node3D).rotation.z, sin(_walk_phase + delta * 1.6) * 0.05, WALK_SMOOTH
	)
	if _flame_material != null:
		_flame_material.emission_energy_multiplier = 0.85 + sin(_walk_phase + delta * 2.2) * 0.15


func animate_combat_state(delta: float, state: Dictionary) -> void:
	## Estados del Sepulturero: lanzar (alza el farol: la luz llama a los
	## ecos), esquiva (el farol se pegа al cuerpo) y reposo.
	if bool(state.get("dodging", false)):
		(_parts["brazo_farol"] as Node3D).rotation.x = lerpf((_parts["brazo_farol"] as Node3D).rotation.x, -0.5, 0.3)
		if _flame_material != null:
			_flame_material.emission_energy_multiplier = 1.3
		return
	var casting := bool(state.get("busy", false)) and String(state.get("phase", "")) != "recover"
	if casting:
		_cast_left = 0.4
	if _cast_left > 0.0:
		_cast_left = maxf(_cast_left - delta, 0.0)
		(_parts["brazo_farol"] as Node3D).rotation.x = lerpf((_parts["brazo_farol"] as Node3D).rotation.x, -1.25, 0.3)
		if _flame_material != null:
			_flame_material.emission_energy_multiplier = 1.6
	else:
		(_parts["brazo_farol"] as Node3D).rotation.x = lerpf(
			(_parts["brazo_farol"] as Node3D).rotation.x, 0.0, WALK_SMOOTH
		)


func play_death() -> void:
	## Caida: el sombrero cae sobre el rostro y el farol se APAGA (sin llama no
	## hay ecos: la escena cuenta la regla).
	var root := _parts["root"] as Node3D
	root.rotation.x = 1.30
	root.position.y = -0.22
	if _flame_material != null:
		_flame_material.emission_energy_multiplier = 0.0
	if _farol_material != null:
		_farol_material.emission_energy_multiplier = 0.0


func reset_pose() -> void:
	var root := _parts["root"] as Node3D
	root.rotation = Vector3.ZERO
	root.position = Vector3.ZERO
	(_parts["tunica"] as Node3D).rotation.x = 0.0
	(_parts["brazo_farol"] as Node3D).rotation = Vector3.ZERO
	if _flame_material != null:
		_flame_material.emission_energy_multiplier = 0.85


func set_blade_glow(active: bool) -> void:
	## El equipo otorga potencia: la llama del farol arde mas viva.
	if _flame_material == null:
		return
	_flame_material.emission_energy_multiplier = 1.8 if active else 0.85


# ---------------------------------------------------------------------------
# Montaje (silueta propia: sombrero ancho + farol; paleta ceniza y hueso)
# ---------------------------------------------------------------------------


func _build() -> void:
	var root := Node3D.new()
	root.name = "RaizSepulturero"
	add_child(root)
	_parts["root"] = root
	# Paleta: piedra apagada, hueso marfil, ambar de ceniza. Nada de verde
	# manigua (Bruja) ni acero de machete (Machetero): el Sepulturero es gris
	# de camposanto con una sola llama.
	var stone := VisualKit.flat_material(Color(0.29, 0.30, 0.34))
	var bone := VisualKit.flat_material(Color(0.80, 0.76, 0.68))
	var straw_dark := VisualKit.flat_material(Color(0.42, 0.35, 0.24))
	# Torso: tunica recta de trabajo (no conica como la de la Bruja).
	var tunica := VisualKit.add_cylinder(root, 0.30, 0.92, Vector3(0, 0.72, 0), stone, 10)
	_parts["tunica"] = tunica
	# Cinturon de cuero + placa de hueso (gremio de sepultureros).
	VisualKit.add_cylinder(root, 0.315, 0.09, Vector3(0, 0.62, 0), VisualKit.flat_material(VisualKit.MAT_BOOT), 10)
	VisualKit.add_box(root, Vector3(0.10, 0.14, 0.03), Vector3(0, 0.62, 0.30), bone)
	# Cabeza bajo el sombrero.
	VisualKit.add_sphere(root, 0.17, Vector3(0, 1.34, 0.02), VisualKit.flat_material(VisualKit.MAT_SKIN))
	# Sombrero de yarey: copa + ala MUY ancha (silueta inconfundible).
	VisualKit.add_cylinder(root, 0.16, 0.16, Vector3(0, 1.52, 0), straw_dark, 10)
	VisualKit.add_cylinder(root, 0.52, 0.035, Vector3(0, 1.47, 0), straw_dark, 14)
	# Brazos: el derecho cuelga; el izquierdo porta el farol.
	VisualKit.add_cylinder(root, 0.07, 0.42, Vector3(0.32, 0.86, 0.0), stone, 6).rotation.z = -0.15
	var brazo := VisualKit.add_cylinder(root, 0.06, 0.40, Vector3(-0.30, 0.92, 0.02), stone, 6)
	brazo.rotation.z = 0.35
	_parts["brazo_farol"] = brazo
	# Farol de ceniza: jaula de hueso con llama ambar. Arma visible de la clase.
	_farol_material = VisualKit.flat_material(Color(0.85, 0.82, 0.74), Color(0.55, 0.58, 0.66), 0.35)
	var farol := Node3D.new()
	farol.name = "Farol"
	root.add_child(farol)
	farol.position = Vector3(-0.42, FAROL_HEIGHT, 0.06)
	VisualKit.add_cylinder(farol, 0.10, 0.02, Vector3(0, 0.16, 0), _farol_material, 8)
	VisualKit.add_cylinder(farol, 0.115, 0.20, Vector3(0, 0.05, 0), _farol_material, 8)
	VisualKit.add_cylinder(farol, 0.10, 0.02, Vector3(0, -0.06, 0), _farol_material, 8)
	_flame_material = VisualKit.flat_material(Color(1.0, 0.72, 0.35), Color(1.0, 0.62, 0.22), 0.85)
	VisualKit.add_sphere(farol, 0.055, Vector3(0, 0.05, 0), _flame_material)
	_parts["farol"] = farol

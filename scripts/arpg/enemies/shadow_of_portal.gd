class_name ShadowOfPortal
extends ArpgEnemy
## Especie: Sombra de Portal (monstruario canon §8). Comportamiento base de la
## FSM (detectar → perseguir → telegráfico carmesí → golpe → recuperar) sin
## extras: es el enemigo "honesto" de la rebanada. Toda la lógica de combate
## vive en ArpgEnemy/ArpgCombatant; aquí solo la identidad visual y el pulso
## del telegráfico que la hizo legible desde la Fase 1.

const BODY_WOBBLE_SPEED := 2.0
const EMBER_BASE := 1.8

var _puppet: Node3D = null
var _body_mesh: MeshInstance3D = null
var _eye_l: MeshInstance3D = null
var _eye_r: MeshInstance3D = null
var _wobble_phase := 0.0


func _build_visual() -> void:
	_puppet = Node3D.new()
	_puppet.name = "ShadowPuppet"
	add_child(_puppet)
	var body_mat := VisualKit.noise_material(VisualKit.MAT_SHADOW_BODY, 0.4, 4)
	var rim_mat := VisualKit.flat_material(VisualKit.MAT_SHADOW_RIM)
	# Cuerpo alargado: silueta inquietante de 2.2 m.
	_body_mesh = VisualKit.add_cylinder(_puppet, 0.34, 1.5, Vector3(0, 1.35, 0), body_mat, 8)
	VisualKit.add_sphere(_puppet, 0.26, Vector3(0, 2.15, 0), body_mat)
	# Faldón desgastado (cono invertido bajo el cuerpo).
	VisualKit.add_cone(_puppet, 0.62, 0.9, Vector3(0, 0.45, 0), rim_mat).rotation_degrees.x = 180.0
	# Brazos colgantes largos.
	VisualKit.add_cylinder(_puppet, 0.09, 1.0, Vector3(-0.42, 1.35, 0.05), body_mat, 6).rotation_degrees.z = 14.0
	VisualKit.add_cylinder(_puppet, 0.09, 1.0, Vector3(0.42, 1.35, 0.05), body_mat, 6).rotation_degrees.z = -14.0
	# Ojos ámbar: foco de lectura del enemigo (carmesí = peligro en el windup).
	_eye_l = VisualKit.add_sphere(
		_puppet,
		0.07,
		Vector3(-0.09, 2.18, 0.2),
		VisualKit.flat_material(VisualKit.MAT_EYE_AMBER, VisualKit.MAT_EYE_AMBER, 2.2)
	)
	_eye_r = VisualKit.add_sphere(
		_puppet,
		0.07,
		Vector3(0.09, 2.18, 0.2),
		VisualKit.flat_material(VisualKit.MAT_EYE_AMBER, VisualKit.MAT_EYE_AMBER, 2.2)
	)
	# Capa de filo frío (Art Pass 4B): borde tenue contra el fondo verde.
	var shell_mat := VisualKit.flat_material(VisualKit.MAT_SHADOW_RIM, Color(0.16, 0.2, 0.32), 0.28)
	var shell := VisualKit.add_cylinder(_puppet, 0.37, 1.42, Vector3(0, 1.36, 0), shell_mat, 8)
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Jirones colgantes bajo el faldón con el shader de viento.
	var tatter_mat := ArpgArtKit.wind_material(Color(0.05, 0.06, 0.09), 0.16, 2.4)
	for index: int in 3:
		var angle := TAU * float(index) / 3.0 + 0.6
		var tatter := VisualKit.add_box(
			_puppet, Vector3(0.1, 0.5, 0.02), Vector3(cos(angle) * 0.42, 0.55, sin(angle) * 0.42), tatter_mat
		)
		tatter.rotation_degrees.y = -rad_to_deg(angle)
	# Bruma de suelo: disco oscuro translúcido que asienta la silueta.
	var haze_material := StandardMaterial3D.new()
	haze_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	haze_material.albedo_color = Color(0.03, 0.04, 0.07, 0.38)
	haze_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var haze := VisualKit.add_cylinder(_puppet, 0.75, 0.02, Vector3(0, 0.03, 0), haze_material, 16)
	haze.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _animate(delta: float) -> void:
	## Ondulación de reposo: la silueta nunca está quieta del todo.
	_wobble_phase += delta
	if state == InternalState.DEAD:
		return
	var wobble := sin(_wobble_phase * BODY_WOBBLE_SPEED) * 0.05
	if _body_mesh != null:
		_body_mesh.position = Vector3(0, 1.35 + wobble, 0)
	if _eye_l != null and state != InternalState.WINDUP and state != InternalState.STRIKE:
		var ember := EMBER_BASE + sin(_wobble_phase * 3.0) * 0.5
		VisualKit.set_emission(_eye_l, VisualKit.MAT_EYE_AMBER, ember)
		VisualKit.set_emission(_eye_r, VisualKit.MAT_EYE_AMBER, ember)


func _visual_telegraph(progress: float) -> void:
	## Pulso carmesí creciente durante el windup: área, tiempo y severidad.
	if _eye_l == null or _eye_r == null:
		return
	var telegraph_color := Color(0.76, 0.12, 0.19)
	var energy := 0.6 + progress * 2.4
	VisualKit.set_emission(_eye_l, telegraph_color, energy)
	VisualKit.set_emission(_eye_r, telegraph_color, energy)
	if _body_mesh != null:
		var body_mat := _body_mesh.material_override as StandardMaterial3D
		if body_mat != null:
			body_mat.emission_enabled = true
			body_mat.emission = telegraph_color
			body_mat.emission_energy_multiplier = progress * 0.9
		_body_mesh.scale = Vector3.ONE * (1.0 + progress * 0.06)


func _strike_visual_start() -> void:
	## La embestida de la sombra: salto corto hacia delante durante la ventana.
	var lunge := float(enemy_data.get("lunge_distance", 1.4))
	var window := maxf(float(enemy_data.get("attack_window", 0.25)), 0.05)
	var forward := transform.basis.z
	velocity.x = forward.x * (lunge / window)
	velocity.z = forward.z * (lunge / window)


func _visual_root() -> Node3D:
	return _puppet

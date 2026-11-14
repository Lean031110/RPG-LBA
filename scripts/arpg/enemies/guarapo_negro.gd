class_name GuarapoNegro
extends ArpgEnemy
## Especie: Guarapo negro (monstruario canon §8). Masa de caña y resina que se
## arrastra por los centrales: LENTO y pesado, con golpe de área que empuja y
## deja una trampa de resina (ralentización real por estado alterado) en quien
## golpea. Es el enemigo tanque de la zona: no rodea, no huye, pisa.

const BODY_SQUASH := 0.12

var _puppet: Node3D = null
var _body_mesh: MeshInstance3D = null
var _creep_phase := 0.0


func _build_visual() -> void:
	## Masa viscosa: bulto oscuro brillante (resina de caña) con juncos secos.
	_puppet = Node3D.new()
	_puppet.name = "BlackSyrupPuppet"
	add_child(_puppet)
	var resin_mat := VisualKit.noise_material(Color(0.09, 0.07, 0.05), 0.5, 6)
	resin_mat.emission_enabled = true
	resin_mat.emission = Color(0.28, 0.16, 0.04)
	resin_mat.emission_energy_multiplier = 0.25
	# Cuerpo: esfera achatada y deformada (masa que se arrastra).
	_body_mesh = VisualKit.add_sphere(_puppet, 0.85, Vector3(0, 0.75, 0), resin_mat)
	_body_mesh.scale = Vector3(1.25, 0.72, 1.1)
	# Juncos de caña clavados en la masa.
	var cane_mat := VisualKit.flat_material(Color(0.45, 0.4, 0.24))
	for index: int in 5:
		var angle := TAU * float(index) / 5.0 + 0.35
		var cane := VisualKit.add_cylinder(
			_puppet, 0.045, 1.1, Vector3(cos(angle) * 0.5, 1.15, sin(angle) * 0.45), cane_mat, 5
		)
		cane.rotation_degrees = Vector3(randf_range(-14, 14), 0, randf_range(-14, 14))
	# Charco de resina bajo la masa.
	var pool_mat := StandardMaterial3D.new()
	pool_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pool_mat.albedo_color = Color(0.07, 0.05, 0.03, 0.55)
	pool_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var pool := VisualKit.add_cylinder(_puppet, 1.15, 0.03, Vector3(0, 0.04, 0), pool_mat, 14)
	pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _animate(delta: float) -> void:
	if state == InternalState.DEAD:
		return
	## Arrastre viscoso: la masa late y se estira en la dirección del avance.
	_creep_phase += delta * 1.6
	if _body_mesh != null:
		var pulse := 1.0 + sin(_creep_phase) * 0.05
		_body_mesh.scale = Vector3(1.25 * pulse, 0.72 / pulse, 1.1 * pulse)


func _strike_visual_start() -> void:
	## El golpe del guarapo: se hincha y revienta en área alrededor.
	if _body_mesh == null or _puppet == null:
		return
	var tween := create_tween()
	tween.tween_property(_body_mesh, "scale", Vector3(1.55, 0.9, 1.35), 0.14)
	tween.tween_property(_body_mesh, "scale", Vector3(1.25, 0.72, 1.1), 0.2)


func _visual_telegraph(progress: float) -> void:
	## Telégrafo: la resina brilla más cuanto más cerca está el golpe.
	if _body_mesh == null:
		return
	var body_mat := _body_mesh.material_override as StandardMaterial3D
	if body_mat == null:
		return
	body_mat.emission_energy_multiplier = 0.25 + progress * 1.6
	_body_mesh.scale = Vector3(
		1.25 + progress * BODY_SQUASH * 2.0, 0.72 - progress * BODY_SQUASH, 1.1 + progress * BODY_SQUASH * 2.0
	)


func _visual_root() -> Node3D:
	return _puppet

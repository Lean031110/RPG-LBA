class_name ArpgArtKit
extends RefCounted
## Kit del Art Pass de Valdeluz (Fase 4B). Contenido 100% original y procedural:
## cero riesgo de licencia; los intentos de descarga de assets externos quedan
## documentados en docs/reportes/FASE_04B_ART_PASS.md (entorno sin acceso viable).
##
## - Materiales de shader (viento / humedad / hierro envejecido) para el Compatibility
##   Renderer: solo desplazamiento de vértices y mezclas en fragment; sin efectos
##   que el renderer no soporte (sin GI dinámica, sin volumétricos).
## - VFX de combate de un solo uso (chispas, polvo, estela del machete) con
##   CPUParticles3D y destrucción automática. La lógica de juego no cambia:
##   estos helpers solo añaden nodos visuales.

const WIND_SHADER := preload("res://assets/art/shaders/wind_sway.gdshader")
const WET_SHADER := preload("res://assets/art/shaders/wet_surface.gdshader")
const IRON_SHADER := preload("res://assets/art/shaders/worn_iron.gdshader")

# ---------------------------------------------------------------------------
# Materiales
# ---------------------------------------------------------------------------


static func wind_material(base_color: Color, strength := 0.05, speed := 1.6) -> ShaderMaterial:
	## Vegetación que se mece; la fase sale de la posición mundial (MODEL_MATRIX),
	## así una sola instancia del material sirve para toda la manigua.
	var material := ShaderMaterial.new()
	material.shader = WIND_SHADER
	material.set_shader_parameter("base_color", base_color)
	material.set_shader_parameter("strength", strength)
	material.set_shader_parameter("speed", speed)
	return material


static func wet_material(base_color: Color, rough := 0.9) -> ShaderMaterial:
	## Charcas y piedra mojada: brillo de fresnel en ángulos rasantes.
	var material := ShaderMaterial.new()
	material.shader = WET_SHADER
	material.set_shader_parameter("base_color", base_color)
	material.set_shader_parameter("rough", rough)
	return material


static func worn_iron_material() -> ShaderMaterial:
	## Hierro forjado con óxido procedimental (faroles, ruedas, herrajes).
	var material := ShaderMaterial.new()
	material.shader = IRON_SHADER
	return material


# ---------------------------------------------------------------------------
# VFX de un solo uso (CPUParticles3D + autodestrucción)
# ---------------------------------------------------------------------------


static func hit_spark(parent: Node, at: Vector3, color := Color(1.0, 0.85, 0.5)) -> void:
	## Chispas del impacto (visuales; el daño ya lo aplicó la lógica de juego).
	var particles := _burst(parent, at, color, 14, 0.32, 3.5, 6.5, Vector3(0, -6, 0), 0.10)
	particles.spread = 180.0


static func dust_burst(parent: Node, at: Vector3) -> void:
	## Polvo rojo de Valdeluz al esquivar o aterrizar.
	var particles := _burst(parent, at, Color(0.55, 0.36, 0.25), 10, 0.45, 1.2, 2.4, Vector3(0, -1.5, 0), 0.16)
	particles.spread = 70.0


static func slash_trail(parent: Node, from: Vector3, to: Vector3) -> void:
	## Estela del tajo: un quad estirado del hombro al alcance del golpe, alineado
	## con la dirección del swing, que se desvanece rápido. Barato: un mesh + tween.
	var puppet := Node3D.new()
	puppet.name = "SlashTrail"
	parent.add_child(puppet)
	var mesh := MeshInstance3D.new()
	var quad := QuadMesh.new()
	var length := maxf(from.distance_to(to), 0.6)
	quad.size = Vector2(0.34, length)
	mesh.mesh = quad
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.95, 0.9, 0.75, 0.55)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = material
	puppet.add_child(mesh)
	var dir := (to - from).normalized()
	var up := Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.9 else Vector3.FORWARD
	var right := dir.cross(up).normalized()
	# Columnas: X = right (ancho), Y = dir (eje largo del quad), Z = normal del plano.
	var basis := Basis(right, dir, right.cross(dir))
	mesh.global_transform = Transform3D(basis, (from + to) / 2.0)
	var tween := puppet.create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, 0.18)
	tween.chain().tween_callback(puppet.queue_free)


static func _burst(
	parent: Node,
	at: Vector3,
	color: Color,
	amount: int,
	lifetime: float,
	velocity_min: float,
	velocity_max: float,
	gravity: Vector3,
	particle_scale: float
) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.name = "VFXBurst"
	particles.one_shot = true
	particles.amount = amount
	particles.lifetime = lifetime
	particles.explosiveness = 1.0
	particles.initial_velocity_min = velocity_min
	particles.initial_velocity_max = velocity_max
	particles.gravity = gravity
	particles.scale_amount_min = particle_scale * 0.6
	particles.scale_amount_max = particle_scale * 1.4
	particles.position = at
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.09, 0.09)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mesh.material = material
	particles.mesh = mesh
	parent.add_child(particles)
	particles.emitting = true
	# Autodestrucción: doble seguro (finished + temporizador).
	particles.finished.connect(particles.queue_free)
	var tree := parent.get_tree() if parent != null else null
	if tree != null:
		var timer := tree.create_timer(lifetime + 0.6)
		timer.timeout.connect(
			func() -> void:
				if is_instance_valid(particles):
					particles.queue_free()
		)
	return particles

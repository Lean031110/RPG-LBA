# gdlint: ignore=max-public-methods
# (La marioneta expone un método de animación por estado; son presentación pura.)
class_name MacheteroPuppet
extends ClassPuppet
## Marioneta procedural del Machetero de la Sierra (Fase 5): TODO el montaje
## visual y su animación viven aquí, separados de la lógica del jugador
## (requisito del prompt: sistemas de estado y presentación desacoplados).
## El jugador llama a los métodos de animación; la marioneta NO conoce combate,
## vida ni recursos. Preparada para sustituir el montaje por modelos animados
## (AnimationPlayer) sin tocar ArpgPlayer: misma interfaz.

const WALK_SMOOTH := 0.15

var _parts := {}
var _walk_phase := 0.0
var _run_blend := 0.0


func _ready() -> void:
	_build()


func animate_walk(phase: float, run_blend: float) -> void:
	## Ciclo compartido caminar/correr: la amplitud escala con la mezcla de
	## carrera; la frecuencia la controla el jugador con su velocidad real.
	_run_blend = run_blend
	var swing := sin(phase) * lerpf(0.55, 0.88, _run_blend)
	(_parts["root"] as Node3D).rotation.x = lerpf((_parts["root"] as Node3D).rotation.x, 0.14 * _run_blend, WALK_SMOOTH)
	(_parts["root"] as Node3D).position.y = (absf(sin(phase)) * 0.05 * lerpf(0.6, 1.0, _run_blend))
	(_parts["leg_l"] as Node3D).rotation.x = swing
	(_parts["leg_r"] as Node3D).rotation.x = -swing
	(_parts["arm_l"] as Node3D).rotation.x = -swing * (0.7 + 0.25 * _run_blend)
	(_parts["arm_r"] as Node3D).rotation.x = -swing * (0.7 + 0.25 * _run_blend)


func animate_idle(delta: float) -> void:
	_walk_phase += delta * 1.6
	var breathe := sin(_walk_phase) * 0.04
	var root := _parts["root"] as Node3D
	root.rotation.x = lerpf(root.rotation.x, 0.0, WALK_SMOOTH)
	root.position.y = lerpf(root.position.y, 0.0, 0.2)
	(_parts["leg_l"] as Node3D).rotation.x = lerp_angle((_parts["leg_l"] as Node3D).rotation.x, 0.0, 0.2)
	(_parts["leg_r"] as Node3D).rotation.x = lerp_angle((_parts["leg_r"] as Node3D).rotation.x, 0.0, 0.2)
	(_parts["arm_l"] as Node3D).rotation.x = breathe
	(_parts["arm_r_free"] as Node3D).rotation.x = breathe


func animate_block(delta: float) -> void:
	## Postura de guardia: machete en alto y brazo izquierdo cubriendo.
	(_parts["arm_r"] as Node3D).rotation.x = lerp_angle(
		(_parts["arm_r"] as Node3D).rotation.x, -2.1, minf(delta * 14.0, 1.0)
	)
	(_parts["arm_l"] as Node3D).rotation.x = lerp_angle(
		(_parts["arm_l"] as Node3D).rotation.x, -1.2, minf(delta * 10.0, 1.0)
	)


func animate_attack_windup(delta: float) -> void:
	(_parts["arm_r"] as Node3D).rotation.x = lerp_angle(
		(_parts["arm_r"] as Node3D).rotation.x, -1.5, minf(delta * 18.0, 1.0)
	)


func animate_attack_swing(progress: float) -> void:
	(_parts["arm_r"] as Node3D).rotation.x = lerp_angle(-1.5, 1.1, progress)


func animate_spin(delta: float) -> void:
	## Huracán de Machetes: giro continuo del cuerpo entero con brazos extendidos.
	(_parts["root"] as Node3D).rotation.y += delta * 14.0
	(_parts["arm_r"] as Node3D).rotation.x = -1.5
	(_parts["arm_l"] as Node3D).rotation.x = -1.5


func animate_dodge(delta: float) -> void:
	(_parts["arm_r"] as Node3D).rotation.x = lerp_angle(
		(_parts["arm_r"] as Node3D).rotation.x, -0.9, minf(delta * 14.0, 1.0)
	)


func relax_arms(delta: float) -> void:
	(_parts["arm_r"] as Node3D).rotation.x = lerp_angle(
		(_parts["arm_r"] as Node3D).rotation.x, 0.0, minf(delta * 10.0, 1.0)
	)
	(_parts["arm_l"] as Node3D).rotation.x = lerp_angle(
		(_parts["arm_l"] as Node3D).rotation.x, 0.0, minf(delta * 10.0, 1.0)
	)


func set_blade_glow(active: bool) -> void:
	## Reflejo del arma equipada: brillo cálido del acero (Art Pass Fase 4B).
	var blade_mesh := _parts.get("blade_mesh") as MeshInstance3D
	if blade_mesh == null:
		return
	if active:
		VisualKit.set_emission(blade_mesh, VisualKit.MAT_BRONZE_GLOW, 0.55)
	else:
		VisualKit.clear_emission(blade_mesh)


func hurt_flash() -> void:
	var torso := _parts["torso_mat"] as StandardMaterial3D
	if torso == null:
		return
	torso.emission_enabled = true
	torso.emission = Color(0.9, 0.1, 0.1)
	torso.emission_energy_multiplier = 0.8
	var timer := get_tree().create_timer(0.15)
	timer.timeout.connect(
		func() -> void:
			if torso != null:
				torso.emission_energy_multiplier = 0.0
	)


func play_death() -> void:
	var root := _parts["root"] as Node3D
	var tween := create_tween()
	tween.tween_property(root, "rotation:x", -PI / 2.0, 0.45)
	tween.parallel().tween_property(root, "position:y", 0.18, 0.45)


func reset_pose() -> void:
	var root := _parts["root"] as Node3D
	root.rotation = Vector3.ZERO
	root.position = Vector3.ZERO


func blade_mesh() -> MeshInstance3D:
	return _parts.get("blade_mesh") as MeshInstance3D


func animate_combat_state(delta: float, state: Dictionary) -> void:
	## Resolvedor de pose por estado (Fase 5): recibe el estado REAL del
	## combate (bloqueo, fase de la acción, esquiva) y elige la animación.
	## Preparado para sustituir por un AnimationPlayer: esta función sería el
	## mapa estado→animación, sin tocar la lógica del jugador.
	if bool(state.get("blocking", false)):
		animate_block(delta)
		return
	if String(state.get("action_kind", "")) == "spin":
		animate_spin(delta)
		return
	match String(state.get("phase", "ready")):
		"windup":
			animate_attack_windup(delta)
		"active", "recover":
			animate_attack_swing(clampf(float(state.get("progress", 0.0)), 0.0, 1.0))
		_:
			if bool(state.get("dodging", false)):
				animate_dodge(delta)
			elif not bool(state.get("busy", false)):
				relax_arms(delta)


func _build() -> void:
	## Montaje procedural original (identidad visual de fases anteriores; solo
	## se movió de archivo, sin cambios de forma ni materiales).
	name = "MacheteroPuppet"
	var shirt := VisualKit.flat_material(VisualKit.MAT_SHIRT_OLD)
	var skin := VisualKit.flat_material(VisualKit.MAT_SKIN)
	var pants := VisualKit.flat_material(VisualKit.MAT_PANTS)
	var boots := VisualKit.flat_material(VisualKit.MAT_BOOT)
	var hat := VisualKit.noise_material(VisualKit.MAT_HAT_STRAW, 0.5, 3)
	var blade := VisualKit.flat_material(VisualKit.MAT_BLADE)
	# Torso: guayabera de trabajo.
	VisualKit.add_box(self, Vector3(0.52, 0.62, 0.32), Vector3(0, 1.12, 0), shirt)
	VisualKit.add_sphere(self, 0.17, Vector3(0, 1.52, 0), skin)
	VisualKit.add_box(self, Vector3(0.46, 0.34, 0.30), Vector3(0, 0.72, 0), pants)
	# Sombrero de yarey ancho: silueta reconocible desde cámara alta.
	VisualKit.add_cylinder(self, 0.24, 0.16, Vector3(0, 1.64, 0), hat, 10)
	VisualKit.add_cylinder(self, 0.55, 0.05, Vector3(0, 1.60, 0), hat, 12)
	# Piernas con pivote en la cadera para el ciclo de caminar.
	var leg_l := Node3D.new()
	leg_l.position = Vector3(-0.14, 0.62, 0)
	add_child(leg_l)
	VisualKit.add_box(leg_l, Vector3(0.17, 0.52, 0.19), Vector3(0, -0.28, 0), pants)
	VisualKit.add_box(leg_l, Vector3(0.19, 0.12, 0.27), Vector3(0, -0.55, 0.04), boots)
	var leg_r := Node3D.new()
	leg_r.position = Vector3(0.14, 0.62, 0)
	add_child(leg_r)
	VisualKit.add_box(leg_r, Vector3(0.17, 0.52, 0.19), Vector3(0, -0.28, 0), pants)
	VisualKit.add_box(leg_r, Vector3(0.19, 0.12, 0.27), Vector3(0, -0.55, 0.04), boots)
	# Brazos con pivote en el hombro; el derecho porta el machete.
	var arm_l := Node3D.new()
	arm_l.position = Vector3(-0.34, 1.34, 0)
	add_child(arm_l)
	VisualKit.add_box(arm_l, Vector3(0.14, 0.48, 0.16), Vector3(0, -0.22, 0), shirt)
	VisualKit.add_sphere(arm_l, 0.09, Vector3(0, -0.5, 0), skin)
	var arm_r := Node3D.new()
	arm_r.position = Vector3(0.34, 1.34, 0)
	add_child(arm_r)
	VisualKit.add_box(arm_r, Vector3(0.14, 0.48, 0.16), Vector3(0, -0.22, 0), shirt)
	VisualKit.add_sphere(arm_r, 0.09, Vector3(0, -0.5, 0), skin)
	# Machete: hoja de acero con cabo de madera.
	var machete := Node3D.new()
	machete.position = Vector3(0, -0.52, 0.06)
	machete.rotation_degrees.x = -12.0
	arm_r.add_child(machete)
	VisualKit.add_box(
		machete, Vector3(0.05, 0.16, 0.06), Vector3(0, 0.02, 0), VisualKit.flat_material(VisualKit.MAT_WOOD)
	)
	var blade_mesh := VisualKit.add_box(machete, Vector3(0.045, 0.52, 0.11), Vector3(0, 0.4, 0.08), blade)
	# Detalles del Art Pass (Fase 4B): mangas, cara, cinta, talega y vaina.
	VisualKit.add_box(arm_l, Vector3(0.13, 0.2, 0.15), Vector3(0, -0.42, 0), skin)
	VisualKit.add_box(arm_r, Vector3(0.13, 0.2, 0.15), Vector3(0, -0.42, 0), skin)
	var eye_mat := VisualKit.flat_material(Color(0.09, 0.07, 0.06))
	VisualKit.add_box(self, Vector3(0.05, 0.05, 0.03), Vector3(-0.06, 1.5, 0.19), eye_mat)
	VisualKit.add_box(self, Vector3(0.05, 0.05, 0.03), Vector3(0.06, 1.5, 0.19), eye_mat)
	var mustache_mat := VisualKit.flat_material(Color(0.14, 0.1, 0.08))
	VisualKit.add_box(self, Vector3(0.13, 0.045, 0.05), Vector3(0, 1.43, 0.21), mustache_mat)
	var band_mat := VisualKit.flat_material(Color(0.14, 0.1, 0.07))
	VisualKit.add_cylinder(self, 0.245, 0.05, Vector3(0, 1.6, 0), band_mat, 10)
	var strap_mat := VisualKit.flat_material(VisualKit.MAT_WOOD.darkened(0.15))
	var strap := VisualKit.add_box(self, Vector3(0.08, 0.78, 0.05), Vector3(0.1, 1.1, 0), strap_mat)
	strap.rotation_degrees.z = 24.0
	var bag_mat := VisualKit.flat_material(VisualKit.MAT_HAT_STRAW.darkened(0.3))
	VisualKit.add_box(self, Vector3(0.24, 0.18, 0.1), Vector3(-0.2, 0.94, 0), bag_mat)
	var sheath := Node3D.new()
	sheath.position = Vector3(-0.3, 0.78, -0.12)
	sheath.rotation_degrees = Vector3(6.0, 18.0, 12.0)
	add_child(sheath)
	var sheath_mat := VisualKit.flat_material(VisualKit.MAT_WOOD.darkened(0.25))
	VisualKit.add_box(sheath, Vector3(0.07, 0.5, 0.12), Vector3(0, 0.24, 0), sheath_mat)
	var sole_mat := VisualKit.flat_material(Color(0.1, 0.07, 0.05))
	VisualKit.add_box(leg_l, Vector3(0.2, 0.05, 0.28), Vector3(0, -0.61, 0.05), sole_mat)
	VisualKit.add_box(leg_r, Vector3(0.2, 0.05, 0.28), Vector3(0, -0.61, 0.05), sole_mat)
	_parts = {
		"root": self,
		"leg_l": leg_l,
		"leg_r": leg_r,
		"arm_l": arm_l,
		"arm_r": arm_r,
		"arm_r_free": arm_r,
		"torso_mat": shirt,
		"blade_mesh": blade_mesh,
	}

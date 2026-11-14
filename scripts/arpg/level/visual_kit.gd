class_name VisualKit
## Fábrica estática de materiales y mallas simples para la vertical slice.
## Todo es geometría procedural original (sin assets de terceros): cero riesgo de licencia.
## El Art Pass (Fase 1B) sustituirá este montaje provisional por dirección artística aprobada.

const MAT_GRASS := Color(0.24, 0.42, 0.19)
const MAT_DIRT := Color(0.55, 0.29, 0.19)
const MAT_STONE := Color(0.62, 0.61, 0.57)
const MAT_WOOD := Color(0.36, 0.25, 0.16)
const MAT_LEAF_DARK := Color(0.11, 0.26, 0.13)
const MAT_LEAF_MID := Color(0.18, 0.37, 0.16)
const MAT_TRUNK := Color(0.31, 0.24, 0.17)
const MAT_SKIN := Color(0.72, 0.52, 0.40)
const MAT_SHIRT_OLD := Color(0.78, 0.74, 0.62)
const MAT_PANTS := Color(0.22, 0.24, 0.30)
const MAT_BOOT := Color(0.20, 0.14, 0.10)
const MAT_HAT_STRAW := Color(0.62, 0.50, 0.30)
const MAT_BLADE := Color(0.58, 0.60, 0.62)
const MAT_SHADOW_BODY := Color(0.05, 0.06, 0.09)
const MAT_SHADOW_RIM := Color(0.16, 0.20, 0.32)
const MAT_EYE_AMBER := Color(0.95, 0.42, 0.12)
const MAT_EYE_TELEGRAPH := Color(0.76, 0.12, 0.19)
const MAT_BRONZE := Color(0.72, 0.48, 0.18)
const MAT_POTION := Color(0.68, 0.10, 0.16)
const MAT_BRONZE_GLOW := Color(1.0, 0.72, 0.25)


static func noise_material(base: Color, noise_scale := 0.08, detail := 5) -> StandardMaterial3D:
	## Material con textura de ruido procedural en escala de grises teñida por `base`.
	## La variación de tono evita los planos de color plano prohibidos por la dirección artística §1.
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = noise_scale
	noise.fractal_octaves = maxi(detail, 2)
	var texture := NoiseTexture2D.new()
	texture.noise = noise
	texture.width = 128
	texture.height = 128
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	# En Godot, albedo_color multiplica a albedo_texture: ruido gris (0..1) x base = variacion de tono.
	material.albedo_color = base
	material.roughness = 0.9
	material.metallic = 0.0
	return material


static func flat_material(color: Color, emission := Color(0, 0, 0), emission_energy := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	material.metallic = 0.0
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = emission_energy
	return material


static func add_box(parent: Node, size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = position
	mesh.material_override = material
	parent.add_child(mesh)
	return mesh


static func add_cylinder(
	parent: Node, radius: float, height: float, position: Vector3, material: Material, radial_segments := 10
) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius * 1.12
	cylinder.height = height
	cylinder.radial_segments = radial_segments
	mesh.mesh = cylinder
	mesh.position = position
	mesh.material_override = material
	parent.add_child(mesh)
	return mesh


static func add_sphere(parent: Node, radius: float, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh.mesh = sphere
	mesh.position = position
	mesh.material_override = material
	parent.add_child(mesh)
	return mesh


static func add_cone(
	parent: Node, radius: float, height: float, position: Vector3, material: Material
) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = radius
	cone.height = height
	cone.radial_segments = 8
	mesh.mesh = cone
	mesh.position = position
	mesh.material_override = material
	parent.add_child(mesh)
	return mesh


static func add_tetra(parent: Node, radius: float, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var tetra := PrismMesh.new()
	tetra.size = Vector3(radius * 3.2, radius * 1.9, radius * 3.2)
	tetra.left_to_right = 0.45
	mesh.mesh = tetra
	mesh.position = position
	mesh.material_override = material
	parent.add_child(mesh)
	return mesh


static func set_emission(mesh: MeshInstance3D, color: Color, energy: float) -> void:
	## Usado por telegráficos: cambia la emisión del material sobreescrito.
	var material := mesh.material_override as StandardMaterial3D
	if material == null:
		return
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy


static func clear_emission(mesh: MeshInstance3D) -> void:
	var material := mesh.material_override as StandardMaterial3D
	if material == null:
		return
	material.emission_enabled = true
	material.emission = Color(0, 0, 0)
	material.emission_energy_multiplier = 0.0

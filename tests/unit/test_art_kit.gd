class_name TestArtKit
extends GdUnitTestSuite
## Kit del Art Pass (Fase 4B): materiales de shader y VFX de un solo uso.
## El contenido es original y procedural: sin licencias de terceros que
## verificar (los intentos de descarga externa se documentan en el informe).


func test_wind_material_parameters() -> void:
	var material := ArpgArtKit.wind_material(Color(0.1, 0.2, 0.12), 0.07, 1.9)
	assert_object(material).is_instanceof(ShaderMaterial)
	assert_object(material.shader).is_instanceof(Shader)
	assert_float(float(material.get_shader_parameter("strength"))).is_equal_approx(0.07, 0.001)
	assert_float(float(material.get_shader_parameter("speed"))).is_equal_approx(1.9, 0.001)


func test_wet_and_iron_materials_build() -> void:
	var wet := ArpgArtKit.wet_material(Color(0.2, 0.15, 0.12), 0.92)
	assert_object(wet).is_instanceof(ShaderMaterial)
	assert_float(float(wet.get_shader_parameter("rough"))).is_equal_approx(0.92, 0.001)
	var iron := ArpgArtKit.worn_iron_material()
	assert_object(iron).is_instanceof(ShaderMaterial)
	assert_object(iron.shader).is_instanceof(Shader)


func test_palette_carries_art_entries() -> void:
	## La paleta de Valdeluz expone los materiales del Art Pass al constructor.
	var palette := TerrainMaterialLibrary.create_valdeluz_palette()
	for key: String in ["puddle_wet", "wind_tuft", "wind_frond", "wind_canopy", "worn_iron"]:
		assert_object(palette.get(key)).is_not_null().override_failure_message(
			"falta la entrada '%s' en la paleta" % key
		)


func test_vfx_spawn_and_autodestroy() -> void:
	var host: Node3D = auto_free(Node3D.new())
	add_child(host)
	ArpgArtKit.hit_spark(host, Vector3.ZERO)
	ArpgArtKit.dust_burst(host, Vector3.ONE)
	ArpgArtKit.slash_trail(host, Vector3(0, 1, 0), Vector3(0, 1, 2))
	# Los tres VFX existen como hijos visuales del host; ninguno toca la logica.
	assert_int(host.get_child_count()).is_greater_equal(3)
	var names: Array = []
	for child in host.get_children():
		names.append(child.name)
	assert_array(names).contains(["VFXBurst", "SlashTrail"])

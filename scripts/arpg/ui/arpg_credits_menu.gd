class_name ArpgCreditsMenu
extends Control
## Créditos de RPG-LBA con el lenguaje visual compartido (iteración 4C).
## Atribución obligatoria de assets de terceros (Poly by Google es CC BY 3.0);
## el detalle vive en THIRD_PARTY_NOTICES.md.

const STUDIO_LOGO_PATH := "res://assets/branding/lba-games-logo.svg"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ArpgBackdrop.new(0.62))
	var center := VBoxContainer.new()
	center.add_theme_constant_override("separation", 10)
	center.custom_minimum_size = Vector2(560, 0)
	add_child(center)
	var title := ArpgUiTheme.make_title("Créditos", 30)
	center.add_child(title)
	for section: Array in _sections():
		var header := ArpgUiTheme.make_body(String(section[0]), 16, ArpgUiTheme.GOLD_LIGHT)
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		center.add_child(header)
		for line: String in section[1]:
			var body := ArpgUiTheme.make_dim(line, 13)
			body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			center.add_child(body)
	var logo_texture: Texture2D = load(STUDIO_LOGO_PATH) as Texture2D
	if logo_texture != null:
		var logo := TextureRect.new()
		logo.texture = logo_texture
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.custom_minimum_size = Vector2(280, 120)
		center.add_child(logo)
	var back := ArpgUiTheme.make_button("Volver", ArpgUiTheme.ButtonStyle.NORMAL, Vector2(240, 52))
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/arpg/menu/main_menu.tscn"))
	center.add_child(back)
	# Centrado continuo por rect del viewport (patrón probado en Android).
	center.resized.connect(func() -> void: ArpgUiTheme.center_in_viewport(center))
	center.sort_children.connect(func() -> void: ArpgUiTheme.center_in_viewport(center))
	get_viewport().connect("size_changed", func() -> void: ArpgUiTheme.center_in_viewport(center))
	ArpgUiTheme.center_in_viewport(center)


func _sections() -> Array:
	return [
		[
			"RPG LBA — Las Cenizas de Lythara",
			[
				"Productora ficticia del proyecto: LBA Games.",
				"Dirección técnica, diseño y desarrollo: agente del repositorio Lean031110/RPG-LBA.",
				"Campaña: El Eco de Valdeluz. Cuba ficticia de 1953, fantasía oscura gótico-caribeña.",
			]
		],
		[
			"Motor y herramientas",
			[
				"Godot Engine 4.7.2 — MIT (godotengine.org).",
				"gdUnit4 7.0.0 — MIT, Mike Schulze (godot-gdunit-labs).",
				"Plantilla base: godot-3d-multiplayer-template v2.0.0 — MIT, devmoreir4.",
			]
		],
		[
			"Assets de terceros (ver THIRD_PARTY_NOTICES.md)",
			[
				"Personaje de plantilla: 3D Godot Robot — CC0, AGChow.",
				"Texturas de prototipo: Kenney — CC0.",
				"Items: Quaternius — CC0.",
				"Sombreros: Poly by Google — CC BY 3.0. Atribución obligatoria: 'Hats by Poly by Google'.",
				"Tipografía de títulos: Cinzel — SIL Open Font License 1.1 (google.com/fonts).",
				"Logotipos RPG LBA y LBA Games: obras originales del proyecto (SVG).",
			]
		],
		[
			"Audio",
			[
				"Música y ambientes originales: pendientes (fases posteriores).",
				"No se incluyen grabaciones ni melodías protegidas de terceros.",
			]
		],
	]

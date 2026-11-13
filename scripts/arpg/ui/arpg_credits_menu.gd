class_name ArpgCreditsMenu
extends Control
## Créditos de la vertical slice. Atribución obligatoria de assets de terceros
## (Poly by Google es CC BY 3.0). El detalle vive en THIRD_PARTY_NOTICES.md.

const STUDIO_LOGO_PATH := "res://assets/branding/lba-games-logo.svg"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.04, 0.05, 0.07)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	box.position = Vector2(size.x / 2.0 - 260.0, 40.0)
	box.custom_minimum_size = Vector2(520, 0)
	var title := Label.new()
	title.text = "Créditos"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("b08d3c"))
	box.add_child(title)
	for section: Array in _sections():
		var header := Label.new()
		header.text = String(section[0])
		header.add_theme_font_size_override("font_size", 16)
		header.add_theme_color_override("font_color", Color("e8e4d8"))
		box.add_child(header)
		for line: String in section[1]:
			var body := Label.new()
			body.text = line
			body.add_theme_font_size_override("font_size", 13)
			body.add_theme_color_override("font_color", Color("9aa0a6"))
			body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(body)
	var logo_texture: Texture2D = load(STUDIO_LOGO_PATH) as Texture2D
	if logo_texture != null:
		var logo := TextureRect.new()
		logo.texture = logo_texture
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.custom_minimum_size = Vector2(280, 120)
		box.add_child(logo)
	var back := Button.new()
	back.text = "Volver"
	back.custom_minimum_size = Vector2(240, 52)
	back.add_theme_font_size_override("font_size", 16)
	back.add_theme_color_override("font_color", Color("e8e4d8"))
	back.add_theme_stylebox_override("normal", _flat(Color(0.13, 0.15, 0.2, 0.96)))
	back.add_theme_stylebox_override("hover", _flat(Color(0.18, 0.21, 0.28, 0.98)))
	back.add_theme_stylebox_override("pressed", _flat(Color("1e3a4a")))
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/arpg/menu/main_menu.tscn"))
	box.add_child(back)


## Caja plana para los botones. Igual a la de otros menús ARPG (p. ej. pausa):
## fondo dado, borde fino, esquinas suaves.
func _flat(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color("2a2e38")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style


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

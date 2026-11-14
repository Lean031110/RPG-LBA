class_name ArpgUiTheme
extends RefCounted
## Sistema visual compartido de RPG-LBA (iteración visual 4C).
## Un solo lenguaje para TODAS las pantallas: paleta del emblema oficial
## (assets/branding/rpg-lba-logo.svg), tipografía Cinzel (OFL) para títulos,
## paneles con borde dorado y botones táctiles grandes estilo ARPG móvil.
##
## Reglas del repositorio: sin lógica de juego en la UI; todo estático y
## desacoplado. Cada pantalla construye sus nodos con estos helpers para no
## divergir en colores, radios o márgenes.

# ---------------------------------------------------------------------------
# Paleta (extraída del logotipo oficial; no inventar colores fuera de aquí)
# ---------------------------------------------------------------------------
enum ButtonStyle { NORMAL, PRIMARY, DANGER, GHOST }

const INK := Color("0b0d12")  # Fondo del emblema (azul noche).
const NIGHT := Color("10141c")  # Paneles oscuros.
const PANEL := Color("151820")  # Interior del emblema.
const PANEL_SOFT := Color("1a1e29")  # Paneles activos / hover.
const BONE := Color("e8e4d8")  # Texto principal (hueso).
const GOLD := Color("c99543")  # Oro del emblema.
const GOLD_LIGHT := Color("fff0b0")  # Oro brillante (gradiente superior).
const GOLD_DARK := Color("68401e")  # Oro profundo (gradiente inferior).
const EMBER := Color("ff704d")  # Rojo fuego del ave.
const EMBER_DARK := Color("690d18")  # Rojo profundo.
const PALM := Color("47704d")  # Verde palma del arco.
const TEAL := Color("1e3a4a")  # Acento azul petróleo (Fase 3).
const DIM := Color("9aa0a6")  # Texto secundario.
const DANGER := Color("e0503e")  # Peligro / vida baja.

## Transparencias del HUD semitransparente (se mantienen las de Fase 3).
const ALPHA_PANEL := 0.42
const ALPHA_BUTTON := 0.35

const FONT_TITLE := preload("res://assets/ui/fonts/Cinzel.ttf")
const LOGO_PATH := "res://assets/branding/rpg-lba-logo.svg"

const MENU_BUTTON_MIN := Vector2(340.0, 56.0)

# ---------------------------------------------------------------------------
# Tipografía
# ---------------------------------------------------------------------------


static func title_font(weight := 700, tracking := 2.0) -> FontVariation:
	## Cinzel variable con peso y espaciado ajustables (títulos y encabezados).
	## Nota 4.7: el eje variable se llama variation_opentype (antes
	## variation_coordinates) y los espaciados son enteros (px).
	var font := FontVariation.new()
	font.base_font = FONT_TITLE
	font.variation_opentype = {"wght": float(weight)}
	font.spacing_glyph = int(round(tracking))
	font.spacing_space = int(round(tracking * 0.5))
	return font


static func make_title(text: String, size := 34, color := GOLD) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", title_font())
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


static func make_body(text: String, size := 15, color := BONE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


static func make_dim(text: String, size := 12) -> Label:
	return make_body(text, size, DIM)


# ---------------------------------------------------------------------------
# Estilos de panel y botón
# ---------------------------------------------------------------------------


static func panel_style(
	border := GOLD_DARK, border_w := 1, radius := 10, bg := Color(PANEL.r, PANEL.g, PANEL.b, 0.96)
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_w)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style


static func hud_panel_style(alpha := ALPHA_PANEL) -> StyleBoxFlat:
	## Panel del HUD en partida: semitransparente, borde fino, sin distracción.
	var style := panel_style(Color(GOLD_DARK.r, GOLD_DARK.g, GOLD_DARK.b, 0.55), 1, 8)
	style.bg_color = Color(PANEL.r, PANEL.g, PANEL.b, alpha)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


static func make_button(text: String, style: ButtonStyle = ButtonStyle.NORMAL, min_size := MENU_BUTTON_MIN) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", BONE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", GOLD_LIGHT)
	button.add_theme_color_override("font_disabled_color", Color(DIM.r, DIM.g, DIM.b, 0.45))
	button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	button.add_theme_constant_override("outline_size", 1)
	button.add_theme_constant_override("content_margin_left", 26)
	button.add_theme_constant_override("content_margin_right", 26)
	var accent := GOLD
	match style:
		ButtonStyle.PRIMARY:
			accent = GOLD
		ButtonStyle.DANGER:
			accent = EMBER
		ButtonStyle.GHOST:
			accent = Color(PALM.r, PALM.g, PALM.b, 0.9)
		_:
			accent = Color(GOLD.r, GOLD.g, GOLD.b, 0.7)
	button.add_theme_stylebox_override("normal", _button_box(accent, 0.0))
	button.add_theme_stylebox_override("hover", _button_box(accent, 1.0))
	button.add_theme_stylebox_override("pressed", _button_box(accent, 2.0))
	button.add_theme_stylebox_override("focused", _button_box(accent, 1.0))
	button.add_theme_stylebox_override("disabled", _button_box(accent, -1.0))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_press_feedback(button)
	return button


static func _button_box(accent: Color, state: float) -> StyleBoxFlat:
	## state: -1 deshabilitado, 0 normal, 1 hover, 2 presionado.
	var style := StyleBoxFlat.new()
	var base := Color(NIGHT.r, NIGHT.g, NIGHT.b, 0.94)
	if state >= 1.0:
		base = Color(PANEL_SOFT.r, PANEL_SOFT.g, PANEL_SOFT.b, 0.97)

		# Barra de acento a la izquierda: lectura rápida del tipo de acción.
	elif state < 0.0:
		base = Color(NIGHT.r, NIGHT.g, NIGHT.b, 0.55)

		# Barra de acento a la izquierda: lectura rápida del tipo de acción.
	style.bg_color = base
	var border_alpha := 0.45 + 0.35 * maxf(state, 0.0)
	style.border_color = Color(accent.r, accent.g, accent.b, border_alpha)
	style.set_border_width_all(1)
	# Barra de acento a la izquierda: lectura rápida del tipo de acción.
	style.border_width_left = 4 if state >= 0.0 else 2
	style.set_corner_radius_all(6)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


static func add_press_feedback(button: Button) -> void:
	## Animación discreta al pulsar (escala 0.97 + rebote), táctil y con ratón.
	var original_scale := button.scale
	button.pressed.connect(
		func() -> void:
			var tree := button.get_tree()
			if tree == null:
				return
			var tween := button.create_tween()
			tween.tween_property(button, "scale", original_scale * Vector2(0.97, 0.97), 0.05)
			tween.tween_property(button, "scale", original_scale, 0.12)
	)


# ---------------------------------------------------------------------------
# Texturas procedurales (fondos cinematográficos)
# ---------------------------------------------------------------------------


static func vertical_gradient(top: Color, mid: Color, bottom: Color) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([top, mid, bottom])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_LINEAR
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	return texture


static func radial_glow(color: Color, reach := 0.5) -> GradientTexture2D:
	## Halo suave para colocar detrás del logotipo o de la luna.
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	gradient.colors = PackedColorArray(
		[
			Color(color.r, color.g, color.b, color.a),
			Color(color.r, color.g, color.b, color.a * 0.35),
			Color(color.r, color.g, color.b, 0.0)
		]
	)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.5 + reach)
	return texture


static func vignette_texture(strength := 0.85) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	gradient.colors = PackedColorArray([Color(0, 0, 0, 0.0), Color(0, 0, 0, strength * 0.35), Color(0, 0, 0, strength)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.72, 0.5)
	texture.width = 320
	texture.height = 180
	return texture


# ---------------------------------------------------------------------------
# Utilidades de composición
# ---------------------------------------------------------------------------


static func full_rect(control: Control) -> Control:
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	return control


static func fade_in(control: Control, duration := 0.4, delay := 0.0) -> void:
	control.modulate.a = 0.0
	var tween := control.create_tween()
	tween.tween_interval(delay)
	tween.tween_property(control, "modulate:a", 1.0, duration)


static func center_in_viewport(control: Control) -> void:
	## Centrado según el rect del viewport (en Android el Control del menú puede
	## quedar a (0,0) y PRESET_CENTER lo pega arriba-izquierda; corrida 43495554774).
	var vs := control.get_viewport().get_visible_rect().size
	var ms := control.get_combined_minimum_size()
	if vs.x > 1.0 and vs.y > 1.0 and ms.x > 1.0:
		control.position = (vs - ms) / 2.0


static func logo_texture(width := 620.0) -> TextureRect:
	## El emblema oficial, tal cual (sin reinventarlo), con su halo cálido.
	var holder := TextureRect.new()
	holder.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	holder.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	holder.custom_minimum_size = Vector2(width, width * 420.0 / 1200.0)
	holder.size = holder.custom_minimum_size
	var texture: Texture2D = load(LOGO_PATH) as Texture2D
	if texture != null:
		holder.texture = texture
	return holder

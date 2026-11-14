class_name ArpgBackdrop
extends Control
## Fondo cinematográfico compartido de las pantallas de RPG-LBA.
## Noche caribeña: cielo degradado, luna con halo, silueta de Valdeluz al
## horizonte, palmas y brasas que ascienden. 100% nodos nativos de Godot
## (GradientTexture2D, Polygon2D, CPUParticles2D): cero assets externos y
## compatible con el Compatibility Renderer.
##
## Uso: add_child(ArpgBackdrop.new()) detrás del contenido de la pantalla.

var _embers: CPUParticles2D = null
var _moon: Control = null
var _time := 0.0


func _init(dim := 0.0) -> void:
	## dim > 0 oscurece el fondo (pantallas de contenido: multijugador, ajustes).
	name = "ArpgBackdrop"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_sky()
	_build_moon()
	_build_town()
	_build_palms()
	_build_embers()
	_build_vignette()
	if dim > 0.0:
		var shade := ColorRect.new()
		shade.color = Color(0.02, 0.03, 0.05, dim)
		shade.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(shade)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	## Parallax sutil: la luna se mece y las brasas titilan con el tiempo.
	_time += delta
	if _moon != null:
		_moon.position.y = 96.0 + sin(_time * 0.25) * 6.0
	if _embers != null:
		_embers.scale_amount_min = 0.7 + sin(_time * 1.7) * 0.08
		_embers.scale_amount_max = 1.5 + cos(_time * 1.3) * 0.1


func _build_sky() -> void:
	var sky := TextureRect.new()
	sky.name = "Sky"
	sky.texture = ArpgUiTheme.vertical_gradient(Color("04060b"), Color("0d1420"), Color("241610"))
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)


func _build_moon() -> void:
	_moon = Control.new()
	_moon.name = "Moon"
	_moon.position = Vector2(1010.0, 96.0)
	_moon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_moon)
	var halo := TextureRect.new()
	halo.texture = ArpgUiTheme.radial_glow(Color(1.0, 0.92, 0.72, 0.35), 0.9)
	halo.size = Vector2(300, 300)
	halo.position = Vector2(-130, -130)
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_moon.add_child(halo)
	var disc := TextureRect.new()
	disc.texture = ArpgUiTheme.radial_glow(Color(1.0, 0.95, 0.8, 1.0), 0.16)
	disc.size = Vector2(64, 64)
	disc.position = Vector2(-32, -32)
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_moon.add_child(disc)


func _build_town() -> void:
	## Silueta de los tejados coloniales de Valdeluz contra el horizonte.
	var town := Polygon2D.new()
	town.name = "ValdeluzSkyline"
	town.color = Color("0a0d13")
	town.polygon = PackedVector2Array(
		[
			Vector2(-80, 470),
			Vector2(-80, 430),
			Vector2(60, 430),
			Vector2(85, 392),
			Vector2(150, 392),
			Vector2(170, 424),
			Vector2(300, 424),
			Vector2(330, 372),
			Vector2(470, 372),
			Vector2(495, 412),
			Vector2(610, 412),
			Vector2(648, 352),
			Vector2(760, 352),
			Vector2(800, 416),
			Vector2(900, 416),
			Vector2(925, 388),
			Vector2(1010, 388),
			Vector2(1040, 430),
			Vector2(1180, 430),
			Vector2(1360, 430),
			Vector2(1360, 470)
		]
	)
	add_child(town)
	# Rescoldo cálido tras el pueblo: el "eco" de Valdeluz.
	var glow := TextureRect.new()
	glow.name = "ValdeluzGlow"
	glow.texture = ArpgUiTheme.radial_glow(Color(1.0, 0.45, 0.22, 0.16), 0.55)
	glow.size = Vector2(700, 260)
	glow.position = Vector2(290, 330)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)


func _build_palms() -> void:
	## Dos matas de palma enmarcando la composición (izquierda y derecha).
	var left := _palm_cluster()
	left.position = Vector2(60, 470)
	left.scale = Vector2(1.15, 1.15)
	add_child(left)
	var right := _palm_cluster()
	right.position = Vector2(1220, 470)
	right.scale = Vector2(-1.0, 1.0)
	add_child(right)


func _palm_cluster() -> Node2D:
	var palm := Node2D.new()
	palm.name = "Palms"
	var trunk := Polygon2D.new()
	trunk.color = Color("080a0f")
	trunk.polygon = PackedVector2Array([Vector2(-7, 0), Vector2(-3, -150), Vector2(3, -150), Vector2(7, 0)])
	palm.add_child(trunk)
	# Frondas: abanico de triángulos desde el extremo del tronco.
	var frond_angles := [-74.0, -46.0, -18.0, 8.0, 36.0, 62.0]
	for angle: float in frond_angles:
		var frond := Polygon2D.new()
		frond.color = Color("090c12")
		var radians := deg_to_rad(angle - 90.0)
		var tip := Vector2(cos(radians), sin(radians)) * 78.0 + Vector2(0, -150)
		frond.polygon = PackedVector2Array([Vector2(0, -150), tip + Vector2(0, 10), tip - Vector2(0, 10)])
		palm.add_child(frond)
	return palm


func _build_embers() -> void:
	## Brasas doradas que ascienden lentamente (la "ceniza viva" de la isla).
	_embers = CPUParticles2D.new()
	_embers.name = "Embers"
	_embers.position = Vector2(640, 780)
	_embers.amount = 42
	_embers.lifetime = 7.5
	_embers.preprocess = 6.0
	_embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_embers.emission_rect_extents = Vector2(700, 20)
	_embers.direction = Vector2(0, -1)
	_embers.spread = 12.0
	_embers.gravity = Vector2(6, -4)
	_embers.initial_velocity_min = 26.0
	_embers.initial_velocity_max = 58.0
	_embers.scale_amount_min = 0.7
	_embers.scale_amount_max = 1.5
	_embers.color_ramp = _ember_ramp()
	_embers.texture = _ember_dot()
	_embers.emitting = true
	add_child(_embers)


func _ember_ramp() -> Gradient:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	gradient.colors = PackedColorArray(
		[Color(1.0, 0.62, 0.3, 0.0), Color(1.0, 0.72, 0.35, 0.85), Color(0.7, 0.3, 0.12, 0.0)]
	)
	return gradient


func _ember_dot() -> ImageTexture:
	## Punto suave para la brasa (radial blanco->transparente, tintado por ramp).
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y: int in 16:
		for x: int in 16:
			var distance := Vector2(x - 7.5, y - 7.5).length() / 8.0
			var alpha := clampf(1.0 - distance, 0.0, 1.0)
			image.set_pixel(x, y, Color(1, 1, 1, alpha * alpha))
	return ImageTexture.create_from_image(image)


func _build_vignette() -> void:
	var frame := TextureRect.new()
	frame.name = "Vignette"
	frame.texture = ArpgUiTheme.vignette_texture(0.9)
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)

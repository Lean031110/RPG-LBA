class_name ArpgCooldownOverlay
extends Control
## Superposición radial de recarga para los botones de acción del HUD.
## Dibuña un sector oscuro que se reduce conforme la habilidad vuelve a estar
## disponible, con el contador de segundos en el centro. Barato: un solo
## _draw por actualización de progreso, sin texturas externas.

var progress := 0.0  # 1.0 = acaba de usarse; 0.0 = lista.

var _label: Label = null
var _accent := Color("c99543")


func _init(diameter: float = 84.0) -> void:
	custom_minimum_size = Vector2(diameter, diameter)
	size = Vector2(diameter, diameter)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color("ffe9bd"))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_label.add_theme_constant_override("outline_size", 3)
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func set_progress(remaining: float, total: float) -> void:
	## remaining/total en segundos; oculta el overlay cuando no hay recarga.
	if total <= 0.05 or remaining <= 0.0:
		if visible:
			visible = false
			progress = 0.0
		return
	progress = clampf(remaining / total, 0.0, 1.0)
	if not visible:
		visible = true
	_label.text = ("%d" % int(ceil(remaining))) if remaining > 1.0 else "%.1f" % remaining
	queue_redraw()


func _draw() -> void:
	if progress <= 0.0:
		return
	var center := size / 2.0
	var radius := minf(size.x, size.y) * 0.5 - 1.0
	# Abanico desde el norte, en el sentido de las agujas, cubriendo lo que falta.
	var points := PackedVector2Array([center])
	var segments := 36
	var sweep := -TAU * progress
	for index: int in segments + 1:
		var angle := -PI / 2.0 + sweep * float(index) / float(segments)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, Color(0.03, 0.04, 0.06, 0.72))
	# Aro de acento que marca el frente de la recarga.
	var head_angle := -PI / 2.0 + sweep
	draw_line(
		center,
		center + Vector2(cos(head_angle), sin(head_angle)) * radius,
		Color(_accent.r, _accent.g, _accent.b, 0.9),
		2.0
	)

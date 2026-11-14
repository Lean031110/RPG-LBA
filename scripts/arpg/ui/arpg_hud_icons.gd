class_name ArpgHudIcons
## Fábrica de iconos del HUD dibujados en código (Fase 5): cero dependencias
## externas, listos para sustituir por los iconos definitivos del Art Pass
## manteniendo las llamadas.


static func pause_icon() -> ImageTexture:
	## Pausa: dos barras.
	var image := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	var color := Color(0.91, 0.89, 0.85, 0.95)
	for y: int in 48:
		for x: int in 48:
			if (x >= 13 and x <= 20 or x >= 27 and x <= 34) and y >= 12 and y <= 35:
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


static func heavy_icon() -> ImageTexture:
	## Machetazo pesado: flecha gruesa descendente.
	var image := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	var color := Color(0.95, 0.88, 0.7, 0.95)
	for y: int in 48:
		for x: int in 48:
			var in_arrow := (
				(x >= 22 and x <= 25 and y >= 8)
				or (y >= 24 and y <= 27 and x >= 14 and x <= 33)
				or (x >= 18 and x <= 21 and y >= 20 and y <= 23)
				or (x >= 26 and x <= 29 and y >= 20 and y <= 23)
			)
			if in_arrow:
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


static func block_icon() -> ImageTexture:
	## Bloqueo: escudo simple.
	var image := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	var color := Color(0.62, 0.74, 0.86, 0.95)
	for y: int in 48:
		for x: int in 48:
			var dx := x - 24.0
			var dy := y - 12.0
			var in_shield := dx * dx + dy * dy <= 144.0 and y >= 8
			var in_tip := y > 20 and y <= 40 and absf(dx) <= 20.0 - (y - 20) * 0.85
			if in_shield or in_tip:
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


static func skill_icon(index: int) -> ImageTexture:
	## Icono por habilidad (legible en pequeño): 0 media luna (tajo), 1 escudo
	## (guardia), 2 flecha (carga), 3 hacha (ceiba).
	var image := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	var color := Color(0.93, 0.82, 0.55, 0.95)
	for y: int in 48:
		for x: int in 48:
			if _skill_icon_pixel(index, x, y):
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


static func ultimate_icon() -> ImageTexture:
	## Definitiva: estrella de giro (Huracán de Machetes).
	var image := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	var color := Color(1.0, 0.62, 0.25, 0.95)
	var center := Vector2(24.0, 24.0)
	for y: int in 48:
		for x: int in 48:
			var delta := Vector2(x, y) - center
			var dist := delta.length()
			if dist > 19.0 or dist < 4.0:
				continue
			var angle := fmod(atan2(delta.y, delta.x) + PI / 8.0, PI / 4.0)
			if absf(angle - PI / 8.0) < 0.32:
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


static func _skill_icon_pixel(index: int, x: int, y: int) -> bool:
	match index:
		0:
			var dx := x - 24.0
			var dy := y - 24.0
			var dist := sqrt(dx * dx + dy * dy)
			return dist <= 17.0 and dist >= 11.0 and dx <= 6.0
		1:
			var dxs := x - 24.0
			var dys := y - 13.0
			return (
				dxs * dxs + dys * dys <= 169.0 and y >= 7 or (y > 18 and y <= 41 and absf(dxs) <= 17.0 - (y - 18) * 0.8)
			)
		2:
			return (
				(x >= 8 and x <= 40 and y >= 20 and y <= 24)
				or (y >= 12 and y <= 30 and x >= 30 and x <= 38 and (x - 34.0) * 2.0 + y <= 46.0)
			)
		_:
			return (x >= 22 and x <= 25 and y >= 14 and y <= 40) or (x >= 10 and x <= 37 and y >= 10 and y <= 16)

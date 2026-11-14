class_name ArpgStatusChips
## Fábrica de chips de estados alterados (Fase 5): etiqueta legible con el
## nombre canónico del estado y su color. La usan el HUD del jugador y el
## marco de objetivo; sin iconos falsos — texto real, listo para los iconos
## definitivos del Art Pass.

const LABELS := {
	"stun": "Aturdido",
	"slow": "Ralentizado",
	"resin": "Trampa de resina",
	"bleed": "Sangrado",
	"armor_break": "Armadura rota",
	"vulnerable": "Vulnerable",
	"invulnerable": "Invulnerable",
	"empowered": "Pulso de monte",
	"haste": "Prisa de manada",
}

const COLORS := {
	"stun": Color("e8c34a"),
	"bleed": Color("d45a4a"),
	"armor_break": Color("c98a2d"),
	"empowered": Color("c99543"),
	"invulnerable": Color("7ec8e8"),
	"resin": Color("9c7b4d"),
}


static func make(status_id: String) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.11, 0.75)
	style.set_corner_radius_all(4)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	chip.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = String(LABELS.get(status_id, status_id))
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", COLORS.get(status_id, Color("9aa0a6")))
	chip.add_child(label)
	return chip

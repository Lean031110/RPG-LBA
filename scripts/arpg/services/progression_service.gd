class_name ProgressionService
## Servicio común de XP y niveles (curva en game/data/progression.json).
## Fórmula: XP_siguiente(N) = round(base + linear*(N-1) + quadratic*(N-1)^2).
## Ejemplos del canon (docs/diseno/02): 1→2 = 100, 2→3 = 143, 29→30 = 7352.

const DEFAULT_BASE := 100.0
const DEFAULT_LINEAR := 35.0
const DEFAULT_QUADRATIC := 8.0


static func curve_params(progression_data: Dictionary) -> Dictionary:
	var curve: Dictionary = progression_data.get("xp_curve", {})
	return {
		"base": float(curve.get("base", DEFAULT_BASE)),
		"linear": float(curve.get("linear", DEFAULT_LINEAR)),
		"quadratic": float(curve.get("quadratic", DEFAULT_QUADRATIC)),
	}


static func level_min(progression_data: Dictionary) -> int:
	return int(progression_data.get("level_min", 1))


static func level_max(progression_data: Dictionary) -> int:
	return int(progression_data.get("level_max", 30))


static func is_level_max_extensible(progression_data: Dictionary) -> bool:
	return bool(progression_data.get("level_max_extensible", true))


static func xp_for_next(level: int, progression_data: Dictionary) -> int:
	## XP necesaria para pasar de `level` a `level + 1`.
	if level < level_min(progression_data):
		return -1
	var params := curve_params(progression_data)
	var n := float(level - 1)
	var value: float = float(params["base"]) + float(params["linear"]) * n + float(params["quadratic"]) * n * n
	return int(round(value))


static func can_level_up(level: int, xp: int, progression_data: Dictionary) -> bool:
	if level >= level_max(progression_data):
		return false
	return xp >= xp_for_next(level, progression_data)


static func level_up_bounds(level: int, progression_data: Dictionary) -> Dictionary:
	## XP acumulada total al entrar en `level` y al salir de él (para barras y guardado).
	var total := 0
	var current := level_min(progression_data)
	while current < level:
		total += xp_for_next(current, progression_data)
		current += 1
	var next_threshold := total + xp_for_next(level, progression_data)
	return {"floor": total, "ceiling": next_threshold}


static func add_xp(level: int, xp_into_level: int, amount: int, progression_data: Dictionary) -> Dictionary:
	## Suma XP y resuelve subidas de nivel en cascada.
	## Devuelve {level, xp_into_level, levels_gained, points_gained}.
	## `points_gained` usa attribute_points_per_level; el crecimiento automático por clase
	## lo aplica la entidad dueña del progreso (no este servicio).
	var max_level := level_max(progression_data)
	var points_per_level := int(progression_data.get("attribute_points_per_level", 5))
	var new_level := level
	var new_xp := xp_into_level + maxi(amount, 0)
	var levels_gained := 0
	while new_level < max_level and new_xp >= xp_for_next(new_level, progression_data):
		new_xp -= xp_for_next(new_level, progression_data)
		new_level += 1
		levels_gained += 1
	if new_level >= max_level:
		new_xp = mini(new_xp, xp_for_next(max_level - 1, progression_data))
	return {
		"level": new_level,
		"xp_into_level": new_xp,
		"levels_gained": levels_gained,
		"points_gained": levels_gained * points_per_level,
	}


static func xp_bar_fraction(level: int, xp_into_level: int, progression_data: Dictionary) -> float:
	## Fracción [0,1] de la barra de XP del nivel actual.
	if level >= level_max(progression_data):
		return 1.0
	var needed := xp_for_next(level, progression_data)
	if needed <= 0:
		return 0.0
	return clampf(float(xp_into_level) / float(needed), 0.0, 1.0)


static func first_kill_xp(enemy_data: Dictionary, is_first_kill: bool) -> int:
	## XP por derrotar un enemigo: completa en primera victoria, reducida al repetir.
	if is_first_kill:
		return int(enemy_data.get("xp_first_kill", 0))
	var repeat := int(enemy_data.get("xp_repeat", 0))
	return mini(repeat, int(enemy_data.get("xp_first_kill", 0)))

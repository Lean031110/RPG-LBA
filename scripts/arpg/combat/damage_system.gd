class_name DamageSystem
extends RefCounted
## Procesamiento central de daño de la Fase 5 (requisito del prompt: un único
## lugar con reglas compartidas por ataques básicos, habilidades, enemigos y
## futuras clases). NO duplica las fórmulas: la mitigación de armadura/resistencia
## y el crítico viven en CombatService; aquí se resuelven los modificadores de
## contexto (inmunidad, bloqueo, vulnerabilidad, potenciación, rotura de armadura,
## límites mínimos/máximos) y se produce un resultado reproducible.
##
## Pipeline completo (documentado en docs/diseno/03_COMBATE_FORMULAS.md):
##   1. Inmunidad del objetivo          → {immune: true, amount: 0}
##   2. Esquiva/parada                  → las resuelve el CUERPO del objetivo
##      ANTES de llamar aquí (necesita su estado de acción, no sus stats)
##   3. Daño base = CombatService.damage_from_data (potencia × coef × atributo ×
##      mitigación de armadura/resistencia, con armadura ya afectada por rotura)
##   4. Crítico = CombatService.crit_roll (prob. y multiplicador del atacante)
##   5. Multiplicadores: saliente (empowered) × entrante (vulnerable)
##   6. Bloqueo: × CombatService.block_factor (si el objetivo bloquea de frente)
##   7. Límites: mínimo/máximo de la habilidad si existen
##
## Resultado (Dictionary, siempre con estas claves):
##   amount: float        daño final a aplicar (>= 0)
##   crit: bool           fue crítico
##   immune: bool         el objetivo era inmune (no aplicar nada)
##   blocked: bool        el golpe se redujo por bloqueo
##   passed_fraction: float  fracción que sobrevivió tras bloqueo (1.0 si no bloqueó)


static func resolve(
	attacker: CombatStats,
	target: CombatStats,
	skill_data: Dictionary,
	rng: RandomNumberGenerator,
	target_status: StatusEffectController = null,
	options: Dictionary = {}
) -> Dictionary:
	var result := {
		"amount": 0.0,
		"crit": false,
		"immune": false,
		"blocked": false,
		"passed_fraction": 1.0,
	}
	# 1) Inmunidad.
	if target_status != null and target_status.is_invulnerable():
		result["immune"] = true
		return result

	# 3) Daño base. La defensa del objetivo se ajusta por su rotura de armadura.
	var damage_type := String(skill_data.get("damage_type", "physical"))
	var defense := target.defense_for(damage_type)
	if target_status != null:
		defense *= target_status.armor_multiplier()
	var base := CombatService.damage_from_data(skill_data, attacker.primary_attribute, defense)

	# 4) Crítico con las estadísticas reales del atacante.
	var crit_result := CombatService.crit_roll(base, attacker.crit_chance, rng, attacker.crit_multiplier)
	var amount := float(crit_result["damage"])
	result["crit"] = bool(crit_result["crit"])

	# 5) Multiplicadores de contexto (empowered del atacante / vulnerable del objetivo).
	amount *= maxf(attacker.outgoing_multiplier, 0.0)
	if target_status != null:
		amount *= target_status.incoming_damage_multiplier()

	# 6) Bloqueo (el cuerpo del objetivo decide si bloquea y de frente; aquí
	#    solo se aplica la reducción que dictan sus estadísticas).
	if bool(options.get("blocked", false)):
		result["blocked"] = true
		var pass_factor := CombatService.block_factor(target.block_reduction)
		result["passed_fraction"] = pass_factor
		amount *= pass_factor

	# 7) Límites de la habilidad (algunas técnicas fijan suelo/techo).
	var min_damage := float(options.get("min_damage", skill_data.get("min_damage", 0.0)))
	var max_damage := float(options.get("max_damage", skill_data.get("max_damage", 0.0)))
	if max_damage > 0.0:
		amount = minf(amount, max_damage)
	amount = maxf(amount, maxf(min_damage, 0.0))

	result["amount"] = amount
	return result


static func resolve_attacker_empowered(attacker_status: StatusEffectController, attacker: CombatStats) -> CombatStats:
	## Aplica el modificador de un solo uso "empowered" (Pulso de monte) a una
	## copia de las estadísticas del atacante y CONSUME el estado. Devuelve las
	## estadísticas a usar en el golpe actual.
	var stats := attacker.duplicate_stats()
	if attacker_status != null and attacker_status.has("empowered"):
		stats.outgoing_multiplier *= attacker_status.outgoing_damage_multiplier()
		attacker_status.consume("empowered")
	return stats

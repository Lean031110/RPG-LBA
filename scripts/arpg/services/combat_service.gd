class_name CombatService
## Servicio único de cálculo de daño y mitigación (AGENTS.md §6: no duplicar fórmulas).
## Las habilidades/enemigos describen potencia, coeficiente, tipo y atributo; el cálculo vive aquí.
## Coeficientes de mitigación y crítico: hipótesis de diseño (docs/diseno/02) pendientes de
## simulación y telemetría. Preparado para validación autoritativa en servidor futuro.

const ARMOR_CONSTANT := 100.0
const RESISTANCE_CONSTANT := 100.0
const MITIGATION_CAP := 0.75
const CRIT_CHANCE_CAP := 0.5
const CRIT_DAMAGE_MULTIPLIER := 1.5


static func attribute_modifier(attribute_value: float) -> float:
	## Modificador compartido por atributo. Fórmula en game/data/classes.json:
	## 1.0 + (atributo - 10) * 0.05
	return 1.0 + (attribute_value - 10.0) * 0.05


static func armor_factor(armor: float) -> float:
	## Fracción de daño que sobrevive a la armadura (1.0 = sin mitigación).
	var mitigation := clampf(armor / (armor + ARMOR_CONSTANT), 0.0, MITIGATION_CAP)
	return 1.0 - mitigation


static func resistance_factor(resistance: float) -> float:
	var mitigation := clampf(resistance / (resistance + RESISTANCE_CONSTANT), 0.0, MITIGATION_CAP)
	return 1.0 - mitigation


static func physical_damage(potency: float, skill_coeff: float, attribute_value: float, target_armor: float) -> float:
	## Daño físico efectivo = potencia x coef x modificador de atributo x mitigación de armadura.
	var damage := potency * skill_coeff * attribute_modifier(attribute_value)
	damage *= armor_factor(target_armor)
	return maxf(damage, 0.0)


static func arcane_damage(
	potency: float, skill_coeff: float, attribute_value: float, target_resistance: float
) -> float:
	## Daño arcano = potencia arcana x coef x modificador de Intelecto x mitigación de resistencia.
	var damage := potency * skill_coeff * attribute_modifier(attribute_value)
	damage *= resistance_factor(target_resistance)
	return maxf(damage, 0.0)


static func damage_from_data(skill_data: Dictionary, attacker_attribute: float, target_defense: float) -> float:
	## Calcula el daño usando los datos de una habilidad/enemigo.
	## skill_data necesita: potency, damage_coeff, attribute (valor), damage_type.
	var potency := float(skill_data.get("potency", 0.0))
	var coeff := float(skill_data.get("damage_coeff", 1.0))
	var damage_type := String(skill_data.get("damage_type", "physical"))
	if damage_type == "arcane":
		return arcane_damage(potency, coeff, attacker_attribute, target_defense)
	return physical_damage(potency, coeff, attacker_attribute, target_defense)


static func crit_roll(damage: float, crit_chance: float, rng: RandomNumberGenerator) -> Dictionary:
	## Devuelve {damage, crit} aplicando el tope global de probabilidad de crítico.
	var chance := clampf(crit_chance, 0.0, CRIT_CHANCE_CAP)
	var is_crit := rng.randf() < chance
	if is_crit:
		return {"damage": damage * CRIT_DAMAGE_MULTIPLIER, "crit": true}
	return {"damage": damage, "crit": false}


static func is_in_telegraph_window(elapsed: float, windup: float, active_until: float) -> bool:
	## Ventana activa de una hitbox: solo entre windup y active_until.
	return elapsed >= windup and elapsed <= active_until


static func is_in_dodge_window(elapsed: float, duration: float) -> bool:
	return elapsed >= 0.0 and elapsed <= duration

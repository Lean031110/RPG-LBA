class_name CombatStats
extends RefCounted
## Estadísticas de combate derivadas de UNA sola fuente de verdad (Fase 5).
## El jugador y los enemigos vuelcan aquí sus valores finales (base de datos +
## nivel + equipo + estados alterados) y el DamageSystem solo lee de aquí.
## Esto evita valores duplicados o inconsistentes entre personaje, enemigos y HUD.
##
## El HUD nunca calcula: consulta estos getters tras cada stats_changed.

## Potencia base de ataque (se multiplica por el coeficiente de cada habilidad).
var attack_power := 8.0
## Atributo principal del atacante (fuerza/intelecto/... ya resuelto por el dueño).
var primary_attribute := 10.0
## Defensa física (mitigación con tope global en CombatService).
var armor := 0.0
## Defensa arcana.
var resistance := 0.0
## Probabilidad de crítico 0..1 (CombatService aplica el tope global).
var crit_chance := 0.05
## Multiplicador de daño crítico (p. ej. 1.5 = +50%).
var crit_multiplier := 1.5
## Velocidad de ataque relativa: 1.0 = normal. Las duraciones de las acciones
## se dividen por este valor (mínimo protegido en SkillController).
var attack_speed := 1.0
## Velocidad de movimiento final (m/s) ya multiplicada por modificadores.
var move_speed := 4.0
## Resistencia al empuje 0..1 (Pies de piedra del Machetero la usa).
var knockback_resistance := 0.0
## Fracción de daño bloqueada al bloquear 0..1 (Guardia del Bohío la sube).
var block_reduction := 0.5
## Multiplicador de daño saliente (Pulso de monte: 1.5 tras parada perfecta).
var outgoing_multiplier := 1.0
## Multiplicador de daño entrante (vulnerable > 1, guardado < 1).
var incoming_multiplier := 1.0


static func from_class_data(class_data: Dictionary, p_level: int, attribute_total: float) -> CombatStats:
	## Constructor del jugador: base de datos + crecimiento por nivel.
	## attribute_total = atributo base + puntos asignados (el jugador lo resuelve).
	var stats := CombatStats.new()
	var base: Dictionary = class_data.get("base_stats", {})
	var growth: Dictionary = class_data.get("growth", {})
	var levels := maxi(p_level - 1, 0)
	stats.attack_power = float(base.get("potency", 8.0))
	stats.primary_attribute = attribute_total
	stats.armor = float(base.get("armor", 0.0)) + float(growth.get("armor_per_level", 0.0)) * levels
	stats.resistance = float(base.get("resistance", 0.0))
	stats.crit_chance = float(base.get("crit_chance", 0.05))
	stats.crit_multiplier = float(base.get("crit_multiplier", 1.5))
	stats.attack_speed = float(base.get("attack_speed", 1.0))
	stats.move_speed = float(class_data.get("move_speed", 4.0))
	stats.block_reduction = float(base.get("block_reduction", 0.5))
	return stats


static func from_enemy_data(enemy_data: Dictionary) -> CombatStats:
	## Constructor de enemigos: los monstruos usan valores planos (sin curvas).
	var stats := CombatStats.new()
	stats.attack_power = float(enemy_data.get("potency", 9.0))
	stats.primary_attribute = float(enemy_data.get("attribute_value", 14.0))
	stats.armor = float(enemy_data.get("armor", 2.0))
	stats.resistance = float(enemy_data.get("resistance", 1.0))
	stats.move_speed = float(enemy_data.get("move_speed", 3.6))
	stats.crit_chance = float(enemy_data.get("crit_chance", 0.0))
	return stats


func defense_for(damage_type: String) -> float:
	## Defensa aplicable según el tipo de daño (físico→armadura, arcano→resistencia).
	return resistance if damage_type == "arcane" else armor


func duplicate_stats() -> CombatStats:
	## Copia defensiva para simular modificadores temporales sin mutar la fuente.
	var copy := CombatStats.new()
	copy.attack_power = attack_power
	copy.primary_attribute = primary_attribute
	copy.armor = armor
	copy.resistance = resistance
	copy.crit_chance = crit_chance
	copy.crit_multiplier = crit_multiplier
	copy.attack_speed = attack_speed
	copy.move_speed = move_speed
	copy.knockback_resistance = knockback_resistance
	copy.block_reduction = block_reduction
	copy.outgoing_multiplier = outgoing_multiplier
	copy.incoming_multiplier = incoming_multiplier
	return copy

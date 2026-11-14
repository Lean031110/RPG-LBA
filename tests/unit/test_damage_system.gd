class_name TestDamageSystem
extends GdUnitTestSuite
## DamageSystem (Fase 5): pipeline central de daño — inmunidad, crítico por
## estadísticas, vulnerabilidad, potenciación, bloqueo, rotura de armadura y
## límites. Las fórmulas base ya se prueban en test_combat_service; aquí se
## prueban los modificadores de contexto.


func _attacker(crit_chance := 0.0, crit_multiplier := 1.5) -> CombatStats:
	var stats := CombatStats.new()
	stats.attack_power = 10.0
	stats.primary_attribute = 10.0
	stats.crit_chance = crit_chance
	stats.crit_multiplier = crit_multiplier
	return stats


func _target(armor := 10.0) -> CombatStats:
	var stats := CombatStats.new()
	stats.armor = armor
	stats.resistance = 10.0
	stats.block_reduction = 0.5
	stats.primary_attribute = 10.0
	return stats


func _skill() -> Dictionary:
	return {"potency": 10.0, "damage_coeff": 1.0, "damage_type": "physical"}


func _rng_zero() -> RandomNumberGenerator:
	## RNG determinista que nunca saca crítico (siempre >= chance).
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	return rng


func test_base_damage_passes_armor() -> void:
	var result := DamageSystem.resolve(_attacker(), _target(10.0), _skill(), _rng_zero())
	assert_float(float(result["amount"])).is_greater(0.0)
	assert_bool(bool(result["crit"])).is_false()
	assert_bool(bool(result["immune"])).is_false()


func test_immunity_blocks_everything() -> void:
	var target_status := StatusEffectController.new()
	target_status.apply("invulnerable", 2.0)
	var result := DamageSystem.resolve(_attacker(), _target(), _skill(), _rng_zero(), target_status)
	assert_bool(bool(result["immune"])).is_true()
	assert_float(float(result["amount"])).is_equal(0.0)


func test_armor_break_increases_damage() -> void:
	var normal := DamageSystem.resolve(_attacker(), _target(50.0), _skill(), _rng_zero())
	var broken_status := StatusEffectController.new()
	broken_status.apply("armor_break", 5.0, {"reduction": 0.5})
	var broken := DamageSystem.resolve(_attacker(), _target(50.0), _skill(), _rng_zero(), broken_status)
	assert_float(float(broken["amount"])).is_greater(float(normal["amount"]))


func test_vulnerable_increases_incoming() -> void:
	var normal := DamageSystem.resolve(_attacker(), _target(), _skill(), _rng_zero())
	var vulnerable_status := StatusEffectController.new()
	vulnerable_status.apply("vulnerable", 3.0, {"multiplier": 1.5})
	var vulnerable := DamageSystem.resolve(_attacker(), _target(), _skill(), _rng_zero(), vulnerable_status)
	assert_float(float(vulnerable["amount"])).is_greater(float(normal["amount"]))


func test_block_reduces_by_stats() -> void:
	var blocked := DamageSystem.resolve(_attacker(), _target(), _skill(), _rng_zero(), null, {"blocked": true})
	assert_bool(bool(blocked["blocked"])).is_true()
	## block_reduction 0.5 con tope del 80%: pasa exactamente el 50%.
	assert_float(float(blocked["passed_fraction"])).is_equal_approx(0.5, 0.001)


func test_block_factor_caps_at_80_percent() -> void:
	## Aunque las estadísticas prometan más, el tope global del 80% manda.
	assert_float(CombatService.block_factor(0.95)).is_equal_approx(0.2, 0.001)
	assert_float(CombatService.block_factor(-0.5)).is_equal(1.0)


func test_max_damage_clamp() -> void:
	var result := DamageSystem.resolve(_attacker(), _target(0.0), _skill(), _rng_zero(), null, {"max_damage": 5.0})
	assert_float(float(result["amount"])).is_less_equal(5.0)


func test_min_damage_floor() -> void:
	## Contra armadura brutal, el mínimo de la técnica se respeta.
	var result := DamageSystem.resolve(_attacker(), _target(10000.0), _skill(), _rng_zero(), null, {"min_damage": 3.0})
	assert_float(float(result["amount"])).is_greater_equal(3.0)


func test_empowered_consumed_once() -> void:
	## Pulso de monte: el empowered multiplica el golpe y se consume.
	var attacker := _attacker()
	var attacker_status := StatusEffectController.new()
	attacker_status.apply("empowered", 10.0, {"multiplier": 1.5})
	var boosted := DamageSystem.resolve_attacker_empowered(attacker_status, attacker)
	assert_float(boosted.outgoing_multiplier).is_equal(1.5)
	assert_bool(attacker_status.has("empowered")).is_false()
	# La segunda llamada ya no aplica el bonus (se consumió).
	var second := DamageSystem.resolve_attacker_empowered(attacker_status, attacker)
	assert_float(second.outgoing_multiplier).is_equal(1.0)

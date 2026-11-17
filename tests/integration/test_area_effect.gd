class_name TestArpgAreaEffect
extends GdUnitTestSuite
## Zonas de combate persistentes (Fase 2, Bruja): ticks de dano/estado,
## expiracion y seguimiento del lanzador.


class ZoneDummy:
	extends CharacterBody3D
	var enemy_data := {"armor": 2.0, "resistance": 1.0, "attribute_value": 10.0}
	var hp := 80.0
	var hits := 0
	var statuses := StatusEffectController.new()

	func _init() -> void:
		collision_layer = ArpgLayers.ENEMY
		collision_mask = ArpgLayers.WORLD
		var shape := CollisionShape3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.4
		capsule.height = 1.8
		shape.shape = capsule
		add_child(shape)

	func take_damage(amount: float, _context: Dictionary = {}) -> bool:
		hp -= amount
		hits += 1
		return true

	func apply_status(id: String, duration: float, params: Dictionary = {}) -> void:
		statuses.apply(id, duration, params)

	func get_status_controller() -> StatusEffectController:
		return statuses


class ZoneShooter:
	extends Node3D
	var stats := CombatStats.new()

	func _init() -> void:
		stats.primary_attribute = 20.0

	func resolve_strike(target: Node, def: Dictionary) -> void:
		if target == null or not target.has_method("take_damage"):
			return
		var damage: float = CombatService.arcane_damage(
			float(def.get("potency", 5.0)), float(def.get("damage_coeff", 1.0)), 20.0, 1.0
		)
		target.take_damage(damage, {})


func _frames(count: int) -> void:
	for index: int in count:
		await get_tree().physics_frame


func _wait(seconds: float) -> void:
	## Espera TIEMPO REAL de escena: el runner headless no garantiza 60
	## physics-frames por segundo, asi que las duraciones se esperan por
	## temporizador, no contando frames.
	await get_tree().create_timer(seconds).timeout


func _zone_def(tick_damage: float, status_id: String) -> Dictionary:
	var def := {
		"id": "zona_test",
		"zone": {"radius": 3.0, "duration": 2.0, "tick_interval": 0.25},
	}
	if tick_damage > 0.0:
		def["zone_tick"] = {"potency": 5.0, "damage_coeff": tick_damage, "damage_type": "arcane"}
	if not status_id.is_empty():
		def["zone_status"] = {"id": status_id, "duration": 0.5, "params": {"slow_fraction": 0.4}}
	return def


func test_zone_applies_status_and_expires() -> void:
	var shooter: ZoneShooter = auto_free(ZoneShooter.new())
	add_child(shooter)
	var dummy: ZoneDummy = auto_free(ZoneDummy.new())
	add_child(dummy)
	dummy.global_position = Vector3(1.0, 0.5, 0.5)
	var zone := ArpgAreaEffect.make(
		shooter, _zone_def(0.0, "slow"), Vector3.ZERO, ArpgLayers.HITBOX_PLAYER, ArpgLayers.ENEMY, ArpgLayers.WORLD
	)
	var estado := {"liberada": false}
	zone.area_expired.connect(func() -> void: estado["liberada"] = true)
	add_child(zone)
	await _wait(0.8)
	assert_bool(dummy.statuses.has("slow")).is_true()
	await _wait(3.5)
	assert_bool(bool(estado["liberada"])).is_true()
	assert_bool(not is_instance_valid(zone)).is_true()


func test_zone_ticks_damage_multiple_times() -> void:
	var shooter: ZoneShooter = auto_free(ZoneShooter.new())
	add_child(shooter)
	var dummy: ZoneDummy = auto_free(ZoneDummy.new())
	add_child(dummy)
	dummy.global_position = Vector3(0, 0.5, 0)
	var zone := ArpgAreaEffect.make(
		shooter, _zone_def(0.6, ""), Vector3.ZERO, ArpgLayers.HITBOX_PLAYER, ArpgLayers.ENEMY, ArpgLayers.WORLD
	)
	add_child(zone)
	await _wait(2.6)
	# 2 s de zona con tick 0.25 s: varios golpes, no uno.
	assert_int(dummy.hits).is_greater_equal(4)
	assert_float(dummy.hp).is_less(80.0)


func test_zone_outside_radius_is_not_hit() -> void:
	var shooter: ZoneShooter = auto_free(ZoneShooter.new())
	add_child(shooter)
	var lejos: ZoneDummy = auto_free(ZoneDummy.new())
	add_child(lejos)
	lejos.global_position = Vector3(0, 0.5, -12.0)
	var zone := ArpgAreaEffect.make(
		shooter, _zone_def(0.6, "slow"), Vector3.ZERO, ArpgLayers.HITBOX_PLAYER, ArpgLayers.ENEMY, ArpgLayers.WORLD
	)
	add_child(zone)
	await _wait(1.2)
	assert_int(lejos.hits).is_equal(0)
	assert_bool(not lejos.statuses.has("slow")).is_true()


func test_zone_follows_shooter_when_configured() -> void:
	var shooter: ZoneShooter = auto_free(ZoneShooter.new())
	add_child(shooter)
	shooter.global_position = Vector3.ZERO
	var zone := ArpgAreaEffect.make(
		shooter,
		_zone_def(0.0, "slow"),
		Vector3.ZERO,
		ArpgLayers.HITBOX_PLAYER,
		ArpgLayers.ENEMY,
		ArpgLayers.WORLD,
		true
	)
	add_child(zone)
	await _wait(0.1)
	shooter.global_position = Vector3(8.0, 0.0, 0.0)
	await _wait(0.1)
	assert_float(zone.global_position.x).is_equal_approx(8.0, 0.01)

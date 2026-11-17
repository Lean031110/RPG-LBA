class_name TestArpgProjectile
extends GdUnitTestSuite
## Componente de proyectil (Fase 2): configuracion, expiracion, penetracion
## y danos reales por resolve_strike del dueno.


class ProjectileDummy:
	extends CharacterBody3D
	var enemy_data := {"armor": 2.0, "resistance": 1.0, "attribute_value": 10.0}
	var hp := 50.0
	var hits := 0

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


class DummyShooter:
	extends Node3D
	## Disparador minimo con resolve_strike real por CombatService (el dano
	## de un proyectil SIEMPRE sale del motor comun, nunca del visual).
	var stats := CombatStats.new()

	func _init() -> void:
		stats.primary_attribute = 20.0
		stats.armor = 0.0
		stats.resistance = 0.0

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


func _make_def(pierce: int) -> Dictionary:
	return {
		"id": "proyectil_test",
		"potency": 5.0,
		"damage_coeff": 1.0,
		"damage_type": "arcane",
		"projectile": {"speed": 30.0, "lifetime": 2.0, "radius": 0.4, "pierce": pierce},
	}


func test_projectile_expires_after_lifetime() -> void:
	var shooter: DummyShooter = auto_free(DummyShooter.new())
	add_child(shooter)
	var projectile := ArpgProjectile.make(
		shooter,
		_make_def(0),
		Vector3.FORWARD,
		Vector3.ZERO,
		ArpgLayers.HITBOX_PLAYER,
		ArpgLayers.ENEMY,
		ArpgLayers.WORLD
	)
	var estado := {"expiro": false}
	projectile.projectile_expired.connect(func() -> void: estado["expiro"] = true)
	add_child(projectile)
	assert_bool(is_instance_valid(projectile)).is_true()
	await _wait(3.0)
	assert_bool(bool(estado["expiro"])).is_true()


func test_projectile_penetrates_n_targets_then_dies() -> void:
	var shooter: DummyShooter = auto_free(DummyShooter.new())
	add_child(shooter)
	# Tres dummies alineados en la trayectoria.
	var dummies: Array[ProjectileDummy] = []
	for index: int in 3:
		var dummy: ProjectileDummy = auto_free(ProjectileDummy.new())
		add_child(dummy)
		dummy.global_position = Vector3(0, 0.5, -2.0 - index * 2.0)
		dummies.append(dummy)
	var projectile := ArpgProjectile.make(
		shooter,
		_make_def(2),
		Vector3.FORWARD,
		Vector3(0, 0.5, 0),
		ArpgLayers.HITBOX_PLAYER,
		ArpgLayers.ENEMY,
		ArpgLayers.WORLD
	)
	var estado := {"expiro": false}
	projectile.projectile_expired.connect(func() -> void: estado["expiro"] = true)
	add_child(projectile)
	await _wait(1.2)
	# pierce 2: atraviesa los dos primeros y expira en el tercero.
	assert_int(dummies[0].hits).is_equal(1)
	assert_int(dummies[1].hits).is_equal(1)
	assert_int(dummies[2].hits).is_equal(0)
	assert_bool(bool(estado["expiro"])).is_true()


func test_projectile_damage_is_real_not_visual() -> void:
	var shooter: DummyShooter = auto_free(DummyShooter.new())
	add_child(shooter)
	var dummy: ProjectileDummy = auto_free(ProjectileDummy.new())
	add_child(dummy)
	dummy.global_position = Vector3(0, 0.5, -4.0)
	var hp_inicial: float = dummy.hp
	var projectile := ArpgProjectile.make(
		shooter,
		_make_def(0),
		Vector3.FORWARD,
		Vector3.ZERO,
		ArpgLayers.HITBOX_PLAYER,
		ArpgLayers.ENEMY,
		ArpgLayers.WORLD
	)
	add_child(projectile)
	await _wait(0.8)
	assert_int(dummy.hits).is_equal(1)
	assert_float(dummy.hp).is_less(hp_inicial)
	# Dano esperado por la formula arcana REAL del motor.
	var esperado: float = CombatService.arcane_damage(5.0, 1.0, 20.0, 1.0)
	assert_float(hp_inicial - dummy.hp).is_equal_approx(esperado, 0.001)

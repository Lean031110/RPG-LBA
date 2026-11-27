class_name TestTiradorKit
extends GdUnitTestSuite
## Ataque básico y Doble Fogonazo del Tirador, comprobados mediante proyectiles reales.


class DummyTarget:
	extends CharacterBody3D
	var enemy_data := {"armor": 2.0, "resistance": 1.0, "attribute_value": 10.0}
	var hp := 100.0
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
		if amount <= 0.0:
			return false
		hp -= amount
		hits += 1
		return true


class TiradorTestPlayer:
	extends ArpgPlayer

	func _on_strike_landed(_target: Node, _amount: float, _is_crit: bool, _def: Dictionary) -> void:
		## La suite valida el combate; no incluye presentación visual del impacto.
		pass


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _make_tirador() -> ArpgPlayer:
	var player: ArpgPlayer = auto_free(TiradorTestPlayer.new())
	add_child(player)
	player.setup("tirador")
	player.global_position = Vector3(0.0, 0.5, 0.0)
	return player


func _make_target(target_position: Vector3) -> DummyTarget:
	var target: DummyTarget = auto_free(DummyTarget.new())
	add_child(target)
	target.global_position = target_position
	target.add_to_group("arpg_enemies")
	return target


func _face_target(player: ArpgPlayer, target: Node3D) -> void:
	## El jugador mira hacia +Z; Godot look_at orienta su -Z al objetivo.
	player.look_at(target.global_position, Vector3.UP)
	player.rotate_y(PI)


func after_test() -> void:
	for child: Node in get_children():
		if child is ArpgPlayer and child.skills.is_busy():
			child.skills.interrupt("test_cleanup")
		if child is ArpgProjectile:
			child.free()


func test_setup_uses_tirador_kit_and_canonical_baseline() -> void:
	var player := _make_tirador()
	assert_bool(player.kit is TiradorKit).is_true()
	assert_float(player.max_hp).is_equal(90.0)
	assert_float(player.max_vigor).is_equal(100.0)
	assert_str(player.get_resource_name()).is_equal("Concentración")
	assert_bool(player.kit.can_block()).is_false()
	assert_bool(bool(player.class_data["basic_attack"]["implemented"])).is_true()
	assert_int(player.get_skill_count()).is_equal(1)
	assert_str(String(player.get_skill_def(0)["id"])).is_equal("doble_fogonazo")
	assert_str(RpgDB.get_text("skill.tirador.doble_fogonazo")).is_equal("Doble Fogonazo")
	assert_bool(player.is_skill_unlocked(0)).is_true()
	assert_bool(bool(player.class_data["ultimate"]["implemented"])).is_false()
	assert_bool(bool(player.class_data["playable_in_slice"])).is_false()


func test_basic_attack_deals_real_ranged_physical_damage_without_resource_cost() -> void:
	var player := _make_tirador()
	var target := _make_target(Vector3(0.0, 0.5, 6.0))
	_face_target(player, target)
	var resource_before := player.vigor

	assert_bool(player.try_attack()).is_true()
	assert_float(player.vigor).is_equal(resource_before)
	await _wait(0.7)
	assert_int(target.hits).is_equal(1)
	assert_float(target.hp).is_less(100.0)


func test_basic_attack_respects_cooldown() -> void:
	var player := _make_tirador()
	assert_bool(player.try_attack()).is_true()
	assert_bool(player.try_attack()).is_false()
	assert_float(player.cooldowns.left("attack")).is_greater(0.0)


func test_doble_fogonazo_spends_resource_once_and_lands_two_sequential_hits() -> void:
	var player := _make_tirador()
	var target := _make_target(Vector3(0.0, 0.5, 6.0))
	_face_target(player, target)
	var resource_before := player.vigor

	assert_bool(player.try_skill_index(0)).is_true()
	assert_float(player.vigor).is_equal(resource_before - 20.0)
	assert_float(player.cooldowns.left("doble_fogonazo")).is_greater(0.0)
	assert_bool(player.try_skill_index(0)).is_false()
	await _wait(0.8)
	assert_int(target.hits).is_equal(2)
	assert_float(target.hp).is_less(100.0)


func test_doble_fogonazo_requires_enough_concentracion() -> void:
	var player := _make_tirador()
	player.vigor = 19.0
	assert_bool(player.try_skill_index(0)).is_false()
	assert_float(player.vigor).is_equal(19.0)
	assert_float(player.cooldowns.left("doble_fogonazo")).is_equal(0.0)


func test_interruption_cancels_unfired_followup_shot() -> void:
	var player := _make_tirador()
	var target := _make_target(Vector3(0.0, 0.5, 4.0))
	_face_target(player, target)
	assert_bool(player.try_skill_index(0)).is_true()
	await _wait(0.16)
	player.skills.interrupt("test_interrupt")
	await _wait(0.55)
	assert_int(target.hits).is_equal(1)


func test_basic_projectile_does_not_damage_through_world_geometry() -> void:
	var player := _make_tirador()
	var target := _make_target(Vector3(0.0, 0.5, 6.0))
	_face_target(player, target)

	var wall := StaticBody3D.new()
	wall.collision_layer = ArpgLayers.WORLD
	var wall_shape := CollisionShape3D.new()
	var wall_box := BoxShape3D.new()
	wall_box.size = Vector3(3.0, 4.0, 0.3)
	wall_shape.shape = wall_box
	wall.add_child(wall_shape)
	wall.position = Vector3(0.0, 1.0, 3.0)
	add_child(auto_free(wall))
	await get_tree().physics_frame
	var ray_query := PhysicsRayQueryParameters3D.create(
		player.global_position + Vector3(0.0, 1.0, 0.0),
		target.global_position + Vector3(0.0, 1.0, 0.0),
		ArpgLayers.WORLD
	)
	var ray_hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(ray_query)
	assert_bool(ray_hit.get("collider") == wall).is_true()

	assert_bool(player.try_attack()).is_true()
	await _wait(0.7)
	assert_int(target.hits).is_equal(0)
	assert_float(target.hp).is_equal(100.0)

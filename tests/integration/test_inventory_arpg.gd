class_name TestInventoryArpg
extends GdUnitTestSuite
## Inventario ARPG Fase 3: recibir objetos, equipar arma (validación por datos y bonus de
## potencia), desequipar, serialización/idempotencia y la vía real de recompensa de misión
## (claim de VS_P00 -> machete mellado de Cheo) y de recogida (pickup).


func _make_player() -> ArpgPlayer:
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = ArpgLayers.WORLD
	floor_body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0, -0.55, 0)
	add_child(auto_free(floor_body))
	var player: ArpgPlayer = auto_free(ArpgPlayer.new())
	add_child(player)
	player.setup("machetero")
	player.global_position = Vector3(0, 0.5, 0)
	return player


func test_receive_item_fills_free_slot() -> void:
	var player := _make_player()
	assert_bool(player.receive_item("machete_mellado")).is_true()
	assert_str(player.inventory.get_slot(0).item_id).is_equal("machete_mellado")
	assert_bool(player.receive_item("fragmento_bronce")).is_true()
	assert_str(player.inventory.get_slot(1).item_id).is_equal("fragmento_bronce")


func test_receive_item_rejects_bad_input() -> void:
	var player := _make_player()
	# Cantidad no positiva: no toca el inventario ni emite errores.
	assert_bool(player.receive_item("machete_mellado", 0)).is_false()
	assert_bool(player.receive_item("machete_mellado", -3)).is_false()
	assert_bool(player.inventory.get_slot(0).is_empty()).is_true()


func test_receive_item_fails_when_inventory_full() -> void:
	var player := _make_player()
	for index: int in PlayerInventory.BASE_INVENTORY_SIZE:
		assert_bool(player.receive_item("fragmento_bronce")).is_true()
	assert_bool(player.receive_item("fragmento_bronce")).is_false()


func test_equip_weapon_from_slot() -> void:
	var player := _make_player()
	player.receive_item("machete_mellado")
	assert_bool(player.try_equip_weapon(0)).is_true()
	assert_str(player.inventory.equipped_weapon.item_id).is_equal("machete_mellado")
	assert_bool(player.inventory.get_slot(0).is_empty()).is_true()


func test_equip_rejects_non_weapons() -> void:
	var player := _make_player()
	player.receive_item("fragmento_bronce")
	assert_bool(player.try_equip_weapon(0)).is_false()
	assert_bool(player.inventory.equipped_weapon.is_empty()).is_true()


func test_unequip_returns_weapon_to_free_slot() -> void:
	var player := _make_player()
	player.receive_item("machete_mellado")
	player.try_equip_weapon(0)
	assert_bool(player.try_equip_weapon(-1)).is_true()
	assert_bool(player.inventory.equipped_weapon.is_empty()).is_true()
	assert_str(player.inventory.get_slot(0).item_id).is_equal("machete_mellado")


func test_weapon_grants_potency_bonus() -> void:
	var player := _make_player()
	assert_float(player._weapon_potency_bonus()).is_equal(0.0)
	player.receive_item("machete_mellado")
	player.try_equip_weapon(0)
	# items.json: machete_mellado potency_bonus 3.0 (data-driven).
	assert_float(player._weapon_potency_bonus()).is_equal(3.0)


func test_serialize_roundtrip_keeps_equipped_weapon() -> void:
	var player := _make_player()
	player.receive_item("machete_mellado")
	player.try_equip_weapon(0)
	var data := player.serialize()
	assert_dict(data).contains_keys("inventory")

	var restored: ArpgPlayer = auto_free(ArpgPlayer.new())
	add_child(restored)
	restored.setup("machetero")
	restored.restore(data)
	assert_str(restored.inventory.equipped_weapon.item_id).is_equal("machete_mellado")
	assert_float(restored._weapon_potency_bonus()).is_equal(3.0)


func test_weapon_pickup_goes_to_inventory() -> void:
	var player := _make_player()
	var pickup: ArpgPickup = auto_free(ArpgPickup.new())
	add_child(pickup)
	pickup.global_position = Vector3(0, 0.45, 0)
	pickup.setup("machete_mellado")
	for index: int in 12:
		await get_tree().physics_frame
	assert_str(player.inventory.get_slot(0).item_id).is_equal("machete_mellado")
	assert_bool(is_instance_valid(pickup)).is_false()


func test_quest_claim_grants_machete() -> void:
	# Vía real de la rebanada: claim de VS_P00 entrega poción + machete (recompensa data-driven).
	SaveSystem.save_path = "user://tmp/inventory_claim_%d.json" % (Time.get_ticks_msec() + randi() % 1000)
	QuestSystem.reset_for_new_game()
	var scene: Node = load("res://scenes/arpg/valdeluz/valdeluz_slice.tscn").instantiate()
	var slice: ValdeluzSlice = auto_free(scene) as ValdeluzSlice
	add_child(slice)
	assert_bool(QuestSystem.accept("VS_P00")).is_true()
	for enemy: ShadowOfPortal in slice._enemies:
		slice._on_enemy_died("sombra_de_portal", enemy.global_position, enemy)
	QuestSystem.notify_collect("fragmento_bronce", 1)
	QuestSystem.notify_collect("fragmento_bronce", 1)
	slice._claim_quest()
	assert_str(slice.player.inventory.get_slot(0).item_id).is_equal("machete_mellado")
	if FileAccess.file_exists(SaveSystem.save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.save_path))
	QuestSystem.reset_for_new_game()

class_name PlayerSaveCodec
extends RefCounted
## Códec de persistencia del jugador (Fase 5): serializa/restaura el estado del
## Machetero desde y hacia un diccionario versionado compatible con SaveSystem.
## Extraído de ArpgPlayer para mantener el archivo principal acotado. Nunca
## guarda referencias a nodos: solo valores planos (IDs estables, números,
## posiciones como array).
##
## Compatibilidad: los campos nuevos (attributes_spent, ultimate_charge) usan
## defaults en partidas viejas; los viejos se siguen leyendo sin romperse.


static func serialize(player: ArpgPlayer) -> Dictionary:
	return {
		"class_id": player.class_id,
		"level": player.level,
		"xp_into_level": player.xp_into_level,
		"attribute_points": player.attribute_points,
		"attributes_spent": player.spent_attributes(),
		"hp": player.hp,
		"vigor": player.vigor,
		"potions": player.potions,
		"ultimate_charge": player.get_ultimate_charge(),
		"position": [player.global_position.x, player.global_position.y, player.global_position.z],
		"inventory": player.inventory.to_dict() if player.inventory != null else {},
	}


static func restore(player: ArpgPlayer, data: Dictionary) -> void:
	player.class_id = String(data.get("class_id", player.class_id))
	player.load_class_data()
	player.reset_for_restore()
	player.level = int(data.get("level", 1))
	player.xp_into_level = int(data.get("xp_into_level", 0))
	player.attribute_points = int(data.get("attribute_points", 0))
	player.restore_spent_attributes(data.get("attributes_spent", {}))
	player.recalculate_stats()
	player.hp = clampf(float(data.get("hp", player.max_hp)), 1.0, player.max_hp)
	player.vigor = clampf(float(data.get("vigor", player.max_vigor)), 0.0, player.max_vigor)
	player.potions = int(data.get("potions", 1))
	player.set_ultimate_charge(float(data.get("ultimate_charge", 0.0)))
	var inventory_data: Dictionary = data.get("inventory", {})
	if player.inventory != null and not inventory_data.is_empty():
		player.inventory.from_dict(inventory_data)
	var position_data: Array = data.get("position", [0, 0, 0])
	if position_data.size() == 3:
		player.global_position = Vector3(position_data[0], position_data[1], position_data[2])
	player.notify_equipment_changed()
	player.stats_changed.emit()

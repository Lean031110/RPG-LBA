class_name PlayerEquipment
extends RefCounted
## Puente equipo-jugador del Machetero (Fase 5): valida y equipa armas del
## inventario propio aplicando sus bonuses a las estadísticas (data-driven).
## Extraído de ArpgPlayer para mantener el archivo principal acotado; usa solo
## la superficie pública del jugador.

var _player: ArpgPlayer = null


func setup(player: ArpgPlayer) -> void:
	_player = player


func receive_item(item_id: String, count := 1) -> bool:
	## Guarda un objeto de equipo/misión en el inventario propio. Las pociones
	## siguen en el contador rápido de la rebanada (decisión documentada).
	if _player == null or _player.inventory == null or count <= 0:
		return false
	if RpgDB.get_item(item_id).is_empty():
		push_error("PlayerEquipment: objeto desconocido %s" % item_id)
		return false
	var index := _player.inventory.get_first_empty_slot()
	if index < 0:
		return false
	var slot := _player.inventory.get_slot(index)
	slot.item_id = item_id
	slot.quantity = count
	return true


func try_equip_weapon(slot_index := -1) -> bool:
	## slot_index >= 0: equipa el arma de ese hueco (swap con la equipada). -1:
	## desequipa al primer hueco libre. Valida kind=weapon y la restricción de
	## clase del dato. El bonus se aplica en las estadísticas (data-driven).
	if _player == null or _player.inventory == null:
		return false
	if slot_index < 0:
		return _unequip_weapon_to_free_slot()
	return _equip_weapon_from_slot(slot_index)


func potency_bonus() -> float:
	## Bonus de potencia del arma equipada (items.json "potency_bonus"; 0 sin arma).
	return _weapon_bonus("potency_bonus", 0.0)


func crit_bonus() -> float:
	return _weapon_bonus("crit_bonus", 0.0)


func armor_bonus() -> float:
	return _weapon_bonus("armor_bonus", 0.0)


func _weapon_bonus(field: String, default_value: float) -> float:
	if _player == null or _player.inventory == null:
		return default_value
	if _player.inventory.equipped_weapon.is_empty():
		return default_value
	var item_data := RpgDB.get_item(_player.inventory.equipped_weapon.item_id)
	return float(item_data.get(field, default_value))


func _unequip_weapon_to_free_slot() -> bool:
	## Devuelve el arma equipada al primer hueco libre (no desequipa si no hay hueco).
	var inventory := _player.inventory
	if inventory.equipped_weapon.is_empty():
		return false
	var free := inventory.get_first_empty_slot()
	if free < 0:
		return false
	var target := inventory.get_slot(free)
	target.item_id = inventory.equipped_weapon.item_id
	target.quantity = inventory.equipped_weapon.quantity
	inventory.equipped_weapon.clear()
	_refresh()
	return true


func _equip_weapon_from_slot(slot_index: int) -> bool:
	## Equipa el arma del hueco indicado dejando la anterior en ese mismo hueco.
	var inventory := _player.inventory
	if not inventory.is_slot_active(slot_index):
		return false
	var slot := inventory.get_slot(slot_index)
	if slot == null or slot.is_empty():
		return false
	var item_data := RpgDB.get_item(slot.item_id)
	if String(item_data.get("kind", "")) != "weapon":
		return false
	var required_class := String(item_data.get("class_id", ""))
	if required_class != "" and required_class != _player.class_id:
		return false
	var swap_id := inventory.equipped_weapon.item_id
	var swap_qty := inventory.equipped_weapon.quantity
	inventory.equipped_weapon.item_id = slot.item_id
	inventory.equipped_weapon.quantity = slot.quantity
	slot.item_id = swap_id
	slot.quantity = swap_qty
	if slot.is_empty():
		slot.clear()
	_refresh()
	return true


func _refresh() -> void:
	## Recalcula estadísticas (bonus del arma) y avisa al HUD.
	_player.recalculate_stats()
	_player.notify_equipment_changed()

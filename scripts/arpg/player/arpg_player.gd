class_name ArpgPlayer
extends CharacterBody3D
## Jugador de la vertical slice: Machetero de la Sierra (única clase jugable en la rebanada).
## Definición 100% dirigida por datos (game/data/classes.json); sin fórmulas duplicadas.
## La animación jamás es fuente de verdad del daño: la hitbox solo está activa en su ventana.
## Lógica desacoplada de la UI: el HUD escucha señales y llama métodos públicos.

signal stats_changed
signal leveled_up(new_level: int)
signal died
signal dodged
signal hit_landed(target: Node, amount: float, is_crit: bool)
signal potion_used(healed: float)
signal attack_started(kind: String)

const GRAVITY := 18.0
const HURT_GRACE_TIME := 0.25
const CRIT_CHANCE := 0.05
const BODY_LAYER := ArpgLayers.PLAYER
const BODY_MASK := ArpgLayers.WORLD
const HITBOX_LAYER := ArpgLayers.HITBOX_PLAYER
const HITBOX_MASK := ArpgLayers.ENEMY

var class_id := "machetero"
var class_data: Dictionary = {}
var level := 1
var xp_into_level := 0
var attribute_points := 0
var hp := 1.0
var max_hp := 1.0
var vigor := 1.0
var max_vigor := 1.0
var armor := 0.0
var potions := 1
var joystick_vector := Vector2.ZERO
var is_dodging := false

var _action := "none"
var _action_timer := 0.0
var _action_params: Dictionary = {}
var _attack_cooldown_left := 0.0
var _skill_cooldown_left := 0.0
var _dodge_cooldown_left := 0.0
var _hurt_grace_left := 0.0
var _walk_phase := 0.0
var _hitbox_shape: CollisionShape3D = null
var _hitbox_area: Area3D = null
var _window_open := false
var _bodies_hit_this_swing: Array[Node] = []
var _rng := RandomNumberGenerator.new()
var _puppet: Dictionary = {}
var _dodge_direction := Vector3.FORWARD
var _dead := false


func setup(new_class_id: String) -> void:
	class_id = new_class_id
	class_data = RpgDB.get_class_data(class_id)
	if class_data.is_empty():
		push_error("ArpgPlayer: clase desconocida %s" % class_id)
		return
	collision_layer = BODY_LAYER
	collision_mask = BODY_MASK
	_build_body_shape()
	_reset_stats()
	_build_hitbox()
	_build_visual()


func _build_body_shape() -> void:
	## Capsula de colision del cuerpo: sin ella no hay fisica de jugador (suelo, muros,
	## areas enemigas). El error fue detectado por las pruebas de integracion.
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	shape.position = Vector3(0, 0.95, 0)
	add_child(shape)


func _reset_stats() -> void:
	level = 1
	xp_into_level = 0
	attribute_points = 0
	var base: Dictionary = class_data.get("base_stats", {})
	var resource: Dictionary = class_data.get("resource", {})
	max_hp = float(base.get("hp", 100))
	hp = max_hp
	armor = float(base.get("armor", 0))
	max_vigor = float(resource.get("base", 100))
	vigor = max_vigor
	potions = 1
	_recalculate_from_level()


func _recalculate_from_level() -> void:
	## Crecimiento automático por clase (docs/diseno/02): HP, recurso y armadura por nivel.
	var growth: Dictionary = class_data.get("growth", {})
	var resource: Dictionary = class_data.get("resource", {})
	var levels_from_base := maxi(level - 1, 0)
	max_hp = float(class_data["base_stats"].get("hp", 100)) + float(growth.get("hp_per_level", 0.0)) * levels_from_base
	armor = (
		float(class_data["base_stats"].get("armor", 0)) + float(growth.get("armor_per_level", 0.0)) * levels_from_base
	)
	max_vigor = float(resource.get("base", 100)) + float(resource.get("per_level", 0)) * levels_from_base
	hp = minf(hp, max_hp)
	vigor = minf(vigor, max_vigor)


func get_class_name() -> String:
	return RpgDB.get_text(String(class_data.get("name_key", "")), "es")


func get_resource_name() -> String:
	return RpgDB.get_text(String(class_data.get("resource", {}).get("name_key", "")), "es")


func get_attribute(attribute: String) -> float:
	## Atributo actual (base de datos; los puntos manuales se asignan en Fase 2).
	return float(class_data.get("base_stats", {}).get(attribute, 10))


func get_hp_fraction() -> float:
	return clampf(hp / max_hp, 0.0, 1.0) if max_hp > 0.0 else 0.0


func get_vigor_fraction() -> float:
	return clampf(vigor / max_vigor, 0.0, 1.0) if max_vigor > 0.0 else 0.0


func get_xp_fraction() -> float:
	return ProgressionService.xp_bar_fraction(level, xp_into_level, RpgDB.get_progression())


func get_level() -> int:
	return level


func get_potions() -> int:
	return potions


func add_xp(amount: int) -> void:
	if amount <= 0 or _dead:
		return

		# Diseño de la rebanada: al subir de nivel se restaura por completo (decisión documentada).
	var result := ProgressionService.add_xp(level, xp_into_level, amount, RpgDB.get_progression())
	xp_into_level = int(result["xp_into_level"])
	attribute_points += int(result["points_gained"])
	if int(result["levels_gained"]) > 0:
		level = int(result["level"])
		_recalculate_from_level()
		# Diseño de la rebanada: al subir de nivel se restaura por completo (decisión documentada).
		hp = max_hp
		vigor = max_vigor
		leveled_up.emit(level)
	stats_changed.emit()


func take_damage(amount: float) -> bool:
	## Devuelve true si el daño se aplicó; false si fue esquivado o ignorado.
	if _dead or amount <= 0.0:
		return false
	if is_dodging:
		dodged.emit()
		return false
	if _hurt_grace_left > 0.0:
		return false
	hp = maxf(hp - amount, 0.0)
	_hurt_grace_left = HURT_GRACE_TIME
	_visual_hurt_flash()
	if hp <= 0.0:
		_dead = true
		_visual_die()
		died.emit()
	stats_changed.emit()
	return true


func heal(amount: float) -> float:
	var before := hp
	hp = minf(hp + amount, max_hp)
	stats_changed.emit()
	return hp - before


func try_attack() -> bool:
	return _start_action("attack", class_data.get("basic_attack", {}))


func try_skill() -> bool:
	var skills: Array = class_data.get("skills", [])
	if skills.is_empty():
		return false
	return _start_action("skill", skills[0])


func try_dodge() -> bool:
	if _dead or not _action_params.is_empty() or is_dodging:
		return false
	if _dodge_cooldown_left > 0.0:
		return false
	var cost := float(class_data.get("dodge", {}).get("cost", 15))
	if vigor < cost:
		return false
	var dodge: Dictionary = class_data.get("dodge", {})
	var input_dir := _input_direction()
	_dodge_direction = input_dir if input_dir.length() > 0.1 else transform.basis.z
	_action = "dodge"
	_action_timer = 0.0
	_action_params = dodge
	is_dodging = true
	vigor -= cost
	_dodge_cooldown_left = float(dodge.get("cooldown", 1.2))
	stats_changed.emit()
	return true


func try_potion() -> bool:
	if _dead or potions <= 0 or hp >= max_hp:
		return false
	var item := RpgDB.get_item("pocion_curativa")
	var heal_amount := float(item.get("heal_amount", 40))
	potions -= 1
	var healed := heal(heal_amount)
	potion_used.emit(healed)
	return true


func add_potion(count := 1) -> void:
	potions += count
	stats_changed.emit()


func _start_action(kind: String, params: Dictionary) -> bool:
	if _dead or not _action_params.is_empty() or is_dodging:
		return false
	if params.is_empty():
		return false
	if kind == "attack" and _attack_cooldown_left > 0.0:
		return false
	if kind == "skill" and _skill_cooldown_left > 0.0:
		return false
	if kind == "skill":
		var cost := float(params.get("resource_cost", 0))
		if vigor < cost:
			return false
		vigor -= cost
		stats_changed.emit()
	_action = kind
	_action_timer = 0.0
	_action_params = params
	_bodies_hit_this_swing = []
	attack_started.emit(kind)
	return true


func _input_direction() -> Vector3:
	## Dirección de movimiento en XZ desde teclado + joystick virtual (HUD).
	var keyboard := Vector3(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		0,
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)
	var stick := Vector3(joystick_vector.x, 0, joystick_vector.y)
	var combined := keyboard + stick
	if combined.length() > 1.0:
		combined = combined.normalized()
	return combined


func _physics_process(delta: float) -> void:
	if class_data.is_empty():
		return
	_tick_timers(delta)
	var motion := Vector3.ZERO
	if not is_dodging and _action_params.is_empty():
		var direction := _input_direction()
		var speed := float(class_data.get("move_speed", 4.0))
		motion = direction * speed
		if direction.length() > 0.05:
			_face_towards(direction, delta)
			_walk_phase += delta * speed * 2.4
			_animate_walk(_walk_phase)
		else:
			_animate_idle(delta)
	else:
		_animate_walk(_walk_phase)
	if is_dodging:
		var duration := maxf(float(_action_params.get("duration", 0.3)), 0.05)
		var dodge_speed := float(_action_params.get("distance", 4.0)) / duration
		motion = _dodge_direction * dodge_speed
		_face_towards(_dodge_direction, delta)
	velocity = motion
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if not _action_params.is_empty():
		_process_action(delta)
	_animate_action(delta)


func _tick_timers(delta: float) -> void:
	_attack_cooldown_left = maxf(_attack_cooldown_left - delta, 0.0)
	_skill_cooldown_left = maxf(_skill_cooldown_left - delta, 0.0)
	_dodge_cooldown_left = maxf(_dodge_cooldown_left - delta, 0.0)
	_hurt_grace_left = maxf(_hurt_grace_left - delta, 0.0)


func _process_action(delta: float) -> void:
	_action_timer += delta
	if _action == "dodge":
		var duration := float(_action_params.get("duration", 0.3))
		if _action_timer >= duration:
			_end_action()
		return
	var windup := float(_action_params.get("windup", 0.12))
	var active_until := float(_action_params.get("active_until", 0.3))
	var total := float(_action_params.get("total_time", 0.55))
	if not _window_open and _action_timer >= windup:
		_open_hitbox_window()
	if _window_open and _action_timer <= active_until:
		_apply_hitbox_damage(_action_params)
	if _window_open and _action_timer > active_until:
		_close_hitbox_window()
	if _action_timer >= total:
		if _action == "attack":
			_attack_cooldown_left = float(_action_params.get("cooldown", 0.9))
		elif _action == "skill":
			_skill_cooldown_left = float(_action_params.get("cooldown", 5.0))
		_end_action()


func _end_action() -> void:
	_action = "none"
	_action_params = {}
	_action_timer = 0.0
	is_dodging = false
	_close_hitbox_window()


func _build_hitbox() -> void:
	## Hitbox frontal real: la colisión solo existe dentro de la ventana activa (prompt 01).
	_hitbox_area = Area3D.new()
	_hitbox_area.name = "AttackHitbox"
	_hitbox_area.collision_layer = HITBOX_LAYER
	_hitbox_area.collision_mask = HITBOX_MASK
	_hitbox_area.monitoring = true
	_hitbox_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 2.2, 2.4)
	_hitbox_shape.shape = box
	_hitbox_shape.disabled = true
	_hitbox_shape.position = Vector3(0, 1.0, 1.4)
	_hitbox_area.add_child(_hitbox_shape)
	add_child(_hitbox_area)


func _open_hitbox_window() -> void:
	var reach := float(_action_params.get("range", 2.6))
	var arc_deg := float(_action_params.get("arc_deg", 100.0))
	var chord := 2.0 * reach * sin(deg_to_rad(arc_deg) * 0.5)
	var box := _hitbox_shape.shape as BoxShape3D
	box.size = Vector3(maxf(chord, 1.2), 2.2, reach)
	_hitbox_shape.position = Vector3(0, 1.0, reach * 0.5)
	_hitbox_shape.disabled = false
	_window_open = true


func _close_hitbox_window() -> void:
	if _hitbox_shape != null:
		_hitbox_shape.disabled = true
	_window_open = false


func _apply_hitbox_damage(params: Dictionary) -> void:
	if _hitbox_area == null:
		return
	for body: Node in _hitbox_area.get_overlapping_bodies():
		if body == self or body in _bodies_hit_this_swing:
			continue
		if not body.has_method("take_damage"):
			continue
		_bodies_hit_this_swing.append(body)
		var defense := _target_defense(body, params)
		var attacker_attribute := get_attribute(String(params.get("attribute", "fuerza")))
		var damage := CombatService.damage_from_data(params, attacker_attribute, defense)
		var crit := CombatService.crit_roll(damage, CRIT_CHANCE, _rng)
		body.take_damage(float(crit["damage"]))
		hit_landed.emit(body, float(crit["damage"]), bool(crit["crit"]))


func _target_defense(body: Node, params: Dictionary) -> float:
	var enemy_data: Dictionary = body.get("enemy_data") if body.get("enemy_data") != null else {}
	if String(params.get("damage_type", "physical")) == "arcane":
		return float(enemy_data.get("resistance", 2))
	return float(enemy_data.get("armor", 2))


func _face_towards(direction: Vector3, delta: float) -> void:
	if direction.length() < 0.05:
		return
	var target_yaw := atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(delta * 12.0, 1.0))


func revive(at_position: Vector3) -> void:
	## Respawn tras derrota en la rebanada: conservar progreso de misión y XP (diseño slice).
	if not _dead:
		return
	_dead = false
	hp = max_hp
	vigor = max_vigor
	_hurt_grace_left = 0.0
	_end_action()
	global_position = at_position
	if not _puppet.is_empty():
		var root := _puppet["root"] as Node3D
		root.rotation = Vector3.ZERO
		root.position = Vector3.ZERO
	stats_changed.emit()


func serialize() -> Dictionary:
	return {
		"class_id": class_id,
		"level": level,
		"xp_into_level": xp_into_level,
		"attribute_points": attribute_points,
		"hp": hp,
		"vigor": vigor,
		"potions": potions,
		"position": [global_position.x, global_position.y, global_position.z],
	}


func restore(data: Dictionary) -> void:
	class_id = String(data.get("class_id", class_id))
	class_data = RpgDB.get_class_data(class_id)
	if class_data.is_empty():
		return
	_reset_stats()
	level = int(data.get("level", 1))
	xp_into_level = int(data.get("xp_into_level", 0))
	attribute_points = int(data.get("attribute_points", 0))
	_recalculate_from_level()
	hp = clampf(float(data.get("hp", max_hp)), 1.0, max_hp)
	vigor = clampf(float(data.get("vigor", max_vigor)), 0.0, max_vigor)
	potions = int(data.get("potions", 1))
	var position_data: Array = data.get("position", [0, 0, 0])
	if position_data.size() == 3:
		global_position = Vector3(position_data[0], position_data[1], position_data[2])
	stats_changed.emit()


# ---------------------------------------------------------------------------
# Montaje visual procedural (original, sin assets de terceros). El Art Pass
# (Fase 1B) sustituye este bloque por dirección artística aprobada.
# ---------------------------------------------------------------------------


func _build_visual() -> void:
	var puppet := Node3D.new()
	puppet.name = "MacheteroPuppet"
	add_child(puppet)
	var shirt := VisualKit.flat_material(VisualKit.MAT_SHIRT_OLD)
	var skin := VisualKit.flat_material(VisualKit.MAT_SKIN)
	var pants := VisualKit.flat_material(VisualKit.MAT_PANTS)
	var boots := VisualKit.flat_material(VisualKit.MAT_BOOT)
	var hat := VisualKit.noise_material(VisualKit.MAT_HAT_STRAW, 0.5, 3)
	var blade := VisualKit.flat_material(VisualKit.MAT_BLADE)
	# Torso: guayabera de trabajo.
	VisualKit.add_box(puppet, Vector3(0.52, 0.62, 0.32), Vector3(0, 1.12, 0), shirt)
	VisualKit.add_sphere(puppet, 0.17, Vector3(0, 1.52, 0), skin)
	VisualKit.add_box(puppet, Vector3(0.46, 0.34, 0.30), Vector3(0, 0.72, 0), pants)
	# Sombrero de yarey ancho: silueta reconocible desde cámara alta.
	VisualKit.add_cylinder(puppet, 0.24, 0.16, Vector3(0, 1.64, 0), hat, 10)
	var brim := VisualKit.add_cylinder(puppet, 0.55, 0.05, Vector3(0, 1.60, 0), hat, 12)
	brim.scale = Vector3(1.0, 1.0, 1.0)
	# Piernas con pivote en la cadera para el ciclo de caminar.
	var leg_l := Node3D.new()
	leg_l.position = Vector3(-0.14, 0.62, 0)
	puppet.add_child(leg_l)
	VisualKit.add_box(leg_l, Vector3(0.17, 0.52, 0.19), Vector3(0, -0.28, 0), pants)
	VisualKit.add_box(leg_l, Vector3(0.19, 0.12, 0.27), Vector3(0, -0.55, 0.04), boots)
	var leg_r := Node3D.new()
	leg_r.position = Vector3(0.14, 0.62, 0)
	puppet.add_child(leg_r)
	VisualKit.add_box(leg_r, Vector3(0.17, 0.52, 0.19), Vector3(0, -0.28, 0), pants)
	VisualKit.add_box(leg_r, Vector3(0.19, 0.12, 0.27), Vector3(0, -0.55, 0.04), boots)
	# Brazos con pivote en el hombro; el derecho porta el machete.
	var arm_l := Node3D.new()
	arm_l.position = Vector3(-0.34, 1.34, 0)
	puppet.add_child(arm_l)
	VisualKit.add_box(arm_l, Vector3(0.14, 0.48, 0.16), Vector3(0, -0.22, 0), shirt)
	VisualKit.add_sphere(arm_l, 0.09, Vector3(0, -0.5, 0), skin)
	var arm_r := Node3D.new()
	arm_r.position = Vector3(0.34, 1.34, 0)
	puppet.add_child(arm_r)
	VisualKit.add_box(arm_r, Vector3(0.14, 0.48, 0.16), Vector3(0, -0.22, 0), shirt)
	VisualKit.add_sphere(arm_r, 0.09, Vector3(0, -0.5, 0), skin)
	# Machete: hoja de acero con cabo de madera.
	var machete := Node3D.new()
	machete.position = Vector3(0, -0.52, 0.06)
	machete.rotation_degrees.x = -12.0
	arm_r.add_child(machete)
	VisualKit.add_box(
		machete, Vector3(0.05, 0.16, 0.06), Vector3(0, 0.02, 0), VisualKit.flat_material(VisualKit.MAT_WOOD)
	)
	VisualKit.add_box(machete, Vector3(0.045, 0.52, 0.11), Vector3(0, 0.4, 0.08), blade)
	_puppet = {
		"root": puppet,
		"leg_l": leg_l,
		"leg_r": leg_r,
		"arm_l": arm_l,
		"arm_r": arm_r,
		"brim": brim,
		"torso_mat": shirt,
	}


func _animate_walk(phase: float) -> void:
	if _puppet.is_empty():
		return
	var swing := sin(phase) * 0.55
	(_puppet["leg_l"] as Node3D).rotation.x = swing
	(_puppet["leg_r"] as Node3D).rotation.x = -swing
	(_puppet["arm_l"] as Node3D).rotation.x = -swing * 0.7
	if _action_params.is_empty() and not is_dodging:
		(_puppet["arm_r"] as Node3D).rotation.x = -swing * 0.7


func _animate_idle(delta: float) -> void:
	if _puppet.is_empty():
		return
	_walk_phase += delta * 1.6
	var breathe := sin(_walk_phase) * 0.04
	(_puppet["leg_l"] as Node3D).rotation.x = lerp_angle((_puppet["leg_l"] as Node3D).rotation.x, 0.0, 0.2)
	(_puppet["leg_r"] as Node3D).rotation.x = lerp_angle((_puppet["leg_r"] as Node3D).rotation.x, 0.0, 0.2)
	(_puppet["arm_l"] as Node3D).rotation.x = breathe
	if _action_params.is_empty() and not is_dodging:
		(_puppet["arm_r"] as Node3D).rotation.x = breathe


func _animate_action(delta: float) -> void:
	if _puppet.is_empty():
		return

		# Arco del tajo: atrás en windup, barrido al frente en la ventana activa.
	var arm_r := _puppet["arm_r"] as Node3D
	if not _action_params.is_empty() and (_action == "attack" or _action == "skill"):
		# Arco del tajo: atrás en windup, barrido al frente en la ventana activa.
		var windup := float(_action_params.get("windup", 0.12))
		var total := float(_action_params.get("total_time", 0.55))
		var progress := clampf(_action_timer / maxf(total, 0.05), 0.0, 1.0)
		if _action_timer < windup:
			arm_r.rotation.x = lerp_angle(arm_r.rotation.x, -1.5, minf(delta * 18.0, 1.0))
		else:
			arm_r.rotation.x = lerp_angle(-1.5, 1.1, progress)
	elif is_dodging:
		arm_r.rotation.x = lerp_angle(arm_r.rotation.x, -0.9, minf(delta * 14.0, 1.0))
	elif _action_params.is_empty():
		arm_r.rotation.x = lerp_angle(arm_r.rotation.x, 0.0, minf(delta * 10.0, 1.0))


func _visual_hurt_flash() -> void:
	if _puppet.is_empty():
		return
	var torso := _puppet["torso_mat"] as StandardMaterial3D
	if torso == null:
		return
	torso.emission_enabled = true
	torso.emission = Color(0.9, 0.1, 0.1)
	torso.emission_energy_multiplier = 0.8
	var timer := get_tree().create_timer(0.15)
	timer.timeout.connect(
		func() -> void:
			if torso != null:
				torso.emission_energy_multiplier = 0.0
	)


func _visual_die() -> void:
	if _puppet.is_empty():
		return
	var root := _puppet["root"] as Node3D
	var tween := create_tween()
	tween.tween_property(root, "rotation:x", -PI / 2.0, 0.45)
	tween.parallel().tween_property(root, "position:y", 0.18, 0.45)

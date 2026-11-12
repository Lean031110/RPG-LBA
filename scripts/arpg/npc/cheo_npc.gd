class_name CheoNPC
extends Node3D
## NPC de la vertical slice: Eusebio “Cheo” Marrero (biblia §5).
## Zona de interacción por radio; el diálogo y la misión los coordina la slice,
## este nodo solo expone estado de rango y datos del NPC (desacoplado de UI).

signal player_entered_range
signal player_exited_range

var npc_data: Dictionary = {}
var npc_id := "cheo"
var player_in_range := false

var _interaction_area: Area3D = null
var _tracked_player: Node3D = null
var _idle_phase := 0.0


func setup(new_npc_id: String) -> void:
	npc_id = new_npc_id
	npc_data = RpgDB.get_npc(npc_id)
	if npc_data.is_empty():
		push_error("CheoNPC: NPC desconocido %s" % npc_id)
		return
	# Fase 3: grupo para blips del minimapa (consulta por grupo; sin lógica de juego).
	add_to_group("arpg_npcs")
	_build_interaction_area()
	_build_visual()


func get_npc_name() -> String:
	return RpgDB.get_text(String(npc_data.get("name_key", "")), "es")


func get_interaction_radius() -> float:
	return float(npc_data.get("interaction_radius", 3.0))


func _build_interaction_area() -> void:
	_interaction_area = Area3D.new()
	_interaction_area.name = "InteractionZone"
	_interaction_area.collision_layer = 0
	_interaction_area.collision_mask = ArpgLayers.PLAYER
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = get_interaction_radius()
	shape.shape = sphere
	_interaction_area.add_child(shape)
	add_child(_interaction_area)
	_interaction_area.body_entered.connect(_on_body_entered)
	_interaction_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body == null or not body is CharacterBody3D:
		return
	_tracked_player = body
	if not player_in_range:
		player_in_range = true
		player_entered_range.emit()


func _on_body_exited(body: Node3D) -> void:
	if _tracked_player == null or body != _tracked_player:
		return
	if player_in_range:
		player_in_range = false
		player_exited_range.emit()
	_tracked_player = null


# ---------------------------------------------------------------------------
# Montaje visual procedural (original). El Art Pass (Fase 1B) lo sustituye.
# ---------------------------------------------------------------------------


func _build_visual() -> void:
	var puppet := Node3D.new()
	puppet.name = "CheoPuppet"
	add_child(puppet)
	var shirt := VisualKit.noise_material(Color(0.62, 0.55, 0.42), 0.4, 3)
	var skin := VisualKit.flat_material(VisualKit.MAT_SKIN.darkened(0.12))
	var pants := VisualKit.flat_material(Color(0.34, 0.30, 0.26))
	var hat := VisualKit.noise_material(VisualKit.MAT_HAT_STRAW.darkened(0.2), 0.5, 3)
	var hair := VisualKit.flat_material(Color(0.82, 0.80, 0.74))
	# Cuerpo viejo y ancho: hombros caídos.
	VisualKit.add_box(puppet, Vector3(0.56, 0.58, 0.34), Vector3(0, 1.05, 0), shirt)
	VisualKit.add_sphere(puppet, 0.16, Vector3(0, 1.44, 0), skin)
	VisualKit.add_box(puppet, Vector3(0.5, 0.32, 0.3), Vector3(0, 0.7, 0), pants)
	# Sombrero de yarey grande (silueta desde cámara alta).
	VisualKit.add_cylinder(puppet, 0.26, 0.18, Vector3(0, 1.58, 0), hat, 10)
	VisualKit.add_cylinder(puppet, 0.62, 0.05, Vector3(0, 1.53, 0), hat, 12)
	# Pelo blanco a los lados.
	VisualKit.add_sphere(puppet, 0.12, Vector3(-0.12, 1.48, -0.04), hair)
	VisualKit.add_sphere(puppet, 0.12, Vector3(0.12, 1.48, -0.04), hair)
	# Barba blanca corta.
	VisualKit.add_box(puppet, Vector3(0.14, 0.12, 0.08), Vector3(0, 1.36, 0.12), hair)
	# Piernas quietas con botas.
	VisualKit.add_box(puppet, Vector3(0.17, 0.5, 0.18), Vector3(-0.14, 0.28, 0), pants)
	VisualKit.add_box(puppet, Vector3(0.17, 0.5, 0.18), Vector3(0.14, 0.28, 0), pants)
	VisualKit.add_box(
		puppet, Vector3(0.19, 0.12, 0.26), Vector3(-0.14, 0.06, 0.03), VisualKit.flat_material(VisualKit.MAT_BOOT)
	)
	VisualKit.add_box(
		puppet, Vector3(0.19, 0.12, 0.26), Vector3(0.14, 0.06, 0.03), VisualKit.flat_material(VisualKit.MAT_BOOT)
	)
	# Machete mellado colgado a la espalda (relato: se lo entrega al jugador).
	var blade := VisualKit.flat_material(VisualKit.MAT_BLADE)
	var back_machete := VisualKit.add_box(puppet, Vector3(0.06, 0.62, 0.1), Vector3(0.1, 1.1, -0.2), blade)
	back_machete.rotation_degrees.z = 8.0


func _process(delta: float) -> void:
	## Balanceo suave al esperar: el pueblo sigue vivo aunque el juego esté en pausa visual.
	_idle_phase += delta

class_name ArpgMinimap
extends Control
## Minimapa estilo ARPG móvil (Diablo Immortal / Mobile Legends): render cenital
## ortográfico del mundo en un SubViewport de baja resolución + blips dibujados por
## grupos. Semitransparente, norte fijo (norte = -Z, arriba en pantalla).
## La matemática pura (world_to_blip / facing_to_arrow_angle) es estática: unit-testeable.
## Sin lógica de juego: solo consulta grupos (arpg_enemies/arpg_pickups/arpg_npcs).

const DEFAULT_SPAN := 30.0
const FRAME_ALPHA := 0.35
const TINT_ALPHA := 0.40
const COLOR_FRAME := Color("14161c")
const COLOR_BORDER := Color("2a2e38")
const COLOR_TINT := Color(0.03, 0.05, 0.09)
const COLOR_PLAYER := Color(0.95, 0.93, 0.82)
const COLOR_ENEMY := Color(0.88, 0.22, 0.18)
const COLOR_PICKUP := Color(0.95, 0.72, 0.25)
const COLOR_NPC := Color(0.35, 0.80, 0.40)
const GROUP_ENEMIES := "arpg_enemies"
const GROUP_PICKUPS := "arpg_pickups"
const GROUP_NPCS := "arpg_npcs"
const CAMERA_HEIGHT := 40.0

@export var map_span_world := DEFAULT_SPAN
@export var follow_smoothing := 8.0

var _player: Node3D = null
var _viewport: SubViewport = null
var _camera: Camera3D = null
var _blips: Control = null


static func world_to_blip(offset: Vector3, span_world: float, size_px: Vector2) -> Vector2:
	## Mundo (X=este, Z=sur; norte = -Z) -> píxeles del minimapa con el jugador al centro.
	## Pura: no depende de escena, cámara ni viewport. El llamador decide el recorte.
	return Vector2(
		offset.x / span_world * size_px.x + size_px.x * 0.5,
		offset.z / span_world * size_px.y + size_px.y * 0.5,
	)


static func facing_to_arrow_angle(yaw: float) -> float:
	## Yaw del jugador (atan2(x, z)) -> ángulo del triángulo en pantalla (draw_* de Godot,
	## 0 rad = hacia abajo/+Z, positivo horario). Norte (-Z) apunta arriba; +X apunta derecha.
	return PI - yaw


func _ready() -> void:
	custom_minimum_size = Vector2(224, 168)
	size = Vector2(224, 168)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func set_player(player: Node3D) -> void:
	## Enlaza el jugador seguido y comparte SU mundo 3D con el SubViewport del minimapa.
	_player = player
	if player == null or not is_inside_tree() or not player.is_inside_tree():
		return
	_viewport.world_3d = player.get_world_3d()


func get_map_camera() -> Camera3D:
	return _camera


func get_map_viewport() -> SubViewport:
	return _viewport


func get_span() -> float:
	return map_span_world


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player) or not _player.is_inside_tree():
		return
	var target := _player.global_position + Vector3(0, CAMERA_HEIGHT, 0)
	_camera.global_position = _camera.global_position.lerp(target, minf(delta * follow_smoothing, 1.0))
	_camera.size = map_span_world
	_blips.queue_redraw()


func _build() -> void:
	var frame := Panel.new()
	frame.name = "MapFrame"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _frame_style())
	add_child(frame)

	var container := SubViewportContainer.new()
	container.name = "MapContainer"
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.offset_left = 4.0
	container.offset_top = 4.0
	container.offset_right = -4.0
	container.offset_bottom = -4.0
	container.stretch = true
	frame.add_child(container)

	_viewport = SubViewport.new()
	_viewport.name = "MapViewport"
	_viewport.transparent_bg = true
	container.add_child(_viewport)

	_camera = Camera3D.new()
	_camera.name = "MapCamera"
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = map_span_world
	_camera.near = 1.0
	_camera.far = 120.0
	# En el árbol PRIMERO: la transformada global solo es fiable dentro de la escena.
	_viewport.add_child(_camera)
	# Mirada cenital con norte arriba: rotar -90° en X deja +Y de la cámara apuntando a -Z.
	_camera.rotation = Vector3(-PI / 2.0, 0.0, 0.0)
	_camera.global_position = Vector3(0, CAMERA_HEIGHT, 0)

	var tint := ColorRect.new()
	tint.name = "MapTint"
	tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint.color = Color(COLOR_TINT.r, COLOR_TINT.g, COLOR_TINT.b, TINT_ALPHA)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(tint)

	_blips = Control.new()
	_blips.name = "MapBlips"
	_blips.set_anchors_preset(Control.PRESET_FULL_RECT)
	_blips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_blips.draw.connect(_draw_blips)
	frame.add_child(_blips)


func _draw_blips() -> void:
	if _player == null or not is_instance_valid(_player) or not _player.is_inside_tree():
		return
	var area := _blips.size
	_draw_group_blips(GROUP_ENEMIES, COLOR_ENEMY, 5.0, area)
	_draw_group_blips(GROUP_PICKUPS, COLOR_PICKUP, 4.0, area)
	_draw_group_blips(GROUP_NPCS, COLOR_NPC, 4.0, area)
	# Jugador: triángulo direccional al centro (siempre visible, gira con el yaw real).
	var angle := facing_to_arrow_angle(_player.rotation.y)
	_blips.draw_set_transform(area * 0.5, angle, Vector2.ONE)
	_blips.draw_colored_polygon(
		PackedVector2Array([Vector2(0, -9), Vector2(7, 8), Vector2(0, 4), Vector2(-7, 8)]), COLOR_PLAYER
	)
	_blips.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_group_blips(group: String, color: Color, radius_px: float, area: Vector2) -> void:
	for node in get_tree().get_nodes_in_group(group):
		var entity := node as Node3D
		if entity == null or not is_instance_valid(entity) or not entity.is_inside_tree():
			continue
		var blip := world_to_blip(entity.global_position - _player.global_position, map_span_world, area)
		blip = _clamp_blip(blip, radius_px, area)
		if group == GROUP_PICKUPS:
			(
				_blips
				. draw_colored_polygon(
					PackedVector2Array(
						[
							blip + Vector2(0, -radius_px * 1.3),
							blip + Vector2(radius_px * 1.1, 0),
							blip + Vector2(0, radius_px * 1.3),
							blip + Vector2(-radius_px * 1.1, 0),
						]
					),
					color
				)
			)
		else:
			_blips.draw_circle(blip, radius_px, color)


func _clamp_blip(blip: Vector2, radius_px: float, area: Vector2) -> Vector2:
	## Los blips del borde se quedan visibles (recortados al marco), como en los ARPG de referencia.
	var margin := radius_px + 3.0
	return Vector2(
		clampf(blip.x, margin, maxf(area.x - margin, margin)),
		clampf(blip.y, margin, maxf(area.y - margin, margin)),
	)


func _frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(COLOR_FRAME.r, COLOR_FRAME.g, COLOR_FRAME.b, FRAME_ALPHA)
	style.border_color = COLOR_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	return style

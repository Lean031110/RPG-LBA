extends Node
## Perfiles de calidad (config/quality_profiles.json). Low por defecto (prompt 01 y GDD).
## No se cambia el renderer en runtime (ADR-002); este servicio solo ajusta escala,
## sombras al construir escenas y valores derivados. Sin promesas de FPS sin medición.

signal profile_changed(profile_id: String)

const PROFILES_PATH := "res://config/quality_profiles.json"
const DEFAULT_PROFILE := "low"
const SETTINGS_PATH := "user://settings.json"

var active_profile := DEFAULT_PROFILE
var last_master_volume := 1.0

var _profiles := {}


func _ready() -> void:
	_load_profiles()
	apply_profile(DEFAULT_PROFILE)
	_restore_persisted()


func _load_profiles() -> void:
	if not FileAccess.file_exists(PROFILES_PATH):
		push_error("GraphicsSettings: falta %s" % PROFILES_PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROFILES_PATH))
	if parsed is Dictionary:
		_profiles = parsed


func get_profile_ids() -> Array:
	return _profiles.get("profiles", {}).keys()


func get_profile(profile_id: String) -> Dictionary:
	var profiles: Dictionary = _profiles.get("profiles", {})
	return profiles.get(profile_id, {})


func get_active_settings() -> Dictionary:
	return get_profile(active_profile)


func apply_profile(profile_id: String) -> bool:
	## Aplica el perfil a la sesion actual. Low es la referencia de diseño (art direction §9).
	if get_profile(profile_id).is_empty():
		push_error("GraphicsSettings: perfil desconocido %s" % profile_id)
		return false
	active_profile = profile_id
	var settings := get_profile(profile_id)
	var render_scale := float(settings.get("render_scale_initial", 1.0))
	var viewport := get_tree().root
	viewport.scaling_3d_scale = clampf(render_scale, 0.5, 1.0)
	# Low: sin MSAA; medium/high la activan los perfiles al medir (sin promesa por hardware).
	viewport.msaa_3d = Viewport.MSAA_DISABLED if profile_id == "low" else Viewport.MSAA_2X
	profile_changed.emit(profile_id)
	return true


func vegetation_density() -> float:
	## Densidad de vegetacion usada por los constructores de nivel.
	return float(get_active_settings().get("vegetation_density", 0.45))


func max_visible_particles() -> int:
	return int(get_active_settings().get("max_visible_particles", 40))


func dynamic_shadows_enabled() -> bool:
	var value: Variant = get_active_settings().get("dynamic_shadows", false)
	if value == true:
		return true
	# Los perfiles medium/high traen strings condicionales; comparar sin mezclar tipos.
	var text := str(value)
	return text == "one_directional_light_if_benchmark_passes" or text == "limited_if_benchmark_passes"


func serialize() -> Dictionary:
	return {"quality_profile": active_profile}


func persist_settings(extra := {}) -> void:
	## Ajustes de usuario independientes del guardado de partida (user://settings.json).
	var record := serialize()
	for key: String in extra:
		record[key] = extra[key]
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(record, "\t"))
	file.close()


func _restore_persisted() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
	if parsed is not Dictionary:
		return
	var record: Dictionary = parsed
	var profile_id := String(record.get("quality_profile", DEFAULT_PROFILE))
	if not get_profile(profile_id).is_empty():
		apply_profile(profile_id)
	var volume := float(record.get("master_volume", 1.0))
	_apply_master_volume(volume)


func set_master_volume(volume: float) -> void:
	_apply_master_volume(volume)


func _apply_master_volume(volume: float) -> void:
	var clamped := clampf(volume, 0.0, 1.0)
	last_master_volume = clamped
	var bus_index := AudioServer.get_bus_index("Master")
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(clamped) if clamped > 0.0 else -60.0)


func restore(data: Dictionary) -> void:
	var profile_id := String(data.get("quality_profile", DEFAULT_PROFILE))
	if get_profile(profile_id).is_empty():
		profile_id = DEFAULT_PROFILE
	apply_profile(profile_id)

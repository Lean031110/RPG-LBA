extends Node
## Perfiles de calidad (config/quality_profiles.json, esquema v2).
## - Deteccion de hardware en Android: sugiere el perfil inicial segun la matriz
##   de compatibilidad (docs/16_COMPATIBILIDAD_ANDROID.md); el usuario puede
##   cambiarlo en Ajustes y la eleccion persiste.
## - Resolucion dinamica con histeresis dentro de la ventana del perfil activo.
## - No se cambia el renderer en runtime (ADR-002).
## - Sin promesas de FPS sin medicion real (AGENTS.md §7): target_fps es un tope.

signal profile_changed(profile_id: String)
signal resolution_changed(new_scale: float)

const PROFILES_PATH := "res://config/quality_profiles.json"
const DEFAULT_PROFILE := "low"
const SETTINGS_PATH := "user://settings.json"
const RAM_GB_LOW := 3.0
const RAM_GB_HIGH := 5.0
const SCREEN_LONG_PX_MEDIUM := 1600
const SCREEN_LONG_PX_HIGH := 2200

var active_profile := DEFAULT_PROFILE
var dynamic_resolution := true
var last_master_volume := 1.0
var hardware_report := {}
var suggested_profile := DEFAULT_PROFILE

var _profiles := {}
var _adaptive := ArpgAdaptiveController.new()
var _stats_timer := 0.0
var _stats_window_ms := 0.0
var _stats_frames := 0
var _debug_timer := 0.0


func _ready() -> void:
        _load_profiles()
        hardware_report = detect_hardware()
        suggested_profile = suggest_profile_for(hardware_report)
        var persisted := _read_persisted()
        var initial := String(persisted.get("quality_profile", ""))
        if get_profile(initial).is_empty():
                initial = suggested_profile
        dynamic_resolution = bool(persisted.get("dynamic_resolution", true))
        apply_profile(initial)
        _apply_master_volume(float(persisted.get("master_volume", 1.0)))
        print(
                "GraphicsSettings: model=%s gpu=%s ram=%.1fGB screen=%d sugerido=%s activo=%s res_dinamica=%s" % [
                        String(hardware_report.get("model", "?")),
                        String(hardware_report.get("gpu", "?")),
                        float(hardware_report.get("ram_total_gb", 0.0)),
                        int(hardware_report.get("screen_long_px", 0)),
                        suggested_profile,
                        active_profile,
                        str(dynamic_resolution),
                ]
        )


func _process(delta: float) -> void:
        _stats_window_ms += delta * 1000.0
        _stats_frames += 1
        _stats_timer += delta
        if _stats_timer >= 0.5:
                var avg_ms := _stats_window_ms / float(maxi(_stats_frames, 1))
                _stats_timer = 0.0
                _stats_window_ms = 0.0
                _stats_frames = 0
                if _adaptive.active:
                        var action := _adaptive.note_frame(avg_ms, 0.5)
                        if action != "hold":
                                var viewport := get_tree().root
                                viewport.scaling_3d_scale = clampf(_adaptive.current, 0.5, 1.0)
                                resolution_changed.emit(_adaptive.current)
        if OS.is_debug_build():
                _debug_timer += delta
                if _debug_timer >= 5.0:
                        _debug_timer = 0.0
                        _emit_perf_line()


func _emit_perf_line() -> void:
        ## Telemetria de depuración: datos REALES del proceso en ejecucion (emulador o
        ## dispositivo). No es un benchmark externo y no se declara como tal.
        var fps := int(Performance.get_monitor(Performance.TIME_FPS))
        var mem_static := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
        print(
                "PERF: fps=%d scale=%.2f mem_static=%.1fMB profile=%s" % [
                        fps,
                        get_tree().root.scaling_3d_scale,
                        mem_static,
                        active_profile,
                ]
        )


func _load_profiles() -> void:
        if not FileAccess.file_exists(PROFILES_PATH):
                push_error("GraphicsSettings: falta %s" % PROFILES_PATH)
                return
        var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROFILES_PATH))
        if parsed is Dictionary:
                _profiles = parsed


func _read_persisted() -> Dictionary:
        if not FileAccess.file_exists(SETTINGS_PATH):
                return {}
        var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
        if parsed is Dictionary:
                return parsed
        return {}


func get_profile_ids() -> Array:
        return _profiles.get("profiles", {}).keys()


func get_profile(profile_id: String) -> Dictionary:
        var profiles: Dictionary = _profiles.get("profiles", {})
        return profiles.get(profile_id, {})


func get_active_settings() -> Dictionary:
        return get_profile(active_profile)


func apply_profile(profile_id: String) -> bool:
        ## Aplica el perfil a la sesion actual. `target_fps` se instala como tope
        ## (Engine.max_fps): un tope no es una promesa de alcanzarlo.
        if get_profile(profile_id).is_empty():
                push_error("GraphicsSettings: perfil desconocido %s" % profile_id)
                return false
        active_profile = profile_id
        var settings := get_profile(profile_id)
        var viewport := get_tree().root
        var initial := clampf(float(settings.get("render_scale_initial", 1.0)), 0.5, 1.0)
        viewport.scaling_3d_scale = initial
        viewport.msaa_3d = int(settings.get("msaa", 0))
        var target_fps := int(settings.get("target_fps", 30))
        Engine.max_fps = target_fps if target_fps > 0 else 0
        _adaptive.configure(settings.get("dynamic_resolution", {}), target_fps, initial, dynamic_resolution)
        profile_changed.emit(profile_id)
        return true


func set_dynamic_resolution_enabled(enabled: bool) -> void:
        dynamic_resolution = enabled
        _adaptive.set_enabled(enabled)


# --------------------------------------------------------------------------
# Detección de hardware y matriz de compatibilidad (docs/16).
# --------------------------------------------------------------------------


func detect_hardware() -> Dictionary:
        ## Reune los criterios de la matriz: ABI/API/RAM/GPU/resolucion. El nombre
        ## comercial (model) se reporta pero NO decide el perfil.
        var hw := {
                "platform": OS.get_name(),
                "model": "",
                "ram_total_gb": 0.0,
                "ram_available_gb": 0.0,
                "gpu": String(RenderingServer.get_video_adapter_name()),
                "screen_long_px": 0,
                "api_level": 0,
                "abis": [],
        }
        var mem := OS.get_memory_info()
        hw["ram_total_gb"] = float(mem.get("physical", 0)) / 1073741824.0
        hw["ram_available_gb"] = float(mem.get("available", 0)) / 1073741824.0
        var primary := DisplayServer.screen_get_usable_rect(
                DisplayServer.SCREEN_PRIMARY
        ) if DisplayServer.get_screen_count() > 0 else Rect2i()
        hw["screen_long_px"] = maxi(primary.size.x, primary.size.y)
        if OS.get_name() == "Android":
                # JavaClassWrapper es singleton del engine en esta version; en escritorio
                # get_singleton devuelve null y todo queda en sus valores neutros.
                # API de JavaClass en 4.7.2 (leccion de la corrida 43476646209): los campos
                # estaticos se leen como PROPIEDADES (Build.VERSION.SDK_INT => .SDK_INT),
                # no existe get_static_field().
                var wrapper: Variant = Engine.get_singleton("JavaClassWrapper")
                if wrapper != null:
                        var build_cls: Variant = wrapper.wrap("android.os.Build")
                        if build_cls != null:
                                hw["model"] = String(build_cls.MODEL)
                                var version_cls: Variant = wrapper.wrap("android.os.Build$VERSION")
                                if version_cls != null:
                                        hw["api_level"] = int(version_cls.SDK_INT)
                                var abis: Variant = build_cls.SUPPORTED_ABIS
                                if abis != null:
                                        hw["abis"] = abis
        return hw


static func suggest_profile_for(hw: Dictionary) -> String:
        ## Matriz pura (probable sin hardware): el criterio mas restrictivo gana.
        ## Escritorio: LOW por diseño (referencia); cambio manual en Ajustes.
        if String(hw.get("platform", "")) != "Android":
                return DEFAULT_PROFILE
        var gpu := String(hw.get("gpu", "")).to_lower()
        var ram := float(hw.get("ram_total_gb", 0.0))
        var long_px := int(hw.get("screen_long_px", 0))
        var ram_tier := 0
        if ram >= RAM_GB_HIGH:
                ram_tier = 2
        elif ram >= RAM_GB_LOW:
                ram_tier = 1
        var gpu_tier := 1
        if gpu.contains("powervr") or gpu.contains("swiftshader") or gpu.contains("llvmpipe") \
                        or gpu.contains("softpipe") or gpu.contains("angle (software"):
                gpu_tier = 0
        if gpu.contains("xclipse") or gpu.contains("mali-g7") or gpu.contains("immortalis") \
                        or gpu.contains("adreno (tm) 8"):
                gpu_tier = 2
        if gpu.contains("adreno"):
                var adreno_num := _first_number_after(gpu, "adreno")
                if adreno_num >= 700:
                        gpu_tier = 2
                elif adreno_num in range(600, 700):
                        gpu_tier = maxi(gpu_tier, 1)
                elif adreno_num > 0 and adreno_num < 600:
                        gpu_tier = 0
        var res_tier := 0
        if long_px >= SCREEN_LONG_PX_HIGH:
                res_tier = 2
        elif long_px >= SCREEN_LONG_PX_MEDIUM:
                res_tier = 1
        var tier := mini(mini(ram_tier, gpu_tier), res_tier)
        match tier:
                2:
                        return "high"
                1:
                        return "medium"
                _:
                        return "low"


static func _first_number_after(text: String, marker: String) -> int:
        ## "adreno (tm) 730" -> 730; 0 si no hay numero.
        var at := text.find(marker)
        if at < 0:
                return 0
        var i := at
        while i < text.length() and not (text[i] >= "0" and text[i] <= "9"):
                i += 1
        var start := i
        while i < text.length() and text[i] >= "0" and text[i] <= "9":
                i += 1
        if start == i:
                return 0
        return int(text.substr(start, i - start))


# --------------------------------------------------------------------------
# Accesores por perfil (consumidos por constructores de nivel, VFX y spawners).
# --------------------------------------------------------------------------


func vegetation_density() -> float:
        return float(get_active_settings().get("vegetation_density", 0.45))


func max_visible_particles() -> int:
        return int(get_active_settings().get("max_visible_particles", 40))


func max_active_enemies() -> int:
        ## Tope de enemigos simultaneos; los spawners lo respetan (matriz Redmi 9C).
        return int(get_active_settings().get("max_active_enemies", 4))


func shadow_mode() -> String:
        ## "off" | "player_only" | "one_directional" | "high_quality" (docs/16).
        return String(get_active_settings().get("shadow_mode", "player_only"))


func shadow_max_distance() -> float:
        return float(get_active_settings().get("shadow_max_distance", 14.0))


func view_distance_multiplier() -> float:
        return float(get_active_settings().get("view_distance_multiplier", 0.65))


func target_fps_cap() -> int:
        return int(get_active_settings().get("target_fps", 30))


# --------------------------------------------------------------------------
# Persistencia (user://settings.json) y guardado de partida.
# --------------------------------------------------------------------------


func serialize() -> Dictionary:
        return {
                "quality_profile": active_profile,
                "dynamic_resolution": dynamic_resolution,
        }


func persist_settings(extra := {}) -> void:
        var record := serialize()
        for key: String in extra:
                record[key] = extra[key]
        var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
        if file == null:
                return
        file.store_string(JSON.stringify(record, "\t"))
        file.close()


func set_master_volume(volume: float) -> void:
        _apply_master_volume(volume)


func _apply_master_volume(volume: float) -> void:
        var clamped := clampf(volume, 0.0, 1.0)
        last_master_volume = clamped
        var bus_index := AudioServer.get_bus_index("Master")
        if bus_index >= 0:
                AudioServer.set_bus_volume_db(bus_index, linear_to_db(clamped) if clamped > 0.0 else -60.0)


# La logica de resolucion dinamica vive en ArpgAdaptiveController
# (scripts/arpg/autoloads/adaptive_controller.gd).


func restore(data: Dictionary) -> void:
        var profile_id := String(data.get("quality_profile", DEFAULT_PROFILE))
        if get_profile(profile_id).is_empty():
                profile_id = DEFAULT_PROFILE
        if data.has("dynamic_resolution"):
                dynamic_resolution = bool(data.get("dynamic_resolution", true))
        apply_profile(profile_id)

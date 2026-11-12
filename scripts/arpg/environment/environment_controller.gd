class_name EnvironmentController
extends Node3D
## Controlador regional de cielo, luz solar/lunar, niebla, clima y faroles.
## Compatibility Renderer: sin GI dinámica, volumétricos ni luces con sombras por defecto.

@export_range(300.0, 7200.0, 60.0) var day_length_seconds := 1440.0
@export_range(0.0, 23.95, 0.05) var start_time_hours := 7.25
@export var auto_advance := true
@export_range(1.0, 90.0, 1.0) var weather_transition_seconds := 18.0
@export var enable_rain_particles := true
@export var allow_dynamic_shadows := false

var day_cycle: DayNightCycle
var weather_controller: WeatherController
var world_environment: WorldEnvironment
var active_environment: Environment
var sky_material: ProceduralSkyMaterial
var sun_light: DirectionalLight3D
var rain_particles: CPUParticles3D

var _solar_keyframes: Array = []
var _night_lights: Dictionary = {}


func _ready() -> void:
	day_cycle = DayNightCycle.new()
	day_cycle.configure(day_length_seconds, start_time_hours)
	weather_controller = WeatherController.new()
	weather_controller.transition_seconds = weather_transition_seconds
	_build_solar_keyframes()
	_create_world_environment()
	_create_sun_light()
	_create_rain_particles()
	_apply_visual_state()


func _process(delta: float) -> void:
	if auto_advance:
		day_cycle.advance(delta)
	weather_controller.advance(delta)
	_apply_visual_state()


## Set a synchronized world time without depending on a character or scene script.
func set_world_time_hours(hour: float) -> void:
	if day_cycle == null:
		return
	day_cycle.set_time_hours(hour)
	_apply_visual_state()


func get_world_time_hours() -> float:
	return day_cycle.time_hours if day_cycle != null else start_time_hours


func get_day_period() -> int:
	return day_cycle.get_period() if day_cycle != null else DayNightCycle.Period.DAWN


func get_day_period_name() -> String:
	return day_cycle.get_period_name() if day_cycle != null else "Amanecer"


func get_clock_label() -> String:
	return day_cycle.get_time_label() if day_cycle != null else "06:30"


func set_weather(weather: int, instant: bool = false) -> bool:
	if weather_controller == null:
		return false
	var changed := weather_controller.set_weather(weather, instant)
	if changed and instant:
		_apply_visual_state()
	return changed


func set_weather_by_name(weather_name: String, instant: bool = false) -> bool:
	match weather_name.strip_edges().to_lower():
		"clear", "despejado":
			return set_weather(WeatherController.Weather.CLEAR, instant)
		"overcast", "nublado":
			return set_weather(WeatherController.Weather.OVERCAST, instant)
		"fog", "niebla":
			return set_weather(WeatherController.Weather.FOG, instant)
		"rain", "lluvia":
			return set_weather(WeatherController.Weather.RAIN, instant)
		_:
			return false


func get_weather_name() -> String:
	return weather_controller.get_weather_name() if weather_controller != null else "Despejado"


func get_weather_weight(weather: int) -> float:
	return weather_controller.get_weight(weather) if weather_controller != null else 0.0


func register_night_light(light: OmniLight3D, base_energy: float = -1.0) -> void:
	if light == null:
		return
	var energy := base_energy if base_energy > 0.0 else light.light_energy
	_night_lights[light.get_instance_id()] = {"light": light, "energy": energy}
	_apply_visual_state()


func _create_world_environment() -> void:
	world_environment = WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	active_environment = Environment.new()
	sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.24, 0.39, 0.58)
	sky_material.sky_horizon_color = Color(0.78, 0.68, 0.55)
	sky_material.ground_bottom_color = Color(0.12, 0.13, 0.14)
	sky_material.ground_horizon_color = Color(0.46, 0.43, 0.39)
	sky_material.sun_angle_max = 20.0

	var sky := Sky.new()
	sky.sky_material = sky_material
	active_environment.background_mode = Environment.BG_SKY
	active_environment.sky = sky
	active_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	active_environment.ambient_light_color = Color(0.42, 0.44, 0.48)
	active_environment.ambient_light_energy = 0.8
	active_environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	active_environment.fog_enabled = true
	active_environment.fog_light_color = Color(0.60, 0.66, 0.70)
	active_environment.fog_density = 0.006
	world_environment.environment = active_environment
	add_child(world_environment)


func _create_sun_light() -> void:
	sun_light = DirectionalLight3D.new()
	sun_light.name = "SunMoonLight"
	sun_light.light_color = Color(1.0, 0.88, 0.72)
	sun_light.light_energy = 0.9
	sun_light.shadow_enabled = false
	sun_light.directional_shadow_max_distance = 38.0
	add_child(sun_light)


func _create_rain_particles() -> void:
	if not enable_rain_particles:
		return

	rain_particles = CPUParticles3D.new()
	rain_particles.name = "RainParticles"
	rain_particles.emitting = false
	rain_particles.visible = false
	rain_particles.amount = _get_particle_limit()
	rain_particles.lifetime = 1.35
	rain_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain_particles.emission_box_extents = Vector3(18.0, 5.0, 24.0)
	rain_particles.position = Vector3(0.0, 7.0, 0.0)
	rain_particles.direction = Vector3(-0.06, -1.0, 0.0)
	rain_particles.spread = 3.0
	rain_particles.gravity = Vector3(0.0, -1.5, 0.0)
	rain_particles.initial_velocity_min = 10.0
	rain_particles.initial_velocity_max = 14.0
	rain_particles.speed_scale = 0.15
	rain_particles.color = Color(0.56, 0.68, 0.78, 0.0)

	var drop := QuadMesh.new()
	drop.size = Vector2(0.025, 0.42)
	var drop_material := StandardMaterial3D.new()
	drop_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	drop_material.vertex_color_use_as_albedo = true
	drop_material.albedo_color = Color(1.0, 1.0, 1.0, 0.48)
	drop.material = drop_material
	rain_particles.mesh = drop
	add_child(rain_particles)


func _get_particle_limit() -> int:
	var configured_limit := 40
	if is_instance_valid(GraphicsSettings):
		configured_limit = GraphicsSettings.max_visible_particles()
	return clampi(configured_limit, 12, 80)


func _build_solar_keyframes() -> void:
	## 24-minute default day, authored from the approved Valdeluz palette.
	_solar_keyframes = [
		{
			"hour": 0.0,
			"sky_top": Color(0.018, 0.030, 0.075),
			"sky_horizon": Color(0.075, 0.090, 0.17),
			"ground_bottom": Color(0.035, 0.045, 0.075),
			"ground_horizon": Color(0.10, 0.12, 0.18),
			"ambient": Color(0.11, 0.14, 0.22),
			"ambient_energy": 0.28,
			"sun_color": Color(0.30, 0.38, 0.62),
			"sun_energy": 0.12,
			"sun_angle_x": -90.0,
			"fog_color": Color(0.09, 0.12, 0.20),
			"fog_density": 0.010,
			"lamp_strength": 1.0
		},
		{
			"hour": 5.5,
			"sky_top": Color(0.10, 0.14, 0.26),
			"sky_horizon": Color(0.78, 0.34, 0.22),
			"ground_bottom": Color(0.08, 0.07, 0.10),
			"ground_horizon": Color(0.30, 0.20, 0.18),
			"ambient": Color(0.28, 0.24, 0.27),
			"ambient_energy": 0.48,
			"sun_color": Color(1.0, 0.48, 0.28),
			"sun_energy": 0.38,
			"sun_angle_x": -7.5,
			"fog_color": Color(0.66, 0.40, 0.32),
			"fog_density": 0.009,
			"lamp_strength": 1.0
		},
		{
			"hour": 7.0,
			"sky_top": Color(0.20, 0.36, 0.56),
			"sky_horizon": Color(0.78, 0.67, 0.53),
			"ground_bottom": Color(0.12, 0.14, 0.14),
			"ground_horizon": Color(0.48, 0.42, 0.35),
			"ambient": Color(0.43, 0.42, 0.39),
			"ambient_energy": 0.72,
			"sun_color": Color(1.0, 0.79, 0.60),
			"sun_energy": 0.78,
			"sun_angle_x": 15.0,
			"fog_color": Color(0.64, 0.68, 0.68),
			"fog_density": 0.007,
			"lamp_strength": 0.0
		},
		{
			"hour": 12.0,
			"sky_top": Color(0.25, 0.45, 0.68),
			"sky_horizon": Color(0.75, 0.81, 0.82),
			"ground_bottom": Color(0.14, 0.15, 0.15),
			"ground_horizon": Color(0.52, 0.54, 0.52),
			"ambient": Color(0.56, 0.58, 0.56),
			"ambient_energy": 0.88,
			"sun_color": Color(1.0, 0.94, 0.82),
			"sun_energy": 1.05,
			"sun_angle_x": 90.0,
			"fog_color": Color(0.67, 0.73, 0.76),
			"fog_density": 0.004,
			"lamp_strength": 0.0
		},
		{
			"hour": 17.0,
			"sky_top": Color(0.30, 0.19, 0.24),
			"sky_horizon": Color(0.87, 0.36, 0.18),
			"ground_bottom": Color(0.12, 0.08, 0.10),
			"ground_horizon": Color(0.45, 0.21, 0.16),
			"ambient": Color(0.40, 0.26, 0.23),
			"ambient_energy": 0.58,
			"sun_color": Color(1.0, 0.50, 0.26),
			"sun_energy": 0.68,
			"sun_angle_x": 165.0,
			"fog_color": Color(0.72, 0.37, 0.25),
			"fog_density": 0.006,
			"lamp_strength": 0.0
		},
		{
			"hour": 19.0,
			"sky_top": Color(0.025, 0.035, 0.095),
			"sky_horizon": Color(0.12, 0.085, 0.17),
			"ground_bottom": Color(0.035, 0.045, 0.075),
			"ground_horizon": Color(0.12, 0.10, 0.16),
			"ambient": Color(0.12, 0.14, 0.22),
			"ambient_energy": 0.30,
			"sun_color": Color(0.30, 0.36, 0.60),
			"sun_energy": 0.10,
			"sun_angle_x": 195.0,
			"fog_color": Color(0.10, 0.13, 0.22),
			"fog_density": 0.010,
			"lamp_strength": 1.0
		},
		{
			"hour": 24.0,
			"sky_top": Color(0.018, 0.030, 0.075),
			"sky_horizon": Color(0.075, 0.090, 0.17),
			"ground_bottom": Color(0.035, 0.045, 0.075),
			"ground_horizon": Color(0.10, 0.12, 0.18),
			"ambient": Color(0.11, 0.14, 0.22),
			"ambient_energy": 0.28,
			"sun_color": Color(0.30, 0.38, 0.62),
			"sun_energy": 0.12,
			"sun_angle_x": 270.0,
			"fog_color": Color(0.09, 0.12, 0.20),
			"fog_density": 0.010,
			"lamp_strength": 1.0
		}
	]


func _get_solar_state(hour: float) -> Dictionary:
	var left: Dictionary = _solar_keyframes[0]
	var right: Dictionary = _solar_keyframes[-1]
	for index in range(1, _solar_keyframes.size()):
		var candidate: Dictionary = _solar_keyframes[index]
		if hour <= float(candidate["hour"]):
			left = _solar_keyframes[index - 1]
			right = candidate
			break

	var span := maxf(float(right["hour"]) - float(left["hour"]), 0.001)
	var blend := clampf((hour - float(left["hour"])) / span, 0.0, 1.0)
	blend = blend * blend * (3.0 - 2.0 * blend)
	var state := {}
	for key in ["sky_top", "sky_horizon", "ground_bottom", "ground_horizon", "ambient", "sun_color", "fog_color"]:
		var from_color: Color = left[key]
		var to_color: Color = right[key]
		state[key] = from_color.lerp(to_color, blend)
	for key in ["ambient_energy", "sun_energy", "sun_angle_x", "fog_density", "lamp_strength"]:
		state[key] = lerpf(float(left[key]), float(right[key]), blend)
	return state


func _apply_visual_state() -> void:
	if active_environment == null or day_cycle == null or weather_controller == null:
		return

	var state := _get_solar_state(day_cycle.time_hours)
	var cloud_weight := weather_controller.get_weight(WeatherController.Weather.OVERCAST)
	var fog_weight := weather_controller.get_weight(WeatherController.Weather.FOG)
	var rain_weight := weather_controller.get_weight(WeatherController.Weather.RAIN)
	var cloudiness := clampf(cloud_weight + rain_weight * 0.55, 0.0, 1.0)

	sky_material.sky_top_color = state["sky_top"].lerp(Color(0.20, 0.23, 0.28), cloudiness * 0.24)
	sky_material.sky_horizon_color = state["sky_horizon"].lerp(Color(0.34, 0.39, 0.43), cloudiness * 0.30)
	sky_material.ground_bottom_color = state["ground_bottom"]
	sky_material.ground_horizon_color = state["ground_horizon"]

	var ambient_color: Color = state["ambient"]
	active_environment.ambient_light_color = ambient_color.lerp(Color(0.25, 0.29, 0.33), cloudiness * 0.22)
	active_environment.ambient_light_energy = float(state["ambient_energy"]) * (1.0 - cloudiness * 0.12)
	active_environment.fog_light_color = state["fog_color"].lerp(
		Color(0.43, 0.50, 0.56), maxf(fog_weight, rain_weight * 0.45)
	)
	active_environment.fog_density = clampf(
		float(state["fog_density"]) + fog_weight * 0.014 + rain_weight * 0.003 + cloud_weight * 0.002,
		0.002,
		0.026
	)

	sun_light.light_color = state["sun_color"]
	sun_light.light_energy = float(state["sun_energy"])
	sun_light.rotation_degrees = Vector3(float(state["sun_angle_x"]), 34.0, 0.0)
	sun_light.shadow_enabled = (
		allow_dynamic_shadows
		and GraphicsSettings.dynamic_shadows_enabled()
		and float(state["sun_energy"]) > 0.2
	)

	if rain_particles != null:
		var raining := rain_weight > 0.01
		rain_particles.emitting = raining
		rain_particles.visible = raining
		rain_particles.speed_scale = lerpf(0.15, 1.0, rain_weight)
		rain_particles.color = Color(0.56, 0.68, 0.78, 0.48 * rain_weight)
		if raining:
			_follow_camera_for_rain()
	_apply_night_lights(float(state["lamp_strength"]))


func _follow_camera_for_rain() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		rain_particles.global_position = camera.global_position + Vector3(0.0, 7.0, 0.0)


func _apply_night_lights(strength: float) -> void:
	for instance_id in _night_lights.keys():
		var entry: Dictionary = _night_lights[instance_id]
		var light: OmniLight3D = entry["light"]
		if not is_instance_valid(light):
			_night_lights.erase(instance_id)
			continue
		light.visible = strength > 0.02
		light.light_energy = float(entry["energy"]) * strength

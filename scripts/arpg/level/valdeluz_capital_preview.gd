extends Node3D
## Escena de revisión aislada para la capital. No sustituye la vertical slice jugable.

@export_range(0.25, 1.0, 0.05) var vegetation_density := 0.75


func _ready() -> void:
	# El preview es una herramienta de revision artistica aislada: aplica el perfil
	# "high" (sombras 60 m + escala 1.0) para que la direccion de arte pueda juzgar
	# la ciudad con la calidad maxima del proyecto. El juego en Android seguira
	# usando su propio perfil detectado; esto no persiste en user://settings.json.
	GraphicsSettings.apply_profile("high")
	var environment_controller := EnvironmentController.new()
	environment_controller.name = "EnvironmentController"
	environment_controller.day_length_seconds = 1440.0
	# Tarde dorada (17:00): keyframe mas calido del ciclo real del juego
	# (sol naranja rasante, ambient rojizo, fog ambar) con sombras largas
	# que hacen legible el volumen de la ciudad en la revision artistica.
	environment_controller.start_time_hours = 17.0
	environment_controller.auto_advance = true
	# Vista cenital de revision: reduce la niebla pensada para la camara en tercera
	# persona (API real del controlador) para poder juzgar la ciudad sin velo gris.
	environment_controller.fog_scale = 0.25
	add_child(environment_controller)
	ValdeluzCapitalBuilder.build(self, vegetation_density)
	var camera := get_node_or_null("PreviewCamera") as Camera3D
	if camera != null:
		camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)

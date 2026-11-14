extends Node3D
## Escena de revisión aislada para la capital. No sustituye la vertical slice jugable.

@export_range(0.25, 1.0, 0.05) var vegetation_density := 0.75


func _ready() -> void:
	var environment_controller := EnvironmentController.new()
	environment_controller.name = "EnvironmentController"
	environment_controller.day_length_seconds = 1440.0
	environment_controller.start_time_hours = 9.0
	environment_controller.auto_advance = true
	environment_controller.allow_dynamic_shadows = false
	add_child(environment_controller)
	ValdeluzCapitalBuilder.build(self, vegetation_density)
	var camera := get_node_or_null("PreviewCamera") as Camera3D
	if camera != null:
		camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)

class_name ArpgPickup
extends Area3D
## Objeto recogible de la vertical slice: fragmento de bronce (misión) o poción (drop).
## La recolección notifica a la misión por tipo; la lógica vive en datos, no en el visual.

signal collected(pickup_type: String, amount: int)

const BOB_AMPLITUDE := 0.12
const BOB_SPEED := 2.4
const SPIN_SPEED := 1.8

var pickup_type := "fragmento_bronce"
var amount := 1
var _phase := 0.0
var _base_y := 0.4
var _visual_root: Node3D = null


func setup(new_type: String, start_amount := 1) -> void:
	pickup_type = new_type
	amount = start_amount
	collision_layer = ArpgLayers.PICKUP
	collision_mask = ArpgLayers.PLAYER
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.9
	shape.shape = sphere
	add_child(shape)
	_build_visual()
	_base_y = 0.45
	body_entered.connect(_on_body_entered)


func get_item_id() -> String:
	return pickup_type


func _on_body_entered(body: Node3D) -> void:
	if body == null:
		return
	if not body.has_method("add_potion"):
		return
	collected.emit(pickup_type, amount)
	if pickup_type == "pocion_curativa" and body.has_method("add_potion"):
		body.add_potion(amount)
	queue_free()


func _process(delta: float) -> void:
	if _visual_root == null:
		return
	_phase += delta
	_visual_root.position.y = _base_y + sin(_phase * BOB_SPEED) * BOB_AMPLITUDE
	_visual_root.rotation_degrees.y += SPIN_SPEED * 60.0 * delta


func _build_visual() -> void:
	_visual_root = Node3D.new()
	_visual_root.name = "PickupVisual"
	add_child(_visual_root)
	if pickup_type == "pocion_curativa":
		var glass := VisualKit.flat_material(Color(0.85, 0.88, 0.90))
		var liquid := VisualKit.flat_material(VisualKit.MAT_POTION, VisualKit.MAT_POTION, 0.9)
		VisualKit.add_cylinder(_visual_root, 0.16, 0.34, Vector3(0, 0, 0), glass, 10)
		VisualKit.add_cylinder(_visual_root, 0.10, 0.2, Vector3(0, 0.26, 0), glass, 8)
		VisualKit.add_sphere(_visual_root, 0.07, Vector3(0, 0.38, 0), glass)
		VisualKit.add_cylinder(_visual_root, 0.12, 0.22, Vector3(0, -0.02, 0), liquid, 10)
	else:
		# Fragmento de bronce: tetraedro con bronce cálido y emisión suave.
		var bronze := VisualKit.flat_material(VisualKit.MAT_BRONZE, VisualKit.MAT_BRONZE_GLOW, 0.8)
		VisualKit.add_tetra(_visual_root, 0.34, Vector3(0, 0, 0), bronze)
		VisualKit.add_tetra(_visual_root, 0.18, Vector3(0.28, -0.08, 0.1), bronze).rotation_degrees.y = 40.0
	_visual_root.position.y = _base_y

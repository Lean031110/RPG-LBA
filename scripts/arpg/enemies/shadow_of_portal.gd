class_name ShadowOfPortal
extends CharacterBody3D
## Enemigo de la vertical slice: Sombra de Portal (monstruario, biblia §8).
## FSM dirigida por datos (game/data/enemies.json). El telegráfico (windup carmesí)
## es legible antes del daño; la animación no es fuente de verdad del golpe.
## Preparado para autoridad de servidor: el daño pasa por take_damage(), sin lógica en VFX.

signal enemy_died(enemy_id: String, death_position: Vector3)
signal telegraph_changed(active: bool, progress: float)

enum InternalState { IDLE, CHASE, WINDUP, STRIKE, RECOVER, DEAD }

const GRAVITY := 18.0

var enemy_data: Dictionary = {}
var enemy_id := "sombra_de_portal"
var state: InternalState = InternalState.IDLE
var state_time := 0.0
var hp := 1.0
var max_hp := 1.0

var _target: Node3D = null
var _strike_damage_done := false
var _spawn_position := Vector3.ZERO
var _body_mesh: MeshInstance3D = null
var _eye_l: MeshInstance3D = null
var _eye_r: MeshInstance3D = null
var _eye_energy := 0.0
var _wobble_phase := 0.0


func setup(new_enemy_id: String) -> void:
        enemy_id = new_enemy_id
        enemy_data = RpgDB.get_enemy(enemy_id)
        if enemy_data.is_empty():
                push_error("ShadowOfPortal: enemigo desconocido %s" % enemy_id)
                return
        collision_layer = ArpgLayers.ENEMY
        collision_mask = ArpgLayers.WORLD
        # Fase 3: grupo para blips del minimapa (consulta por grupo; sin lógica de juego).
        add_to_group("arpg_enemies")
        _build_body_shape()
        max_hp = float(enemy_data.get("hp", 45))
        hp = max_hp
        _spawn_position = global_position
        _build_visual()


func _build_body_shape() -> void:
        ## Capsula de colision del enemigo: sin ella no hay fisica (suelo, hitbox del jugador).
        var shape := CollisionShape3D.new()
        var capsule := CapsuleShape3D.new()
        capsule.radius = 0.45
        capsule.height = 2.2
        shape.shape = capsule
        shape.position = Vector3(0, 1.1, 0)
        add_child(shape)


func set_target(target: Node3D) -> void:
        _target = target


func get_state_name() -> String:
        match state:
                InternalState.CHASE:
                        return "chase"
                InternalState.WINDUP:
                        return "windup"
                InternalState.STRIKE:
                        return "strike"
                InternalState.RECOVER:
                        return "recover"
                InternalState.DEAD:
                        return "dead"
                _:
                        return "idle"


func distance_to_player() -> float:
        if _target == null:
                return INF
        return global_position.distance_to(_target.global_position)


func take_damage(amount: float) -> bool:
        if state == InternalState.DEAD or amount <= 0.0:
                return false
        hp = maxf(hp - amount, 0.0)
        _visual_hit_flash()
        if hp <= 0.0:
                _die()
        return true


func _die() -> void:
        state = InternalState.DEAD
        state_time = 0.0
        enemy_died.emit(enemy_id, global_position)
        collision_layer = 0
        _visual_dissolve()


func _physics_process(delta: float) -> void:
        if enemy_data.is_empty():
                return
        state_time += delta
        _wobble_phase += delta
        _animate_idle_wobble()
        match state:
                InternalState.DEAD:
                        velocity = Vector3.ZERO
                        return
                InternalState.IDLE:
                        _process_idle()
                InternalState.CHASE:
                        _process_chase(delta)
                InternalState.WINDUP:
                        _process_windup(delta)
                InternalState.STRIKE:
                        _process_strike(delta)
                InternalState.RECOVER:
                        _process_recover(delta)
        velocity.y = velocity.y - GRAVITY * delta if not is_on_floor() else 0.0
        move_and_slide()


func _process_idle() -> void:
        var detect := float(enemy_data.get("detect_radius", 9.0))
        if _target != null and distance_to_player() <= detect:
                _enter(InternalState.CHASE)


func _process_chase(delta: float) -> void:
        if _target == null:
                _enter(InternalState.IDLE)
                return
        var dist := distance_to_player()
        var lose := float(enemy_data.get("lose_radius", 16.0))
        var attack_range := float(enemy_data.get("attack_range", 2.2))
        if dist > lose:
                _enter(InternalState.IDLE)
                return
        if dist <= attack_range:
                _enter(InternalState.WINDUP)
                return
        var direction := _target.global_position - global_position
        direction.y = 0.0
        direction = direction.normalized()
        velocity.x = direction.x * float(enemy_data.get("move_speed", 3.6))
        velocity.z = direction.z * float(enemy_data.get("move_speed", 3.6))
        _face_towards(direction, delta)


func _process_windup(delta: float) -> void:
        velocity.x = move_toward(velocity.x, 0.0, 24.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 24.0 * delta)
        # Si el objetivo escapa durante el windup, la sombra pierde el interes.
        if _target == null or distance_to_player() > float(enemy_data.get("lose_radius", 16.0)):
                _enter(InternalState.IDLE)
                return
        var windup_time := maxf(float(enemy_data.get("windup_time", 0.75)), 0.05)
        var progress := clampf(state_time / windup_time, 0.0, 1.0)
        _visual_telegraph(progress)
        telegraph_changed.emit(true, progress)
        if _target != null:
                var direction := _target.global_position - global_position
                direction.y = 0.0
                if direction.length() > 0.05:
                        _face_towards(direction.normalized(), delta)
        if state_time >= windup_time:
                _strike_damage_done = false
                _enter(InternalState.STRIKE)


func _process_strike(_delta: float) -> void:
        var window := maxf(float(enemy_data.get("attack_window", 0.25)), 0.05)
        var lunge := float(enemy_data.get("lunge_distance", 1.4))
        var forward := transform.basis.z
        velocity.x = forward.x * (lunge / window)
        velocity.z = forward.z * (lunge / window)
        _visual_telegraph(1.0)
        telegraph_changed.emit(true, 1.0)
        if not _strike_damage_done and state_time >= window * 0.4:
                _strike_damage_done = true
                _try_damage_player()
        if state_time >= window:
                _enter(InternalState.RECOVER)


func _process_recover(_delta: float) -> void:
        velocity.x = 0.0
        velocity.z = 0.0
        _visual_telegraph(0.0)
        telegraph_changed.emit(false, 0.0)
        var recover_time := float(enemy_data.get("recover_time", 1.1))
        if state_time >= recover_time:
                _enter(InternalState.CHASE)


func _try_damage_player() -> void:
        if _target == null or not _target.has_method("take_damage"):
                return

                # Solo daña si el jugador sigue al frente de la sombra en el momento del golpe.
        var reach := float(enemy_data.get("attack_range", 2.2)) + 0.8
        if distance_to_player() > reach:
                return
                # Solo daña si el jugador sigue al frente de la sombra en el momento del golpe.
        var to_player := _target.global_position - global_position
        to_player.y = 0.0
        var forward := transform.basis.z
        if to_player.length() > 0.05 and forward.dot(to_player.normalized()) < 0.35:
                return
        var attribute := get_attribute_value()
        var defense := float(_target.get("armor") if _target.get("armor") != null else 0.0)
        var damage := (
                CombatService
                . damage_from_data(
                        {
                                "potency": float(enemy_data.get("potency", 9.0)),
                                "damage_coeff": float(enemy_data.get("damage_coeff", 1.0)),
                                "damage_type": String(enemy_data.get("damage_type", "physical")),
                        },
                        attribute,
                        defense,
                )
        )
        _target.take_damage(damage)


func get_attribute_value() -> float:
        ## Atributo del monstruo leído de datos (los monstruos usan valor plano, no curva).
        return float(enemy_data.get("attribute_value", 14.0))


func _enter(new_state: InternalState) -> void:
        state = new_state
        state_time = 0.0
        velocity.x = 0.0
        velocity.z = 0.0
        if new_state != InternalState.WINDUP and new_state != InternalState.STRIKE:
                _visual_telegraph(0.0)
                telegraph_changed.emit(false, 0.0)


func _face_towards(direction: Vector3, delta: float) -> void:
        var target_yaw := atan2(direction.x, direction.z)
        rotation.y = lerp_angle(rotation.y, target_yaw, minf(delta * 10.0, 1.0))


# ---------------------------------------------------------------------------
# Montaje visual procedural (original). El Art Pass (Fase 1B) lo sustituye.
# ---------------------------------------------------------------------------


func _build_visual() -> void:
        var puppet := Node3D.new()
        puppet.name = "ShadowPuppet"
        add_child(puppet)
        var body_mat := VisualKit.noise_material(VisualKit.MAT_SHADOW_BODY, 0.4, 4)
        var rim_mat := VisualKit.flat_material(VisualKit.MAT_SHADOW_RIM)
        # Cuerpo alargado: silueta inquietante de 2.2 m.
        _body_mesh = VisualKit.add_cylinder(puppet, 0.34, 1.5, Vector3(0, 1.35, 0), body_mat, 8)
        VisualKit.add_sphere(puppet, 0.26, Vector3(0, 2.15, 0), body_mat)
        # Faldón desgastado (cono invertido bajo el cuerpo).
        VisualKit.add_cone(puppet, 0.62, 0.9, Vector3(0, 0.45, 0), rim_mat).rotation_degrees.x = 180.0
        # Brazos colgantes largos.
        VisualKit.add_cylinder(puppet, 0.09, 1.0, Vector3(-0.42, 1.35, 0.05), body_mat, 6).rotation_degrees.z = 14.0
        VisualKit.add_cylinder(puppet, 0.09, 1.0, Vector3(0.42, 1.35, 0.05), body_mat, 6).rotation_degrees.z = -14.0
        # Ojos ámbar: foco de lectura del enemigo (art direction: carmesí = peligro).
        _eye_l = VisualKit.add_sphere(
                puppet,
                0.07,
                Vector3(-0.09, 2.18, 0.2),
                VisualKit.flat_material(VisualKit.MAT_EYE_AMBER, VisualKit.MAT_EYE_AMBER, 2.2)
        )
        _eye_r = VisualKit.add_sphere(
                puppet,
                0.07,
                Vector3(0.09, 2.18, 0.2),
                VisualKit.flat_material(VisualKit.MAT_EYE_AMBER, VisualKit.MAT_EYE_AMBER, 2.2)
        )
        # ---- Art Pass (Fase 4B): solo nodos visuales, la FSM no cambia ----
        # Capa de filo frío: cilindro levemente mayor con emisión tenue; da el
        # read de "sombra con borde" contra el fondo verde de la manigua.
        var shell_mat := VisualKit.flat_material(VisualKit.MAT_SHADOW_RIM, Color(0.16, 0.2, 0.32), 0.28)
        var shell := VisualKit.add_cylinder(puppet, 0.37, 1.42, Vector3(0, 1.36, 0), shell_mat, 8)
        shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        # Jirones colgantes bajo el faldón, meciéndose con el shader de viento.
        var tatter_mat := ArpgArtKit.wind_material(Color(0.05, 0.06, 0.09), 0.16, 2.4)
        for index: int in 3:
                var angle := TAU * float(index) / 3.0 + 0.6
                var tatter := VisualKit.add_box(
                        puppet,
                        Vector3(0.1, 0.5, 0.02),
                        Vector3(cos(angle) * 0.42, 0.55, sin(angle) * 0.42),
                        tatter_mat
                )
                tatter.rotation_degrees.y = -rad_to_deg(angle)
        # Bruma de suelo: disco oscuro translúcido que asienta la silueta.
        var haze_material := StandardMaterial3D.new()
        haze_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        haze_material.albedo_color = Color(0.03, 0.04, 0.07, 0.38)
        haze_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        var haze := VisualKit.add_cylinder(puppet, 0.75, 0.02, Vector3(0, 0.03, 0), haze_material, 16)
        haze.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _animate_idle_wobble() -> void:
        if _body_mesh == null:
                return
        var wobble := sin(_wobble_phase * 2.0) * 0.05
        _body_mesh.position = Vector3(0, 1.35 + wobble, 0)
        # Art Pass: ascua de reposo; el pulso carmesí del windup lo pisa luego.
        if _eye_l != null and state != InternalState.WINDUP and state != InternalState.STRIKE:
                var ember := 1.8 + sin(_wobble_phase * 3.0) * 0.5
                VisualKit.set_emission(_eye_l, VisualKit.MAT_EYE_AMBER, ember)
                VisualKit.set_emission(_eye_r, VisualKit.MAT_EYE_AMBER, ember)


func _visual_telegraph(progress: float) -> void:
        ## Pulso carmesí creciente durante el windup: área, tiempo y severidad legibles.
        if _eye_l == null or _eye_r == null:
                return
        var telegraph_color := Color(0.76, 0.12, 0.19)
        var energy := 0.6 + progress * 2.4
        VisualKit.set_emission(_eye_l, telegraph_color, energy)
        VisualKit.set_emission(_eye_r, telegraph_color, energy)
        if _body_mesh != null:
                var body_mat := _body_mesh.material_override as StandardMaterial3D
                if body_mat != null:
                        body_mat.emission_enabled = true
                        body_mat.emission = telegraph_color
                        body_mat.emission_energy_multiplier = progress * 0.9
                _body_mesh.scale = Vector3.ONE * (1.0 + progress * 0.06)


func _visual_hit_flash() -> void:
        if _body_mesh == null:
                return
        var body_mat := _body_mesh.material_override as StandardMaterial3D
        if body_mat == null:
                return
        body_mat.emission_enabled = true
        body_mat.emission = Color(0.95, 0.85, 0.75)
        body_mat.emission_energy_multiplier = 1.4
        var timer := get_tree().create_timer(0.12)
        timer.timeout.connect(
                func() -> void:
                        if body_mat != null:
                                body_mat.emission_energy_multiplier = 0.0
        )


func _visual_dissolve() -> void:
        if _body_mesh == null:
                return
        var puppet := _body_mesh.get_parent()
        var tween := create_tween()
        tween.set_ease(Tween.EASE_IN)
        tween.tween_property(puppet, "scale", Vector3(0.05, 0.02, 0.05), 0.55)
        tween.parallel().tween_property(puppet, "position:y", 0.05, 0.55)
        tween.chain().tween_callback(queue_free)

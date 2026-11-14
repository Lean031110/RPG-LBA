# Fase 2 — Lista de seguimiento (estados por tarea)

Estados: COMPLETADO · PENDIENTE · BLOQUEADO · NO PROBADO.
"NO PROBADO" nunca se convierte en "COMPLETADO" sin evidencia real (AGENTS.md §8).

## Personaje y movimiento

| Tarea | Estado | Evidencia / nota |
|---|---|---|
| Aparición del personaje en escena 3D | COMPLETADO (Fase 1) + Fase 2 | `PlayerSpawn` en slice y prototipo; pruebas de montaje. |
| Movimiento en ocho direcciones | COMPLETADO | `test_eight_keyboard_directions`, joystick continuo. |
| Normalización diagonal (sin ventaja en diagonal) | COMPLETADO | `test_diagonal_is_normalized` (velocidad plana). |
| Aceleración/desaceleración | COMPLETADO | `test_acceleration_ramps_up`, `test_deceleration_stops_smoothly`; 24/30 m/s² por defecto. |
| `move_accel`/`move_decel` como datos por clase | PENDIENTE | El código ya los lee; falta decisión de balance (fase de combate). |
| Gravedad y detección de suelo | COMPLETADO (Fase 1) + floor_snap nuevo | `test_gravity_falls_and_lands`, `test_gravity_lands_on_ground`. |
| Movimiento en pendientes razonables | COMPLETADO | Rampas 15.3°; `test_player_climbs_ramp_and_stays_on_floor`. |
| Colisiones con suelo y obstáculos | COMPLETADO (Fase 1) + obstáculos nuevos | `test_boundary_walls_block_player`, capas WORLD. |
| Orientación del modelo según el movimiento | COMPLETADO | Giro hacia la velocidad real (anti-deslizamiento). |
| Permanecer quieto | COMPLETADO | Idle procedural + desaceleración a cero. |
| Movimiento relativo a la cámara | COMPLETADO | `camera_source` + `_to_camera_space`; prueba con yaw 90°. |

## Cámara isométrica

| Tarea | Estado | Evidencia / nota |
|---|---|---|
| Perspectiva coherente (ortográfica) | COMPLETADO (Fase 1) | `test_defaults_match_fase1`. |
| Seguimiento del jugador | COMPLETADO (Fase 1) | `test_follow_converges_smoothly`. |
| Altura/distancia/ángulo/suavidad configurables | COMPLETADO | Propiedades por instancia; `test_configuration_changes_apply`. |
| Zoom limitado | COMPLETADO (Fase 1) | `test_zoom_clamps_to_bounds`. |
| No rotar por controles de movimiento | COMPLETADO | `test_movement_input_does_not_rotate_camera`. |
| Evitar atravesar obstáculos (oclusión) | PENDIENTE | Limitación documentada; se evalúa con el arte final. |
| Zoom táctil (pinch) | PENDIENTE | La arquitectura lo admite; no está en el alcance de esta fase. |

## Entradas PC y Android

| Tarea | Estado | Evidencia / nota |
|---|---|---|
| Input Map centralizado (equivalentes move_up/down/left/right, interact, primary_action, dodge) | COMPLETADO | Equivalencias documentadas (informe C.12): `move_forward/backward/left/right`, `arpg_interact`, `arpg_attack`, `arpg_dodge`. |
| Teclado WASD en PC | COMPLETADO (Fase 1) | `test_keyboard_actions_move_player`, `test_eight_keyboard_directions`. |
| Joystick virtual (zona clara, límites, dirección) | COMPLETADO | `ArpgVirtualJoystick`; pruebas unitarias de la matemática. |
| Zona muerta | COMPLETADO | 0.12; `test_dead_zone_blocks_tiny_offsets`. |
| Liberación en cualquier punto / dedo seguido fuera del área | COMPLETADO (diseño + código) | Seguimiento por índice en `_input`. |
| Multitáctil con dedo real | NO PROBADO | Sin hardware; emulación de ratón comparte el camino de código. |
| Botones de ataque/esquiva/interacción preparados | COMPLETADO (Fase 1) | Clúster del HUD + botón contextual; combatirá en fases siguientes. |
| HUD adaptable a resoluciones | COMPLETADO | `_layout_hud()` + `resized`; landscape 16:9/20:9 objetivo. |

## Escenario de pruebas

| Tarea | Estado | Evidencia / nota |
|---|---|---|
| Suelo, límites, obstáculos, alturas, escala, luz, spawn | COMPLETADO | `PrototypeGroundBuilder` + 8 pruebas. |
| Determinismo del layout | COMPLETADO | `test_layout_is_deterministic` (sin RNG). |
| Escenario como región de Lythara | PENDIENTE | Fuera de alcance: es infraestructura; el Art Pass (1B) trae la ambientación final. |

## Animaciones

| Tarea | Estado | Evidencia / nota |
|---|---|---|
| Idle / caminar con transiciones y sincronía | COMPLETADO (Fase 1) + sincronía por velocidad real | Puppet procedural; sin deslizamiento. |
| Estado "run" | PENDIENTE | Requiere decisión de diseño (velocidad única actual). |
| Modelos/animaciones finales (Art Pass) | PENDIENTE | Fase 1B; hoy montaje procedural original. |

## Exportación y Android

| Tarea | Estado | Evidencia / nota |
|---|---|---|
| Preset `Android Debug` (arm64, sin credenciales) | COMPLETADO | `export_presets.cfg`; APK 44 MB. |
| APK construido y firmado | COMPLETADO | exit 0, `apksigner verify` PASS, solo `lib/arm64-v8a`. |
| `import_etc2_astc` | COMPLETADO | `project.godot` + re-import de `.import`. |
| Ejecución en dispositivo Android real | NO PROBADO | Sin hardware; nada de FPS/compatibilidad se declara. |
| APK en CI (`android-debug.yml`) | PENDIENTE | El workflow existe; requiere `workflow_dispatch`/tag tras abrir la PR (sin credenciales de escritura no se pudo disparar desde aquí). |

## Calidad y documentación

| Tarea | Estado | Evidencia / nota |
|---|---|---|
| Suite GdUnit4 (regresión Fase 1 + nuevas) | COMPLETADO | 132/132, 0 huérfanos. |
| Lint/format | COMPLETADO | `gdlint`/`gdformat --check` en verde. |
| Smoke multijugador | COMPLETADO | 3× `status=PASS`. |
| Informe y lista de pendientes | COMPLETADO | Este documento + informe. |
| Capturas 16:9/20:9 y revisión visual humana | PENDIENTE | Entorno headless; corresponde al Art Pass/UX Pass. |

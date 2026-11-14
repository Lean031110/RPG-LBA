# Informe de implementación — Fase 2: primer prototipo jugable

**Rama:** `feature/phase-2-playable-prototype` (base: `agent/fase1-vertical-slice` @ `56f8b0f`, punta de la cadena PR#2 → PR#3 → PR#4)
**Fecha:** 2026-11-13
**Motor:** Godot 4.7.2 Standard · GDScript · Compatibility Renderer (ADR-002, sin cambios)
**Definición de fase:** especificación del responsable ("RPG LBA — FASE 2: PRIMER PROTOTIPO JUGABLE"), 18 secciones.

---

## A. Resumen

**Objetivo:** el primer prototipo 3D jugable — personaje controlable, movimiento en ocho direcciones, cámara isométrica, colisiones, escenario de pruebas, controles PC + táctiles y arquitectura preparada para combate.

**Resultado:** PARCIAL→COMPLETADO según la matriz de aceptación (sección G). El hallazgo central de la auditoría es que la Fase 1 publicada ya entregaba una parte importante de este objetivo (jugador con movimiento+gravedad, cámara isométrica con zoom, joystick básico, HUD con botones, animación procedural sincronizada, 108 pruebas). Esta Fase 2 cerró los huecos reales sin re-implementar lo que ya funcionaba:

1. Movimiento con aceleración/desaceleración (antes: velocidad instantánea).
2. Movimiento relativo a la cámara (antes: eje mundial fijo; hoy identidad por defecto y seguimiento de yaw cuando se asigna `camera_source`).
3. `floor_snap_length` para bajar rampas sin micro-vuelos.
4. Cámara isométrica 100 % configurable (ángulo/offset/suavidad/zoom por instancia) sin cambio de comportamiento por defecto.
5. Joystick virtual reconstruido como control autónomo (`ArpgVirtualJoystick`): seguimiento de UN dedo por índice, liberación en cualquier punto de la pantalla, zona muerta, emulación con ratón.
6. HUD re-colocable en tiempo real según resolución (16:9 y 20:9 landscape).
7. Escenario de pruebas dedicado (`prototype_ground`) con rampas, plataforma, obstáculos, referencias de escala y punto de aparición.
8. Exportación Android verificada de extremo a extremo (preset `Android Debug`, arm64, APK firmado con `apksigner`).
9. 24 pruebas nuevas; regresión total 132/132.

**No confundir fase terminada con juego terminado:** esta fase NO añade combate, clases, misiones ni contenido (sección 10 de la especificación: base técnica, no el RPG completo).

## B. Auditoría inicial (estado real antes de tocar nada)

- **Cadena de integración:** `main` (solo Fase 0) ← PR#2 `docs/vision-cubana-dark-fantasy` ← PR#3 `docs/classes-progression-open-campaign` ← PR#4 `agent/fase1-vertical-slice` (Fase 1 reconstruida y publicada; 108/108 GdUnit4 y CI verde según su informe con Actions reales). Ninguna está fusionada; por eso la base de esta rama es la punta de la cadena (56f8b0f), que contiene las tres.
- **Se respetaron los archivos de otros agentes:** esta fase no toca `docs/narrativa/*`, `docs/diseno/*`, `docs/direccion-artistica/*`, `prompts/09*`, `prompts/10*`, `AGENTS.md` ni `docs/01_GDD.md` (en vuelo en PR#2/#3). La única edición compartida es una fila aditiva en `README.md` y una línea del pie del menú, ambos ya presentes en la cadena base.
- **Artefacto de entorno:** el clon local mostraba 825 archivos "modificados" sin cambios de contenido (`mode change 100644→100755`, 0 inserciones/borrados). Es un artefacto del sandbox (todo marcado ejecutable). Corregido con `git config core.filemode false`; árbol limpio desde entonces. No es trabajo de ningún agente y no se versionó nada de eso.
- **Faltaba `export_presets.cfg`:** el `.gitignore` heredado de la plantilla lo ignoraba, y por eso `android-debug.yml` (que lo busca en el repo) jamás podía construir APK. Corregido en esta fase (sección E).
- **Contradicción documentada (AGENTS.md §1):** la "Fase 2" del roadmap interno (`docs/09_ROADMAP`) es *combate y seis clases*; la "FASE 2" de esta especificación del propietario es *el primer prototipo jugable*. Prevalece la definición del propietario (es la más reciente y la que autoriza este trabajo). El documento de roadmap pertenece a PR#2/#3 en vuelo y NO se editó aquí; cuando esa cadena se integre, el responsable debería renumerar (lo que hoy es "Fase 2 del roadmap" pasa a ser una fase posterior). No se improvisó una tercera estructura.
- **Error nativo detectado y corregido durante la implementación:** `class_name VirtualJoystick` oculta una clase nativa de Godot 4.7.2 (error de parseo en import estricto). Renombrado a `ArpgVirtualJoystick` siguiendo la convención `Arpg*` del proyecto.

## C. Funcionalidades implementadas

1. **Aceleración/desaceleración** en `ArpgPlayer`: `velocity` planar persigue el objetivo con `move_toward` (24 m/s² / 30 m/s² por defecto; sobre-escribibles por clase con `move_accel`/`move_decel` en `classes.json` cuando el balance lo aporte — mismo patrón que `move_speed`).
2. **Movimiento relativo a la cámara:** `_to_camera_space()` proyecta la base de la cámara (aplanada a XZ) sobre la entrada; sin `camera_source` asignada es la identidad (compatibilidad Fase 1). La esquiva también hereda el marco de cámara.
3. **`floor_snap_length = 0.25`** en el jugador: contacto estable en descensos.
4. **Giro y ciclo de caminar siguen la velocidad REAL del cuerpo** (no la entrada): evita deslizamiento visual durante la rampa de aceleración.
5. **Durante acciones/esquiva el cuerpo se frena en seco** (comportamiento Fase 1 conservado para el combate).
6. **Cámara configurable:** `pitch_degrees`, `follow_offset`, `follow_smoothing`, `zoom_min/max/step`, `ortho_size` como propiedades por instancia, con los valores por defecto exactos de la Fase 1. `get_camera()` expuesto para futuras mejoras (shake/transiciones).
7. **`ArpgVirtualJoystick` (control nuevo):** dedo seguido por índice vía `_input` (ve todos los eventos táctiles del viewport), arrastre fuera del área sin perder el seguimiento, liberación en cualquier punto (nunca queda pegado), zona muerta 0.12, recorte del recorrido, emulación con botón izquierdo del ratón para escritorio, matemática pura estática (`value_from_offset`) testeable sin escena.
8. **HUD adaptable:** `_layout_hud()` re-coloca paneles, joystick, clúster de acciones, botón de interacción y diálogo al cambiar el tamaño del viewport (`root.resized`); clamps para anchos pequeños; objetivo landscape 16:9/20:9.
9. **Escenario de pruebas `prototype_ground`:** determinista (sin RNG), con suelo+camino de tierra roja, límites invisibles + postes, 6 obstáculos con colisión, plataforma de piedra 0.75 m, dos rampas a ~15.3° (cara superior a ras de la línea de pendiente: sin escalón en la unión), marco de puerta de 2.1 m y farol de 3.2 m como referencias de escala, iluminación de media mañana sin sombras dinámicas (perfil Low), `PlayerSpawn`, jugador+cámara+HUD+pausa cableados. Sin combate, sin misiones, sin guardado (es infraestructura).
10. **Entrada de menú:** botón "Prototipo (Fase 2)" en el menú principal.
11. **Exportación Android:** preset `Android Debug` (arm64-v8a, sin Gradle, sin credenciales) + `import_etc2_astc=true` en `project.godot` (requisito del motor para arm64; re-importó los `.import` existentes). APK construido y firmado localmente; `android-debug.yml` queda operativo.
12. **Convención de entradas (decisión documentada):** el Input Map existente ya cubre los equivalentes pedidos — `move_forward/move_backward` ≡ `move_up/move_down`, `arpg_interact` ≡ `interact`, `arpg_attack` (J/LMB) ≡ `primary_action`, `arpg_dodge` (Espacio) ≡ `dodge`. NO se duplicaron acciones nuevas: renombrar quebraría la Fase 1 (tests y scripts) sin aportar valor; la equivalencia queda documentada aquí.

## D. Archivos creados

| Ruta | Descripción |
|---|---|
| `scripts/arpg/ui/arpg_virtual_joystick.gd` | Control de joystick táctil autónomo (señal `value_changed`, matemática estática testeable). |
| `scripts/arpg/level/prototype_ground_builder.gd` | Constructor determinista del escenario de pruebas (grupos Ground/WorldEnvironment/Boundaries/Obstacles/Heights/ScaleRefs). |
| `scripts/arpg/level/prototype_ground.gd` | Orquestador del prototipo: jugador, cámara, HUD, pausa; sin guardado ni misiones. |
| `scenes/arpg/prototype/prototype_ground.tscn` | Escena del prototipo (`PlayerSpawn` + HUD). |
| `export_presets.cfg` | Preset `Android Debug` (arm64-v8a, `use_gradle_build=false`, sin keystore). |
| `tests/unit/test_virtual_joystick.gd` | 6 casos: zona muerta, recorte, signos, factor Fase 1, emisión de señal. |
| `tests/unit/test_camera_rig.gd` | 5 casos: valores por defecto, límites de zoom, convergencia suave, cámara sin rotación por movimiento, re-configuración. |
| `tests/integration/test_movement_physics.gd` | 5 casos: aceleración, desaceleración, gravedad/aterrizaje, marco de cámara con yaw 90°, ocho direcciones de teclado. |
| `tests/integration/test_prototype_ground.gd` | 8 casos: grupos, rectángulo jugable, capas, determinismo, montaje de escena, subida/bajada de rampa, muros que bloquean, gravedad. |
| `docs/reportes/FASE_02_INFORME_DE_IMPLEMENTACION.md` | Este informe. |
| `docs/reportes/FASE_02_PENDIENTES.md` | Lista de seguimiento con estados. |
| `+ .uid` de cada script y escena nuevos | Generados por el importador (convención del repo). |

## E. Archivos modificados

| Ruta | Motivo |
|---|---|
| `scripts/arpg/player/arpg_player.gd` | Modelo de movimiento (acel/desacel/floor_snap/marco de cámara); giro y pasos según velocidad real; 20 métodos públicos (límite gdlint respetado: el setter de cámara se volvió asignación directa `player.camera_source = rig`). |
| `scripts/arpg/player/iso_camera_rig.gd` | Constantes → propiedades configurables por instancia; mismo comportamiento por defecto. |
| `scripts/arpg/ui/arpg_hud.gd` | Joystick delegado a `ArpgVirtualJoystick`; `_layout_hud()` + `root.resized`; API pública y campos usados por pruebas intactos. |
| `scripts/arpg/ui/arpg_main_menu.gd` | Botón "Prototipo (Fase 2)"; pie de menú actualizado. |
| `tests/integration/test_player_movement.gd` | Waits 6→26 fotogramas (asentamiento de la aceleración) y velocidad plana (la caída libre no es parte del modelo de movimiento). Justificado en el propio archivo. |
| `project.godot` | `rendering/textures/vram_compression/import_etc2_astc=true` (requisito arm64). |
| `.gitignore` | Deja de ignorar `export_presets.cfg`; ignora `export_credentials.cfg` y `*.keystore` (AGENTS.md §4: credenciales nunca en el repo). |
| 8 × `assets/**/*.png.import` | Re-import por ETC2/ASTC (`imported_formats` + `path.etc2`); efecto esperado del ajuste anterior. |
| `README.md` | Fila aditiva en "Estado real" (archivo compartido; cambio mínimo sobre la versión de la cadena). |

## F. Arquitectura

**Movimiento (ArpgPlayer._physics_process):**
1. `_input_direction()` combina teclado (Input Map) + `joystick_vector` (HUD/joystick), normaliza la diagonal (>1) y la rota al marco de la cámara (`_to_camera_space`, identidad sin cámara).
2. La velocidad planar persigue `dirección × move_speed` con `move_toward(accel·Δ)`; al soltar, frena con `decel`.
3. `move_and_slide()` resuelve colisiones (muros/rampas/obstáculos); gravedad solo fuera del suelo; `floor_snap` en contactos.
4. Presentación separada de la lógica: el "puppet" procedural gira hacia la velocidad real y su ciclo de pasos escala con ella (sin deslizamiento). El daño nunca depende de la animación (ventanas de hitbox intactas de la Fase 1).

**Cámara (IsoCameraRig):** Node3D con `Camera3D` ortográfica hija; `follow_offset` + `pitch_degrees` posicionan; `follow_smoothing` lerpea en `_physics_process`; zoom con rueda clampeado. No rota por movimiento. Preparada para zoom/pan posteriores; oclusión documentada como limitación (sección J).

**Entradas:** Input Map del proyecto (equivalencias en C.12); el teclado usa acciones; el táctil llega por `ArpgVirtualJoystick._input` (índice de dedo) y emite `value_changed`; el HUD lo re-emite como `joystick_changed`; el slice/prototipo lo conecta a `player.joystick_vector`. Un solo camino de datos, sin lógica de juego en la UI.

**Escenario de pruebas:** `PrototypeGroundBuilder` (estático, determinista) construye geometría+luz; `PrototypeGround` orquesta spawn de jugador/cámara/HUD/pausa; la escena `.tscn` solo lleva el marcador y el HUD. Patrón idéntico al de la vertical slice (ValdeluzBuilder/ValdeluzSlice) para que el combate futuro pueda reutilizar ambos.

## G. Pruebas (comandos exactos y resultados reales)

Binario: `/home/z/my-project/tools/godot/Godot_v4.7.2-stable_linux.x86_64` (4.7.2.stable.official.ed1daf0bf). Logs locales en `artifacts/logs/` (no se versionan; `artifacts/` está en `.gitignore`).

| # | Prueba | Comando | Resultado |
|---|---|---|---|
| 1 | Import pass 1 | `godot --headless --path . --import` | PASS (sin errores) |
| 2 | Import pass 2 (estricto) | `godot --headless --editor --path . --quit --verbose` + grep `SCRIPT ERROR:\|Parse Error:\|Failed loading resource:\|ERROR:` | PASS (96 líneas de log, 0 errores; detectó aquí el error `VirtualJoystick` nativo, corregido) |
| 3 | Smoke escena principal | `timeout 90s godot --headless --audio-driver Dummy --path . --quit-after 180` + grep | PASS |
| 4 | Smoke prototipo (nuevo) | `timeout 90s godot --headless --audio-driver Dummy --path . res://scenes/arpg/prototype/prototype_ground.tscn --quit-after 240` + grep | PASS |
| 5 | Lint | `gdlint scripts tests` | PASS (0 problemas; detectó >20 métodos públicos, corregido sin tocar reglas) |
| 6 | Formato | `gdformat --check scripts tests` | PASS (61 archivos sin cambios) |
| 7 | GdUnit4 completo | `GODOT_BIN=… ./addons/gdUnit4/runtest.sh --headless "--audio-driver Dummy" --continue --add res://tests` | **132/132 PASS, 0 errores, 0 fallos, 0 skipped, 0 huérfanos, exit 0** (108 de Fase 1 + 24 nuevos) |
| 8 | Regresión multijugador | `GODOT_BIN=… bash tests/multiplayer/run_multiplayer_smoke.sh .` | PASS (servidor + 2 clientes, 3× `status=PASS`, exit 0) |
| 9 | Export Android (nuevo) | `godot --headless --path . --export-debug "Android Debug" artifacts/android/RPG-LBA-debug.apk` | **PASS exit 0**; primera ejecución abortó (exit 134) porque el daemon `adb` no estaba activo: arrancado `adb start-server`, re-ejecución limpia. APK 44 MB. |
| 10 | Firma APK | `build-tools/35.0.1/apksigner verify --print-certs …apk` | PASS (certificado debug Godot) |
| 11 | Arquitecturas del APK | `unzip -l …apk \| grep lib/` | Solo `lib/arm64-v8a/` (`libgodot_android.so`, `libc++_shared.so`) + `assets/assets.sparsepck` — las claves `architectures/arm64-v8a=true` / `architectures/x86_64=false` del preset son correctas |
| 12 | Cifras de suite | `grep Overall Summary` | 19 archivos de suite (15 de Fase 1 + 4 nuevos), 132 casos |

Entorno local del export: OpenJDK 21 + Android SDK (cmdline-tools, platform-tools, build-tools;35.0.1) + plantillas 4.7.2-stable instaladas en `~/.local/share/godot/export_templates/4.7.2.stable/` (nombre con punto: exigido por el motor; el workflow de CI usa el mismo). CI usa Temurin 17; equivalencia razonable, el CI es la referencia definitiva.

## H. Evidencias

- Logs locales: `artifacts/logs/{import_pass1,import_pass2,smoke_main,smoke_prototype,gdunit_full,mp_smoke,export_android}.log` (no versionados).
- APK local: `artifacts/android/RPG-LBA-debug.apk` + `.idsig` (no versionados; `builds/` y `artifacts/` en `.gitignore`).
- El keystore de depuración usado por el motor vive en `~/.local/share/godot/keystores/` (fuera del repo; el log del export lo redacta solo).
- **Sin capturas de gameplay:** el entorno es headless; la revisión visual humana queda pendiente (AGENTS.md §10). No se inventaron capturas.
- CI de GitHub: se activará solo al abrir la PR (`validate.yml` responde a `pull_request`; `android-debug.yml` es `workflow_dispatch`/tags). Sin credenciales de escritura en este entorno no se pudo disparar ni verificar desde aquí: quedará evidenciable en la propia PR al abrirla.

## I. Pendientes

Ver `FASE_02_PENDIENTES.md` (estados por tarea). Resumen: prueba en dispositivo Android real, FPS medidos, capturas 16:9/20:9 y revisión visual humana, animación "run" (requiere decisión de diseño/datos), oclusión de cámara, zoom táctil (pinch), `move_accel/move_decel` como datos de clase cuando el balance lo pida.

## J. Limitaciones

1. **Android en hardware: NO PROBADO.** El APK se construye y firma, pero no hay dispositivo Android en este entorno. Ningún FPS, temperatura ni compatibilidad se declara (AGENTS.md §7).
2. **Cámara sin oclusión:** con el ángulo alto y el offset actual el caso es raro; un `SpringArm3D` u oclusión se evaluará cuando el arte final introduzca interiores/vegetación densa. Documentado en el propio script.
3. **Animación "run":** no existe estado de carrera (velocidad única por diseño de la rebanada). Requiere decisión de diseño (¿sprint? ¿dato por clase?) antes de implementarse; la estructura procedural la admitiría (el ciclo escala con la velocidad real).
4. **Sin revisiones visuales humanas** (headless). El HUD/escenario siguen siendo base provisional hasta el Art Pass + UX Pass (Fase 1B), que sigue siendo prioridad obligatoria antes de ampliar contenido.
5. **Multitáctil real (dedo físico):** la lógica está cubierta por diseño y por pruebas de la matemática pura; la emulación de `InputEventScreenTouch/Drag` con hardware no fue posible aquí. La emulación con ratón comparte el mismo camino de código.
6. **El export necesita `adb` activo** para finalizar limpio (Godot consulta dispositivos tras exportar): documentado en G.9; en CI el paso de SDK ya lo deja listo.

## K. Compatibilidad

- **PC:** verificado en Linux headless — import, smokes, 132/132 pruebas, lint/format, export Android como proceso. El teclado (WASD/J/K/Espacio/Q/E + rueda) funciona por diseño del Input Map; la parte visual requiere revisión humana.
- **Android:** exportación y firma verificadas (arm64). Ejecución en dispositivo, joystick con dedo real, `user://`, FPS y `sensor_landscape`: NO PROBADO (sin hardware). El proyecto declara `handheld/orientation=4` y stretch `canvas_items/expand`, pensado para landscape.

## L. Riesgos para la siguiente fase (combate)

1. **No acoplar el joystick al HUD de nuevo:** el control es `ArpgVirtualJoystick`; el HUD solo re-emite. Cualquier botón nuevo de habilidad debe seguir ese patrón (señal → jugador), sin lógica de juego en la UI.
2. **La aceleración interactúa con el combate:** durante acciones la velocidad se frena en seco (Fase 1). Al implementar nuevas acciones (cancellables, combos) decidir explícitamente qué pasa con el momentum; hoy se conserva la frenada.
3. **La cámara sigue sin rotar por movimiento** y el movimiento ya es camera-relative: si una fase futura añade yaw de cámara, el marco del jugador lo hereda solo (probar con la prueba `test_movement_frame_follows_camera_yaw` como plantilla).
4. **`classes.json` gana `move_accel/move_decel` opcionalmente** — no duplicar fórmulas: los datos mandan sobre los defaults (patrón existente).
5. **Export Android:** nunca versionar keystores (`.gitignore` ya cubre `*.keystore`/`export_credentials.cfg`); el preset no lleva credenciales. `package/unique_name="com.lbagames.rpglba"` es un identificador provisional pendiente de decisión del propietario.
6. **El escenario `prototype_ground` es infraestructura:** no convertirlo en contenido del juego; las regiones reales llegan con el Art Pass y el streaming por zonas (arquitectura 06).

## M. Próximos pasos

1. **Abrir/revisar la PR de esta fase** (verificar CI: validate + godot-ci; disparar `android-debug.yml` por `workflow_dispatch` para el artifact del APK).
2. **Art Pass + UX Pass (Fase 1B)** — sigue siendo la puerta obligatoria (AGENTS.md §10): terreno/cielo/día-noche/clima, HUD legible, capturas 16:9 y 20:9, revisión visual humana.
3. **Prueba en dispositivo Android real** (idealmente el Redmi 9C del GDD) con el APK debug: registrar modelo, RAM, FPS y renderer.
4. **Combate y clases** (la "Fase 2" del roadmap interno, a renumerar): seis clases, XP 1–30, balance con evidencia.
5. Decidir sprint/"run" (dato por clase) y oclusión de cámara en su momento.

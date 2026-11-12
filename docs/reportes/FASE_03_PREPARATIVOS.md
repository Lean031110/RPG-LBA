# Informe de preparativos — Fase 3: HUD móvil, minimapa, correr/caminar e inventario

**Rama:** `agent/fase3-preparativos-hud-minimap` (base: `feature/phase-2-playable-prototype` @ `4411698`, PR#6)
**Fecha:** 2026-11-13
**Motor:** Godot 4.7.2 Standard · GDScript · Compatibility Renderer (ADR-002, sin cambios)
**Definición:** petición del propietario tras la entrega de la Fase 2: subir a GitHub y verificar Actions; preparar la siguiente fase verificando HUD organizado, orientación horizontal obligatoria, controles estilo Diablo Immortal / Mobile Legends: Bang Bang (semitransparentes), minimapa, animaciones de caminar/correr, combate, inventario, daño al jugador, multijugador y organización de assets.

---

## A. Resumen

**Estado de la Fase 2 (publicación):** rama `feature/phase-2-playable-prototype` empujada, **PR#6 abierta** (base `agent/fase1-vertical-slice`, punta de la cadena PR#2→#3→#4) y **CI `validate.yml` en verde** en sus cinco verificaciones: import+smoke estricto, smoke multijugador (servidor + 2 clientes), auditoría de manifiesto de assets, suite GdUnit4 completa y reporte de pruebas. Sin merge automático (regla del repositorio).

**Preparativos Fase 3 (esta rama):** se implementó y verificó lo que pedía el propietario para la siguiente fase, sin tocar los archivos en vuelo de otros agentes (PR#2/#3/#5):

1. **HUD reorganizado estilo ARPG móvil** (Diablo Immortal / MLBB): joystick abajo-izquierda, **clúster de acciones en arco** abajo-derecha (ataque como botón más grande, 104 px; habilidad/esquiva/poción decrecientes), **todo semitransparente**, paneles de stats/misión arriba-izquierda, minimapa arriba-derecha y botón de mochila bajo el minimapa.
2. **Minimapa cenital** (`ArpgMinimap`): render ortográfico real del mundo en SubViewport de baja resolución (224×168), norte fijo, tinte semitransparente y **blips por grupos** (enemigos rojos, recogibles dorados, NPC verdes, jugador = triángulo direccional).
3. **Caminar/correr** por magnitud de entrada: deflexión baja del joystick camina (analógico, estilo MLBB), deflexión alta o teclado **corren** (×1.55, dato por clase `run_multiplier`). Animación diferenciada (amplitud de zancada, inclinación y bombeo de brazos escalan con el fundido `run_blend`; la frecuencia ya escalaba con la velocidad real).
4. **Inventario ARPG**: el jugador tiene inventario propio (slots + arma equipada), el **machete mellado de Cheo** llega como recompensa de VS_P00 (data-driven), equipar suma `potency_bonus` al daño de la hitbox, brilla el acero del machete visual y hay **panel de mochila** (rejilla semitransparente, tecla I / botón).
5. **Verificaciones pedidas** (existían de Fase 1/2 y se re-verificaron con pruebas reales): combate (ventanas de hitbox, daño, crítico, esquiva), jugador recibe daño (golpe de la Sombra, i-frames, HUD), multijugador (smoke servidor + 2 clientes PASS local y en CI), orientación **landscape obligatoria** (`sensor_landscape`, nunca vertical, con test de regresión), assets organizados (manifiesto + iconos nuevos originales).
6. **Iconos UI originales** (machete, tajo, esquiva, frasco, fragmento, morral) generados proceduralmente por el proyecto: cero riesgo de licencia, en `assets/ui/icons/` + manifiesto.
7. **Capturas reales del juego** (16:9 y 20:9) obtenidas con render por software bajo xvfb y verificadas con un modelo de visión: HUD legible, sin solapamientos, sin glitches. Commiteadas en `screenshots/arpg/`.
8. **170/170 pruebas** (132 previas + 38 nuevas), lint/format limpios, import doble estricto limpio, smokes de las tres escenas limpios, smoke multijugador PASS.

## B. Funcionalidades implementadas (detalle)

### HUD móvil (scripts/arpg/ui/arpg_hud.gd, reescritura controlada)
- Conserva **toda la API pública y los campos que usan las pruebas de Fase 1** (barras, etiquetas, diálogo, prompt de interacción, joystick, toast).
- Botones de acción circulares con icono + pista de tecla (J/K/ESP/Q), ordenados en arco alrededor de la esquina inferior-derecha (`_place_arc_button`, ángulo/radio). El ataque es el más grande (referencia Diablo Immortal/MLBB).
- Alfas: paneles 0.42, botones 0.35 (hover 0.55, presionado 0.85), joystick 0.42/0.82, barras 0.45. La escena sigue visible a través de todo el HUD.
- `_layout_hud()` re-coloca todo (16:9 y 20:9) y una prueba nueva verifica **sin solapamientos** (joystick vs clúster, botones entre sí, minimapa vs stats) en ambas resoluciones.
- Acción nueva `arpg_inventory` (tecla I) para abrir/cerrar la mochila; también con botón de morral bajo el minimapa.

### Minimapa (scripts/arpg/ui/arpg_minimap.gd, nuevo)
- SubViewport (224×168) + cámara ortográfica cenital (norte = -Z arriba), sigue al jugador con suavizado, comparte el mundo 3D del jugador (`world_3d`).
- Blips dibujados por grupos: `arpg_enemies` (rojo), `arpg_pickups` (dorado, rombo), `arpg_npcs` (verde), jugador (triángulo que gira con el yaw real). Recorte al marco para que los blips del borde no desaparezcan.
- Matemática pura estática (`world_to_blip`, `facing_to_arrow_angle`) unit-testeable sin escena.
- Rendimiento móvil: resolución baja, sin sombras, actualización por visibilidad; es infraestructura lista para el Art Pass (marco/mapa artístico llegan luego).

### Caminar/correr (scripts/arpg/player/arpg_player.gd)
- `_raw_input()` expone la magnitud sin normalizar; `RUN_INPUT_THRESHOLD = 0.6` separa caminar de correr.
- Caminar: velocidad de clase × deflexión analógica (el vector dirección conserva la magnitud < 1). Correr: velocidad de clase × `run_multiplier` (machetero 1.55 en `classes.json`; los datos mandan sobre el default).
- **Teclado = correr** (magnitud 1.0): estándar ARPG (Diablo Immortal/MLBB no tienen botón de andar). Decisión documentada; las pruebas de Fase 2 que asumían velocidad única se ajustaron con justificación en el propio archivo (precedente Fase 2).
- Animación: `_run_blend` (0→1 suave) escala amplitud de zancada (0.55→0.88), inclinación del torso (hasta 0.14 rad) y bombeo de brazos; la cadencia escala con la velocidad real (anti-deslizamiento de Fase 2). `move_tier` ("idle"/"walk"/"run") es público para HUD/minimapa.

### Inventario de armas (scripts/arpg/ui/arpg_inventory_panel.gd nuevo + arpg_player.gd)
- `ArpgPlayer.inventory: PlayerInventory` (del kit, reutilizado sin duplicar lógica) serializado en `serialize()/restore()` (compatibilidad con saves viejos: sin clave = vacío).
- `receive_item()` (equipo/misión), `try_equip_weapon(slot)` / `try_equip_weapon(-1)` (equipar/desequipar con validación `kind=weapon` + restricción de clase del dato).
- **Bonus de daño data-driven**: el arma equipada suma `potency_bonus` (machete +3) dentro de la hitbox, sin fórmulas nuevas (pasa por `CombatService`).
- Recompensa de VS_P00 ahora entrega poción + **machete mellado de Cheo** (coherente con la historia del objeto). Se descartó el drop aleatorio de arma: rompería la prueba determinista de drops de la Fase 1 (3 pociones exactas) y añadiría RNG innecesario.
- `ArpgPickup` entiende armas (visual de mini-machete + `receive_item`), camino genérico listo para drops de la Fase 3.
- Panel "Mochila": rejilla 8×2 semitransparente, hueco de arma equipada con bonus, cerrar con I o botón. Sin lógica de juego en la UI (delega en el jugador).

### Daño al jugador y combate (verificación de lo existente + cobertura)
- El flujo completo ya existía desde Fase 1 y quedó re-verificado en esta rama por la suite: Sombra detecta → persigue → telegrafía → golpea → **el jugador recibe daño** (con armadura, gracia de 0.25 s, i-frames de esquiva) → HUD actualiza barras → muerte → reintento; y jugador → ventana de hitbox → daño/crítico → muerte de Sombra → XP → drop. Pruebas: `test_enemy_ai`, `test_attack_window`, `test_combat_service`, `test_hud_binding`, `test_scene_flow` (todas en verde, 170/170).

### Multijugador (verificación)
- Smoke real servidor + 2 clientes en localhost: **PASS local** (registro y spawn de jugadores en los tres procesos) y **PASS en CI** (job `multiplayer-smoke` de PR#6).
- La base (autoload `Network`, RPCs de registro/sincronización, lista de jugadores, chat) funciona; el gameplay ARPG sigue siendo single-player. La integración multijugador del ARPG (autoridad de servidor sobre enemigos/combate) es Fase 5 según `docs/05_MULTIJUGADOR_Y_SERVIDOR.md` y `prompts/06_MULTIJUGADOR_LAN.md`.

### Assets y organización
- Iconos UI originales (obra del proyecto, generados con script versionado `scripts/…/make_ui_icons.py` → versión local del agente) en `assets/ui/icons/` con fila nueva en `assets/manifest.csv`. Auditoría de manifiesto: PASS (7 filas).
- Capturas reales commiteadas: `screenshots/arpg/fase3_{menu,prototipo_16x9,prototipo_20x9,slice,slice_inventario}_16x9.png`.
- No se tocó `assets/` de terceros; las atribuciones y licencias existentes quedan intactas.

## C. Archivos creados

| Ruta | Descripción |
|---|---|
| `scripts/arpg/ui/arpg_minimap.gd` | Minimapa cenital semitransparente con blips por grupos; matemática estática testeable. |
| `scripts/arpg/ui/arpg_inventory_panel.gd` | Panel de mochila semitransparente (rejilla + arma equipada); sin lógica de juego. |
| `assets/ui/icons/*.png` (6) | Iconos originales: machete, tajo, esquiva, frasco, fragmento, morral. |
| `scripts/local/capture_hud.gd` | Herramienta de capturas reales del juego (xvfb/escritorio) para revisión visual. |
| `tests/unit/test_minimap.gd` | 8 casos: matemática de blips/ángulos, estructura, mundo compartido, seguimiento de cámara, grupos. |
| `tests/unit/test_project_settings.gd` | 6 casos: orientación landscape obligatoria, stretch, renderer, escena principal, acciones, capas. |
| `tests/integration/test_run_movement.gd` | 6 casos: caminar analógico, correr, teclado corre, dato por clase, fundido visual. |
| `tests/integration/test_hud_fase3.gd` | 8 casos: arco de botones, semitransparencia, posiciones, sin solapamientos 16:9/20:9, mochila, regresión API. |
| `tests/integration/test_inventory_arpg.gd` | 10 casos: recibir/equipar/desequipar, bonus, serialización, pickup, recompensa de misión. |
| `screenshots/arpg/*.png` (5) | Capturas reales (render software) del menú, prototipo 16:9/20:9, slice y mochila. |
| `docs/reportes/FASE_03_PREPARATIVOS.md` | Este informe. |
| `docs/reportes/FASE_03_PENDIENTES.md` | Lista de seguimiento con estados. |
| `+ .uid` de cada script nuevo | Convención del repositorio (generados por el importador). |

## D. Archivos modificados

| Ruta | Motivo |
|---|---|
| `scripts/arpg/player/arpg_player.gd` | Tiers caminar/correr (+animación), inventario propio, equipar arma con bonus, serialización; limpieza de comentarios duplicados (artefacto de edición previa); excepción `gdlint: ignore=max-public-methods` documentada (22 métodos: la clase absorbe inventario y locomoción; regla global intacta). |
| `scripts/arpg/ui/arpg_hud.gd` | Reescritura controlada: arco de botones con iconos, semitransparencia, minimapa, botón/panel de mochila, acción I. API de Fase 1 intacta. |
| `scripts/arpg/ui/arpg_virtual_joystick.gd` | Alfas 0.55→0.42 (base) y 0.92→0.82 (perilla): controles más ligeros, misma matemática. |
| `scripts/arpg/enemies/shadow_of_portal.gd` | `add_to_group("arpg_enemies")` (blips de minimapa). |
| `scripts/arpg/npc/cheo_npc.gd` | `add_to_group("arpg_npcs")` (blips verdes). |
| `scripts/arpg/pickups/arpg_pickup.gd` | Grupo de minimapa, visual de arma, camino genérico `receive_item` (armas de drops futuros). |
| `scripts/arpg/level/valdeluz_slice.gd` | Recompensas de equipo al inventario + toast; toast al recoger arma. |
| `scripts/inventory/inventory_slot.gd` | `from_dict` conserva ids desconocidos para ItemDatabase del kit (el ARPG usa RpgDB; p. ej. machete_mellado). Solo se acota apilado si se conoce el ítem. |
| `game/data/classes.json` | `run_multiplier: 1.55` en machetero (dato por clase). |
| `game/data/items.json` | `potency_bonus: 3.0` en machete_mellado. |
| `game/data/quests.json` | VS_P00 recompensa poción + machete mellado. |
| `project.godot` | Acción `arpg_inventory` (I); descripciones de grupos de minimapa en `[global_group]`. |
| `assets/manifest.csv` | Fila de los iconos UI originales. |
| `tests/integration/test_movement_physics.gd` | Ajustes justificados (teclado/deflexión máxima ahora corre, 6.51 m/s). Intención de los casos intacta. |
| `tests/integration/test_player_movement.gd` | Ídem (velocidad de clase y diagonal). |
| `tests/integration/test_prototype_ground.gd` | Rampa con deflexión de caminar (a velocidad de carrera el ascenso sobrepasa la plataforma y el caso deja de medir lo que mide). |
| `tests/unit/test_quest_system.gd` | `has_size(2)` en recompensas de VS_P00 (poción + machete; claim único sigue igual). |
| `README.md` | Fila aditiva en "Estado real". |

## E. Decisiones de diseño (documentadas)

1. **Teclado corre por defecto**; el joystick camina con deflexión baja (referencia MLBB). `run_multiplier` es dato por clase.
2. **Machete por recompensa de misión**, no por drop aleatorio (determinismo, coherencia narrativa, prueba de drops intacta).
3. **Pociones fuera del inventario** por ahora (contador rápido de la rebanada): el inventario de esta fase es de equipo; la economía completa (apilado en inventario, vendedor, rarezas) es la Fase 3 plena según `prompts/03_INVENTARIO_ECONOMIA.md`.
4. **Excepción gdlint por archivo** (`max-public-methods` en `arpg_player.gd`, 22 vs 20) en lugar de relajar la regla global o vaciar la API.
5. **Minimapa norte fijo** (sin rotación con jugador): legibilidad y coste mínimo; la rotación con el jugador se evalúa en el UX Pass.

## F. Pruebas (comandos y resultados reales)

Binario: `/home/z/my-project/tools/godot/Godot_v4.7.2-stable_linux.x86_64` (4.7.2.stable.official.ed1daf0bf). Logs en `artifacts/logs/` (no versionados).

| # | Prueba | Resultado |
|---|---|---|
| 1 | Import pass 1 (`--import`) | PASS |
| 2 | Import pass 2 estricto (`--editor --quit --verbose` + grep) | PASS (0 errores) |
| 3 | `gdlint scripts tests` | PASS (0 problemas; 68 archivos) |
| 4 | `gdformat --check scripts tests` | PASS (68 sin cambios) |
| 5 | GdUnit4 completo | **170/170 PASS, 0 errores, 0 fallos, 0 huérfanos, exit 0** (132 previas + 38 nuevas) |
| 6 | Smoke escena principal (`--quit-after 180`) | PASS limpio |
| 7 | Smoke prototipo (`prototype_ground.tscn --quit-after 240`) | PASS limpio |
| 8 | Smoke slice (`valdeluz_slice.tscn --quit-after 240`) | PASS limpio |
| 9 | Smoke multijugador (`run_multiplayer_smoke.sh`) | **PASS** (servidor + 2 clientes, registro y spawn en los tres) |
| 10 | Auditoría de manifiesto (`check_asset_manifest.py`) | PASS (7 filas) |
| 11 | Capturas reales bajo xvfb (render por software llvmpipe) | 5 capturas 1280×720/1600×720 generadas (`scripts/local/capture_hud.gd`) |
| 12 | Verificación visual de capturas con modelo de visión | HUD completo y legible: joystick, arco de 4 botones con iconos, semitransparencia, minimapa con terreno/flecha/blips, stats, mochila sin solapamientos ni glitches |

Iteración honesta: la primera ejecución de la suite dio **170 casos con 16 fallos y 1 error** (analizados y corregidos en el propio repositorio: doble escalado del caminar analógico, orden add_child del minimapa, `from_dict` del kit que borraba ids ARPG, 12 ajustes justificados de tests de Fase 2 sensibles a la velocidad única, ruta de ajustes de capas). La ejecución final es la 170/170 de arriba.

## G. Estructura propuesta para la Fase 3 (diseño de la siguiente fase)

La "Fase 2 del roadmap interno" (combate y seis clases, a renumerar) es la puerta. Propuesta de estructura por paquetes de trabajo, reutilizando lo ya construido:

1. **WP1 — Combate y seis clases** (`prompts/02_COMBATE_Y_CLASES.md`): las seis clases ya tienen kit completo en `classes.json` (la suite valida estructura). Implementar controladores de clase sobre `ArpgPlayer` (proyectiles para Bruja/Tirador, pets de Sepulturero, auras de Bardo), ultimates (`implemented: false` hoy), cancelaciones/combos (decidir momentum: hoy frenada en seco), y barridos de cooldown en los botones del arco.
2. **WP2 — Inventario y economía completos** (`prompts/03_INVENTARIO_ECONOMIA.md`): apilado de consumibles en el panel (hoy contador rápido), rarezas/afijos sobre `RpgDB.get_item`, equipar sombrero/mochila (ya hay modelos e iconos del kit con licencia verificada), vendedor y oro. El panel y los slots ya existen.
3. **WP3 — XP 1–30 y balance con evidencia** (`docs/diseno/02`): `move_accel/move_decel/run_multiplier` por clase como datos (el código ya los lee), simulación de curva (`test_xp_curve` como base) y telemetría.
4. **WP4 — Multijugador LAN** (`prompts/06_MULTIJUGADOR_LAN.md`): autoridad de servidor sobre enemigos/golpes (los servicios ya están desacoplados y `ShadowOfPortal` documenta la preparación), sincronización de posición/animación de `ArpgPlayer`, lobby sobre el autoload `Network` existente (smoke en CI ya verde).
5. **WP5 — Art Pass + UX** (Fase 1B, sigue siendo puerta obligatoria): sustituir puppet procedural por modelos animados (la estructura idle/walk/run/action ya está), mapa artístico del minimapa, terreno/cielo/día-noche (en vuelo en PR#5 de otro agente), capturas y revisión humana.
6. Orden recomendado: **WP5 (parcial) → WP1 → WP2 → WP3 → WP4**, porque el arte define el estándar visual que el resto de fases debe respetar y PR#5 ya está en vuelo.

## H. Limitaciones y NO PROBADO

1. **Android en hardware: NO PROBADO** (sin dispositivo). Nada de FPS/temperatura/joystick con dedo real se declara. El APK debug se construye y firma (Fase 2); CI puede generarlo con `android-debug.yml` (workflow_dispatch).
2. **Multitáctil con dedo físico**: NO PROBADO; la matemática está unit-testeada y la emulación con ratón comparte camino de código.
3. Las capturas se generaron con **render por software** (llvmpipe): fieles en composición/layout, no en rendimiento (irrelevantes para medir FPS).
4. La verificación visual con modelo de visión **no sustituye** la revisión humana exigida por AGENTS.md §10; las capturas están commiteadas para que el propietario las revise.
5. Minimapa sin mapa artístico ni iconos de POI (infraestructura; llega con el Art Pass).
6. El botón de ataque no muestra aún el barrido radial de cooldown (encolado en WP1).

## I. Riesgos

1. El arco de botones usa posiciones fijas por ángulo/radio: si se añade un quinto botón, recalcular solapamientos (la prueba `test_no_overlaps_at_16x9_and_20x9` protege).
2. `InventorySlot.from_dict` ahora conserva ids desconocidos: el kit debe tolerar ítems no listados en `ItemDatabase` (sus pruebas siguen en verde).
3. Si la Fase 3 cambia el umbral de correr o el multiplicador, actualizar las pruebas de movimiento con evidencia (los valores están en datos).
4. El minimapa renderiza el mundo dos veces: en escenas densas del Art Pass, evaluar cull_mask o bajar frecuencia de actualización en el perfil Low.

## J. Próximos pasos

1. Revisar y fusionar la cadena en orden: PR#2 → #3 → #4 → #5 → #6 (Fase 2) → la PR de esta rama.
2. Prueba en dispositivo Android real con el APK debug (registrar modelo, RAM, FPS, renderer).
3. Arrancar WP5 (Art Pass) — PR#5 ya trae terreno/iluminación/día-noche.
4. WP1 (combate y seis clases) con barridos de cooldown en el HUD.

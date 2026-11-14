# Fase 5 — Auditoría inicial y plan de trabajo

Fecha: 2026-11-15 · Rama: `agent/fase5-sistemas-combate` (base: `983c688`, punta de la PR #11 / tag `v0.1.1-fase4c`).

## 1. Estado del repositorio (verificado)

- Cadena de PRs intacta: #3 ← #4 ← #5 ← #6 ← #7 ← #8 ← #9 ← #10 ← #11 (abierta, `fix/fase4b-lint-release` → `agent/fase4b-artpass-valdeluz`).
- Release `v0.1.1-fase4c` publicada con ARM64 (45,2 MB) + Universal (103,2 MB) + informes de verificación.
- Suite base ejecutada antes de tocar nada: **34/34 suites, ~259 casos, 0 fallos** (gdUnit4, Godot 4.7.2 headless).
- `gdlint` + `gdformat` disponibles (gdtoolkit 4.5.0, fijado en `requirements-dev.txt`).
- Rama de trabajo nueva creada desde la punta; nada se ha empujado todavía.

## 2. Clasificación real de los sistemas

### Terminados (se conservan y se extienden, no se reescriben)

| Sistema | Evidencia |
| --- | --- |
| Movimiento del jugador | Aceleración/frenado, relativo a cámara, tiers caminar/correr, snap de suelo (`arpg_player.gd`, pruebas de movimiento en `tests/integration`). |
| `CombatService` | Fórmula central de daño (potencia × coef × mod. atributo × mitigación), crítico con tope, ventanas de telegraph. Pruebas en `test_combat_service.gd`. |
| `ProgressionService` / `QuestSystem` / `SaveSystem` | XP con curva, misiones por datos con 5 estados, guardado versionado con respaldo de corruptos. Pruebas propias en verde. |
| Enemigo Sombra de Portal | FSM IDLE/CHASE/WINDUP/STRIKE/RECOVER/DEAD con telegraph legible. Pruebas `test_enemy_ai.gd`. |
| HUD base | Panel de stats, tracker de misión, joystick virtual, arco de botones, minimapa, mochila, pausa táctil, diálogo. Pruebas 3/4C. |
| Presentación/menús 4C | Splash propio, menú rediseñado, MULTIJUGADOR honesto, oclusión ARPG. Pruebas 4C. |

### Parcialmente implementados (objetivo de esta fase)

| Sistema | Estado real detectado |
| --- | --- |
| Kit del Machetero | **Solo 1 habilidad** (`tajo_guasima`; `try_skill()` usa `skills[0]` siempre). Sin ataque pesado, sin combos, sin bloqueo, sin definitiva (`huracan_machetes` está `implemented:false` en `classes.json`). |
| Crítico del jugador | `CRIT_CHANCE` constante 0,05 — **ignora las estadísticas**; el multiplicador es fijo 1,5. |
| Recurso (Vigor) | **No existe regeneración**: el vigor solo se restaura al subir de nivel. Tras ~6 esquivas + 5 habilidades el jugador queda seco para siempre. |
| Enemigos | Un único tipo; su golpe no usa hitbox física (chequeo distancia+punto), no hay estado de aturdimiento/retroceso y su detección atraviesa muros (sin LOS). |
| Ataques del jugador | La hitbox es un Area3D que solapa cuerpos: **puede golpear a través de muros finos** (sin raycast de trayectoria libre). Sin buffer de entrada ni cadenas de combo. |
| HUD de combate | Sin barra de 5 habilidades + definitiva, sin marco de objetivo (vida/nombre/nivel del enemigo), sin números de daño/crítico, sin estados alterados visibles. |
| Multiplayer LAN | `Network` funciona en lobby pero: no limpia el peer anterior al crear sala nueva (puerto 8080 queda ocupado → **error 20 ERR_CANT_CREATE**, exactamente el reportado), no tiene señal `player_disconnected` (la lista no se actualiza al marcharse alguien), el campo IP no acepta puerto, y **los presets de exportación Android no piden el permiso INTERNET** (ENet no puede abrir sockets en Android sin él — causa raíz del error 20 en el dispositivo). |
| Interfaces | Menús 4C correctos en 16:9/20:9; falta confirmación al abandonar partida desde pausa y verificación de navegación completa. |

### Solo interfaz / provisional

- Panel "Estado del modo" del menú multijugador: describe con honestidad qué falta (correcto), pero el lobby en sí tiene los fallos de ciclo de vida anteriores.
- `scenes/level/`, `scripts/player/`, `scripts/ui/`: plantilla original heredada (no forma del flujo ARPG; se conserva, no se toca).

## 3. Errores concretos encontrados (con causa)

1. **Error 20 al crear sala** (`ERR_CANT_CREATE` de `ENetMultiplayerPeer.create_server`): dos causas reales y reproducibles:
   a. Crear sala → cambiar de escena sin pulsar "Abandonar sala" → el peer ENet anterior sigue vivo con el puerto 8080 enlazado → la segunda llamada a `start_host()` crea un peer NUEVO sin cerrar el VIEJO y falla. `start_host()` no hace teardown previo.
   b. En Android: sin `permissions/internet` en `export_presets.cfg`, la creación del socket UDP está bloqueada por el sandbox → mismo código de error. Los dos presets (ARM64 y Universal) no piden INTERNET.
2. **"Sin conectar — Jugadores: 0" tras el fallo**: consecuencia de (1): el menú queda en estado inicial; además al desconectarse un jugador la lista no se refresca porque `Network` no emite señal alguna de desconexión de jugador.
3. **Vigor sin regeneración** (ver tabla): jugablemente roto para una sesión completa.
4. **Golpes a través de muros**: `_apply_hitbox_damage()` itera `get_overlapping_bodies()` sin verificar línea de visión.
5. **Crítico fijo**: ignora estadísticas y equipo.
6. **Habilidad única cableada por índice 0**: la UI no puede ofrecer más habilidades ni definitiva porque el jugador no las expone.

## 4. Plan de bloques (orden de ejecución, pruebas tras cada bloque)

- **Bloque B — Motor de combate**: `combat/` con `CombatStats`, `CooldownController`, `StatusEffectController`, `DamageSystem` (envuelve `CombatService`, sin duplicar fórmulas), `HitboxController` (ventana + LOS + golpes únicos por swing), `SkillController` (ventanas, buffer, combos, interrupciones), `TargetingSystem`, autoload `CombatEvents` (bus de señales para HUD).
- **Bloque C — Machetero**: kit completo por datos según canon (docs/diseno/02): combo de 3 tajos + ataque pesado; habilidades **Tajo de Guásima** (sangrado), **Guardia del Bohío** (guardia activada), **Carga del Mambí** (embestida que interrumpe), **Corte de la Ceiba** (rompe armadura); definitiva **Huracán de Machetes** (giro + avance + ruptura). Pasivas canon: **Pulso de monte** (parada perfecta restaura vigor y potencia el siguiente golpe) y **Pies de piedra** (resistencia al empuje). Regeneración de vigor, crítico por estadísticas, velocidad de ataque, desbloqueo por nivel y persistencia.
- **Bloque D — Enemigos**: base `ArpgEnemy` (FSM + combate reutilizable) con la Sombra migrada y dos enemigos nuevos del monstruario canon: **Perro de ceniza** (rápido, rodea, aúlla) y **Guarapo negro** (lento, golpe pesado con empuje y trampa de resina que ralentiza).
- **Bloque E — Colisiones**: LOS en hitbox de jugador y enemigos, LOS en detección, herramienta de depuración de colisiones conmutable, pruebas de físicas en movimiento real.
- **Bloque F — HUD**: barra de 5 habilidades + definitiva (coste, disponibilidad, recarga radial, bloqueada), marco de objetivo, números de daño/crítico flotantes, estados alterados, todo por señales.
- **Bloque G — Interfaces**: navegación verificada, confirmación de abandono, centrado multirresolución.
- **Bloque H — Multijugador**: ciclo de vida de sesión robusto (teardown previo, puertos con respaldo, `ip:puerto` al unirse, señal de desconexión), permiso INTERNET en ambos presets, smoke test de sala doble (crear → unir → salir → crear otra) sin reiniciar.
- **Bloque I — Integración**: suite completa + pruebas nuevas, lint/format, exportación Android vía CI, PR a la rama de la cadena.

## 5. Decisiones de diseño documentadas

- El bloqueo es una **acción mantenida** (botón táctil/tecla) con reducción de daño según estadísticas; Guardia del Bohío es la versión habilidad (más fuerte, con duración). Encaja con el canon y con los controles existentes.
- La parada perfecta (parry) es la pasiva **Pulso de monte**: ventana de 0,2 s al empezar a bloquear.
- La definitiva se carga golpeando (+por golpe) y recibiendo daño (+por golpe); se gasta al lanzarla. Condición y consumo propios, visibles en el HUD.
- Desbloqueo por nivel (S1:1, S2:2, S3:3, S4:4, Definitiva:5): progresión real sin inventar un árbol incompatible con el plan maestro.
- El multijugador de esta fase es **lobby LAN** (crear/unir/lista/salir/reutilizar); la sincronización de partida ARPG sigue fuera de alcance y así se documenta.

# Fase 5 — Informe final: sistemas de juego, combate y personaje completos

Fecha: 2026-11-15 · Rama: `agent/fase5-sistemas-combate` (base: `983c688`, PR #11).
Estado de la suite al cierre: **295/295 casos en 42 suites, 0 fallos**;
gdlint + gdformat en verde; smoke multijugador (2 procesos reales) en verde.

Distingue en todo momento entre **implementado y probado automáticamente**
(headless, en este entorno) y **pendiente de prueba física** (teléfonos
Android reales; al final hay una lista explícita).

---

## 1. Archivos creados

**Motor de combate (`scripts/arpg/combat/`)**

| Archivo | Rol |
| --- | --- |
| `arpg_combatant.gd` | Base de combate compartida jugador/enemigos: canal único de daño entrante (con ganchos virtuales de defensa especial), canal único de golpe saliente (`resolve_strike`), estados, recargas y montaje de componentes. |
| `combat_stats.gd` | CombatStats: única fuente de verdad de estadísticas derivadas (con constructores desde datos de clase y de enemigo). |
| `cooldown_controller.gd` | Recargas por identificador con señales `cooldown_started/ended` (HUD radial). |
| `status_effect_controller.gd` | Estados alterados: aplicar/refrescar sin apilar, expiración, sangrado periódico, consultas derivadas (can_act, multiplicadores). |
| `damage_system.gd` | Pipeline de daño: inmunidad → defensa especial → gracia → crítico por estadísticas → vulnerabilidad/potenciación → bloqueo (tope 80%) → límites. |
| `hitbox_controller.gd` | Hitbox reutilizable: ventana real, golpe único por swing, línea de visión (LOS) y geometría centrada para arcos de 360°. |
| `skill_controller.gd` | Ventanas windup/activa/recuperación escaladas por velocidad de ataque, buffer de entrada, cancelación por esquiva e interrupciones. |
| `targeting_system.gd` | Selección de objetivo con LOS y prioridad frontal-cercana; señal `target_changed`. |
| `combat_events.gd` | Autoload: bus de señales de combate para la UI (damage_dealt, attack_parried, enemy_killed, status_changed). |

**Jugador (`scripts/arpg/player/`)**

| Archivo | Rol |
| --- | --- |
| `machetero_kit.gd` | Controlador del kit: combo de 3 tajos, pesado, 4 habilidades, definitiva (5 ticks + remate), bloqueo/parada, esquiva, carga de definitiva. |
| `machetero_puppet.gd` | Marioneta visual desacoplada: montaje procedural + resolvedor de poses por estado (listo para AnimationPlayer sin tocar lógica). |
| `player_input_provider.gd` | Entrada separada de la lógica (teclado + joystick + marco de cámara). |
| `player_equipment.gd` | Puente con el inventario de equipo (validación + bonuses a estadísticas). |
| `player_save_codec.gd` | Persistencia versionada (campos nuevos con defaults compatibles). |

**Enemigos (`scripts/arpg/enemies/`)**

| Archivo | Rol |
| --- | --- |
| `arpg_enemy.gd` | FSM reutilizable (IDLE/PATROL/CHASE/WINDUP/STRIKE/RECOVER/HURT/STUNNED/DEAD) con telegráfico obligatorio, detección con LOS, golpe por hitbox con LOS y reaparición por datos. |
| `perro_de_ceniza.gd` | Especie: sabueso rápido que RODEA al objetivo y aúlla prisa a la manada (estado haste real). |
| `guarapo_negro.gd` | Especie: masa lenta y tanque; golpe de área 360° con empuje y trampa de resina (ralentización real). |

**HUD e interfaces (`scripts/arpg/ui/`)**

| Archivo | Rol |
| --- | --- |
| `arpg_combat_feedback.gd` | Capa de feedback: números de daño flotantes (crítico/parada) y marco de objetivo (nombre/nivel/vida/estados). |
| `arpg_status_chips.gd` | Chips de estados alterados (texto canónico + color). |
| `arpg_hud_icons.gd` | Iconos del HUD dibujados en código (listos para sustituir por arte). |

**Pruebas**: `tests/unit/test_damage_system.gd`, `test_status_effects.gd`,
`test_cooldown_controller.gd`, `test_network_lan.gd`;
`tests/integration/test_machetero_kit.gd`, `test_enemy_species.gd`,
`test_hud_fase5.gd`, `test_interfaces_fase5.gd`.

## 2. Archivos modificados

- `scripts/arpg/player/arpg_player.gd` — reescrito como fachada coordinadora sobre ArpgCombatant + MacheteroKit (792 → 912 líneas con kit delegado; el visual se movió a la marioneta).
- `scripts/arpg/enemies/shadow_of_portal.gd` — migrada a ArpgEnemy (solo identidad visual + embestida).
- `scripts/arpg/ui/arpg_hud.gd` — barra de habilidades, definitiva, bloqueo, pesado, teclado, bloqueo en diálogos.
- `scripts/arpg/ui/arpg_multiplayer_menu.gd` — IP:puerto real, refresco por desconexión, mensaje de error documentado.
- `scripts/arpg/ui/arpg_pause_overlay.gd` — confirmación de abandono en dos pasos.
- `scripts/autoload/network.gd` — reescrito: ciclo de vida robusto (teardown previo, respaldo de puertos, ip:puerto, `player_disconnected`).
- `scripts/arpg/level/valdeluz_slice.gd` — registro de aparición por marcador, respawn por datos, XP primero/repetible por marcador.
- `scripts/arpg/services/combat_service.gd` — multiplicador de crítico por parámetro + `block_factor` con tope.
- `game/data/classes.json` — kit completo del Machetero (canon docs/diseno/02).
- `game/data/enemies.json` — 3 especies + niveles + campos de FSM/respawn/estados.
- `project.godot` — autoload CombatEvents + acciones de entrada nuevas.
- `export_presets.cfg` — `permissions/internet=true` en ambos presets (causa raíz Android del error 20).
- `scenes/arpg/valdeluz/valdeluz_slice.tscn` — marcadores de la manada y del guarapo.
- `.github/workflows/godot-ci.yml` — suite completa + smoke multijugador en CI.
- `.gdlintrc`, `docs/18_MULTIJUGADOR.md`, `docs/PLAN_MAESTRO_ITERACIONES_RPG_LBA.md` y pruebas existentes actualizadas a los contratos nuevos.

## 3. Sistemas que estaban rotos y cómo se corrigieron

| Problema real (auditoría) | Corrección |
| --- | --- |
| Una sola habilidad cableada (`skills[0]`); definitiva `implemented:false`. | Kit completo por datos ejecutado por MacheteroKit. |
| Sin regeneración de vigor (quedarse seco para siempre). | `regen_per_second` por datos, aplicada en el tick del jugador. |
| Crítico fijo 5% ignorando estadísticas. | Crítico por CombatStats (prob. y multiplicador), tope global en CombatService. |
| Golpes a través de muros (Área solapaba cuerpos). | HitboxController con raycast LOS obligatorio por objetivo. |
| Enemigos detectaban a través de muros. | Detección con LOS (raycast WORLD+PLAYER). |
| El golpe del enemigo no usaba hitbox física (distancia + punto). | Mismo HitboxController que el jugador; misma ventana, mismo LOS. |
| La FSM del enemigo nunca avanzaba su acción (SkillsController sin advance) ni abría la hitbox. | `skills.advance` en `_physics_process` + apertura de hitbox en la ventana. |
| Estados de la técnica no se aplicaban (solo el jugador lo hacía). | `_apply_strike_status` en el canal base compartido. |
| Geometría 360°: caja frontal de media profundidad (el Huracán/Guarapo no golpeaban alrededor). | Caja centrada de alcance completo en X y Z para arcos ≥ 359°. |
| Enemigo muerto conservaba velocidad de caída. | `velocity = Vector3.ZERO` en la muerte. |
| **Error 20 del multijugador** (dos causas): peer previo sin liberar al recrear sala; y en Android falta del permiso INTERNET. | Teardown siempre previo + `permissions/internet` en ambos presets + respaldo de puertos 8080..8084. |
| Lista de jugadores con fantasmas al marcharse alguien. | Señal `player_disconnected` + refresco del menú. |
| HUD no reflejaba daño (sin `stats_changed` tras el golpe) ni curación. | `combatant_damaged` → `stats_changed`; `heal` avisa. |
| Botones de combate activos durante diálogos. | `_actions_blocked()` en botones y teclado del HUD. |
| Salir de la pausa sin confirmación. | Confirmación en dos pasos con rearme. |
| Archivo de jugador de 956 líneas mezclando todo. | 7 archivos con responsabilidades separadas (base, kit, entrada, equipo, guardado, marioneta, fachada). |

## 4. Arquitectura final del motor de combate

```
ArpgCombatant (CharacterBody3D)            scripts/arpg/combat/arpg_combatant.gd
├─ Entrante: take_damage(amount, context)
│   1. muerto / importe ≤ 0 → false
│   2. invulnerable → false
│   3. _resolve_special_defense()          (virtual; jugador: esquiva → parada → bloqueo)
│   4. gracia de golpe (0.25 s; bypass para daño periódico)
│   5. aplicar HP → _apply_reactions()     (empuje con resistencia; virtual)
│   6. muerte → estados limpios + _on_combatant_died() (virtual)
├─ Saliente: resolve_strike(objetivo, def)
│   1. CombatStats de ambos (el hijo añade empowered/perforación)
│   2. DamageSystem.resolve() (fórmula en CombatService: potencia × coef ×
│      mod. atributo × mitigación; crítico; vulnerabilidad; bloqueo; límites)
│   3. take_damage del objetivo + estados de la técnica + CombatEvents
└─ Componentes: skills (SkillController), hitbox (HitboxController con LOS),
   cooldowns (CooldownController), statuses (StatusEffectController), stats
   (CombatStats)
      ▲ heredan
      ├─ ArpgPlayer (+ MacheteroKit, TargetingSystem, PlayerInputProvider,
      │              PlayerEquipment, PlayerSaveCodec, MacheteroPuppet)
      └─ ArpgEnemy (+ species: ShadowOfPortal, PerroDeCeniza, GuarapoNegro)
```

Fórmula documentada en `scripts/arpg/combat/damage_system.gd` y probada en
`tests/unit/test_damage_system.gd` + `test_combat_service.gd`.

## 5. Funcionamiento de las 4 habilidades y la definitiva

| Habilidad | Efecto real (probado) |
| --- | --- |
| **Tajo de Guásima** (S1, niv. 1, 20 vigor, 5 s) | Golpe en arco de 140° y 3.2 m; aplica sangrado (2.5 daño/s, 4 s). Prueba: conecta 1 golpe y deja estado. |
| **Guardia del Bohío** (S2, niv. 2, 25 vigor, 12 s) | Postura de 4 s: bloqueo reforzado 0.65 y la parada perfecta ATURDE al atacante 1 s. Pruebas: parada anula daño + restaura vigor + empowered; bloqueo normal reduce 45%. |
| **Carga del Mambí** (S3, niv. 2, 25 vigor, 8 s) | Embestida de 7 m en 0.35 s (área 360° de 2.2 m) que aturde 1.2 s a quien atraviesa. Prueba: dummy recibe golpe con `stun_duration 1.2`. |
| **Corte de la Ceiba** (S4, niv. 3, 30 vigor, 10 s) | Golpe lento (coef. 2.6, empuje 4) que rompe armadura 50% durante 6 s. Prueba (estados): armor_multiplier 0.5. |
| **Huracán de Machetes** (definitiva, niv. 3, carga 100) | Giro con avance de 3 m: 5 ticks de 360° + remate que rompe armadura; se carga +8 por golpe dado, +5 por golpe recibido, +15 por parada; consume toda la carga. Pruebas: sin carga no lanza; 5 ticks al mismo enemigo; carga por golpes. |

Pasivas canon: **Pulso de monte** (parada en los primeros 0.2 s de bloqueo:
anula, restaura 10 vigor, empodera ×1.5 el siguiente golpe, +15 de carga) y
**Pies de piedra** (35% de resistencia al empuje).

## 6. Estado del Machetero de la Sierra

- Movimiento en 8 direcciones con diagonal normalizada, relativo a cámara,
  aceleración/frenado por datos, tiers caminar/correr y snap de suelo.
- Combo ligero de 3 pasos con buffer de entrada y caducidad de 1.2 s.
- Ataque pesado, esquiva direccional con coste y recarga, bloqueo mantenido
  con parada, poción, interacción con NPC y recogida por proximidad.
- Atributos (fuerza/destreza/intelecto/espiritu) con 5 puntos/nivel gastables
  (`spend_attribute_point`) y persistencia de lo gastado.
- Progresión: XP por curva canon, subida de nivel con restauración completa
  (decisión de la rebanada documentada), desbloqueos S1:1/S2:2/S3:2/S4:3/D:3.
- Muerte → pantalla de derrota → reaparición conservando progreso.
- Sin salto: no está contemplado para esta clase en el canon (pertenecía a
  una clase de un documento previo); decisión documentada.
- Pruebas: `test_machetero_kit.gd` (17 casos) + movimiento/física previos.

## 7. Estado de los enemigos y la IA

- FSM común: idle → (patrulla opcional) → chase (con LOS y gracia de pérdida
  0.6 s) → windup telegráfico → strike (hitbox con LOS) → recover → hurt al
  recibir daño → stunned cuando corresponde → dead.
- Ataques con las MISMAS reglas que el jugador (misma hitbox, mismo
  DamageSystem, mismos estados): el Guarapo rompe bloqueos con empuje y el
  Perro puede ser aturdido por la Carga.
- Especies diferenciadas: Sombra (melee honesto), Perro de ceniza (rodea con
  componente lateral, aúlla `haste` ×1.35 a la manada en 8 m), Guarapo negro
  (golpe 360° con empuje 3.2 y resina que ralentiza 45%).
- Recompensas por datos: XP primero/repetible por marcador (18/12, 12/8,
  26/16), drops con probabilidad, respawn 22–40 s respetando el tope de la
  matriz de compatibilidad.
- Pruebas: `test_enemy_ai.gd` (actualizada) + `test_enemy_species.gd` (10
  casos: rodeo, aullido, resina, LOS de detección y de golpe, interrupciones).

## 8. Estado de las colisiones

- Jugador: cápsula real; suelo/muros/edificios por capas (WORLD); snap de
  suelo en pendientes; gravedad; sin atravesamientos (pruebas de la Fase 2-3
  en verde).
- Golpes: hitbox de caja por arco (cuerda) o centrada (360°), activa SOLO en
  la ventana, un golpe por swing y por tick del Huracán, y LOS obligatoria
  (prueba: muro entre jugador y enemigo dentro del área → 0 daño).
- Detección de enemigos con LOS (prueba: enemigo a 4 m tras muro no hace
  aggro).
- Interacción NPC por área (PLAYER), recogidas por área (PICKUP).
- Herramienta de depuración: `get_tree().debug_collisions_hint` conmutable
  (producción sin costo; documentada para QA físico).
- Pruebas de físicas en movimiento real (no solo headless estático): la suite
  integra gravedad, rampas y límites del prototipo + el bucle de combate real.

## 9. Funciones del HUD implementadas

- Panel de personaje: vida, vigor, XP, nivel, clase, recurso (por señales).
- Barra de 4 habilidades: recarga radial, candado por nivel (tooltip con el
  nivel), atenuado sin vigor, coste visible, botón de habilidad 0 compartido
  con el arco (sin duplicados).
- Definitiva: relleno de carga y realce al estar lista.
- Combate: marco de objetivo (nombre/nivel/vida/estados del enemigo por
  señales), números de daño flotantes con crítico mayor y "¡PARADA!".
- Estados alterados: chips del jugador con nombre canónico.
- Misiones: tracker + progreso + pistas (existente, verificado).
- Interacciones: botón contextual (hablar/recoger) por rango real.
- Controles: joystick + ataque/pesado/4 habilidades/definitiva/esquiva/
  poción/bloqueo (mantenido)/mochila/pausa; sin bloqueos mutuos; teclado
  completo J/L/K/2/3/4/R/ESP/Q/MAYÚS/I/ESC/P.
- Actualización por señales; sondeo acotado a 6 radiales + disponibilidad a
  4 Hz; combate bloqueado durante diálogos.

## 10. Funciones de las interfaces implementadas

- Navegación verificada de las 5 pantallas de menú (prueba de carga real).
- Contrato del menú principal (Continuar/Nueva/MULTIJUGADOR/Ajustes/Créditos/
  Salir) probado.
- Selección de clase → Jugar → rebanada; Continuar carga el guardado real.
- Pausa: reanudar (táctil/ESC/P), ajustes rápidos, confirmación de abandono
  en dos pasos con rearme.
- Derrota: reintentar (revive conservando progreso) o volver al menú.
- Centrado multirresolución por rect del viewport en 16:9 y 20:9 (pruebas de
  layout de la Fase 3 actualizadas a los tamaños nuevos del clúster).
- Multijugador: crear sala (muestra IP:puerto real), unirse por IP o IP:puerto,
  lista viva (altas y bajas), abandonar sala.

## 11. Solución del error de multijugador

Causa raíz del código 20 (`ERR_CANT_CREATE`), dos frentes (detalle en
`docs/18_MULTIJUGADOR.md`):

1. **Peer previo sin liberar** (escritorio y reentrada): `start_host`/`join_game`
   ahora hacen teardown completo (close + desasignar + limpiar lista) ANTES
   de crear el peer nuevo; `leave_game` libera el puerto al instante.
2. **Android sin permiso INTERNET**: ambos presets de exportación incluyen
   `permissions/internet=true` (sin él, el sandbox bloquea el socket UDP con
   el mismo código 20).

Defensas añadidas: respaldo de puertos 8080..8084 (la sala abre en el
siguiente libre y la pantalla muestra el real), campo IP con `ip:puerto`,
señal `player_disconnected` (lista sin fantasmas), anfitrión registrado
también en headless.

Verificación automatizada del escenario exigido — crear sala → IP visible →
unirse → ambos jugadores listados → un jugador se desconecta (lista
actualizada) → salir de la sala → **crear otra sala inmediatamente** →
repetir sin reiniciar la aplicación — con **2 procesos headless reales**
(`tests/multiplayer/run_multiplayer_smoke.sh`, ahora también en CI) más 7
pruebas unitarias de ciclo de vida. **Pendiente: la misma prueba con dos
teléfonos Android en el mismo WiFi** (el flujo es idéntico).

## 12. Pruebas automatizadas ejecutadas y resultados

- **295 casos en 42 suites, 0 errores, 0 fallos** (gdUnit4, Godot 4.7.2
  headless). 69 casos nuevos en esta fase; los existentes actualizados a los
  contratos nuevos (armadura → CombatStats, FSM con STRIKE por hitbox, XP
  repetible 12, kit completo en datos).
- Cobertura nueva: DamageSystem (10), estados (8), recargas (6), kit del
  Machetero (17), especies/LOS (10), HUD Fase 5 (8), interfaces (5), LAN (7),
  bucle de combate real (1).
- gdlint + gdformat: en verde (con dos excepciones documentadas en
  `.gdlintrc`/cabeceras: max-public-methods del jugador y del HUD).
- Smoke multijugador de 2 procesos: PASS (servidor + 2 clientes, doble sala).
- Nada se redujo para poner CI en verde: al contrario, la CI ahora ejecuta
  la suite completa + el smoke (antes solo importaba y validaba).

## 13. Pruebas realizadas en Android

En este entorno NO se dispone de dispositivo físico ni de emulador con GPU;
lo ejecutado aquí es headless. Estado real:

- **Pendiente de verificación física (S22 Ultra)**: instalar los APK de esta
  rama (los genera el workflow android-debug al hacer push), jugar el bucle
  completo (combo, habilidades, definitiva, bloqueo/parada, morir/reaparecer)
  y repetir el escenario LAN con dos teléfonos en el mismo WiFi.
- La CI existente ya valida en emuladores API 35/36 (instalación, arranque y
  capturas) sobre cada push a la rama.
- Riesgos conocidos de la fase que requieren el teléfono: rendimiento del
  guarapo (partícula de masa) en perfil LOW y la latencia real de ENet en
  WiFi doméstico.

## 14. Errores conocidos y tareas pendientes

- El ARM64 de la release v0.1.1 sigue **sin verificación física en el S22
  Ultra** (la hipótesis documentada sigue siendo copia local corrupta; el
  análisis forense de 4C no cambió).
- La parada perfecta no tiene ventana visual propia (solo el "¡PARADA!" del
  HUD); el aviso de ventana llega con el Art Pass.
- Los iconos de habilidades son dibujos en código (legibles, provisionales).
- El guardado de la posición del enemigo reaparecido no persiste (por
  diseño: el respawn reinicia la instancia en su marcador).
- Perro de ceniza: el aullido suena cada 6 s de caza sin costo; falta el
  enfriamiento de diseño cuando haya telemetría real.
- Sincronización de partida ARPG en LAN: fuera de alcance (lobby sólido
  solamente), como exige el plan.
- Sonido: aplazado por completo (decisión del prompt).

## 15. Rama, commits y PR

- Rama: `agent/fase5-sistemas-combate` (desde `983c688`, punta de la PR #11;
  sin tocar `main` ni otras ramas).
- Commits por bloques: motor de combate/Machetero/monstruario → HUD →
  interfaces → multijugador → bucle de combate real + CI → documentación.
- **PR #14** abierta al final de la cadena:
  https://github.com/Lean031110/RPG-LBA/pull/14
  (`agent/fase5-sistemas-combate` → `agent/fase4b-artpass-valdeluz`,
  manteniendo la cadena #3→#11→#14).

## 16. Estado de los APK y de CI

- **APK**: no se publica release nueva en esta fase (regla del prompt: nada
  de releases sin artefactos verificados). El push de la rama dispara
  `android-debug` que construye **ARM64 + Universal** como artefactos con la
  nueva `permissions/internet`; versionCode se incrementará en la release
  cuando el propietario verifique en el teléfono.
- **CI verificada tras el push** (ambas en verde):
  - `RPG LBA - Validate` (run 43630562950): lint+formato ✓,
    import+smoke de juego ✓, **multiplayer-smoke (servidor dedicado + 2
    clientes) ✓** — la primera vez que el smoke multijugador corre en CI —,
    auditoría de licencias ✓ y **gdunit-tests (295 casos) ✓**.
    https://github.com/Lean031110/RPG-LBA/actions/runs/43630562950
  - `RPG LBA - Android debug APK` (run 43630531922): APKs ARM64 (36.2 MB) y
    Universal (93.8 MB) construidos **con el permiso INTERNET nuevo**,
    instalados y arrancados en los emuladores API 35 y 36 con evidencia.
    https://github.com/Lean031110/RPG-LBA/actions/runs/43630531922

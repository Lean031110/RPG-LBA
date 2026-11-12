# Fase 3 (preparativos) — Lista de seguimiento

Estados: COMPLETADO · PENDIENTE · BLOQUEADO · NO PROBADO.
"NO PROBADO" nunca se convierte en "COMPLETADO" sin evidencia real (AGENTS.md §8).

## Publicación y CI (petición del propietario)

| Tarea | Estado | Evidencia / nota |
|---|---|---|
| Subir la Fase 2 a GitHub (rama `feature/phase-2-playable-prototype`) | COMPLETADO | Push directo con credenciales autorizadas; PR#6 abierta sobre `agent/fase1-vertical-slice`. |
| Verificar que Actions pase en la PR de Fase 2 | COMPLETADO | `validate.yml` verde: import+smoke, multiplayer-smoke, asset-license-audit, gdunit-tests, test-report (5/5). |
| Sin merge automático (regla del repositorio) | COMPLETADO | PRs abiertas; decisión del propietario. |
| APK debug desde CI (`android-debug.yml`) | PENDIENTE | Requiere `workflow_dispatch`/tag; el preset y el workflow quedaron operativos en Fase 2. |

## HUD y controles (estilo Diablo Immortal / MLBB)

| Tarea | Estado | Evidencia / nota |
|---|---|---|
| HUD correctamente organizado (zonas: stats/misión, minimapa, joystick, arco de acciones) | COMPLETADO | `test_hud_fase3` (posiciones + sin solapamientos 16:9/20:9) + capturas reales verificadas. |
| Controles semitransparentes | COMPLETADO | Alfas 0.35-0.55 en botones/paneles; verificado en capturas. |
| Botones en arco con ataque protagonista | COMPLETADO | 104/84/72/64 px con iconos propios; prueba de tamaños. |
| Joystick táctil (Fase 2) | COMPLETADO | Sin cambios de comportamiento; alfa ajustada. |
| Pantalla horizontal obligatoria | COMPLETADO | `sensor_landscape` (nunca vertical) + test de regresión `test_project_settings`. |
| Minimapa | COMPLETADO | `ArpgMinimap` (render cenital real + blips por grupos); 8 pruebas + capturas. |
| Barrido radial de cooldown en botones | PENDIENTE | WP1 (combate): necesita acceso a cooldowns del jugador. |
| Mapa artístico del minimapa / POIs | PENDIENTE | Art Pass (WP5). |

## Personaje

| Tarea | Estado | Evidencia / nota |
|---|---|---|
| Animación de caminar | COMPLETADO | Ciclo procedural analógico (amplitud/cadencia con la velocidad real). |
| Animación de correr | COMPLETADO | `_run_blend`: zancada 0.55→0.88, inclinación, bombeo; `test_run_movement`. |
| Teclado corre / joystick analógico camina | COMPLETADO | Decisión documentada (estándar ARPG); dato por clase `run_multiplier`. |
| Modelos animados finales (esqueleto) | PENDIENTE | Art Pass (WP5); la estructura de estados ya está. |

## Combate, daño e inventario

| Tarea | Estado | Evidencia / nota |
|---|---|---|
| Sistema de combate (ventanas, daño, crítico, esquiva, cooldowns) | COMPLETADO (Fase 1) + re-verificado | 170/170 incluye `test_attack_window`, `test_combat_service`, `test_enemy_ai`. |
| El jugador recibe daño (armadura, gracia, i-frames, muerte/reintento) | COMPLETADO (Fase 1) + re-verificado | `test_enemy_ai` (golpe de Sombra, daño por datos, esquiva anula). |
| Inventario del jugador (equipo) | COMPLETADO | Slots + arma equipada + serialización; `test_inventory_arpg` (10 casos). |
| Equipar arma cambia el daño | COMPLETADO | `potency_bonus` data-driven (+3 machete) dentro de la hitbox. |
| Panel de mochila (UI) | COMPLETADO | Rejilla semitransparente, tecla I / botón; captura verificada. |
| Recompensa de misión entrega arma | COMPLETADO | VS_P00 → machete mellado de Cheo (data-driven). |
| Drops de equipo de enemigos | PENDIENTE | Camino genérico listo (`receive_item` + visual); lo trae WP2 con tabla de botín real. |
| Inventario completo (consumibles apilados, rarezas, vendedor) | PENDIENTE | WP2 (`prompts/03_INVENTARIO_ECONOMIA.md`). |

## Multijugador

| Tarea | Estado | Evidencia / nota |
|---|---|---|
| Base multijugador (host/join, registro, lista, chat) | COMPLETADO (kit, Fase 0/1) | Smoke servidor + 2 clientes PASS local y en CI (PR#6). |
| Multijugador del gameplay ARPG (enemigos/combate autoritativos) | PENDIENTE | Fase 5 (`prompts/06_MULTIJUGADOR_LAN.md`); servicios ya desacoplados. |
| Partida real entre dos personas/dispositivos | NO PROBADO | Sin hardware; nada se declara. |

## Assets

| Tarea | Estado | Evidencia / nota |
|---|---|---|
| Assets organizados con manifiesto y atribuciones | COMPLETADO | Auditoría de manifiesto PASS (7 filas); atribuciones intactas. |
| Iconos UI originales (sin riesgo de licencia) | COMPLETADO | 6 iconos en `assets/ui/icons/` + manifiesto. |
| Texturas/materiales visibles y correctos | COMPLETADO (prototipo/slice) | Capturas reales verificadas sin glitches; el Art Pass eleva la calidad final. |
| Sustituir `close.svg` sin licencia verificada | PENDIENTE | Preexistente (Fase 0); el panel nuevo usa botón de texto, no ese icono. |

## Verificación y documentación

| Tarea | Estado | Evidencia / nota |
|---|---|---|
| Suite completa 170/170 | COMPLETADO | 0 errores/fallos/huérfanos; ajustes justificados en los propios tests. |
| Lint/format/import estricto | COMPLETADO | gdlint 0 problemas; gdformat 68 archivos sin cambios; import doble limpio. |
| Capturas reales 16:9 y 20:9 | COMPLETADO | `screenshots/arpg/` (5) + verificación con modelo de visión. |
| Revisión visual humana (propietario) | PENDIENTE | AGENTS.md §10; capturas commiteadas para revisión. |
| Informe y lista de pendientes | COMPLETADO | Este documento + `FASE_03_PREPARATIVOS.md`. |

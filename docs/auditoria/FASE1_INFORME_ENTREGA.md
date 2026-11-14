# Informe de entrega — Fase 1: Vertical Slice (reconstrucción)

**Rama:** `agent/fase1-vertical-slice` (base: `docs/classes-progression-open-campaign` @ `5e3c735`)
**Fecha:** 2026-11-13
**Motor:** Godot 4.7.2 Standard · GDScript · Compatibility Renderer (ADR-002)

## 1. Objetivo y alcance

Reconstruir y **publicar en GitHub** la vertical slice de 5 minutos de *El Eco de Valdeluz*, perdida tras la entrega local previa (nunca integrada: la rama de Fase 1 no existía en el remoto y el entorno local se recicló). Alcance según `prompts/01_VERTICAL_SLICE.md` adaptado al canon cubano vigente:

- Menú principal (Continuar/Nueva partida/Ajustes/Créditos/Salir), pausa, derrota y ajustes.
- Personaje 3D de prueba de **una clase** (Machetero de la Sierra), montaje procedural original.
- Cámara isométrica elevada (ortográfica, 55°, seguimiento suave, zoom limitado).
- Movimiento omnidireccional: joystick virtual izquierdo + teclado WASD.
- Escena "afueras de Valdeluz": césped, camino de tierra roja con roderas, piedra caliza, palmas/ceibas, límites integrados en el paisaje, colisiones.
- Enemigo **Sombra de Portal**: detecta, persigue, telegráfica (windup carmesí), golpea, muere y suelta poción.
- Ataque básico con **hitbox real activa solo en su ventana**; daño calculado por `CombatService` (servicio único).
- Vida, muerte, drop de poción, consumibles.
- HUD provisional móvil: barras HP/Vigor/XP, contador de misiones, joystick, acciones a la derecha, interacción contextual.
- Misión tutorial **VS_P00 "El eco de Valdeluz"**: aceptar (diálogo con Cheo) → progreso (3 sombras + 2 fragmentos) → reclamar (50 XP + poción) → guardado.
- Perfil gráfico **Low por defecto** (config/quality_profiles.json).
- Suite **GdUnit4** (108 casos) + CI.

**Fuera de alcance (fases siguientes):** Art Pass/UX Pass completo con ciclo día/noche y clima (Fase 1B), seis clases completas con XP/balance simulado (Fase 2), inventario/economía (Fase 3), misiones P00–P27 completas (Fase 4).

## 2. Estado verificado de partida (lección registrada)

- La Fase 1 anterior se reportó como entrega local (48/48 tests, 10 capturas) pero **nunca se subió**: sin rama, sin PR, sin CI. El bundle local se perdió con el reciclaje del entorno.
- Acción correctiva: esta entrega vive íntegramente en el repositorio (código, pruebas, datos, informe) y se valida por GitHub Actions antes de darse por buena. **Ningún resultado se declara sin ejecución real.**

## 3. Decisiones (resumen; detalle en el PR)

1. **Renderer Compatibility aplicado** (ADR-002 ya decidido): `project.godot` pasa de Forward Plus heredado de la plantilla a `gl_compatibility` (incluida variante móvil). El string `renderer_preset` de `validate.yml` se actualizó para reflejar el estado real.
2. **Convención frontal +Z** en personajes (los montajes ya usaban +Z): `_face_towards` con `atan2(d.x, d.z)` y frontal `basis.z`; documentado en los scripts para no revertirlo por accidente.
3. **XP por instancia** para la rebanada (cada sombra única = primera victoria, 18 XP): el servicio `first_kill_xp` ya implementa la regla repetible (18/4) para cuando exista respawn.
4. **gdUnit4 7.0.0 vendored** en `addons/gdUnit4` (SHA `674a5a0e0065e641d289fffa4e4350a47be57705`, MIT) y CI con `version: 'installed'` (determinista, sin clonar master móvil).
5. **Fuente Kurland retirada** (licencia PENDIENTE DE VERIFICACIÓN; AGENTS §5: sin licencia verificable no se incorpora). El HUD/menús provisionales usan la fuente por defecto del motor hasta el UX Pass.
6. **Icono del proyecto original** (campana agrietada entre cenizas, generado proceduralmente): reemplaza el render del robot de la plantilla; fila de manifiesto actualizada.
7. **Visual 100 % procedural y original** (primitivas + ruido, sin assets externos): cero riesgo de licencia en la rebanada; el Art Pass (1B) sustituirá estos montajes por dirección artística aprobada.
8. **VS_P01 como dato de prerequisito** (bloqueada hasta completar VS_P00): demuestra la ampliación por datos sin reescribir el gestor (requisito del canon de misiones). Su contenido real llega en Fase 4.
9. La plantilla multiugador (Network, level.tscn, mp_driver) **no se tocó**: el smoke multijugador sigue en verde.

## 4. Pruebas ejecutadas (comandos exactos)

Godot: `Godot_v4.7.2-stable_linux.x86_64` local (idéntico al de CI).

| Paso | Comando | Resultado |
|---|---|---|
| Import doble (1) | `godot --headless --path . --import` | PASS |
| Import doble (2, estricto) | `godot --headless --editor --path . --quit --verbose` + grep de errores | PASS (sin errores) |
| Smoke escena principal | `timeout 90s godot --headless --audio-driver Dummy --path . --quit-after 180` | PASS (sin errores) |
| Smoke multijugador | `GODOT_BIN=... bash tests/multiplayer/run_multiplayer_smoke.sh .` | PASS (server+2 clientes, 3× status=PASS) |
| Lint | `gdlint scripts tests` | PASS (0 problemas) |
| Formato | `gdformat --check scripts tests` | PASS |
| GdUnit4 | `GODOT_BIN=... ./addons/gdUnit4/runtest.sh --headless "--audio-driver Dummy" --continue --add res://tests` | **108/108 PASS, 0 errores, 0 huérfanos** |
| Acciones de GitHub (final, verde) | [run 43280525911](https://github.com/Lean031110/RPG-LBA/actions/runs/43280525911) | **PASS** (5/5 checks, 108/108 en CI) |

Ejecuciones previas durante el ciclo de corrección (evidencia del proceso, no ocultas):
[43279668985](https://github.com/Lean031110/RPG-LBA/actions/runs/43279668985) (fallo: `.gitignore` tragaba `addons/gdUnit4/bin`, el runner de pruebas nunca llegó al checkout) y [43280139728](https://github.com/Lean031110/RPG-LBA/actions/runs/43280139728) (pruebas 108/108 exit 0 pero el publicador de reportes requería `checks: write`).

Cobertura GdUnit4 por área: curva XP (10), servicio de combate (9), datos de clases vs canon (6), datos de enemigos/ítems (6), gestor de misiones (11), guardado versionado (6), perfiles gráficos (7), movimiento (10), ventana de golpeo (8), IA de enemigo (8), recogibles (4), HUD (8), flujo de escena (6), layout de nivel (7).

## 5. Criterios de aceptación (prompt 01)

| # | Criterio | Estado |
|---|---|---|
| 1 | Menú simple Jugar/Ajustes/Créditos | PASS (con Continuar y confirmación de clase) |
| 2 | Personaje 3D de prueba de una clase | PASS (Machetero; el resto llega en Fase 2) |
| 3 | Cámara top-down/isométrica estable | PASS (ortográfica 55°, seguimiento suave, zoom con rueda) |
| 4 | Movimiento omnidireccional (joystick + teclado) | PASS |
| 5 | Bosque con suelo, caminos, árboles, colisiones y límites | PASS (visual provisional; NOT TESTED en revisión humana) |
| 6 | Enemigo que detecta, persigue, telegrafía y ataca | PASS (windup 0.75 s carmesí) |
| 7 | Ataque básico con hitbox en ventana activa y daño real | PASS (ventana 0.12–0.30 s; forma deshabilitada fuera) |
| 8 | Vida, muerte y drop de poción | PASS |
| 9 | HUD móvil con joystick izq. y acciones der. | PASS (legible; rediseño en 1B) |
| 10 | Misión tutorial con aceptar/progreso/reclamar | PASS (VS_P00; diálogo con Cheo; flags) |
| 11 | Perfil Low por defecto | PASS |
| 12 | Tests de movimiento/daño/cooldown/muerte/drop/quest | PASS (108 casos GdUnit4) |
| 13 | Proyecto importable sin errores nuevos | PASS (import doble) |
| 14 | Sin errores críticos en logs | PASS (greps de import/smoke) |
| 15 | Licencias registradas por recurso | PASS (manifest + THIRD_PARTY; solo originales + plantilla) |

## 6. NOT TESTED / SKIPPED (honestidad obligatoria)

- **Aceptación visual humana**: el entorno de validación es headless; no hay capturas de gameplay. El Art Pass (Fase 1B) exige capturas 16:9/20:9 y revisión humana.
- **APK Android, dispositivo físico, FPS, Redmi 9C**: NOT TESTED (sin hardware). `android-debug.yml` sigue en `workflow_dispatch`/tags.
- **Ciclo día/noche y clima**: no incluido a propósito (alcance de la Fase 1B).
- **Audio**: sin música/efectos finales; volumen del bus Master operativo en ajustes.
- **Guardado en Android** (`user://`): probado solo en escritorio.

## 7. Archivos principales

- `game/data/`: classes/enemies/quests/progression/items (JSON externatizados, fuente única de balance).
- `scripts/arpg/`: 24 scripts (autoloads `RpgDB`/`SaveSystem`/`QuestSystem`/`GraphicsSettings`, servicios `CombatService`/`ProgressionService`, jugador, enemigo, NPC, recogibles, HUD, menús, builder, slice).
- `scenes/arpg/`: 5 escenas (menú, ajustes, créditos, HUD, Valdeluz).
- `tests/unit` + `tests/integration`: 14 suites GdUnit4 (108 casos).
- `addons/gdUnit4/`: runtime vendored (MIT).
- `assets/manifest.csv`, `THIRD_PARTY_NOTICES.md`, `icon.png`, `.github/workflows/validate.yml`, `project.godot`.

## 8. Cómo reproducir

```bash
git clone https://github.com/Lean031110/RPG-LBA.git
cd RPG-LBA
git checkout agent/fase1-vertical-slice
godot --headless --path . --import
godot --headless --editor --path . --quit
# Jugar: abrir en Godot 4.7.2 y F5. Teclado: WASD + J/K/Espacio/Q/E; rueda: zoom.
```

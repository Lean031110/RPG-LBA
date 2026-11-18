# ARCHITECTURE — Mapa de la arquitectura REAL

Descripción del código tal como existe en `main` (verificado 2026-11-16).
Para la arquitectura objetivo (separación datos/dominio/servicios/red y
evolución a servidor autoritativo) ver `06_ARQUITECTURA_GODOT.md`.

## Motor y configuración innegociable

- Godot 4.7.2 Standard, GDScript tipado, Compatibility Renderer (opengl3).
- Plataforma principal: Android ARM64; PC como destino de desarrollo.
- `project.godot` versión 0.2.0; export presets Android (ARM64 + Universal).

## Autoloads (`scripts/arpg/autoloads/`)

| Autoload | Rol |
|---|---|
| `GraphicsSettings` | Perfiles LOW/MEDIUM/HIGH + adaptativo, matriz hardware, persistencia `user://settings.json` |
| `QuestSystem` | Estado de misiones (VS_P00 y campaña futura) |
| `RpgDb` | Acceso a datos del juego (JSON bajo `data/`) |
| `SaveSystem` | Payload de guardado (jugador, misiones, ajustes) |

## Capas del ARPG (`scripts/arpg/`)

| Directorio | Contenido real |
|---|---|
| `combat/` | Motor común: `arpg_combatant`, `damage_system`, `hitbox_controller` (con LOS), `skill_controller` (ventanas windup/activa/recuperación), `cooldown_controller`, `status_effect_controller`, `combat_stats`, `targeting_system`, `combat_events` |
| `player/` | `arpg_player` (Machetero: datos+acciones+locomoción+persistencia), `machetero_kit`, `machetero_puppet` (presentación), `iso_camera_rig`, `player_equipment`, `player_input_provider`, `player_save_codec` |
| `enemies/` | 3 especies con FSM común y IA diferenciada |
| `environment/` | `EnvironmentController` (cielo, sol/luna, niebla con `fog_scale`, clima, faroles), `WeatherController`, `DayNightCycle` |
| `level/` | Builders procedurales deterministas: `valdeluz_builder` (slice), `valdeluz_capital_builder` (PR #15), `prototype_ground_builder`, `visual_kit` (materiales/cajas compartidos) |
| `services/` | `combat_service`, `progression_service` |
| `ui/` | HUD, paneles, tema (`ArpgUiTheme`), inventario ARPG |
| `npc/`, `pickups/`, `camera/`, `art/` | NPC (Cheo), recogidas, cámara, utilidades de arte |

## Plantilla heredada (base multiplayer, ADR-006)

`scripts/ui/`, `scripts/inventory/`, `scripts/multiplayer/` (y sus escenas)
provienen de `devmoreir4/godot-3d-multiplayer-template` v2.0.0: sesiones
ENet, inventario/equipo/chat de plantilla, servidor headless. Se conserva
para la Fase 6 (evolución a cliente-servidor autoritativo). El ARPG usa su
propio stack (`scripts/arpg/*`); la duplicación es intencionada y
temporal (herencia vs ARPG) y se resolverá al integrar la autoridad de
servidor.

## Datos

- `data/` — JSON de juego (misiones, especies, loot) cargado por `RpgDb`.
- `config/quality_profiles.json` — perfiles gráficos reales.
- `config/templates/` — plantillas de datos.

## Pruebas y CI

- `tests/unit`, `tests/integration` (GdUnit4), `tests/multiplayer`
  (arnés de smoke de 2 procesos, no GdUnit).
- Workflows: `validate.yml` (PR a cualquier rama), `godot-ci.yml`
  (PR a main: 6 checks requeridas), `android-debug-apk.yml`
  (APK autofirmada + emuladores API 35/36), `visual-captures.yml`
  (16:9 y 20:9), `asset-factory*.yml` (departamento de arte).
- Herramientas locales: `scripts/local/` (capturas), `scripts/ci/`
  (suite visual de CI).

## Reglas de evolución (hacia servidor autoritativo)

1. Los sistemas de combate/inventario/progreso/economía deben poder mover
   su lógica a una autoridad de servidor: nada de estado authoritative en
   el cliente más allá de presentación.
2. Los identificadores de objetos/misiones deben ser estables y
   versionables (migraciones en SaveSystem).
3. Las intenciones del jugador ya pasan por `player_input_provider` y
   `skill_controller`; ese es el punto de corte natural cliente→servidor.

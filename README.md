# RPG LBA — Las Cenizas de Lythara

Action RPG 3D móvil de fantasía medieval: cámara elevada/isométrica, mundo por
regiones, misiones, mazmorras generadas por módulos con semilla determinista,
botín, seis clases originales y multijugador con servidor dedicado
autoritativo.

**Estado actual: Fase 0 (auditoría y base reproducible) completada; esperando
autorización humana para Fase 1 (vertical slice).**

> Este repositorio NO contiene todavía el juego descrito en el GDD. Contiene la
> base técnica auditada (plantilla multijugador), el kit de diseño completo y la
> infraestructura de CI. Consulta `docs/09_ROADMAP_Y_PROMPTS.md` para el plan
> por fases y `PROVENANCE.md` para la trazabilidad de la plantilla base.

## Qué funciona hoy (evidencia en `docs/auditoria/FASE0_INFORME_AUDITORIA.md`)

- Proyecto Godot 4.7.2 que importa sin errores críticos (doble pasada).
- Sesiones multijugador ENet: host, join, servidor dedicado headless (puerto UDP
  8080, hasta 10 jugadores declarados por la plantilla, 2 probados de forma
  real y automatizable en CI).
- Inventario autoritativo en servidor (16 slots + 4 de mochila), equipamiento
  visible sincronizado, chat con sanitización, lista de jugadores.
- Movimiento tercera/primera persona con teclado/ratón (NO es el control final
  del juego; la cámara isométrica y el joystick llegan en Fase 1).

## Qué NO existe todavía (no lo busques, no está)

- Combate: el ataque de la plantilla es **solo animación visual, sin daño**
  (verificado en código). Sin HP, hitbox, enemigos ni drops.
- Clases, habilidades, misiones, mundo por regiones, mazmorras, economía,
  guardado, guilds, trade, controles táctiles, exportación Android.

## Reglas del proyecto

- `AGENTS.md` es obligatorio y prevalece.
- El GDD (`docs/01_GDD.md`) y los ADR (`docs/13_RIESGOS_Y_DECISIONES.md`) son
  la fuente de verdad. No se inventan features no aprobadas.
- Trabajo en ramas `agent/<fase>-<tarea>` + Pull Request. Sin push directo a
  `main`. Una fase por PR.
- Nada se marca PASS sin ejecución real: se usa PASS / FAIL / SKIPPED / NOT TESTED.
- Godot 4.7.2 Standard + GDScript + Compatibility Renderer (cambio de renderer
  pendiente de Fase 1) + Android ARM64.
- Servidor dedicado autoritativo; el cliente nunca decide daño, inventario,
  moneda ni recompensas.
- Cada asset de terceros exige fila en `assets/manifest.csv` con licencia
  comprobada. Ver `THIRD_PARTY_NOTICES.md`.

## Cómo importar y probar (local)

Requisitos: Godot **4.7.2 Standard** (misma versión que el CI).

```bash
# 1) Importar (la primera pasada genera .godot/; la segunda valida)
godot --headless --path . --import
godot --headless --editor --path . --quit

# 2) Abrir en el editor y ejecutar (F5)
#    Menú -> Host para crear partida, otra instancia -> Join 127.0.0.1

# 3) Servidor dedicado headless (UDP 8080)
./run_headless_server.sh            # requiere godot en PATH o GODOT_BIN

# 4) Smoke multijugador automatizado: servidor + 2 clientes headless
GODOT_BIN=/ruta/a/Godot_v4.7.2-stable_linux.x86_64 \
  bash tests/multiplayer/run_multiplayer_smoke.sh .
#    (o scripts/local/run_mp_smoke.sh que localiza el binario)

# 5) Pipeline local completo (import + smoke)
GODOT_BIN=/ruta/a/godot bash scripts/ci/validate_project.sh .
```

Nota conocida: la primera importación en un checkout limpio imprime mensajes de
la fuente `Kurland.ttf` (la UI del editor intenta cargarla antes de importarla).
Son benignos y desaparecen en la segunda pasada; el CI está diseñado para
ignorar la primera pasada y validar la segunda.

## CI (GitHub Actions)

- `validate.yml`: import (2 pasadas) + smoke de escena principal + **prueba
  multijugador servidor/2 clientes** + auditoría del manifiesto de assets +
  GdUnit4 (se activará cuando existan `addons/gdUnit4` y `tests/` de unidad).
- `godot-ci.yml` (heredado, actualizado a 4.7.2): gdlint/gdformat + import.
- `android-debug.yml`: export APK debug — SKIPPED hasta que exista
  `export_presets.cfg` con preset Android.
- `release.yml` (heredado): draft de release con ZIP fuente + SHA-256 en tags
  `vX.Y.Z`.

## Licencias y créditos

- Código de la plantilla base: MIT — Carlos Moreira
  (devmoreir4/godot-3d-multiplayer-template, tag v2.0.0, commit
  `51b2614`). Detalle completo en `PROVENANCE.md`.
- Assets de terceros: CC0 (AGChow, Kenney, Quaternius), CC BY 3.0 (sombreros
  Poly by Google — atribución obligatoria) y 2 pendientes de verificación
  (fuente Kurland, icono close.svg). Detalle en `THIRD_PARTY_NOTICES.md` y
  `assets/manifest.csv`.
- La licencia del código propio de RPG LBA aún no está decidida (decisión
  pendiente registrada en `docs/13_RIESGOS_Y_DECISIONES.md`).

## Documentación

| Ruta | Contenido |
| --- | --- |
| `AGENTS.md` | Reglas innegociables para agentes/colaboradores |
| `docs/00…15_*.md` | Kit de diseño completo (GDD, sistemas, arquitectura, QA, CI, criterios) |
| `prompts/00…08_*.md` | Prompts por fase (ejecutar en orden, uno por PR) |
| `config/` | Plantillas CSV/JSON de datos de juego y perfiles de calidad |
| `docs/auditoria/` | Informes de auditoría de fase |
| `PROVENANCE.md` | Trazabilidad de la plantilla base y del motor |

# Informe — Reconciliación integral del desarrollo (2026-11-15)

Alcance: mandato «ORDEN MAESTRA — RPG LBA». Revisión de todas las ramas, PR,
commits, workflows, releases e issues; grafo de dependencias; integración
progresiva de las fases maduras; corrección de errores reales; validación
automatizada; determinación de fase; ruta de continuación.

## 1. Estado inicial de GitHub (verificado)

- `main` = 26fb66b (solo PR#1 fase0 + PR#2 visión cubana). 13 PR abiertas con
  trabajo maduro apilado; `delete_branch_on_merge` activo; tags heredados de la
  plantilla base (v1.0.0–v2.0.0, devmoreir4); releases v0.1.0/v0.1.1 publicadas
  desde puntas de rama de fase, no desde `main`.
- 0 issues. Rama local espuria `origin` (= 26fb66b) detectada y documentada.
- Rama fantasma `agent/fase1c-valdeluz-capital` = alias exacto de fase1b
  (mismo SHA 4b8bcdd); su PR #15 añade trabajo ÚNICO de fase futura.

## 2. Grafo de dependencias (resumen; detalle completo en la sesión)

```
main ─┬─ #3 docs/classes ─ #4 fase1 ─┬─ #5 fase1b ─ #15 capital (futura)
      │                             └─ #6 phase2 ─ #7 ─ #8 ─ #9 ─ #10
      │                                                          └─ #11 ─ #14
      ├─ #13 docs/roadmap (independiente)
      └─ #12 ai-art-department (independiente; cuarentena)
```

Duplicaciones confirmadas y resueltas sin pérdida:
- fase1b ⊂ fase4b (mismo contenido, fusionada dentro de #10): integrada una
  sola vez vía #5; #10 no repite nada (git resuelve por SHA).
- PR #14 declaraba base 983c688 (#11) pero GitHub apuntaba a #10: ancestry
  verificada (983c688 ES ancestro de 3317adf); base corregida a `main` tras
  fusionar #11 → el diff de #14 quedó en solo sus 9 commits propios.

## 3. Integración ejecutada (orden real, cada una con CI completa en verde)

| # | PR | SHA de fusión | Conflictos resueltos |
|---|---|---|---|
| 3 | docs/classes | fd4aa84 | ninguno (rama actualizada con main) |
| 13 | docs/roadmap | c79c4d3 | ninguno |
| 4 | fase1 | e8e3748 | ninguno |
| 5 | fase1b | 67f0727 | formato: el lint nunca había corrido sobre la fase apilada |
| 6 | phase2 | 636f9b6 | ninguno |
| 7 | fase3 | 26b26c5 | ninguno |
| 8 | fase3b | 8c48e5f | ninguno |
| 9 | fase4a | d3740dd | valdeluz_builder/test_level_layout: gana la versión consolidada; la variante fase4a (8240575) queda en historial y su funcionalidad (sombras por perfil) reaparece vía EnvironmentController |
| 10 | fase4b | 1f8fbac | cluster entorno/builder → versión consolidada de la punta de la cadena (tabs + CI 295/295) |
| 11 | fase4c | 51808dd | 7 archivos 4C-visual: conserva la versión 4C (ours), main solo aportaba reflow |
| 14 | fase5 | 6cb7593 | ninguno (árbol idéntico tras e61d20a) |
| 12 | art dept | 39af791 | ninguno; Kurland.ttf (fuente heredada sin verificar) eliminada por el lado main |

Bucle por PR (mandato §6): retarget base→main → merge de main en la rama →
push → esperar las 6 checks requeridas + emuladores → merge por API.
`delete_branch_on_merge` desactivado antes de empezar; ninguna rama eliminada;
sin push directo a main; sin force push; historial intacto.

## 4. Errores corregidos durante la reconciliación (con causa raíz)

1. **Workflows del departamento de arte invalidos** (3 «failure» sin jobs en
   cada push): `timeout-minutes` colgaba de la raíz del workflow, donde no es
   válido → movido a nivel job (asset-factory/validation/publication).
2. **Carrera de escritura en la rama de arte**: factory y publication empujan
   a la misma rama en paralelo; el primer despacho simultáneo perdió el lote
   producido (push no-ff) → grupo de concurrencia compartido
   `art-department-write` + `pull --rebase --autostash` en factory.
3. **`GODOT_BIN` literal en godot-ci.yml**: el bloque `env:` no expande
   `$VAR` estilo shell; el smoke LAN recibía `Godot_v${GODOT_VERSION}...` y los
   3 procesos morían con 127 → expresión `${{ env.GODOT_VERSION }}`. El job
   nunca había corrido sobre la cadena (godot-ci solo dispara hacia main).
4. **Formato/lint nunca ejecutado sobre fases apiladas**: gdformat+gdlint
   aplicados en las ramas de fase1b, fase4a y fase4b antes de sus fusiones.
5. **Corrupción de indentación** (8240575 reindentó con espacios): resuelta al
   tomar la versión consolidada con tabs de la punta de la cadena.

## 5. Verificaciones de PR #12 antes de integrarla (mandato §4.K)

- Workflows manuales ejecutados: factory (lote producido, validado y guardado),
  validation (suite + catálogo), publication (marcado + PR actualizada) — verde.
- Importación real de los 93+ recursos (67 GLB) en Godot 4.7.2 headless:
  segunda pasada con 0 errores; 148 artefactos importados.
- Licencias: catálogo por recurso «MIT (proyecto RPG-LBA) — generación
  procedural propia»; 0 archivos >45 MB; peso total del arte ~76 MB.
- Kurland.ttf (fuente heredada de la plantilla, sin verificar) eliminada por
  el lado main durante el merge (decisión de licencia de Fase 1 respetada).

## 6. Validación visual (mandato §8 y §10.G)

- Suite de capturas 16:9 y 20:9 bajo Xvfb + llvmpipe (nuevo workflow
  `visual-captures.yml` + `scripts/ci/capture_visual_suite.sh` +
  `verify_visual_captures.py`): 9 capturas (menú, presentación, ajustes,
  créditos, multijugador, partida en Valdeluz 16:9 y 20:9, inventario) —
  ninguna negra ni vacía (media 51–136, varianza 734–3866).
- La aceptación visual final sigue requiriendo revisión humana (AGENTS §10):
  las capturas se publican como artefacto de CI para eso.

## 7. Determinación de fase real (mandato §13)

- Última fase completamente integrada: **Fase 5** (sistemas, combate,
  personaje) + **departamento de arte** + documentación completa.
- Fase parcialmente integrada: mundo/contenido — PR #15 (capital de Valdeluz)
  conservada como fase futura, sin fusionar.
- Terminado y probado (295/295 casos, 42 suites): movimiento, combate
  (daño/crítico/bloqueo/parada/estados), Machetero completo lógico, 3 especies
  de enemigos, HUD completo, interfaces, lobby LAN (error 20 corregido),
  guardado, perfiles Android, APK ARM64+Universal con instalación en emulador.
- NOT TESTED (requiere hardware humano): LAN con dos teléfonos en el mismo
  WiFi, instalación/arranque en el S22 Ultra físico, FPS sostenidos en Redmi
  9C, parada perfecta con ventana visual, audio (aplazado a propósito).

## 8. Continuación de la producción (mandato §14)

Próxima iteración (ya apuntada en PLAN_MAESTRO): **mundo y texturas** —
PR #15 es el arranque de esa fase; su rama debe actualizarse contra el `main`
consolidado cuando se retome, sin fusionarla antes de tiempo.

## 9. APK y release

- `version/code` 2→3, `version/name` «0.1.1»→«0.2.0» en ambos presets.
- Release `v0.2.0-fase5` publicada desde `main` consolidado (no desde una
  punta de rama) con APK ARM64+Universal, informes, SHA256SUMS y capturas.

# DECISIONS — Registro de decisiones (ADR)

Los ADR-001 a ADR-007 (motor, renderer, multiplayer, persistencia, mundo,
repo base, pruebas) viven en
[`docs/13_RIESGOS_Y_DECISIONES.md`](../13_RIESGOS_Y_DECISIONES.md) y siguen
siendo válidos. Esta carpeta registra las decisiones nuevas a partir de la
reconciliación integral (2026-11-15/16).

| ADR | Título | Fecha | Estado |
|---|---|---|---|
| [ADR-008](ADR-008_numeracion_fases.md) | Numeración canónica: fases oficiales del Kit vs iteraciones internas | 2026-11-16 | Aceptada |
| [ADR-009](ADR-009_politica_assets.md) | Política de assets: manifiesto, fábrica y pendientes de licencia | 2026-11-16 | Aceptada |
| [ADR-010](ADR-010_prioridad_gameplay.md) | Prioridad de fases de gameplay sobre el mundo; PR #15 en borrador | 2026-11-16 | Aceptada |
| [ADR-011](ADR-011_fog_scale.md) | API `fog_scale` en EnvironmentController para vistas de revisión | 2026-11-16 | Aceptada |
| [ADR-012](ADR-012_keystore_debug.md) | Keystore de depuración: alcance y prohibición de uso en producción | 2026-11-16 | Aceptada |

## Reglas de los ADR de este proyecto

- Una ADR nueva no invalida el trabajo previo: documenta por qué cambia y
  qué conserva.
- Las decisiones creativas (identidad, canon narrativo, seis clases) no se
  cambian por ADR: pertenecen al propietario.
- Toda ADR debe citar evidencia verificable (PR, commit, test, log).

# ADR-008 — Numeración canónica: fases oficiales del Kit vs iteraciones internas

**Fecha:** 2026-11-16 · **Estado:** Aceptada · **Contexto:** reconciliación
integral (PR #16, `reportes/RECONCILIACION_INTEGRAL.md`)

## Contexto

El proyecto tiene DOS numeraciones históricas que se cruzan:

1. **Fases oficiales 0–9** del Production Kit
   (`docs/kit/PROMPT_MAESTRO.md`): 0 bootstrap, 1 vertical slice,
   2 combate y 6 clases, 3 inventario/economía, 4 misiones, 5 mundo y
   mazmorras, 6 multijugador autoritativo, 7 mundos/guilds, 8 calidad y
   rendimiento, 9 release candidate.
2. **Iteraciones internas** del plan de agentes
   (`PLAN_MAESTRO_ITERACIONES_RPG_LBA.md`): fase 0 bootstrap, fase 1
   vertical slice, fase 1b mundo/ambiente, fase 2 prototipo jugable,
   fase 3 preparativos, 3B APK, 4A Android, 4B artpass, 4C visual,
   fase 5 sistemas de combate.

El conflicto concreto: la "Fase 5 interna" aportó el motor de combate
(= Fase oficial 2), mientras que la "Fase 5 oficial" (mundo/mazmorras)
apenas está iniciada. Declarar "Fase 5 completa" sin esta distinción
habría sido un error de estado.

## Decisión

- La numeración **oficial y canónica** es la del Production Kit (0–9).
- Las iteraciones internas se citan SIEMPRE a través de la tabla de
  correspondencia de `docs/ROADMAP.md`, nunca sueltas.
- Una fase oficial solo se marca completa cuando TODOS sus criterios de
  cierre (ROADMAP.md) están PASS.
- `docs/ROADMAP.md` es la referencia única de correspondencia y estado;
  `09_ROADMAP_Y_PROMPTS.md` y `PLAN_MAESTRO_ITERACIONES_RPG_LBA.md`
  se conservan como documentos históricos/operativos con enlaces al
  canónico.

## Consecuencias

- Estado real actual: Fases 0 y 1 completas; Fase 2 PARCIAL (1/6 clases);
  Fases 3 y 7 no iniciadas; 4, 5, 6 y 8 parciales; 9 no iniciada.
- Cualquier informe futuro debe citar "fase oficial" para evitar la
  ambigüedad que esta ADR resuelve.

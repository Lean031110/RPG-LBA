# ADR-010 — Prioridad de fases de gameplay sobre el mundo; PR #15 en borrador

**Fecha:** 2026-11-16 · **Estado:** Aceptada · **Evidencia:** PR #15
(abierta, borrador), orden del propietario de 2026-11-15 (reconciliación:
"no acumular ramas de fases futuras por delante del gameplay").

## Contexto

La capital procedural de Valdeluz (PR #15, rama
`feature/valdeluz-capital-city`) es una fase futura (Fase oficial 5,
mundo). Las fases de gameplay 2–4 (clases, economía, misiones) están
incompletas. Fusionar la capital ahora adelataría contenido de mundo sin
el gameplay que lo justifica y ampliaría la superficie de mantenimiento
(más escenas que soportar en cada refactor de combate/UI).

## Decisión

1. El orden de trabajo es el de dependencias de `docs/ROADMAP.md`:
   Fase 2 (5 clases restantes) → Fase 3 (economía) → Fase 4 (misiones) →
   Fase 5 (mundo, integrando la capital).
2. La PR #15 se conserva ABIERTA como borrador y se mantiene viva con
   merges de `main` y correcciones (no se deja pudrir), pero no se
   fusiona hasta que su fase llegue.
3. La capital no debe romper la vertical slice jugable ni la misión
   VS_P00: son criterios de cierre de su fusión futura.

## Consecuencias

- El "world building" continúa como línea de fondo (artpass de la capital
  ya corregido: ADR-011) sin bloquear el gameplay.
- Cada fusión futura de main hacia la rama capital debe re-ejecutar la
  suite de la capital (4 tests) y la suite completa (299) como mínimo.

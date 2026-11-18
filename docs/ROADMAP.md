# ROADMAP — Fases oficiales y correspondencia con iteraciones internas

Documento canónico de fases. Regla de numeración (ADR-008): **la numeración
oficial es la del Production Kit (fases 0–9)**; las iteraciones internas
(`docs/PLAN_MAESTRO_ITERACIONES_RPG_LBA.md`) se citan solo a través de esta
tabla de correspondencia. Una fase oficial NO se marca completa porque
exista una iteración interna con el mismo número.

## Correspondencia canónica

| Fase oficial (Kit) | Iteraciones internas que la cubren | Estado real | PR | Criterio de cierre |
|---|---|---|---|---|
| **0. Auditoría y bootstrap** | Fase 0 interna (auditoría repo base, fijar Godot/GDScript/Compatibility) | COMPLETA | #1 | Pipeline mínimo reproducible verde |
| **1. Vertical slice** | Fase 1 (slice), 1b (mundo/ambiente), docs visión cubana | COMPLETA | #2, #3, #4, #5 | VS_P00 jugable con guardado, XP, combate, UI y CI |
| **2. Combate ARPG y 6 clases** | Fase 5 interna (sistemas de combate) cubrió el motor común + Machetero | **PARCIAL — EN CURSO** | #14 (fusionada) | Las 6 clases con kit completo, pruebas y persistencia |
| **3. Inventario, equipo y economía** | — (solo diseño) | NO INICIADA | — | Sistema ARPG con instancias, rarezas, mercaderes, tests de transacción |
| **4. Misiones y narrativa** | — (QuestSystem existe de la slice) | PARCIAL MÍNIMA | #4 | Campaña inicial coherente sobre QuestSystem con persistencia |
| **5. Mundo y mazmorras** | Fase 1b (escenarios), 4B (artpass Valdeluz), capital (PR #15 en borrador) | PARCIAL | #5, #10; #15 abierta | Capital + 5 regiones + 3 mazmorras validadas (conectividad, nav, spawns, jefe) |
| **6. Multijugador LAN autoritativo** | 4C-visual (lobby ENet), smoke 2 procesos | PARCIAL (lobby, no autoritativo) | #11 | Servidor headless autoritativo con 2 clientes y grupos de 4 |
| **7. Mundos, grupos y guilds** | — | NO INICIADA | — | Depende de Fase 6 completa |
| **8. Calidad, rendimiento y audio** | 4A (perfiles/matríz Android), 16_ADAPTIVE | PARCIAL | #9, #11 | 4 perfiles + audio + validación física S22 Ultra y Redmi 9C |
| **9. Release Candidate** | 3B (APK autofirma), 18_GOOGLE_PLAY (doc) | NO INICIADA | #8 | APK/AAB firmada, QA manual, notas de versión, aprobación del propietario |

## Orden de dependencias (regla dura)

1. Fase 2 completa (6 clases) antes de declarar el combate cerrado.
2. Fase 3 (inventario/economía) puede avanzar tras Fase 2; comparte
   persistencia con ella.
3. Fase 4 (misiones) se apoya en QuestSystem existente; no reescribirlo.
4. Fase 5 (mundo) integra la capital de la PR #15 cuando el gameplay lo
   exija; hasta entonces la PR se conserva como borrador.
5. Fase 6 (autoritativo) requiere el gameplay de Fases 2–4 estable.
6. Fases 7–9 solo con sus dependencias verificadas.

## Notas de correspondencia

- La "Fase 5 interna" (sistemas de combate de `reportes/FASE_05_SISTEMAS.md`)
  NO equivale a la "Fase oficial 5 (mundo y mazmorras)": aportó el motor de
  combate de la Fase oficial 2. Esta trampa de numeración motivó el ADR-008.
- Las iteraciones 4A/4B/4C son sub-entregas de calidad/presentación que
  alimentan las fases oficiales 8 y 5 según el componente.
- Los tags `v0.1.x-fase4*` y releases asociadas se publicaron desde puntas
  de rama de fase, no desde `main`; no representan estados de fase oficial
  cerrada (ver `reportes/RECONCILIACION_INTEGRAL.md`).

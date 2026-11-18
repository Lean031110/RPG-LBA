# ROADMAP — Fases oficiales y dependencias
**Actualizado:** 2026-11-18 · Fuente de estado: `docs/STATUS.md`.
La numeración oficial es la del Production Kit (fases 0–9). Las iteraciones internas se citan como historial, no como equivalencia automática.

| Fase oficial | Estado real | Cierre verificable |
|---|---|---|
| 0. Auditoría/bootstrap | COMPLETA | Repo reproducible, engine y pipeline fijados |
| 1. Vertical slice | COMPLETA | VS_P00 jugable, movimiento, combate inicial, guardado y CI |
| 2. Combate y seis clases | **EN CURSO 3/6** | Seis kits distintos, selección, HUD, persistencia, tests y balance |
| 3. Inventario/equipo/economía | NO INICIADA | Inventario ARPG propio, loot, equipo, transacciones y persistencia |
| 4. Misiones/narrativa | PARCIAL | Prólogo y campaña jugables con objetivos, diálogo, recompensas y saves |
| 5. Mundo/mazmorras | PARCIAL | Valdeluz urbana + primera región + dungeon piloto, navegación, transiciones y contenido |
| 6. Multijugador autoritativo | PARCIAL | Servidor headless autoritativo, dos clientes y validación de transacciones |
| 7. Mundos/grupos/guilds | NO INICIADA | Party, instancias, guilds y comercio seguro |
| 8. Calidad/rendimiento/audio | PARCIAL | Audio completo, profiling, batería/temperatura y pruebas físicas |
| 9. Release candidate | NO INICIADA | AAB firmada, QA manual, privacidad/legal, migraciones, notas y aprobación |

## Correspondencia de numeración
- La Fase 2 del informe `FASE_02_INFORME_DE_IMPLEMENTACION.md` fue el prototipo de movimiento/cámara/touch. Es un entregable histórico distinto.
- La Fase oficial 2 es la implementación de las seis clases descritas en `docs/diseno/02_CLASES_ATRIBUTOS_HABILIDADES.md`.
- La Fase interna 5 de combate aportó el motor común y Machetero; no equivale a la Fase oficial 5 del mundo.
- PR #15 es una preview procedural de capital en una rama futura; no se considera integrada ni cierra Fase 5.

## Próxima secuencia obligatoria
1. **Fase 2A — Tirador del Malecón:** kit a distancia, línea de visión, trampas y Concentración.
2. **Fase 2B — Cimarrón Sombrío:** sigilo acotado, flanqueo, movilidad y marcas.
3. **Fase 2C — Bardo del Solar:** compás, buffs de grupo, control y secuencias.
4. **Fase 2D — integración:** selección, HUD, persistencia, pruebas de regresión y balance de seis clases.
5. **Fase 3:** inventario/equipo/economía ARPG.
6. **Fase 4:** prólogo P00–P03 y primera cadena completa.
7. **Fase 5A:** revisión de PR #15 y slice urbana de Valdeluz (no fusionar #15 sin autorización).
8. **Fase 5B:** región Brumaclara jugable.
9. **Fase 5C:** Galerías de Ghar como dungeon piloto determinista.
10. Escalar el pipeline a regiones restantes solo después de medir la plantilla.

## Dependencias duras
- Fase 2 antes de cerrar combate y antes de balance definitivo.
- Fase 3 comparte IDs, guardado y futura autoridad de red; diseñar migraciones antes de publicar datos.
- Fase 4 usa QuestSystem existente; no reescribirlo sin necesidad probada.
- Fase 5 reutiliza EnvironmentController, TerrainMaterialLibrary, VisualKit y builders existentes.
- Fase 6 requiere lógica de combate, inventario, drops y progreso preparada para autoridad del servidor.
- Fases 7 y 9 dependen de persistencia y seguridad.
- UX móvil y profiling deben avanzar en paralelo con las fases de contenido, no al final.

## Gates universales
Cada PR: rama `agent/<fase>-<tarea>`, una unidad de alcance, importación doble, GdUnit, lint/formato, smoke relevante, licencia de assets, evidencia visual si cambia presentación y documentación. Resultados: PASS/FAIL/SKIPPED/NOT TESTED.

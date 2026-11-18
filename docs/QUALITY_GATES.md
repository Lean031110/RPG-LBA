# QUALITY_GATES — Puertas de aceptación

Qué se exige para declarar terminada una tarea o fase. Condensado operativo
de `12_CRITERIOS_DE_ACEPTACION.md` y `10_QA_Y_VALIDACION.md`; en caso de
conflicto manda este documento más el estado real de CI.

## Definition of Done (por tarea)

1. Criterios de aceptación del encargo cumplidos.
2. Importación headless correcta (doble importación en CI).
3. Sin errores críticos nuevos.
4. Tests relacionados en verde; suite completa cuando la tarea toca
   sistemas compartidos.
5. `gdlint` y `gdformat --check` limpios.
6. Assets con licencia comprobada y registrados en el manifiesto.
7. Capturas reales del motor cuando hay cambio visual (16:9 y 20:9).
8. Documentación afectada actualizada (STATUS/ROADMAP/ADR según aplique).
9. PR con CI verde y descripción de limitaciones.
10. Estados declarados honestamente (ver abajo).

## Estados obligatorios

- **PASS:** comprobado con evidencia ejecutable (log, Actions, captura).
- **FAIL:** ejecutado y fallado; se declara, no se oculta.
- **SKIPPED:** omitido con justificación escrita.
- **NOT TESTED:** sin evidencia de ejecución (p. ej. hardware físico
  ausente). Nunca se convierte en PASS por proximidad.

Prohibido: declarar 100% terminado, "sin errores", "compatible con todos
los Android", "optimizado" o "listo para producción" sin pruebas que lo
demuestren.

## Checks requeridas para fusionar a `main` (protección del repo)

1. `project-import (Godot 4.7.2) + game-smoke-test`
2. `multiplayer-smoke (dedicated server + 2 clients)`
3. `asset-license-audit (manifest)`
4. `gdunit-tests`
5. `GDScript lint and format`
6. `Godot headless check`

Adicional en PR con artefactos: `RPG LBA - Android debug APK` (autofirma +
verificación de instalación en emuladores API 35/36) y `Visual Captures`.

## Umbrales actuales verificados

- GdUnit4: 295/295 en `main` (299/299 en la rama de la capital). Un PR que
  reduzca casos de prueba debe justificarlo y sustituirlos por equivalentes.
- Lint: 0 problemas en `scripts/` y `tests/` (excepción documentada:
  `arpg_player.gd` con tope 1200 líneas, `.gdlintrc`).
- Capturas visuales: PNG no vacío y no negro, verificado por script.

## Puertas por fase oficial

| Fase | Puerta adicional |
|---|---|
| 2 (clases) | Cada clase: daño/coste/cooldown/estados/cancelación probados; identidad mecánica propia (no copia del Machetero) |
| 3 (economía) | Tests de transacción, inventario lleno, fallos de persistencia, no duplicación |
| 4 (misiones) | Objetivos funcionales y recompensas comprobables; VS_P00 intacta |
| 5 (mundo/mazmorras) | Conectividad, entrada/salida, colisiones, navegación, semilla, spawns, jefe, recompensas por mazmorra |
| 6 (multijugador) | Servidor headless + 2 clientes, validación de mensajes, rate limiting, prevención de duplicación |
| 8 (calidad) | Validación FÍSICA S22 Ultra y Redmi 9C (hasta entonces: NOT TESTED) |
| 9 (RC) | Firma correcta, QA manual, notas de versión, aprobación humana explícita del propietario |

## Regla de fusiones

Nadie fusiona PR automáticamente. El agente prepara la PR con checks
verdes y el propietario decide. Las PR de fases futuras (p. ej. #15) se
conservan como borrador hasta que su fase llegue en el roadmap.

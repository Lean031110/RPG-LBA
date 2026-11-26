# Fase 2 — Ataque básico del Tirador (2026-11-26)

## Incremento

Se implementa el primer incremento funcional del Tirador: un ataque básico físico a distancia que crea un `ArpgProjectile`, usa el `SkillController` y la resolución de daño compartida, no consume recurso y respeta una recarga. Los valores de daño y cadencia añadidos en `game/data/classes.json` son una baseline provisional para pruebas, no un balance aprobado.

La fábrica de `ArpgPlayer` construye ahora `TiradorKit`. La clase continúa incompleta deliberadamente: conserva `playable_in_slice: false`, no tiene habilidades ni definitiva implementadas y no se habilita como personaje seleccionable.

## Correcciones compartidas necesarias

- El proyectil consulta con un barrido físico el segmento recorrido en cada paso y expira si encuentra geometría del mundo. La prueba de regresión confirma que un muro impide el daño, incluso cuando la velocidad del proyectil podría hacerlo cruzar antes de la comprobación de solapamiento.
- El proyectil expira inmediatamente al alcanzar su límite de objetivos/penetración, en lugar de seguir vivo hasta colisionar con otro cuerpo o agotar su vida.
- La suite detiene acciones pendientes y libera proyectiles entre casos.

## Decisiones y solapamientos

La revisión independiente recomendó limitar este trabajo al ataque básico y no presentar el Tirador como clase completa. Se mantiene ese alcance y no se alteran el renderer, la arquitectura de entrada, el canon de habilidades ni los assets.

Durante el diagnóstico se reprodujo un error de captura liberada en la autolimpieza del VFX de impacto. La corrección correspondiente ya está en la [PR #28](https://github.com/Lean031110/RPG-LBA/pull/28), abierta contra `main`; por eso `scripts/arpg/art/art_kit.gd` queda sin cambios en esta rama. La prueba de Tirador omite explícitamente la presentación visual del impacto porque valida mecánica y daño, no VFX.

## Archivos de la mejora

- `game/data/classes.json`: baseline del disparo y cadenas en español.
- `scripts/arpg/player/tirador_kit.gd` y su UID: ejecución del ataque básico.
- `scripts/arpg/player/arpg_player.gd`: registro del kit en la fábrica.
- `scripts/arpg/combat/projectile.gd`: barrido contra geometría y expiración al agotar objetivos.
- `tests/integration/test_tirador_kit.gd` y su UID: configuración, daño, coste, cooldown y obstrucción por muro.

## Validación

Entorno: Godot `4.7.2.stable.official.ed1daf0bf`, headless, en Linux. Base remota consultada antes de publicar: `main` en `e1d415b8a2fd1439736a4c899b309a76085fae29`.

| Comprobación | Resultado |
|---|---|
| Suite enfocada del Tirador, 4 casos | **PASS** — 4/4; 0 errores, fallos, flaky, omitidos u huérfanos. |
| Suite completa de GdUnit4 | **PASS** — 346/346 casos, 47/47 suites; proceso con código 0. |
| `gdlint scripts tests` | **PASS** — sin problemas. |
| `gdformat --check scripts tests` | **PASS** — 141 archivos sin cambios requeridos. |
| Doble importación headless y comprobación estricta de importación | **PASS** — sin errores de parseo ni carga. |
| Smoke de escena principal (`--quit-after 180`) | **PASS** — finaliza sin errores críticos. |
| Auditoría de metadatos `assets/manifest.csv` | **PASS** — 9 filas; el propio script recuerda que la revisión humana de licencias sigue pendiente. No se incorporaron assets. |
| Hardware Android ARM64 / dispositivos físicos | **NOT TESTED** — no se ejecutó en dispositivos físicos. |

### Diagnóstico de cierre del runner

La ejecución completa sobre `main` limpio (`e1d415b`, 342 casos) también acaba con código 0 y 0 huérfanos reportados por GdUnit, pero Godot imprime al cerrar: 3 RID, 193 instancias ObjectDB y 128 recursos retenidos. En esta rama (346 casos) imprime 3 RID, 194 instancias ObjectDB y 129 recursos. La suite focalizada del Tirador termina sin errores, fallos, huérfanos ni mensajes de recursos retenidos. El incremento de una instancia y un recurso en el proceso de la suite completa no quedó aislado; se registra como riesgo pendiente y no se afirma que sea benigno ni causado por un caso concreto.

## Validación remota — PR #29

La [PR #29](https://github.com/Lean031110/RPG-LBA/pull/29) se abrió como borrador desde `agent/phase2-tirador-basic-attack-2026-11-26`, commit `f72eb70ed1b3ed1a664725e80c1c475e134d67e2`, sin fusionar. En el run [RPG LBA - Android debug APK #45841658563](https://github.com/Lean031110/RPG-LBA/actions/runs/45841658563), el resumen final fue **14 checks PASS, 1 FAIL y 1 SKIPPED**, sin checks pendientes.

La exportación y firma ARM64/Universal, las comprobaciones estáticas, la instalación/sanity ABI de ARM64 y los emuladores API 36 pasaron. El único fallo fue [Emulador x86_64 (API 35) — Universal](https://github.com/Lean031110/RPG-LBA/actions/runs/45841658563/job/139985600588): instalación, arranque, render de intro y render del menú pasaron, pero la captura final muestra la pantalla «Sala de Valdeluz» (multijugador), no el slice jugable; el probe terminó en luma 42 / sky 0 y el script no encontró un fotograma de Valdeluz. No se observó un error fatal de Godot en la evidencia del job. La captura y los logs del emulador están en el [artefacto API 35](https://github.com/Lean031110/RPG-LBA/actions/runs/45841658563/artifacts/15128502782).

Como comparación, el job API 35 equivalente pasó en el run de la [PR #28](https://github.com/Lean031110/RPG-LBA/actions/runs/45633198750), cuya captura sí llegó a Valdeluz. Esto hace plausible un fallo intermitente de navegación automatizada, pero no demuestra esa causa ni descarta una regresión; el síntoma queda **sin aislar**. El job no justifica por sí solo atribuir el fallo al kit/proyectil, y no se modificó código a ciegas. La PR permanece en borrador a la espera de revisión/resolución de este check.

## Pendientes

1. Revisar manualmente el balance provisional del ataque.
2. Completar el kit canónico del Tirador antes de habilitar su selección.
3. Probar input, colisión, legibilidad visual, rendimiento y estabilidad en hardware Android real.
4. Investigar la diferencia de un objeto/recurso retenido en el proceso de la suite completa.
5. Aislar por qué el smoke API 35 termina en la pantalla de multijugador y no en Valdeluz; mantener la PR en borrador hasta revisar el fallo.
6. Dejar la decisión de merge al propietario; no fusionar automáticamente.

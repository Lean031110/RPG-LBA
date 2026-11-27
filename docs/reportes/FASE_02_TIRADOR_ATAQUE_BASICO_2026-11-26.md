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

Como comparación, el job API 35 equivalente pasó en el run de la [PR #28](https://github.com/Lean031110/RPG-LBA/actions/runs/45633198750), cuya captura sí llegó a Valdeluz. Esto hace plausible un fallo intermitente de navegación automatizada, pero no demuestra esa causa ni descarta una regresión; el síntoma queda **sin aislar**. El job no justifica por sí solo atribuir el fallo al kit/proyectil, y no se modificó código a ciegas.

Tras añadir únicamente documentación de CI (sin cambios al código del juego), el head `89de38322bfbd96c0541233d4016dfcc9cee33f4` obtuvo un [run Android completo PASS](https://github.com/Lean031110/RPG-LBA/actions/runs/45844102472): el resumen de PR quedó en **15 PASS, 1 SKIPPED, 0 FAIL y 0 pendientes**; en particular, el [mismo job de emulador API 35](https://github.com/Lean031110/RPG-LBA/actions/runs/45844102472/job/139994091022) pasó. Así, el fallo inicial no se reprodujo en la siguiente ejecución sobre el mismo código de juego y es consistente con una intermitencia del smoke/navegación automatizada, aunque su causa exacta sigue sin aislarse. La PR se mantiene como borrador para revisión del propietario; el resultado PASS no equivale a merge ni a prueba en hardware físico.

En el head documental posterior `8c1f2edcd35e59dfe7b974b22f5f9d4e872214a0`, Android (`45845236879`), Validate (`45845247800`) y Visual Captures (`45845247837`) concluyeron PASS. El run separado de Godot CI (`45845247989`) tuvo un primer intento que terminó en **SIGSEGV / exit 134** durante GdUnit: registró `Lambda capture at index 0 was freed` y stack GDScript en `scripts/arpg/combat/area_effect.gd:128` (`_apply_tick`); el último caso que alcanzó a anunciarse era `test_mariposa_spawns_homing_familiar`. `area_effect.gd` no forma parte del diff de esta rama. El [rerun del job Godot headless](https://github.com/Lean031110/RPG-LBA/actions/runs/45845247989/job/140064108991) pasó (incluyendo importación, GdUnit y smoke multiplayer; 3m07s). Por tanto, la caída no se reprodujo en el rerun, pero la advertencia de lambda liberada y la diferencia de recursos descrita arriba quedan como deuda técnica a investigar, no como error demostrado del cambio del Tirador.

La API de Actions reportó el run Validate como exitoso, aunque al momento de cerrar el informe `gh pr checks` todavía mostraba como `pending` su job de auditoría del manifiesto pese a que la API del job devolvió `conclusion: success` con `status: in_progress`. Se anota esta inconsistencia de estado como pendiente de refresco del check; la PR permanece draft y sin fusionar.

## Pendientes

1. Revisar manualmente el balance provisional del ataque.
2. Completar el kit canónico del Tirador antes de habilitar su selección.
3. Probar input, colisión, legibilidad visual, rendimiento y estabilidad en hardware Android real.
4. Investigar la diferencia de un objeto/recurso retenido en el proceso de la suite completa y el aviso de lambda liberada en `AreaEffect`; el SIGSEGV del headless no se reprodujo en el rerun.
5. Si el smoke API 35 vuelve a fallar, aislar por qué los toques automatizados terminan en la pantalla de multijugador; el fallo inicial no se reprodujo en runs posteriores.
6. Confirmar que GitHub refresque a PASS el job de auditoría del manifiesto que sigue figurando pendiente en el resumen de checks pese a que el run Validate concluyó exitosamente.
7. Dejar la decisión de merge al propietario; no fusionar automáticamente.

## Incremento diario — Doble Fogonazo (2026-11-27)

### Funcionalidad

Se implementa la primera habilidad canónica del Tirador, **Doble Fogonazo**, como dos disparos de proyectil secuenciales durante la ventana activa. El casteo utiliza el flujo compartido de desbloqueo, coste, cooldown y buffer; consume Concentración una sola vez. El segundo disparo se cancela si termina o se interrumpe la acción, o si el jugador muere. Los datos de la habilidad y su nombre/descripción están externalizados en `game/data/classes.json` y localizados en español.

Los valores de esta primera implementación son provisionales y no constituyen balance aprobado: coste 20 de Concentración, cooldown de 5 s, coeficiente de daño 0.6 por proyectil, intervalo 0.12 s y dispersión de 2°. Se conserva `playable_in_slice: false`; la definitiva continúa sin implementar y no se habilita la clase completa.

### Archivos del incremento

- `scripts/arpg/player/tirador_kit.gd`: casteo y emisión secuencial con limpieza al completar, interrumpir o morir.
- `game/data/classes.json`: definición de la habilidad y textos españoles.
- `tests/integration/test_tirador_kit.gd`: casos de dos impactos, coste único, cooldown, recurso insuficiente e interrupción; conserva los tests del ataque básico y su obstrucción por muro.

No se incorporaron assets. Un revisor interno independiente, limitado a lectura, corroboró el alcance y las condiciones de secuenciación/cancelación; no delegué implementación.

### Validación local sobre el árbol final

Entorno: Godot `4.7.2.stable.official.ed1daf0bf`, Linux sandbox, ejecución headless. Resultados:

| Comprobación | Resultado |
|---|---|
| `gdlint scripts tests` | **PASS** — sin problemas. |
| `gdformat --check scripts tests` | **PASS** — 141 archivos sin cambios de formato requeridos. |
| `git diff --check` | **PASS** — sin errores de whitespace. |
| Parseo/validación de `game/data/classes.json` y claves españolas | **PASS** — estructura, coste, cooldown, dos tiros y cadenas verificadas. |
| `godot --headless --path . --editor --quit` | **PASS** — importación headless. |
| `godot --headless --path . --quit-after 180` | **PASS** — smoke headless de proyecto/escena de arranque; no es prueba de dispositivo. |
| `GODOT_BIN="$(command -v godot)" timeout 120s ./addons/gdUnit4/runtest.sh --headless --audio-driver Dummy --continue --add res://tests/integration/test_tirador_kit.gd` | **PASS** — 7/7, 0 errores, fallos, flaky, omitidos u huérfanos. |
| `GODOT_BIN="$(command -v godot)" timeout 420s ./addons/gdUnit4/runtest.sh --headless --audio-driver Dummy --continue --add res://tests` | **PASS** — 349/349 casos, 47/47 suites, exit code 0. |
| Hardware físico Android ARM64, rendimiento y controles táctiles | **NOT TESTED** — no se ejecutó en dispositivo físico. |
| CI para el nuevo commit | **PENDING** — se disparará al subir el commit a la PR #29. El último head remoto anterior, `6d7a33c`, tenía 15 checks PASS y 1 SKIPPED. |

### Diagnósticos y pendientes

La suite completa sigue imprimiendo durante tests de Bruja/IA el aviso `Lambda capture at index 0 was freed`; los casos afectados terminan PASSED y el total es 0 errores/fallos. Al cerrar, el proceso también reporta 3 RID del renderer dummy, 194 instancias ObjectDB y 129 recursos retenidos, además de páginas VariantPool. Estos avisos se observaron antes en la rama y no se aislaron como consecuencia de Doble Fogonazo; quedan como deuda técnica global, no como PASS de limpieza de recursos. El runner de GdUnit también intenta conectarse a `127.0.0.1:0`, pero ejecuta y concluye los casos con código 0.

Pendiente: revisión de balance, prueba humana de legibilidad/controles y rendimiento en hardware Android ARM64, y CI del nuevo head. La clase sigue deliberadamente incompleta y no seleccionable.

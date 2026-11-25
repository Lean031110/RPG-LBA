# Corrección de callback de VFX — 2026-11-25

## Alcance y base

- Repositorio: `Lean031110/RPG-LBA`.
- Rama: `agent/fix-vfx-particle-callback-2026-11-25`.
- Commit base probado: `e1d415b8a2fd1439736a4c899b309a76085fae29` (`main` al iniciar esta corrección).
- Alcance: corregir la captura de una partícula liberada en el timer de respaldo de `ArpgArtKit` y agregar una regresión automatizada. No se cambia lógica de combate ni contenido narrativo. No modifica archivos de las PR abiertas de Art Pass.

## Diagnóstico y decisión

`ArpgArtKit._burst()` conecta `CPUParticles3D.finished` a `particles.queue_free()` y programa además un timeout de respaldo. La lambda del timeout capturaba el nodo `particles`; cuando `finished` lo liberaba antes del timeout, Godot reportaba `Lambda capture at index 0 was freed. Passed "null" instead.` La comprobación `is_instance_valid(particles)` no evita evaluar la captura ya liberada.

La corrección conserva ambas rutas de limpieza y conecta directamente `timer.timeout` con `particles.queue_free`, de modo que el motor desconecte el método receptor al destruir el nodo. La revisión independiente read-only confirmó que este es el cambio mínimo seguro. La prueba existente de ArtKit ahora espera 80 frames y verifica que los VFX del host ya se hayan limpiado.

## Archivos

- `scripts/arpg/art/art_kit.gd`: el timeout usa conexión directa al método y no una lambda con referencia al nodo.
- `tests/unit/test_art_kit.gd`: espera asincrónicamente por frames y verifica la autodestrucción después de `finished` y del timeout de respaldo.

## Evidencia y resultados

- Godot: `4.7.2.stable.official.ed1daf0bf`.
- Importación headless: PASS, dos ejecuciones (`godot --headless --path . --editor --quit`).
- Reproducción controlada en worktree baseline con el test nuevo y el código original de `main`: la suite enfocada emitió dos errores `Lambda capture at index 0 was freed`, mientras GdUnit seguía reportando 4/4 aserciones aprobadas. Esta salida demuestra que las aserciones previas no detectaban la regresión de runtime.
- Código corregido, suite enfocada: `godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit/test_art_kit.gd` — PASS, 4/4; cero mensajes de captura lambda.
- Suite completa: `godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests` — PASS, 342/342 casos y 46/46 suites; el log completo no contiene `Lambda capture at index` ni `SCRIPT ERROR`.
- Calidad estática: `gdlint scripts tests` PASS; `gdformat --check scripts tests` PASS (139 archivos sin cambios); `git diff --check` PASS.
- Log completo de la suite: `/tmp/rpg-lba-vfx-full-suite.log` (evidencia local de esta ejecución, no artefacto de GitHub Actions).

## Limitaciones y pendientes

GdUnit informa 0 errores, fallos, casos flaky, skips u orphans. La ejecución completa sí termina con avisos/errors del motor durante la limpieza global: 193 instancias ObjectDB y 128 recursos en uso, páginas PagedAllocator y 3 RID de shaders. Son distintos de la captura corregida y quedan abiertos para diagnóstico independiente. Las líneas `ERROR` emitidas dentro de tests negativos (perfil inválido, errores de red, JSON/guardados corruptos) son parte de esos escenarios comprobados; no se contaron como fallos de suite.

No se validó APK Android, instalación/ejecución en emulador, dispositivo físico, rendimiento móvil ni evaluación visual humana para este cambio. No se afirma cobertura física. CI remota de esta rama queda pendiente de la PR.

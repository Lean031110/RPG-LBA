# Art Pass/UX — diagnóstico de Valdeluz y benchmark aislado de terreno

**Fecha:** 2026-11-24
**Rama:** `agent/art-pass-terrain-benchmark-2026-11-24`
**Base:** `e1d415b`
**PR:** [#27 — borrador, sin fusionar](https://github.com/Lean031110/RPG-LBA/pull/27)
**Estado:** diagnóstico y banco técnico preparados; **revisión artística humana pendiente**. No se declara aprobada la dirección visual.

## Objetivo y límites

Aislar la causa del panel oscuro central visible en Valdeluz y dejar un benchmark independiente de materiales de terreno que reutilice los recursos actuales, sin reiniciar el proyecto ni ampliar la slice antes de la revisión artística.

La escena jugable, el constructor de Valdeluz, el rig de cámara, el controlador ambiental global y los presets Android no se modificaron. Los cambios de runtime están confinados a `scenes/dev/art_benchmark/` y `scripts/dev/art_benchmark/`; también se añadió un smoke test y se endureció el wrapper de capturas visuales. Tras abrir el PR, GitHub Actions generó APK de depuración como artefactos. No se generó AAB ni se publicó Release.

## Diagnóstico visual confirmado

La franja central oscura la produce `Ground/RedDirtPath`, construido como caja de 4,6 m de ancho (`PATH_HALF_WIDTH = 2.3`) y recorrido longitudinal bajo el encuadre. El eje del camino y el personaje comparten encuadre. Ocultar solo `RedDirtPath` hace desaparecer el panel y permite volver a ver el personaje; ocultar `Ground/GroundMesh` no lo elimina. Esto confirma que la fuente es la geometría/material del camino, no un fallo de seguimiento de cámara ni la malla base del terreno. La franja horizontal superior es distinta: al ocultar `Ground/Boundaries` desaparece esa contribución del perímetro, mientras el panel del camino permanece.

El hallazgo acota la causa a la composición y lectura del camino, pero no elige por sí solo una corrección artística. No se cambió su ancho, altura, material, trazado ni relación con la cámara. La comparación diferencial real está archivada aquí:

| Captura | Evidencia |
|---|---|
| Valdeluz con camino | [Diagnóstico base](../../screenshots/arpg/valdeluz_path_diagnostic_before.png) |
| Valdeluz ocultando solo `RedDirtPath` | [Diagnóstico sin el camino rojo](../../screenshots/arpg/valdeluz_path_diagnostic_without_red_path.png) |

La dirección artística debe revisar deliberadamente ancho/encuadre/contraste del camino antes de alterar la slice. La orientación solar del sistema global también queda como seguimiento independiente: el banco usa una dirección descendente de luz solo en su propia instancia para comparar albedos; `EnvironmentController` no se modificó ni se considera aprobado por estas capturas.

## Benchmark implementado

Escena de desarrollo: `scenes/dev/art_benchmark/terrain_benchmark.tscn`, con lógica en `scripts/dev/art_benchmark/terrain_benchmark.gd`. Compara cinco entradas obtenidas de `TerrainMaterialLibrary.create_valdeluz_palette()` —césped, tierra roja, caliza, barro y charco húmedo—, incluye detalles procedurales simples, rótulos y cámara ortográfica propia. Reutiliza `EnvironmentController`, fija mediodía y evita avance del reloj, sombras dinámicas y niebla **solo en esa instancia de prueba**. La orientación descendente de luz y el fondo gris neutro son locales al benchmark; no cambian iluminación ni materiales de la slice.

La primera revisión de las capturas mostró que el parche de césped se confundía con el fondo, porque ambos compartían el material de césped, y que la niebla ambiental reducía la legibilidad. Se conservaron las capturas v2 como historial y se generó una iteración v3 con fondo neutro y niebla desactivada en la escena aislada. La v3 permite ver con más claridad los cinco parches; sigue siendo una herramienta de comparación técnica, no una aprobación estética.

- [Benchmark v3 — 16:9, 1280×720](../../screenshots/arpg/terrain_material_benchmark_16_9_v3.png)
- [Benchmark v3 — 20:9, 1600×720](../../screenshots/arpg/terrain_material_benchmark_20_9_v3.png)
- Iteración previa conservada: [16:9 v2](../../screenshots/arpg/terrain_material_benchmark_16_9_v2.png), [20:9 v2](../../screenshots/arpg/terrain_material_benchmark_20_9_v2.png).

### Tercer benchmark: alternativas de camino A/B/C

A petición del responsable, se preparó una comparación aislada en `scenes/dev/art_benchmark/terrain_path_alternatives.tscn`, con lógica en `scripts/dev/art_benchmark/terrain_path_alternatives.gd`. A muestra una franja recta ancha con roderas; B omite el camino; C presenta un sendero sinuoso de tierra roja, roderas, piedras calizas y vegetación de borde. Cada panel conserva una referencia procedural del Machetero para comparar escala y legibilidad. El material procede de la paleta existente de Valdeluz; la malla es procedural y duplica localmente los materiales para desactivar el culling sin modificar los recursos compartidos.

Esta alternativa C es solo un benchmark de decisión: no cambia la escena jugable ni selecciona una solución artística final. Las capturas fueron regeneradas tras ampliar los rótulos; la iteración de desarrollo defectuosa sin el camino visible no se conserva en el repositorio.

- [Alternativas A/B/C — 16:9, 1280×720](../../screenshots/arpg/terrain_path_alternatives_16_9_v1.png)
- [Alternativas A/B/C — 20:9, 1600×720](../../screenshots/arpg/terrain_path_alternatives_20_9_v1.png)

No se añadieron assets externos; ambos bancos usan geometría procedural y materiales ya existentes. No se requieren entradas nuevas en `assets/manifest.csv`.

## Cambios de automatización

`scripts/ci/capture_visual_suite.sh` incorpora los benchmarks de materiales y caminos en 16:9 y 20:9, conserva el código de salida de Godot, guarda logs, evita sobrescribir resultados existentes y marca error si la captura falla o no produce PNG. Mantiene las capturas anteriores del juego.

`tests/unit/test_terrain_art_benchmark.gd` comprueba carga del benchmark de materiales y la comparación A/B/C, materiales regionales reutilizados, construcción de la malla sinuosa y roderas, panel sin camino, referencias de jugador y cámaras. No modifica ni sustituye pruebas existentes.

## Pruebas y resultados

| Prueba | Estado | Resultado / limitación |
|---|---|---|
| Importación con Godot 4.7.2 Standard | **PASS** | `GODOT_SILENCE_ROOT_WARNING=1 godot --headless --editor --path . --quit` terminó con código 0 tras importar los recursos. No se observó error de importación en el log. |
| GdUnit4 — suite completa | **PASS con avisos al cerrar** | 344/344 casos, 47/47 suites; 0 errores, 0 fallos, 0 flaky, 0 omitidos y 0 huérfanos. Comando: `GODOT_SILENCE_ROOT_WARNING=1 godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd --path . -a tests`. Al salir Godot reportó 193 instancias ObjectDB, 128 recursos, páginas de allocator y 3 RID de shaders todavía en uso; el comando terminó con código 0. |
| GdUnit4 — benchmark focal | **PASS** | 2/2 casos; comprueba el benchmark de materiales y A/B/C. Incluido en la suite completa anterior. Comando focal: `GODOT_SILENCE_ROOT_WARNING=1 godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd --path . -a tests/unit/test_terrain_art_benchmark.gd`. |
| Lint GDScript | **PASS** | `gdlint scripts tests` — sin problemas. |
| Formato GDScript | **PASS** | `gdformat --check scripts tests` — 142 archivos sin cambios. |
| Wrapper, fallo simulado | **PASS** | Motor ficticio salió con código 23; el wrapper devolvió 1 y guardó logs para las 13 entradas. |
| Wrapper, éxito simulado | **PASS** | Motor ficticio produjo 13 archivos PNG de prueba y 13 logs; comprobación de contrato, no sustituye capturas reales. `bash -n scripts/ci/capture_visual_suite.sh` también pasó. |
| Capturas reales del benchmark A/B/C | **PASS** | Godot 4.7.2 con OpenGL3 y `scripts/local/capture_hud.gd`; capturas 1280×720 y 1600×720 regeneradas e inspeccionadas. C visible y rótulos legibles en ambos formatos. |
| Revisión artística humana | **NOT TESTED** | Pendiente de decisión del responsable; el benchmark y sus capturas no constituyen aprobación estética ni autorización para integrar el camino en Valdeluz. |
| GitHub Actions de PR #27, commit `6dec225` (base previa) | **PASS en ese commit; cambios locales aún sin CI** | 15 checks exitosos, 1 omitido, 0 fallidos y 0 pendientes. Ejecuciones: [Validate #45393804241](https://github.com/Lean031110/RPG-LBA/actions/runs/45393804241), [Godot CI #45393804431](https://github.com/Lean031110/RPG-LBA/actions/runs/45393804431), [Visual Captures #45393804224](https://github.com/Lean031110/RPG-LBA/actions/runs/45393804224) y [Android debug APK #45393795253](https://github.com/Lean031110/RPG-LBA/actions/runs/45393795253). Deben revisarse de nuevo tras publicar el commit actualizado. |
| Export Android de depuración en Actions (commit previo) | **PASS en ese commit; cambios locales aún sin exportar** | Exportó ARM64 y Universal, verificó estáticamente ambos APK y pasó emuladores x86_64 API 35/36 más sanity ARM64 API 35/36. Artefactos en la [ejecución Android](https://github.com/Lean031110/RPG-LBA/actions/runs/45393795253): `RPG-LBA-Android-ARM64-debug` (56,959,539 bytes) y `RPG-LBA-Android-Universal-debug` (114,577,075 bytes), además de evidencia de emulador. Son builds debug, no un AAB ni prueba en teléfono físico. |
| AAB/release listo para Google Play | **NOT TESTED** | No se produjo AAB ni se publicó Release; el paso de publicar se omite salvo tags `v*`. |
| Teléfono Android físico | **NOT TESTED** | No se probó en hardware físico. La importación local avisó que no está disponible el directorio Android build-tools; Actions sí completó exportación/emuladores. |

## Riesgo de exportación Android

Ambos presets actuales usan `export_filter="all_resources"` y `exclude_filter=""`. Por tanto, la escena y los scripts de desarrollo del benchmark también podrían incluirse en las exportaciones Android actuales, incluidos los APK debug producidos por Actions. No se tocó esa política en esta tarea: queda registrada para una decisión explícita sobre exclusiones y posterior verificación de exportación. La escena no se configura como escena principal.

## Pendientes para la siguiente revisión

1. Revisión humana de A/B/C y decisión explícita sobre si integrar C o modificarla; no se ha cambiado el mapa jugable.
2. Tras esa decisión, validar composición, anchura, contraste y lectura del jugador en la slice real de Valdeluz antes de dar por cerrada la puerta visual.
3. Investigar aparte la orientación solar global con capturas comparables de amanecer, mediodía, atardecer y noche antes de modificar `EnvironmentController`.
4. Decidir si se excluyen `scenes/dev/` y `scripts/dev/` de los presets Android, y validar el resultado en un export real cuando el toolchain esté disponible.
5. Los enlaces de Actions arriba corresponden al commit `6dec225`; revisar de nuevo los checks más recientes del PR #27 tras cada commit. No fusionar ni publicar Release automáticamente.

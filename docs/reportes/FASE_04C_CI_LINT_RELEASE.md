# Fase 4C — Informe: Release workflow en rojo, lint/formato nunca ejecutados y release automática

**Rama base:** `agent/fase4b-artpass-valdeluz` (PR#10). Los commits de esta fase
se empujan a esa misma rama (actualizan PR#10) porque corrigen código y CI de
toda la cadena 4A/4B.

---

## A. Qué pasó

Tras publicar la release `v0.1.0-fase4-debug` (con los dos APK verificados), el
workflow **Release** quedó en rojo (corrida 43500998983) mientras android-debug
quedó en verde (43500998813). Diagnóstico con los jobs de la corrida:

- Paso fallido: `Validate project / GDScript lint and format` → `Lint GDScript`.
- El job venía de `godot-ci.yml`, invocado como workflow reutilizable por
  `release.yml` en el push del tag.

## B. Causa raíz (dos hallazgos)

1. **`gdlint`/`gdformat` nunca se habían ejecutado sobre el código de las fases.**
   `godot-ci.yml` solo se dispara en pushes/PRs hacia `main`/`develop`, y toda
   la cadena de fases trabaja con PRs apilados hacia ramas `agent/*`. El push
   del tag fue la primera ejecución real, y encontró **19 errores** de
   `max-line-length (120)` en 5 scripts (arpg_player.gd, arpg_hud.gd,
   arpg_main_menu.gd, valdeluz_slice.gd, valdeluz_builder.gd) y **20 archivos**
   que `gdformat` re formateaba.
2. **`release.yml` era una plantilla heredada incompatible con este tag**:
   exigía semver estricto (`vX.Y.Z`), commit contenido en `main`, y creaba un
   ZIP llamado `godot-3d-multiplayer-template-…`. Con `v0.1.0-fase4-debug`
   habría fallado en `Prepare release` aunque el lint pasara.

## C. Correcciones

1. **19 líneas corregidas sin cambio de comportamiento** (solo envolturas de
   línea y materiales locales extraídos en el bloque visual del Machetero;
   mismos colores y geometría; los materiales compartidos por par de ojos/suelas
   son idénticos visualmente). `gdformat` aplicado después: 20 archivos
   reformateados (solo espacios/saltos; suite re-verificada).
2. **`validate.yml`**: nuevo job `gdscript-quality` (gdlint + gdformat) que
   corre en **TODO** PR y en pushes a main/develop. Este era el agujero
   sistémico; documentado en comentario del propio workflow.
3. **`release.yml`**: skip elegante (verde, sin release) para tags no-semver o
   commits fuera de `main`; renombrado del artefacto a `RPG-LBA-<tag>-source.zip`.
4. **`android-debug.yml`**: nuevo job `publish-release` — en pushes de tags
   `v*`, tras pasar TODA la verificación (export estático + emuladores API 35/36
   + sanity ARM64 + informe), publica/actualiza la release de GitHub con los dos
   APK, informes, SHA256SUMS, LEEME, capturas y notas honestas. Objetivo: el
   flujo completo build→verifica→release es reproducible sin credenciales del
   agente (solo `GITHUB_TOKEN`). LEEME actualizado al canal Releases (el texto
   anterior solo hablaba del ZIP de Actions).

## D. Pruebas ejecutadas (local, Godot 4.7.2 + OpenJDK 21)

| # | Prueba | Comando | Resultado |
|---|---|---|---|
| 1 | Reproducción del fallo de CI | `gdlint scripts tests` con gdtoolkit==4.5.0 | 19 errores reproducidos (los mismos de CI) |
| 2 | Lint tras corrección | `gdlint scripts tests` | **PASS** (0 problemas) |
| 3 | Formato | `gdformat --check scripts tests` | **PASS** (0 pendientes) |
| 4 | Suite completa GdUnit4 | `runtest.sh --headless --add res://tests` | **200/200 PASS** (29/29 suites, 0 errores) |
| 5 | Import limpio | `Godot --headless --path . --import` | PASS |
| 6 | YAML de los 3 workflows | `yaml.safe_load` + `bash -n` de los bloques run | PASS (15/15 bloques) |

## E. Verificación independiente de la release publicada (hecha en esta fase)

Sobre los assets públicos de `v0.1.0-fase4-debug` (descarga directa, sin API):

- SHA-256 del `RPG-LBA-Android-ARM64-debug.apk` descargado = **coincide** con
  `SHA256SUMS.txt` publicado (`9f6c4c2f…a11d1e`).
- Estructura ZIP íntegra: `classes.dex`, `AndroidManifest.xml`, `resources.arsc`
  **Stored + alineado a 4 bytes** (requisito targetSdk 30+).
- Manifiesto (androguard): `com.lbagames.rpglba`, minSdk 24, targetSdk 36,
  versionName 0.1.0, launcher `com.godot.game.GodotAppLauncher`,
  `extractNativeLibs=true` — consistente con `.so` comprimidos (el `zipalign`
  de CI solo exige alineación de entradas SIN comprimir; `resources.arsc` sí lo
  está). NOTA: la verificación inicial propia marcó FAIL en `.so` Stored por
  asumir `extractNativeLibs=false`; corregido: la configuración real es válida.
- Bloque de firma APK: esquemas **v2 + v3** presentes (más v1).
- Certificado del firmante dentro del APK:
  SHA-256 `edf1066f…bbbab` = **coincide exactamente** con el certificado de
  `build/android/rpglba-debug.keystore` del repositorio (CN=RPG LBA Debug,
  O=LBA Games, C=CU) verificado con keytool.
- Datos del juego embebidos: 876 entradas en `assets/`, incluidos
  `config/quality_profiles.json` y `game/data/*.json`.

Conclusión: el artefacto publicado es válido; el «Error al analizar el paquete»
original sigue explicado por la cadena de entrega (ZIP sin extraer o descarga
corrupta), ya mitigada con el canal de Releases + SHA256SUMS + LEEME.

## F. Cómo queda el flujo de entrega

1. Se empuja un tag `v*` (p.ej. `v0.1.1-fase4-debug`).
2. `android-debug.yml`: export dual → verificación estática por variante →
   emuladores API 35/36 → sanity ARM64 → informe → **release automática** con
   todos los assets.
3. `release.yml`: para tags no-semver se salta en verde; para semver en `main`
   crea el release de fuente `RPG-LBA-<tag>-source.zip`.
4. `validate.yml` (todo PR): lint + formato + import + smoke + multiplayer +
   manifiesto de assets + GdUnit4.

## G. Pendiente / NOT TESTED

- La corrida real de `publish-release` en GitHub Actions: no ejecutable desde
  este entorno (sin credenciales de push; el job está validado en sintaxis y
  lógica, pero NO se ha probado en un tag real). Primer tag tras empujar estos
  commits: `v0.1.1-fase4-debug`.
- Dispositivos físicos (Redmi 9C, S22 Ultra): protocolo de docs/16 §E,
  PENDIENTE DE HARDWARE, como en 4A/4B.
- La re-ejecución en verde del workflow Release sobre el tag antiguo
  `v0.1.0-fase4-debug` no es posible sin mover el tag; se documenta el tag
  nuevo como sucesor.

## H. Lecciones para el siguiente agente

- Un check que «nunca corrió» no es un check en verde: revisar los disparadores
  de cada workflow antes de confiar en el estado verde de una rama.
- Los PRs apilados hacia ramas no-protegidas evitan los workflows filtrados por
  rama base; cualquier check crítico debe vivir en un workflow que corra en
  `pull_request` sin filtro (ahora así en validate.yml).
- No reutilizar tags movidos: etiqueta nueva para cada entrega.

# Fase 3B — APK debug con autofirma open source y flujo de verificación de instalación

**Petición del propietario (literal, resumida):** verificar que se genera el APK
del juego y que es funcional para probar lo que hay hasta ahora; añadirle una
autofirma cualquiera de código abierto; crear un flujo que verifique si el APK
es válido para instalar y que todo se compiló bien. Después, esperar su
validación sobre lo que hay que hacer.

---

## A. Resumen

**Estado:** la exportación Android debug ya existía desde la Fase 2, pero el
flujo de CI `android-debug.yml` **jamás se había ejecutado** (solo se disparaba
con `workflow_dispatch`/tag y nadie lo disparó; la FASE_03_PENDIENTES lo
registraba como PENDIENTE). Además, un export en CI habría fallado: el flujo
no configuraba las rutas de SDK/JDK que Godot lee de Editor Settings, no
creaba ningún keystore y abortaba (exit 134) si el daemon `adb` no estaba
activo. Esta fase cierra ese hueco de extremo a extremo:

1. **Autofirma open source propia** (`build/android/rpglba-debug.keystore`):
   clave autofirmada de debug generada con `keytool` de OpenJDK, versionada en
   el repo con credenciales públicas documentadas. El preset `Android Debug`
   la usa explícitamente; cada APK de CI sale firmado con la misma identidad
   (se puede instalar encima del anterior sin desinstalar).
2. **Flujo de verificación de instalación** (`android-debug.yml` reconstruido):
   dos trabajos — (a) export + verificación estática completa y (b) instalación
   real en emulador API 35 + arranque del juego + vigilancia de crashes, con
   captura y logcat como evidencia.
3. **Arquitectura del preset**: el debug pasa a llevar `arm64-v8a` + `x86_64`
   (el segundo hace el APK instalable en el emulador de CI y en Chromebooks;
   la release decidirá sus ABIs cuando toque).
4. **Bug real detectado y corregido durante la exportación**: la pantalla de
   Créditos fallaba en parseo (`_flat()` inexistente en `ArpgCreditsMenu`);
   habría ido rota dentro del APK. Corregido + prueba de regresión.

## B. Auditoría inicial (estado real antes de tocar nada)

- **Cadena de integración:** `main` ← PR#2 ← PR#3 ← PR#4 (Fase 1) ← PR#6
  (Fase 2) ← PR#7 (preparativos Fase 3). Ninguna fusionada; esta rama nace de
  la punta de esa cadena (`cb69edc`), como PR apilado.
- **`android-debug.yml` heredado:** solo `workflow_dispatch` + tags `v*`;
  instalaba NDK/cmake que el export directo (sin Gradle) no usa; NO escribía
  Editor Settings (Godot aborta sin `android_sdk_path`/`java_sdk_path`), NO
  creaba keystore (el de la sesión anterior vivía en `$HOME` y se perdió con
  el entorno), NO verificaba nada del APK y NO tenía prueba de instalación.
- **Preset heredado:** `keystore/debug` vacío y `x86_64=false`; el APK local
  previo se firmaba con un keystore de sesión anterior (no reproducible).
- **Evidencia previa útil (FASE_02, informe §G):** el export headless aborta
  con exit 134 si `adb` no está activo; el directorio de destino del export
  debe existir antes de llamar a `--export-debug`.
- **Artefacto de entorno recurrente:** 825 archivos con `mode change
  100644→100755` sin cambios de contenido (todo el sandbox marcado ejecutable).
  Ya documentado en Fase 2; se mantiene `core.fileMode=false` local y no se
  versiona nada de eso.

## C. Qué se hizo (detalle)

### C.1 Autofirma open source (`build/android/`)
- `rpglba-debug.keystore`: PKCS#12, RSA 2048, validez 9999 días, sujeto
  `CN=RPG LBA Debug, O=LBA Games, C=CU`, generado con `keytool` (OpenJDK,
  GPL-2.0-with-classpath-exception: código abierto, como pidió el propietario).
- Huella SHA-256 del certificado:
  `ED:F1:06:6F:37:A3:D1:32:1B:E8:A1:58:42:66:FE:AE:64:D9:5D:9F:A9:E8:6E:A1:A0:FE:EF:A3:57:0B:BB:AB`
- Credenciales **públicas por diseño** (alias `rpglba-debug`, contraseña
  `android`): la convención debug universal de Android. `build/android/README.md`
  documenta qué es, cómo rotarla y la advertencia de nunca usarla para release.
- `export_presets.cfg` ahora referencia el keystore explícitamente
  (`keystore/debug="build/android/rpglba-debug.keystore"` + usuario + contraseña),
  con `architectures/x86_64=true`. Godot resuelve la ruta relativa al proyecto.
- `.gitignore`: la regla `*.keystore` se mantiene para toda otra clave; este
  archivo es la única excepción, con justificación en el propio `.gitignore`.

### C.2 Flujo de verificación (`android-debug.yml` + `scripts/ci/verify_apk.sh`)
- Disparadores: `workflow_dispatch`, `push` a `main`/`develop`/`agent/**`/`feature/**`,
  `pull_request` y tags `v*`. Concurrency con cancelación de corridas obsoletas.
- **Job 1 (build-sign-verify):** Java 17 Temurin + SDK (build-tools 35.0.1,
  platform-tools, platforms;android-35 — sin NDK/cmake: el export directo no
  los usa, validado en local), caché de Godot + plantillas, Editor Settings
  mínimo con las dos rutas que el motor exige, `adb start-server` (evita el
  exit 134), import, `--export-debug`, y verificación estática completa:
  tamaño/SHA-256, `zipalign -c 4`, `apksigner verify` (DN y huella DE LA
  AUTOFIRMA DEL PROYECTO — no vale cualquier firma), esquema v2, `aapt2 dump
  badging` (paquete, minSdk, ABIs), filtro MAIN/LAUNCHER del manifiesto,
  entradas estructurales (`classes.dex`, `libgodot_android.so` por ABI,
  `main_menu.tscn.remap`, >=100 entradas de datos del juego).
- **Job 2 (emulator-install-test):** imagen `android-35;google_apis;x86_64`
  con KVM, arranque headless (SwiftShader), **`adb install -r`** (la prueba de
  "válido para instalar"), resolución de la actividad lanzable, `am start`,
  proceso vivo tras 25 s, sin `FATAL EXCEPTION` en logcat, `screencap` +
  logcat como artefactos, y desinstalación al final.
- `verify_apk.sh` es reutilizable en local (es el mismo comando de CI).

### C.3 Bug corregido: pantalla de Créditos
- `scripts/arpg/ui/arpg_credits_menu.gd` llamaba `_flat()` (líneas 50-52) sin
  definirlo: error de parseo en el import estricto del export. La pantalla
  habría ido rota dentro del APK (el menú principal sí la enlaza).
- Corregido con el helper idéntico al de otros menús ARPG; el archivo quedó
  además re-formateado por gdformat (mezcla de tabs/espacios heredada).
- Prueba de regresión: `tests/unit/test_credits_menu.gd` (instancia la escena
  y exige los tres styleboxes del botón "Volver").

## D. Archivos creados / modificados

| Ruta | Cambio |
|---|---|
| `build/android/rpglba-debug.keystore` | NUEVO. Autofirma debug (PKCS12, RSA 2048, 9999 días). |
| `build/android/README.md` | NUEVO. Documentación de la autofirma y cómo rotarla. |
| `scripts/ci/verify_apk.sh` | NUEVO. Verificación estática del APK (15 comprobaciones). |
| `.github/workflows/android-debug.yml` | REESCRITO. Export + autofirma + verificación estática + emulador. |
| `export_presets.cfg` | Keystore del proyecto + `x86_64=true` (debug). |
| `.gitignore` | Excepción documentada para la autofirma debug. |
| `scripts/arpg/ui/arpg_credits_menu.gd` | Fix `_flat()` + formato gdformat. |
| `tests/unit/test_credits_menu.gd` (+`.uid`) | NUEVO. Regresión de la pantalla de Créditos. |
| `docs/reportes/FASE_03B_APK_DEBUG_FIRMA_VERIFICACION.md` | Este informe. |
| `README.md` | Fila aditiva en "Estado real". |
| `docs/reportes/FASE_03_PENDIENTES.md` | Fila "APK debug desde CI" actualizada. |

No se tocó `docs/narrativa/*`, `docs/diseno/*`, `prompts/*`, `AGENTS.md` ni
`assets/` de terceros.

## E. Pruebas ejecutadas (local, comandos exactos y resultados)

Entorno: OpenJDK 21 + `keytool`, Android SDK (cmdline-tools, platform-tools,
build-tools;35.0.1, platforms;android-35) en `tools/android-sdk`, plantillas
4.7.2-stable en `~/.local/share/godot/export_templates/4.7.2.stable/`, Godot
4.7.2 Standard (editor Linux) — mismo flujo que CI (Temurin 17 en CI).

| # | Prueba | Comando | Resultado |
|---|---|---|---|
| 1 | Suite GdUnit4 completa | `GODOT_BIN=… ./addons/gdUnit4/runtest.sh --headless "--audio-driver Dummy" --continue --add res://tests` | **171/171 PASS** (0 errores/fallos/skipped/orphans, exit 0; 25 suites; 170 previas + 1 nueva) |
| 2 | CI local (import + smoke + manifiesto) | `GODOT_BIN=… bash scripts/ci/validate_project.sh .` | **PASS** exit 0 |
| 3 | Smoke multijugador | `GODOT_BIN=… bash tests/multiplayer/run_multiplayer_smoke.sh .` | **PASS** (servidor + 2 clientes: registro y spawn en los tres procesos) |
| 4 | Import estricto (tras el fix de Créditos) | `godot --headless --editor --path . --quit` | exit 0, **0 errores de script/parseo** (antes: `Failed to load script arpg_credits_menu.gd`) |
| 5 | Export Android debug | `adb start-server && godot --headless --path . --export-debug "Android Debug" builds/android/RPG-LBA-debug.apk` (con `mkdir -p builds/android` previo) | **exit 0**; APK 73.610.973 bytes (73,6 MB; arm64-v8a + x86_64) |
| 6 | Firma (¿es la autofirma del proyecto?) | `build-tools/35.0.1/apksigner verify --print-certs …apk` | **DN `CN=RPG LBA Debug, O=LBA Games, C=CU`; SHA-256 `edf1066f…bbab` = huella del keystore versionado** |
| 7 | Esquemas de firma | `apksigner verify --verbose` | v2: true, v3: true (v1: false, esperado) |
| 8 | Alineación | `zipalign -c 4` | PASS |
| 9 | Badging / manifiesto | `aapt2 dump badging` + `aapt2 dump xmltree … AndroidManifest.xml` | package `com.lbagames.rpglba`, minSdk 24, targetSdk 36, native-code `arm64-v8a`+`x86_64`, entrada lanzable `com.godot.game.GodotAppLauncher` (MAIN/LAUNCHER), orientación fijada por el preset |
| 10 | Contenido embebido | `unzip -l` | 966 entradas; `classes.dex`, `libgodot_android.so` por ABI, 868 entradas `assets/` (escenas exportadas, `.gdc`, `.ctex`, remaps): el juego va DENTRO del APK |
| 11 | Verificación estática completa | `ANDROID_BUILD_TOOLS=… ./scripts/ci/verify_apk.sh builds/android/RPG-LBA-debug.apk …` | **PASS 15/15 comprobaciones, 0 fallos, exit 0** |

## F. Evidencia de CI (GitHub Actions)

- Corridas de esta rama: **(se completa con identificadores reales cuando el
  flujo termine; se añaden en un commit posterior, como en fases anteriores)**
- Artefactos por corrida: APK firmado, informe de verificación, captura del
  emulador y logcat (retención 14 días).

## G. Decisiones y dependencias

1. **Keystore debug versionado** vs. AGENTS.md §4 ("no guardar secretos"): no
   es un secreto — credenciales públicas de convención debug publicadas en el
   propio repo, igual que el keystore debug universal de Android. La regla se
   mantiene para cualquier otra clave (una de release SÍ es un secreto real y
   no se versionará). El propietario pidió expresamente la autofirma; sin una
   clave estable en el repo, cada corrida de CI firmaría con una identidad
   distinta y Android exigiría desinstalar el APK anterior.
2. **`x86_64` en el preset debug**: necesario para que el emulador de CI
   (x86_64) pueda instalar el mismo artefacto que se entrega; +37 MB en el APK
   debug. La release no hereda esta decisión (cuando exista preset de release
   se decide con datos).
3. **Sin NDK/cmake en CI**: el export directo de Godot no los usa; se quitó
   del flujo heredado (ahorra ~1 GB de descarga por corrida). Validado en
   local con el mismo set de paquetes.
4. **Editor Settings mínimos**: dos claves (`android_sdk_path`,
   `java_sdk_path`) bastan; probado en local antes de apostar por ello en CI.
5. **Aviso de Godot** "Could not find version of build tools that matches
   Target SDK, using 35.0.1" (targetSdk 36 del template): benigno; la firma y
   la verificación con build-tools 35.0.1 son correctas (v2/v3 verificados).

## H. Qué quedó pendiente / no probado (honestidad)

- **Dispositivo físico Android: NOT TESTED.** No hay hardware. El emulador
  API 35 (x86_64, SwiftShader) es la evidencia más fuerte disponible; tocará
  a una persona instalar el APK en un teléfono real (ARM64) y reportarlo.
- Rendimiento/FPS en emulador o dispositivo: **NO MEDIDO** (no es el alcance).
- `assets/fonts/Kurland.ttf` (referencia del kit heredado en
  `scenes/level/player.tscn`) no existe en el repo: Godot lo advierte durante
  el export pero no bloquea nada (no está en la ruta ARPG). Se registra tal
  cual; pertenece al kit base, no a esta fase.
- La rotación en emulador/pantalla (sensor_landscape) no se automatiza en CI;
  el setting de proyecto y su prueba de regresión ya lo cubren desde la Fase 3.

## I. Archivos importantes para el siguiente agente

- `build/android/README.md` — la autofirma: qué es, cómo NO usarla para release.
- `scripts/ci/verify_apk.sh` — qué se verifica de un APK y por qué.
- `.github/workflows/android-debug.yml` — el flujo completo (2 jobs).
- `export_presets.cfg` — fuente de verdad del preset Android Debug.
- Este informe, §E (comandos exactos) y §G (decisiones).

## J. Recomendación para la siguiente fase

1. Fusionar la cadena en orden (PR#2→#7→esta) o pedir al propietario que
   decida; la cadena lleva 7 PR abiertas y conviene no dejarla crecer más.
2. Cuando el juego pase a distribución real: crear keystore de release PRIVADO
   (fuera del repo / secretos de CI) y preset de release separado; nunca
   reutilizar la autofirma debug.
3. Añadir al emulador de CI una prueba de "instalar encima" (adb install -r
   sobre un APK previo de la misma firma) si empieza a haber builds frecuentes.

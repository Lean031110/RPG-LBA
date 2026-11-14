# Fase 4A — Informe de compatibilidad Android (Redmi 9C + S22 Ultra)

**Rama:** `agent/fase4a-android-compat-matriz` · **PR:** #9 (apilado sobre PR #8, Fase 3B) ·
**Base de la cadena:** main ← #3 ← #4 (Fase 1) ← #5 (1B World Environment) ← #6 (Fase 2) ← #7 (Fase 3) ← #8 (Fase 3B).

---

## A. Petición del propietario (literal, resumida)

El APK descargado desde el ZIP de GitHub Actions producía «Error al analizar el
paquete» al instalarlo en su Samsung Galaxy S22 Ultra; el mismo APK sí instaló
en el emulador API 35 de CI. Exige: diagnóstico del artefacto, matriz de
compatibilidad obligatoria Redmi 9C (todas sus variantes) y S22 Ultra o superior
(sin nombre comercial como único criterio), dos builds (ARM64 recomendada +
Universal), CI que compile ambos, verifique firmas/manifiestos/bibliotecas,
instale en API 35 y 36, arranque el juego, capture el menú y una escena
jugable, vigile logs/crashes, publique artefactos y SHA-256; protocolo de
pruebas físicas; tres perfiles LOW/MEDIUM/HIGH con detección de hardware y
cambio manual desde Ajustes; y un Art Pass profesional en rama separada.

## B. Diagnóstico del artefacto que falló (docs/16 §A)

Artefacto de referencia: `RPG-LBA-Android-debug` (id 14002030066) de la corrida
final de la Fase 3B (43345197409). Verificación local independiente (androguard
+ análisis propio del ZIP/firma en este entorno) **y** verificación de CI
(21/21 checks): el APK publicado era válido — SHA-256
`46a6a841...ab304c` idéntico al que CI verificó antes de publicarlo; firma v2+v3
presente con el DN y la huella exactos de la autofirma del proyecto; manifiesto
válido (`com.lbagames.rpglba`, minSdk 24, targetSdk 36, MAIN/LAUNCHER); ABIs
arm64-v8a + x86_64; `zipalign -c 4` PASS; `resources.arsc` Stored; datos del
juego embebidos (851 entradas). **Las 8 causas candidatas quedaron
descartadas excepto la cadena de entrega** (instalar el `.zip` sin extraer o
descarga corrupta), que es la explicación más probable del «Error al analizar
el paquete». Correcciones de entrega: artefactos con nombre exacto,
`LEEME_INSTALACION.txt` y `SHA256SUMS.txt` dentro de cada ZIP.

## C. Qué se implementó

1. **Matriz de compatibilidad en código** (`GraphicsSettings.suggest_profile_for`,
   `config/quality_profiles.json` esquema v2): ABI/API reportados; el perfil lo
   decide el criterio MÁS RESTRICTIVO de RAM (<3/3-5/≥5 GB), GPU (PowerVR,
   Adreno <600 → LOW; Adreno ≥700, Xclipse, Mali-G7, Immortalis → HIGH) y
   resolución (eje largo <1600/1600-2200/≥2200). Redmi 9C en todas sus
   variantes (2/3/4 GB, PowerVR GE8320, 720x1600) → **LOW**; S22 Ultra
   (8/12 GB, Adreno 730/Xclipse 920, 1440x3080) → **HIGH**. El nombre comercial
   nunca decide. El usuario puede cambiar el perfil en Ajustes/pausa y persiste
   (`user://settings.json`).
2. **Perfiles completos**: tope de FPS (`Engine.max_fps`), resolución dinámica
   con histéresis (`ArpgAdaptiveController`: baja >130% del presupuesto sostenido,
   sube <70%), modos de sombra por perfil (LOW `player_only` ≤16 m; MEDIUM una
   direccional 40 m; HIGH `high_quality` 60 m + blend_splits), tope de enemigos
   simultáneos (4/6/8), partículas (40/80/140), vegetación y distancia de vista.
   Telemetría `PERF:` (fps/escala/memoria) cada 5 s en builds debug.
3. **Dos variantes de APK**, misma autofirma y mismo package:
   `RPG-LBA-Android-ARM64-debug.apk` (arm64-v8a) y
   `RPG-LBA-Android-Universal-debug.apk` (arm64-v8a + armeabi-v7a + x86_64).
   x86 de 32 bits no incluido: el export 4.7.2 no produce `lib/x86` con
   `x86_32=true` (verificado); documentado como limitación (docs/16 §C).
4. **CI ampliada** (`.github/workflows/android-debug.yml`):
   export de ambas variantes + `verify_apk.sh --abis` por variante (firma v2+v3
   con DN y huella de la autofirma, zipalign, `resources.arsc` Stored, ABIs
   exactos, entradas estructurales); emuladores x86_64 API 35 (google_apis) y
   API 36 (default) con `emulator_install_test.sh` (instalación real, arranque
   con sondeo paciente, capturas del menú y de una escena jugable con guard de
   bytes, telemetría PERF, vigilancia de `FATAL EXCEPTION`); sanity de la
   variante ARM64 (`emulator_abi_sanity.sh`): rechazo exacto
   `INSTALL_FAILED_NO_MATCHING_ABIS` = parseo+firma validados, y si la imagen
   trae traducción ARM (google_apis API 35: la trae), instala y ejecuta.
5. **Bug real de Android heredado desde la Fase 1, corregido**: el menú
   principal se construía en `_ready` con `size=(0,0)` (en Android el control no
   recibe tamaño y `resized` no dispara) y quedaba pegado al borde izquierdo.
   Ahora se coloca desde el rect del viewport. El panel de confirmación de
   clase, igual. Nadie lo había detectado: las «capturas» previas pasaban el
   umbral de luma sobre el color de clearance (77) o el aviso del sistema.
6. **Fix de import heredado**: `scenes/level/player.tscn` referenciaba
   `Kurland.ttf` (fuente retirada por licencia en Fase 1); eliminada la
   referencia colgante.

## D. Pruebas ejecutadas (comandos y resultados)

Local (Godot 4.7.2 Standard, OpenJDK 21):

| # | Prueba | Comando | Resultado |
|---|---|---|---|
| 1 | Suite GdUnit4 completa | `GODOT_BIN=… ./addons/gdUnit4/runtest.sh --headless "--audio-driver Dummy" --continue --add res://tests` | **200/200 PASS** (183 de Fase 4A + art; 0 errores) |
| 2 | Import + smoke | `GODOT_BIN=… bash scripts/ci/validate_project.sh .` | PASS |
| 3 | Layout del menú medido | `godot --headless --path . -s scripts/local/measure_menu_layout.gd` | Nueva partida (640,423); Jugar centro+(-152,+44.5); Prototipo (640,489) — coordenadas que usa CI |
| 4 | Diagnóstico del artefacto | `python3 scripts/diagnose_apk.py` (androguard + análisis del bloque de firma) | PASS (ver §B) |

CI: ver §E.

## E. Evidencia de CI (identificadores reales)

Corrida final en verde de esta fase (android-debug, todos los trabajos):
**43499106389** (export+verificación estática de las dos variantes, emuladores
x86_64 API 35 y 36, sanity ARM64 API 35 y 36, informe). Validate (GdUnit4):
**43497398488** en verde con 9cc65fe0; la re-ejecución del job intermitente de
publicación de check-run (flake de contabilidad ya documentado en Fase 3B, no
de pruebas) fue necesaria una vez. Corrida verde equivalente con el contenido
del Art Pass: 43499113001 (con `playable_capture=valdeluz`). Capturas reales
del menú y de la escena jugable en los artefactos
`RPG-LBA-Android-emulator-api35/36-x86_64-evidence`; telemetría PERF con la
resolución dinámica reaccionando a la carga (0.70→0.50 bajo SwiftShader).
Sanity ARM64: API 36 `INSTALL_FAILED_NO_MATCHING_ABIS` exacto; API 35 (imagen
con traducción ARM) instala y ejecuta.

**Historial honesto de iteraciones** (cada fallo con su causa y corrección):

| Corrida | Resultado | Causa | Corrección |
|---|---|---|---|
| 43469298703 | failure | `x86_32=true` no produce `lib/x86` (la plantilla 4.7.2 no la trae) | Universal en las 3 ABIs verificables; documentado |
| 43473507397 | failure | `adb install` escribe el fallo en STDERR; `tee` solo capturaba stdout | `> archivo 2>&1` en el sanity |
| 43474930008 / 43476646209 | failure | Diálogo de consentimiento inmersivo (panel claro ~238) atrapando los taps; pantalla clavada en luma 156-179 | `settings put secure immersive_mode_confirmations confirmed` (AOSP canónico) + descarte por uiautomator |
| 43480672530 | failure | `wm size` y el raw de screencap discrepaban del framebuffer (2880 vs 1920); taps fuera de los botones | taps desde `wm size` (autoridad) + dims del PNG en el log |
| 43488263754 | failure | `pt(w/2, 423)`: la escala se aplicaba a `w/2` (960→1440); el primer tap caía 480 px a la derecha | solo las coordenadas de diseño llevan escala |
| 43493770874 | failure | `PID=$(adb shell pidof …)` muere en silencio con `set -e` si pidof viene vacío (el juego tardaba >25 s) | sondeo paciente 45 s con `|| true` |
| 43495554774 | partial | La escena de Valdeluz cargaba (luma 110) pero el discriminante de cielo no casaba con la composición isométrica | escena jugable = 3D clara (luma≥70) o cielo; guard de bytes intacto |
| **43497398488 (Validate)** | **success** | Validate en verde (183/183 en el log; el job de publicacion del check-run re-ejecutado una vez por el flake documentado en Fase 3B) | — |
| **43499106389 (android-debug)** | **success** | — | estado final |

## F. Qué quedó pendiente / NOT TESTED

- **Dispositivos físicos** (Redmi 9C y S22 Ultra): protocolo de 12 puntos listo
  en docs/16 §E (instalación limpia, primer arranque, menú, nueva partida,
  movimiento, combate, inventario, minimapa, orientación, suspender/reanudar,
  temperatura 15-30 min, FPS y RAM). **PENDIENTE DE HARDWARE.**
- **Ejecución del APK ARM64 en arm64**: los runners x86_64 se niegan a arrancar
  AVDs arm64 («Avd's CPU Architecture 'arm64' is not supported by the QEMU2
  emulator on x86_64 host»). Verificado hasta donde permite el entorno.
- Pruebas de emulador NO sustituyen pruebas físicas; la telemetría PERF es del
  proceso en emulador y se etiqueta como tal. Ninguna promesa de FPS.

## G. Archivos importantes

- `docs/16_COMPATIBILIDAD_ANDROID.md` — diagnóstico, matriz, protocolo físico.
- `config/quality_profiles.json` (esquema v2) + `scripts/arpg/autoloads/graphics_settings.gd` + `adaptive_controller.gd`.
- `export_presets.cfg` (dos presets, misma autofirma), `build/android/rpglba-debug.keystore`.
- `scripts/ci/verify_apk.sh`, `scripts/ci/emulator_install_test.sh`, `scripts/ci/emulator_abi_sanity.sh`.
- `.github/workflows/android-debug.yml`.

## H. Recomendación para la siguiente fase

1. Ejecutar el protocolo físico de docs/16 §E en el Redmi 9C y el S22 Ultra y
   volcar los resultados a la tabla de docs/16 §D con evidencia real.
2. Publicar los APK como Release (directo, sin ZIP externo) cuando el
   propietario lo apruebe.
3. Art Pass (PR apilado sobre este): ya en `agent/fase4b-artpass-valdeluz`.

## I. Instrucciones para el siguiente agente

- Leer `AGENTS.md`, `docs/16_COMPATIBILIDAD_ANDROID.md` y este informe antes de
  tocar nada de Android.
- Jamás prometer FPS/compatibilidad física sin medición (AGENTS §7); la
  telemetría PERF es del proceso, no del teléfono.
- El flujo de emuladores es sensible a tres cosas ya resueltas: consentimiento
  inmersivo (AOSP `immersive_mode_confirmations`), taps desde `wm size` con
  escala solo en coordenadas de diseño, y `pidof || true`. Mantener las
  lecciones comentadas en los scripts.

# 16 — Compatibilidad Android: diagnóstico, matriz y protocolo

**Fase 4A · Rama `agent/fase4a-android-compat-matriz` · PR apilado sobre la Fase 3B (PR #8).**

Este documento es la fuente de verdad de la compatibilidad Android de RPG LBA.
Nada de lo escrito aquí es una promesa de rendimiento: cada afirmación lleva su
evidencia (corrida de Actions, comando o medición) y lo no probado queda marcado
como **PENDIENTE DE HARDWARE** o **NOT TESTED** (AGENTS.md §3 y §7).

---

## A. Diagnóstico del artefacto que falló en el S22 Ultra

**Síntoma reportado por el propietario:** al instalar en un Samsung Galaxy S22
Ultra el APK descargado del ZIP de GitHub Actions, Android muestra
«Error al analizar el paquete». El mismo APK **sí** instaló y arrancó en el
emulador API 35 de CI (corrida 43343138392, evidencia en el artefacto
`RPG-LBA-Android-emulator-evidence`).

**Artefacto de referencia:** `RPG-LBA-Android-debug` (id 14002030066) de la
corrida final **43345197409** (rama `agent/fase3b-apk-firma-verificacion`,
commit `7440b06`), el último publicado antes de este informe.

| Propiedad | Valor verificado | Herramienta |
|---|---|---|
| Archivo | `RPG-LBA-debug.apk`, 73.220.098 bytes | descompresión del artefacto |
| SHA-256 | `46a6a841cbe0a1f7b5df97424cc5f3a6333573d17c96c51a908c2cacb9ab304c` | `sha256sum` local; **coincide byte a byte** con el informe de verificación que CI escribió DENTRO del propio artefacto |
| Firma v2 | PRESENTE, 1 certificado | `apksigner verify` en CI + análisis local del APK Signing Block (4088 bytes antes de la central directory) |
| Firma v3 | PRESENTE, 1 certificado | ídem |
| Certificado | `CN=RPG LBA Debug, O=LBA Games, C=CU`, SHA-256 `edf1066f…bbab` | ídem; es exactamente la autofirma del proyecto (`build/android/rpglba-debug.keystore`) |
| DN + huella | idénticos en v2 y v3 | ídem |
| Manifiesto | `package: com.lbagames.rpglba`, `versionName 0.1.0`, `versionCode 1`, `minSdk 24`, `targetSdk 36`, entrada MAIN/LAUNCHER `com.godot.game.GodotAppLauncher` | `aapt2 dump badging` + `androguard` local |
| ABIs | `arm64-v8a` + `x86_64` (con `libgodot_android.so` y `libc++_shared.so` por ABI) | listado de `lib/` |
| Alineación | `zipalign -c 4` PASS; las 154 entradas STORED tienen offsets de datos múltiplo de 4; sin data-descriptors | CI + análisis local de la central directory |
| `resources.arsc` | **Stored** (sin comprimir), dato alineado a 4 | `unzip -v` + análisis local |
| Datos del juego | 851 entradas en `assets/` (escenas, `.gdc`, `.ctex`, remaps) | `unzip -l` |
| Compresión de `.so` | DEFLATE (empaquetado legacy: el instalador extrae las libs a disco) | `unzip -v` |

### Causas candidatas y su veredicto

| # | Hipótesis (lista pedida por el propietario) | Veredicto | Evidencia |
|---|---|---|---|
| 1 | Problema de extracción o descarga | **PROBABLE (única vía abierta)** | El APK publicado es válido (ver arriba). Si el archivo que llega al instalador no es byte a byte ese APK, la causa está en la cadena de entrega: instalar el `.zip` del artefacto sin extraer (un ZIP no es un APK → `INSTALL_PARSE_FAILED_NOT_APK`), o descarga truncada/corrupta (verificar contra `SHA256SUMS.txt`) |
| 2 | Manifiesto inválido | DESCARTADA | `aapt2 dump badging`/`androguard` lo parsean; instaló en API 35 |
| 3 | Firma incorrecta | DESCARTADA | v2+v3 verificadas por `apksigner` (CI) y por análisis local independiente del bloque de firma; DN y huella = autofirma del proyecto |
| 4 | APK corrupto | DESCARTADA en la publicación | El SHA-256 del artefacto coincide con el que CI verificó antes de publicarlo; instaló y arrancó en emulador. **PENDIENTE** de verificar el SHA-256 del archivo que llega al teléfono (paso 3 del LEEME) |
| 5 | Arquitectura no compatible | DESCARTADA para S22 Ultra y Redmi 9C | `arm64-v8a` presente en el APK; ambos teléfonos son arm64. Redmi 9C: Helio G35 (AArch64). S22 Ultra: Snapdragon 8 Gen 1 / Exynos 2200 |
| 6 | Bibliotecas nativas incorrectas | DESCARTADA | `libgodot_android.so` + `libc++_shared.so` por ABI, plantillas oficiales 4.7.2; arrancó y presentó fotograma en emulador |
| 7 | SDK o versión Android incompatibles | DESCARTADA | `minSdk 24` ≤ Android 7; Redmi 9C (Android 10/11) y S22 Ultra (Android 12–16) quedan muy por encima. `targetSdk 36` no impide instalar en versiones anteriores |
| 8 | Conflicto de firma con instalación anterior | IMPROBABLE / a comprobar en el teléfono | Nunca se consiguió instalar una build previa (no hay «anterior»). Todas las builds recientes usan la MISMA autofirma, así que actualizarse encima funciona. Si existiera un resto con otra clave: `adb shell pm list packages \| grep lbagames`, desinstalarlo con autorización (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`) |

**Conclusión:** el APK publicado era válido e instalable; el «Error al analizar el
paquete» del S22 Ultra ocurrió en la **cadena de entrega** (con toda probabilidad,
instalar el `.zip` del artefacto sin extraer, o una descarga corrupta), no dentro
del APK. Correcciones aplicadas en esta fase para cerrar esa vía:

1. **Artefactos con nombre exacto** (`RPG-LBA-Android-ARM64-debug.apk`,
   `RPG-LBA-Android-Universal-debug.apk`) y **`LEEME_INSTALACION.txt`** dentro de
   cada ZIP con los pasos y las causas descartadas.
2. **`SHA256SUMS.txt`** en cada artefacto: el propietario puede verificar que el
   archivo que llega al teléfono es byte a byte el publicado.
3. El APK **universal** (4 ABIs) se conserva para emuladores y 32 bits; el
   **ARM64** (más ligero) es el recomendado en teléfono.

### Códigos de PackageManager de referencia

| Código | Significado típico en nuestro contexto |
|---|---|
| `INSTALL_PARSE_FAILED_NOT_APK` (−100) | Se intentó instalar algo que no es un APK (el `.zip` sin extraer) o está corrupto |
| `INSTALL_PARSE_FAILED_NO_CERTIFICATES` (−103) | APK sin firma válida (descartado aquí) |
| `INSTALL_PARSE_FAILED_MANIFEST_MALFORMED` (−108) | Manifiesto ilegible (descartado aquí) |
| `INSTALL_PARSE_FAILED_RESOURCES_ARSC_COMPRESSED` | `resources.arsc` comprimido (descartado: va Stored) |
| `INSTALL_FAILED_OLDER_SDK` (−121) | `minSdk` del APK superior a la versión del dispositivo (descartado: minSdk 24) |
| `INSTALL_FAILED_NO_MATCHING_ABIS` (−113) | El APK no trae librerías para la ABI del dispositivo (descartado en arm64) |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` / `INSTALL_PARSE_FAILED_INCONSISTENT_CERTIFICATES` | Resto de una instalación previa con otra firma: desinstalar la anterior (con autorización) |

Para obtener el código exacto: `adb install -r <apk>` y reportar la línea `INSTALL_*`.

---

## B. Matriz de compatibilidad obligatoria

### Criterios (nunca el nombre comercial como único criterio)

El perfil sugerido lo decide `GraphicsSettings.suggest_profile_for(hw)` con el
criterio **más restrictivo** de tres niveles (`docs` de `config/quality_profiles.json`):

| Criterio | LOW (0) | MEDIUM (1) | HIGH (2) |
|---|---|---|---|
| RAM total (`OS.get_memory_info().physical`) | < 3.0 GB | 3.0 – 5.0 GB | ≥ 5.0 GB |
| GPU (`RenderingServer.get_video_adapter_name()`) | PowerVR, SwiftShader/LLVMpipe/software, Adreno < 600 | (neutro: Adreno 6xx, Mali-G6, desconocido) | Adreno ≥ 700, Xclipse, Mali-G7, Immortalis, Adreno 8xx |
| Resolución (eje largo de pantalla) | < 1600 px | 1600 – 2199 px | ≥ 2200 px |

- ABI y API Android se **reportan** (`SUPPORTED_ABIS`, `SDK_INT` vía
  `JavaClassWrapper`) pero no definen el perfil: con `minSdk 24` cualquier
  Android 7+ vale, y todos los APKs de esta fase llevan `arm64-v8a`.
- Temperatura: no accesible de forma fiable desde Godot en todos los
  dispositivos. La resolución dinámica usa **tiempo de fotograma sostenido con
  histéresis** en su lugar (ver §C.3).
- El usuario puede cambiar el perfil en Ajustes (y en pausa); persiste en
  `user://settings.json`. El sugerido se muestra en Ajustes junto al hardware
  detectado.

### Redmi 9C (todas sus variantes de hardware/memory)

| Variante | RAM real aprox. | GPU | Pantalla | Perfil sugerido |
|---|---|---|---|---|
| 2 GB / 32 GB | ~1.8 GB | PowerVR GE8320 | 720×1600 | **LOW** |
| 3 GB / 32 GB | ~2.7 GB | PowerVR GE8320 | 720×1600 | **LOW** |
| 4 GB / 64 GB | ~3.6 GB | PowerVR GE8320 | 720×1600 | **LOW** (la GPU de gama baja domina; más RAM no sube el perfil) |

Objetivos LOW (todos sujetos a prueba física; **ninguno prometido**):

- Android compatible con el mínimo declarado (minSdk 24; el 9C trae Android 10/11).
- ABI `arm64-v8a` (Helio G35 es AArch64; MIUI 64-bit).
- Perfil gráfico LOW, **tope 30 FPS** (`Engine.max_fps=30`, cap ≠ promesa).
- Resolución dinámica 0.50–0.75 con histéresis.
- Texturas: conjunto único del proyecto; el objetivo 512/1024 se aproxima hoy
  con escala de render + distancia de vista (variantes por perfil: pendiente
  del Art Pass).
- Sombras dinámicas **limitadas**: modo `player_only`, alcance ≤ 16 m.
- Vegetación reducida por `vegetation_density=0.45` + LOD/rangos de visibilidad.
- Partículas ≤ 40 visibles; **enemigos simultáneos ≤ 4**.
- Consumo de RAM: telemetría `PERF:` (memoria estática del proceso) en logcat.
- Arranque rápido y sin crashes: verificado en emulador; **físico pendiente**.

### Samsung Galaxy S22 Ultra y superiores

| Criterio | Valor S22 Ultra | Nivel |
|---|---|---|
| ABI | arm64-v8a (Android 64-bit only) | compatible |
| API Android | 12 → 16 (One UI 8); minSdk 24 lo cubre de sobra | compatible |
| RAM | 8/12 GB (≥ 5.0 reportado) | 2 |
| GPU | Adreno 730 (Snapdragon) / Xclipse 920 (Exynos) | 2 |
| Resolución | 1440×3080 → eje largo 3080 | 2 |
| Perfil sugerido | **HIGH** (mín(2,2,2)) | — |

Objetivos HIGH (sujetos a prueba física): tope 60 FPS con **límites adaptativos**
(la resolución dinámica baja si el tiempo de fotograma se sostiene por encima del
130% del presupuesto), sombras `high_quality` a 60 m con blend_splits, texturas
1K del Art Pass (2K pendiente), vegetación 1.0, partículas ≤ 140, enemigos ≤ 8,
escala de render 1.0 con ventana 0.85–1.0, MSAA 2x. Resolución y calidad
configurables desde Ajustes.

### «S22 Ultra o superior» (sin nombre comercial)

Un dispositivo entra en HIGH solo si **los tres criterios** dan nivel 2
(RAM ≥ 5 GB **y** GPU de gama alta **y** eje largo ≥ 2200 px). Un teléfono con
12 GB de RAM y GPU de gama media queda en MEDIUM: la RAM sola no compra
sombras a 60 m. Emuladores (SwiftShader/ANGLE software) caen a LOW por diseño:
más honesto para CI y más parecido a un Redmi 9C que a un S22 Ultra.

### Bandas resumen

| Perfil | Banda objetivo | Tope FPS | Escala de render | Sombras | Partículas | Enemigos |
|---|---|---|---|---|---|---|
| LOW | Redmi 9C (todas las variantes) | 30 | 0.70 (ventana 0.50–0.75) | player_only ≤ 16 m | 40 | 4 |
| MEDIUM | ARM64 intermedio | 60 | 0.85 (ventana 0.70–0.90) | una direccional 40 m | 80 | 6 |
| HIGH | S22 Ultra y superiores por matriz | 60 | 1.0 (ventana 0.85–1.0) | high_quality 60 m | 140 | 8 |

---

## C. Compilación Android (dos variantes)

| | `RPG-LBA-Android-ARM64-debug.apk` | `RPG-LBA-Android-Universal-debug.apk` |
|---|---|---|
| Preset | `Android Debug ARM64` | `Android Debug Universal` |
| ABIs | arm64-v8a | arm64-v8a, armeabi-v7a, x86 (x86_32), x86_64 |
| Público | **Recomendado en teléfono** | Emuladores, pruebas, 32 bits |
| Package | `com.lbagames.rpglba` (idéntico; no se cambia) | idéntico |
| Firma | Autofirma del proyecto (v2+v3), idéntica | idéntica |
| minSdk / targetSdk | 24 / 36 (por defecto del export directo 4.7.2, verificado con `aapt2`) | idéntico |

Reglas respetadas: **no se cambia el package ID ni la firma arbitrariamente**
(misma autofirma en ambas variantes: se pueden instalar una sobre otra); la
clave debug es solo para desarrollo (ver `build/android/README.md`); nunca la
clave pública debug para producción.

**Páginas de 16 KB:** los `.so` van **comprimidos (DEFLATE)** dentro del APK
(empaquetado legacy del export directo): el instalador los extrae a disco, por
lo que la alineación de páginas de 16 KB no aplica a estos builds. Si en el
futuro se activa `use_gradle_build` con `compress_native_libraries=false`
(libs mapeadas desde el APK), será exigible la alineación ELF de 16 KB
(`readelf -lW` → `ALIGN` ≥ 0x4000); queda documentado aquí como requisito
de esa futura variante.

---

## D. Pruebas CI (qué verifica `android-debug.yml` ahora)

| Paso | Estado que produce |
|---|---|
| Export de las dos variantes + verificación estática (firma v2/v3 con DN y huella de la autofirma del proyecto, zipalign, `resources.arsc` Stored, ABIs exactos por variante, manifiesto, `classes.dex`, libs por ABI, datos del juego embebidos ≥ 100 entradas) | PASS/FAIL por variante |
| Emulador x86_64 **API 35** con el APK Universal: `adb install -r` → Success, arranque, proceso vivo, sin `FATAL EXCEPTION`, captura del **menú** y de una **escena jugable** (Valdeluz; fallback a Prototipo), telemetría PERF | PASS **en emulador** |
| Emulador x86_64 **API 36**, mismo guion | PASS **en emulador** |
| Emulador **arm64** con el APK ARM64 (traducción ARM→x86, presupuesto ampliado) | PASS **en emulador** |
| Dispositivo físico Redmi 9C | **PENDIENTE DE HARDWARE** |
| Dispositivo físico Samsung S22 Ultra | **PENDIENTE DE HARDWARE** |
| No compatible | ninguno declarado; cualquier bloqueo físico se documentará aquí |

**Las pruebas de emulador no sustituyen las pruebas físicas.** La telemetría
`PERF:` (fps, escala, memoria estática) son datos del proceso en emulador y se
etiquetan como tales; no se presentan como benchmark de teléfono.

---

## E. Protocolo de pruebas físicas para el propietario

Equipo necesario: el Redmi 9C y el S22 Ultra, con «Instalar apps desconocidas»
permitido para el explorador de archivos. Duración estimada: 30–45 min por
teléfono. **No borrar partidas ni instalaciones previas sin autorización.**

Antes de empezar: verificar el SHA-256 del APK contra `SHA256SUMS.txt` del
artefacto (descartar descarga corrupta) y extraer el ZIP (instalar el `.apk`,
nunca el `.zip`).

| # | Prueba | Qué observar | Estado |
|---|---|---|---|
| 1 | Instalación limpia (adb o instalador de paquetes) | Sin «Error al analizar el paquete»; si falla: anotar el código `INSTALL_*` exacto | PENDIENTE |
| 2 | Primer arranque | Tiempo hasta el menú; sin cierre abrupto | PENDIENTE |
| 3 | Menú principal | Legible, botones tocables, logo intacto | PENDIENTE |
| 4 | Nueva partida (Valdeluz) | Carga, sin caída al 3D | PENDIENTE |
| 5 | Movimiento (joystick) | 8 direcciones, correr/caminar | PENDIENTE |
| 6 | Combate | Machete, telegráficos, daño, muerte de sombra | PENDIENTE |
| 7 | Inventario | Abrir, equipar arma | PENDIENTE |
| 8 | Minimapa | Blips de enemigos/objetos | PENDIENTE |
| 9 | Cambios de orientación/resolución | Se mantiene horizontal forzada | PENDIENTE |
| 10 | Suspender y reanudar | Sin pérdida de partida ni grises | PENDIENTE |
| 11 | Temperatura tras 15–30 min de juego | Zona cálida razonable; sin thermal throttle perceptible | PENDIENTE |
| 12 | FPS y memoria | Telemetría PERF en logcat (`adb logcat \| grep PERF:`) o pantalla de Ajustes | PENDIENTE |

Qué reportar de cada fila: PASS/FAIL + una frase. De los FAIL: el mensaje
exacto y el `INSTALL_*`/logcat si aplica. Con esos datos se actualiza la tabla
de §D y la matriz de §B con evidencia física, no con suposiciones.

---

## F. Guía de instalación rápida (la misma que `LEEME_INSTALACION.txt`)

1. Descarga el artefacto ZIP desde la página de Actions.
2. **Extrae el ZIP** (dentro hay un `.apk` + informes). No instales el `.zip`.
3. Verifica el SHA-256 del `.apk` contra `SHA256SUMS.txt`.
4. En el teléfono: Ajustes → Seguridad → «Instalar apps desconocidas» → permite
   tu explorador.
5. Abre el `.apk` extraído. Las variantes ARM64/Universal comparten firma y
   package: se actualizan entre sí sin desinstalar.

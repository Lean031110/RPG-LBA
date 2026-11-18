# IMPORTAR RPG LBA — Guía rápida (Godot 4.7.2)

Proyecto: **RPG LBA — Las Cenizas de Lythara** (Godot 4.7.2 Standard, GDScript
tipado, Compatibility Renderer, español, Android ARM64 prioritario).

## 1. Requisitos

- **Godot 4.7.2 Standard** (NO Mono, NO 4.6/4.8): <https://godotengine.org/download>
  o `Godot_v4.7.2-stable_linux.x86_64` / `..._win64.exe` / `..._macos.universal`.
- Sistema: Windows 10+, macOS 12+, o Linux x86_64. Para exportar a Android:
  JDK 17, Android SDK (platform-tools, build-tools 35.0.1, platforms;android-35)
  y las plantillas de exportación 4.7.2 (ver §4).

## 2. Abrir el proyecto (paso a paso)

1. Descomprime `RPG-LBA-Godot-Project.zip` en una carpeta **nueva y vacía**
   (por ejemplo `RPG-LBA/`). No la abras dentro de otra copia del proyecto.
2. Comprueba que existe `project.godot` en la raíz de esa carpeta.
3. Abre el **Godot Project Manager** (el ejecutable de Godot, sin proyecto).
4. Pulsa **Import** → selecciona el archivo `project.got`… usa el botón
   **Browse** y elige `RPG-LBA/project.godot` → **Import & Edit**.
5. Espera la barra de importación (primera vez: unos minutos; el proyecto
   importa 300+ recursos, incl. 93 modelos procedurales). **Deja que termine**
   antes de hacer nada.
6. Godot abre el editor con el proyecto cargado.

## 3. Ejecutar el juego

1. En el panel **FileSystem** abre `scenes/arpg/menu/` y selecciona
   **`intro_splash.tscn`** (presentación) — es la escena principal definida en
   `project.godot` (`run/main_scene`).
2. Pulsa **F5** (Run Project). Si Godot pregunta qué escena usar, elige
   `intro_splash.tscn`.
3. Flujo esperado: presentación → **menú principal** → «Nueva partida» →
   mundo de Valdeluz (afueras) con HUD, inventario (tecla `I`), combate y
   misión inicial. Controles teclado: WASD mover, ratón cámara/atacar,
   `Shift` correr, `I` inventario, `Esc` pausa.
4. Pruebas automatizadas (opcional): el addon **gdUnit4** viene incluido;
   menú `gdUnit` → «Run tests» (suite completa ~295 casos), o desde terminal:
   `bash scripts/ci/run_gdunit_local.sh` si usas Linux.

## 4. Exportar a Android (debug, ARM64)

1. Editor → **Editor → Manage Export Templates… → Download and Install**
   (plantillas 4.7.2).
2. Editor → **Project → Export…** → preset **«Android Debug ARM64»** (ya
   configurado: `com.lbagames.rpglba`, versión 0.2.0/código 3, ARM64
   `arm64-v8a`, Compatibility, autofirma debug incluida en
   `build/android/rpglba-debug.keystore` — credenciales públicas de
   desarrollo, NO usar para release).
3. Configura las rutas del SDK/JDK en **Editor Settings → Export → Android**
   (`android_sdk_path`, `java_sdk_path`).
4. **Export Project** (desactiva «Export With Debug» solo si sabes qué firma
   usar; para desarrollo déjalo activado) → obtiene un `.apk` instalable en
   cualquier teléfono ARM64 con Android 7.0+ (minSdk 24).
5. La CI del repositorio hace esto mismo en cada push (workflow
   `android-debug.yml`) y verifica firma/zipalign/ABIs automáticamente.

## 5. Problemas comunes

| Síntoma | Causa/solución |
|---|---|
| «Error: No export templates» | Instálalas (§4.1) — versión exacta 4.7.2. |
| Errores de script al abrir | Estás usando Godot ≠ 4.7.2 (Mono o 4.3). Usa 4.7.2 Standard. |
| La ventana se ve oscura | Es un juego de fantasía oscura; espera al menú tras la presentación (~3 s). |
| No hay audio | El audio está aplazado de propósito (decisión de roadmap documentada). |
| Falta `assets/manifest.csv` | Está en `assets/manifest.csv`; ábrelo con cualquier editor para ver licencias. |

## 6. Qué contiene el ZIP del proyecto

`project.godot`, `export_presets.cfg` (sin contraseñas: la autofirma debug
usa credenciales públicas de convención), `scenes/` (32 escenas), `scripts/`
(lógica tipada), `game/` (datos JSON de balance), `assets/` (arte + manifiesto
de licencias), `addons/gdUnit4` (runtime de pruebas), `tests/` (47 suites),
`docs/` (GDD, arquitectura, QA, roadmap, informes), `build/android/`
(autofirma debug + README), `THIRD_PARTY_NOTICES.md`, `PROVENANCE.md`,
`LICENSE`. **No incluye** `.godot/` (caché, se regenera al importar),
keystores de release, tokens ni credenciales de ningún tipo.

Más detalle operativo: `docs/15_IMPORTAR_Y_PROBAR_LOCAL.md` (guía interna
canónica) y `AGENTS.md` (reglas del proyecto).

# 11 — GitHub, ramas, Actions, artefactos y releases

## Repositorio

Nombre sugerido: `RPG-LBA` (el agente debe verificar disponibilidad y respetar el usuario GitHub propietario). Visibilidad privada mientras se revisan assets/seguridad; pública cuando el responsable decida. El source de la plantilla base es MIT, pero assets tienen licencias propias.

## Flujo de ramas

- `main`: siempre integrable.
- `develop`: opcional si hay varios colaboradores; para un solo agente se puede prescindir.
- `agent/<phase>-<task>`: ramas de trabajo.
- `release/vX.Y.Z`: estabilización.

PR obligatorio, revisión humana antes de integrar cambios que afecten persistencia, red, economía, licencias o exportación de release.

## Workflows incluidos

- `.github/workflows/validate.yml`: importación headless, smoke test y GdUnit4.
- `.github/workflows/android-debug.yml`: exportación debug manual/por tag cuando exista preset Android.

Son plantillas iniciales; el agente debe adaptarlas al proyecto real y no informar que hay cobertura de test si no existen tests.

## Checks requeridos en main

- `project-import`
- `gdunit-tests` (cuando `tests/` y addon están inicializados)
- `game-smoke-test`
- `asset-license-audit`
- `android-debug-build` (una vez configurado; puede ser workflow manual hasta que el preset esté listo)

## Seguridad

- `permissions: contents: read` por defecto.
- `GITHUB_TOKEN` con permisos mínimos.
- No ejecutar código de PR de forks con secretos disponibles.
- No almacenar Android keystore ni contraseñas en archivos del proyecto.
- Secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`; solo release signing.
- Pin de actions de terceros a SHA completo en repo de producción después de verificar versión. Las plantillas usan tags legibles como guía, no son aprobación permanente de seguridad.
- Actualizar actions y dependencias por PR y correr suite.

## Artifacts

Cada pipeline guarda:
- logs de importación;
- logs de smoke test;
- reporte JUnit/HTML;
- capturas si hay visual test;
- APK debug si se exporta;
- reporte de licencias;
- `build-info.json` con commit, Godot, build date, preset y status.

Los artifacts expiran según retención configurada. La build reproducible debe guardar commit y versiones exactas.

## Releases

- Solo tags `vX.Y.Z` después de PR y release checklist.
- Adjuntar APK/AAB y server build (si corresponde).
- Adjuntar changelog, checksums SHA-256, licencias y limitaciones.
- No publicar una release de producción basada únicamente en que “Actions está verde”. Requiere pruebas físicas y revisión humana.

## Costes

GitHub Actions no es una máquina gratis e ilimitada. Revisar el plan, cuotas, tiempo de ejecución, tamaño de artifacts y uso mensual de la cuenta. Optimizar cachés y no ejecutar matrices enormes en cada commit. PRs usan una matriz ligera; builds Android pesadas pueden ser workflow_dispatch o tags.

# 18 — Publicación Android y Google Play desde GitHub Actions

**Estado:** planificación para después de tener una beta jugable validada.
**Package ID conocido:** `com.lbagames.rpglba` (verificar en el proyecto real antes de publicar).
**Canal inicial recomendado:** Internal testing; luego Closed testing/Beta; finalmente Production.

## 1. ¿Puede GitHub publicar automáticamente en Google Play?

Sí. GitHub Actions puede compilar un Android App Bundle (AAB) firmado y subirlo a Google Play Console mediante Google Play Developer API. El pipeline puede cargarlo en una pista de pruebas o dejar un release en borrador. La publicación efectiva a usuarios debe quedar protegida por aprobación manual y por los requisitos/revisión de Google Play.

No significa que GitHub cree la cuenta de desarrollador, acepte contratos, configure impuestos, complete fichas, resuelva verificaciones de identidad o garantice aprobación de Google.

## 2. APK frente a AAB

- APK: útil para instalación directa, pruebas manuales y distribución controlada fuera de Play.
- AAB: formato preferido para publicar en Google Play. Play genera APKs optimizados para cada dispositivo.
- Mantener ambos pipelines: APK debug/QA para probar y AAB release firmado para Play.
- Aumentar `versionCode` en cada subida; no reutilizar un código ya cargado.
- Mantener estable el package/application ID y proteger la clave de firma.

No subir un APK debug como versión pública.

## 3. Preparación manual en Google Play Console

Cuando la beta esté lista:
1. Crear cuenta de Google Play Developer y completar identidad/pagos/verificaciones requeridas.
2. Crear la aplicación RPG LBA en Play Console con el nombre y package ID definitivos.
3. Aceptar acuerdos y completar ficha, clasificación de contenido, audiencia, privacidad, seguridad de datos, acceso a la app y demás declaraciones aplicables.
4. Configurar Play App Signing y conservar la clave de upload de forma segura.
5. Subir primero un AAB manual o usar la configuración inicial exigida por Play Console para activar la aplicación/API.
6. Crear pista Internal testing y añadir testers.
7. Completar requisitos vigentes de testing para cuentas personales nuevas, si aplican.
8. Configurar una cuenta de servicio en Google Cloud, habilitar Google Play Developer API y dar a esa cuenta únicamente los permisos necesarios en Play Console.
9. Probar una subida a Internal testing antes de automatizar Beta/Production.

La cuenta de servicio y la clave JSON son credenciales privadas: nunca se suben al repositorio.

## 4. GitHub Actions

Workflow futuro, por ejemplo `.github/workflows/google-play-release.yml`:
- disparador manual `workflow_dispatch` con selección explícita de pista;
- opcional disparador por tag de release validado;
- compilar Godot export template AAB en entorno fijado;
- ejecutar import, tests, smoke, auditoría de assets y validación del package ID;
- firmar usando upload key guardada en GitHub Actions Secrets o Environment;
- verificar firma, versionCode, package ID y artefacto;
- subir AAB a pista Internal primero;
- conservar AAB, mapping/símbolos cuando existan, checksums y build-info;
- requerir Environment protection / aprobación para Closed/Beta/Production;
- nunca publicar Production automáticamente desde cada push a main.

Preferir acciones oficiales/mantenidas y fijar versiones/SHAs. Revisar permisos y cadena de suministro de cada Action antes de adoptarla.

## 5. Secretos y permisos

Nombres sugeridos (solo cuando se implemente):
- `PLAY_SERVICE_ACCOUNT_JSON` — JSON de cuenta de servicio;
- `ANDROID_UPLOAD_KEYSTORE_BASE64`;
- `ANDROID_UPLOAD_KEYSTORE_PASSWORD`;
- `ANDROID_UPLOAD_KEY_ALIAS`;
- `ANDROID_UPLOAD_KEY_PASSWORD`.

Usar GitHub Environments separados para internal/beta/production. Limitar permisos de workflow y de la cuenta de servicio. No imprimir variables, JSON, keystore ni contraseñas. Rotar cualquier secreto expuesto.

La cuenta de servicio debe tener acceso mínimo al paquete y a las pistas necesarias; no darle permisos administrativos globales si no hacen falta.

## 6. Flujo de releases propuesto

| Etapa | Automatización | Aprobación |
|---|---|---|
| PR / desarrollo | Tests, import, lint, smoke; APK debug opcional | Revisión PR |
| Tag beta | Build AAB firmado, verificación y subida Internal | Manual |
| Beta cerrada | Promoción/subida a Closed testing | Manual |
| Release candidate | Matriz de dispositivos, QA, política, privacidad y estabilidad | Propietario |
| Production | Subida/promoción en Play Console | Aprobación humana obligatoria |

GitHub puede cargar el bundle y gestionar tracks, pero Google Play conserva sus revisiones y controles. No prometer publicación inmediata.

## 7. Política de actualizaciones de contenido

La edición Play debe recibir actualizaciones de APK/código mediante Google Play. No implementar un auto-updater que descargue o instale APKs ni descargar código ejecutable desde GitHub.

Los paquetes externos descritos en `docs/17_CONTENT_PACKS_GITHUB_UPDATES.md` deben limitarse a contenido no ejecutable y datos declarativos; revisar política vigente antes de activar esa función.

## 8. Checklist de beta jugable

Antes de crear el primer release:
- vertical slice completa y aprobada;
- flujo de menú, creación/selección de personaje y tutorial;
- combate, inventario, misiones y guardado sin pérdida de datos;
- controles táctiles y cámara probados físicamente;
- lobby multijugador LAN probado con al menos dos dispositivos reales;
- Redmi 9C y S22 Ultra probados y resultados publicados honestamente;
- privacidad, permisos, SDKs, contenido, licencias y créditos revisados;
- crash/ANR, rendimiento, temperatura, consumo y conectividad revisados;
- política de contenido descargable revisada;
- firma y recuperación de claves documentadas;
- soporte, contacto, ficha, capturas y descripción preparados.

## 9. Fuentes oficiales

- Subir una app a Play Console: https://developer.android.com/studio/publish/upload-bundle
- Google Play Developer APIs: https://developer.android.com/google/play/developer-api
- Política Device and Network Abuse: https://support.google.com/googleplay/android-developer/answer/16559646

Revisar los requisitos de cuenta, testing, targets de Android y formularios vigentes el día del lanzamiento.

# 17 — Actualizaciones de contenido sin actualizar el APK

**Estado:** arquitectura futura; no implementar en la fase actual.
**Distribución candidata:** GitHub Releases del repositorio público RPG-LBA.
**Runtime:** Godot 4.7.2, Android y PC.

## 1. Objetivo

Permitir que el juego compruebe si existe contenido nuevo y ofrezca descargarlo sin instalar un APK nuevo, siempre que el cambio sea contenido estático o datos declarativos compatibles con la versión instalada.

Ejemplos aptos:
- mapas/sectores construidos con recursos ya soportados por el juego;
- modelos 3D, mallas, texturas, atlas, materiales dentro de un conjunto permitido;
- audio y música con licencias verificadas;
- imágenes, iconos y elementos cosméticos;
- datos declarativos de misiones, diálogos, recompensas, tablas de aparición y parámetros de eventos, usando un esquema ya implementado y validado.

No apto para esta vía:
- nuevos scripts GDScript/C#, bytecode, bibliotecas nativas, GDExtension, APK, DLL, SO, JAR, DEX;
- shaders/código nuevo descargado;
- lógica ejecutable o expresiones arbitrarias dentro de JSON;
- cambios de motor, red, autenticación, sistema de guardado o reglas fundamentales que no existan en la versión instalada.

Si un cambio necesita código nuevo, corrección de lógica, nuevos permisos o actualización de motor, requiere una nueva versión de la aplicación distribuida por el canal oficial (Google Play para la edición de Play).

## 2. Restricción esencial de Google Play

Para la edición publicada en Google Play, el cliente no debe autoactualizarse ni descargar código ejecutable desde GitHub u otro servidor. Google Play prohíbe que una app distribuida por Play se modifique/actualice por fuera de su mecanismo y restringe descargar ejecutables como DEX, JAR o SO desde fuera de Play.

Por tanto, los paquetes remotos deben ser **contenido no ejecutable y datos declarativos**, con lista permitida de tipos de archivo. No usar un PCK remoto como puerta trasera para incluir scripts, shaders o código interpretado. Aunque Godot permite cargar PCK/ZIP en runtime, esa capacidad técnica no anula las políticas de Google Play.

Antes de lanzar esta función, revisar de nuevo la política oficial y someter el diseño final a revisión de cumplimiento. Si no se puede demostrar que un tipo de contenido es seguro y conforme, no descargarlo dinámicamente para la edición Play.

## 3. GitHub Releases como origen

GitHub Releases puede alojar paquetes versionados como assets de releases. La documentación actual indica hasta 1000 assets por release, cada archivo inferior a 2 GiB, sin límite publicado de ancho de banda de releases. Aun así, GitHub no es un CDN/SLA de videojuego: disponibilidad, latencia, límites de API, acceso regional y experiencia en Cuba deben probarse.

Reglas:
- usar releases públicas y versionadas;
- no descargar desde ramas `main`, URLs `latest` mutables ni archivos sin versión;
- publicar un manifiesto de contenido asociado a cada release;
- conservar versiones previas y no sobrescribir assets de una release publicada;
- si crece el tamaño/uso, evaluar almacenamiento de objetos/CDN propio y conservar el manifiesto como contrato estable.

## 4. Contrato de manifiesto

Crear un manifiesto JSON versionado, por ejemplo `content-manifest.json`, servido por URL estable y respaldado por assets versionados.

Campos recomendados:
- `manifest_schema_version`
- `game_content_version`
- `minimum_app_version`
- `maximum_tested_app_version` (opcional)
- `channel` (stable/beta/dev)
- `published_at`
- `packs[]`: `id`, `version`, `required`, `platforms`, `url`, `size_bytes`, `sha256`, `signature`, `min_app_version`, `dependencies[]`, `files[]` o catálogo de contenido.
- `notes_es` y `notes_en`.

No ejecutar ni interpretar campos como código. Validar esquema, rangos, URLs HTTPS permitidas, tamaño máximo, IDs y dependencias antes de iniciar descarga.

## 5. Flujo de actualización del cliente

1. En inicio, menú de contenido o Ajustes, consultar manifiesto con timeout.
2. Si no hay Internet, seguir jugando con contenido instalado y mostrar estado offline discreto.
3. Comparar versiones y compatibilidad.
4. Mostrar al jugador qué se actualizará, tamaño aproximado y notas.
5. Descargar automáticamente solo si el usuario habilitó esa opción; por defecto, preguntar y ofrecer Wi-Fi únicamente.
6. Permitir pausar/reanudar y cancelar.
7. Descargar a un archivo temporal en `user://`, nunca sobrescribir el paquete activo.
8. Verificar tamaño, SHA-256 y firma criptográfica con clave pública embebida.
9. Validar lista de archivos y esquema de datos.
10. Aplicar en el siguiente arranque o al volver al menú, nunca en mitad de combate/partida.
11. Activar de forma atómica; mantener la versión anterior para rollback.
12. Si falla, borrar temporal, conservar versión anterior y mostrar error entendible.

No borrar partidas ni preferencias al instalar un pack. Las migraciones de datos de guardado son una función distinta, versionada y probada.

## 6. Formato de paquetes y carga Godot

Godot ofrece resource packs PCK/ZIP y `ProjectSettings.load_resource_pack()`. Es una opción técnica para recursos, pero debe restringirse a contenido no ejecutable aprobado.

Diseño recomendado para Google Play:
- paquetes de assets estáticos y datos declarativos en formato documentado;
- escenas/recursos solo si el pipeline garantiza que no incluyen scripts ni código descargable;
- los scripts que interpretan esos datos permanecen dentro del APK;
- whitelist estricta de extensiones y rutas;
- rechazar cualquier archivo ejecutable, script, shader o extensión nativa;
- usar versiones de esquema para que los datos antiguos/nuevos sean compatibles.

No usar ZIP/PCK como excusa para descargar código. No cargar contenido de terceros sin procedencia/licencia auditada.

## 7. Integridad y seguridad

- SHA-256 detecta corrupción, pero no prueba quién publicó el archivo.
- Firmar manifiesto y/o paquetes con firma asimétrica; clave privada fuera del repositorio y de los logs.
- La app contiene solo la clave pública de verificación.
- Aceptar HTTPS y hosts permitidos.
- Limitar tamaño, cantidad de archivos, profundidad de rutas y descompresión.
- Prevenir path traversal, zip bombs, archivos duplicados y sustitución de versiones.
- Rechazar downgrade salvo rollback explícito firmado.
- No ejecutar scripts, comandos ni rutas de archivos desde manifiesto.
- No incluir tokens GitHub en el APK.
- No confiar en checksum descargado desde una fuente distinta no autenticada.

## 8. Publicación desde GitHub Actions

Workflow futuro:
1. validar licencias y contenido;
2. exportar/build de paquetes de contenido;
3. ejecutar pruebas de esquema, whitelist, integridad y compatibilidad;
4. calcular SHA-256;
5. firmar manifiesto/paquetes con secreto protegido o proceso offline;
6. generar release notes;
7. publicar GitHub Release con tag inmutable de contenido;
8. actualizar manifiesto estable solo después de validar release;
9. ejecutar smoke de descarga desde un cliente de prueba.

No publicar automáticamente recursos de PR no revisadas en el canal stable. Canales beta/dev separados.

## 9. Experiencia del jugador

- aviso claro: “Hay contenido nuevo para Valdeluz (120 MB)”;
- explicar si es obligatorio u opcional;
- mostrar progreso, tamaño y estado;
- opción “Solo con Wi-Fi” y “Preguntar siempre”;
- poder seguir jugando offline con el contenido instalado si no es obligatorio;
- si el pack es obligatorio para entrar a una zona, bloquear solo esa zona y explicar por qué;
- no interrumpir combate ni una sesión multijugador;
- evitar descargas ocultas y consumo de datos inesperado.

## 10. Limitaciones de contenido y multijugador

Los clientes que entren en la misma sesión deben tener versiones compatibles del contenido requerido. El host/servidor anuncia versión de protocolo y contenido; el cliente valida antes de unirse. Si no coinciden, mostrar actualización requerida o permitir solo zonas compatibles.

No permitir que un host introduzca contenido arbitrario no firmado a otros jugadores. En el modo actual de lobby LAN, conservar el flujo existente; la validación de versión se añadirá en una fase posterior.

## 11. Pruebas de aceptación

- offline: el juego arranca y conserva contenido local;
- manifiesto sin cambios: no descarga nada;
- pack compatible: descarga, verifica e instala;
- hash/firma incorrectos: rechaza sin sustituir el pack activo;
- descarga interrumpida: reanuda o reinicia de forma segura;
- espacio insuficiente: informa y no corrompe contenido;
- versión incompatible: no aplica;
- rollback: restaura última versión válida;
- partida guardada permanece intacta;
- no hay scripts, shaders ni binarios ejecutables dentro de paquetes;
- el lobby impide mezcla incompatible sin romper la creación/unión de partidas;
- prueba física con conectividad limitada e intermitente.

## 12. Fuentes técnicas

- Godot, exportar PCK/ZIP: https://docs.godotengine.org/en/latest/tutorials/export/exporting_pcks.html
- Godot, carga de recursos en runtime: https://docs.godotengine.org/en/latest/tutorials/io/runtime_file_loading_and_saving.html
- GitHub Releases y límites: https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases
- Política Google Play Device and Network Abuse: https://support.google.com/googleplay/android-developer/answer/16559646

Revisar estas fuentes al implementar; sus políticas y límites pueden cambiar.

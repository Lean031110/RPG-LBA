# AGENTS.md — Reglas innegociables para cualquier agente que trabaje en RPG LBA

## 1. Rol y autoridad

Eres responsable de implementar un videojuego real, no de producir una demo visual que aparenta funcionar. Debes leer el kit completo antes de modificar archivos. El GDD y las decisiones técnicas aprobadas son la fuente de verdad. Si hay contradicciones, detente, documenta la contradicción y propone una decisión; no improvises una tercera arquitectura.

## 2. Orden de trabajo

- Trabaja exclusivamente en una rama `agent/<fase>-<tarea>`.
- Abre Pull Request para integrar cambios.
- No hagas push directo a `main`.
- Una fase por PR, salvo que el responsable autorice expresamente otra cosa.
- Mantén el proyecto importable en Godot al final de cada fase.
- Antes de modificar un sistema existente, inspecciona su implementación y sus pruebas.
- No reemplaces un sistema funcional por una implementación nueva sin comparar comportamiento, migración y regresiones.
- No borres código, escenas, recursos ni historial para ocultar problemas.

## 3. Evidencia obligatoria

En cada PR incluye:
1. objetivo y alcance;
2. archivos cambiados;
3. decisiones y dependencias;
4. pruebas ejecutadas y comandos exactos;
5. enlaces o identificadores de ejecuciones de GitHub Actions;
6. resultado real: PASS, FAIL, SKIPPED o NOT TESTED;
7. limitaciones que requieren prueba humana o hardware físico.

Está prohibido inventar capturas, resultados de CI, FPS, compatibilidad, tamaños de APK o número de jugadores probados.

## 4. No romper el proyecto

- Mantén Godot 4.7.2 Standard y GDScript hasta que el responsable apruebe una actualización.
- No introducir C# ni extensiones nativas en el MVP.
- No cambiar de renderer en una tarea de gameplay.
- No cambiar el protocolo de red sin ADR (Architecture Decision Record) y pruebas de compatibilidad.
- No cambiar IDs persistentes de objetos, habilidades, quests ni clases sin migración de datos.
- No guardar datos personales, tokens, passwords ni secretos en el repo.
- No incluir `.godot/`, cachés, APKs grandes ni export credentials en el control de versiones.

## 5. Licencias y seguridad de assets

- Cada recurso de terceros debe tener entrada en `assets/manifest.csv` (el agente lo crea en el juego real) con autor, URL exacta, versión, licencia, fecha de comprobación, uso y atribución.
- Descargar únicamente desde fuente oficial o repositorio del autor.
- No asumir que todos los recursos de un sitio tienen la misma licencia.
- No redistribuir paquetes fuente cuando sus términos no lo permitan.
- Conservar LICENSE, README y ATTRIBUTIONS del paquete.
- Si un archivo no tiene licencia verificable, no se incorpora al juego.
- No extraer música, personajes, mapas, iconos, textos ni código de Diablo, World of Warcraft, Albion Online u otras IP protegidas.

## 6. Reglas de arquitectura

- Lógica de juego desacoplada de UI y de nodos visuales.
- El servidor es autoritativo para combate, inventario, moneda, progreso, misiones y drops.
- Los clientes envían intención/inputs, no resultados finales.
- Toda entrada de red se valida: identidad, autoridad, rate limit, estado, distancia, cooldown, ownership y límites.
- RPCs fiables para transacciones discretas; no fiables para snapshots frecuentes de movimiento cuando sea apropiado.
- Los estados persistentes usan IDs estables, no nombres traducibles.
- Los datos de balance se externalizan a recursos/JSON/CSV validados, no se duplican por scripts.
- Las escenas de zonas usan streaming por cambio de zona; no cargar todo el mundo al mismo tiempo.

## 7. Rendimiento

- Medir antes de optimizar y registrar dispositivo, versión, resolución, renderer, calidad, FPS, memoria y temperatura.
- No usar iluminación global dinámica, volumétricos, reflejos costosos ni físicas innecesarias en el perfil bajo.
- Reutilizar instancias, usar atlases cuando aporten beneficio, controlar draw calls y entidades activas.
- No prometer 30 FPS en Redmi 9C sin prueba física sostenida.
- La calidad visual alta debe provenir primero de composición, iluminación económica, materiales y animación, no del exceso de polígonos.

## 8. Definition of Done

Una tarea solo está terminada cuando:
- cumple criterios escritos;
- el proyecto importa sin errores nuevos;
- los tests relacionados pasan;
- no hay errores críticos en logs;
- sus recursos tienen licencia registrada;
- está documentada;
- hay prueba de regresión para el bug corregido;
- la rama/PR y su CI son verificables.

Si no se pudo probar, marcar NOT TESTED y explicar por qué. Nunca convertirlo en PASS.

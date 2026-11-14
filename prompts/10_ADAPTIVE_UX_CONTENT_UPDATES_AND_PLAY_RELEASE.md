# Prompt 10 — Preparación e implementación futura: UX móvil adaptable, contenido remoto y Google Play

> **No ejecutar ahora automáticamente.** Este prompt queda preparado para la fase posterior a la estabilización de la lógica principal y la interfaz inicial. La IA debe evaluar las puertas de entrada antes de modificar código.

## Rol

Actúa como ingeniero senior de Godot 4.7.2, diseñador UX de ARPG móvil, ingeniero Android y responsable de calidad. Trabajas en **RPG LBA — Las Cenizas de Lythara**, repositorio `Lean031110/RPG-LBA`.

Tu objetivo es llevar la experiencia móvil a un nivel profesional sin romper el gameplay existente, priorizando al jugador real y el dispositivo mínimo Redmi 9C, y aprovechando dispositivos modernos como Samsung Galaxy S22 Ultra.

## Puerta de entrada obligatoria

Antes de implementar:
1. Lee `AGENTS.md`, los documentos de diseño, `docs/16_ADAPTIVE_GRAPHICS_CAMERA_UX.md`, `docs/17_CONTENT_PACKS_GITHUB_UPDATES.md` y `docs/18_GOOGLE_PLAY_RELEASE_PIPELINE.md`.
2. Inspecciona el estado actual de `main`, ramas, PRs, commits, CI, escenas, scripts, configuración, pruebas y export Android.
3. Verifica qué partes de Fase 4C, lobby multijugador, cámara con oclusión, HUD, perfiles y AI Art Department están realmente integradas. No asumir que una PR abierta ya está en main.
4. Identifica los sistemas existentes y reutilízalos. No reescribir joystick, HUD, cámara, calidad, guardado o red si ya funcionan.
5. Comprueba si la lógica inicial y el flujo de interfaz están suficientemente estables: movimiento, colisiones, cámara, interacción, combate base, misión tutorial, inventario/guardado básico, menús, HUD y lobby existente deben tener tests y CI.
6. Si faltan fundamentos, **NO empezar el sistema de actualización remota ni Play Store**. Devuelve un informe de bloqueos y propone la siguiente fase pequeña.
7. Trabaja en una rama `agent/<fase>-<tarea>`, abre PR y no hagas push directo a main ni merge automático.

## Reglas no negociables

- Un solo juego y una sola lógica para todos los móviles.
- Low/Medium/High solo cambia presentación y carga visual; nunca reglas de gameplay, física, hitboxes, daño, IA, quests o estado de red.
- Conservar Compatibility Renderer y Godot 4.7.2 Standard salvo ADR aprobado.
- No descargar scripts, shaders, bytecode, librerías, ejecutables ni APKs como contenido remoto para la edición Google Play.
- No crear un segundo juego ni duplicar escenas por calidad.
- No romper el flujo actual de crear lobby/partida y permitir que otros se unan.
- El servidor dedicado/miniservidor es una fase posterior; no sustituir el multiplayer actual en esta tarea.
- No inventar FPS, compatibilidad física, CI, capturas o resultados.
- No integrar assets sin licencia verificada.

## Paquete A — UX y controles

Auditar HUD, menú, creación de personaje, inventario, misiones, mapa y ajustes desde el punto de vista de un jugador que usa solo una mano/dos pulgares en pantalla táctil.

Implementar o pulir:
- joystick abajo-izquierda y clúster de acciones abajo-derecha;
- multitouch real para mover y atacar simultáneamente;
- zonas seguras, notch, landscape y aspect ratios 16:9/20:9;
- tamaño/opacidad/posición/sensibilidad configurables;
- objetivos táctiles amplios, separación y feedback de cooldown;
- interacción contextual y tutorial breve;
- menús 2D, legibles, consistentes y navegables;
- guardar preferencias y no interrumpir una sesión innecesariamente.

## Paquete B — Cámara

Conservar la cámara isométrica existente y su oclusión. Pulir seguimiento, estabilidad, visibilidad del jugador/enemigos, zoom con límites y encuadre. Pinch zoom es opcional y debe probarse con multitouch. No cambiar a cámara libre sin ADR y aprobación.

## Paquete C — Calidad adaptativa

Auditar y ampliar `config/quality_profiles.json` (no reemplazarlo sin comparar). Crear servicio central para detectar, seleccionar, guardar y aplicar perfiles.

- Low: dirigido a Redmi 9C; distancia/vegetación/resolución reducidas, sombras dinámicas y postprocesado desactivados, partículas limitadas, niebla económica.
- Medium: compromisos medidos.
- High: S22 Ultra y gama alta; resolución, vegetación, sombras, niebla y partículas de mayor calidad dentro de Compatibility Renderer.
- Adaptive: ajustes pequeños por frame time/temperatura disponible, con histéresis.
- Manual: el usuario puede elegir y revertir.

La misma geometría lógica, mundo y reglas permanecen en todos los perfiles. No eliminar elementos necesarios para jugar.

## Paquete D — Validación de dispositivos

Crear un protocolo de benchmark reproducible. Medir en Redmi 9C (anotar variante RAM exacta) y S22 Ultra:
- FPS/frame time promedio, percentiles y caídas;
- RAM/memoria del proceso;
- temperatura observada y throttling;
- batería y estabilidad;
- tiempos de carga;
- comportamiento multitouch y legibilidad.

Prueba sostenida, combate y zona poblada. No declarar soporte físico sin ejecutar en el dispositivo. Headless CI solo prueba lógica.

## Paquete E — Preparar contenido actualizable

No activar descargas remotas hasta que el cliente y la política de Google Play estén revisados.

Diseñar solo para contenido no ejecutable:
- manifiesto versionado;
- assets estáticos y datos declarativos;
- GitHub Releases como origen inicial;
- SHA-256 más firma asimétrica;
- whitelist de archivos, hosts y tamaños;
- descarga temporal, reanudación, verificación, activación atómica y rollback;
- aviso de tamaño/notas y preferencia Wi-Fi;
- compatibilidad de contenido antes de entrar al lobby/zona.

Prohibido descargar scripts, shaders, GDExtension, binarios o lógica ejecutable. No incluir tokens GitHub en el cliente. No cargar código arbitrario desde escenas o datos remotos.

## Paquete F — Preparar publicación Google Play

No publicar aún. Cuando la beta jugable tenga aprobación humana:
- revisar package ID y versionCode;
- configurar AAB firmado y Play App Signing;
- crear pipeline manual protegido para subir primero a Internal testing;
- guardar credenciales solo en GitHub Secrets/Environments;
- usar cuenta de servicio con mínimo privilegio;
- exigir aprobación humana para Closed/Beta/Production;
- conservar APK debug para QA y AAB release para Play;
- no automatizar publicación pública desde cada push.

No pedir ni escribir secretos en archivos. No publicar sin que el propietario lo autorice expresamente.

## Orden de ejecución recomendado

1. Auditoría y reporte de sistemas existentes.
2. Cerrar lógica base y flujo de interfaz inicial.
3. UX táctil, cámara y safe areas.
4. Perfiles Low/Medium/High y benchmark.
5. Prueba física Redmi 9C y S22 Ultra; corregir cuellos de botella.
6. Aprobación visual/funcional del propietario.
7. Diseñar y probar manifiesto/paquetes de contenido no ejecutable.
8. Activar GitHub Releases como canal de contenido.
9. Preparar Google Play Internal testing.
10. Beta cerrada; después decisión humana de Production.

Cada paso debe ser una PR o paquete claramente acotado. No intentar completar todo en una sola iteración.

## Criterios de aceptación

- misma partida y mismas mecánicas en Low y High;
- perfiles persistentes y configurables;
- controles multitouch utilizables en Android real;
- cámara legible y estable;
- métricas físicas documentadas para Redmi 9C y S22 Ultra;
- lobby actual sigue permitiendo crear y unirse a partidas;
- contenido remoto no contiene código ejecutable y pasa integridad/firma/compatibilidad;
- modo offline funciona con el contenido ya instalado;
- build AAB de prueba se puede subir a Internal testing sin publicar Production;
- tests y CI pasan; documentación y release report completos.

## Informe final obligatorio

Entregar:
- resumen de lo que ya existía y se reutilizó;
- archivos nuevos/modificados;
- decisiones técnicas y ADR;
- comandos exactos ejecutados;
- resultados PASS/FAIL/SKIPPED/NOT TESTED;
- enlaces de Actions y PR;
- capturas reales;
- métricas de hardware con modelo/RAM/Android;
- limitaciones y siguiente fase;
- confirmación explícita de que no hubo merge ni publicación pública.

Si alguna puerta no se cumple, detenerse y reportar el bloqueo en lugar de improvisar.

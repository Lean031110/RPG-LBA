# RPG LBA — Kit de producción asistida por IA

**Versión del kit:** 1.0.0  
**Fecha de investigación:** 11 de noviembre de 2026  
**Motor objetivo:** Godot 4.7.2 Standard  
**Lenguaje:** GDScript  
**Plataforma principal:** Android (teléfonos modestos y potentes)  
**Nombre provisional completo:** **RPG LBA: Las Cenizas de Lythara**

## Qué contiene este archivo

Este ZIP es el **paquete maestro de diseño y ejecución para una IA de programación**. Contiene el documento de diseño del juego, narrativa, reglas de sistemas, arquitectura multijugador, arquitectura de Godot, dirección artística, catálogo preliminar de recursos, fases de trabajo, criterios de aceptación, política de pruebas, reglas para el agente y plantillas iniciales de GitHub Actions.

**No es todavía el videojuego compilado ni contiene redistribuidos todos los paquetes 3D.** La IA deberá clonar la plantilla base, comprobarla, obtener los recursos de sus fuentes oficiales y construir el juego siguiendo las fases. Esto evita distribuir copias de assets sin revisar sus términos y evita fingir que un proyecto sin compilar ya está terminado.

## Orden de lectura obligatorio para la IA

1. `AGENTS.md`
2. `docs/00_BRIEF_MAESTRO.md`
3. `docs/01_GDD.md`
4. `docs/02_NARRATIVA_Y_MISIONES.md`
5. `docs/03_CLASES_COMBATE_LOOT.md`
6. `docs/04_MUNDO_DUNGEONS.md`
7. `docs/05_MULTIJUGADOR_Y_SERVIDOR.md`
8. `docs/06_ARQUITECTURA_GODOT.md`
9. `docs/07_UX_CONTROLES_MOBILE.md`
10. `docs/08_DIRECCION_ARTISTICA_ASSETS.md`
11. `docs/09_ROADMAP_Y_PROMPTS.md`
12. `docs/10_QA_Y_VALIDACION.md`
13. `docs/11_GITHUB_Y_CI_CD.md`
14. `docs/12_CRITERIOS_DE_ACEPTACION.md`
15. `docs/13_RIESGOS_Y_DECISIONES.md`
16. `docs/14_FUENTES_Y_REFERENCIAS.md`

Después, ejecutar los prompts de `prompts/` **en orden y uno por uno**. No saltar a la siguiente fase hasta que se cumplan sus criterios de salida.

## Decisiones fundamentales

- RPG de acción 3D con cámara elevada/isométrica fija, inspirado en patrones de género, no una copia de Diablo, Albion u otros juegos.
- Arte 3D estilizado low-poly, con formas suaves, materiales legibles y animación clara.
- Proyecto principal escrito en GDScript, no C#.
- Renderer inicial Compatibility para favorecer compatibilidad con hardware modesto. La compatibilidad real se comprueba en dispositivos físicos; no se promete 30 FPS sin medición.
- Red multijugador cliente-servidor con **servidor dedicado autoritativo**. El cliente nunca decide daño, inventario, moneda ni recompensas.
- Primera prueba de red: 2 clientes. Primera capacidad objetivo del prototipo: 4 jugadores. Objetivo inicial por instancia de zona tras pruebas: hasta 10; no es promesa de MMO masivo.
- Un realm/mundo lógico con zonas conectadas en la primera entrega. Arquitectura preparada para múltiples realms con `world_id` y procesos/instancias independientes.
- Persistencia SQLite para desarrollo de una sola instancia; PostgreSQL como destino cuando haya varios procesos o producción.
- GitHub como fuente de verdad, Pull Requests, Actions, artefactos y releases.
- Nunca declarar que una prueba pasó sin registro real.

## Cómo usar el kit

1. Descomprime el ZIP.
2. Sube esta carpeta o sus documentos al agente de programación en la nube.
3. Dale primero el prompt `prompts/00_AUDITORIA_Y_BOOTSTRAP.md`.
4. Indícale el repositorio GitHub destino y asegúrate de que tiene permisos explícitos para crear ramas/PR.
5. Pide que trabaje en una rama y que no publique una release hasta que todas las comprobaciones requeridas estén verdes.
6. Revisa el primer informe antes de autorizar la implementación.

## Nota sobre la plantilla base

Punto de partida recomendado: `https://github.com/devmoreir4/godot-3d-multiplayer-template`, release `v2.0.0` (comprobar el tag y la licencia antes de clonar). La plantilla anuncia Godot 4.7, GDScript, sesiones, hasta 10 jugadores, inventario autoritativo, equipamiento, chat y servidor dedicado. Su código está bajo MIT; los assets de terceros se rigen por sus propias licencias. El ataque de muestra reproduce una animación, pero no implementa daño real. La IA debe comprobar todo esto en el código de la versión fijada.

## Qué significa “listo”

“Listo para importar” significa que existe un repositorio con `project.godot`, dependencias documentadas, recursos y archivos fuente, y que el workflow de CI ha importado y validado la versión correspondiente. “Listo para jugar” exige además pruebas de escena, pruebas funcionales y, para Android, una instalación física. “Listo para publicar” exige pruebas en dispositivos objetivo, seguridad del servidor, licencias y una release etiquetada. Son estados diferentes.

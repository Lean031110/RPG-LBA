# PROMPT 09 — ART PASS + UX PASS: GÓTICO CARIBEÑO (CUBA, 1953)

## AUTORIZACIÓN
Ejecuta exclusivamente el Art Pass + UX Pass de RPG LBA — Las Cenizas de Lythara. No avances a Fase 2 ni implementes las seis clases completas en esta tarea. La meta es corregir la presentación visual de la vertical slice y conseguir aprobación humana.

## PRIMERO: AUDITORÍA OBLIGATORIA
1. Lee AGENTS.md, README.md, docs/AGENT_BRIEFING_VISION_CUBANA.md, docs/01_GDD.md, docs/narrativa/00_BIBLIA_DEL_MUNDO_Y_HISTORIA.md, docs/direccion-artistica/03_DIRECCION_ARTISTICA_Y_UX.md, docs/13_RIESGOS_Y_DECISIONES.md, docs/visual_fase1 y el informe de Fase 1.
2. Comprueba el estado remoto real: main, rama Fase 1, commits, PR, Actions y archivos presentes. No asumas que el bundle local se subió.
3. Comprueba el árbol git, escenas, materiales, scripts, perfiles y pruebas existentes. No reemplaces sistemas funcionales sin entenderlos.
4. Informa el commit base exacto y crea rama agent/art-pass-cuban-dark-fantasy desde el commit aprobado. Nunca push directo a main.
5. Presenta plan breve y luego ejecuta sin pedir confirmación por cada archivo. Detente si hay conflicto de base o pérdida potencial de trabajo.

## DIRECCIÓN CREATIVA OBLIGATORIA
El juego ocurre en una Cuba ficticia de 1953. La estética es fantasía oscura gótico-caribeña. Referencia de calidad: atmósfera y claridad de un ARPG oscuro moderno, pero NO copies Diablo III ni ningún otro juego: nada de sus interfaces, iconos, mapas, personajes, tipografías, animaciones o assets.

El mundo debe parecer Cuba: tierra roja, césped tropical, palmas, ceibas, vegetación de manigua, piedra caliza, caminos de carreta, barro, charcos, madera, metal envejecido, portales coloniales, faroles, radios, trenes, bohíos y arquitectura cubana. Mantén el misterio medieval-fantástico con reliquias, monstruos, fortalezas, magia y ruinas.

## OBJETIVO A — TERRENO Y MATERIALES
Rehacer el bosque/escena de Valdeluz como una zona de calidad visual clara.
- Crear materiales distinguibles para césped, tierra roja, piedra caliza, barro húmedo, madera y metal.
- El césped debe tener variación de tono, parches, hierba agrupada y bordes naturales; no una alfombra verde uniforme.
- Los caminos deben ser tierra visible, con roderas, piedras, raíces y charcos donde tenga sentido.
- Distribuir árboles tropicales, palmas, ceibas, rocas y sotobosque con siluetas variadas.
- Evitar repetición evidente de texturas; usar UV/tiling controlado, variación de color, decals o mallas económicas.
- Los materiales deben funcionar en Compatibility Renderer y perfil Low.
- No incorporar recursos sin licencia comprobada y fila en assets/manifest.csv.

## OBJETIVO B — CIELO, HORIZONTE, DÍA Y NOCHE
- Añadir cielo y horizonte visibles, con nubes sencillas y atmósfera coherente.
- Ciclo configurable de 24 minutos reales por día de juego (valor inicial ajustable).
- Amanecer 05:30–07:00, día 07:00–17:00, atardecer 17:00–19:00, noche 19:00–05:30.
- Sol y luna se mueven suavemente; interpolar color e intensidad de luz y ambient light.
- Encender faroles y ventanas al anochecer.
- Mantener personaje, enemigos y telegráficos legibles durante toda hora.
- Clima básico: despejado, nublado, lluvia y niebla. Transiciones suaves; tormentas quedan para otra fase si comprometen alcance.
- Preparar el reloj para autoridad de servidor futura; el cliente interpola.
- No usar volumétricos ni efectos caros por defecto en Low.

## OBJETIVO C — REDISEÑO COMPLETO DE UI/UX
La UI actual no está aprobada. Rediseñar HUD, menú principal, ajustes, inventario/diario y pausa.
- Tema: negro carbón, azul petróleo, hierro envejecido, cuero, latón/oro viejo y acentos carmesí.
- Títulos góticos legibles; cuerpo sans serif clara.
- HUD: retrato/clase, nivel, HP/recurso, minimapa, objetivo de misión, vida de jefe, joystick izquierdo, acciones a la derecha, esquiva, consumible e interacción contextual.
- No tapar personaje, enemigos, telegráficos ni objetivo.
- Menú principal con logo, fondo de Valdeluz/La Habana, Continuar, Nueva partida, Personajes, Ajustes, Créditos y Salir.
- Ajustes por categorías: Controles, Gráficos, Audio, Accesibilidad y Juego.
- Diario con Historia, Secundarias, Encargos y Recuerdos.
- Inventario con silueta de personaje, slots, comparación y filtros.
- Escalado para 16:9, 20:9, tablets y safe areas; botones ajustables.
- Animaciones de UI breves; mantener respuesta táctil inmediata.
- No depender solo del color para estados.

## OBJETIVO D — PRUEBA VISUAL
Capturar:
1. Bosque de día.
2. Bosque al amanecer.
3. Bosque al atardecer.
4. Bosque de noche.
5. Primer plano de césped/tierra/piedra.
6. HUD en combate real con enemigo y telegráfico.
7. Menú principal.
8. Inventario o diario.
9. Ajustes Low/Medium/High.
10. Layout en relación 20:9.
Incluir comparativa antes/después. No usar capturas simuladas ni escenas vacías como evidencia de gameplay.

## RESTRICCIONES TÉCNICAS
- Godot 4.7.2 Standard, GDScript, Compatibility Renderer.
- No C#, extensiones nativas ni cambio de renderer.
- No borrar tests, assets ni sistemas existentes.
- No alterar IDs persistentes de misiones, objetos o enemigos sin migración.
- Mantener proyecto importable.
- Perfil Low debe ser funcional y legible.
- No afirmar FPS, compatibilidad Redmi 9C ni APK hasta medir/probar físicamente.
- Evitar shaders costosos, transparencias masivas y exceso de luces dinámicas.
- Mantener lógica separada de UI y nodos visuales.

## VALIDACIÓN
Ejecuta y reporta comandos reales:
- importación Godot dos pasadas;
- lint y formato GDScript;
- GdUnit4 completo;
- smoke test;
- pruebas específicas del ciclo temporal y materiales;
- capturas visuales automatizadas;
- CI de GitHub Actions.
Si una prueba no puede ejecutarse, marca SKIPPED o NOT TESTED y explica por qué. No ocultes warnings ni errores.

## ENTREGA
- Rama agent/art-pass-cuban-dark-fantasy.
- Commits organizados y árbol limpio.
- PR hacia main, preferiblemente draft hasta revisar capturas.
- Informe con objetivo, archivos, decisiones, assets/licencias, comandos, resultados, capturas y limitaciones.
- No hacer merge automático.
- No iniciar la Fase 2.
- Esperar la aprobación visual del responsable antes de ampliar el mapa o producir más contenido.

## CREDENCIALES
El PAT nuevo solo se introduce en el gestor seguro del entorno/agente. Nunca lo pidas por chat, no lo imprimas, no lo pongas en URL, código, workflow, commit ni artefacto. Si falta credencial, deja rama y bundle listos y reporta el bloqueo sin inventar push.
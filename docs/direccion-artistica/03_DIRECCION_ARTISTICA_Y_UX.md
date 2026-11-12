# Dirección artística y UX — El Eco de Valdeluz

## Objetivo visual

La versión actual de la vertical slice es una prueba funcional. Su interfaz, materiales y bosque no deben considerarse dirección artística aprobada. La siguiente tarea debe producir un **Art Pass** y un **UX Pass** antes de ampliar contenido.

La referencia emocional es un ARPG oscuro de producción alta: composición dramática, siluetas claras, iluminación atmosférica, interfaz sobria y combate legible. No copiar pantallas, iconos, fuentes, mapas ni assets de Diablo III. Crear un lenguaje visual propio: **gótico caribeño de 1953**.

## 1. Paleta y materiales

- Negro carbón: fondos, sombras y marcos.
- Azul petróleo: noche, mar y metal frío.
- Verde manigua: vegetación, musgo y humedad.
- Tierra roja: caminos, barro y suelo cubano.
- Piedra caliza: edificios, ruinas y caminos.
- Ámbar de farol: luz cálida y puntos de interés.
- Rojo carmesí: corrupción, peligro y señales de jefe.
- Oro viejo: títulos, reliquias y recompensas importantes.

Cada superficie debe tener material reconocible: césped con variación de tono, tierra con ruido y huellas, piedra con rugosidad, madera con vetas, metal con desgaste, barro con zonas húmedas. Prohibido resolver el mundo con planos de color plano sin textura o repetición visible.

## 2. Terreno y vegetación

El suelo debe mostrar al menos cuatro biomas materiales por región:
- Césped tropical: variación de verdes, parches secos, hojas, hierba alta en grupos y bordes irregulares.
- Tierra roja: caminos compactados, barro, roderas de carreta, piedras y charcos.
- Piedra caliza: roca clara, grietas, musgo y zonas erosionadas.
- Suelo húmedo: barro oscuro, hojas caídas, raíces y reflejos económicos.

En el bosque inicial:
- Camino principal de tierra que guíe la lectura.
- Césped con densidad variable, no una alfombra uniforme.
- Árboles tropicales, palmas, ceibas y vegetación de sotobosque con siluetas distintas.
- Rocas, raíces, troncos, flores y maleza en grupos naturales.
- Variación de elevación suave y límites físicos invisibles o integrados en el paisaje.
- Elementos grandes en primer plano no deben tapar al jugador; usar fade/occlusion.

**Prueba de aceptación:** una captura a 1280×720 y otra en relación 20:9 deben permitir distinguir claramente césped, tierra, piedra, troncos, personaje y enemigo sin depender de acercar la cámara.

## 3. Cielo, iluminación y ciclo día/noche

Implementar un sistema de tiempo de mundo con ciclo configurable:
- Duración inicial sugerida: 24 minutos reales por día de juego (ajustable).
- Amanecer: 05:30–07:00, niebla baja, luz cálida y sombras largas.
- Día: 07:00–17:00, cielo azul atmosférico, nubes suaves, luz legible y contraste natural.
- Atardecer: 17:00–19:00, ámbar, naranja oscuro y siluetas.
- Noche: 19:00–05:30, azul profundo, luna, estrellas, faroles y fuentes de luz local.
- Tormentas y niebla son eventos climáticos separados del reloj.

Requisitos:
- Cielo visible y horizonte coherente; no dejar el mundo como un vacío negro.
- Sol y luna se desplazan de forma continua.
- Cambiar intensidad, color y dirección de luz con interpolación suave.
- Encender faroles y ventanas al anochecer.
- Ajustar ambient light y niebla sin ocultar el terreno ni el telegráfico de enemigos.
- Las zonas interiores usan iluminación propia y no deben heredar el cielo como fuente dominante.
- El reloj del servidor será autoritativo en multijugador; el cliente solo interpola.
- En perfil Low usar cielo simple, una luz principal, sombras limitadas y pocas luces locales; evitar volumétricos costosos.

**Prueba de aceptación:** capturar la misma zona en amanecer, mediodía, atardecer y noche; se deben reconocer el mismo terreno y sus materiales, pero con atmósfera distinta.

## 4. Clima dinámico

Primera versión: despejado, nublado, lluvia y niebla. Tormenta eléctrica se añade cuando la base esté estable.
- La lluvia afecta partículas, sonido, charcos y visibilidad, no la precisión de combate sin una razón jugable.
- El clima cambia gradualmente y no aparece/desaparece en un frame.
- En Low, reducir partículas y reflejos; conservar audio y lectura del terreno.
- Los eventos narrativos pueden forzar clima, pero el sistema debe devolver el control al ciclo normal.

## 5. Cámara y composición

- Cámara isométrica elevada, con seguimiento suave y zoom limitado.
- Personaje visible en todo momento salvo cinemáticas.
- Evitar que árboles, techos o columnas oculten enemigos.
- En combate, mantener al jugador y los telegráficos dentro del encuadre.
- Zoom automático leve en jefes solo si no perjudica lectura móvil.
- No usar desenfoque de movimiento ni profundidad de campo pesada en perfil Low.

## 6. Rediseño completo de interfaz

La UI actual es provisional. Rediseñar desde cero su composición, jerarquía, espaciado, tipografía y paneles. Inspiración funcional: ARPG oscuro de alta legibilidad, pero con ornamentos originales de hierro forjado, cuero, latón y cartografía cubana.

### HUD de combate
- Barra superior izquierda: retrato/insignia de clase, nivel, HP y recurso.
- Parte superior central: nombre y vida del jefe/enemigo élite cuando corresponda.
- Objetivo de misión: panel compacto a la izquierda, 2–3 líneas máximas.
- Minimapa: esquina superior derecha, marco circular o cuadrado ornamental, con norte, objetivos y leyenda.
- Zona inferior central/derecha: ataque básico, 4 habilidades, esquiva y consumible.
- Joystick a la izquierda, con tamaño y opacidad ajustables.
- Botón de interacción contextual cerca del objetivo, sin tapar controles.
- Indicadores de estado con iconos, nombre accesible y tiempo restante.

### Menús
- Pantalla principal con logo, fondo animado de La Habana/Valdeluz y opciones claras: Continuar, Nueva partida, Personajes, Ajustes, Créditos, Salir.
- Selección de clase con modelo 3D, rol, atributos, dificultad y vídeo/animación corta.
- Inventario con silueta de personaje, slots visibles, comparación de estadísticas y filtros.
- Diario con pestañas: Historia, Secundarias, Encargos, Recuerdos.
- Mapa con regiones descubiertas y puntos de interés; no revelar todo desde inicio.
- Ajustes organizados en Controles, Gráficos, Audio, Accesibilidad y Juego.
- Pausa con Reanudar, Inventario, Misiones, Ajustes y Salir al menú.
- Diálogos con retrato, nombre, subtítulos, opción de velocidad y registro de conversación.

### Lenguaje visual de UI
- Marcos de metal envejecido y cuero; no sobrecargar cada botón.
- Tipografía de títulos gótica legible; cuerpo con sans serif clara.
- Contraste mínimo suficiente para pantallas móviles; no usar oro pálido sobre blanco.
- Estados de botón: normal, hover/focus, pressed, disabled, cooldown.
- Iconos originales con silueta reconocible a 48 px.
- Animaciones de UI cortas y económicas (120–220 ms); nada debe retrasar el control.
- Escalado para 16:9, 20:9, tablets, notch y safe areas.

**Regla:** el HUD se valida con una captura real de gameplay, con enemigos, vegetación y efectos activos. Una pantalla vacía no prueba legibilidad.

## 7. Dirección de arte de personajes

- Siluetas claras desde cámara alta.
- Proporciones estilizadas low-poly, pero materiales PBR sencillos.
- Ropa de época adaptada a combate fantástico: guayaberas, botas, pañuelos, cuero, lona, metal reparado, sombreros y accesorios.
- Animaciones de locomoción, ataque, daño, esquiva, habilidad, muerte e interacción.
- VFX no deben ocultar la silueta ni los telegráficos.
- Los seis modelos comparten escala, rig y presupuesto de animación.

## 8. Audio y música

- Ambientes: grillos, lluvia en zinc, mar, tren, viento en palma, pregones, dominó y campanas.
- Música original con influencias de son, bolero, danzón, rumba y punto guajiro; componer y grabar material propio o con licencia explícita.
- La música no debe ser una colección de clichés: cada región tiene tema y variación día/noche.
- En combate, priorizar señales de ataque y daño por encima de música.
- Subtítulos para señales narrativas importantes.

## 9. Perfiles gráficos

| Sistema | Low | Medium | High |
|---|---|---|---|
| Sombras | solo jugador/enemigos cercanos | distancia media | distancia alta limitada |
| Vegetación | instancias reducidas | densidad media | densidad completa |
| Partículas | mínimo | medio | alto |
| Niebla | simple | volumétrica solo si se mide viable | mejorada |
| Resolución interna | escala adaptativa | 100% objetivo | 100% |
| Luces locales | pocas | moderadas | limitadas por escena |
| Postprocesado | desactivado | mínimo | selectivo |

No cambiar renderer en runtime. El perfil Low debe ser la primera referencia de diseño.

## 10. Capturas y revisión visual obligatorias

Cada PR visual incluye:
1. Gameplay de día.
2. Gameplay de noche.
3. Primer plano de terreno (césped/tierra/piedra).
4. HUD con combate real.
5. Menú principal.
6. Inventario o diario.
7. Captura en relación 20:9.
8. Tabla de comparación antes/después.

La revisión debe responder:
- ¿Se entiende dónde está el jugador?
- ¿Se distingue césped de tierra?
- ¿Hay horizonte/cielo?
- ¿Se entiende qué es interactivo?
- ¿Se leen HP, recurso y objetivo?
- ¿El enemigo y su telegráfico destacan?
- ¿La escena parece parte del mismo juego?

## 11. Orden de implementación recomendado

1. Hacer benchmark visual de materiales y terreno.
2. Construir un pequeño entorno de prueba con césped, tierra roja, piedra y vegetación.
3. Ajustar cámara y cielo.
4. Implementar ciclo día/noche y clima básico.
5. Rediseñar HUD y menús con tema completo.
6. Integrar assets solo después de validar licencia y coherencia.
7. Rehacer el bosque de la vertical slice con la nueva dirección.
8. Ejecutar tests, capturas y pruebas en hardware Android cuando esté disponible.

No ampliar el mapa ni producir decenas de enemigos antes de aprobar el Art Pass.

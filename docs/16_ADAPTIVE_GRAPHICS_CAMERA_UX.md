# 16 — Especificación de gráficos adaptativos, cámara y UX móvil

**Estado:** especificación aprobada para implementación futura. No significa que todo esté implementado.
**Proyecto:** RPG LBA — Las Cenizas de Lythara
**Motor fijado por el proyecto:** Godot 4.7.2 Standard, GDScript, Compatibility Renderer.
**Dispositivos de referencia:** Redmi 9C (mínimo práctico a validar) y Samsung Galaxy S22 Ultra (alto).

## 1. Principio de diseño: una sola experiencia, calidad escalable

Todos los dispositivos deben ejecutar el mismo juego: mismos mapas, geometría lógica, personajes, hitboxes, físicas, enemigos, misiones, inventario, progresión, reglas de combate y multijugador. Solo se degradan o mejoran parámetros de presentación y carga visual.

Queda prohibido:
- crear una edición de juego distinta para gama baja;
- quitar enemigos, misiones, objetos, interacciones o mecánicas según el móvil;
- alterar daño, velocidad, alcance, colisiones o dificultad según el perfil gráfico;
- ocultar contenido interactivo necesario para completar una misión por usar Low.

Sí se permite adaptar: resolución interna, distancia de dibujado, densidad de elementos decorativos, LOD, sombras, partículas cosméticas, niebla, antialiasing, filtros y frecuencia de efectos ambientales.

## 2. Dispositivos y objetivos de rendimiento

| Perfil | Referencia | Objetivo de diseño | Condición |
|---|---|---:|---|
| Low | Redmi 9C, incluidas variantes de RAM | 30 FPS objetivo | Debe medirse en el dispositivo físico; no prometer estabilidad sin prueba sostenida |
| Medium | Android intermedio | 30–45 FPS objetivo | Elegido por benchmark, no solo por modelo |
| High | Galaxy S22 Ultra y gama alta equivalente | 60 FPS objetivo | Máxima calidad compatible con temperatura y estabilidad |

El Redmi 9C tiene variantes de memoria y configuraciones regionales. La detección no debe basarse únicamente en el nombre comercial. Registrar RAM disponible, renderer/GPU cuando sea accesible, resolución, frame time y memoria. Si una señal no está disponible, usar un valor seguro y permitir selección manual.

**Regla térmica:** priorizar estabilidad sostenida sobre un pico breve de FPS. Si el teléfono se calienta o el frame time empeora durante una ventana sostenida, bajar gradualmente efectos y escala; usar histéresis para evitar saltos constantes. No depender de APIs térmicas no disponibles en todos los Android.

## 3. Perfiles visuales de partida

La configuración existente `config/quality_profiles.json` es la referencia inicial y debe auditarse antes de tocarla. Sus números son valores de arranque, no resultados medidos.

### Low — Redmi 9C
- Escala de render inicial orientativa: 0.70.
- Sombras dinámicas desactivadas.
- Hasta 40 partículas cosméticas visibles.
- Densidad de vegetación orientativa: 0.45.
- Distancia visual orientativa: 0.65.
- Postprocesado desactivado.
- Niebla económica por distancia/color, sin volumétricos.
- LOD agresivo y culling por distancia/frustum.
- Materiales compartidos, atlas y texturas pequeñas.
- Limitar luces dinámicas y elementos transparentes superpuestos.

### Medium
- Escala inicial orientativa: 0.85.
- Sombras de una luz direccional solo si benchmark lo permite.
- Hasta 80 partículas cosméticas.
- Vegetación 0.75 y distancia 0.85 como punto de partida.
- Postprocesado mínimo y selectivo.

### High — S22 Ultra
- Escala inicial orientativa: 1.0.
- Hasta 140 partículas cosméticas como punto de partida.
- Vegetación y distancia completas.
- Sombras de calidad controlada.
- Niebla, clima, iluminación ambiental, efectos y filtros selectivos.
- Mayor resolución de texturas donde aporte diferencia visible.

**Importante:** Compatibility Renderer no equivale a Forward+/Mobile con todas las funciones avanzadas. No activar volumetric fog, GI dinámica, SSR, reflejos costosos ni shaders incompatibles. La calidad alta debe aprovechar composición, materiales, sombras económicas, partículas y niebla compatible; no convertir el proyecto a otro renderer sin ADR, matriz de compatibilidad y pruebas Android.

## 4. Sistema de selección y ajuste

Implementar un servicio central (nombre a decidir tras inspeccionar el código, por ejemplo `GraphicsQualityService`) con responsabilidades separadas:
1. Detectar capacidades al primer arranque.
2. Elegir Low/Medium/High como sugerencia.
3. Permitir cambio manual persistente.
4. Aplicar ajustes sin reiniciar cuando sea seguro; reiniciar solo si una opción lo exige y explicarlo.
5. Medir frame time y memoria durante juego real.
6. Aplicar ajustes adaptativos pequeños y con histéresis, sin cambiar reglas de juego.
7. Registrar perfil, versión del juego, resolución y métricas para pruebas; no recopilar identificadores personales.

Prioridad de selección:
- preferencia manual del jugador;
- si no existe, perfil detectado por benchmark/capacidades;
- fallback conservador Low si faltan datos.

No confiar en una tabla rígida de modelos como única fuente. Permitir que un teléfono moderno seleccione Medium si está caliente o que un teléfono antiguo use un perfil distinto si sus capacidades lo justifican.

## 5. Cámara y perspectiva

Conservar la cámara isométrica 3D ya existente y sus mejoras de oclusión. No reemplazarla por cámara libre ni cambiar el lenguaje visual sin aprobación.

Comportamiento esperado:
- cámara elevada y ortográfica/isométrica, con personaje y contexto de combate legibles;
- seguimiento suave y estable, sin vibración;
- mantener al jugador visible y no ocultar enemigos/telegráficos;
- oclusión reversible con histéresis; evitar parpadeos al cruzar puertas/árboles;
- zoom táctil opcional por gesto pinch, con límites y valor predeterminado consistente;
- rotación desactivada por defecto; solo añadirla si mejora navegación y se prueba en móvil;
- ajustar encuadre para landscape, notch, barras de sistema y relaciones 16:9 / 20:9;
- Low puede reducir distancia y densidad decorativa, pero no cambiar la orientación ni el encuadre de combate de forma que altere la jugabilidad.

## 6. Controles táctiles y HUD

Mantener controles ARPG:
- joystick virtual abajo a la izquierda;
- ataque básico como acción principal abajo a la derecha;
- habilidades, esquiva y poción en arco o agrupación clara;
- interacción contextual cuando el jugador esté cerca de un objeto/NPC;
- minimapa, vida/recurso, objetivo y misión sin tapar el centro de acción.

Requisitos de experiencia:
- botones táctiles generosos, con separación suficiente para evitar pulsaciones accidentales;
- multitouch real: mover y atacar simultáneamente, soltar un dedo sin cancelar otro;
- joystick con zona muerta, respuesta analógica, arrastre fuera del área y posición configurable;
- áreas seguras Android, notch y navegación del sistema respetados;
- tamaño, opacidad, posición y sensibilidad configurables;
- feedback visual/sonoro de pulsación, cooldown, acción no disponible y objetivo;
- textos legibles, contraste suficiente y opción de reducir movimiento/VFX;
- inventario, mapa, habilidades, misiones y ajustes con navegación táctil consistente;
- no usar texto diminuto ni depender de hover/ratón.

La UI debe ser 2D y anclada a viewport/safe areas. No construir menús como escenas 3D ni recalcular todo el HUD cada frame. Mantener el mismo orden y semántica de controles en todos los perfiles.

## 7. Experiencia del jugador: flujo mínimo

1. Arranque breve y presentación saltable.
2. Menú principal y selección Solo / Multijugador LAN.
3. Crear o continuar personaje.
4. Entrar a Valdeluz con controles visibles y tutorial contextual.
5. Aprender mover, atacar, esquivar, interactuar y abrir inventario sin ventanas que bloqueen el juego.
6. Recibir feedback claro al completar objetivos, obtener objetos o subir de nivel.
7. Pausar y cambiar gráficos/controles sin perder progreso.
8. Volver a la partida con la misma configuración y estado guardado.

No introducir tutoriales intrusivos repetidos. Guardar qué consejos ya se mostraron.

## 8. Arquitectura de implementación

- Separar lógica de gameplay, UI, cámara y render quality.
- Los perfiles deben ser datos validados, no condicionales dispersos por escenas.
- Exponer interfaces para vegetación/LOD/partículas/niebla y aplicar cambios en lotes.
- Mantener IDs y escenas lógicas compartidas.
- No duplicar escenas completas por perfil.
- No cambiar física, colisiones ni autoridad de red por calidad gráfica.
- No tocar renderer, plugins, versión Godot ni formato de guardado sin ADR y migración.

## 9. Pruebas y evidencia obligatorias

Automatizadas:
- lectura/validación de perfiles y valores fuera de rango;
- perfil Low nunca activa funciones incompatibles/costosas prohibidas;
- cambiar perfil no modifica atributos, daño, hitboxes, misiones ni estado de red;
- persistencia de preferencias;
- escalado UI para 16:9, 20:9 y resoluciones pequeñas;
- joystick multitouch, cancelación y liberación independiente;
- cámara, oclusión y zoom con límites;
- regresión de escenas, combate y lobby.

Hardware:
- Redmi 9C: identificar variante RAM, Android, resolución, duración, FPS/frame time, memoria y temperatura observada;
- Galaxy S22 Ultra: misma matriz, High y Medium;
- prueba mínima sostenida de 15 minutos por perfil, más recorrido de combate y zona poblada;
- capturas reales 16:9 y 20:9; revisión visual humana;
- registrar caídas, calentamiento, tirones, batería y fallos.

Estados permitidos: PASS, FAIL, SKIPPED, NOT TESTED. CI headless no demuestra FPS ni compatibilidad física.

## 10. Definition of Done

- La misma sesión/partida se comporta igual en Low y High.
- Cambiar calidad no altera gameplay ni red.
- Controles utilizables con multitouch físico.
- Cámara legible, estable y sin oclusiones críticas.
- Los perfiles se aplican y persisten.
- Suite completa y CI verde.
- Prueba física Redmi 9C y S22 Ultra registrada; no afirmar soporte del Redmi antes de probar.
- Capturas revisadas por el propietario.
- Informe y PR independientes; no merge automático.

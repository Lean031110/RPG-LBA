# 07 — UX, menús y controles móviles

## Flujo de inicio

1. Pantalla de arranque breve: “LBA Studio presenta”.
2. Logo/título: “RPG LBA — Las Cenizas de Lythara”.
3. Créditos de tecnología y colaboradores reales, solo nombres verificados.
4. Menú principal.
5. Selección de modo: Solo / Multijugador LAN / Online (online se muestra deshabilitado hasta desplegar servicio real).
6. Selección de mundo/realm disponible.
7. Selector/creación de personaje.
8. Confirmación de región y entrada al juego.

No inventar compañías colaboradoras ni logos de terceros. La intro puede saltarse y recordar preferencia.

## Menú principal

- Continuar (si existe personaje local).
- Jugar solo.
- Multijugador local.
- Online (deshabilitado mientras no haya backend público).
- Ajustes.
- Créditos.
- Salir.

## Creación de personaje

- Nombre único por mundo, filtro de nombres y longitud 3–16 caracteres.
- Seleccionar clase.
- Seleccionar cuerpo/preset, rostro, cabello, color de cabello, tono de piel y accesorio inicial según assets disponibles.
- Preview 3D con giro y pose idle.
- Selección de aspecto no debe cambiar hitbox ni atributos.
- Clase no se cambia libremente tras confirmar; permitir borrar/crear personaje y más adelante un sistema controlado de cambio.

## HUD de combate

- Arriba izquierda: retrato, vida y recurso.
- Arriba centro: objetivo/boss bar cuando corresponda.
- Arriba derecha: minimapa, brújula, menú.
- Abajo izquierda: joystick virtual.
- Abajo derecha: ataque básico grande, 3–4 habilidades, esquiva, poción y botón interactuar contextual.
- Centro/parte superior: alertas de objetivo y loot sin tapar personaje.
- Barra de vida de objetivo opcional al fijar target.

## Inventario y personaje

- Inventario grid con filtros (todo, equipo, materiales, consumibles, quest).
- Panel personaje con slots y estadísticas básicas.
- Comparación de objeto equipado vs seleccionado.
- Acciones: equipar, usar, dividir stack, descartar con confirmación, bloquear/favorito.
- No permitir descartar objetos de misión ni eliminar sin confirmación.

## Menús adicionales

- Misiones: principales, secundarias, completadas; tracking de una principal y hasta dos secundarias.
- Mapa: mundo/zonas, puntos descubiertos, party y objetivos.
- Habilidades: árbol por clase, descripción, costo, cooldown y previsualización.
- Grupo: miembros, invitaciones, líder, distancia, estado.
- Guild: miembros, rangos, invitaciones, descripción, lista; fase posterior al party.
- Comercio: doble ventana, ambos lados confirman, muestra resultado final y espera un segundo confirmatorio.
- Comerciante: comprar/vender, filtro, precio y capacidad.
- Herrero: fabricar, mejorar, reparar/desguazar.
- Almacén: depositar/retirar con validación de servidor.
- Ajustes: idioma, gráficos, audio, controles, cámara/UI, accesibilidad, privacidad.
- Créditos: assets, plugins, fuentes, música y colaboradores.

## Idiomas

- Español como idioma inicial.
- Inglés preparado como segundo catálogo, pero no marcar “completo” hasta traducir todos los strings.
- IDs semánticos, no texto visible hardcodeado en scripts.

## Audio

Buses: Master, Music, SFX, UI, Voice.
- Música ambiente por región, loop sin cortes audibles.
- Música dinámica o capa de jefe como etapa posterior.
- Sonido por clase: impacto, casteo, cooldown listo, interacción.
- Reforzar telegráficos con audio, pero no depender exclusivamente de él.
- Controles separados de volumen y mute.

## Usabilidad

- Todos los botones críticos con área táctil generosa.
- No colocar acciones bajo notch, cámara o zona del sistema Android.
- Escalado UI con safe areas.
- Reducir movimiento y VFX.
- Objetivos y estados con icono + texto o forma, no solo color.
- Evitar ventanas pequeñas que requieran precisión de mouse.

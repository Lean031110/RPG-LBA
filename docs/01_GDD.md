# 01 — Game Design Document (GDD)

## 1. Visión general

**RPG LBA: Las Cenizas de Lythara** es un action RPG 3D de fantasía medieval. La cámara se mantiene elevada, con ángulo isométrico legible y control táctil de doble zona: joystick virtual a la izquierda y ataques/habilidades/consumibles a la derecha. El jugador explora regiones conectadas, combate enemigos, completa historias, consigue equipo y se une a grupos para superar mazmorras con jefes.

El tono combina aventura, misterio y fantasía oscura moderada. La dirección visual será estilizada low-poly con siluetas limpias, superficies suaves, paleta coherente y efectos mágicos de alto contraste. El juego no debe imitar literalmente la interfaz, arte, iconos, historia o personajes de títulos existentes.

## 2. Bucle principal

1. Seleccionar personaje y mundo.
2. Aparecer en ciudad o último punto seguro.
3. Leer objetivo, aceptar misión o preparar equipo.
4. Viajar a una región de caza/exploración.
5. Explorar, combatir, recolectar y descubrir eventos.
6. Recibir experiencia, oro, materiales y botín.
7. Volver a ciudad, vender, reparar, fabricar o mejorar equipo.
8. Desbloquear región/mazmorra y mejorar build.
9. Repetir con enemigos y retos de mayor nivel.

Cada expedición debe tener una duración útil de 10–25 minutos. La misión secundaria puede resolverse en 3–10 minutos.

## 3. Cámara y lectura

- Cámara 3D elevada fija, cercana a isométrica; rotación no necesaria en primera versión.
- Cámara ortográfica como primera implementación para lectura consistente; evaluar perspectiva débil solo si las pruebas visuales demuestran una mejora clara.
- Ángulo inicial a probar: 50–58° desde el plano horizontal; altura/ortho-size configurable por zona.
- El personaje controlado permanece cerca del centro, con desplazamiento suave y límites para no ocultarlo.
- Ocultar/atenuar elementos que tapen al personaje (árboles, techos) con material de transparencia gradual o hide-on-occlusion sencillo.
- Enemigos y telegráficos nunca deben quedar ocultos por efectos.

## 4. Estructura del mundo

El mundo se organiza en un realm con regiones conectadas. Cada región se divide internamente en sectores de streaming y puntos de interés. No se carga el mundo completo en memoria.

- Ciudad segura: servicios, comerciantes, herrero, alquimista, maestro de clase, almacén, tablón y portal.
- Regiones exteriores: caza, recolección, eventos y entradas a mazmorras.
- Mazmorras: instancias privadas o de grupo, generación determinista por semilla.
- Zonas de jefe: arenas con fases, telegráficos y condiciones de victoria.

## 5. Modos de juego

### Solitario

Una partida local con guardado propio. La lógica y los sistemas de personaje son los mismos que en online, con autoridad local. Los datos del modo solitario no se mezclan con personajes online.

### Multijugador LAN

Se elige un mundo local y se conecta al servidor dedicado en la red. El servidor puede estar en la PC del jugador, pero ejecuta como proceso headless y no es un cliente que tenga privilegios especiales.

### Online

Selección de región/realm, lista de mundos, personaje y zona. Se habilita cuando exista servidor público desplegado, matchmaking/lobby, autentificación y reglas de protección de datos.

## 6. Sesión y jugadores

- Grupo: 4 jugadores.
- Zona: comenzar con 4 conectados probados; objetivo de 10 por instancia tras benchmark.
- Guild: objetivo inicial 20 miembros.
- El diseño de datos admite más capacidad, pero no se subirá el límite sin pruebas de latencia, CPU, memoria y ancho de banda.
- Recompensas de grupo: experiencia compartida dentro de radio; loot personal instanciado para evitar disputa en el MVP.

## 7. Progreso

- Nivel 1–30 para el primer arco de contenido.
- El jugador gana XP por misiones, enemigos, exploración y mazmorras.
- Cada nivel entrega puntos de habilidad o mejora predefinida según el sistema de progresión aprobado.
- Desbloqueos de habilidades por niveles; especializaciones por ramas.
- No hacer que la mejora de poder dependa solo de grind repetitivo; cada tramo debe desbloquear una herramienta o decisión jugable.
- La dificultad de enemigos se define por zona y rango de nivel. No escalar automáticamente todos los enemigos al nivel del jugador: mantener zonas de inicio reconocibles y riesgo por región.

## 8. Equipo y objetos

Slots: arma principal, mano secundaria/escudo/catalizador, cabeza, torso, manos, piernas, pies, amuleto y dos anillos. La disponibilidad de off-hand depende de clase.

Rarezas: común, poco común, raro, épico, legendario. La rareza añade afijos y una propiedad distintiva; no solo incrementa números sin límite.

Objetos:
- armas, armaduras, consumibles, materiales, recetas, llaves, objetos de misión y cosméticos.
- Equipo con nivel requerido y clase/slot cuando corresponda.
- Durabilidad y reparación solo si no crea fricción innecesaria; se puede dejar para fase posterior.
- Botín personal para grupo, con tabla determinista por enemigo/encuentro y semilla del servidor.

## 9. Economía

- Moneda: Plata de Lythara.
- Comerciantes: compra/venta de consumibles y materiales comunes.
- Herrero: reparación (si se activa), fabricación y mejora controlada.
- Alquimista: pociones y consumibles.
- Desguace: convertir equipo sobrante en materiales.
- Almacén: inventario compartido por cuenta/realm sujeto a reglas de seguridad.
- Mercado entre jugadores: fase posterior, no en MVP.
- Trade directo: ventana doble, revisión final y confirmación bilateral; el servidor valida propiedad y cantidades de forma atómica.

## 10. Descubrimiento y mundo

- Hitos de exploración en cada región: puntos panorámicos, santuarios, cofres ocultos y mini-jefes.
- Eventos de zona: caravanas atacadas, portales inestables, campamentos enemigos.
- Recolección de hierbas, mineral y madera en puntos limitados y visibles.
- Los recursos reaparecen por temporizador de servidor, no por reloj del cliente.

## 11. Fin de juego del primer arco

- Mazmorras en dificultad normal y desafiante.
- Jefes con 2–3 fases y señales visuales/sonoras.
- Caza de élites y eventos de región.
- Equipamiento épico y legendario con builds alternativas.
- El contenido final inicial debe durar varias sesiones, pero no debe intentar competir con un MMO comercial completo.

## 12. Accesibilidad y experiencia móvil

- Escalado de UI para pantallas 16:9, 20:9, tablets y notch/safe areas.
- Botones reubicables y opción de cambiar tamaño/opacidad.
- Vibración configurable, subtítulos, volumen separado, texto legible, daltonismo no dependiente solo del color.
- Auto-target opcional y modo apuntado manual simplificado.
- Opción para reducir partículas y sacudida de cámara.
- Controles táctiles y gamepad Bluetooth opcional; no depender de teclado/ratón.

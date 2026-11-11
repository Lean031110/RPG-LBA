# 00 — Brief maestro del producto

## Identidad

- **Nombre:** RPG LBA
- **Subtítulo de campaña:** Las Cenizas de Lythara
- **Género:** action RPG 3D, fantasía medieval, cámara elevada/isométrica, exploración por zonas, botín, misiones y cooperación online.
- **Plataforma inicial:** Android ARM64.
- **Idioma inicial:** español; sistema preparado para inglés.
- **Modelo comercial:** no definir monetización durante el MVP. No pay-to-win.
- **Audiencia:** jugadores móviles que disfrutan explorar, conseguir equipo, aprender builds y jugar en grupo.

## Promesa del juego

“Explora un mundo medieval fracturado, domina una clase, consigue equipo, descubre mazmorras que cambian en cada incursión y derrota en grupo a las criaturas que nacen de la Herida de Ceniza”.

## Pilares de diseño

1. **Combate legible y satisfactorio:** telegráficos visibles, animaciones con anticipación, impacto, respuesta y lectura de peligros incluso en pantalla pequeña.
2. **Progreso comprensible:** cada sesión aporta experiencia, materiales, oro, equipo o avance de misión.
3. **Mundo con propósito:** cada zona tiene identidad, recursos, enemigos, secretos y razón para volver.
4. **Cooperación sencilla:** formar grupo, invitar, revivir, compartir objetivos y entrar a mazmorras sin menús interminables.
5. **Accesible en móviles modestos:** 30 FPS como objetivo de perfil bajo sujeto a pruebas físicas; calidad escalable.
6. **Integridad del mundo:** el servidor valida todo lo que afecta a otros jugadores o a la economía.

## Alcance inicial de contenido

- 6 clases originales de fantasía.
- Nivel inicial 1–30 para el primer arco completo.
- 1 ciudad central segura.
- 5 regiones exteriores conectadas por salidas/portales/caminos.
- 3 mazmorras con generación procedural por salas y semilla determinista.
- 5 misiones principales.
- 8 misiones secundarias iniciales (ampliables por cadenas).
- 5 jefes principales y varios enemigos élite.
- Grupo de 4 jugadores.
- Guilds/clanes iniciales de hasta 20 miembros como objetivo de diseño, sujeto a validación de servidor.
- Zona inicial: 4 jugadores probados; 10 jugadores objetivo de instancia solo tras pruebas. La plantilla base anuncia soporte hasta 10, pero RPG LBA deberá medirlo otra vez.

## Modos

1. **Historia en solitario:** mundo local y guardado local; utiliza las mismas reglas de gameplay con autoridad local/offline.
2. **Multijugador LAN:** clientes Android/PC conectan a un servidor dedicado ejecutado en la PC del usuario o en una máquina de la misma red. No se usa “host jugador” como autoridad de producción.
3. **Online:** clientes conectan a servidores dedicados alojados externamente. Esta opción se habilita cuando exista infraestructura, cuentas, protección y operación real; no fingir que GitHub Actions es el servidor online.

## Decisión de multijugador

Se elige **servidor dedicado autoritativo**, no P2P/player-host. Ventajas: inventarios, daño, moneda y drops no dependen del teléfono del anfitrión; desconectar al anfitrión no destruye el mundo; se puede ejecutar headless en una PC; permite varias instancias/mundos y evolucionar a PostgreSQL. Coste: requiere una máquina servidor y diseño de persistencia. Para LAN, esa máquina puede ser la PC del usuario. Para jugar por Internet se necesitará alojamiento y disponibilidad pública.

## Reglas de diseño

- El mundo será grande por la suma de regiones, no un único mapa cargado de una vez.
- Las mazmorras se generan desde salas y módulos validados, no con aleatoriedad sin restricciones.
- Los jugadores pueden comerciar, pero cada transacción requiere confirmación de ambos lados y validación del servidor.
- Las zonas iniciales son PvE. PvP consensuado puede evaluarse después; no forma parte del MVP.
- No incluir chat de voz en MVP. Chat de texto con controles de spam y bloqueo será posterior a la infraestructura de seguridad.
- No incluir NFT, blockchain, gacha de pago ni marketplace con dinero real.

## Público y hardware

Objetivo mínimo de desarrollo: Android que cumpla OpenGL ES 3.0 para Compatibility Renderer, memoria y CPU suficientes. Redmi 9C es dispositivo de referencia, no garantía: hay variantes de RAM y el comportamiento depende del driver, versión Android y temperatura. La documentación de Godot 4.7 lista OpenGL ES 3.0 para Compatibility en móvil; verificar en hardware real.

## No objetivos iniciales

- MMO masivo de cientos/miles de jugadores por zona.
- PvP abierto con loot completo.
- Monturas, mascotas complejas, housing, raids de 20 jugadores.
- Mercado global, correo interno, subastas y temporada competitiva.
- Mundo seamless de escala planetaria.
- Fotorealismo o assets de alta densidad.

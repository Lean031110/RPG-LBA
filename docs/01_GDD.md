# 01 — Game Design Document (GDD)

> **Actualización de canon 2026-11-12:** La identidad creativa vigente es RPG LBA — Las Cenizas de Lythara; la primera campaña se titula *El Eco de Valdeluz* y ocurre en una Cuba ficticia de 1953, reinterpretada como fantasía oscura caribeña. Esta definición supersede la descripción genérica de fantasía medieval de versiones anteriores. La biblia narrativa, las misiones, las clases y la dirección artística enlazadas abajo son las fuentes específicas de contenido.
>
> - Narrativa: [Biblia del mundo](narrativa/00_BIBLIA_DEL_MUNDO_Y_HISTORIA.md) y [misiones](narrativa/01_MISIONES_Y_CADENAS.md).
> - Clases: [atributos y habilidades](diseno/02_CLASES_ATRIBUTOS_HABILIDADES.md).
> - Arte y UX: [dirección artística](direccion-artistica/03_DIRECCION_ARTISTICA_Y_UX.md).
> - Ejecución de agentes: [briefing](AGENT_BRIEFING_VISION_CUBANA.md).

## 1. Visión general

**RPG LBA: Las Cenizas de Lythara** es un action RPG 3D de fantasía oscura caribeña. Su primera campaña, **El Eco de Valdeluz**, transcurre en una Cuba ficticia de 1953: pueblos de interior, La Habana, fortalezas, centrales azucareros, mogotes, montañas, ciénagas y una dimensión sobrenatural llamada La Otra Orilla. El juego combina combate de acción isométrico, seis clases con habilidades propias, exploración por regiones, misiones cinematográficas y multijugador planificado con servidor dedicado autoritativo.

La identidad visual es gótico caribeño: arquitectura colonial y art déco, vegetación tropical, césped, tierra roja, piedra caliza, metal envejecido, faroles, radios, trenes y clima dramático. La interfaz debe ser oscura y sobria, pero de lectura inmediata en móvil. No copiar recursos ni UI de juegos existentes.

## 2. Bucle principal

1. Seleccionar personaje y clase.
2. Aparecer en Valdeluz, La Habana o último punto seguro.
3. Consultar diario, hablar con personajes y preparar equipo.
4. Viajar a una región de exploración.
5. Explorar, combatir, investigar, recolectar y descubrir eventos.
6. Completar objetivos, recuperar recuerdos y conseguir experiencia, equipo y materiales.
7. Volver a un refugio, comerciar, fabricar, curar y mejorar habilidades.
8. Desbloquear regiones, mazmorras y capítulos de la campaña.
9. Repetir con encuentros más complejos, decisiones y jefes.

Cada expedición debe tener duración útil de 10–25 minutos. Las misiones secundarias suelen durar 3–10 minutos, con cadenas narrativas más largas.

## 3. Cámara y lectura

- Cámara 3D elevada, cercana a isométrica; rotación no necesaria en primera versión.
- Cámara ortográfica como primera implementación; evaluar perspectiva débil solo si las pruebas visuales demuestran mejora.
- Ángulo inicial a probar: 50–58° desde el plano horizontal; altura/ortho-size configurable por zona.
- Personaje controlado cerca del centro, con seguimiento suave.
- Ocultar/atenuar elementos que tapen al personaje.
- Enemigos y telegráficos nunca deben quedar ocultos por vegetación o efectos.

## 4. Estructura del mundo

El mundo se organiza por regiones cubanas ficticias o inspiradas en geografía real, con sectores de streaming y puntos de interés. No cargar el mundo completo al mismo tiempo. La región inicial es Valdeluz; las zonas principales se detallan en la biblia narrativa.

- Ciudad/refugio: servicios, comerciantes, herrero, médico, almacén y tablón.
- Regiones exteriores: combate, exploración, eventos y recolección.
- Mazmorras: instancias de grupo o solitario con semilla determinista.
- Jefes: arenas con fases, telegráficos y condiciones de victoria.

## 5. Modos de juego

### Solitario
Partida local con guardado propio. La lógica de personaje y combate se diseña para que pueda validarse luego en servidor; el modo offline no comparte datos con online.

### Multijugador LAN
Cliente conectado a servidor dedicado local, proceso headless sin privilegios especiales de cliente.

### Online
Se habilita cuando existan servidor público, autenticación, matchmaking/lobby y reglas de protección de datos.

## 6. Sesión y jugadores

- Grupo: 4 jugadores como objetivo inicial.
- Zona: probar 4 conectados antes de elevar límites; el objetivo de 10 por instancia requiere benchmark real.
- Guild: objetivo posterior de 20 miembros.
- Loot personal instanciado en grupo para evitar disputa en MVP.

## 7. Progreso

- Nivel 1–30 para el primer arco.
- XP por misiones, enemigos, exploración y mazmorras.
- Desbloqueos de habilidades y especializaciones a niveles definidos.
- La progresión debe desbloquear decisiones jugables y no depender solo de grind.
- Las zonas mantienen rangos de nivel propios; no escalar todo automáticamente al jugador.

## 8. Equipo y objetos

Slots: arma principal, mano secundaria/escudo/catalizador, cabeza, torso, manos, piernas, pies, amuleto y dos anillos. Off-hand depende de clase. Rarezas: común, poco común, raro, épico y legendario. Los afijos deben crear decisiones y no solo inflación de números.

Objetos: armas, armaduras, consumibles, materiales, recetas, llaves, objetos de misión y cosméticos. Loot de grupo personal, validado por servidor futuro.

## 9. Economía

Moneda inicial de diseño: **Reales de Plata** (nombre de lore sujeto a revisión). Comerciantes, herrero, médico/alquimista, almacén y fabricación. Mercado y trade entre jugadores quedan para fase posterior con transacciones atómicas y validación autoritativa.

## 10. Descubrimiento y mundo

Hitos de exploración, puntos panorámicos, santuarios ficticios, cofres, mini-jefes, caravanas, trenes, eventos de región y recolección de hierbas/mineral/madera. Respawn y clima deben ser autoridad del servidor en multijugador.

## 11. Fin de juego del primer arco

Mazmorras en dificultades normal/desafiante, jefes de 2–3 fases, eventos de región y equipo épico/legendario. El contenido inicial debe ser finito y sostenible; no intentar simular un MMO comercial completo desde el MVP.

## 12. Accesibilidad y experiencia móvil

Escalado 16:9, 20:9, tablets y safe areas; botones reubicables; vibración y subtítulos configurables; tipografía legible; estados no dependientes solo del color; auto-target opcional; reducción de partículas y sacudida; gamepad opcional. El HUD se define en la dirección artística.

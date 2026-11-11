# 04 — Mundo, regiones, mazmorras y jefes

## 1. Mapa macro de Lythara

El mundo se percibe grande mediante regiones conectadas, rutas, portales y puntos de interés. No es un único mapa infinito cargado simultáneamente.

### Región 0 — Valdeluz (ciudad segura)

Servicios: alcalde/capitana, herrero, alquimista, comerciante general, almacén, tablón de misiones, entrenador, portal, posada, estación de grupo y tablón de guild. No aparecen enemigos en ciudad. Aquí se enseña economía y preparación.

### Región 1 — Bosque de Brumaclara (niveles 1–7)

Bosque luminoso con niebla suave, ruinas y caminos. Enemigos: lobos cenicientos, bandidos, brotes corrompidos, tiradores cultistas. Recursos: madera, hierbas, cuero. POI: torre caída, santuario de raíces y guarida de Fenris.

### Región 2 — Minas de Ghar (niveles 8–12)

Complejo minero conectado a una entrada exterior y a mazmorra. Enemigos: mineros poseídos, autómatas, murciélagos de polvo, guardias del culto. Recursos: hierro, cobre, fragmentos de cristal. POI: elevador, forja vieja, galerías colapsadas.

### Región 3 — Marjal Cenizal (niveles 10–16)

Pantano de agua baja, árboles torcidos, setas luminosas. Enemigos: sapos tóxicos, ahogados, brujas del fango. Recursos: plantas, resina y veneno. POI: altar sumergido y cabaña del herbolario.

### Región 4 — Costa Quebrada (niveles 13–18)

Acantilados, playas, barcos varados y cuevas marinas. Enemigos: saqueadores, cangrejos de sal, sirvientes de marea. Recursos: sal, coral y restos navales. POI: faro apagado y entrada al Archivo Sumergido.

### Región 5 — Sierra de los Colosos (niveles 18–24)

Montañas, puentes antiguos, nieve ligera y canteras. Enemigos: gólems menores, cultistas, bestias de roca. Recursos: mineral raro y piedra estelar. POI: observatorio y santuario de campana.

### Región 6 — Bastión del Umbral (niveles 24–30)

Fortaleza exterior del culto, patios, catacumbas y brecha. Región de campaña final y jefe. Enemigos de alto riesgo. Entrada controlada por progreso de historia.

## 2. Mazmorras iniciales

### D1 — Galerías de Ghar

3–5 salas por run. Salas posibles: cámara de herramientas, vagonetas, puente roto, sala de válvulas, cámara de forja. Mini-evento: reactivar ventilación antes de que suba la corrupción. Jefe: Yunque Hueco, 2 fases.

### D2 — Archivo Sumergido

4–6 salas. Salas posibles: biblioteca inundada, pasarela de coral, cámara de campanas, sala de espejos, altar. Peligros: corrientes, zonas de agua, proyectiles. Jefa: Nerissa, 3 fases ligeras.

### D3 — Catacumbas del Umbral

5–7 salas. Salas posibles: osario, corredor de estatuas, prisión, sala de sellos, cripta y arena final. Jefe: Vigía Carmesí, 3 fases.

## 3. Generación procedural determinista

Generar una semilla del servidor al crear la instancia. A partir de ella:
- elegir un grafo de salas con entrada/salida conectadas;
- validar rutas navegables;
- insertar una sala de combate, una de evento, una de recompensa y la arena del jefe;
- colocar puertas/llaves solo cuando la ruta sea resoluble;
- seleccionar variantes de enemigos por nivel y tamaño de grupo;
- elegir cofres y secretos dentro de límites;
- persistir semilla y tabla de recompensas de la run.

No generar geometría arbitraria en tiempo real como primer método. Usar módulos artísticos preconstruidos con puntos de conexión y reglas de compatibilidad. La aleatoriedad debe variar composición, no romper jugabilidad.

## 4. Jefes

1. **Fenris, Alfa Cenizo:** embestida, salto a objetivo y llamada de dos lobos. Enseña lectura de ataque.
2. **Madre Musgosa:** raíz en cono, zonas de espora y escudo ligado a tótems. Grupo destruye tótems.
3. **Yunque Hueco:** golpe de martillo, líneas de lava fría, invoca autómatas; las válvulas alteran arena.
4. **Nerissa, Voz de la Marea:** proyectiles, oleadas que cubren zonas y eco duplicado; grupo se mueve entre refugios.
5. **Vigía Carmesí:** guardia frontal, marcas en suelo, pilares de sello y fase de ruptura; castiga quedarse quieto.

## 5. Eventos de mundo

- Caravana detenida: escolta breve, olas de enemigos.
- Portal inestable: cerrar tres anclas y derrotar élite.
- Campamento del culto: destruir suministros y liberar prisioneros.
- Recurso raro: punto de recolección protegido por guardián.

## 6. Viaje y navegación

- Mapa global con regiones descubiertas.
- Mini-mapa local con objetivos, NPC importantes y miembros de grupo.
- Puntos de viaje desbloqueables; no teletransporte libre desde cualquier lugar a todos los puntos.
- Zonas cambian con una transición corta y una escena de carga; no prometer streaming sin interrupciones hasta validarlo.

## 7. Reutilización visual

Los módulos de aldea, bosque, ruinas, mina, mazmorra y fortaleza deben compartir escala y paleta. El agente debe establecer un kit modular con medidas, pivotes, colisiones y nombres consistentes, usando assets libres verificados.

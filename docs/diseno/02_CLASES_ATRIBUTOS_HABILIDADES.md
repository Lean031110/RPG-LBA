# Clases, atributos, habilidades y balance — RPG LBA

**Canon de diseño revisado:** seis arquetipos originales de ARPG oscuro caribeño. La inspiración es la claridad de roles de los action RPG clásicos; no se copian clases, nombres, habilidades, siluetas ni iconografía de Diablo u otra franquicia. Las seis clases son caminos de combate, no castas ni representaciones de religiones reales.

## Filosofía de balance

- Cada clase debe ser poderosa en su especialidad y tener una debilidad que el jugador pueda gestionar.
- Ninguna clase puede ser la mejor en daño, supervivencia, movilidad y apoyo a la vez.
- El DPS teórico no es el único criterio: control, interrupción, supervivencia, utilidad y facilidad de ejecución cuentan.
- Los números de este documento son **baseline de diseño**, no resultados de balance medidos. Se deben validar con simulaciones y pruebas dentro del juego.
- En solitario todas las clases deben poder completar la campaña. En grupo deben complementarse sin exigir una composición obligatoria.
- No usar escalado automático para borrar diferencias entre clases. Los encuentros deben permitir varias soluciones.

## Atributos comunes

| Atributo | Efecto principal |
|---|---|
| Vida (HP) | Daño que puede recibir el personaje |
| Recurso de clase | Energía propia de cada arquetipo |
| Fuerza | Daño físico pesado, guardia y ruptura |
| Destreza | Precisión, crítico, velocidad y recuperación |
| Intelecto | Potencia arcana, invocaciones y efectos |
| Espíritu | Curación, barreras y resistencia a corrupción |
| Armadura | Mitigación física |
| Resistencia | Mitigación elemental y estados |

El daño final debe calcularse en un único servicio de combate compartido. Las habilidades solo describen potencia, tipo, coste, alcance y modificadores; no duplican fórmulas por clase.

## Las seis clases jugables

### 1. Machetero de la Sierra — El Guardián del Batey
**Fantasía:** combatiente frontal, disciplinado y resistente. Protege a otros y domina el espacio con un machete pesado, escudo improvisado y herramientas de campo.

- **Rol:** tanque / daño cuerpo a cuerpo sostenido.
- **Recurso:** Vigor.
- **Pros:** mucha vida y armadura; interrupciones fiables; protege aliados; excelente contra grupos que se acercan.
- **Contras:** alcance corto; movilidad limitada; sufre contra enemigos voladores y ataques a distancia; consume vigor si bloquea mal.
- **Atributos prioritarios:** Fuerza, luego Espíritu y Destreza.
- **Pasiva — Pulso de monte:** bloquear en el instante correcto recupera vigor y fortalece el siguiente golpe.
- **Pasiva — Pies de piedra:** reduce empujones, pero no inmuniza contra control de jefes.
- **Habilidades:** Tajo de Guásima (arco frontal y sangrado leve); Guardia del Bohío (guardia frontal y protección cercana); Carga del Mambí (embestida que interrumpe); Corte de la Ceiba (golpe lento que rompe armadura).
- **Definitiva — Huracán de Machetes:** secuencia circular de golpes con breve avance y final de ruptura.
- **Especializaciones:** Guardián del Batey (mitigación y protección) / Hoja de la Sierra (ruptura y contraataques).
- **Estilo de juego:** anticipar, bloquear y castigar; no quedarse quieto recibiendo daño.

### 2. Bruja de la Manigua — La Tejedora de Tormentas
**Fantasía:** hechicera de control que manipula raíces, viento, lluvia y energía de la manigua. Su magia es ficticia y no representa prácticas religiosas reales.

- **Rol:** control de masas / daño arcano por zonas.
- **Recurso:** Esencia.
- **Pros:** domina grupos; ralentiza y separa enemigos; daño persistente; gran control de zonas y pasillos.
- **Contras:** poca vida y armadura; vulnerable al ser alcanzada; depende de posicionamiento y gestión de esencia.
- **Atributos prioritarios:** Intelecto, Espíritu y Destreza.
- **Pasiva — Oído de la manigua:** revela amenazas cercanas tras permanecer quieta brevemente.
- **Pasiva — Raíz persistente:** los controles duran más en enemigos ya afectados por naturaleza, con límite contra jefes.
- **Habilidades:** Espina de Júcaro (proyectil penetrante); Niebla de Yagruma (nube de ralentización); Raíces del Jagüey (inmovilización de área); Mariposa de Ceniza (familiar que marca y hostiga un objetivo).
- **Definitiva — Manigua Despierta:** crea una tormenta de raíces, hojas y viento que controla el terreno y daña gradualmente.
- **Especializaciones:** Señora de Raíces (control y debilitaciones) / Hija de la Tormenta (daño elemental y movilidad).
- **Estilo de juego:** preparar terreno, atraer enemigos a zonas peligrosas y reposicionarse.

### 3. Sepulturero de Guanabacoa — El Pastor de los Ecos
**Fantasía:** invocador sombrío que escucha los recuerdos atrapados en objetos funerarios. Convoca ecos ficticios de antiguos combatientes y usa marcas de ceniza. No invoca ni caricaturiza entidades de religiones vivas.

- **Rol:** invocación / desgaste / control táctico.
- **Recurso:** Ceniza.
- **Pros:** puede dividir la atención enemiga; excelente en peleas largas; marcas y debilitaciones; las invocaciones crean espacio para lanzar magia.
- **Contras:** daño personal bajo sin preparación; depende de mantener ecos activos; vulnerable a daño de área y a interrupciones; requiere gestionar posicionamiento de invocaciones.
- **Atributos prioritarios:** Intelecto, Espíritu y Vida.
- **Pasiva — Nombre prestado:** al derrotar enemigos marcados obtiene fragmentos de ceniza, con límite de acumulación.
- **Pasiva — Último encargo:** cuando un eco termina su duración, deja una onda breve; no puede activar cadenas infinitas.
- **Habilidades:** Llamada del Osario (invoca un guardián espectral temporal); Marca del Último Nombre (debilita y revela un enemigo); Procesión de Hueso y Bronce (los ecos avanzan en línea y empujan); Vela de los Ausentes (sacrifica parte de la duración de una invocación para curar al Sepulturero y recuperar recurso).
- **Definitiva — El Patio de los que Vuelven:** convoca una procesión de ecos durante una ventana limitada; cada eco tiene salud, objetivo y reglas claras.
- **Especializaciones:** Capataz de Ecos (más invocaciones y control) / Lector de Ceniza (marcas, detonaciones y daño directo).
- **Estilo de juego:** preparar marcas, elegir cuándo invocar y sacrificar ecos. No debe jugarse como un mago de proyectiles convencional.

### 4. Tirador del Malecón — El Ojo del Faro
**Fantasía:** especialista de precisión con rifle de cerrojo, pistola, trampas y conocimiento del terreno urbano y costero.

- **Rol:** daño a distancia / ejecución de objetivos prioritarios.
- **Recurso:** Concentración.
- **Pros:** gran alcance; daño alto a objetivos marcados; interrumpe canalizaciones; puede preparar trampas.
- **Contras:** vulnerable al ser rodeado; necesita línea de visión; menor daño en movimiento; munición especial y concentración deben administrarse.
- **Atributos prioritarios:** Destreza, Fuerza e Intelecto.
- **Pasiva — Ojo de faro:** mantener línea de visión sobre un objetivo aumenta precisión hasta un límite.
- **Pasiva — Sangre fría:** impactos precisos generan concentración; fallar no concede recurso.
- **Habilidades:** Disparo de Faro (tiro cargado); Trampa de Red (ralentiza enemigos ligeros); Paso del Muelle (esquiva lateral); Doble Fogonazo (dos disparos rápidos de pistola).
- **Definitiva — Última Luz del Malecón:** disparo penetrante en línea, con telegráfico y tiempo de preparación.
- **Especializaciones:** Ojo del Faro (crítico y ejecución) / Trampero del Puerto (trampas, control y preparación).
- **Estilo de juego:** escoger posición, marcar prioridades y no desperdiciar disparos.

### 5. Cimarrón Sombrío — La Sombra del Jagüey
**Fantasía:** explorador, duelista y especialista en infiltración que domina cuevas, tejados, senderos y rutas ocultas. Su narrativa honra libertad y resistencia; nunca trivializa la esclavitud.

- **Rol:** asesino / movilidad / daño explosivo.
- **Recurso:** Vigor.
- **Pros:** movilidad superior; gran daño a objetivos aislados; puede evitar ataques y entrar/salir del combate; descubre rutas.
- **Contras:** poca resistencia; daño cae en peleas largas; exige precisión y posicionamiento; sufre contra grupos con detección.
- **Atributos prioritarios:** Destreza, Fuerza e Intelecto.
- **Pasiva — Paso sin huella:** fuera de combate acumula una carga de sigilo.
- **Pasiva — Oportunidad:** flanquear aplica una marca de vulnerabilidad con límite por objetivo.
- **Habilidades:** Cuchilla de Jagüey (combo rápido); Sombra entre Palmas (desplazamiento evasivo); Marca del Rastreador (revela debilidad); Cuerda de Garfio (movilidad hacia anclaje o control de enemigos pequeños).
- **Definitiva — Noche sin Testigos:** secuencia de ataques sobre objetivos marcados; cada objetivo recibe un impacto máximo por ciclo.
- **Especializaciones:** Cuchilla Silente (crítico y ejecución) / Rastreador Libre (marcas, movilidad y trampas).
- **Estilo de juego:** elegir el momento de entrada y retirarse antes de quedar rodeado.

### 6. Bardo del Solar — El Corazón del Barrio
**Fantasía:** músico y narrador que transforma ritmo, voz e instrumentos en ondas de memoria. El compás sincroniza al grupo; no es un simple mago con guitarra.

- **Rol:** apoyo / control / daño híbrido.
- **Recurso:** Compás.
- **Pros:** mejora a aliados; interrumpe enemigos; control en área; aporta recuperación y utilidad fuera del combate.
- **Contras:** daño individual moderado; necesita mantener ritmo y cercanía al grupo; pierde eficacia si se interrumpen sus secuencias.
- **Atributos prioritarios:** Espíritu, Destreza e Intelecto.
- **Pasiva — Ritmo compartido:** acciones coordinadas de aliados generan compás adicional.
- **Pasiva — La gente responde:** completar una secuencia musical concede una bonificación breve, con enfriamiento interno.
- **Habilidades:** Clave de Son (onda de daño y marca); Bolero de Guardia (mitigación para aliados); Rumba de Brío (velocidad temporal); Danzón de Eco (confunde enemigos menores e interrumpe canalizaciones).
- **Definitiva — El Solar Entero:** crea una zona musical que fortalece al grupo y vuelve vulnerables a los espectros.
- **Especializaciones:** Voz del Solar (apoyo y recuperación) / Tambor de Guerra (control y daño rítmico).
- **Estilo de juego:** mantener el compás, leer la pelea y apoyar en el momento oportuno.

## Estadísticas iniciales comparables (nivel 1)

Son valores de arranque para pruebas. Los recursos tienen distinta economía; no comparar sus números como si fueran unidades idénticas.

| Clase | HP | Recurso | Fuerza | Destreza | Intelecto | Espíritu | Armadura base |
|---|---:|---:|---:|---:|---:|---:|---:|
| Machetero | 125 | 100 Vigor | 18 | 13 | 8 | 11 | 12 |
| Bruja | 85 | 125 Esencia | 7 | 12 | 20 | 16 | 4 |
| Sepulturero | 95 | 115 Ceniza | 8 | 11 | 20 | 18 | 6 |
| Tirador | 90 | 100 Concentración | 12 | 20 | 10 | 10 | 5 |
| Cimarrón | 95 | 110 Vigor | 13 | 20 | 12 | 10 | 5 |
| Bardo | 100 | 100 Compás | 10 | 14 | 13 | 20 | 7 |

### Crecimiento por nivel

Cada nivel concede **5 puntos de atributo** para distribuir manualmente. Además, cada clase recibe crecimiento automático moderado:

| Clase | HP por nivel | Recurso máximo por nivel | Armadura por nivel |
|---|---:|---:|---:|
| Machetero | +12 | +4 | +1.0 |
| Bruja | +7 | +6 | +0.3 |
| Sepulturero | +8 | +6 | +0.4 |
| Tirador | +8 | +5 | +0.4 |
| Cimarrón | +8 | +5 | +0.4 |
| Bardo | +9 | +5 | +0.5 |

Los puntos manuales aumentan estadísticas mediante coeficientes compartidos y visibles. El equipo puede modificar valores, pero no debe anular las fortalezas y debilidades de clase.

## Progresión de experiencia y niveles

- Nivel máximo del primer arco: **30**, ampliable en futuras temporadas/capítulos.
- XP por derrotar enemigos: solo la primera muerte/recompensa de un enemigo de misión entrega XP completa; enemigos repetibles usan XP reducida y límite por zona/hora para evitar granjas abusivas.
- Misiones principales: recompensa alta; secundarias: media; encargos repetibles: baja y con límite diario/local configurable.
- Exploración: XP por descubrir lugar por primera vez, completar evento y abrir punto de interés; no por caminar repetidamente.
- Jefes: recompensa única por primera victoria en cada dificultad.
- En grupo: XP se reparte por participación válida dentro de rango; no se duplica por cantidad de jugadores. Ajustar por dificultad/vida real del encuentro y evitar penalizar apoyo/healing.
- No conceder XP por daño a aliados, invocaciones propias ni objetivos fuera de nivel/rango.
- Mostrar barra de XP, XP actual/total necesario, fuente de recompensa y desbloqueo siguiente.

### Curva provisional de XP

XP para pasar del nivel N al N+1:

`XP_siguiente(N) = redondear(100 + 35(N-1) + 8(N-1)^2)`

Ejemplos:
| Tramo | XP por nivel |
|---|---:|
| 1 → 2 | 100 |
| 2 → 3 | 143 |
| 3 → 4 | 202 |
| 4 → 5 | 277 |
| 5 → 6 | 368 |
| 6 → 7 | 475 |
| 7 → 8 | 598 |
| 8 → 9 | 737 |
| 9 → 10 | 892 |
| 10 → 11 | 1,063 |
| 15 → 16 | 2,020 |
| 20 → 21 | 3,377 |
| 25 → 26 | 5,132 |
| 29 → 30 | 6,916 |

Los números son hipótesis de pacing. El equipo debe simular cuánto tarda un jugador normal en alcanzar niveles 5, 10, 20 y 30, y ajustar las recompensas de las misiones. No prometer horas de juego hasta medir.

## Fórmulas de combate y reglas anti-dominancia

- Daño físico efectivo = potencia física × coeficiente de habilidad × modificador de atributo × mitigación de armadura.
- Daño arcano = potencia arcana × coeficiente de habilidad × modificador de Intelecto × mitigación de resistencia.
- Crítico, bloqueo, evasión y vulnerabilidad tienen límites globales y rendimientos decrecientes.
- Control de masas sobre jefes usa resistencia acumulativa; nunca bloqueo permanente.
- Invocaciones comparten presupuesto de entidades activas y reciben límites de daño/vida; no pueden generar XP ni drops por sí mismas.
- Curación y barreras tienen coeficientes reducidos en PvP futuro; PvP no está autorizado en el MVP.
- Los telegráficos muestran área, tiempo y severidad; las habilidades no deben causar daño solo por animación.
- La dificultad aumenta por patrones, combinaciones y presión, no solo inflando HP.

Los coeficientes exactos deben centralizarse en datos configurables y ajustarse con telemetría de pruebas. No fijar fórmulas duplicadas dentro de cada habilidad.

## Equipo, builds y desbloqueos

- Cada clase tiene ataque básico, esquiva, cuatro habilidades equipables y una definitiva.
- Especializaciones desbloqueadas en niveles 10 y 20, con elección reversible mediante coste moderado en refugios.
- A nivel 5 se desbloquea una pasiva adicional elegible.
- Armas, armaduras y afijos deben respetar la fantasía de clase.
- Rarezas: común, poco común, raro, épico y legendario. Los legendarios cambian decisiones de build, no solo suben números.
- Guardar clase, nivel, XP, atributos asignados, habilidades, especialización y versión de datos con IDs estables.

## Pruebas obligatorias

1. Curva XP: monotónica, sin overflow y nivel máximo correcto.
2. Recompensa de XP por fuente, primera victoria, repetición y grupo.
3. No duplicar XP por invocaciones, daño repetido ni reconexión.
4. Crecimiento automático y puntos manuales por nivel.
5. Coste, cooldown, alcance, interrupción y cancelación de cada habilidad.
6. Mitigación física/arcana, críticos, bloqueo y resistencias.
7. Pruebas comparativas de DPS, supervivencia, control y apoyo por clase.
8. Cada clase puede superar encuentros de campaña en solitario con habilidad razonable.
9. Las builds de grupo no deben hacer obligatoria una clase.
10. Perfil Low mantiene legibilidad de invocaciones, telegráficos y VFX.
11. Guardado/carga y migración de personajes ante cambios de balance.

Toda métrica de balance debe acompañarse de escenario, nivel, equipo, build, duración y semilla de prueba. No declarar clases equilibradas solo por inspección de números.

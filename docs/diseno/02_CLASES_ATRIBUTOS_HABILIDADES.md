# Clases, atributos y habilidades — RPG LBA

## Principios de balance

Las seis clases deben ser distintas por ritmo, distancia, recursos, movilidad y utilidad de grupo. Ninguna debe ser “la mejor” en todo. Los números siguientes son una **línea base de prototipo**, no balance final. El agente debe implementarlos en datos externos y crear pruebas de daño, costes, cooldowns, escalado y estados.

### Atributos

- **Vida (HP):** daño que puede recibir.
- **Vigor:** recurso para ataques físicos, esquiva y técnicas.
- **Fuerza:** daño físico, guardia y armas pesadas.
- **Destreza:** velocidad, precisión, crítico y recuperación.
- **Intelecto:** daño arcano, recursos mágicos y potencia de efectos.
- **Espíritu:** curación, resistencia a corrupción y apoyo.
- **Armadura:** mitigación física.
- **Resistencia:** mitigación elemental y a estados.

Los atributos se muestran en UI con nombre y explicación. No usar únicamente color para distinguir daño o rareza.

## Estadísticas iniciales sugeridas (nivel 1)

| Clase | HP | Vigor | Maná/Esencia | Fuerza | Destreza | Intelecto | Espíritu | Rol |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| Machetero de la Sierra | 125 | 100 | 35 | 18 | 13 | 8 | 11 | Tanque/combate cercano |
| Bruja de la Manigua | 85 | 55 | 125 | 7 | 12 | 20 | 16 | Control/daño arcano |
| Santero de la Luz | 105 | 70 | 115 | 9 | 11 | 15 | 20 | Curación/apoyo |
| Tirador del Malecón | 90 | 85 | 65 | 12 | 20 | 10 | 10 | Distancia/precisión |
| Cimarrón Sombrío | 95 | 110 | 50 | 13 | 20 | 12 | 10 | Asesino/movilidad |
| Bardo del Solar | 100 | 80 | 95 | 10 | 14 | 13 | 18 | Apoyo/control |

**Recurso por clase:** vigor para Machetero y Cimarrón; esencia para Bruja y Santero; concentración para Tirador; compás para Bardo. La interfaz puede normalizar el recurso visual, pero debe conservar reglas propias.

## 1. Machetero de la Sierra

**Fantasía:** defensor de caminos, cortador de maleza y protector de comunidades. Usa machete, sable corto, escudo improvisado y herramientas de campo. Es resistente, directo y domina el espacio cercano.

**Pasivas**
- *Pulso de monte:* gana vigor al bloquear o esquivar en el momento correcto.
- *Pies de piedra:* reduce empujones y ralentizaciones.

**Habilidades**
1. **Tajo de Guásima** — arco frontal amplio; daño físico medio y sangrado leve.
2. **Guardia del Bohío** — postura defensiva; reduce daño frontal y protege a un aliado cercano.
3. **Carga del Mambí** — embestida lineal que interrumpe enemigos ligeros.
4. **Corte de la Ceiba** — golpe vertical pesado; rompe escudos y armaduras.
5. **Definitiva: Huracán de Machetes** — combo circular con desplazamiento corto y final de alto impacto; no debe ser una copia de torbellinos de otras franquicias.

**Debilidad:** alcance corto y dependencia de vigor.  
**Identidad de equipo:** machetes con marcas artesanales, cuero, lona, metal reparado y amuletos familiares.

## 2. Bruja de la Manigua

**Fantasía:** conocedora de plantas, nieblas y fuerzas antiguas. Su magia es de control del terreno, raíces, viento y espíritus ficticios. No representa ni caricaturiza una religión real.

**Pasivas**
- *Oído de la manigua:* revela enemigos ocultos al permanecer quieta brevemente.
- *Raíz persistente:* los controles duran más sobre enemigos afectados por naturaleza.

**Habilidades**
1. **Espina de Júcaro** — proyectil de raíz que atraviesa una línea corta.
2. **Niebla de Yagruma** — nube que ralentiza y reduce precisión enemiga.
3. **Raíces del Jagüey** — inmoviliza una zona; los enemigos fuertes pueden resistir parcialmente.
4. **Mariposa de Ceniza** — familiar arcano que marca un objetivo y vuelve con energía.
5. **Definitiva: Manigua Despierta** — crea un círculo de raíces, viento y hojas oscuras que controla el campo y causa daño gradual.

**Debilidad:** poca vida y vulnerabilidad cuando enemigos rápidos alcanzan su posición.  
**Identidad de equipo:** fibras, semillas, madera, telas naturales, frascos y símbolos inventados del mundo.

## 3. Santero de la Luz

**Fantasía:** protector y sanador que canaliza luz, memoria y juramentos. El término de clase es una fantasía original; no debe afirmar que sus poderes describen prácticas religiosas reales. El personaje puede ser reinterpretado visualmente como **Guardián de la Luz** si el equipo narrativo decide evitar confusión cultural.

**Pasivas**
- *Manos que sostienen:* curar a un aliado concede una barrera breve.
- *Luz contra ceniza:* inflige daño adicional a criaturas de corrupción, con límite para evitar dominación de meta.

**Habilidades**
1. **Lumbre Serena** — proyectil de luz de daño moderado.
2. **Velo Protector** — escudo a sí mismo o aliado.
3. **Agua Clara** — curación directa y eliminación de un estado menor.
4. **Campana del Alba** — pulso que interrumpe espectros y revela enemigos.
5. **Definitiva: Coro de los Siete** — zona de apoyo que cura gradualmente, reduce corrupción y fortalece resistencia del grupo.

**Debilidad:** daño explosivo bajo y tiempos de lanzamiento.  
**Identidad de equipo:** bastón, campanillas, telas claras envejecidas, latón y símbolos de protección originales.

## 4. Tirador del Malecón

**Fantasía:** tirador de precisión que mezcla rifle de época, pistola, trampas y movilidad urbana. Armas y munición deben tener estética y manejo compatibles con la ambientación de 1953.

**Pasivas**
- *Ojo de faro:* gana precisión al mantener línea de visión.
- *Sangre fría:* disparos a objetivos marcados reducen una parte del cooldown de herramienta, con límite.

**Habilidades**
1. **Disparo de Faro** — tiro cargado de alto daño a un objetivo.
2. **Trampa de Red** — inmoviliza o ralentiza enemigos pequeños.
3. **Paso del Muelle** — esquiva lateral que deja una marca explosiva pequeña.
4. **Doble Fogonazo** — dos disparos rápidos de pistola.
5. **Definitiva: Última Luz del Malecón** — apunta a una línea amplia y dispara una descarga penetrante; telegráfico visible para enemigos y aliados.

**Debilidad:** sufre si lo rodean; necesita gestionar munición o concentración.  
**Identidad de equipo:** rifle de cerrojo, pistola, cartucheras, gabardina, botas y herramientas de pescador.

## 5. Cimarrón Sombrío

**Fantasía:** explorador furtivo y duelista que conoce rutas secretas, cuevas y tejados. Su historia honra la resistencia y la libertad; no convierte la esclavitud en estética ni trivializa su memoria.

**Pasivas**
- *Paso sin huella:* moverse fuera del combate acumula una carga de sigilo.
- *Oportunidad:* atacar desde flanco o espalda aplica marca de vulnerabilidad limitada.

**Habilidades**
1. **Cuchilla de Jagüey** — corte rápido con veneno ficticio de planta.
2. **Sombra entre Palmas** — desplazamiento corto que evita proyectiles durante una ventana breve.
3. **Marca del Rastreador** — revela debilidad y aumenta precisión del siguiente ataque.
4. **Cuerda de Garfio** — atrae al personaje hacia un punto o desplaza enemigos pequeños.
5. **Definitiva: Noche sin Testigos** — secuencia de golpes a objetivos marcados; cada objetivo puede recibir daño una vez por ciclo.

**Debilidad:** menor resistencia en enfrentamientos prolongados y dependencia de posicionamiento.  
**Identidad de equipo:** cuero oscuro, telas discretas, cuchillas artesanales, cuerda y herramientas de escalada.

## 6. Bardo del Solar

**Fantasía:** músico, narrador y líder de barrio. Usa ritmo, voz, instrumentos y memoria colectiva para apoyar al grupo. No es un “mago músico” genérico: su recurso es el compás y su identidad se basa en sincronizar acciones.

**Pasivas**
- *Ritmo compartido:* las acciones correctas de aliados cercanos generan compás.
- *La gente responde:* al completar una secuencia musical, concede una pequeña bonificación de grupo.

**Habilidades**
1. **Clave de Son** — onda sonora que daña y marca enemigos.
2. **Bolero de Guardia** — reduce daño recibido por aliados cercanos.
3. **Rumba de Brío** — aumenta temporalmente velocidad de movimiento y ataque.
4. **Danzón de Eco** — confunde enemigos y rompe canalizaciones.
5. **Definitiva: El Solar Entero** — invoca una zona de música y memoria: cura levemente, fortalece aliados y hace vulnerables a espectros.

**Debilidad:** daño individual moderado y dependencia de mantener compás/posición.  
**Identidad de equipo:** tres, guitarra, claves, maracas, ropa de escenario gastada, pañuelo y accesorios.

## Reglas comunes de habilidades

- Cada clase tiene ataque básico, esquiva, cuatro habilidades y una definitiva inicial.
- Las habilidades tienen coste, cooldown, alcance, telegráfico, categoría de daño y eventos de prueba.
- La definitiva se carga con acciones de clase, no solo con tiempo.
- El jugador puede equipar una selección limitada para móvil; no saturar la pantalla.
- Cada habilidad debe tener animación anticipatoria, impacto, recuperación, VFX y sonido.
- Las animaciones no pueden ser la fuente de verdad del daño.
- El servidor futuro valida objetivo, distancia, cooldown, recurso, estado y resultado.
- No usar daño aleatorio sin límites; la semilla y los modificadores deben poder reproducirse en pruebas.

## Progresión y especializaciones

A niveles 5, 10 y 20 se desbloquean decisiones de especialización. Cada clase puede orientar su build hacia dos estilos, pero no se crean seis subclases completas en el MVP.

| Clase | Especialización A | Especialización B |
|---|---|---|
| Machetero | Guardián del Batey (defensa) | Hoja de la Sierra (daño/ruptura) |
| Bruja | Señora de Raíces (control) | Hija de la Tormenta (daño elemental) |
| Santero/Guardián | Custodio del Alba (barreras) | Voz de los Siete (curación) |
| Tirador | Ojo del Faro (crítico) | Trampero del Puerto (control) |
| Cimarrón | Cuchilla Silente (crítico) | Rastreador Libre (movilidad/marcas) |
| Bardo | Voz del Solar (apoyo) | Tambor de Guerra (daño/control) |

## Reglas de accesibilidad y UI

- El jugador puede mover botones y ajustar tamaño/opacidad.
- Mostrar icono, nombre, cooldown numérico y coste.
- Las habilidades disponibles se distinguen por forma y texto, no solo color.
- Opción de auto-target y modo manual.
- Permitir reducir flashes, vibración, sacudida y partículas.
- Las barras de HP/recurso deben ser legibles sobre fondos claros y oscuros.

## Pruebas obligatorias por clase

1. Cálculo de daño físico/arcano y mitigación.
2. Coste de recurso antes/después de ejecutar.
3. Cooldown y cancelación.
4. Alcance, línea de visión y objetivo inválido.
5. Interrupción, control y resistencia de élites.
6. Muerte del jugador durante animación de habilidad.
7. Modo solo local y futura validación servidor.
8. Rendimiento de VFX en perfil Low.

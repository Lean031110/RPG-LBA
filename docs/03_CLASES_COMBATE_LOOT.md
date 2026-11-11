# 03 — Clases, combate, habilidades y botín

## 1. Reglas de combate

- Combate en tiempo real, dirigido por el servidor.
- Ataque básico y 4 habilidades equipadas; una habilidad definitiva puede ocupar un slot especial al desbloquearse.
- Esquiva con cooldown corto y ventana de invulnerabilidad muy breve solo si balance y latencia lo permiten.
- Enemigos telegráficos: color/forma/animación + sonido; dar tiempo de reacción para pantalla táctil.
- La cámara y los efectos no deben ocultar el área de peligro.
- Hit detection y daño se calculan en servidor; cliente predice animación y movimiento cosmético con reconciliación.
- No usar animación como única prueba de daño: cada ataque define área, alcance, hitbox/hurtbox y ventana activa.

## 2. Estadísticas

- Vida (HP), recurso de clase (Maná/Furia/Fe/Enfoque), daño, armadura, resistencia elemental, velocidad de ataque, crítico, velocidad de movimiento y reducción de cooldown.
- Evitar demasiadas estadísticas en la interfaz de móvil. Mostrar básicas y un panel avanzado opcional.
- Rendimientos decrecientes en crítico, armadura y reducción de enfriamiento.
- El nivel de objeto no debe convertir equipo anterior en totalmente inútil; usar afijos/estilos de build.

## 3. Seis clases originales

### Paladín del Alba — protector y soporte

- Recurso: Fe.
- Rol: tanque/soporte, daño sagrado moderado.
- Básico: golpe de espada.
- Habilidades de ejemplo: Escudo Radiante (mitigación/escudo), Martillo del Alba (proyectil), Juramento Protector (buff de grupo), Sentencia Solar (área definitiva).
- Fortalezas: supervivencia, defensa en grupo, control de pequeños enemigos.
- Debilidades: movilidad y daño sostenido menores.

### Bárbaro de la Fragua — combatiente frontal

- Recurso: Furia generada al atacar/recibir golpes.
- Rol: daño cuerpo a cuerpo y control.
- Habilidades: Hender, Salto Sísmico, Torbellino de Acero, Grito Indómito.
- Fortalezas: área y resistencia al estar rodeado.
- Debilidades: alcance y vulnerabilidad a enemigos que obligan a moverse.

### Hechicera de los Ecos — daño mágico

- Recurso: Maná.
- Rol: daño elemental y control de zona.
- Habilidades: Proyectil Ígneo, Cadena de Escarcha, Paso Relámpago, Tormenta Prismática.
- Fortalezas: daño a distancia y control.
- Debilidades: frágil, depende de administrar recurso.

### Cazador del Velo — tirador táctico

- Recurso: Enfoque.
- Rol: daño a distancia, trampas y marcaje.
- Habilidades: Flecha Perforante, Trampa de Raíces, Lluvia de Saetas, Marca del Depredador.
- Fortalezas: alcance, daño a objetivo marcado y control de rutas.
- Debilidades: requiere colocación y distancia.

### Nigromante del Umbral — invocación y maldiciones

- Recurso: Esencia.
- Rol: daño por tiempo, debilitamiento e invocaciones limitadas.
- Habilidades: Lanza Ósea, Siervo de Ceniza, Maldición Devoradora, Cosecha de Almas.
- Fortalezas: presión sostenida y sinergia con enemigos debilitados.
- Debilidades: depende de gestionar invocación y cooldowns.
- Límite inicial estricto de invocaciones por jugador para rendimiento.

### Asesino de la Sombra — movilidad y precisión

- Recurso: Concentración.
- Rol: ráfagas, veneno y movilidad.
- Habilidades: Corte Gemelo, Paso Umbrío, Bomba de Humo, Ejecución Marcada.
- Fortalezas: movilidad y daño a objetivos prioritarios.
- Debilidades: menos eficaz si falla la entrada o se prolonga combate frontal.

## 4. Progresión de habilidades

- Nivel 1: básico + una habilidad principal.
- Niveles posteriores desbloquean habilidades y variantes.
- Primer arco: 6–8 habilidades por clase diseñadas; 4 activas simultáneas + básico + esquiva/consumible.
- Cada habilidad tiene ID, clase, coste, cooldown, alcance, área, etiquetas, animación, VFX, sonido y reglas de servidor.
- Variantes modifican comportamiento (más área, control, coste menor), no solo +número.
- Reinicio de puntos mediante recurso de juego, nunca pago real en MVP.

## 5. Arquetipos de enemigos

- Hostigador: rápido, poca vida, flanquea.
- Bruto: lento, golpe pesado telegrafiado.
- Tirador: obliga a moverse, dispara proyectiles.
- Invocador: crea unidades o zonas.
- Guardián: protege puntos y bloquea rutas.
- Élite: añade afijo (rápido, explosivo, resistente, invocador), máximo dos afijos en primera versión.
- Jefe: fases y mecánicas únicas; no un enemigo normal con más vida.

## 6. Botín

Rarezas: común, poco común, raro, épico y legendario.

- Común: estadísticas base, útil para inicio/venta.
- Poco común: una propiedad secundaria.
- Raro: 2–3 afijos.
- Épico: 3–4 afijos y posible sinergia de clase.
- Legendario: efecto único identificable, limitado y probado.

Reglas:
- La tabla de loot corre en el servidor con RNG sembrado y controles de duplicación.
- En grupo, cada jugador recibe drops personales o roll separado; evitar disputas en el MVP.
- Los objetos tienen `item_id` estable, `definition_id`, rareza, nivel, afijos, propietario temporal y estado.
- No aceptar que un cliente modifique cantidades, rareza o estadísticas.

## 7. Consumibles

- Pociones de vida y recurso, antídotos, comida temporal y llaves de mazmorra.
- Cooldowns y cantidades validados en servidor.
- UI debe indicar cooldown y cantidad con lectura grande.

## 8. Balance

- Crear hojas/JSON de datos y un script de validación de rangos.
- Cada clase debe tener supervivencia, daño, utilidad y movilidad medidos.
- No equilibrar solo por DPS; medir tiempo para matar, daño recibido, interrupciones, utilidad de grupo y facilidad en móvil.
- Cambios de balance deben tener tests de datos: valores no negativos, cooldown mínimo, costes <= recurso permitido, no habilidades bloqueadas sin nivel.

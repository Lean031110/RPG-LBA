# Fase oficial 2 — Cierre de las seis clases ARPG
**Revisión:** 2026-11-18 · **Estado auditado:** 3/6 kits implementados; Fase 2 ABIERTA.

## 1. Qué significa esta fase
La Fase oficial 2 del Production Kit es **combate ARPG y seis clases**. No es la antigua Fase 2 de prototipo de movimiento documentada en `FASE_02_INFORME_DE_IMPLEMENTACION.md`. El movimiento/cámara/joystick son una entrega técnica anterior. ADR-008 y `docs/ROADMAP.md` son la autoridad de numeración.

## 2. Estado real observado
| Clase | Datos en JSON | Kit de clase | Estado |
|---|---|---|---|
| Machetero | sí | `MacheteroKit` | implementado; usar tests actuales como baseline |
| Bruja | sí | `BrujaKit` | implementada; usar tests actuales como baseline |
| Sepulturero | sí | `SepultureroKit` | implementado; usar tests actuales como baseline |
| Tirador | solo ID/base parcial; sin lista de skills | no | pendiente |
| Cimarrón | solo ID/base parcial; sin lista de skills | no | pendiente |
| Bardo | solo ID/base parcial; sin lista de skills | no | pendiente |

La verificación se hizo sobre `game/data/classes.json` y `scripts/arpg/player/` en el HEAD auditado. La presencia de nombres/IDs no equivale a una clase jugable.

## 3. Contrato técnico que deben reutilizar
- `ArpgCombatant`, `DamageSystem`, `SkillController`, `CooldownController`, `StatusEffectController`, `HitboxController`, `TargetingSystem` y `ClassKit` son el motor compartido.
- El jugador/HUD debe depender de la interfaz común, no de nombres concretos de clase.
- Los kits de clase controlan identidad mecánica; no duplicar fórmula de daño ni UI.
- La lógica debe poder migrarse a autoridad de servidor: cliente solicita intención; servidor valida y calcula resultado.
- Datos balanceables viven en JSON con IDs estables. Añadir validación de esquema, defaults explícitos y tests para datos ausentes/incorrectos.
- Persistencia debe guardar class_id, nivel, atributos, recurso, carga definitiva, especialización y estado necesario; nunca guardar nodos/objetos volátiles como verdad persistente.
- Mantener Godot 4.7.2 Standard, GDScript y Compatibility Renderer. No introducir C# ni extensiones nativas.

## 4. Canon de las tres clases pendientes
Toda habilidad se implementa conforme a `docs/diseno/02_CLASES_ATRIBUTOS_HABILIDADES.md`. Las descripciones siguientes son resumen de identidad, no autorización para cambiar el canon.

### Tirador del Malecón — El Ojo del Faro
- Rol: daño a distancia y ejecución de objetivos prioritarios.
- Recurso: Concentración. Atributos prioritarios: Destreza, Fuerza e Intelecto.
- Pasivas: Ojo de faro (mantener línea de visión mejora precisión hasta un límite); Sangre fría (impactos precisos generan Concentración; fallar no).
- Kit: Disparo de Faro (tiro cargado), Trampa de Red (ralentiza enemigos ligeros), Paso del Muelle (esquiva lateral), Doble Fogonazo (dos disparos rápidos de pistola).
- Definitiva: Última Luz del Malecón, disparo penetrante lineal con preparación y telegráfico.
- Especializaciones: Ojo del Faro / Trampero del Puerto.
- Contrajuego: línea de visión, preparación, menor daño en movimiento y vulnerabilidad al cerco. No crear munición infinita sin decisión de diseño; la economía de munición debe coordinarse con Fase 3.

### Cimarrón Sombrío — La Sombra del Jagüey
- Rol: asesino, movilidad y daño explosivo.
- Recurso: Vigor. Atributos: Destreza, Fuerza e Intelecto.
- Pasivas: Paso sin huella (carga de sigilo fuera de combate); Oportunidad (flanqueo marca vulnerabilidad con límite por objetivo).
- Kit: Cuchilla de Jagüey (combo rápido), Sombra entre Palmas (desplazamiento evasivo), Marca del Rastreador (revela debilidad), Cuerda de Garfio (movilidad hacia anclaje o control de enemigos pequeños).
- Definitiva: Noche sin Testigos, secuencia sobre objetivos marcados con máximo de un impacto por objetivo y ciclo.
- Especializaciones: Cuchilla Silente / Rastreador Libre.
- Contrajuego: poca resistencia, rendimiento menor en peleas largas y necesidad de posicionamiento. La fantasía honra libertad y resistencia; no trivializar la esclavitud ni convertirla en estética de poder.

### Bardo del Solar — El Corazón del Barrio
- Rol: apoyo, control y daño híbrido.
- Recurso: Compás. Atributos: Espíritu, Destreza e Intelecto.
- Pasivas: Ritmo compartido (acciones coordinadas generan Compás); La gente responde (secuencia musical completa concede bonificación breve con cooldown interno).
- Kit: Clave de Son (onda y marca), Bolero de Guardia (mitigación de aliados), Rumba de Brío (velocidad temporal), Danzón de Eco (confunde enemigos menores e interrumpe canalizaciones).
- Definitiva: El Solar Entero, zona musical que fortalece al grupo y expone espectros.
- Especializaciones: Voz del Solar / Tambor de Guerra.
- Contrajuego: daño individual moderado; secuencias interrumpibles y necesidad de proximidad al grupo. La música debe ser original/licenciada, no una imitación de canciones existentes.

## 5. Orden de implementación
Una clase por PR, no las tres juntas:
1. Tirador: proyectil/canalización, línea de visión, trampas y concentración.
2. Cimarrón: flanqueo, sigilo acotado, movilidad y marca.
3. Bardo: buffs de aliados, auras/zonas, control de enemigos y secuencia musical.
4. Integración: selector/creación de personaje, HUD por recurso, guardado/carga y compatibilidad de clases.
5. Balance: simulación automatizada de DPS, supervivencia, control, apoyo, uptime y consumo de recurso en niveles 1/10/20/30.

## 6. Matriz obligatoria de pruebas por clase
- Datos: IDs únicos, campos requeridos, unlock levels válidos, costes/cooldowns positivos, rangos y límites.
- Ataque básico: alcance, línea de visión, daño, animación/ventana, cooldown y objetivo válido.
- Cada una de las cuatro habilidades: éxito, coste, cooldown, desbloqueo, cancelación, interrupción, muerte del objetivo y cambio de escena.
- Definitiva: carga, no duplicación, consumo único, cooldown, persistencia apropiada y comportamiento ante desconexión.
- Pasivas: trigger, cooldown interno, cap, expiración y prevención de cadenas infinitas.
- Recurso: regen, coste insuficiente, máximo, muerte, carga y guardado.
- Estado: stun/root/slow/mark/bleed; inmunidades y límites de jefe.
- Red: autoridad, rate limit, validación de distancia/ownership cuando la ruta multiplayer esté lista.
- UX: iconos propios, cooldown radial, barra de recurso, estados accesibles, vibración opcional.
- Persistencia: guardar/cargar clase, nivel, atributos, puntos, equipo y estado compatible.

## 7. Criterios de cierre de Fase 2
No cerrar hasta:
- seis kits distintos y seleccionables;
- cuatro habilidades + ataque básico + esquiva + definitiva + dos pasivas + dos especializaciones por clase (las especializaciones pueden tener primera versión funcional acotada, pero no ser solo nombres);
- todas las habilidades balanceadas por datos y sin fórmulas duplicadas;
- selector/preview/feedback UI y HUD compatible;
- guardado versionado y migración;
- pruebas automatizadas y smoke de combate con cada clase;
- simulación comparativa y playtest humano;
- CI verde en PR y evidencia visual real;
- reporte de limitaciones, especialmente hardware Android NOT TESTED si no se dispone de teléfono.

## 8. Prompt operativo por clase
Ver `prompts/11_RPG_LBA_AGENT_PLAYBOOK.md` — Prompt 2. Cada agente debe inspeccionar el kit compartido y tests antes de editar. No inventar nombres/IDs, no reutilizar el kit de otra clase como implementación final y no marcar PASS sin Actions.

## 9. Estado
**NO COMPLETADA — 3/6.** Este documento define el trabajo restante; no afirma que los tres kits pendientes ya existan.

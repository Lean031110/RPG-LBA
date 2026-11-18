# Pipeline de construcción del mundo — El Eco de Valdeluz
**Revisión:** 2026-11-18 · **Estado:** especificación de producción; las regiones no se consideran construidas por estar descritas.

## 1. Principio de escala
Lythara es un mundo de regiones conectadas, no un mapa monolítico. Cada región se divide en sectores con entradas/salidas controladas. Cargar la región activa y sus vecinos inmediatos; descargar sectores lejanos sin perder estado persistente. No prometer streaming seamless: la transición inicial puede usar portal/puerta/escena de carga breve hasta que exista benchmark que justifique otra solución.

## 2. Macro mapa de campaña
El documento `docs/04_MUNDO_DUNGEONS.md` define seis zonas macro:
0. Valdeluz — refugio y servicios.
1. Bosque de Brumaclara — niveles 1–7.
2. Minas de Ghar — 8–12.
3. Marjal Cenizal — 10–16.
4. Costa Quebrada — 13–18.
5. Sierra de los Colosos — 18–24.
6. Bastión del Umbral — 24–30.

La biblia narrativa amplía geografía y biomas con La Habana, Mogotes de la Niebla, Central de las Ánimas, Sierra del Juramento y Ciénaga del Silencio. Antes de implementar nuevas regiones, crear una tabla de correspondencia: región gameplay ↔ lugar narrativo ↔ capítulo ↔ nivel ↔ assets ↔ misiones. Resolver nombres/solapamientos mediante adenda a GDD, no por renombrado improvisado.

## 3. Estado verificable del mundo
- Valdeluz slice: escena jugable y ambiente base existen en main según el estado/documentación previa.
- Capital de Valdeluz: PR #15 abierta/draft, preview procedural separada. Incluye plaza, calles, barrios y edificios exteriores; la descripción de la PR declara interiores no transitables. No está integrada en main.
- Las otras cinco regiones, tres mazmorras y cinco jefes tienen diseño en documentos, no evidencia de implementación completa.
- No afirmar que hay casas transitables, NPCs con rutinas, interiores, navegación completa, streaming por sectores o mundo terminado sin escena, tests y captura verificables.

## 4. Orden de construcción recomendado
### W0 — Auditoría y mapa de dependencias
- Inventariar escenas, builders, materiales, colisiones, navegación, spawners, POIs, NPCs, puertas, misiones y assets.
- Hacer matriz de reutilización y evitar duplicar builders/VisualKit/TerrainMaterialLibrary/EnvironmentController.
- Acordar escala métrica, orientación, grid, capas de colisión y presupuesto de draw calls.

### W1 — Valdeluz como vertical slice urbana
- Mantener PR #15 aislada hasta revisar su CI, escena y cambios contra main.
- Auditar geometría y layout, rutas accesibles, colisiones y rendimiento.
- Crear un bloque urbano representativo: plaza + dos calles + un interior funcional + un servicio NPC + una misión.
- Definir sistema de interiores modular (portal, escena o subescena), occlusion/culling y retorno al exterior.
- Añadir navegación de NPC y jugador; no llenar la ciudad con edificios huecos.
- Probar 16:9/20:9 y perfil Low, capturar rutas de día/noche.
- La aprobación de integración de #15 corresponde al propietario; este pipeline no la fusiona.

### W2 — Región exterior Brumaclara
- Un loop de exploración de 5–10 minutos: entrada, landmark, combate, recurso, evento, retorno.
- Terrain layers: césped tropical, tierra roja, piedra caliza, barro/hojarasca.
- Caminos legibles, barreras físicas naturales, rutas opcionales y landmarks.
- Spawns por encounter tables; densidad y respawn controlados.
- Navegación validada para jugador/enemigos; enemigos no atraviesan paredes ni quedan atrapados.
- Misión de región conectada al QuestSystem y persistente.

### W3 — Mazmorra piloto: Galerías de Ghar
- Módulos preconstruidos con conectores compatibles; semilla determinista.
- Grafo de salas siempre conectado; entrada/salida y ruta resoluble.
- Salas de combate, evento, recompensa y jefe; puertas/llaves nunca bloquean la ruta.
- Yunque Hueco con telegráficos, fases, vulnerabilidades y reglas anti-softlock.
- Guardar semilla, progreso de run y recompensas; pruebas de repetición y rollback.

### W4 — Repetir plantilla por región
Para cada región: World Art Bible, mapa de navegación, POI list, encuentro/loot tables, misión principal/secundaria, set de assets, rendimiento y pruebas. No clonar contenido sin diferenciación cultural/visual.

### W5 — Integración macro
- Mapa global, desbloqueo por historia, viajes, puntos seguros y carga/descarga.
- Transiciones con estado persistente y protección ante cierre/crash.
- Eventos de mundo con cooldowns y reglas de instancia.
- Streaming solo tras medir memoria y tiempos en dispositivos objetivo.

## 5. Contrato técnico de cada zona
Cada paquete de zona debe entregar:
- `zone_id` estable y versión de contenido.
- Escena raíz y puntos de entrada/salida.
- Bounds, colisiones, navegación y zonas no transitables.
- POIs con IDs estables, discovery flags y minimapa.
- Spawn points, encounter tables, niveles y límites de entidades.
- NPCs, diálogos, horarios/rutinas si forman parte del alcance.
- Misiones, triggers, eventos y estado persistente.
- Iluminación/clima compatible con perfiles gráficos.
- Assets con manifest de autor/licencia/fuente.
- Tests estructurales, navegación, semilla, transiciones y capturas.
- Presupuesto y mediciones de rendimiento.

## 6. Dungeons: criterios de generación
No construir salas aleatorias sin validar el grafo. La semilla debe reproducir la misma run. Verificar accesibilidad con path queries, alcance de puertas, llaves, boss arena, respawn y puntos de salida. La tabla de loot debe generarse en autoridad del servidor cuando el online exista; el cliente no decide recompensas.

## 7. Prompt operativo
Ver `prompts/11_RPG_LBA_AGENT_PLAYBOOK.md` — Prompt 3 (zona) y Prompt 4 (mazmorra). La PR #15 se trata como entrada de trabajo, no como contenido ya aceptado.

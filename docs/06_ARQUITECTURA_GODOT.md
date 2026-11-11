# 06 — Arquitectura técnica Godot

## Versiones fijadas

- Godot 4.7.2 Standard (no .NET).
- GDScript tipado.
- Renderer de primera entrega: Compatibility.
- Android ARM64 como export objetivo.
- GdUnit4 7.x compatible con Godot 4.7; fijar una versión estable exacta revisada durante bootstrap (la documentación actual muestra v7.0.0 para Godot 4.7).

## Renderizado

Compatibility usa OpenGL/OpenGL ES y apunta a hardware antiguo/low-end. En Android requiere GPU con OpenGL ES 3.0. Esto debe validarse en el Redmi 9C real; no basta con que el SoC figure en una lista. La calidad del cliente se adapta mediante resolución, distancia, sombras, partículas, densidad de vegetación y posprocesado. El renderer se fija para la build; no se puede cambiar de Compatibility a Mobile dentro del mismo APK en tiempo de ejecución.

Build inicial única: Compatibility. Build opcional futura “Enhanced” con Mobile renderer solo si los dispositivos Vulkan seleccionados pasan matriz de pruebas; se tratará como variante separada con los mismos datos y lógica.

## Estructura propuesta

```text
RPG_LBA/
  AGENTS.md
  project.godot
  export_presets.cfg
  README.md
  LICENSE
  THIRD_PARTY_NOTICES.md
  assets/
    characters/ enemies/ environments/ props/ ui/ audio/
    manifest.csv
  data/
    classes/ skills/ items/ enemies/ quests/ zones/ loot/
  scenes/
    boot/ menus/ world/ player/ enemies/ npc/ dungeons/ ui/
  scripts/
    core/ gameplay/ combat/ inventory/ quests/ world/ ai/
    networking/ persistence/ ui/ audio/ input/ tools/
  server/
    config/ scripts/ migrations/
  tests/
    unit/ integration/ multiplayer/ performance/
  tools/ci/
  docs/
  .github/workflows/
```

## Autoloads (solo si justifican responsabilidad global)

- `GameState`: modo actual, escena, transición, configuración no persistente.
- `ContentDB`: carga/valida definiciones de clases/items/skills/quests.
- `AudioManager`: buses y reproducción.
- `LocaleManager`: traducciones.
- `SaveService`: solo modo offline local; online consulta a servidor.
- `NetworkClient`: cliente de red; no duplicar la autoridad del servidor.

No hacer un Autoload monolítico que conozca todos los sistemas.

## Capas

1. **Data:** definiciones inmutables (Resource/JSON con schemas y validación).
2. **Domain:** reglas sin depender de UI/escenas, ej. cálculo de daño/loot/progreso.
3. **Application:** casos de uso, ej. equipar item, aceptar quest, entrar a zona.
4. **Presentation:** nodos, animaciones, UI y VFX.
5. **Infrastructure:** red, persistencia, input, audio y plataforma.

## Entidades

- `CharacterDefinition`, `CharacterState`, `ClassDefinition`.
- `SkillDefinition`, `SkillRuntimeState`.
- `ItemDefinition`, `ItemInstance`, `EquipmentState`.
- `EnemyDefinition`, `EnemyRuntimeState`.
- `QuestDefinition`, `QuestProgress`.
- `ZoneDefinition`, `DungeonSeed`, `DungeonRoomDefinition`.
- `WorldInstance`, `PartyState`, `GuildState`.

Separar definición de objeto (plantilla) y objeto concreto en inventario (instancia).

## Input móvil

- Input actions abstractas: move, basic_attack, skill_1..4, dodge, potion, interact, target_next, open_inventory.
- Joystick analógico izquierdo con deadzone configurable.
- Botón de ataque y habilidades en grupo derecho.
- Adaptador de teclado/gamepad para pruebas, no lógica paralela.

## Navegación y enemigos

- NavMesh/NavigationRegion por zona o chunks, bake offline.
- Límite de agentes activos cercano; IA a menor frecuencia fuera de cámara/distancia.
- Máquinas de estado o behavior nodes simples, evitar árboles complejos prematuros.
- Enemigos con estados idle, patrol, alert, chase, telegraph, attack, recover, return, dead.
- El servidor calcula AI y eventos; cliente presenta animaciones.

## Streaming de regiones

- Cada región como escena raíz independiente.
- Puertas/caminos/portal disparan transición asíncrona y loading UI.
- Mantener party/realm; transferir snapshot mínimo de personaje y estado.
- Los assets no usados se descargan de memoria cuando sea seguro.
- La generación procedural de dungeon toma una semilla del servidor, el cliente reconstruye módulos y el servidor conserva estado real.

## Calidad gráfica

Perfiles:
- Bajo: 30 FPS objetivo, resolución render scale 0.65–0.75, sombras dinámicas apagadas o solo una luz/cascada económica, distancia corta, baja densidad de vegetación, partículas reducidas, sin postprocesado pesado.
- Medio: escala 0.8–0.9, una sombra direccional si el móvil la sostiene, densidad normal.
- Alto: escala 1.0, más distancia/partículas/sombras moderadas.
- Adaptativo: iniciar bajo y subir/bajar según frame time/temperatura con histéresis; no oscilar continuamente.

No establecer números finales hasta medir. En Compatibility, los efectos avanzados no disponibles en el renderer no se deben simular con shaders costosos.

## Rendimiento de contenido

- Mallas optimizadas y LOD cuando tengan beneficio real.
- Atlases/materiales compartidos.
- Texturas de personajes/props 256–512 px como base, hero assets hasta 1024 si se justifica.
- Comprimir texturas según target móvil y medir memoria VRAM.
- Evitar materiales transparentes en gran cantidad.
- Vegetación con instancing cuando proceda.
- Limitar partículas y cuerpos físicos.
- Evitar física rígida dinámica para cada objeto decorativo.

## Exportación

El APK se compila en GitHub Actions con export template correspondiente a Godot 4.7.2 y Android SDK/JDK compatibles. Godot documenta OpenJDK 17 y los componentes SDK necesarios; confirmar matriz exacta en workflow al implementarlo. No se comprometen credentials de firma al repo.

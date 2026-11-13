# Fase 1B — Sistema ambiental de Valdeluz

## Alcance

Esta entrega añade una capa reutilizable de atmósfera para la vertical slice sin modificar los sistemas de personaje, combate, inventario, misiones ni progresión. El constructor del bosque sigue siendo el punto de composición; la nueva capa se instancia como hijo propio y se puede reutilizar desde otras regiones.

## Arquitectura

- `DayNightCycle` (`scripts/arpg/environment/day_night_cycle.gd`): reloj independiente del render. Expone hora, etiqueta de reloj y seis periodos: amanecer, mañana, mediodía, atardecer, anochecer y noche. Duración inicial: 24 minutos reales por día de juego. Se puede pausar o sincronizar con una hora externa.
- `WeatherController` (`scripts/arpg/environment/weather_controller.gd`): estado sin dependencia de nodos visuales. Mezcla pesos para despejado, nublado, niebla y lluvia. Permite redirigir una transición sin saltos de estado.
- `EnvironmentController` (`scripts/arpg/environment/environment_controller.gd`): aplica curvas horarias al cielo procedural, luz direccional, luz ambiental, niebla y luces locales. Administra lluvia con partículas CPU limitadas por perfil.
- `TerrainMaterialLibrary` (`scripts/arpg/environment/terrain_material_library.gd`): paleta procedural reutilizable para césped, tierra roja, roderas, caliza, barro, musgo, madera envejecida y hierro forjado.

No se crea un autoload ambiental global: cada región instancia y controla su propio ciclo/clima. El futuro reloj de servidor puede llamar a `set_world_time_hours()` sin conocer la escena del jugador.

## Uso

El constructor ya instancia el controlador. En una región nueva:

```gdscript
var atmosphere := EnvironmentController.new()
atmosphere.name = "EnvironmentController"
atmosphere.day_length_seconds = 1440.0
atmosphere.start_time_hours = 7.25
atmosphere.auto_advance = true
add_child(atmosphere)
```

API pública:

- `set_world_time_hours(hour)`, `get_world_time_hours()`
- `get_day_period()`, `get_day_period_name()`, `get_clock_label()`
- `set_weather(WeatherController.Weather.RAIN)`
- `set_weather_by_name("lluvia")`
- `get_weather_name()`, `get_weather_weight(weather_id)`
- `register_night_light(omni_light, base_energy)`

Las transiciones de clima duran 18 segundos por defecto. Se pueden forzar durante una secuencia narrativa con `set_weather(..., true)`. El reloj avanza continuamente; se puede congelar con `auto_advance = false` y moverlo mediante la API.

## Decisiones para móviles

- Se conserva Compatibility Renderer.
- Una luz direccional para sol/luz lunar; no hay GI dinámica ni niebla volumétrica.
- Sombras dinámicas desactivadas por defecto. Solo se pueden habilitar explícitamente y según el perfil gráfico.
- La lluvia usa `CPUParticles3D`, desactivada cuando el clima no es lluvia y limitada a un máximo de 80 instancias; Low parte del límite de partículas configurado en calidad.
- Faroles locales sin sombras; el controlador interpola su energía durante amanecer/anochecer.
- El terreno usa una malla procedural subdividida con relieve visual suave (máximo aproximado de 12 cm); la colisión permanece estable y plana para no introducir escalones en la navegación.
- Los materiales usan ruido procedural y no incorporan nuevos assets externos ni licencias.

## Añadir clima o regiones

1. Añadir el nuevo estado y su peso en `WeatherController.Weather`.
2. Definir la contribución visual en `EnvironmentController._apply_visual_state()`.
3. Añadir una transición automatizada que compruebe pesos normalizados.
4. Crear una paleta específica en `TerrainMaterialLibrary` sin duplicar el controlador.
5. Registrar faroles u otras luces nocturnas mediante `register_night_light()`.

## Limitaciones actuales

- La noche usa un tono azul profundo y luz direccional fría; todavía no dibuja un disco lunar independiente ni un campo estelar. Se deja para un pase de cielo separado, tras revisar la composición con la cámara real.
- Las nubes se representan por color y niebla; no hay malla de nubes.
- Tormenta eléctrica, relámpagos, viento animado en vegetación, charcos con reflejos, cuevas con presets propios y streaming regional quedan para una fase posterior.
- El perfil gráfico se consulta para el límite de partículas y la opción de sombras; no se mide FPS desde el controlador.
- No se incluye captura de pantalla generada ni se declara validación visual humana o Android físico en esta entrega.

## Evidencia de prueba

Los tests GdUnit4 nuevos cubren el reloj, las seis franjas, el cambio de clima, transiciones, normalización de pesos, API del controlador, faroles y configuración Low sin sombras. Estado antes de CI: **NOT TESTED** localmente (el entorno de trabajo no dispone del ejecutable Godot 4.7.2). El resultado final debe confirmarse con el workflow del repositorio.

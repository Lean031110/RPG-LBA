# ADR-013 — Jerarquía territorial: región de Camagüey y localidad de Verdaluz

- **Estado:** Aprobada como canon territorial por el responsable del proyecto.
- **Fecha:** 2026-11-18.
- **Alcance:** documentación de mundo, narrativa, streaming y direccionamiento de zonas.
- **Rama de trabajo:** `agent/world-hierarchy-camaguey-verdaluz`.

## Contexto

La documentación anterior trataba Valdeluz como si fuera una región completa del mapa. El responsable aclaró que el mundo del juego será mucho mayor y estará compuesto por grandes regiones y localidades cargadas por separado. Camagüey será una de esas regiones amplias; Verdaluz estará situada dentro de Camagüey y será la localidad principal de inicio de la campaña.

La región de Camagüey todavía no tiene un mapa detallado ni una lista aprobada de barrios, pueblos, caminos o puntos de interés. No deben inventarse ni darse por existentes hasta que se diseñen.

## Decisión canónica

La jerarquía territorial queda establecida así:

```text
Mundo de RPG LBA
└── Región de Camagüey
    └── Localidad de Verdaluz
        └── Sectores, calles, edificios y puntos de interés
            (por diseñar y validar)
```

- **Mundo de RPG LBA:** conjunto completo de regiones y territorios explorables. No es un único mapa continuo cargado en memoria.
- **Región de Camagüey:** una región geográfica amplia dentro del mundo. Su extensión, límites, conexiones y subzonas siguen pendientes de diseño.
- **Verdaluz:** localidad ficticia dentro de Camagüey. Es el hogar del prólogo, el punto de partida narrativo y la primera localidad segura del jugador.
- **Subzonas de Verdaluz:** barrios/sectores, calles, interiores y puntos de interés que se definirán en una fase posterior. Esta ADR no les asigna nombres ni dimensiones.

La Habana, el Central de las Ánimas, la Sierra del Juramento, la Ciénaga del Silencio, la Fortaleza del Morro Negro y La Otra Orilla continúan como territorios o escenarios de la campaña según la biblia narrativa. Esta decisión no los ubica automáticamente dentro de Camagüey.

## Reglas de contenido y continuidad

1. Usar **Verdaluz** como nombre canónico de la localidad inicial en textos nuevos y documentación vigente.
2. El título de campaña se actualiza a **El Eco de Verdaluz**.
3. Camagüey no equivale al mundo completo ni a una única escena jugable.
4. No rellenar el mapa de Camagüey con barrios, monumentos, carreteras o edificios no aprobados.
5. Mantener los nombres internos de escenas, scripts, recursos, IDs de misiones y rutas existentes durante esta actualización documental. Una migración técnica de nombres requerirá inventario de referencias, pruebas y una tarea separada.
6. Los nombres persistentes deben ser IDs estables independientes del texto visible y de la traducción.

## Regla técnica de zonas

La región macro y la unidad cargable no tienen por qué ser lo mismo:

- `world_id`: mundo/realm persistente.
- `region_id`: región geográfica macro, por ejemplo `camaguey`.
- `zone_id`: zona/escena jugable cargada en ese momento, por ejemplo la zona de la localidad de Verdaluz.
- `instance_id`: instancia aislada de mazmorra o evento.

Cada zona jugable se carga como escena independiente mediante transición asíncrona. El cliente no debe cargar toda Camagüey ni todo el mundo al entrar en Verdaluz. El servidor conserva la autoridad del estado y valida las transferencias entre zonas. La implementación concreta debe seguir la arquitectura de Godot y las pruebas existentes; esta ADR no afirma que el streaming completo ya esté implementado.

## Consecuencias

- Se corrige la jerarquía narrativa sin ampliar artificialmente el alcance de la Fase 5.
- Verdaluz conserva su función de localidad inicial segura.
- Camagüey queda registrada como región macro pendiente de diseño.
- Se preservan rutas internas antiguas para evitar romper escenas y recursos existentes.
- Los futuros mapas, misiones y datos de zona deberán referenciar la jerarquía con IDs estables.

## Verificación requerida para futuras fases

- Un mapa macro de Camagüey aprobado antes de añadir sus subzonas.
- Un catálogo de zonas con IDs, límites, conexiones, puntos de entrada/salida y requisitos de carga.
- Pruebas de transición entre zonas, descarga de recursos y recuperación de sesión.
- Prueba multijugador de transferencia de grupo/servidor sin duplicar ni perder estado.
- Revisión humana de la geografía y de la representación visual de Verdaluz.

## Fuera de alcance de esta ADR

No crea geometría 3D, edificios, texturas, calles, misiones nuevas ni contenido jugable. Tampoco cambia el motor, el renderer, el protocolo de red, los límites de jugadores ni el sistema de persistencia.

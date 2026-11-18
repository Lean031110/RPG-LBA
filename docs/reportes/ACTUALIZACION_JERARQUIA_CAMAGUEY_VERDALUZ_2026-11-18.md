# Informe de cambios — Jerarquía territorial Camagüey / Verdaluz

- **Fecha:** 2026-11-18
- **Rama:** `agent/world-hierarchy-camaguey-verdaluz`
- **Base:** `main` en `e1d415b8a2fd1439736a4c899b309a76085fae29`
- **Tipo de entrega:** reconciliación de canon y documentación; no incluye geometría 3D ni cambios de gameplay.
- **Estado:** cambios publicados en la rama; pendientes de revisión y CI del Pull Request.

## 1. Objetivo

Corregir la representación del mapa para que la documentación no trate Verdaluz como una región independiente ni confunda Camagüey con el mundo completo. El mundo de RPG LBA es amplio y se compone de grandes regiones; Camagüey es una de ellas y Verdaluz es una localidad dentro de Camagüey.

## 2. Canon territorial adoptado

```text
Mundo de RPG LBA
└── Región de Camagüey
    └── Localidad de Verdaluz
        └── Sectores, calles, edificios y POI (pendientes de diseño)
```

- **Camagüey:** región macro dentro del mundo. Su mapa detallado, límites, conexiones y asentamientos secundarios siguen sin estar definidos.
- **Verdaluz:** localidad ficticia dentro de Camagüey, hogar del prólogo y punto inicial seguro.
- **Mundo global:** incluye otras regiones y escenarios de campaña; Camagüey no es el mapa completo.
- No se añadieron barrios, calles, monumentos, edificios ni POI nuevos de Camagüey. Los detalles de la expansión urbana de Verdaluz también quedan para diseño posterior.
- El título de campaña en la documentación vigente se normalizó a **El Eco de Verdaluz**.

## 3. Cambios realizados por archivo

| Archivo | Cambio |
|---|---|
| `AGENTS.md` | Se actualizó el canon creativo y las reglas para que los agentes respeten Camagüey → Verdaluz y no inventen subzonas. |
| `README.md` | Se actualizó el nombre visible de la campaña y se explicó que Verdaluz está dentro de Camagüey. Se conservaron nombres de ramas y artefactos históricos. |
| `docs/00_BRIEF_MAESTRO.md` | Se alineó la descripción del género con la visión cubana y se añadió la jerarquía del mundo. |
| `docs/01_GDD.md` | Se corrigió la localidad inicial y se añadió una sección de jerarquía territorial y carga independiente. |
| `docs/04_MUNDO_DUNGEONS.md` | Verdaluz dejó de figurar como Región 0; ahora aparece como localidad inicial dentro de Camagüey. Las demás entradas se clasifican como zonas de exploración/campaña. |
| `docs/05_MULTIJUGADOR_Y_SERVIDOR.md` | Se separaron los identificadores `region_id` y `zone_id`, y se explicó cómo conviven región macro, zona cargada e instancia. |
| `docs/06_ARQUITECTURA_GODOT.md` | Se documentó que la unidad de streaming es la zona jugable/escena, no necesariamente toda la región macro. |
| `docs/narrativa/00_BIBLIA_DEL_MUNDO_Y_HISTORIA.md` | Se actualizó el nombre de la localidad y se anidó Verdaluz bajo la región de Camagüey. |
| `docs/narrativa/01_MISIONES_Y_CADENAS.md` | Se normalizaron las referencias narrativas a Verdaluz y el título de campaña. |
| `docs/AGENT_BRIEFING_VISION_CUBANA.md` | Se añadió la jerarquía vigente y la prohibición de inventar geografía no aprobada. |
| `docs/02_NARRATIVA_Y_MISIONES.md` | Se marcó como resumen histórico/superado porque contradice el canon creativo vigente. No se borró su contenido. |
| `docs/README.md` | Se añadió el ADR-013 y se retiró un enlace a una biblia visual que no existe en la rama consultada. |
| `docs/DECISIONS/ADR-013_jerarquia_mundo_camaguey_verdaluz.md` | Se registró la decisión canónica, las reglas técnicas, consecuencias y verificaciones futuras. |
| Este informe | Registro detallado de alcance, decisiones, archivos y estado de pruebas. |

## 4. Decisiones técnicas preservadas

La actualización no cambia el motor ni la arquitectura aprobada:

- Godot 4.7.2 Standard, GDScript y Compatibility Renderer se mantienen.
- El mundo no se carga como un mapa único en memoria.
- `world_id` identifica el mundo/realm.
- `region_id` identifica la región geográfica macro, por ejemplo `camaguey`.
- `zone_id` identifica la zona/escena jugable actualmente cargada, por ejemplo la localidad de Verdaluz.
- `instance_id` identifica una instancia separada de mazmorra o evento.
- La transferencia entre zonas debe preservar el estado mínimo del personaje y del grupo y mantener la autoridad del servidor.
- Los límites actuales de multijugador no se amplían: la prueba inicial sigue siendo 2 clientes; el MVP apunta a 4 jugadores por party/zona; 10 es objetivo condicionado a benchmark.

## 5. Compatibilidad y nombres internos

Se conservaron rutas técnicas históricas como:

- `scenes/arpg/valdeluz/`
- `scripts/arpg/level/valdeluz_slice.gd`
- `scripts/arpg/level/valdeluz_builder.gd`
- `class_name ValdeluzSlice` y `class_name ValdeluzBuilder`

Estos nombres son identificadores internos existentes, no el nombre visible canónico. Renombrarlos en esta tarea habría requerido migrar referencias de escenas, scripts, recursos, pruebas, CI y posibles IDs guardados. Se evita esa migración para no introducir regresiones. Una futura limpieza técnica debe hacerse en una rama separada con inventario de referencias y pruebas completas.

## 6. Verificaciones realizadas

| Verificación | Resultado |
|---|---|
| Rama creada desde `main` | **PASS** — rama independiente `agent/world-hierarchy-camaguey-verdaluz`. |
| Base de la rama | **PASS** — `main` estaba en `e1d415b8a2fd1439736a4c899b309a76085fae29` al iniciar. |
| Existencia del ADR-013 en el árbol | **PASS**. |
| Lectura de los 13 documentos modificados | **PASS** — GitHub devolvió el contenido actualizado en la rama. |
| Enlaces relativos a archivos | **PASS con nota** — los enlaces rotos detectados son referencias intencionales a carpetas (`DECISIONS/`, `auditoria/`, `reportes/`, `kit/`), no archivos inexistentes. Se retiró un enlace a una biblia visual ausente. |
| Importación Godot / headless | **NOT TESTED** — cambios documentales; no se ejecutó un runtime Godot en este entorno. |
| GdUnit, lint, smoke y multijugador | **NOT TESTED** — deben ejecutarse mediante CI en el PR. |
| Android físico, APK y FPS | **NOT TESTED** — fuera del alcance de esta reconciliación documental. |
| Mapa 3D de Camagüey / Verdaluz | **NOT IMPLEMENTED** — esta entrega fija el canon; no genera ni modifica geometría 3D. |

## 7. Pendientes posteriores

1. Diseñar y aprobar el mapa macro de Camagüey antes de crear contenido geográfico adicional.
2. Diseñar Verdaluz como localidad jugable: sectores, calles, manzanas, edificios, interiores, caminos y puntos de interés.
3. Convertir el catálogo de lugares en datos con IDs estables y conexiones explícitas.
4. Implementar o completar el streaming de zonas y probar descarga de recursos y transferencias.
5. Ejecutar CI completa y revisión humana del PR.
6. Si se decide renombrar las rutas internas `valdeluz`, hacerlo como migración separada.

## 8. Criterio de cierre

Esta fase documental se considera lista para revisión cuando el PR muestra la jerarquía de forma coherente en GDD, biblia, mundo, arquitectura y reglas de agentes. No se considera una entrega de mapa, entorno 3D ni streaming funcional hasta que esos componentes tengan implementación y pruebas verificables.

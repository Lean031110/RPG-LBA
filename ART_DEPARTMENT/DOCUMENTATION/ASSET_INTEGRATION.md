# ASSET_INTEGRATION.md — Guía de integración para el agente principal

## Regla de oro

**Consulta el catálogo**:
`ART_DEPARTMENT/AI_ASSET_FACTORY/catalog/assets_manifest.json`
Los IDs y rutas son estables. Si necesitas mover algo, dilo en un PR:
el catálogo se actualiza y se comunica (mandato §12).

Resumen rápido por recurso (todo en campos del manifiesto):

| Campo | Significado |
|---|---|
| `id` / `ruta` | identificador estable y ruta relativa al repo |
| `categoria` | `texture/<tipo>`, `model/<cat>`, `material/<uso>` |
| `resolucion` / `poligonos` / `vertices` | presupuesto del recurso |
| `materiales` / `materiales_detalle` | materiales embebidos en el GLB |
| `escala` | 1 unidad GLB = 1 metro (Godot: 1 m = 1 unidad) |
| `pivote` | base en origen (y=0), +Y arriba, frente −Z |
| `colisiones` | caja envolvente sugerida (p.ej. "caja simple 2.10x3.20x2.50 m") |
| `lod` | rutas de variantes LOD (vacío en el primer lote: todo low-poly) |
| `perfil` | MOBILE / BALANCED / HIGH con el que se generó |
| `estado` | `validated` (producción local) / `published` (tras el PR) |
| `validacion` | informe JSON por recurso (checks PASS/FAIL/SKIPPED) |
| `procedencia` / `licencia` | generación procedural propia / MIT del proyecto |

## Dónde están los recursos

```
assets/models/{vegetation,rocks,urban,furniture,architecture,buildings,objects}/
assets/environment/textures/{ground,stone,concrete,wood,metal,tiles,vegetation,water}/
assets/materials/
```

## Modelos 3D (GLB) en Godot 4

1. Arrastra el `.glb` al proyecto (o copia la carpeta): Godot importa con el
   plugin glTF y crea `MeshInstance3D` + `StandardMaterial3D` desde el
   `pbrMetallicRoughness` embebido. Los `.import` los genera tu editor
   (la fábrica NO los fabrica a mano para no inventar UIDs).
2. Escala: los modelos están en metros; en Godot 1 m = 1 unidad →
   escala 1.0 salvo decisión artística.
3. Pivote en la base: al soltar sobre un suelo queda apoyado; rota libremente.
4. Colisión sugerida: el campo `colisiones` del catálogo trae la caja
   envolvente; para StaticBody3D usa "Create Convex Collision Simplified"
   (los modelos son low-poly: la convexa es fiel y barata, apta para móvil).
5. Draw calls: las piezas están **fusionadas por material** dentro de cada
   GLB (p.ej. la palma real = 3 nodos, la casa = 6-9).

## Texturas PBR

Cada textura son 6 PNG con el mismo ID (`assets/environment/textures/...`):

| Archivo | Mapa Godot |
|---|---|
| `*_albedo.png` | `albedo_texture` (y `albedo_color` = blanco) |
| `*_normal.png` | `normal_enabled` + `normal_texture` (`normal_scale` a gusto) |
| `*_roughness.png` | `roughness_texture` (modo canal correcto) |
| `*_metallic.png` | `metallic_texture` |
| `*_ao.png` | `ao_light_affect` + `ao_texture` (opcional) |
| `*_height.png` | no usar en Compatibility Renderer salvo justificado |

Todas son **seamless** (tileables): UV repetida sin costuras. En perfil Low,
usa 512 (MOBILE) — se pueden regenerar a esa resolución con la fábrica.

## Materiales (`assets/materials/*.json`)

Definición lista para crear el StandardMaterial3D a mano o por script:
`albedo_color`, `roughness`, `metallic`, `texturas` (rutas `res://`) y
`normal_scale`. No generamos `.tres` a mano porque los UID los crea Godot
(alternativa programática: `ResourceSaver` desde un script del editor).

## Pedir más recursos

- Añade trabajos a la cola (ver GENERATION_GUIDE.md) y ejecuta el workflow
  **Asset Factory** en la rama `feature/ai-art-department`, o
  localmente `cli.py process --limit 3`.
- Las categorías de generadores disponibles:
  `cli.py status` + `generators/models/*` (naturaleza, arquitectura, urbano,
  mobiliario, edificios, objetos) y `generators/textures/textures.py` (19 tipos).

## Estado actual (primer lote — 93 recursos)

- 21 texturas (césped, tierra roja, barro, arena, caliza, adoquín, granito,
  ladrillo, estuco×4, hormigón, asfalto, madera×2, zinc, tejas, mármol,
  agua, follaje).
- 62 modelos (10 vegetación, 10 rocas, 10 urbano, 10 mobiliario,
  10 arquitectura, 7 edificios modulares, 5 objetos).
- 10 materiales.
- Todos con informe de validación PASS y preview en `ART_DEPARTMENT/PREVIEWS/`.

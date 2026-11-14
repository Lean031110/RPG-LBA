# GENERATION_GUIDE.md — Guía de generación

## Cómo funciona la fábrica

```
cola (asset_queue.json)                    catálogo (assets_manifest.json)
   pending → processing → completed → validated → published / failed
        └── dispatch() ──→ generador ──→ AssetManager.publish()
                                             ├── clasifica categoría
                                             ├── nombre/ID estables (prefijo + índice)
                                             ├── deduplica por hash (rechaza copias)
                                             └── registra metadatos completos
                        └── preview ──→ validadores ──→ informe JSON por recurso
```

Los generadores **nunca** deciden dónde guardar (mandato §10): entregan
archivos temporales + metadatos y el Asset Manager clasifica, nombra
(`tex_<categoría>_<nombre>_001`, `mdl_<categoría>_<nombre>_001`,
`mat_<nombre>_001`) y registra.

## Solicitar recursos (enqueue)

### Opción A: preset
```bash
python ART_DEPARTMENT/AI_ASSET_FACTORY/cli.py preset first-batch   # 93 recursos
```

### Opción B: cola propia (plantillas en `templates/`)
Crea trabajos JSON con la estructura de `templates/job_texture.json` /
`job_model.json` y añádelos con:
```bash
python -c "
import sys; sys.path.insert(0, 'ART_DEPARTMENT/AI_ASSET_FACTORY')
from core.queue_manager import QueueManager
from core.utils import stable_seed
q = QueueManager()
q.add_job('job_9001', category='texture', name='arena_blanca',
          generator='texture:sand', resolution=1024, priority=2,
          params={'name': 'arena_blanca', 'wear': 0.2})
"
python ART_DEPARTMENT/AI_ASSET_FACTORY/cli.py process --limit 3
```

Estados: `pending → processing → completed → validated → published`
(`/ failed` tras 3 intentos). La semilla determina variaciones reales.

## Añadir un nuevo generador

### Textura nueva (o variante)
1. Escribe el builder en
   `generators/textures/textures.py` (firma `def mi_textura(rng, size, params)`),
   devolviendo `height`, `albedo`, `roughness_base`, `roughness_mod`,
   `metallic_base`/`metallic_mask`, `normal_strength`, `ao_gain`.
   Usa los primitivos periódicos de `noise.py` (todo es seamless por
   construcción; coeficientes de seno ENTEROS para envolver).
2. Regístralo en `TEXTURE_BUILDERS` (nombre → builder, categoría).
3. Añádelo a la cola y procesa.

### Modelo nuevo
1. Escribe el builder en el módulo de su categoría
   (`nature.py`, `urban.py`, `furniture.py`, `architecture.py`,
   `buildings.py`, `objects.py`): firma `def build_X(b, p, rng)` donde
   `b` es el backend con `b.mat()` y `b.part()` (primitivas Y-up en metros).
2. Regístralo en la tabla `*_BUILDERS` de su módulo.
3. Encola con `generador = "model:build_X"`.

Convención del DSL geométrico: **Y-up, metros, pivote en la base (y=0),
frente −Z**; cilindros centrados, conos con base en `location` y punta +Y.

### Variaciones reales (prohibido duplicar)
- Distinta `semilla` → jitter de proporciones/disposición (modelo) o ruido
  distinto (textura).
- Distintos `params` (color, wear, floors, width...) → geometría/materiales
  distintos; el dedupe por hash rechaza contenidos idénticos.

## Perfiles de calidad (config/profiles.json)

| Perfil | Texturas | Tris máx (prop) | Segmentos | LOD |
|---|---|---|---|---|
| MOBILE | 512 | 900 | 8 | 0 |
| BALANCED | 1024 | 2200 | 12 | 1 |
| HIGH | 2048 | 5000 | 16 | 1 |

Seleccionables por trabajo (`perfil`) o al procesar (`--profile`).

## Motores futuros (GPU)

`integrations/future_engines.py` contiene las pasarelas ComfyUI/SDXL y
Hunyuan3D **desactivadas por diseño** (mandato §4). Para activarlas:
verificar hardware, implementar la llamada real y registrarlas en
`generators/registry.py`; la salida debe pasar los mismos validadores.

# TROUBLESHOOTING.md — Errores comunes y reanudación

## Reanudar trabajos interrumpidos

La cola persiste su estado en
`ART_DEPARTMENT/AI_ASSET_FACTORY/catalog/asset_queue.json`.

- Una ejecución de Actions/local interrumpida deja trabajos en `processing`;
  al arrancar de nuevo, `process` llama a `reset_stale()` y los devuelve a
  `pending` (umbral: 45 min, config `stale_processing_minutes`).
- Forzar reanudación manual:
  ```bash
  python -c "
  import sys; sys.path.insert(0, 'ART_DEPARTMENT/AI_ASSET_FACTORY')
  from core.queue_manager import QueueManager
  q = QueueManager()
  print('devueltos a pending:', q.reset_stale())
  "
  ```
- Un trabajo `failed` agotó sus 3 intentos: mira `ultimo_error` en la cola
  y corrige antes de reintentar. Para reintentarlo tras corregir:
  pon su `estado` a `pending` y `intentos` a 0.

## Síntomas y soluciones

| Síntoma | Causa probable | Solución |
|---|---|---|
| `KeyError: 'path'` en scripts propios | el campo del manifiesto es `ruta` | usar `entry["ruta"]` / `entry["files"]` |
| `can't multiply sequence by non-int` | multiplicar una tupla de color por float | `tuple(c*k for c in COLOR)` |
| Validación `seamless_bordes` FAIL | coeficientes de seno no enteros o retícula impar | ver `noise.py`: todo periódico usa enteros/hiladas impares |
| Validación `roughness_variada` FAIL | modulación del builder constante | el generador ya mezcla fbm propia; si añades un builder nuevo, da un `roughness_mod` con variación |
| Validación `pivote_base` FAIL | primitiva por debajo de y=0 | DSL: pivote en base; sube el `location` |
| `Invalid RGBA argument` en previews | color numpy.uint8 de trimesh | ya corregido (conversión defensiva en preview.py) |
| GLB se ve rotado 90° | el DSL es Y-up; primitivas trimesh/bpy son +Z | ya corregido (pre-rotación + from_pydata con flip) — si añades backend nuevo, respétalo |
| bpy no instala | Python ≠ 3.11 exacto | usa trimesh (fallback automático) o crea venv 3.11 |
| Actions: "sin cambios que guardar" | lote vacío (cola agotada o bloqueada) | `cli.py status`; si hay materiales en WAIT, produce primero sus texturas |
| Material en `pending` para siempre | su `texture_id` no existe | genera la textura o corrige el ID del trabajo |

## Errores conocidos (transparencia)

- La comprobación headless de Godot está preparada pero **SKIPPED** sin
  binario en PATH (reportada como NOT TESTED, jamás como PASS).
- El backend bpy/Blender no se ejecutó en el sandbox de desarrollo
  (Python 3.12): se verificó trimesh; bpy corre en CI con Python 3.11.

## Log de una ejecución sana

```
[OK] mdl_buildings_house_colonial_01_001 -> assets/models/buildings/... (0.1s, PASS)
[DONE] 3 recursos procesados. Cola: {'pending': 87, 'validated': 6, ...}
```
Los informes por recurso están en
`ART_DEPARTMENT/AI_ASSET_FACTORY/catalog/validation_reports/<id>.json`.

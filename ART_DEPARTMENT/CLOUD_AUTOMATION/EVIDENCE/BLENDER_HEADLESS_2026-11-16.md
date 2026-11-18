# Evidencia: Blender headless procesa un asset de prueba y exporta un GLB verificable

**Fecha:** 2026-11-16 (UTC)
**Criterio de aceptación §17.10:** Blender headless procesa un asset de prueba y exporta un GLB verificable.
**Resultado:** **PASS** (dos assets, ejecutado fuera de GitHub Actions en un entorno Linux limpio; el mismo contrato es reproducible en Actions con `bpy==4.2.0`).

## Entorno y binarios (fuentes oficiales, versión fijada)

| Componente | Valor |
|---|---|
| Blender | 4.2.0 (hash a51f293548ad, build 2024-07-16), `blender-4.2.0-linux-x64.tar.xz` desde https://download.blender.org/release/Blender4.2/ |
| SHA-256 del tarball | `4f4fd7646af01f6fee9d420408318381a6e52571268eb7cf9cd5033bd9e7a359` |
| Script | `scripts/ci/blender_headless_smoke.py` (commiteado; funciona igual bajo `blender --background --python` que con el módulo pip `bpy`) |
| Verificador independiente | `trimesh` + `pygltflib` (pip) |

## Comandos exactos

```bash
blender --background --python scripts/ci/blender_headless_smoke.py -- \
  --input assets/models/vegetation/mdl_vegetation_palm_royal_001.glb \
  --output /tmp/blender_out/mdl_vegetation_palm_royal_001_processed.glb

blender --background --python scripts/ci/blender_headless_smoke.py -- \
  --input assets/models/urban/mdl_urban_bollard_001.glb \
  --output /tmp/blender_out/mdl_urban_bollard_001_processed.glb
```

## Resultados (línea BLENDER_SMOKE_REPORT del propio script)

| Asset | Import (objetos/vértices/tris/materiales) | Procesado | Export |
|---|---|---|---|
| `mdl_vegetation_palm_royal_001` | 3 / 576 / 588 / 3 (coincide con el catálogo) | −252 vértices duplicados, normales recalculadas hacia fuera, triangulación | 324 vértices, 588 tris, 3 materiales — GLB 43 KB |
| `mdl_urban_bollard_001` | 3 / 174 / 336 / 3 | sin duplicados que fusionar; normales + triangulación | 174 vértices, 336 tris, 3 materiales — GLB 15 KB |

## Verificación independiente (trimesh, fuera de Blender)

- `mdl_vegetation_palm_royal_001_processed.glb`: 3 geometrías, 588 caras, materiales `m_madera`, `m_manigua`, `m_manigua_claro` preservados, base en Y=0 (glTF Y-up), altura 10.361 m. SHA-256 `520efb794a7996cc85106825d589e1116aa9b32142e6bdbeb4f970172615a133`.
- `mdl_urban_bollard_001_processed.glb`: 3 geometrías, 336 caras, materiales `m_caliza`, `m_carbon`, `m_petroleo` preservados, base en Y=0, altura 0.959 m. SHA-256 `6c5e04806c5615bcf66f1b2a7c8c20f238d7359094c0fc56fb564e9cf7ab7fc8`.

## Procesamiento aplicado (contrato de normalización de la fábrica)

1. Importación glTF 2.0 del GLB original del catálogo.
2. `remove_doubles` (umbral 1e-5), `normals_make_consistent(inside=False)`, triangulación de quads/ngons.
3. Base del asset en el suelo (desplazamiento uniforme del scene-bbox mínimo a 0).
4. Exportación GLB 2.0 (`export_apply`, materiales EXPORT).

## Limitaciones honestas

- Los GLB de salida viven solo en /tmp de la máquina de pruebas: no se añadieron assets nuevos al catálogo (política de lotes: 1–3 con revisión).
- El humo de pipeline no sustituye la revisión visual humana ni la prueba física en dispositivo.
- La re-ejecución en GitHub Actions queda registrada por los workflows de fábrica (`asset-factory.yml` instala `bpy==4.2.0` con fallback a trimesh).

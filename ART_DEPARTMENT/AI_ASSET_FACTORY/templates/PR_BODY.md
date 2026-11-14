# AI Art Department: fábrica de recursos 3D + primer lote

## 1. Objetivo y alcance

Departamento autónomo de producción visual para **RPG LBA — Las Cenizas de Lythara**
(Godot 4.7). Implementa la **AI Asset Factory**: generadores procedurales de
texturas PBR seamless y de modelos 3D estilizados (gótico caribeño 1953), cola
de trabajos reanudable, Asset Manager con catálogo estable, validación
automática y workflows de GitHub Actions compatibles con GitHub Free.
**No toca gameplay, escenas, scripts ni configuración del motor.**

## 2. Archivos cambiados (solo adiciones)

- `ART_DEPARTMENT/` — fábrica completa (core, generadores, validadores,
  procesadores, integraciones, config, templates, tests, catálogo) +
  DOCUMENTATION + PREVIEWS.
- `assets/models/**` (62 GLB), `assets/environment/textures/**` (21 juegos ×
  6 mapas PBR), `assets/materials/**` (10 definiciones JSON).
- `.github/workflows/asset-{factory,validation,publication}.yml` (nuevos; los
  workflows existentes NO se modifican).
- `ARTIFACTS/` (gitignored: solo staging temporal).

## 3. Decisiones y dependencias

- **Sin GPU**: generación 100% CPU (NumPy/Pillow para texturas; trimesh o
  bpy/Blender local para geometría). Integraciones futuras (ComfyUI/Hunyuan3D)
  quedan implementadas como stubs DESACTIVADOS.
- **Canon artístico**: paleta gótico-caribeña de
  `docs/direccion-artistica/03_DIRECCION_ARTISTICA_Y_UX.md`. La contradicción
  brief-vs-canon está documentada y resuelta en `INITIAL_AUDIT.md §4`.
- Python 3.11 en CI (para `bpy`); local se usó 3.12 + trimesh (backend
  registrado por recurso en el catálogo).
- Sin Git LFS (no configurado en el repo; el lote pesa ~21 MB).

## 4. Pruebas ejecutadas (comandos exactos)

```
python3 -m pytest ART_DEPARTMENT/AI_ASSET_FACTORY/tests/ -q   # 41 passed
python3 ART_DEPARTMENT/AI_ASSET_FACTORY/cli.py validate        # 93 recursos, 0 fallos, manifest PASS, duplicados PASS
python3 ART_DEPARTMENT/AI_ASSET_FACTORY/cli.py preview --all   # 93 previews
python3 ART_DEPARTMENT/AI_ASSET_FACTORY/cli.py gallery
```

## 5. GitHub Actions

Los tres workflows se disparan manualmente (`workflow_dispatch`) desde la
pestaña Actions eligiendo la rama `feature/ai-art-department`:
`Asset Factory (produccion)`, `Asset Validation`, `Asset Publication`.
El ciclo nocturno está desactivado por defecto (variable de repo
`FACTORY_CRON_ENABLED`). En esta PR se reportan resultados de ejecución
LOCAL verificables; los identificadores de ejecución de Actions se
añadirán al dispararlos.

## 6. Resultado real

- Producción del primer lote: **PASS** (93/93 recursos validados: 21 texturas,
  10 materiales, 62 modelos; 0 fallos; 0 duplicados).
- Suite pytest: **PASS** (41/41).
- Comprobación con Godot headless: **SKIPPED / NOT TESTED** (sin binario Godot
  en el entorno de desarrollo; workflow preparado para activarla).

## 7. Limitaciones que requieren prueba humana o hardware físico

- Revisión visual humana de capturas con la cámara real del juego (canon §10).
- Importación final en el editor Godot del agente principal (los `.import`
  los genera el editor; la fábrica deliberadamente no los fabrica).
- Rendimiento en Redmi 9C (perfil MOBILE) sin medir en hardware físico.
- El backend bpy/Blender se ejecuta en CI (Python 3.11); en el sandbox de
  desarrollo solo se verificó el backend trimesh.

## 8. Instrucciones para el agente principal

Ver `ART_DEPARTMENT/DOCUMENTATION/ASSET_INTEGRATION.md` y el catálogo
`ART_DEPARTMENT/AI_ASSET_FACTORY/catalog/assets_manifest.json`
(IDs y rutas estables). PRODUCTION_STATUS.md se actualiza en cada lote.

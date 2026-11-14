# ART_DEPARTMENT — Departamento de Producción 3D de RPG-LBA

Fábrica autónoma de recursos visuales (texturas PBR seamless + modelos 3D
estilizados) para **RPG LBA — Las Cenizas de Lythara** (Godot 4.7), con
estética **gótico caribeña 1953** según el canon del repositorio
(`docs/direccion-artistica/03_DIRECCION_ARTISTICA_Y_UX.md`).

## Qué hay aquí

| Carpeta | Contenido |
|---|---|
| `AI_ASSET_FACTORY/` | La fábrica: core (cola, Asset Manager, catálogo), generadores (texturas procedurales + 62 modelos paramétricos), validadores, previews, tests, CLI |
| `DOCUMENTATION/` | Auditoría inicial + 8 documentos de uso (abajo) |
| `PREVIEWS/` | Galería HTML + una imagen por recurso (se regenera sola) |
| `TEXTURES/ MATERIALS/ MODELS_3D/ ENVIRONMENTS/` | Punteros a la ubicación canónica en `assets/` (evita duplicar binarios en Git) |

## Dónde están los recursos (para el agente principal)

- Modelos: `assets/models/<categoría>/<id>.glb` — 62 modelos en 7 categorías.
- Texturas: `assets/environment/textures/<tipo>/<id>_<mapa>.png` — 21 juegos
  de 6 mapas PBR (albedo/normal/roughness/metallic/AO/height).
- Materiales: `assets/materials/<id>.json` — 10 definiciones Godot.
- **Catálogo estable (fuente de verdad):**
  `ART_DEPARTMENT/AI_ASSET_FACTORY/catalog/assets_manifest.json`
  (ID, ruta, resolución, polígonos, materiales, colisión, perfil,
  procedencia, licencia, estado de validación... por recurso).

## Uso rápido

```bash
# 1. instalar (local o CI)
pip install -r ART_DEPARTMENT/AI_ASSET_FACTORY/requirements.txt
# opcional (CI, Python 3.11): pip install bpy==4.2.0

# 2. sembrar la cola del primer lote (ya ejecutado: 93/93 validados)
python ART_DEPARTMENT/AI_ASSET_FACTORY/cli.py preset first-batch

# 3. producir en lotes pequeños (1-5 por ejecución; reanudable)
python ART_DEPARTMENT/AI_ASSET_FACTORY/cli.py process --limit 3

# 4. validar / previews / galería / estado
python ART_DEPARTMENT/AI_ASSET_FACTORY/cli.py validate
python ART_DEPARTMENT/AI_ASSET_FACTORY/cli.py preview --all
python ART_DEPARTMENT/AI_ASSET_FACTORY/cli.py gallery
python ART_DEPARTMENT/AI_ASSET_FACTORY/cli.py status
```

## Documentación

1. `DOCUMENTATION/INITIAL_AUDIT.md` — auditoría del repo, límites y decisiones.
2. `DOCUMENTATION/INSTALLATION.md` — instalación de la fábrica.
3. `DOCUMENTATION/GENERATION_GUIDE.md` — añadir generadores y pedir recursos.
4. `DOCUMENTATION/ASSET_INTEGRATION.md` — cómo integrar los recursos (agente principal).
5. `DOCUMENTATION/GODOT_COMPATIBILITY.md` — convenciones para Godot 4.
6. `DOCUMENTATION/GITHUB_ACTIONS.md` — workflows y cuotas de GitHub Free.
7. `DOCUMENTATION/TROUBLESHOOTING.md` — errores comunes y reanudación.
8. `DOCUMENTATION/PRODUCTION_STATUS.md` — estado de producción (vivo).

## Reglas de convivencia (AGENTS.md)

- Rama propia + PR; nunca push a `main`.
- No se toca gameplay/scripts/escenas/config del motor.
- IDs y rutas del catálogo **estables**: si algo debe moverse, se documenta
  en el PR y se comunica (mandato §12).
- Todo recurso lleva procedencia y licencia registradas (aquí: generación
  procedural propia, MIT del proyecto).

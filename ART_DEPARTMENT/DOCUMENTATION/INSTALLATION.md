# INSTALLATION.md — Instalación de la AI Asset Factory

## Requisitos

- Python **3.11 o 3.12** (3.11 exacto si se quiere `bpy`, el motor Blender).
- Git. Opcional: binario Godot 4.7 para la comprobación headless.
- Sin GPU: toda la generación es CPU (mandato: la primera versión no depende
  de tarjetas gráficas).

## Instalación

```bash
git clone https://github.com/Lean031110/RPG-LBA.git
cd RPG-LBA
git checkout feature/ai-art-department

python -m venv .venv && source .venv/bin/activate   # opcional
pip install -r ART_DEPARTMENT/AI_ASSET_FACTORY/requirements.txt
```

Contenido de `requirements.txt`: `numpy, Pillow, trimesh, pygltflib,
opencv-python-headless, matplotlib, pytest`.

## Motor geométrico (backend)

La fábrica elige automáticamente:

- **Blender (bpy)** — motor principal, requiere **Python 3.11 exacto**:
  ```bash
  pip install bpy==4.2.0
  ```
  Con bpy, la misma API de la fábrica construye los meshes vía Blender Python
  API y exporta GLB con el exportador oficial de Blender (`export_yup`).
- **trimesh** — fallback 100% CPU (instalado con los requirements). Si bpy no
  está, se usa este y se registra en el catálogo (`procedencia.backend`).

Se puede forzar: `cli.py process --backend blender|trimesh|auto`.

## Verificación de la instalación

```bash
python -m pytest ART_DEPARTMENT/AI_ASSET_FACTORY/tests/ -q   # 41 tests
python ART_DEPARTMENT/AI_ASSET_FACTORY/cli.py status          # cola + catálogo
```

## Entornos verificados

- Desarrollo (este informe): Python 3.12.16, sin Blender binario → backend
  trimesh. Librerías: numpy 2.1.3, Pillow 11.3, trimesh 4.11.1, pygltflib
  1.16.5, OpenCV 4.13, matplotlib 3.9.2, pytest 9.0.2.
- CI (GitHub Actions): Python 3.11 + intento de `bpy==4.2.0` con
  `continue-on-error` (si falla, trimesh) — ver GITHUB_ACTIONS.md.

## No subir al repo (ya gitignored)

`.venv/`, `__pycache__/`, `.pytest_cache/`, `ARTIFACTS/staging/`,
`*.blend1`. Los pesos de modelos de IA NO se descargan (mandato §14).

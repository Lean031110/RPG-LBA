"""Resolución central de rutas de RPG-LBA AI Asset Factory.

Todas las rutas se calculan a partir de la raíz del repositorio para que
la fábrica funcione igual en local y en GitHub Actions.
"""
from __future__ import annotations

import os
from pathlib import Path


def repo_root() -> Path:
    """Raíz del repositorio RPG-LBA (contiene project.godot)."""
    env = os.environ.get("RPG_LBA_ROOT")
    if env:
        return Path(env).resolve()
    # Subir desde este archivo: core/ -> AI_ASSET_FACTORY -> ART_DEPARTMENT -> raíz
    here = Path(__file__).resolve()
    return here.parents[3]


ROOT = repo_root()
ART_DEPARTMENT = ROOT / "ART_DEPARTMENT"
FACTORY = ART_DEPARTMENT / "AI_ASSET_FACTORY"

# Catálogo y cola (fuente de verdad para ambos agentes)
CATALOG_DIR = FACTORY / "catalog"
MANIFEST_PATH = CATALOG_DIR / "assets_manifest.json"
QUEUE_PATH = CATALOG_DIR / "asset_queue.json"
REPORTS_DIR = CATALOG_DIR / "validation_reports"

# Producción (interna de la fábrica)
CONFIG_DIR = FACTORY / "config"
TEMPLATES_DIR = FACTORY / "templates"
PREVIEWS_DIR = ART_DEPARTMENT / "PREVIEWS"

# Integración con el juego (carpetas acordadas; ver INITIAL_AUDIT.md §2)
ASSETS = ROOT / "assets"
ASSET_MODELS = ASSETS / "models"
ASSET_TEXTURES = ASSETS / "environment" / "textures"
ASSET_MATERIALS = ASSETS / "materials"
ASSET_ENVIRONMENTS = ASSETS / "environments"

# Artifacts de ejecución (NO almacenamiento permanente, gitignored)
ARTIFACTS = ROOT / "ARTIFACTS"


def ensure_dirs() -> None:
    for p in (
        CATALOG_DIR,
        REPORTS_DIR,
        PREVIEWS_DIR,
        ASSET_MODELS,
        ASSET_MATERIALS,
        ASSET_ENVIRONMENTS,
        ARTIFACTS,
    ):
        p.mkdir(parents=True, exist_ok=True)


def rel(path: Path) -> str:
    """Ruta relativa al repo en formato posix (estable para el catálogo)."""
    return Path(path).resolve().relative_to(ROOT).as_posix()


# Mapa de categorías de la fábrica -> carpeta de modelos en assets/
MODEL_CATEGORY_DIRS = {
    "vegetation": ASSET_MODELS / "vegetation",
    "rocks": ASSET_MODELS / "rocks",
    "urban": ASSET_MODELS / "urban",
    "furniture": ASSET_MODELS / "furniture",
    "architecture": ASSET_MODELS / "architecture",
    "buildings": ASSET_MODELS / "buildings",
    "objects": ASSET_MODELS / "objects",
    "vehicles": ASSET_MODELS / "vehicles",
}

# Mapa de tipos de textura -> carpeta en assets/environment/textures/
TEXTURE_TYPE_DIRS = {
    "stone": ASSET_TEXTURES / "stone",
    "ground": ASSET_TEXTURES / "ground",
    "concrete": ASSET_TEXTURES / "concrete",
    "wood": ASSET_TEXTURES / "wood",
    "metal": ASSET_TEXTURES / "metal",
    "tiles": ASSET_TEXTURES / "tiles",
    "vegetation": ASSET_TEXTURES / "vegetation",
    "water": ASSET_TEXTURES / "water",
}

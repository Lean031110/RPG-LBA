"""Generador de modelos 3D: builder paramétrico -> GLB real.

- Elige backend (blender si hay bpy; trimesh como fallback) y lo registra
  en los metadatos (procedencia.backend).
- Aplica geometría según perfil de calidad (MOBILE/BALANCED/HIGH).
- Calcula colisión simple (caja envolvente) y triángulos.
- Genera LOD1 (segmentos reducidos) solo si el perfil lo pide y supera
  el umbral de triángulos.
"""
from __future__ import annotations

from pathlib import Path

from core import paths
from core.config import Profiles
from generators.models import architecture, buildings, furniture, nature, objects, urban
from generators.models.backends import make_backend
from core.config import resolve_backend

MODEL_BUILDERS: dict[str, dict] = {
    "vegetation": nature.VEGETATION_BUILDERS,
    "rocks": nature.ROCK_BUILDERS,
    "architecture": architecture.ARCHITECTURE_BUILDERS,
    "urban": urban.URBAN_BUILDERS,
    "furniture": furniture.FURNITURE_BUILDERS,
    "buildings": buildings.BUILDING_BUILDERS,
    "objects": objects.OBJECT_BUILDERS,
}


def find_model_builder(name: str):
    for category, table in MODEL_BUILDERS.items():
        if name in table:
            return category, table[name]
    raise KeyError(
        f"Generador de modelo desconocido: {name}. Categorías: "
        + ", ".join(f"{c}({len(t)})" for c, t in MODEL_BUILDERS.items())
    )


def generate_model(name: str, params: dict, seed: int, profile: str = "BALANCED",
                   backend_name: str = "auto", job_id: str = "",
                   staging: Path | None = None):
    import numpy as np

    profiles = Profiles()
    geo = profiles.geometry(profile)
    category, builder = find_model_builder(name)

    backend = make_backend(resolve_backend(backend_name))
    p = dict(params or {})
    p.setdefault("geometry", geo)
    rng = np.random.default_rng(seed)
    info = builder(backend, p, rng)

    stage = staging or (paths.ARTIFACTS / "staging" / (job_id or f"mdl_{name}_{seed}"))
    stage.mkdir(parents=True, exist_ok=True)
    glb_path = stage / "model.glb"
    stats = backend.export_glb(glb_path)
    bounds = stats.get("bounds")
    if bounds is None:
        bounds = [1.0, 1.0, 1.0]
    collision = (f"caja simple {bounds[0]:.2f}x{bounds[1]:.2f}x{bounds[2]:.2f} m "
                 "(convex recomendado en Godot: Mesh -> Create Convex Collision)")

    # LOD opcional (perfil BALANCED/HIGH y geometría no trivial)
    lods = []
    if geo.get("lod_levels", 0) > 0 and stats["triangles"] > 1200:
        lod_geo = dict(geo)
        lod_geo["radial_segments"] = max(5, geo["radial_segments"] // 2)
        lod_geo["sphere_segments"] = (max(5, geo["sphere_segments"][0] // 2),
                                       max(4, geo["sphere_segments"][1] // 2))
        backend2 = make_backend(resolve_backend(backend_name))
        p2 = dict(params or {})
        p2["geometry"] = lod_geo
        builder(backend2, p2, np.random.default_rng(seed))
        lod_path = stage / "model_lod1.glb"
        backend2.export_glb(lod_path)
        lods.append(lod_path)

    from core.asset_manager import Delivery  # import tardío

    return Delivery(
        kind="model",
        category=category,
        name=params.get("name", name),
        description=params.get(
            "description",
            f"Modelo 3D estilizado '{name}' ({category}) paramétrico, "
            f"perfil {profile}, {stats['triangles']} triángulos, "
            f"{stats['materials']} materiales fusionados por material.",
        ),
        files={"glb": glb_path},
        materials=backend.materials_info(),
        params=params,
        seed=seed,
        resolution=None,
        triangles=stats["triangles"],
        vertices=stats["vertices"],
        collision=collision,
        lods=lods,
        profile=profile,
        backend=backend.name,
        extra=info or {},
    )

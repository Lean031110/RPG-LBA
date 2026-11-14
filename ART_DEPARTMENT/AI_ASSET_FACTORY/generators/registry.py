"""Registro de generadores: nombre de cola -> callable ejecutable.

Formato del campo 'generador' de la cola:
  texture:<tipo>     (p.ej. texture:grass_tropical)
  model:<nombre>     (p.ej. model:palm_royal)
  material:<nombre>  (p.ej. material:stucco_coral)
"""
from __future__ import annotations

from typing import Callable

from generators.models.generator import generate_model
from generators.textures.generator import generate_texture
from generators.textures.materials import generate_material


def dispatch(generator: str, params: dict, seed: int, resolution: int | None,
             profile: str, job_id: str, staging=None):
    kind, _, name = generator.partition(":")
    if kind == "texture":
        res = int(resolution or 1024)
        return generate_texture(name, params, seed, res, job_id=job_id, staging=staging)
    if kind == "model":
        return generate_model(name, params, seed, profile=profile, job_id=job_id,
                              staging=staging)
    if kind == "material":
        return generate_material(name, params, seed, profile=profile, job_id=job_id,
                                 staging=staging)
    raise ValueError(f"Generador no reconocido: {generator}")


def known_generators() -> dict[str, list[str]]:
    from generators.models.generator import MODEL_BUILDERS
    from generators.textures.textures import TEXTURE_BUILDERS

    return {
        "texture": sorted(TEXTURE_BUILDERS),
        "model": {cat: sorted(tbl) for cat, tbl in MODEL_BUILDERS.items()},
    }

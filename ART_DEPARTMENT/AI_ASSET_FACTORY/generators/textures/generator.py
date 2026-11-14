"""Generador de texturas: builder -> mapas PBR -> PNGs reales.

Resoluciones soportadas (mandato §7): 256, 512, 1024, 2048.
Seamless garantizado por construcción (ver noise.py).
"""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

from core import paths
from core.utils import stable_seed
from generators.textures import pbr
from generators.textures.textures import TEXTURE_BUILDERS, COLONIAL_FACADES


def _png(path: Path, arr: np.ndarray) -> None:
    if arr.ndim == 3:
        img = Image.fromarray(np.clip(arr * 255.0, 0, 255).astype(np.uint8), mode="RGB")
    else:
        img = Image.fromarray(np.clip(arr * 255.0, 0, 255).astype(np.uint8), mode="L")
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, optimize=True)


def generate_texture(kind: str, params: dict, seed: int, resolution: int,
                     job_id: str = "", staging: Path | None = None) -> "object":
    """Devuelve una Delivery con archivos PNG (albedo/normal/rough/metal/ao/height).

    params: wear, moss, color, scale, rows/cols/ridges/planks (por tipo), etc.
    """
    if kind not in TEXTURE_BUILDERS:
        raise ValueError(f"Tipo de textura desconocido: {kind}. Disponibles: {list(TEXTURE_BUILDERS)}")
    builder, category = TEXTURE_BUILDERS[kind]
    if resolution not in (256, 512, 1024, 2048):
        raise ValueError(f"Resolución no permitida: {resolution}")

    rng = np.random.default_rng(seed)
    fields = builder(rng, resolution, params)

    height = np.clip(np.asarray(fields["height"], dtype=np.float64), 0.0, 1.0)
    albedo = np.clip(np.asarray(fields["albedo"], dtype=np.float64), 0.0, 1.0)
    normal = pbr.height_to_normal(height, fields.get("normal_strength", 1.0))
    ao = pbr.height_to_ao(height, fields.get("ao_gain", 1.0), sigma=max(4.0, resolution / 160.0))

    rough_mod = fields.get("roughness_mod")
    roughness = pbr.build_roughness(fields["roughness_base"], rough_mod)
    if roughness.size == 1:
        roughness = np.full((resolution, resolution), float(roughness.flat[0]))
    # garantizar variación REAL de roughness (nada de mapas constantes):
    # modulación aditiva con fbm periódico propio (semilla derivada distinta);
    # aditiva para que también funcione con bases bajas (agua, mármol)
    from generators.textures.noise import fbm as _fbm
    rng_rough = np.random.default_rng((seed * 7919 + 13) % (2**63 - 1))
    rough_noise = _fbm(rng_rough, resolution, base_cells=6, octaves=5)
    roughness = np.clip(roughness + 0.30 * (rough_noise - 0.5), 0.05, 1.0)

    metal_mask = fields.get("metallic_mask")
    metallic = pbr.build_metallic(fields.get("metallic_base", 0.0), metal_mask)
    if metallic.size == 1:
        metallic = np.full((resolution, resolution), float(metallic.flat[0]))

    stage = staging or (paths.ARTIFACTS / "staging" / (job_id or f"tex_{kind}_{seed}"))
    stage.mkdir(parents=True, exist_ok=True)
    files = {
        "albedo": stage / "albedo.png",
        "normal": stage / "normal.png",
        "roughness": stage / "roughness.png",
        "metallic": stage / "metallic.png",
        "ao": stage / "ao.png",
        "height": stage / "height.png",
    }
    _png(files["albedo"], albedo)
    _png(files["normal"], normal)
    _png(files["roughness"], roughness)
    _png(files["metallic"], metallic)
    _png(files["ao"], ao)
    _png(files["height"], height)

    from core.asset_manager import Delivery  # import tardío para evitar ciclo

    name = params.get("name", kind)
    return Delivery(
        kind="texture",
        category=category,
        name=name,
        description=params.get(
            "description",
            f"Textura procedural seamless '{kind}' a {resolution}x{resolution} "
            "con mapas PBR independientes (albedo/normal/rough/metal/AO/height).",
        ),
        files=files,
        materials=[],
        params=params,
        seed=seed,
        resolution=resolution,
        profile=params.get("profile", "BALANCED"),
        backend="numpy+pillow",
    )


def facade_color_params() -> list[dict]:
    """Variantes REALES de fachada colonial (color base distinto por variante)."""
    out = []
    for i, col in enumerate(COLONIAL_FACADES):
        out.append(
            {
                "name": f"stucco_colonial_{i + 1:02d}",
                "color": tuple(int(round(c * 255)) for c in col),
                "description": "Estuco colonial envejecido con manchas de humedad (canon §1).",
            }
        )
    return out

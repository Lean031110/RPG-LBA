"""Generador de materiales para Godot (definiciones JSON + PBR).

Un material de la fábrica referencia las texturas publicadas (rutas
estables res://assets/...) y fija parámetros StandardMaterial3D.
NO se generan .tres a mano (los UID los crea Godot); ver
DOCUMENTATION/ASSET_INTEGRATION.md.
"""
from __future__ import annotations

from pathlib import Path

from core import paths
from core.catalog import Catalog
from core.utils import hex_to_rgb01


def generate_material(name: str, params: dict, seed: int, profile: str = "BALANCED",
                     job_id: str = "", staging: Path | None = None):
    """params: color_base (hex), roughness, metallic, texture_id (opcional),
    categoria, descripcion, normal_strength..."""
    tex_id = params.get("texture_id")
    textures: dict[str, str] = {}
    if tex_id:
        cat = Catalog()
        entry = cat.get(tex_id)
        if entry is None:
            raise KeyError(f"El material referencia una textura inexistente: {tex_id}")
        base = entry["ruta"]
        for role, rel_path in entry.get("files", {}).items():
            textures[role] = "res://" + rel_path
    color = hex_to_rgb01(params.get("color_base", "#C9BFAB"))
    definition_params = {
        "albedo_color": [round(c, 3) for c in color],
        "roughness": float(params.get("roughness", 0.9)),
        "metallic": float(params.get("metallic", 0.0)),
        "normal_scale": float(params.get("normal_scale", 1.0)),
        "texturas": {k: v for k, v in textures.items()},
        "texture_id": tex_id,
        "uso_godot": (
            "StandardMaterial3D: albedo_color + albedo_texture (si hay), "
            "roughness/metallic y normal_texture con normal_scale."
        ),
        "categoria_godot": params.get("categoria", "terreno"),
    }
    from core.asset_manager import Delivery

    return Delivery(
        kind="material",
        category=params.get("categoria", "generic"),
        name=params.get("name", name),
        description=params.get(
            "description", "Material PBR del canon para Godot 4 (Compatibility Renderer)."
        ),
        files={},
        materials=[{"name": params.get("name", name), "base_color": list(color)}],
        params=definition_params,
        seed=seed,
        profile=profile,
        backend="numpy+pillow",
    )

"""Configuración de la fábrica y perfiles de calidad.

Perfiles (mandato §11):
- MOBILE:   geometría ligera, texturas 512, materiales sencillos.
- BALANCED: geometría intermedia, texturas 1024, mayor detalle.
- HIGH:     mayor detalle geométrico, texturas 2048 justificadas.
"""
from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path

from core import paths

PROFILES_FILE = paths.CONFIG_DIR / "profiles.json"
FACTORY_CONFIG_FILE = paths.CONFIG_DIR / "factory_config.json"

DEFAULT_PROFILES: dict = {
    "MOBILE": {
        "texture_resolution": 512,
        "max_triangles_prop": 900,
        "max_triangles_building": 3500,
        "radial_segments": 8,
        "sphere_segments": (8, 6),
        "lod_levels": 0,
        "materials": "flat-color-pbr",
        "notes": "Perfil Low del canon (Compatibility Renderer, Redmi 9C como referencia de diseño).",
    },
    "BALANCED": {
        "texture_resolution": 1024,
        "max_triangles_prop": 2200,
        "max_triangles_building": 7000,
        "radial_segments": 12,
        "sphere_segments": (12, 8),
        "lod_levels": 1,
        "materials": "flat-color-pbr+texture",
        "notes": "Perfil Medium del canon.",
    },
    "HIGH": {
        "texture_resolution": 2048,
        "max_triangles_prop": 5000,
        "max_triangles_building": 16000,
        "radial_segments": 16,
        "sphere_segments": (16, 12),
        "lod_levels": 1,
        "materials": "textured-pbr",
        "notes": "Perfil High del canon; solo cuando esté justificado.",
    },
}

DEFAULT_FACTORY_CONFIG: dict = {
    "backend": "auto",          # auto | blender | trimesh
    "default_profile": "BALANCED",
    "max_attempts": 3,          # reintentos limitados por recurso
    "stale_processing_minutes": 45,  # reanudación tras interrupción
    "batch_limit_default": 5,   # recursos por ejecución (GitHub Free)
    "collision_simple": True,
    "license": "MIT (proyecto RPG-LBA) - generacion procedural propia",
    "provenance": "Procedural - RPG-LBA AI Asset Factory (sin recursos de terceros)",
}


@dataclass
class FactoryConfig:
    backend: str = "auto"
    default_profile: str = "BALANCED"
    max_attempts: int = 3
    stale_processing_minutes: int = 45
    batch_limit_default: int = 5
    collision_simple: bool = True
    license: str = DEFAULT_FACTORY_CONFIG["license"]
    provenance: str = DEFAULT_FACTORY_CONFIG["provenance"]
    extra: dict = field(default_factory=dict)

    @classmethod
    def load(cls) -> "FactoryConfig":
        data: dict = {}
        if FACTORY_CONFIG_FILE.exists():
            data = json.loads(FACTORY_CONFIG_FILE.read_text(encoding="utf-8"))
        else:
            data = dict(DEFAULT_FACTORY_CONFIG)
            FACTORY_CONFIG_FILE.parent.mkdir(parents=True, exist_ok=True)
            FACTORY_CONFIG_FILE.write_text(
                json.dumps(DEFAULT_FACTORY_CONFIG, indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8",
            )
        known = {f for f in cls.__dataclass_fields__ if f != "extra"}
        cfg = cls(**{k: v for k, v in data.items() if k in known})
        cfg.extra = {k: v for k, v in data.items() if k not in known}
        return cfg


class Profiles:
    def __init__(self) -> None:
        if PROFILES_FILE.exists():
            self.data = json.loads(PROFILES_FILE.read_text(encoding="utf-8"))
        else:
            self.data = dict(DEFAULT_PROFILES)
            PROFILES_FILE.parent.mkdir(parents=True, exist_ok=True)
            PROFILES_FILE.write_text(
                json.dumps(DEFAULT_PROFILES, indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8",
            )

    def get(self, name: str) -> dict:
        if name not in self.data:
            raise KeyError(f"Perfil desconocido: {name}. Válidos: {list(self.data)}")
        return self.data[name]

    def texture_resolution(self, profile: str) -> int:
        return int(self.get(profile)["texture_resolution"])

    def geometry(self, profile: str) -> dict:
        p = self.get(profile)
        return {
            "radial_segments": p["radial_segments"],
            "sphere_segments": tuple(p["sphere_segments"]),
            "max_triangles_prop": p["max_triangles_prop"],
            "max_triangles_building": p["max_triangles_building"],
            "lod_levels": p["lod_levels"],
        }


def resolve_backend(requested: str) -> str:
    """'auto' elige Blender (bpy) si está disponible; si no, trimesh."""
    if requested in ("blender", "trimesh"):
        return requested
    try:
        import bpy  # noqa: F401
        return "blender"
    except Exception:
        return "trimesh"

"""Asset Manager (mandato §10).

Los generadores NUNCA deciden dónde guardar: entregan archivos temporales
+ metadatos, y el Asset Manager clasifica, crea carpetas, asigna nombre
estable, guarda, registra materiales, actualiza el catálogo, comprueba
duplicados (hash) y mantiene referencias.
"""
from __future__ import annotations

import json
import shutil
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from core import paths
from core.catalog import Catalog, new_entry
from core.config import FactoryConfig
from core.utils import sha256_file

TEXTURE_ROLES = ("albedo", "normal", "roughness", "metallic", "ao", "height")


class DuplicateAssetError(RuntimeError):
    def __init__(self, existing_id: str):
        super().__init__(
            f"Contenido idéntico ya publicado como {existing_id}; "
            "genera una variación real (semilla/parámetros distintos)."
        )
        self.existing_id = existing_id


@dataclass
class Delivery:
    """Lo que un generador entrega al Asset Manager."""

    kind: str                      # texture | model | material
    category: str                  # p.ej. 'ground', 'vegetation', 'urban'
    name: str                      # nombre base solicitado (sin id)
    description: str = ""
    files: dict[str, Path] = field(default_factory=dict)  # rol -> ruta temporal
    materials: list[dict] = field(default_factory=list)
    params: dict = field(default_factory=dict)
    seed: int | None = None
    resolution: int | None = None
    triangles: int | None = None
    vertices: int | None = None
    collision: str = ""
    lods: list[str] = field(default_factory=list)
    profile: str = "BALANCED"
    backend: str = "trimesh"
    extra: dict = field(default_factory=dict)


class AssetManager:
    def __init__(self, catalog: Catalog | None = None, cfg: FactoryConfig | None = None) -> None:
        self.catalog = catalog or Catalog()
        self.cfg = cfg or FactoryConfig.load()
        paths.ensure_dirs()

    # ------------------------------------------------------------ prefijos
    def _prefix(self, d: Delivery) -> str:
        if d.kind == "texture":
            return f"tex_{d.category}_{d.name}"
        if d.kind == "material":
            return f"mat_{d.name}"
        return f"mdl_{d.category}_{d.name}"

    # ------------------------------------------------------------ guardado
    def publish(self, d: Delivery) -> dict:
        """Clasifica, guarda, deduplica y registra. Devuelve la entrada del catálogo."""
        if d.kind == "texture":
            entry = self._publish_texture(d)
        elif d.kind == "model":
            entry = self._publish_model(d)
        elif d.kind == "material":
            entry = self._publish_material(d)
        else:
            raise ValueError(f"kind desconocido: {d.kind}")

        # Duplicado por hash → rechazar (mandato: no recursos idénticos)
        primary_hash = entry.get("hash")
        if primary_hash:
            existing = self.catalog.find_by_hash(primary_hash)
            if existing and existing["id"] != entry["id"]:
                # eliminar archivos recién copiados antes de rechazar
                for rel in [entry.get("ruta")] + list(entry.get("files", {}).values()):
                    p = paths.ROOT / rel
                    if p.exists():
                        p.unlink()
                self.catalog.remove(entry["id"])
                raise DuplicateAssetError(existing["id"])

        return entry

    # ------------------------------------------------------------ texturas
    def _publish_texture(self, d: Delivery) -> dict:
        assert "albedo" in d.files, "Una textura requiere albedo como archivo primario"
        base_dir = paths.TEXTURE_TYPE_DIRS.get(d.category)
        if base_dir is None:
            base_dir = paths.ASSET_TEXTURES / d.category
        base_dir.mkdir(parents=True, exist_ok=True)

        asset_id = self.catalog.next_id(self._prefix(d))
        files_out: dict[str, str] = {}
        for role in TEXTURE_ROLES:
            src = d.files.get(role)
            if src is None or not Path(src).exists():
                continue
            dst = base_dir / f"{asset_id}_{role}.png"
            shutil.copyfile(src, dst)
            files_out[role] = paths.rel(dst)
        primary = files_out["albedo"]

        entry = new_entry(
            id=asset_id,
            nombre=d.name.replace("_", " ").title(),
            categoria=f"texture/{d.category}",
            descripcion=d.description
            or f"Textura procedural seamless {d.name} con mapas PBR independientes.",
            ruta=primary,
            formato="PNG (RGB/RGBA)",
            resolucion=d.resolution,
            materiales=[m["name"] for m in d.materials],
            texturas=sorted(files_out.values()),
            colisiones="",
            lod=[],
            perfil=d.profile,
            procedencia="Generador procedural NumPy/Pillow — RPG-LBA AI Asset Factory",
            licencia=self.cfg.license,
            seed=d.seed,
            backend="numpy+pillow",
            estado="completed",
            hash=sha256_file(paths.ROOT / primary),
            files=files_out,
        )
        self.catalog.register(entry)
        return entry

    # -------------------------------------------------------------- modelos
    def _publish_model(self, d: Delivery) -> dict:
        assert "glb" in d.files, "Un modelo requiere el archivo GLB"
        base_dir = paths.MODEL_CATEGORY_DIRS.get(d.category)
        if base_dir is None:
            base_dir = paths.ASSET_MODELS / d.category
        base_dir.mkdir(parents=True, exist_ok=True)

        asset_id = self.catalog.next_id(self._prefix(d))
        dst = base_dir / f"{asset_id}.glb"
        shutil.copyfile(d.files["glb"], dst)
        primary = paths.rel(dst)

        lods: list[str] = []
        for i, lod_src in enumerate(d.lods, start=1):
            lod_dst = base_dir / f"{asset_id}_lod{i}.glb"
            shutil.copyfile(lod_src, lod_dst)
            lods.append(paths.rel(lod_dst))

        entry = new_entry(
            id=asset_id,
            nombre=d.name.replace("_", " ").title(),
            categoria=f"model/{d.category}",
            descripcion=d.description or f"Modelo 3D estilizado {d.name} (génesis paramétrica).",
            ruta=primary,
            formato="GLB (glTF 2.0 binario)",
            poligonos=d.triangles,
            vertices=d.vertices,
            materiales=[m["name"] for m in d.materials],
            texturas=[],
            escala="1 unidad GLB = 1 metro (metro = unidad Godot)",
            pivote="base en origen (y=0), +Y arriba, frente -Z",
            colisiones=d.collision or "ver campo colision_simple",
            lod=lods,
            perfil=d.profile,
            procedencia=f"Generador paramétrico {d.backend} — RPG-LBA AI Asset Factory",
            licencia=self.cfg.license,
            seed=d.seed,
            backend=d.backend,
            estado="completed",
            hash=sha256_file(dst),
            files={"glb": primary},
            materiales_detalle=d.materials,
            parametros=d.params,
        )
        self.catalog.register(entry)
        return entry

    # ------------------------------------------------------------ materiales
    def _publish_material(self, d: Delivery) -> dict:
        base_dir = paths.ASSET_MATERIALS
        base_dir.mkdir(parents=True, exist_ok=True)
        asset_id = self.catalog.next_id(self._prefix(d))
        definition = {
            "id": asset_id,
            "nombre": d.name.replace("_", " ").title(),
            "categoria": f"material/{d.category}",
            "descripcion": d.description,
            "perfil": d.profile,
            "procedencia": "Definición generada por RPG-LBA AI Asset Factory",
            "licencia": self.cfg.license,
            "backend": "numpy+pillow",
            "semilla": d.seed,
            **d.params,  # color_base, roughness, metallic, texturas (rutas relativas), etc.
        }
        dst = base_dir / f"{asset_id}.json"
        dst.write_text(json.dumps(definition, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

        entry = new_entry(
            id=asset_id,
            nombre=definition["nombre"],
            categoria=f"material/{d.category}",
            descripcion=d.description,
            ruta=paths.rel(dst),
            formato="JSON (definición de material para Godot)",
            materiales=[definition["nombre"]],
            texturas=definition.get("texturas", []),
            perfil=d.profile,
            procedencia="RPG-LBA AI Asset Factory",
            licencia=self.cfg.license,
            seed=d.seed,
            backend="numpy+pillow",
            estado="completed",
            hash=sha256_file(dst),
            files={"json": paths.rel(dst)},
        )
        self.catalog.register(entry)
        return entry

    # ------------------------------------------------------------- utilidades
    def stable_path_for(self, category: str, asset_id: str) -> Path:
        if category in paths.MODEL_CATEGORY_DIRS:
            return paths.MODEL_CATEGORY_DIRS[category] / f"{asset_id}.glb"
        return paths.ASSET_TEXTURES / category / f"{asset_id}_albedo.png"

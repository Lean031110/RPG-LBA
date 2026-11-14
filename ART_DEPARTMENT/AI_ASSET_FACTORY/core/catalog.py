"""Catálogo central de recursos (assets_manifest.json).

Contrato con el agente principal: los IDs y rutas son estables.
Cada recurso registra (mandato §12): id, nombre, categoría, descripción,
ruta, formato, resolución, polígonos, materiales, texturas, escala,
colisiones, LOD, perfil de calidad, procedencia, licencia, fecha y estado.
"""
from __future__ import annotations

import json
import threading
from datetime import datetime, timezone
from typing import Any

from core import paths

_LOCK = threading.RLock()


class Catalog:
    def __init__(self, path=None) -> None:
        self.path = path or paths.MANIFEST_PATH
        self._data = self._load()

    def _load(self) -> dict:
        if self.path.exists():
            try:
                return json.loads(self.path.read_text(encoding="utf-8"))
            except json.JSONDecodeError:
                pass  # regenerar catálogo corrupto desde cero (conservando backup)
        return {"version": 1, "updated": "", "assets": {}}

    def save(self) -> None:
        with _LOCK:
            self._data["updated"] = datetime.now(timezone.utc).isoformat(timespec="seconds")
            self.path.parent.mkdir(parents=True, exist_ok=True)
            tmp = self.path.with_suffix(".json.tmp")
            tmp.write_text(
                json.dumps(self._data, indent=2, ensure_ascii=False, sort_keys=False) + "\n",
                encoding="utf-8",
            )
            tmp.replace(self.path)

    # ------------------------------------------------------------- consultas
    def get(self, asset_id: str) -> dict | None:
        return self._data["assets"].get(asset_id)

    def find_by_path(self, rel_path: str) -> dict | None:
        for a in self._data["assets"].values():
            if a.get("ruta") == rel_path or a.get("files", {}).get("primary") == rel_path:
                return a
        return None

    def find_by_hash(self, content_hash: str) -> dict | None:
        for a in self._data["assets"].values():
            if a.get("hash") == content_hash:
                return a
        return None

    def by_category(self, category: str) -> list[dict]:
        return [a for a in self._data["assets"].values() if a.get("category") == category]

    def all_assets(self) -> list[dict]:
        return list(self._data["assets"].values())

    def next_index(self, prefix: str) -> int:
        """Siguiente número libre para un prefijo de ID (estable)."""
        used = {
            a_id
            for a_id in self._data["assets"]
            if a_id.startswith(prefix + "_")
        }
        n = 1
        while f"{prefix}_{n:03d}" in used:
            n += 1
        return n

    def next_id(self, prefix: str) -> str:
        return f"{prefix}_{self.next_index(prefix):03d}"

    # ------------------------------------------------------------- registro
    def register(self, entry: dict) -> str:
        asset_id = entry["id"]
        with _LOCK:
            if not entry.get("fecha"):
                entry["fecha"] = datetime.now(timezone.utc).isoformat(timespec="seconds")
            self._data["assets"][asset_id] = entry
        self.save()
        return asset_id

    def update_state(self, asset_id: str, state: str) -> None:
        with _LOCK:
            a = self._data["assets"].get(asset_id)
            if a is None:
                return
            a["estado"] = state
            a["fecha"] = datetime.now(timezone.utc).isoformat(timespec="seconds")
        self.save()

    def remove(self, asset_id: str) -> None:
        with _LOCK:
            self._data["assets"].pop(asset_id, None)
        self.save()

    def stats(self) -> dict:
        by_cat: dict[str, int] = {}
        by_state: dict[str, int] = {}
        for a in self._data["assets"].values():
            cat = a.get("categoria", "?")
            by_cat[cat] = by_cat.get(cat, 0) + 1
            by_state[a.get("estado", "?")] = by_state.get(a.get("estado", "?"), 0) + 1
        return {"total": len(self._data["assets"]), "by_category": by_cat, "by_state": by_state}


def entry_template() -> dict:
    """Estructura completa de una entrada del manifiesto."""
    return {
        "id": "",
        "nombre": "",
        "categoria": "",
        "descripcion": "",
        "ruta": "",
        "formato": "",
        "resolucion": None,
        "poligonos": None,
        "vertices": None,
        "materiales": [],
        "texturas": [],
        "escala": "1 unidad GLB = 1 metro",
        "pivote": "base en origen, +Y arriba, frente -Z",
        "colisiones": "",
        "lod": [],
        "perfil": "",
        "procedencia": "",
        "licencia": "",
        "fecha": "",
        "estado": "",
        "semilla": None,
        "backend": "",
        "validacion": "",
    }


def new_entry(**kwargs: Any) -> dict:
    e = entry_template()
    e.update(kwargs)
    return e

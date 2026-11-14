"""Galería estática de previews (ART_DEPARTMENT/PREVIEWS/index.html)."""
from __future__ import annotations

import html
from pathlib import Path

from core import paths
from core.catalog import Catalog


def build_gallery() -> Path:
    cat = Catalog()
    entries = cat.all_assets()
    by_cat: dict[str, list[dict]] = {}
    for e in entries:
        key = e.get("categoria", "?").split("/")[0]
        by_cat.setdefault(key, []).append(e)

    def rel_preview(e):
        p = e.get("preview")
        if not p:
            return ""
        return "../../" + p if not p.startswith("../") else p

    parts = ["""<!DOCTYPE html>
<html lang="es"><head><meta charset="utf-8">
<title>RPG-LBA — Fábrica de Recursos 3D</title>
<style>
 body{background:#15181B;color:#C9BFAB;font-family:system-ui,sans-serif;margin:24px}
 h1{color:#D8912F;font-size:22px} h2{color:#6E9A96;border-bottom:1px solid #2A2F33;padding-bottom:4px}
 .grid{display:flex;flex-wrap:wrap;gap:14px;margin:14px 0 34px 0}
 .card{background:#1C2126;border:1px solid #2A2F33;border-radius:8px;padding:8px;width:290px}
 .card img{width:100%;border-radius:4px}
 .card .id{font-family:monospace;color:#A98B3D;font-size:11px}
 .card .meta{font-size:12px;color:#8A9096;margin-top:4px}
</style></head><body>
<h1>RPG-LBA — AI Asset Factory · Galería</h1>
<p>Biblioteca producida proceduralmente (gótico caribeño 1953). Rutas estables en el catálogo.</p>
"""]
    cat_titles = {
        "texture": "Texturas (PBR seamless)",
        "model": "Modelos 3D (GLB)",
        "material": "Materiales",
    }
    for key in ("texture", "material", "model"):
        group = by_cat.get(key, [])
        if not group:
            continue
        parts.append(f"<h2>{cat_titles.get(key, key)} ({len(group)})</h2><div class='grid'>")
        for e in sorted(group, key=lambda x: x["id"]):
            prev = rel_preview(e)
            img = f"<img src='{html.escape(prev)}'>" if prev else "<div class='meta'>(sin preview)</div>"
            tri = e.get("poligonos")
            res = e.get("resolucion")
            meta = " · ".join(str(x) for x in [tri and f"{tri} tris", res and f"{res}px",
                                               e.get("perfil", ""), e.get("estado", "")] if x)
            parts.append(
                f"<div class='card'>{img}<div class='id'>{html.escape(e['id'])}</div>"
                f"<div class='meta'>{html.escape(e.get('nombre',''))}<br>{html.escape(meta)}</div></div>"
            )
        parts.append("</div>")
    parts.append("</body></html>")
    out = paths.PREVIEWS_DIR / "index.html"
    out.write_text("\n".join(parts), encoding="utf-8")
    return out

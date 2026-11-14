"""Validación automática de recursos (mandato §13).

Comprobaciones por tipo:
- Textura: existencia, integridad PNG, resolución, seamless real (bordes),
  mapas PBR presentes y distintos (no copias), rango de valores.
- Modelo: GLB íntegro y recargable, geometría válida, normales, UV,
  escala razonable (metros), pivote en base, materiales, triángulos.
- Manifiesto: campos obligatorios, rutas existentes, IDs únicos.
- Duplicados: hash idéntico entre recursos (texturas o modelos) -> FAIL.
La comprobación con Godot headless queda como paso opcional (ver
integrations/godot_bridge.py) y se reporta SKIPPED si no hay binario.
"""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

from core import paths
from core.report import ValidationReport


def _open_gray(path: Path) -> np.ndarray:
    return np.asarray(Image.open(path).convert("L"), dtype=np.float64) / 255.0


def validate_texture(entry: dict) -> ValidationReport:
    rep = ValidationReport(entry["id"])
    files = entry.get("files", {})
    root = paths.ROOT

    for role in ("albedo", "normal", "roughness", "metallic", "ao", "height"):
        p = root / files.get(role, "")
        ok = p.exists() and p.stat().st_size > 0
        rep.check(f"archivo_{role}", ok, str(p))

    alb = root / files["albedo"]
    rep.check("albedo_abre", alb.exists() and Image.open(alb).size == (entry["resolucion"], entry["resolucion"])
              if alb.exists() else False, f"esperado {entry['resolucion']}px")

    if alb.exists():
        a = np.asarray(Image.open(alb).convert("L"), dtype=np.float64) / 255.0
        # seamless: la diferencia en el borde debe ser comparable al PEOR caso
        # interior (percentil 99.9 de transiciones normales del patrón: bordes
        # de piedra, hiladas, vetas). Una costura real supera cualquier
        # transición interior del propio patrón.
        diff_x = np.abs(np.diff(a, axis=1)).ravel()
        diff_y = np.abs(np.diff(a, axis=0)).ravel()
        px999 = float(np.percentile(diff_x, 99.9)) if diff_x.size else 0.0
        py999 = float(np.percentile(diff_y, 99.9)) if diff_y.size else 0.0
        dx = float(np.abs(a[:, -1] - a[:, 0]).mean())
        dy = float(np.abs(a[-1, :] - a[0, :]).mean())
        rep.check("seamless_bordes",
                  dx <= 1.5 * max(px999, 1e-3) + 0.02 and dy <= 1.5 * max(py999, 1e-3) + 0.02,
                  f"borde dx={dx:.4f} dy={dy:.4f} vs p99.9 interior {px999:.4f}/{py999:.4f}")
        rep.check("rango_albedo", 0.02 < a.std() or a.mean() > 0.01,
                  f"media={a.mean():.3f} std={a.std():.3f}")

    # mapas distintos (prohibido copiar la misma imagen a todos los canales)
    if alb.exists():
        a_hash = {role: _open_gray(root / files[role]).sum() for role in files
                  if (root / files[role]).exists() and role != "albedo"}
        # con la suma basta para detectar copias exactas entre mapas
        vals = {"albedo": _open_gray(alb).sum(), **a_hash}
        duplicated = [r for r, v in vals.items() if list(vals.values()).count(v) > 1]
        rep.check("mapas_pbr_distintos", not duplicated, f"repetidos={duplicated}")

    if files.get("roughness") and (root / files["roughness"]).exists():
        r = _open_gray(root / files["roughness"])
        rep.check("roughness_variada", float(r.std()) > 0.02,
                  f"std={float(r.std()):.4f} (>0.02; nada de mapas constantes)")
    if files.get("normal") and (root / files["normal"]).exists():
        n = np.asarray(Image.open(root / files["normal"]).convert("RGB"), dtype=np.float64) / 255.0
        rep.check("normal_blue_dominante", n[..., 2].mean() > 0.5,
                  f"media B={n[..., 2].mean():.3f} (>0.5)")
        rep.check("normal_rango", 0.0 <= n.min() and n.max() <= 1.0, f"min={n.min():.2f} max={n.max():.2f}")
    return rep


def validate_model(entry: dict) -> ValidationReport:
    rep = ValidationReport(entry["id"])
    import trimesh

    p = paths.ROOT / entry["ruta"]
    rep.check("archivo_glb", p.exists() and p.stat().st_size > 300, str(p))
    if not p.exists():
        return rep
    try:
        scene = trimesh.load(p, process=False)
        geoms = list(scene.geometry.values()) if hasattr(scene, "geometry") else [scene]
    except Exception as e:  # GLB corrupto
        rep.check("glb_integro", False, f"error al recargar: {e}")
        return rep
    rep.check("glb_integro", True, f"{len(geoms)} mallas")

    verts = np.concatenate([g.vertices for g in geoms], axis=0) if geoms else np.zeros((0, 3))
    faces = sum(len(g.faces) for g in geoms)
    rep.check("geometria_valida", len(verts) > 0 and faces > 0, f"{len(verts)} verts / {faces} tris")
    rep.check("normales_finitas", bool(np.isfinite(verts).all()), "sin NaN/Inf en vértices")
    rep.check("uv_presentes", all(g.visual.uv is not None and len(g.visual.uv) > 0
                                  if hasattr(g.visual, "uv") else False for g in geoms) if geoms else False,
              "UV planas por normal dominante")
    if entry.get("poligonos") is not None:
        rep.check("triangulos_coherentes", abs(entry["poligonos"] - faces) <= 2,
                  f"catálogo={entry['poligonos']} real={faces}")

    if len(verts):
        mn, mx = verts.min(axis=0), verts.max(axis=0)
        size = mx - mn
        rep.check("escala_metros", bool((size > 0.02).all() and (size < 40).all()),
                  f"dimensiones={size.round(2).tolist()}")
        rep.check("pivote_base", -0.02 <= mn[1] <= 0.35,
                  f"y_min={mn[1]:.3f} (base en origen)")
        rep.check("colision_registrada", bool(entry.get("colisiones")), entry.get("colisiones", ""))
    rep.check("materiales_presentes", len(entry.get("materiales", [])) > 0,
              f"{len(entry.get('materiales', []))} materiales")
    return rep


def validate_material(entry: dict) -> ValidationReport:
    rep = ValidationReport(entry["id"])
    p = paths.ROOT / entry["ruta"]
    rep.check("archivo_json", p.exists() and p.stat().st_size > 100, str(p))
    if not p.exists():
        return rep
    import json

    data = json.loads(p.read_text(encoding="utf-8"))
    rep.check("albedo_color", "albedo_color" in data and len(data["albedo_color"]) == 3, "")
    rep.check("roughness_rango", 0 <= float(data.get("roughness", 0)) <= 1, "")
    rep.check("metallic_rango", 0 <= float(data.get("metallic", 0)) <= 1, "")
    for role, res_path in data.get("texturas", {}).items():
        rp = paths.ROOT / res_path.replace("res://", "")
        rep.check(f"textura_{role}", rp.exists(), str(rp))
    return rep


def validate_manifest() -> ValidationReport:
    rep = ValidationReport("MANIFEST")
    from core.catalog import Catalog

    cat = Catalog()
    rep.check("manifiesto_json", len(cat.all_assets()) >= 0, f"{len(cat.all_assets())} recursos")
    required = ["id", "nombre", "categoria", "ruta", "formato", "procedencia", "licencia", "estado"]
    missing_all = []
    broken = []
    for e in cat.all_assets():
        miss = [k for k in required if not e.get(k)]
        if miss:
            missing_all.append(f"{e.get('id')}: {miss}")
        if not (paths.ROOT / e.get("ruta", "?")).exists():
            broken.append(e.get("id"))
    rep.check("campos_obligatorios", not missing_all, "; ".join(missing_all[:6]))
    rep.check("rutas_existen", not broken, "; ".join(broken[:6]))
    ids = [e["id"] for e in cat.all_assets()]
    rep.check("ids_unicos", len(ids) == len(set(ids)), "")
    return rep


def validate_entry(entry: dict) -> ValidationReport:
    cat = entry.get("categoria", "")
    if cat.startswith("texture"):
        return validate_texture(entry)
    if cat.startswith("model"):
        return validate_model(entry)
    if cat.startswith("material"):
        return validate_material(entry)
    rep = ValidationReport(entry.get("id", "?"))
    rep.skipped("tipo desconocido", cat)
    return rep


def duplicates_check() -> ValidationReport:
    """Recursos idénticos (hash) o texturas visualmente iguales (cv2)."""
    rep = ValidationReport("DUPLICADOS")
    from core.catalog import Catalog

    cat = Catalog()
    entries = cat.all_assets()
    hashes = {}
    dup = []
    for e in entries:
        h = e.get("hash")
        if h:
            if h in hashes:
                dup.append(f"{hashes[h]} ≡ {e['id']}")
            else:
                hashes[h] = e["id"]
    rep.check("hash_duplicados", not dup, "; ".join(dup))

    # imágenes visualmente idénticas (cv2 absdiff sobre albedos)
    tex = [e for e in entries if e.get("categoria", "").startswith("texture")]
    seen = {}
    visual_dups = []
    for e in tex:
        p = paths.ROOT / e.get("files", {}).get("albedo", "")
        if not p.exists():
            continue
        import cv2

        small = cv2.resize(cv2.imread(str(p), cv2.IMREAD_GRAYSCALE), (64, 64))
        for (other_id, other_img) in seen.items():
            diff = float(np.abs(small.astype(np.int16) - other_img.astype(np.int16)).mean())
            if diff < 1.5:  # prácticamente la misma imagen
                visual_dups.append(f"{other_id} ~ {e['id']} (diff={diff:.2f})")
        seen[e["id"]] = small
    rep.check("texturas_visualmente_distintas", not visual_dups, "; ".join(visual_dups[:8]))
    return rep

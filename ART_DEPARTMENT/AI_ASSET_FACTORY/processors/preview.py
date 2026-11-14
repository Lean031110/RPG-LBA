"""Previsualizaciones reales: hojas de contactos de texturas (PBR) y
renders de modelos (matplotlib headless). Se guardan en ART_DEPARTMENT/PREVIEWS/."""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

from core import paths

BG = (21, 24, 27)      # fondo negro carbón del canon
FG = (201, 191, 171)   # caliza para texto
ACCENT = (216, 145, 47)  # ámbar de farol

ROLE_LABELS = {
    "albedo": "Albedo",
    "normal": "Normal",
    "roughness": "Roughness",
    "metallic": "Metallic",
    "ao": "Ambient Occlusion",
    "height": "Height",
}


def _load(path) -> Image.Image:
    return Image.open(path).convert("RGB")


def texture_contact_sheet(entry: dict, out_png: Path) -> Path:
    files = entry.get("files", {})
    size = 256
    cols = 3
    rows = 2
    pad = 8
    header = 56
    label_h = 22
    W = cols * size + pad * (cols + 1)
    Hh = header + rows * (size + label_h) + pad * (rows + 1)
    sheet = Image.new("RGB", (W, Hh), BG)
    d = ImageDraw.Draw(sheet)
    d.text((pad + 4, 12), f"{entry['id']}  —  {entry['nombre']}", fill=FG)
    d.text((pad + 4, 30), f"{entry.get('resolucion','?')}px · perfil {entry.get('perfil','')}",
           fill=ACCENT)
    roles = ["albedo", "normal", "roughness", "metallic", "ao", "height"]
    for idx, role in enumerate(roles):
        rel = files.get(role)
        if not rel:
            continue
        img = _load(paths.ROOT / rel)
        img = img.resize((size, size), Image.LANCZOS)
        c, r = idx % cols, idx // cols
        x = pad + c * (size + pad)
        y = header + pad + r * (size + label_h + pad)
        sheet.paste(img, (x, y))
        d.rectangle([x, y, x + size - 1, y + size - 1], outline=(60, 64, 68))
        d.text((x + 4, y + size + 4), ROLE_LABELS.get(role, role), fill=FG)
    # demo de tileado (seamless) con el albedo replicado 2x2
    alb = files.get("albedo")
    if alb:
        img = _load(paths.ROOT / alb).resize((size // 2, size // 2), Image.LANCZOS)
        tile = Image.new("RGB", (size, size))
        for i in range(2):
            for j in range(2):
                tile.paste(img, (i * size // 2, j * size // 2))
        x = pad + 2 * (size + pad)
        y = header + pad + 1 * (size + label_h + pad)
        sheet.paste(tile, (x, y))
        d.rectangle([x, y, x + size - 1, y + size - 1], outline=ACCENT)
        d.text((x + 4, y + size + 4), "Tiled 2x2 (seamless)", fill=ACCENT)
    out_png.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out_png, optimize=True)
    return out_png


def model_render(glb_path: Path, out_png: Path, elev: int = 18, azim: int = -60) -> Path:
    """Render headless del GLB con matplotlib (silueta + materiales)."""
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from mpl_toolkits.mplot3d.art3d import Poly3DCollection

    import trimesh

    scene = trimesh.load(glb_path, process=False)
    geoms = []
    if isinstance(scene, trimesh.Scene):
        for g in scene.geometry.values():
            geoms.append(g)
    else:
        geoms = [scene]

    fig = plt.figure(figsize=(4, 4), dpi=110)
    ax = fig.add_subplot(111, projection="3d")
    ax.set_facecolor("#15181B")
    fig.patch.set_facecolor("#15181B")
    light = np.array([0.45, 0.75, 0.5])
    light = light / np.linalg.norm(light)
    all_v = []
    for g in geoms:
        color = (0.7, 0.67, 0.6, 1.0)
        try:
            mat = getattr(g.visual, "material", None)
            bc = getattr(mat, "baseColorFactor", None)
            if bc is not None:
                vals = [float(v) for v in list(bc)[:3]]
                if any(v > 1.0 + 1e-6 for v in vals):
                    vals = [v / 255.0 for v in vals]
                color = (vals[0], vals[1], vals[2], 1.0)
        except Exception:
            pass
        # materiales muy oscuros: aclarar SOLO para el preview (legibilidad)
        if sum(color[:3]) < 0.55:
            color = tuple(min(1.0, c * 2.3 + 0.10) for c in color[:3]) + (1.0,)
        tris = g.vertices[g.faces]
        all_v.append(g.vertices)
        fc = _shaded_faces(g, color, light)
        pc = Poly3DCollection(tris, facecolors=fc, edgecolors="none", linewidths=0)
        ax.add_collection3d(pc)

    # disco de suelo tenue para 'apoyar' visualmente el objeto
    if all_v:
        V = np.concatenate(all_v, axis=0)
        y_min = float(V[:, 1].min())
        c2 = (float(V[:, 0].min() + V[:, 0].max()) / 2, y_min,
              float(V[:, 2].min() + V[:, 2].max()) / 2)
        r = max(float((V.max(axis=0) - V.min(axis=0)).max()) / 2, 0.05) * 1.35
        theta = np.linspace(0, 2 * np.pi, 40)
        disk = np.stack([np.cos(theta), np.zeros_like(theta), np.sin(theta)], axis=1) * r
        disk[:, 0] += c2[0]
        disk[:, 2] += c2[2]
        ground = Poly3DCollection([disk], facecolors=(0.16, 0.18, 0.20, 1.0),
                                   edgecolors=(0.3, 0.33, 0.36), linewidths=0.4)
        ax.add_collection3d(ground)

    if all_v:
        V = np.concatenate(all_v, axis=0)
        mn, mx = V.min(axis=0), V.max(axis=0)
        c = (mn + mx) / 2
        r = max((mx - mn).max() / 2, 1e-3) * 1.25
        ax.set_xlim(c[0] - r, c[0] + r)
        ax.set_ylim(c[1] - r, c[1] + r)
        ax.set_zlim(c[2] - r, c[2] + r)
    ax.set_axis_off()
    ax.view_init(elev=elev, azim=azim)
    fig.tight_layout(pad=0)
    out_png.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_png, facecolor=fig.get_facecolor())
    plt.close(fig)
    return out_png


def _shaded_faces(g, base_color, light_dir):
    """Colores por cara con iluminación propia (normales × luz)."""
    normals = np.asarray(g.face_normals)
    lum = np.clip(0.38 + 0.62 * np.abs(normals @ light_dir), 0.25, 1.0)
    cols = np.zeros((len(normals), 4))
    cols[:, 0:3] = np.asarray(base_color)[None, 0:3] * lum[:, None]
    cols[:, 3] = 1.0
    return cols


def material_swatch(entry: dict, out_png: Path) -> Path:
    """Tarjeta de material: color base + miniatura de albedo si hay textura."""
    import json

    W, Hh = 360, 140
    img = Image.new("RGB", (W, Hh), BG)
    d = ImageDraw.Draw(img)
    d.text((10, 10), entry["id"], fill=FG)
    try:
        definition = json.loads((paths.ROOT / entry["ruta"]).read_text(encoding="utf-8"))
    except Exception:
        definition = {}
    params = definition if definition else entry.get("parametros", {})
    col = params.get("albedo_color", [0.7, 0.7, 0.7])
    col255 = tuple(int(round(c * 255)) for c in col)
    d.rectangle([10, 34, 120, 120], fill=col255, outline=(60, 64, 68))
    d.text((130, 34), f"rough {params.get('roughness', '?')}", fill=FG)
    d.text((130, 50), f"metal {params.get('metallic', '?')}", fill=FG)
    texs = params.get("texturas", {})
    alb = texs.get("albedo")
    if alb:
        try:
            t = _load(paths.ROOT / alb.replace("res://", "")).resize((100, 100), Image.LANCZOS)
            img.paste(t, (240, 34))
        except Exception:
            pass
    out_png.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_png, optimize=True)
    return out_png


def preview_for_entry(entry: dict) -> Path:
    cat = entry.get("categoria", "")
    base = paths.PREVIEWS_DIR / cat.split("/", 1)[-1]
    out = base / f"{entry['id']}.png"
    if cat.startswith("texture"):
        return texture_contact_sheet(entry, out)
    if cat.startswith("material"):
        return material_swatch(entry, out)
    if cat.startswith("model"):
        return model_render(paths.ROOT / entry["ruta"], out)
    raise ValueError(f"categoría sin preview: {cat}")

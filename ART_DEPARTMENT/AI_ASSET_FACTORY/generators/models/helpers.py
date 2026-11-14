"""Helpers de construcción: materiales del canon y subconstructores comunes."""
from __future__ import annotations

import numpy as np

from core.utils import hex_to_rgb01

# ------------------------------------------------------- materiales canon
C = {
    "carbon": hex_to_rgb01("#1C1C22"),
    "petroleo": hex_to_rgb01("#1F4E5F"),
    "manigua": hex_to_rgb01("#2E4A32"),
    "manigua_claro": hex_to_rgb01("#4A6B3C"),
    "tierra_roja": hex_to_rgb01("#8A3B2A"),
    "caliza": hex_to_rgb01("#C9BFAB"),
    "ambar": hex_to_rgb01("#D8912F"),
    "carmesi": hex_to_rgb01("#7A1F2B"),
    "oro_viejo": hex_to_rgb01("#A98B3D"),
    "ocre": hex_to_rgb01("#B89C5A"),
    "turquesa": hex_to_rgb01("#6E9A96"),
    "coral": hex_to_rgb01("#B96A5A"),
    "crema": hex_to_rgb01("#D1C6A8"),
    "musgo": hex_to_rgb01("#3A5232"),
    "madera": hex_to_rgb01("#6B4A2A"),
    "madera_clara": hex_to_rgb01("#9C7A4A"),
    "teja": hex_to_rgb01("#9C4A2F"),
    "zinc": hex_to_rgb01("#8A9096"),
    "oxido": hex_to_rgb01("#6E3A1E"),
    "vidrio_oscuro": hex_to_rgb01("#26343A"),
    "vidrio_petroleo": hex_to_rgb01("#2A4A55"),
}

FACADE_COLORS = ["ocre", "turquesa", "coral", "crema", "caliza"]


def register_materials(b) -> dict:
    """Crea los materiales del canon en el backend y devuelve el dict handle->nombre."""
    m = {}
    specs = [
        ("carbon", "carbon", 0.85, 0.0),
        ("petroleo", "petroleo", 0.55, 0.35),
        ("manigua", "manigua", 0.9, 0.0),
        ("manigua_claro", "manigua_claro", 0.9, 0.0),
        ("tierra_roja", "tierra_roja", 0.95, 0.0),
        ("caliza", "caliza", 0.88, 0.0),
        ("ambar", "ambar", 0.35, 0.0),
        ("carmesi", "carmesi", 0.7, 0.0),
        ("oro_viejo", "oro_viejo", 0.45, 0.85),
        ("ocre", "ocre", 0.9, 0.0),
        ("turquesa", "turquesa", 0.9, 0.0),
        ("coral", "coral", 0.9, 0.0),
        ("crema", "crema", 0.9, 0.0),
        ("musgo", "musgo", 0.95, 0.0),
        ("madera", "madera", 0.75, 0.0),
        ("madera_clara", "madera_clara", 0.75, 0.0),
        ("teja", "teja", 0.9, 0.0),
        ("zinc", "zinc", 0.5, 0.85),
        ("oxido", "oxido", 0.8, 0.4),
        ("vidrio_oscuro", "vidrio_oscuro", 0.15, 0.0),
        ("vidrio_petroleo", "vidrio_petroleo", 0.2, 0.0),
    ]
    for key, cname, rough, metal in specs:
        m[key] = b.mat(f"m_{cname}", C[cname], roughness=rough, metallic=metal)
    return m


def decayed(b, mat_name: str, color, decay: float):
    """Variante 'envejecida' de un material (fachadas/ madera expuesta)."""
    c = np.array(color, dtype=np.float64)
    dark = np.array([0.10, 0.09, 0.08])
    out = np.clip(c * (1.0 - 0.35 * decay) + dark * 0.35 * decay, 0, 1)
    return b.mat(f"{mat_name}_aged{int(decay * 100)}", tuple(out), roughness=0.92, metallic=0.0)


# ------------------------------------------------------- subconstructores
def column(b, m, x: float, z: float, height: float, radius: float = 0.12,
           base_h: float = 0.15, cap_h: float = 0.12, mat: str | None = None):
    mat = mat or m["caliza"]
    seg = 12
    b.part("cylinder", mat, radius=radius, depth=height - base_h - cap_h,
           location=(x, base_h + (height - base_h - cap_h) / 2, z), segments=seg, smooth=True)
    b.part("box", mat, size=(radius * 2.4, base_h, radius * 2.4), location=(x, base_h / 2, z))
    b.part("box", mat, size=(radius * 2.4, cap_h, radius * 2.4), location=(x, height - cap_h / 2, z))


def railing(b, mat, width: float, height: float = 0.9, y0: float = 0.0, z: float = 0.0,
            axis: str = "x", posts: int = 5):
    """Barandilla a lo largo del eje dado."""
    post_r = 0.02
    for i in range(posts + 1):
        t = i / max(posts, 1)
        px = (t - 0.5) * width if axis == "x" else 0.0
        pz = z if axis == "x" else (t - 0.5) * width
        b.part("cylinder", mat, radius=post_r, depth=height, location=(px, y0 + height / 2, pz))
    if axis == "x":
        b.part("box", mat, size=(width, 0.04, 0.04), location=(0, y0 + height, z))
        b.part("box", mat, size=(width, 0.04, 0.04), location=(0, y0 + height * 0.35, z))
    else:
        b.part("box", mat, size=(0.04, 0.04, width), location=(z, y0 + height, 0))
        b.part("box", mat, size=(0.04, 0.04, width), location=(z, y0 + height * 0.35, 0))


def window_colonial(b, m, x: float, y: float, z: float, w: float = 0.7, h: float = 1.0,
                    shutters: bool = True, facing: str = "z"):
    """Ventana colonial: marco madera + vidrio + postigos."""
    frame = m["madera"]
    glass = m["vidrio_petroleo"]
    t = 0.05
    if facing == "z":
        b.part("box", frame, size=(w, t, 0.06), location=(x, y + h / 2, z))
        b.part("box", frame, size=(w, t, 0.06), location=(x, y + h - t / 2 - 0.02, z))
        b.part("box", frame, size=(t, h, 0.06), location=(x - w / 2 + t / 2, y + h / 2, z))
        b.part("box", frame, size=(t, h, 0.06), location=(x + w / 2 - t / 2, y + h / 2, z))
        b.part("box", glass, size=(w - 2 * t, h - 2 * t, 0.02), location=(x, y + h / 2, z - 0.01))
        if shutters:
            sw = w * 0.5
            b.part("box", frame, size=(sw, h, 0.03), location=(x - w / 2 - sw / 2, y + h / 2, z + 0.05))
            b.part("box", frame, size=(sw, h, 0.03), location=(x + w / 2 + sw / 2, y + h / 2, z + 0.05))
    else:  # facing x (paredes laterales)
        b.part("box", frame, size=(0.06, t, w), location=(x, y + h / 2, z))
        b.part("box", frame, size=(0.06, t, w), location=(x, y + h - t / 2 - 0.02, z))
        b.part("box", frame, size=(0.06, h, t), location=(x, y + h / 2, z - w / 2 + t / 2))
        b.part("box", frame, size=(0.06, h, t), location=(x, y + h / 2, z + w / 2 - t / 2))
        b.part("box", glass, size=(0.02, h - 2 * t, w - 2 * t), location=(x - 0.01, y + h / 2, z))


def door_colonial(b, m, x: float, z: float, w: float = 1.0, h: float = 2.1, facing: str = "z",
                  color_key: str = "madera"):
    """Puerta doble con dintel y umbral."""
    wood = m[color_key]
    t = 0.06
    if facing == "z":
        b.part("box", m["madera_clara"], size=(w + 0.24, 0.14, t * 2), location=(x, h + 0.07, z))  # dintel
        b.part("box", m["caliza"], size=(w + 0.3, 0.08, 0.5), location=(x, 0.04, z + 0.2))          # umbral
        b.part("box", wood, size=(w / 2 - 0.02, h, t), location=(x - w / 4, h / 2, z))
        b.part("box", wood, size=(w / 2 - 0.02, h, t), location=(x + w / 4, h / 2, z))
        b.part("box", m["oro_viejo"], size=(0.05, 0.05, 0.12), location=(x - 0.16, h * 0.5, z + t))
        b.part("box", m["oro_viejo"], size=(0.05, 0.05, 0.12), location=(x + 0.16, h * 0.5, z + t))
    else:
        b.part("box", wood, size=(t, h, w), location=(x, h / 2, z))
        b.part("box", m["madera_clara"], size=(t * 2, 0.14, w + 0.24), location=(x, h + 0.07, z))


def stairs(b, mat, width: float, steps: int = 6, rise: float = 0.18, run: float = 0.3,
           x0: float = 0.0, y0: float = 0.0, axis: str = "z"):
    for i in range(steps):
        y = y0 + rise * (i + 0.5)
        off = run * (i + 0.5)
        if axis == "z":
            b.part("box", mat, size=(width, rise, run), location=(x0, y, off - run / 2))
        else:
            b.part("box", mat, size=(run, rise, width), location=(off - run / 2, y, x0))


def fronds(b, mat, top_y: float, count: int, length: float, tilt: float, rng,
           segments: int = 6):
    """Corona de hojas (palmas): hojas planas radiando con caída."""
    for i in range(count):
        ang = i * 2 * np.pi / count + rng.uniform(-0.15, 0.15)
        d = rng.uniform(0.06, 0.16) + tilt
        w = length * 0.22
        cx = np.cos(ang) * length * 0.45
        cz = np.sin(ang) * length * 0.45
        cy = top_y - np.sin(d) * length * 0.28
        b.part("box", mat, size=(length, 0.02, w), rotation=(0, -ang, -d),
               location=(cx, cy, cz))


def canopy(b, mat, center, radius: float, blobs: int, rng, segments: int = 8,
           squashed: float = 0.6):
    """ Copa de árbol por racimo de esferas (silueta legible)."""
    cx, cy, cz = center
    for i in range(blobs):
        ang = rng.uniform(0, 2 * np.pi)
        r = rng.uniform(0.2, 0.85) * radius
        s = rng.uniform(0.45, 0.9) * radius
        b.part("sphere", mat, radius=s,
               location=(cx + np.cos(ang) * r, cy + rng.uniform(-0.15, 0.35) * radius,
                         cz + np.sin(ang) * r),
               segments=max(6, segments), smooth=True)
    b.part("sphere", mat, radius=radius, location=(cx, cy, cz), segments=max(6, segments), smooth=True)


def grass_blades(b, mat, count: int, height: float, spread: float, rng,
                  segments: int = 6, blade_w: float = 0.03):
    for _ in range(count):
        ang = rng.uniform(0, 2 * np.pi)
        r = rng.uniform(0.0, spread)
        x, z = np.cos(ang) * r, np.sin(ang) * r
        tilt = rng.uniform(0.03, 0.32)
        bh = height * rng.uniform(0.7, 1.15)
        rot = (tilt, rng.uniform(0, 2 * np.pi), 0)
        b.part("box", mat, size=(blade_w, bh, blade_w * 2.2),
               rotation=rot,
               location=(x + np.sin(tilt) * bh * 0.3, bh * 0.55 + 0.02, z))

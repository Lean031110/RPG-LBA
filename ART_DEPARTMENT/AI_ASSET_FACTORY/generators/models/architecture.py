"""Elementos arquitectónicos coloniales modulares (puertas, ventanas,
columnas, escaleras, balcones, arcos, verjas de hierro, tejados)."""
from __future__ import annotations

import numpy as np

from generators.models import helpers as H

G_DEFAULTS = {"radial_segments": 8, "sphere_segments": (8, 6)}


def _g(p):
    return {**G_DEFAULTS, **(p.get("geometry") or {})}


def _seg(g):
    return g["radial_segments"]


def door_colonial(b, p, rng):
    m = H.register_materials(b)
    w = p.get("width", rng.uniform(0.95, 1.25))
    h = p.get("height", rng.uniform(2.0, 2.4))
    H.door_colonial(b, m, 0, 0, w=w, h=h, facing="z", color_key="madera")
    return {"size_m": (w, h, 0.1)}


def door_simple(b, p, rng):
    m = H.register_materials(b)
    w = p.get("width", rng.uniform(0.85, 1.05))
    h = p.get("height", rng.uniform(2.0, 2.2))
    wood = m["madera_clara"]
    b.part("box", wood, size=(w, h, 0.06), location=(0, h / 2, 0))
    b.part("box", m["madera"], size=(w * 0.6, 0.03, 0.07), location=(0, h * 0.55, 0.002))
    b.part("box", m["oro_viejo"], size=(0.04, 0.04, 0.08), location=(w * 0.35, h * 0.48, 0.02))
    return {"size_m": (w, h, 0.07)}


def window_colonial(b, p, rng):
    m = H.register_materials(b)
    H.window_colonial(b, m, 0, 0, 0, w=p.get("width", 0.8), h=p.get("height", 1.1),
                      shutters=True, facing="z")
    return {"size_m": (1.8, 1.1, 0.12)}


def window_modern(b, p, rng):
    m = H.register_materials(b)
    H.window_colonial(b, m, 0, 0, 0, w=p.get("width", 0.9), h=p.get("height", 1.0),
                      shutters=False, facing="z")
    b.part("box", m["caliza"], size=(p.get("width", 0.9) + 0.3, 0.06, 0.2),
           location=(0, p.get("height", 1.0) + 0.03, 0.0))  # antepecho
    return {"size_m": (1.2, 1.06, 0.2)}


def column_colonial(b, p, rng):
    m = H.register_materials(b)
    h = p.get("height", rng.uniform(2.6, 3.4))
    r = p.get("radius", rng.uniform(0.11, 0.16))
    H.column(b, m, 0, 0, h, radius=r)
    return {"height_m": h}


def stairs_run(b, p, rng):
    m = H.register_materials(b)
    steps = int(p.get("steps", rng.integers(4, 8)))
    H.stairs(b, m["caliza"], width=p.get("width", 1.2), steps=steps)
    return {"steps": steps, "size_m": (p.get("width", 1.2), steps * 0.18, steps * 0.3)}


def balcony_module(b, p, rng):
    """Balcón colonial: losa + barandilla de hierro + ménsulas (pivote y=0)."""
    m = H.register_materials(b)
    w = p.get("width", rng.uniform(2.2, 3.6))
    d = p.get("depth", 0.9)
    y0 = p.get("floor_y", 0.0)   # módulo con base en el origen por defecto
    b.part("box", m["caliza"], size=(w, 0.14, d), location=(0, y0 + 0.07, 0))
    H.railing(b, m["carbon"], width=w, height=0.95, y0=y0 + 0.14, z=d / 2 - 0.03, axis="x", posts=7)
    for i in (-1, 1):
        b.part("box", m["caliza"], size=(0.16, 0.5, 0.5), location=(i * (w / 2 - 0.2), y0 + 0.25, -0.1))
    # puntas de lanza en la barandilla
    for i in range(8):
        t = i / 7
        b.part("cone", m["oro_viejo"], radius=0.018, depth=0.12,
               location=((t - 0.5) * w, y0 + 1.19, d / 2 - 0.03), segments=4)
    return {"size_m": (w, 1.1, d)}


def arch_colonial(b, p, rng):
    """Portal de arco: pilares + semicírculo de dovelas."""
    m = H.register_materials(b)
    w = p.get("width", rng.uniform(1.6, 2.6))
    h = p.get("height", rng.uniform(2.2, 3.0))
    d = p.get("depth", 0.45)
    H.column(b, m, -w / 2 - 0.08, 0, h, radius=0.09, base_h=0.2, cap_h=0.08)
    H.column(b, m, w / 2 + 0.08, 0, h, radius=0.09, base_h=0.2, cap_h=0.08)
    n = 9
    r = w / 2
    for k in range(n):
        theta = np.pi * k / (n - 1)
        x = np.cos(theta) * r
        y = h + np.sin(theta) * r * 0.55
        b.part("box", m["caliza"], size=(0.34, 0.14, d),
               rotation=(0, 0, theta - np.pi / 2), location=(x, y, 0))
    return {"size_m": (w + 0.4, h + r * 0.6, d)}


def fence_iron(b, p, rng):
    """Verja de hierro forjado (canon UI: hierro envejecido)."""
    m = H.register_materials(b)
    w = p.get("width", rng.uniform(1.8, 3.2))
    h = p.get("height", 1.15)
    iron = m["carbon"]
    b.part("box", iron, size=(w, 0.06, 0.06), location=(0, h, 0))
    b.part("box", iron, size=(w, 0.05, 0.05), location=(0, 0.12, 0))
    for i in range(9):
        t = i / 8
        x = (t - 0.5) * w
        b.part("box", iron, size=(0.03, h - 0.15, 0.03), location=(x, (h - 0.15) / 2 + 0.1, 0))
        b.part("cone", iron, radius=0.03, depth=0.14, location=(x, h + 0.07, 0), segments=4)
        if i % 2 == 0 and i < 8:
            b.part("box", iron, size=(w / 8, 0.025, 0.025),
                   rotation=(0, 0, np.pi / 4), location=(x + w / 16, h * 0.55, 0))
    return {"size_m": (w, h, 0.06)}


def roof_hip_tile(b, p, rng):
    """Tejado a cuatro aguas (módulo con base en y=0, listo para colocar)."""
    m = H.register_materials(b)
    w = p.get("width", rng.uniform(3.0, 5.0))
    d = p.get("depth", w * 0.7)
    rise = p.get("rise", rng.uniform(0.9, 1.5))
    over = 0.25
    # cono del DSL: base en y=0, punta hacia +Y
    b.part("cone", m["teja"], radius=max(w, d) * 0.72, depth=rise, segments=4,
           rotation=(0, np.pi / 4, 0), location=(0, 0.0, 0))
    # alero perimetral (borde de tejas)
    b.part("box", m["teja"], size=(w + 2 * over, 0.1, 0.2), location=(0, 0.05, d / 2 + over - 0.1))
    b.part("box", m["teja"], size=(w + 2 * over, 0.1, 0.2), location=(0, 0.05, -d / 2 - over + 0.1))
    b.part("box", m["teja"], size=(0.2, 0.1, d + 2 * over), location=(w / 2 + over - 0.1, 0.05, 0))
    b.part("box", m["teja"], size=(0.2, 0.1, d + 2 * over), location=(-w / 2 - over + 0.1, 0.05, 0))
    return {"size_m": (w + 0.5, rise + 0.1, d + 0.5)}


ARCHITECTURE_BUILDERS = {
    "door_colonial": door_colonial,
    "door_simple": door_simple,
    "window_colonial": window_colonial,
    "window_modern": window_modern,
    "column_colonial": column_colonial,
    "stairs_run": stairs_run,
    "balcony_module": balcony_module,
    "arch_colonial": arch_colonial,
    "fence_iron": fence_iron,
    "roof_hip_tile": roof_hip_tile,
}

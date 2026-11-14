"""Mobiliario de interiores (mesas, sillas, camas, armarios...)."""
from __future__ import annotations

import numpy as np

from generators.models import helpers as H

G_DEFAULTS = {"radial_segments": 8, "sphere_segments": (8, 6)}


def _g(p):
    return {**G_DEFAULTS, **(p.get("geometry") or {})}


def table_wood(b, p, rng):
    m = H.register_materials(b)
    w = p.get("width", rng.uniform(1.2, 1.9))
    d = p.get("depth", w * 0.62)
    h = p.get("height", rng.uniform(0.72, 0.78))
    b.part("box", m["madera"], size=(w, 0.05, d), location=(0, h, 0))
    for sx in (-1, 1):
        for sz in (-1, 1):
            b.part("box", m["madera_clara"], size=(0.07, h, 0.07),
                   location=(sx * (w / 2 - 0.09), h / 2, sz * (d / 2 - 0.09)))
    return {"size_m": (w, h + 0.05, d)}


def chair_wood(b, p, rng):
    m = H.register_materials(b)
    h = p.get("height", 0.9)
    sh = 0.45
    w = p.get("width", 0.42)
    b.part("box", m["madera"], size=(w, 0.04, w), location=(0, sh, 0))
    for sx in (-1, 1):
        for sz in (-1, 1):
            b.part("box", m["madera_clara"], size=(0.04, sh, 0.04),
                   location=(sx * (w / 2 - 0.04), sh / 2, sz * (w / 2 - 0.04)))
    for i in range(2):
        b.part("box", m["madera"], size=(w, 0.04, 0.05), location=(0, sh + 0.22 + i * 0.14, -w / 2 + 0.05))
    for sx in (-1, 1):
        b.part("box", m["madera_clara"], size=(0.04, 0.36, 0.04),
               location=(sx * (w / 2 - 0.04), sh + 0.18, -w / 2 + 0.05))
    return {"size_m": (w, h, w)}


def rocking_chair(b, p, rng):
    """Silla de balanceo (guaniquito criollo)."""
    m = H.register_materials(b)
    chair_wood(b, p, rng)
    w = p.get("width", 0.42)
    for sx in (-1, 1):
        b.part("box", m["madera"], size=(0.05, 0.05, 0.85),
               rotation=(0, 0, 0), location=(sx * (w / 2 - 0.05), 0.06, 0.02))
        b.part("box", m["madera_clara"], size=(0.05, 0.14, 0.22),
               location=(sx * (w / 2 - 0.05), 0.09, 0.34))
    return {"size_m": (w, 0.95, 0.9)}


def sofa(b, p, rng):
    m = H.register_materials(b)
    w = p.get("width", rng.uniform(1.7, 2.2))
    d = 0.85
    h = 0.42
    fabric = m["petroleo"]
    b.part("box", fabric, size=(w, h, d), location=(0, h / 2, 0))
    b.part("box", fabric, size=(w, 0.55, 0.22), location=(0, h + 0.27, -d / 2 + 0.11))
    for sx in (-1, 1):
        b.part("box", fabric, size=(0.18, 0.30, d), location=(sx * (w / 2 - 0.09), h + 0.14, 0))
    b.part("box", m["crema"], size=(w - 0.4, 0.09, d - 0.3), location=(0, h + 0.045, 0.05))
    for sx in (-0.5, 0.5):
        b.part("box", m["crema"], size=(w * 0.42, 0.10, 0.35), location=(sx * w * 0.5, h + 0.06, 0.18))
    for sx in (-1, 1):
        for sz in (-1, 1):
            b.part("box", m["madera"], size=(0.06, 0.12, 0.06),
                   location=(sx * (w / 2 - 0.1), 0.06, sz * (d / 2 - 0.1)))
    return {"size_m": (w, 0.75, d)}


def wardrobe(b, p, rng):
    m = H.register_materials(b)
    w = p.get("width", rng.uniform(1.1, 1.5))
    h = p.get("height", rng.uniform(2.0, 2.3))
    d = 0.6
    b.part("box", m["madera"], size=(w, h, d), location=(0, h / 2, 0))
    b.part("box", m["madera_clara"], size=(w / 2 - 0.02, h - 0.12, 0.03),
           location=(-w / 4, h / 2 + 0.03, d / 2 + 0.005))
    b.part("box", m["madera_clara"], size=(w / 2 - 0.02, h - 0.12, 0.03),
           location=(w / 4, h / 2 + 0.03, d / 2 + 0.005))
    b.part("box", m["oro_viejo"], size=(0.04, 0.18, 0.04), location=(0, h * 0.55, d / 2 + 0.03))
    b.part("box", m["crema"], size=(w + 0.1, 0.1, d + 0.1), location=(0, h + 0.05, 0))
    return {"size_m": (w, h + 0.1, d)}


def bed(b, p, rng):
    m = H.register_materials(b)
    w = p.get("width", rng.uniform(1.0, 1.4))
    l = p.get("length", rng.uniform(1.9, 2.1))
    b.part("box", m["madera"], size=(w, 0.30, l), location=(0, 0.15, 0))
    b.part("box", m["crema"], size=(w - 0.08, 0.16, l - 0.08), location=(0, 0.38, 0))
    b.part("box", m["crema"], size=(w * 0.7, 0.12, 0.42), location=(0, 0.46, -l / 2 + 0.28))
    b.part("box", m["madera"], size=(w, 0.95, 0.07), location=(0, 0.48, -l / 2))
    for sx in (-1, 1):
        for sz in (-1, 1):
            b.part("box", m["madera_clara"], size=(0.09, 0.22, 0.09),
                   location=(sx * (w / 2 - 0.06), 0.11, sz * (l / 2 - 0.06)))
    b.part("box", m["petroleo"], size=(w - 0.2, 0.06, l * 0.55), location=(0, 0.47, l * 0.18))
    return {"size_m": (w, 0.95, l)}


def bookshelf(b, p, rng):
    m = H.register_materials(b)
    w = p.get("width", rng.uniform(0.8, 1.2))
    h = p.get("height", rng.uniform(1.8, 2.1))
    d = 0.32
    shelves = int(p.get("shelves", 4))
    b.part("box", m["madera"], size=(0.05, h, d), location=(-w / 2, h / 2, 0))
    b.part("box", m["madera"], size=(0.05, h, d), location=(w / 2, h / 2, 0))
    for i in range(shelves + 1):
        y = i * (h - 0.1) / shelves
        b.part("box", m["madera_clara"], size=(w, 0.04, d), location=(0, y + 0.05, 0))
        if i < shelves:
            x = -w / 2 + 0.06
            while x < w / 2 - 0.1:
                bw = rng.uniform(0.03, 0.06)
                bh = rng.uniform(0.18, 0.26)
                col = [m["carmesi"], m["ocre"], m["petroleo"], m["crema"]][int(rng.integers(0, 4))]
                b.part("box", col, size=(bw, bh, d * 0.7), location=(x + bw / 2, y + 0.05 + bh / 2, 0))
                x += bw + rng.uniform(0.005, 0.035)
    return {"size_m": (w, h, d)}


def lamp_floor(b, p, rng):
    m = H.register_materials(b)
    g = _g(p)
    seg = g["radial_segments"]
    h = p.get("height", rng.uniform(1.4, 1.7))
    b.part("cylinder", m["oro_viejo"], radius=0.16, depth=0.05, location=(0, 0.025, 0), segments=seg)
    b.part("cylinder", m["carbon"], radius=0.025, depth=h - 0.3, location=(0, (h - 0.3) / 2, 0),
           segments=seg, smooth=True)
    b.part("cone", m["ambar"], radius=0.22, depth=0.28, location=(0, h - 0.15, 0), segments=seg)
    b.part("cone", m["carbon"], radius=0.23, depth=0.04, location=(0, h + 0.02, 0), segments=seg)
    return {"height_m": h + 0.04}


def desk(b, p, rng):
    m = H.register_materials(b)
    w = p.get("width", rng.uniform(1.1, 1.5))
    h = 0.75
    d = 0.65
    b.part("box", m["madera"], size=(w, 0.05, d), location=(0, h, 0))
    b.part("box", m["madera_clara"], size=(w * 0.4, h - 0.08, 0.5),
           location=(w * 0.28, (h - 0.08) / 2 + 0.05, -0.02))
    for i in range(2):
        b.part("box", m["madera"], size=(w * 0.36, 0.02, 0.44),
               location=(w * 0.28, 0.35 + i * 0.3, 0))
    for sx in (-1, 1):
        b.part("box", m["madera_clara"], size=(0.06, h, 0.06),
               location=(sx * (w / 2 - 0.1), h / 2, d / 2 - 0.1))
    b.part("box", m["madera_clara"], size=(0.06, h, 0.06),
           location=(-w / 2 + 0.1, h / 2, -d / 2 + 0.1))
    return {"size_m": (w, h + 0.05, d)}


def counter_shop(b, p, rng):
    """Mostrador de comercio con tablero de zinc (tiendas de barrio)."""
    m = H.register_materials(b)
    w = p.get("width", rng.uniform(2.0, 3.0))
    h = p.get("height", rng.uniform(1.0, 1.15))
    d = 0.65
    b.part("box", m["madera"], size=(w, h - 0.06, d), location=(0, (h - 0.06) / 2, 0))
    b.part("box", m["zinc"], size=(w + 0.08, 0.06, d + 0.08), location=(0, h, 0))
    b.part("box", m["oro_viejo"], size=(w - 0.4, 0.04, 0.2), location=(0, h + 0.02, -d / 2 - 0.12))
    for i in range(3):
        b.part("box", m["petroleo"], size=(0.05, h - 0.2, 0.05),
               location=((i - 1) * w * 0.3, (h - 0.2) / 2 + 0.05, 0.05))
    return {"size_m": (w, h + 0.1, d + 0.1)}


FURNITURE_BUILDERS = {
    "table_wood": table_wood,
    "chair_wood": chair_wood,
    "rocking_chair": rocking_chair,
    "sofa": sofa,
    "wardrobe": wardrobe,
    "bed": bed,
    "bookshelf": bookshelf,
    "lamp_floor": lamp_floor,
    "desk": desk,
    "counter_shop": counter_shop,
}

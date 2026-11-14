"""Mobiliario urbano: faroles coloniales, bancos, papeleras, paradas de
guagua, alcantarillas, señales, bolardos y jardineras."""
from __future__ import annotations

import numpy as np

from generators.models import helpers as H

G_DEFAULTS = {"radial_segments": 8, "sphere_segments": (8, 6)}


def _g(p):
    return {**G_DEFAULTS, **(p.get("geometry") or {})}


def lamppost_colonial(b, p, rng):
    """Farol colonial (canon §3: encender faroles al anochecer)."""
    m = H.register_materials(b)
    g = _g(p)
    seg = g["radial_segments"]
    h = p.get("height", rng.uniform(2.6, 3.4))
    iron = m["carbon"]
    b.part("cylinder", m["caliza"], radius=0.16, depth=0.12, location=(0, 0.06, 0), segments=seg)
    b.part("cylinder", iron, radius=0.045, depth=h, location=(0, h / 2, 0), segments=seg, smooth=True)
    # farolilla: vidrio ámbar + estructura
    lh = 0.42
    top = h
    b.part("cylinder", m["ambar"], radius=0.14, depth=lh, location=(0, top + lh / 2, 0),
           segments=6, smooth=True)
    for i in range(6):
        a = i * np.pi / 3
        b.part("box", iron, size=(0.03, lh, 0.03),
               location=(np.cos(a) * 0.15, top + lh / 2, np.sin(a) * 0.15))
    b.part("cone", iron, radius=0.2, depth=0.22, location=(0, top + lh + 0.1, 0), segments=6)
    b.part("cone", m["oro_viejo"], radius=0.06, depth=0.1, location=(0, top + lh + 0.25, 0),
           segments=6)
    return {"height_m": h + lh + 0.3}


def lamppost_modern(b, p, rng):
    m = H.register_materials(b)
    g = _g(p)
    seg = g["radial_segments"]
    h = p.get("height", rng.uniform(4.0, 5.5))
    b.part("cylinder", m["petroleo"], radius=0.06, depth=h, location=(0, h / 2, 0),
           segments=seg, smooth=True)
    b.part("box", m["petroleo"], size=(0.8, 0.05, 0.05), location=(0.35, h, 0))
    b.part("box", m["ambar"], size=(0.34, 0.1, 0.16), location=(0.62, h - 0.02, 0))
    b.part("box", m["carbon"], size=(0.4, 0.06, 0.22), location=(0.62, h + 0.07, 0))
    return {"height_m": h}


def bench_park(b, p, rng):
    m = H.register_materials(b)
    w = p.get("width", rng.uniform(1.6, 2.4))
    seat_y = 0.45
    wood = m["madera_clara"]
    # listones del asiento
    for i in range(3):
        b.part("box", wood, size=(w, 0.04, 0.12), location=(0, seat_y, (i - 1) * 0.15))
    # patas
    for sx in (-1, 1):
        b.part("box", m["carbon"], size=(0.06, seat_y, 0.4),
               location=(sx * (w / 2 - 0.12), seat_y / 2, 0))
    return {"size_m": (w, 0.5, 0.45)}


def bench_street(b, p, rng):
    """Banco urbano con respaldo (guayabera de hierro + madera)."""
    m = H.register_materials(b)
    w = p.get("width", rng.uniform(1.8, 2.6))
    y = 0.45
    for i in range(3):
        b.part("box", m["madera_clara"], size=(w, 0.04, 0.12), location=(0, y, (i - 1) * 0.15))
    for i in range(4):
        b.part("box", m["madera_clara"], size=(w, 0.035, 0.1),
               rotation=(0.16, 0, 0), location=(0, y + 0.22 + i * 0.085, -0.22 + i * 0.085 * 0.16))
    for sx in (-1, 1):
        b.part("box", m["carbon"], size=(0.06, 0.8, 0.42), location=(sx * (w / 2 - 0.1), 0.4, 0))
    return {"size_m": (w, 0.75, 0.45)}


def trash_bin(b, p, rng):
    m = H.register_materials(b)
    g = _g(p)
    seg = g["radial_segments"]
    r = p.get("radius", rng.uniform(0.28, 0.38))
    h = p.get("height", rng.uniform(0.75, 0.95))
    b.part("cylinder", m["petroleo"], radius=r, depth=h, location=(0, h / 2, 0), segments=seg,
           smooth=True)
    b.part("cylinder", m["carbon"], radius=r + 0.02, depth=0.07, location=(0, h - 0.03, 0),
           segments=seg, smooth=True)
    b.part("cylinder", m["carbon"], radius=r * 0.55, depth=0.05, location=(0, h + 0.03, 0),
           segments=seg, smooth=True)
    return {"size_m": (r * 2, h + 0.05, r * 2)}


def bus_stop(b, p, rng):
    """Parada de guagua: estructura, techo de zinc, panel y banco."""
    m = H.register_materials(b)
    g = _g(p)
    seg = g["radial_segments"]
    w = p.get("width", 3.0)
    d = p.get("depth", 1.4)
    h = p.get("height", 2.4)
    for sx in (-1, 1):
        for sz in (-1, 1):
            b.part("box", m["carbon"], size=(0.07, h, 0.07),
                   location=(sx * (w / 2 - 0.05), h / 2, sz * (d / 2 - 0.05)))
    b.part("box", m["zinc"], size=(w + 0.2, 0.06, d + 0.2), location=(0, h, 0))
    b.part("box", m["petroleo"], size=(w, 1.2, 0.05), location=(0, 1.6, -d / 2 + 0.03))
    b.part("box", m["vidrio_oscuro"], size=(w, 0.85, 0.03), location=(0, 1.0, -d / 2 + 0.02))
    for i in range(3):
        b.part("box", m["madera_clara"], size=(w * 0.8, 0.04, 0.12),
               location=(0, 0.45, (i - 1) * 0.15 - 0.1))
    for sx in (-1, 1):
        b.part("box", m["carbon"], size=(0.05, 0.45, 0.4),
               location=(sx * (w * 0.4 - 0.1), 0.225, -0.1))
    b.part("box", m["oro_viejo"], size=(0.5, 0.25, 0.03), location=(w / 2 - 0.4, h - 0.4, d / 2))
    return {"size_m": (w, h, d)}


def manhole_cover(b, p, rng):
    m = H.register_materials(b)
    g = _g(p)
    seg = g["radial_segments"]
    r = p.get("radius", 0.4)
    dark = m["carbon"]
    b.part("cylinder", dark, radius=r, depth=0.05, location=(0, 0.025, 0), segments=seg, smooth=True)
    b.part("cylinder", m["petroleo"], radius=r * 0.75, depth=0.06, location=(0, 0.03, 0),
           segments=seg, smooth=True)
    for i in range(8):
        a = i * np.pi / 4
        b.part("box", m["oxido"], size=(0.06, 0.02, 0.06),
               location=(np.cos(a) * r * 0.85, 0.055, np.sin(a) * r * 0.85))
    return {"size_m": (r * 2, 0.06, r * 2)}


def traffic_sign_stop(b, p, rng):
    m = H.register_materials(b)
    g = _g(p)
    seg = g["radial_segments"]
    h = p.get("height", 2.1)
    b.part("cylinder", m["petroleo"], radius=0.035, depth=h, location=(0, h / 2, 0),
           segments=seg, smooth=True)
    b.part("cylinder", m["carmesi"], radius=0.32, depth=0.03, rotation=(np.pi / 2, 0, 0),
           location=(0, h + 0.05, 0), segments=8, smooth=True)
    b.part("cylinder", m["crema"], radius=0.10, depth=0.035, rotation=(np.pi / 2, 0, 0),
           location=(0, h + 0.05, 0.001), segments=8, smooth=True)
    return {"height_m": h + 0.37}


def bollard(b, p, rng):
    m = H.register_materials(b)
    g = _g(p)
    seg = g["radial_segments"]
    h = p.get("height", rng.uniform(0.7, 0.95))
    b.part("cylinder", m["carbon"], radius=0.09, depth=h, location=(0, h / 2, 0), segments=seg,
           smooth=True)
    b.part("sphere", m["petroleo"], radius=0.09, location=(0, h, 0), segments=seg, smooth=True)
    b.part("cylinder", m["caliza"], radius=0.13, depth=0.08, location=(0, 0.04, 0), segments=seg)
    return {"height_m": h + 0.09}


def planter_urban(b, p, rng):
    """Jardinera de hormigón con arbusto (vegetación de acera)."""
    m = H.register_materials(b)
    g = _g(p)
    seg = g["sphere_segments"][0]
    w = p.get("width", rng.uniform(0.9, 1.5))
    d = w * 0.55
    h = p.get("height", rng.uniform(0.5, 0.75))
    b.part("box", m["crema"], size=(w, h, d), location=(0, h / 2, 0))
    b.part("box", m["tierra_roja"], size=(w - 0.16, 0.06, d - 0.16), location=(0, h - 0.03, 0))
    for i in range(int(p.get("blobs", 3))):
        a = rng.uniform(0, 2 * np.pi)
        rr = rng.uniform(0.0, 0.18)
        b.part("sphere", m["manigua"] if i % 2 else m["manigua_claro"],
               radius=rng.uniform(0.18, 0.3),
               location=(np.cos(a) * rr, h + 0.16, np.sin(a) * rr), segments=seg, smooth=True)
    return {"size_m": (w, h + 0.5, d)}


URBAN_BUILDERS = {
    "lamppost_colonial": lamppost_colonial,
    "lamppost_modern": lamppost_modern,
    "bench_park": bench_park,
    "bench_street": bench_street,
    "trash_bin": trash_bin,
    "bus_stop": bus_stop,
    "manhole_cover": manhole_cover,
    "traffic_sign_stop": traffic_sign_stop,
    "bollard": bollard,
    "planter_urban": planter_urban,
}

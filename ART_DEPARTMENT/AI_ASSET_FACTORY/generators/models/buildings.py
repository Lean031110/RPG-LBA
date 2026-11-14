"""Edificios modulares paramétricos.

Parámetros comunes (mandato §6): ancho, fondo, pisos, ventanas por piso,
tipo de tejado, color de fachada (colonial envejecido), estado de
conservación, elementos decorativos (portal, balcón, toldo...).
"""
from __future__ import annotations

import numpy as np

from core.utils import hex_to_rgb01
from generators.models import helpers as H

G_DEFAULTS = {"radial_segments": 8, "sphere_segments": (8, 6)}

# Fachadas coloniales envejecidas (INITIAL_AUDIT.md §4)
FACADES = {
    "ocre": hex_to_rgb01("#B89C5A"),
    "turquesa": hex_to_rgb01("#6E9A96"),
    "coral": hex_to_rgb01("#B96A5A"),
    "crema": hex_to_rgb01("#D1C6A8"),
    "caliza": hex_to_rgb01("#C9BFAB"),
}


def _g(p):
    return {**G_DEFAULTS, **(p.get("geometry") or {})}


def _facade_mat(b, p, rng):
    color = FACADES[p.get("facade", "ocre")]
    decay = float(p.get("decay", 0.35))
    c = np.array(color)
    aged = np.clip(c * (1 - 0.25 * decay) + np.array([0.08, 0.075, 0.07]) * decay, 0, 1)
    return b.mat("m_fachada", tuple(aged), roughness=0.92, metallic=0.0)


def _hip_roof(b, m, w, d, y_base, rise, mat_roof):
    # cono del DSL: base en y_base, punta hacia +Y
    b.part("cone", mat_roof, radius=max(w, d) * 0.71, depth=rise, segments=4,
           rotation=(0, np.pi / 4, 0), location=(0, y_base, 0))
    over = 0.28
    b.part("box", mat_roof, size=(w + over, 0.12, 0.22), location=(0, y_base - 0.02, d / 2 + over - 0.11))
    b.part("box", mat_roof, size=(w + over, 0.12, 0.22), location=(0, y_base - 0.02, -d / 2 - over + 0.11))
    b.part("box", mat_roof, size=(0.22, 0.12, d + over), location=(w / 2 + over - 0.11, y_base - 0.02, 0))
    b.part("box", mat_roof, size=(0.22, 0.12, d + over), location=(-w / 2 - over + 0.11, y_base - 0.02, 0))


def _facade_windows(b, m, w, floors, n_win, y0, floor_h, z_face, door=False):
    for f in range(floors):
        y = y0 + f * floor_h
        if f == 0 and door:
            H.door_colonial(b, m, (0 if n_win % 2 else w * 0.15), z_face, w=0.95, h=2.1)
            start = 1
        else:
            start = 0
        for i in range(start, n_win):
            t = (i + 0.5) / n_win
            x = (t - 0.5) * w
            H.window_colonial(b, m, x, y + 0.6, z_face, w=0.62, h=0.95, shutters=f == floors - 1)


def _base_plinth(b, m, w, d, h):
    b.part("box", m["caliza"], size=(w + 0.12, h, d + 0.12), location=(0, h / 2, 0))


# ================================================================ CASAS
def house_colonial_01(b, p, rng):
    """Casa colonial de 1 piso con portal y tejado a 4 aguas."""
    m = H.register_materials(b)
    w = p.get("width", rng.uniform(6.0, 8.5))
    d = p.get("depth", rng.uniform(5.0, 7.0))
    fh = p.get("floor_height", 3.0)
    facade = _facade_mat(b, p, rng)
    roof = m["teja"]
    _base_plinth(b, m, w, d, 0.25)
    b.part("box", facade, size=(w, fh, d), location=(0, 0.25 + fh / 2, 0))
    _facade_windows(b, m, w, 1, int(p.get("windows", 4)), 0.25, fh, d / 2, door=True)
    # portal: dos columnas + losa voladiza
    for sx in (-1, 1):
        H.column(b, m, sx * (w / 2 - 0.35), d / 2 + 0.6, 2.8, radius=0.12)
    b.part("box", m["crema"], size=(w, 0.12, 1.5), location=(0, 0.25 + fh, d / 2 + 0.75))
    _hip_roof(b, m, w, d, 0.25 + fh + 0.06, p.get("rise", rng.uniform(1.3, 2.0)), roof)
    return {"pisos": 1, "size_m": (w, fh + 2.0, d)}


def house_colonial_02(b, p, rng):
    """Casa colonial de 2 pisos con balcón de hierro (typical Malecón)."""
    m = H.register_materials(b)
    w = p.get("width", rng.uniform(6.5, 9.0))
    d = p.get("depth", rng.uniform(5.5, 7.5))
    floors = int(p.get("floors", 2))
    fh = p.get("floor_height", 3.0)
    facade = _facade_mat(b, p, rng)
    _base_plinth(b, m, w, d, 0.3)
    for f in range(floors):
        y = 0.3 + f * fh
        b.part("box", facade, size=(w, fh, d), location=(0, y + fh / 2, 0))
    # moldura entre pisos
    b.part("box", m["crema"], size=(w + 0.08, 0.14, d + 0.08), location=(0, 0.3 + fh, 0))
    _facade_windows(b, m, w, floors, int(p.get("windows", 4)), 0.3, fh, d / 2, door=True)
    # balcón corrido en el primer piso superior
    y0 = 0.3 + fh
    b.part("box", m["crema"], size=(w * 0.8, 0.12, 0.85), location=(0, y0, d / 2 + 0.42))
    H.railing(b, m["carbon"], width=w * 0.8, height=0.95, y0=y0 + 0.06, z=d / 2 + 0.78, axis="x",
              posts=8)
    _hip_roof(b, m, w, d, 0.3 + floors * fh + 0.08, p.get("rise", rng.uniform(1.4, 2.2)), m["teja"])
    return {"pisos": floors, "size_m": (w, floors * fh + 2.5, d)}


def shop_facade(b, p, rng):
    """Comercio de barrio: escaparate, toldo y rótulo (oro viejo)."""
    m = H.register_materials(b)
    w = p.get("width", rng.uniform(5.0, 7.0))
    d = p.get("depth", 5.0)
    fh = p.get("floor_height", 3.2)
    facade = _facade_mat(b, p, rng)
    _base_plinth(b, m, w, d, 0.2)
    b.part("box", facade, size=(w, fh, d), location=(0, 0.2 + fh / 2, 0))
    # escaparate ancho
    b.part("box", m["vidrio_petroleo"], size=(w * 0.6, 1.7, 0.06), location=(-w * 0.12, 1.25, d / 2))
    b.part("box", m["madera"], size=(w * 0.62, 0.1, 0.14), location=(-w * 0.12, 2.15, d / 2))
    b.part("box", m["madera"], size=(0.08, 1.7, 0.14), location=(-w * 0.42, 1.25, d / 2))
    b.part("box", m["madera"], size=(0.08, 1.7, 0.14), location=(w * 0.18, 1.25, d / 2))
    H.door_colonial(b, m, w * 0.36, d / 2, w=0.9, h=2.05)
    # toldo
    b.part("box", m["carmesi"], size=(w * 0.68, 0.05, 1.1), rotation=(0.22, 0, 0),
           location=(-w * 0.12, 2.45, d / 2 + 0.5))
    for sx in (-1, 1):
        b.part("box", m["madera"], size=(0.05, 0.05, 1.05), rotation=(0.22, 0, 0),
               location=(-w * 0.12 + sx * w * 0.33, 2.42, d / 2 + 0.5))
    # rótulo
    b.part("box", m["carbon"], size=(w * 0.5, 0.5, 0.08), location=(-w * 0.12, 2.85, d / 2 + 0.02))
    b.part("box", m["oro_viejo"], size=(w * 0.36, 0.08, 0.1), location=(-w * 0.12, 2.92, d / 2 + 0.04))
    _hip_roof(b, m, w, d, 0.2 + fh + 0.06, rng.uniform(0.9, 1.4), m["zinc"])
    return {"pisos": 1, "size_m": (w, fh + 1.5, d)}


def apartment_block(b, p, rng):
    """Bloque de apartamentos: 3 pisos, azotea plana con pretil."""
    m = H.register_materials(b)
    w = p.get("width", rng.uniform(12.0, 16.0))
    d = p.get("depth", rng.uniform(9.0, 11.0))
    floors = int(p.get("floors", 3))
    fh = p.get("floor_height", 3.0)
    facade = _facade_mat(b, p, rng)
    _base_plinth(b, m, w, d, 0.25)
    for f in range(floors):
        b.part("box", facade, size=(w, fh, d), location=(0, 0.25 + f * fh + fh / 2, 0))
        for i in range(int(p.get("windows", 5))):
            t = (i + 0.5) / int(p.get("windows", 5))
            x = (t - 0.5) * (w - 0.8)
            H.window_colonial(b, m, x, 0.25 + f * fh + 0.7, d / 2, w=0.65, h=1.05, shutters=False)
        # balcónes alternos
        if f % 2 == 0:
            for i in range(0, int(p.get("windows", 5)), 2):
                t = (i + 0.5) / int(p.get("windows", 5))
                x = (t - 0.5) * (w - 0.8)
                y = 0.25 + f * fh
                b.part("box", m["crema"], size=(1.6, 0.1, 0.7), location=(x, y, d / 2 + 0.35))
                H.railing(b, m["petroleo"], width=1.6, height=0.9, y0=y + 0.05, z=d / 2 + 0.65,
                          axis="x", posts=4)
    # pretil de azotea
    for sx in (-1, 1):
        b.part("box", m["crema"], size=(w, 0.9, 0.15), location=(0, 0.25 + floors * fh + 0.45, sx * (d / 2)))
    for sx in (-1, 1):
        b.part("box", m["crema"], size=(0.15, 0.9, d), location=(sx * (w / 2), 0.25 + floors * fh + 0.45, 0))
    # escalera de acceso a azotea
    b.part("box", m["crema"], size=(2.2, 2.2, 1.2), location=(w / 2 - 1.2, 0.25 + floors * fh + 1.1, -d / 2 + 0.7))
    return {"pisos": floors, "size_m": (w, floors * fh + 1.4, d)}


def corner_house(b, p, rng):
    """Casa en esquina: dos cuerpos en L con alturas distintas."""
    m = H.register_materials(b)
    w1 = p.get("width", rng.uniform(5.0, 6.5))
    d1 = w1 * 0.7
    floors1 = int(p.get("floors", 2))
    fh = 3.0
    facade = _facade_mat(b, p, rng)
    # cuerpo principal
    b.part("box", facade, size=(w1, floors1 * fh, d1),
           location=(0, floors1 * fh / 2, 0))
    _facade_windows(b, m, w1, floors1, 3, 0, fh, d1 / 2, door=True)
    _hip_roof(b, m, w1, d1, floors1 * fh + 0.05, rng.uniform(1.2, 1.6), m["teja"])
    # cuerpo secundario perpendicular
    w2 = d1 * 0.9
    d2 = w1 * 0.55
    off = w1 / 2 + d2 / 2 - 0.3
    b.part("box", facade, size=(d2, fh, w2), location=(off, fh / 2, -d1 / 2 - w2 / 2 + 0.3))
    H.door_colonial(b, m, off, -d1 / 2 - w2 + 0.35, w=0.95, h=2.05, facing="x")
    H.window_colonial(b, m, off, 0.8, -d1 / 2 - w2 + 0.35, w=0.6, h=0.9, facing="x")
    b.part("cone", m["zinc"], radius=max(d2, w2) * 0.72, depth=1.0, segments=4,
           rotation=(0, np.pi / 4, 0), location=(off, fh, -d1 / 2 - w2 / 2 + 0.3))
    return {"pisos": floors1, "size_m": (w1 + d2, floors1 * fh + 1.6, d1 + w2)}


BUILDING_BUILDERS = {
    "house_colonial_01": house_colonial_01,
    "house_colonial_02": house_colonial_02,
    "shop_facade": shop_facade,
    "apartment_block": apartment_block,
    "corner_house": corner_house,
}

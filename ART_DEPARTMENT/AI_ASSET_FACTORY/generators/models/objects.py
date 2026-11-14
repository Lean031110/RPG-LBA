"""Objetos decorativos y utilería (barriles, cajas, macetas, letreros)."""
from __future__ import annotations

import numpy as np

from generators.models import helpers as H

G_DEFAULTS = {"radial_segments": 8, "sphere_segments": (8, 6)}


def _g(p):
    return {**G_DEFAULTS, **(p.get("geometry") or {})}


def barrel_rum(b, p, rng):
    """Barril de ron con aros de metal envejecido."""
    m = H.register_materials(b)
    g = _g(p)
    seg = g["radial_segments"]
    h = p.get("height", rng.uniform(0.85, 1.05))
    r = p.get("radius", rng.uniform(0.32, 0.42))
    b.part("cylinder", m["madera"], radius=r, depth=h, location=(0, h / 2, 0), segments=seg,
           smooth=True)
    b.part("cylinder", m["madera"], radius=r * 0.55, depth=0.04, location=(0, h + 0.02, 0),
           segments=seg, smooth=True)
    for i in range(3):
        y = h * (0.12 + 0.38 * i)
        rr = r * (0.98 + 0.05 * np.sin(y / h * np.pi))
        b.part("cylinder", m["oxido"], radius=rr + 0.01, depth=0.05, location=(0, y, 0),
               segments=seg, smooth=True)
    return {"size_m": (r * 2, h, r * 2)}


def crate_wood(b, p, rng):
    """Caja de madera de ron (jaba) con listones."""
    m = H.register_materials(b)
    s = p.get("size", rng.uniform(0.5, 0.8))
    b.part("box", m["madera"], size=(s, s, s), location=(0, s / 2, 0))
    for sx in (-1, 1):
        b.part("box", m["madera_clara"], size=(0.05, s, s * 0.2), location=(sx * (s / 2 - 0.02), s / 2, 0))
    b.part("box", m["madera_clara"], size=(s, 0.05, s * 0.2), location=(0, s - 0.02, 0))
    b.part("box", m["carmesi"], size=(s * 0.3, 0.06, 0.02), location=(0, s * 0.6, s / 2 + 0.01))
    return {"size_m": (s, s, s)}


def terracotta_pot(b, p, rng):
    """Maceta de barro con planta de interior."""
    m = H.register_materials(b)
    g = _g(p)
    seg = g["radial_segments"]
    r = p.get("radius", rng.uniform(0.18, 0.3))
    h = p.get("height", r * 1.4)
    b.part("cylinder", m["teja"], radius=r, depth=h, location=(0, h / 2, 0), segments=seg, smooth=True)
    b.part("cylinder", m["teja"], radius=r * 0.8, depth=h * 0.16, location=(0, h * 0.9, 0),
           segments=seg, smooth=True)
    b.part("cylinder", m["tierra_roja"], radius=r * 0.72, depth=0.04, location=(0, h + 0.01, 0),
           segments=seg, smooth=True)
    for i in range(int(p.get("leaves", 5))):
        a = rng.uniform(0, 2 * np.pi)
        d = rng.uniform(0.15, 0.5)
        b.part("box", m["manigua_claro"], size=(r * 1.3, 0.02, 0.08),
               rotation=(0, -a, -d), location=(np.cos(a) * r * 0.5, h + r * 0.7, np.sin(a) * r * 0.5))
    return {"size_m": (r * 2, h + r * 0.8, r * 2)}


def hanging_sign(b, p, rng):
    """Letrero colgante de comercio con brazo de hierro."""
    m = H.register_materials(b)
    g = _g(p)
    seg = g["radial_segments"]
    post_h = p.get("post_height", 2.6)
    b.part("cylinder", m["carbon"], radius=0.05, depth=post_h, location=(0, post_h / 2, 0),
           segments=seg, smooth=True)
    b.part("box", m["carbon"], size=(0.8, 0.04, 0.04), location=(0.45, post_h - 0.1, 0))
    b.part("box", m["crema"], size=(0.6, 0.4, 0.04), location=(0.55, post_h - 0.45, 0))
    b.part("box", m["oro_viejo"], size=(0.42, 0.06, 0.05), location=(0.55, post_h - 0.42, 0.01))
    b.part("box", m["carmesi"], size=(0.42, 0.04, 0.05), location=(0.55, post_h - 0.52, 0.01))
    b.part("cylinder", m["oro_viejo"], radius=0.012, depth=0.16, location=(0.32, post_h - 0.3, 0),
           segments=6)
    return {"height_m": post_h}


def crate_stack(b, p, rng):
    """Pila de jabas apiladas con ligera rotación (almacén)."""
    m = H.register_materials(b)
    crate_wood(b, {"size": p.get("size", 0.6)}, rng)
    s = p.get("size", 0.6)
    b.part("box", m["madera_clara"], size=(s * 0.95, s * 0.95, s * 0.95),
           rotation=(0, rng.uniform(-0.25, 0.25), 0), location=(0.05, s * 1.5, 0.03))
    b.part("box", m["madera"], size=(s * 0.8, s * 0.8, s * 0.8),
           rotation=(0, rng.uniform(-0.35, 0.35), 0), location=(-0.04, s * 2.32, -0.02))
    return {"size_m": (s, s * 2.8, s)}


OBJECT_BUILDERS = {
    "barrel_rum": barrel_rum,
    "crate_wood": crate_wood,
    "terracotta_pot": terracotta_pot,
    "hanging_sign": hanging_sign,
    "crate_stack": crate_stack,
}

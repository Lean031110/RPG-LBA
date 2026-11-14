"""Generadores de naturaleza: vegetación tropical y elementos naturales.

Todo es paramétrico (altura, copa, densidad, variación) y usa materiales
del canon gótico-caribeño. Cada llamada con semilla distinta produce una
variación REAL (jitter de proporciones y disposición), no una copia.
"""
from __future__ import annotations

import numpy as np

from generators.models import helpers as H

G_DEFAULTS = {"radial_segments": 8, "sphere_segments": (8, 6)}


def _g(p):
    return {**G_DEFAULTS, **(p.get("geometry") or {})}


def _seg(g, sphere=False):
    if sphere:
        return g["sphere_segments"][0]
    return g["radial_segments"]


# ================================================== VEGETACIÓN (categoría)
def palm_royal(b, p, rng):
    """Palma real: tronco alto esbelto, corona de hojas y yema."""
    m = H.register_materials(b)
    g = _g(p)
    h = p.get("height", rng.uniform(7.5, 11.0))
    r = p.get("trunk_r", 0.14)
    lean = rng.uniform(-0.05, 0.05)
    seg = _seg(g)
    for i in range(5):
        t0 = i / 5
        b.part("cylinder", m["madera"], radius=r * (1.0 - 0.25 * t0), depth=h / 5,
               rotation=(lean * rng.uniform(0.7, 1.3), 0, 0),
               location=(lean * h * 0.5 * t0, h / 5 * (i + 0.5), 0), segments=seg, smooth=True)
    b.part("sphere", m["manigua_claro"], radius=0.22, location=(lean * h * 0.5, h, 0),
           segments=_seg(g, True), smooth=True)
    H.fronds(b, m["manigua"], h, count=int(p.get("fronds", 9)), length=rng.uniform(2.4, 3.4),
             tilt=rng.uniform(0.12, 0.3), rng=rng, segments=seg)
    return {"height_m": h}


def palm_coconut(b, p, rng):
    """Cocotero: tronco curvado, hojas grandes y cocos."""
    m = H.register_materials(b)
    g = _g(p)
    h = p.get("height", rng.uniform(5.0, 8.0))
    r = p.get("trunk_r", 0.18)
    seg = _seg(g)
    lean = rng.uniform(0.10, 0.26)
    for i in range(6):
        t0 = i / 6
        b.part("cylinder", m["madera"], radius=r * (1.0 - 0.3 * t0), depth=h / 6,
               rotation=(0, 0, lean * 0.9),
               location=(lean * h * 0.55 * t0, h / 6 * (i + 0.5) + 0.07, 0), segments=seg,
               smooth=True)
    top = (lean * h * 0.55, h, 0)
    H.fronds(b, m["manigua"], h, count=7, length=rng.uniform(2.8, 3.8),
             tilt=rng.uniform(0.25, 0.45), rng=rng, segments=seg)
    for i in range(3):
        a = rng.uniform(0, 2 * np.pi)
        b.part("sphere", m["madera"], radius=0.14,
               location=(top[0] + np.cos(a) * 0.25, h - 0.35, np.sin(a) * 0.25),
               segments=max(6, _seg(g, True) - 2), smooth=True)
    return {"height_m": h}


def tree_ceiba(b, p, rng):
    """Ceiba: tronco grueso con contrafuertes y copa ancha (canon §2)."""
    m = H.register_materials(b)
    g = _g(p)
    h = p.get("height", rng.uniform(6.0, 9.0))
    r = p.get("trunk_r", rng.uniform(0.45, 0.7))
    seg = _seg(g)
    b.part("cylinder", m["madera"], radius=r, depth=h * 0.62,
           location=(0, h * 0.31, 0), segments=seg, smooth=True)
    for i in range(4):
        a = i * np.pi / 2 + rng.uniform(-0.2, 0.2)
        b.part("cone", m["madera"], radius=r * 0.55, depth=h * 0.22,
               rotation=(np.cos(a) * 0.5, 0, np.sin(a) * 0.5),
               location=(np.cos(a) * r * 1.1, h * 0.10, np.sin(a) * r * 1.1), segments=4)
    for i in range(3):
        a = rng.uniform(0, 2 * np.pi)
        b.part("cylinder", m["madera"], radius=r * 0.45, depth=h * 0.35,
               rotation=(np.sin(a) * 0.5, 0, -np.cos(a) * 0.5),
               location=(np.cos(a) * r * 0.8, h * 0.62, np.sin(a) * r * 0.8), segments=seg - 2,
               smooth=True)
    H.canopy(b, m["manigua"], (0, h * 0.78, 0), radius=h * 0.32, blobs=int(p.get("blobs", 6)),
             rng=rng, segments=_seg(g, True))
    return {"height_m": h}


def tree_mango(b, p, rng):
    """Árbol frutal de copa redonda (mango)."""
    m = H.register_materials(b)
    g = _g(p)
    h = p.get("height", rng.uniform(4.0, 6.0))
    r = p.get("trunk_r", rng.uniform(0.22, 0.34))
    seg = _seg(g)
    b.part("cylinder", m["madera"], radius=r, depth=h * 0.55, location=(0, h * 0.275, 0),
           segments=seg, smooth=True)
    for i in range(2):
        a = rng.uniform(0, 2 * np.pi)
        b.part("cylinder", m["madera"], radius=r * 0.6, depth=h * 0.3,
               rotation=(np.sin(a) * 0.6, 0, -np.cos(a) * 0.6),
               location=(np.cos(a) * r * 1.2, h * 0.62, np.sin(a) * r * 1.2), segments=seg - 2,
               smooth=True)
    H.canopy(b, m["manigua"], (0, h * 0.72, 0), radius=h * 0.34, blobs=int(p.get("blobs", 5)),
             rng=rng, segments=_seg(g, True))
    return {"height_m": h}


def tree_flamboyan(b, p, rng):
    """Flamboyán: copa plana ancha con puntos carmesí (flamboyanes)."""
    m = H.register_materials(b)
    g = _g(p)
    h = p.get("height", rng.uniform(4.5, 6.5))
    seg = _seg(g)
    r = rng.uniform(0.25, 0.35)
    b.part("cylinder", m["madera"], radius=r, depth=h * 0.6, location=(0, h * 0.3, 0),
           segments=seg, smooth=True)
    cy = h * 0.68
    for i in range(int(p.get("pads", 7))):
        a = i * 2 * np.pi / 7
        rr = rng.uniform(0.4, 0.9) * h * 0.35
        b.part("sphere", m["manigua"], radius=rng.uniform(0.7, 1.15),
               location=(np.cos(a) * rr, cy + rng.uniform(-0.1, 0.25), np.sin(a) * rr),
               segments=_seg(g, True), smooth=True)
    for i in range(int(p.get("flowers", 10))):
        a = rng.uniform(0, 2 * np.pi)
        rr = rng.uniform(0.6, 1.35) * h * 0.35
        b.part("sphere", m["carmesi"], radius=0.09,
               location=(np.cos(a) * rr, cy + rng.uniform(0.0, 0.3), np.sin(a) * rr),
               segments=max(5, _seg(g, True) - 3), smooth=True)
    return {"height_m": h}


def bush_tropical(b, p, rng):
    """Arbusto de manigua: matas apretadas con claros."""
    m = H.register_materials(b)
    g = _g(p)
    r = p.get("radius", rng.uniform(0.5, 0.9))
    for i in range(int(p.get("blobs", 5))):
        a = rng.uniform(0, 2 * np.pi)
        rr = rng.uniform(0.1, 0.65) * r
        sr = r * rng.uniform(0.4, 0.6)
        b.part("sphere", m["manigua"] if i % 2 else m["manigua_claro"],
               radius=sr,
               location=(np.cos(a) * rr, rng.uniform(0.85, 1.15) * r, np.sin(a) * rr),
               segments=_seg(g, True), smooth=True)
    return {"radius_m": r}


def grass_clump(b, p, rng):
    """Mata de hierba alta en grupos (canon §2: hierba agrupada)."""
    m = H.register_materials(b)
    h = p.get("height", rng.uniform(0.35, 0.6))
    H.grass_blades(b, m["manigua_claro"], count=int(p.get("blades", 14)), height=h,
                   spread=p.get("spread", 0.16), rng=rng)
    H.grass_blades(b, m["manigua"], count=7, height=h * 0.7, spread=0.10, rng=rng)
    return {"height_m": h}


def fern(b, p, rng):
    """Helecho: frondes arqueadas desde el centro."""
    m = H.register_materials(b)
    g = _g(p)
    seg = _seg(g)
    h = p.get("height", rng.uniform(0.45, 0.8))
    b.part("sphere", m["musgo"], radius=0.06, location=(0, 0.05, 0),
           segments=max(5, seg - 3), smooth=True)
    for i in range(int(p.get("fronds", 8))):
        a = i * 2 * np.pi / max(1, int(p.get("fronds", 8)))
        d = rng.uniform(0.35, 0.65)
        b.part("box", m["manigua_claro"], size=(h * 0.95, 0.015, 0.09),
               rotation=(0, -a, -d),
               location=(np.cos(a) * h * 0.42, h * 0.5, np.sin(a) * h * 0.42))
    return {"height_m": h}


def hedge(b, p, rng):
    """Seto de parque: volumen con ondulación."""
    m = H.register_materials(b)
    g = _g(p)
    w = p.get("width", 2.0)
    h = p.get("height", rng.uniform(0.55, 0.85))
    d = p.get("depth", 0.45)
    b.part("box", m["manigua"], size=(w, h, d), location=(0, h / 2, 0))
    for i in range(int(w * 2)):
        x = (rng.uniform(-0.5, 0.5)) * w
        b.part("sphere", m["manigua_claro"], radius=rng.uniform(0.12, 0.22),
               location=(x, h + rng.uniform(-0.05, 0.05), rng.uniform(-d / 2, d / 2)),
               segments=max(5, _seg(g, True) - 3), smooth=True)
    return {"size_m": (w, h, d)}


def flowers_patch(b, p, rng):
    """Mata de flores carmesí/ámbar sobre hierba (detalle de parques)."""
    m = H.register_materials(b)
    h = p.get("height", rng.uniform(0.3, 0.5))
    H.grass_blades(b, m["manigua"], count=10, height=h, spread=0.14, rng=rng)
    cols = p.get("flowers", ["carmesi", "ambar"])
    for i in range(int(p.get("n_flowers", 6))):
        a = rng.uniform(0, 2 * np.pi)
        rr = rng.uniform(0.0, 0.16)
        key = cols[i % len(cols)]
        b.part("sphere", m[key], radius=rng.uniform(0.05, 0.08),
               location=(np.cos(a) * rr, h * rng.uniform(0.85, 1.1), np.sin(a) * rr),
               segments=5, smooth=True)
    return {"height_m": h}


# ===================================================== ROCAS (categoría)
def rock_boulder(b, p, rng):
    m = H.register_materials(b)
    g = _g(p)
    seg = _seg(g, True)
    r = p.get("radius", rng.uniform(0.8, 1.6))
    # roca facetada: esfera tangente al suelo + cristales cónicos incrustados
    b.part("sphere", m["caliza"], radius=r, location=(0, r, 0), segments=seg, smooth=True)
    for i in range(int(p.get("facets", 5))):
        a = rng.uniform(0, 2 * np.pi)
        e = rng.uniform(0.0, np.pi / 2.5)
        b.part("cone", m["caliza"], radius=r * rng.uniform(0.28, 0.5),
               depth=r * rng.uniform(0.5, 0.9),
               rotation=(np.cos(a) * e, 0, np.sin(a) * e),
               location=(np.cos(a) * r * 0.75, r * 0.55, np.sin(a) * r * 0.75), segments=4)
    return {"radius_m": r}


def rock_round(b, p, rng):
    m = H.register_materials(b)
    seg = _seg(_g(p), True)
    r = p.get("radius", rng.uniform(0.3, 0.8))
    b.part("sphere", m["caliza"], radius=r, location=(0, r, 0), segments=seg, smooth=True)
    b.part("sphere", m["caliza"], radius=r * 0.55, location=(r * 0.6, r * 0.75, r * 0.3),
           segments=max(5, seg - 3), smooth=True)
    return {"radius_m": r}


def rock_mossy(b, p, rng):
    out = rock_round(b, p, rng)
    m = H.register_materials(b)
    seg = _seg(_g(p), True)
    r = out["radius_m"]
    for i in range(4):
        a = rng.uniform(0, 2 * np.pi)
        b.part("sphere", m["musgo"], radius=r * rng.uniform(0.22, 0.34),
               location=(np.cos(a) * r * 0.6, r * 0.72, np.sin(a) * r * 0.6),
               segments=max(5, seg - 3), smooth=True)
    return out


def rock_sandstone(b, p, rng):
    """Roca estratificada (arenisca ocre)."""
    m = H.register_materials(b)
    w = p.get("width", rng.uniform(0.8, 1.4))
    layers = int(p.get("layers", 4))
    for i in range(layers):
        t = i / max(1, layers - 1)
        mat = m["ocre"] if i % 2 else m["caliza"]
        b.part("box", mat, size=(w * (1.0 - 0.15 * t), 0.18 + rng.uniform(0, 0.1),
                                 w * 0.7 * (1.0 - 0.15 * t)),
               location=(rng.uniform(-0.05, 0.05) * w, 0.12 + i * 0.24, rng.uniform(-0.05, 0.05) * w))
    return {"size_m": (w, layers * 0.26, w * 0.7)}


def pebbles_set(b, p, rng):
    m = H.register_materials(b)
    seg = _seg(_g(p), True)
    n = int(p.get("pebbles", 9))
    for i in range(n):
        a = rng.uniform(0, 2 * np.pi)
        rr = rng.uniform(0.05, 0.5)
        r = rng.uniform(0.05, 0.14)
        mat = m["caliza"] if i % 3 else m["tierra_roja"]
        b.part("sphere", mat, radius=r, location=(np.cos(a) * rr, r * 0.95, np.sin(a) * rr),
               segments=max(5, seg - 3), smooth=True)
    return {"pebbles": n}


def rock_roadside(b, p, rng):
    """Piedra de borde de camino (alargada, caliza)."""
    m = H.register_materials(b)
    seg = _seg(_g(p), True)
    w = p.get("width", rng.uniform(1.0, 1.8))
    b.part("sphere", m["caliza"], radius=0.45, location=(0, 0.44, 0), segments=seg, smooth=True)
    b.part("box", m["caliza"], size=(w, 0.42, 0.55), location=(0, 0.26, 0))
    return {"size_m": (w, 0.6, 0.55)}


def rock_volcanic(b, p, rng):
    """Bloque volcánico oscuro (mazmorras/dungeons)."""
    m = H.register_materials(b)
    seg = _seg(_g(p), True)
    r = p.get("radius", rng.uniform(0.5, 1.0))
    b.part("sphere", m["carbon"], radius=r, location=(0, r, 0), segments=seg, smooth=True)
    for i in range(int(p.get("spikes", 4))):
        a = rng.uniform(0, 2 * np.pi)
        b.part("cone", m["carbon"], radius=r * 0.22, depth=r * rng.uniform(0.4, 0.8),
               rotation=(np.cos(a) * 0.9, 0, np.sin(a) * 0.9),
               location=(np.cos(a) * r * 0.6, r * 0.55, np.sin(a) * r * 0.6), segments=4)
    return {"radius_m": r}


def rock_coral(b, p, rng):
    """Roca caliza erosionada porosa (costa)."""
    m = H.register_materials(b)
    seg = _seg(_g(p), True)
    r = p.get("radius", rng.uniform(0.4, 0.9))
    b.part("sphere", m["caliza"], radius=r, location=(0, r, 0), segments=seg, smooth=True)
    for i in range(int(p.get("pores", 6))):
        a = rng.uniform(0, 2 * np.pi)
        rr = r * rng.uniform(0.35, 0.75)
        b.part("sphere", m["petroleo"], radius=r * rng.uniform(0.12, 0.2),
               location=(np.cos(a) * rr, r * 0.7, np.sin(a) * rr),
               segments=max(4, seg - 4), smooth=True)
    return {"radius_m": r}


def rock_stack_cairn(b, p, rng):
    """Mojón de piedras apiladas (hitos de camino)."""
    m = H.register_materials(b)
    seg = _seg(_g(p), True)
    base_r = p.get("radius", rng.uniform(0.45, 0.7))
    floor_y = 0.0
    for i in range(3):
        r = base_r * (1.0 - 0.28 * i)
        b.part("sphere", m["caliza"] if i % 2 else m["crema"], radius=r,
               location=(rng.uniform(-0.04, 0.04), floor_y + r, rng.uniform(-0.04, 0.04)),
               segments=max(5, seg - 2), smooth=True)
        floor_y += r * 0.9
    return {"height_m": floor_y}


def log_fallen(b, p, rng):
    """Tronco caído con tocones de musgo."""
    m = H.register_materials(b)
    g = _g(p)
    seg = _seg(g)
    length = p.get("length", rng.uniform(1.2, 2.6))
    r = rng.uniform(0.14, 0.24)
    b.part("cylinder", m["madera"], radius=r, depth=length, rotation=(0, 0, np.pi / 2),
           location=(0, r, 0), segments=seg, smooth=True)
    for i in range(3):
        b.part("sphere", m["musgo"], radius=r * 0.5,
               location=(rng.uniform(-length / 2, length / 2), r * 0.9, rng.uniform(-r / 2, r / 2)),
               segments=max(5, _seg(g, True) - 3), smooth=True)
    return {"length_m": length}


# ------------------------------------------------------------ registro
VEGETATION_BUILDERS = {
    "palm_royal": palm_royal,
    "palm_coconut": palm_coconut,
    "tree_ceiba": tree_ceiba,
    "tree_mango": tree_mango,
    "tree_flamboyan": tree_flamboyan,
    "bush_tropical": bush_tropical,
    "grass_clump": grass_clump,
    "fern": fern,
    "hedge": hedge,
    "flowers_patch": flowers_patch,
}

ROCK_BUILDERS = {
    "rock_boulder": rock_boulder,
    "rock_round": rock_round,
    "rock_mossy": rock_mossy,
    "rock_sandstone": rock_sandstone,
    "pebbles_set": pebbles_set,
    "rock_roadside": rock_roadside,
    "rock_volcanic": rock_volcanic,
    "rock_coral": rock_coral,
    "rock_stack_cairn": rock_stack_cairn,
    "log_fallen": log_fallen,
}

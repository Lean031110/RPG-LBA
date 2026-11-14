"""Utilidades deterministas: RNG con semilla, hashing, IDs estables y color."""
from __future__ import annotations

import hashlib
import json
import struct
from typing import Any

import numpy as np


def stable_seed(*parts: Any) -> int:
    """Semilla 64 bits reproducible a partir de partes (strings/números)."""
    blob = "|".join(str(p) for p in parts)
    digest = hashlib.sha256(blob.encode("utf-8")).hexdigest()
    return int(digest[:16], 16) % (2**63 - 1)


def rng_from(seed: int) -> np.random.Generator:
    return np.random.default_rng(seed)


def sha256_file(path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def hash_dict(data: dict) -> str:
    blob = json.dumps(data, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(blob).hexdigest()[:16]


def hex_to_rgb01(hex_color: str) -> tuple[float, float, float]:
    h = hex_color.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def rgb01_to_hex(rgb) -> str:
    return "#{:02X}{:02X}{:02X}".format(*(int(round(min(1.0, max(0.0, c)) * 255)) for c in rgb))


def mix_colors(c1, c2, t: float):
    return tuple((1.0 - t) * a + t * b for a, b in zip(c1, c2))


def jitter_color(rgb, rng: np.random.Generator, amount: float = 0.06):
    """Variación de color real (HLS) para diferenciar recursos hermanos."""
    r, g, b = rgb
    h, l, s = rgb_to_hls(r, g, b)
    h = (h + rng.uniform(-amount, amount)) % 1.0
    l = float(np.clip(l + rng.uniform(-amount, amount * 0.8), 0.05, 0.95))
    s = float(np.clip(s + rng.uniform(-amount, amount), 0.0, 1.0))
    return hls_to_rgb(h, l, s)


def rgb_to_hls(r, g, b):
    maxc, minc = max(r, g, b), min(r, g, b)
    l = (minc + maxc) / 2.0
    if minc == maxc:
        return 0.0, l, 0.0
    if l <= 0.5:
        s = (maxc - minc) / (maxc + minc)
    else:
        s = (maxc - minc) / (2.0 - maxc - minc)
    rc, gc, bc = tuple((maxc - c) / (maxc - minc) for c in (r, g, b))
    if r == maxc:
        h = bc - gc
    elif g == maxc:
        h = 2.0 + rc - bc
    else:
        h = 4.0 + gc - rc
    h = (h / 6.0) % 1.0
    return h, l, s


def hls_to_rgb(h, l, s):
    if s == 0.0:
        return l, l, l
    if l <= 0.5:
        m2 = l * (1.0 + s)
    else:
        m2 = l + s - l * s
    m1 = 2.0 * l - m2
    return (
        _v(m1, m2, h + 1 / 3),
        _v(m1, m2, h),
        _v(m1, m2, h - 1 / 3),
    )


def _v(m1, m2, hue):
    hue = hue % 1.0
    if hue < 1 / 6:
        return m1 + (m2 - m1) * hue * 6.0
    if hue < 1 / 2:
        return m2
    if hue < 2 / 3:
        return m1 + (m2 - m1) * (2 / 3 - hue) * 6.0
    return m1


def pack_floats_md5(values) -> str:
    """Hash corto y estable para firmar parámetros numéricos."""
    blob = b"".join(struct.pack("f", float(v)) for v in values)
    return hashlib.md5(blob).hexdigest()[:12]

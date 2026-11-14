#!/usr/bin/env python3
"""Verifica que las capturas visuales no sean negras ni vacias (mandato §10.G).

Criterio: media de luminancia > 8 y varianza > 40 (una imagen negra tiene
media ~0 y varianza ~0; una imagen plana de un solo color tiene varianza 0).
"""
from __future__ import annotations

import statistics
import sys
from pathlib import Path

from PIL import Image


def main() -> int:
    if len(sys.argv) != 2:
        print("uso: verify_visual_captures.py <directorio>")
        return 2
    directory = Path(sys.argv[1])
    pngs = sorted(directory.glob("*.png"))
    if not pngs:
        print("FAIL: no hay capturas que verificar")
        return 1
    failures = 0
    for png in pngs:
        im = Image.open(png).convert("L")
        pixels = list(im.getdata())
        mean = sum(pixels) / len(pixels)
        var = statistics.pvariance(pixels)
        ok = mean > 8.0 and var > 40.0
        print(f"{png.name}: mean={mean:.1f} var={var:.0f} -> {'OK' if ok else 'FAIL (negra/vacia)'}")
        if not ok:
            failures += 1
    if failures:
        print(f"FAIL: {failures} captura(s) invalida(s)")
        return 1
    print(f"PASS: {len(pngs)} capturas validas (no negras, no vacias)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

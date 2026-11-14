"""Derivación de mapas PBR a partir del campo de altura / máscaras.

Regla del mandato §7: PROHIBIDO copiar la misma imagen en todos los canales.
Cada mapa se calcula con una transformación distinta del campo maestro:
- normal:    gradiente envuelto del height (Sobel con np.roll) -> tangentes.
- ao:        cavidad = desenfoque periódico del height menos el height.
- roughness: base del material + modulación por máscara propia del material.
- metallic:  máscara de rayado/óxido del material (o 0 para dieléctricos).
"""
from __future__ import annotations

import numpy as np

from generators.textures import noise as nz


def height_to_normal(height: np.ndarray, strength: float = 1.0) -> np.ndarray:
    """Mapa normal RGB (0.5 + n*0.5) desde el gradiente envuelto del height."""
    h = np.asarray(height, dtype=np.float64)
    dx = np.roll(h, -1, axis=1) - np.roll(h, 1, axis=1)
    dy = np.roll(h, -1, axis=0) - np.roll(h, 1, axis=0)
    z = np.ones_like(h) / max(strength, 1e-6)
    nx = -dx
    ny = -dy  # +Y hacia arriba en textura (OpenGL)
    norm = np.sqrt(nx * nx + ny * ny + z * z)
    n = np.stack([nx / norm, ny / norm, z / norm], axis=-1)
    return np.clip(0.5 + 0.5 * n, 0.0, 1.0)


def height_to_ao(height: np.ndarray, gain: float = 1.4, sigma: float = 6.0) -> np.ndarray:
    """Oclusión por cavidad: oscurece donde el height está por debajo de su entorno."""
    h = np.asarray(height, dtype=np.float64)
    soft = nz.wrap_gaussian(h, sigma)
    cavity = np.clip(soft - h, 0.0, None)
    rng_h = max(float(h.max() - h.min()), 1e-6)
    ao = 1.0 - gain * cavity / rng_h
    return np.clip(ao, 0.0, 1.0)


def build_roughness(base: float, modulation: np.ndarray | None, gain: float = 0.35) -> np.ndarray:
    """Roughness = base + ganancia*modulación (modulación = ruido/máscara propia)."""
    img = np.full(modulation.shape if modulation is not None else (1, 1), float(base))
    if modulation is not None:
        img = float(base) + gain * (np.asarray(modulation, dtype=np.float64) - 0.5)
    return np.clip(img, 0.02, 1.0)


def build_metallic(base: float, mask: np.ndarray | None, gain: float = 0.0) -> np.ndarray:
    """Metallic: máscara = fracción de superficie metálica (1 metal, 0 dieléctrico,
    p.ej. óxido). Sin máscara -> valor constante del material."""
    if mask is None:
        return np.full((1, 1), float(np.clip(base, 0.0, 1.0)))
    m = np.asarray(mask, dtype=np.float64)
    return np.clip(float(base) * (0.15 + 0.85 * m), 0.0, 1.0)


def apply_wear(albedo: np.ndarray, height: np.ndarray, wear: float,
               rng: np.random.Generator, dark: tuple = (0.04, 0.05, 0.06)) -> np.ndarray:
    """Desgaste gótico-caribeño: manchas de humedad y suciedad en zonas bajas."""
    if wear <= 0:
        return albedo
    stain = nz.fbm(rng, albedo.shape[0], base_cells=3, octaves=4)
    stain = np.clip((stain - 0.45) * 2.2, 0.0, 1.0)
    low = 1.0 - np.clip(np.asarray(height, dtype=np.float64), 0.0, 1.0)
    grime = np.clip(stain * (0.35 + 0.65 * low), 0.0, 1.0) * wear
    dark_arr = np.array(dark, dtype=np.float64)
    return np.clip(albedo * (1.0 - grime[..., None]) + dark_arr * grime[..., None], 0.0, 1.0)


def moss_overlay(albedo: np.ndarray, rng: np.random.Generator, moss_color, amount: float,
                 size: int | None = None) -> np.ndarray:
    """Musgo verde manigua en zonas húmedas (canon: 'piedra con musgo')."""
    if amount <= 0:
        return albedo
    n = albedo.shape[0]
    patches = nz.fbm(rng, n, base_cells=5, octaves=5)
    mask = np.clip((patches - 0.55) * 3.0, 0.0, 1.0) * amount
    moss = np.array(moss_color, dtype=np.float64)
    return np.clip(albedo * (1.0 - mask[..., None]) + moss * mask[..., None], 0.0, 1.0)

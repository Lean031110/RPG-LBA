"""Ruido procedural PERIÓDICO (seamless por construcción).

Todos los generadores usan retículas envueltas (índices módulo N) o FFT
periódica, de modo que las texturas son tileables sin costuras.
Nada se recorta ni se estira en los bordes.
"""
from __future__ import annotations

import numpy as np


def _smoothstep(t: np.ndarray) -> np.ndarray:
    return t * t * (3.0 - 2.0 * t)


def value_noise(rng: np.random.Generator, size: int, cells_x: int, cells_y: int | None = None) -> np.ndarray:
    """Ruido de valores sobre retícula envuelta -> perfectamente periódico.

    cells_x/cells_y: número de celdas de la retícula por eje (controla la
    frecuencia; pueden diferir para crear anisotropía, p.ej. vetas de madera).
    """
    cy = cells_y or cells_x
    grid = rng.random((cy, cells_x)).astype(np.float64)

    x = np.linspace(0.0, cells_x, size, endpoint=False)
    y = np.linspace(0.0, cy, size, endpoint=False)
    xi = np.floor(x).astype(np.int64) % cells_x
    yi = np.floor(y).astype(np.int64) % cy
    fx = _smoothstep(x - np.floor(x))[None, :]
    fy = _smoothstep(y - np.floor(y))[:, None]

    x0 = xi[None, :]                 # (1,size)
    x1 = (xi + 1) % cells_x
    y0 = yi[:, None]                 # (size,1)
    y1 = (yi + 1) % cy

    a = grid[np.ix_(y0.ravel(), x0.ravel())]
    b = grid[np.ix_(y0.ravel(), x1.ravel())]
    c = grid[np.ix_(y1.ravel(), x0.ravel())]
    d = grid[np.ix_(y1.ravel(), x1.ravel())]
    top = a + (b - a) * fx
    bottom = c + (d - c) * fx
    return top + (bottom - top) * fy


def fbm(rng: np.random.Generator, size: int, base_cells: int = 4, octaves: int = 5,
        persistence: float = 0.5, cells_x: int | None = None, cells_y: int | None = None) -> np.ndarray:
    """fBm periódico: suma de octavas de value_noise con frecuencia x2."""
    acc = np.zeros((size, size), dtype=np.float64)
    amp, total = 1.0, 0.0
    for o in range(octaves):
        f = base_cells * (2 ** o)
        acc += amp * value_noise(rng, size, (cells_x or f), (cells_y or f))
        total += amp
        amp *= persistence
    return acc / total


def wrap_gaussian(arr: np.ndarray, sigma: float) -> np.ndarray:
    """Desenfoque gaussiano PERIÓDICO vía FFT (sin bordes)."""
    arr = np.asarray(arr, dtype=np.float64)
    if arr.ndim == 3:
        return np.stack([wrap_gaussian(arr[..., c], sigma) for c in range(arr.shape[2])], axis=-1)
    n, m = arr.shape
    F = np.fft.rfft2(arr)
    ky = np.fft.fftfreq(n) * n
    kx = np.fft.rfftfreq(m) * m
    Hy = np.exp(-2.0 * (np.pi ** 2) * (sigma / n) ** 2 * ky[:, None] ** 2) * np.ones_like(kx)[None, :]
    Hx = np.exp(-2.0 * (np.pi ** 2) * (sigma / m) ** 2 * kx[None, :] ** 2) * np.ones_like(ky)[:, None]
    H = Hy * Hx
    return np.fft.irfft2(F * H, s=(n, m))


def voronoi(rng: np.random.Generator, size: int, cells: int, jitter: float = 0.85):
    """Voronoi periódico (distancia F1 y id de celda).

    Devuelve (distancia_normalizada, id_celda). Las semillas viven en una
    retícula de `cells x cells` celdas; al examinar los vecinos se usan
    índices DESENROLLADOS (la semilla del vecino envuelto se coloca fuera
    del rango [0,cells) para que la distancia sea la real del toro) y el
    módulo solo para consultar el offset y el id. Así el patrón encaja
    perfectamente en los bordes (tileable).
    """
    ny = nx = cells
    off_y = rng.random((ny, nx)) * jitter
    off_x = rng.random((ny, nx)) * jitter

    py = np.arange(size)[:, None] * (ny / size)
    px = np.arange(size)[None, :] * (nx / size)
    cy = np.floor(py).astype(np.int64)
    cx = np.floor(px).astype(np.int64)

    best = np.full((size, size), 1e9)
    best_id = np.zeros((size, size), dtype=np.int64)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            gy_u = cy + dy               # índice desenrollado (vecino real)
            gx_u = cx + dx
            gy = gy_u % ny               # celda equivalente (offset + id)
            gx = gx_u % nx
            sy = gy_u + off_y[gy, gx]   # posición real de la semilla
            sx = gx_u + off_x[gy, gx]
            d = np.hypot(sy - py, sx - px)
            m = d < best
            best[m] = d[m]
            best_id[m] = (gy * nx + gx)[m]
    return np.clip(best / 2.0, 0.0, 1.0), best_id


def cracks(rng: np.random.Generator, size: int, n_cracks: int, length: int,
            curvature: float = 0.55) -> np.ndarray:
    """Grietas por caminos aleatorios con envoltura (periódicas)."""
    img = np.zeros((size, size), dtype=np.float64)
    for _ in range(n_cracks):
        x, y = int(rng.integers(0, size)), int(rng.integers(0, size))
        ang = rng.uniform(0, 2 * np.pi)
        for _ in range(length):
            img[y % size, x % size] += 1.0
            ang += rng.uniform(-curvature, curvature)
            x += int(round(np.cos(ang)))
            y += int(round(np.sin(ang)))
    out = wrap_gaussian(img, 1.4)
    if out.max() > 0:
        out = out / out.max()
    return out


def speckles(rng: np.random.Generator, size: int, n: int, radius: int = 1,
             intensity: float = 1.0) -> np.ndarray:
    """Puntos/discos sueltos con envoltura (poros, chispa, adoquines pequeños)."""
    img = np.zeros((size, size), dtype=np.float64)
    half = radius
    stamp_d = np.arange(-half, half + 1)
    sy, sx = np.meshgrid(stamp_d, stamp_d, indexing="ij")
    stamp = np.clip(1.0 - np.hypot(sy, sx) / (half + 0.5), 0.0, 1.0)
    for _ in range(n):
        y = int(rng.integers(0, size))
        x = int(rng.integers(0, size))
        ys = (y + stamp_d) % size
        xs = (x + stamp_d) % size
        img[np.ix_(ys, xs)] += stamp * rng.uniform(0.5, 1.0) * intensity
    if img.max() > 0:
        img = img / img.max()
    return img


def strokes(rng: np.random.Generator, size: int, n: int, length: int,
           curvature: float = 0.9) -> np.ndarray:
    """Trazos cortos orientados (briznas de hierba, rayones de metal). Periódicos."""
    img = np.zeros((size, size), dtype=np.float64)
    for _ in range(n):
        x, y = int(rng.integers(0, size)), int(rng.integers(0, size))
        ang = rng.uniform(0, 2 * np.pi)
        v = rng.uniform(0.5, 1.0)
        for _ in range(length):
            img[y % size, x % size] = max(img[y % size, x % size], v)
            ang += rng.uniform(-curvature, curvature)
            x += int(round(np.cos(ang)))
            y += int(round(np.sin(ang)))
    return img


def blend(*pairs) -> np.ndarray:
    """Mezcla ponderada: pares (array, peso)."""
    total_w = sum(w for _, w in pairs)
    out = None
    for a, w in pairs:
        a = np.asarray(a, dtype=np.float64)
        if out is None:
            out = a * (w / total_w)
        else:
            out = out + a * (w / total_w)
    return out


def hash01(i: np.ndarray, j: np.ndarray, seed: int) -> np.ndarray:
    """Hash determinista por celda -> [0,1) (variación de color por celda)."""
    h = (i.astype(np.uint32) * 374761393 + j.astype(np.uint32) * 668265263
         + np.uint32(seed & 0xFFFFFFFF))
    h = (h ^ (h >> np.uint32(13))) * np.uint32(1274126177)
    h = h ^ (h >> np.uint32(16))
    return (h & np.uint32(0xFFFFFF)).astype(np.float64) / float(0xFFFFFF)

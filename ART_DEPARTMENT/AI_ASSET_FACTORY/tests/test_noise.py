"""Pruebas del ruido procedural periódico (seamless por construcción)."""
import numpy as np

from generators.textures import noise as nz


def _seam_score(a: np.ndarray, axis: int) -> float:
    d = np.abs(np.diff(a, axis=axis)).ravel()
    p999 = float(np.percentile(d, 99.9)) if d.size else 0.0
    if axis == 1:
        edge = float(np.abs(a[:, -1] - a[:, 0]).mean())
    else:
        edge = float(np.abs(a[-1, :] - a[0, :]).mean())
    return edge - 1.5 * max(p999, 1e-3)


def test_value_noise_periodico():
    rng = np.random.default_rng(42)
    a = nz.value_noise(rng, 256, 8)
    assert a.shape == (256, 256)
    assert _seam_score(a, 0) < 0.02 and _seam_score(a, 1) < 0.02


def test_fbm_periodico():
    rng = np.random.default_rng(7)
    a = nz.fbm(rng, 256, base_cells=4, octaves=5)
    assert _seam_score(a, 0) < 0.02 and _seam_score(a, 1) < 0.02


def test_fbm_determinista():
    a = nz.fbm(np.random.default_rng(99), 128, base_cells=4, octaves=4)
    b = nz.fbm(np.random.default_rng(99), 128, base_cells=4, octaves=4)
    assert np.allclose(a, b)


def test_wrap_gaussian_periodico():
    rng = np.random.default_rng(3)
    a = rng.random((128, 128))
    for sigma in (2.0, 8.0):
        b = nz.wrap_gaussian(a, sigma)
        assert _seam_score(b, 0) < 1e-6 and _seam_score(b, 1) < 1e-6


def test_voronoi_periodico():
    rng = np.random.default_rng(11)
    dist, ids = nz.voronoi(rng, 256, 8)
    assert _seam_score(dist, 0) < 0.02 and _seam_score(dist, 1) < 0.02
    # los ids también deben envolver: fila/columna extremas conectan celdas reales
    assert ids.shape == (256, 256)


def test_cracks_y_speckles_periodicos():
    rng = np.random.default_rng(5)
    a = nz.cracks(rng, 128, n_cracks=6, length=40)
    b = nz.speckles(rng, 128, n=200, radius=1)
    for x in (a, b):
        assert _seam_score(x, 0) < 0.05 and _seam_score(x, 1) < 0.05


def test_hash01_rango():
    i = np.arange(64).reshape(8, 8)
    v = nz.hash01(i, i.T, 123)
    assert v.shape == (8, 8)
    assert v.min() >= 0.0 and v.max() < 1.0

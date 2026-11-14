"""Constructores de texturas procedurales — RPG-LBA (gótico caribeño 1953).

Paleta obligatoria del canon (docs/direccion-artistica/03 §1):
negro carbón, azul petróleo, verde manigua, tierra roja, piedra caliza,
ámbar de farol, rojo carmesí, oro viejo. Los "colores coloniales" se
interpretan desgastados/envejecidos (resolución de la contradicción del
INITIAL_AUDIT.md §4).

Cada constructor devuelve un dict con:
  height (HxW), albedo (HxWx3), roughness_base, roughness_mod,
  metallic_base, metallic_mask, normal_strength, ao_gain.
Ningún mapa es copia de otro: cada uno se deriva por caminos distintos.
"""
from __future__ import annotations

import numpy as np

from core.utils import hex_to_rgb01, jitter_color
from generators.textures import noise as nz
from generators.textures.pbr import apply_wear, moss_overlay

# ----------------------------------------------------------------- paleta
CARBON = hex_to_rgb01("#1C1C22")        # negro carbón
PETROLEO = hex_to_rgb01("#1F4E5F")      # azul petróleo
MANIGUA = hex_to_rgb01("#2E4A32")       # verde manigua
MANIGUA_CLARO = hex_to_rgb01("#4A6B3C")
TIERRA_ROJA = hex_to_rgb01("#8A3B2A")   # tierra roja cubana
CALIZA = hex_to_rgb01("#C9BFAB")        # piedra caliza
AMBAR = hex_to_rgb01("#D8912F")         # ámbar de farol
CARMESI = hex_to_rgb01("#7A1F2B")       # rojo carmesí (corrupción)
ORO_VIEJO = hex_to_rgb01("#A98B3D")     # oro viejo

# Colores coloniales envejecidos (resolución de contradicción, auditoría §4)
OCRE_APAGADO = hex_to_rgb01("#B89C5A")
TURQUESA_EMPOLVADO = hex_to_rgb01("#6E9A96")
CORAL_DESVAIDO = hex_to_rgb01("#B96A5A")
CREMA_SUCIA = hex_to_rgb01("#D1C6A8")
MUSGO = hex_to_rgb01("#3A5232")
MADERA_TROPICAL = hex_to_rgb01("#6B4A2A")
MADERA_CLARA = hex_to_rgb01("#9C7A4A")
TEJA = hex_to_rgb01("#9C4A2F")
TEJA_VIEJA = hex_to_rgb01("#7A3A28")
ZINC = hex_to_rgb01("#8A9096")
OXIDO = hex_to_rgb01("#6E3A1E")
BARRO = hex_to_rgb01("#4A3320")

COLONIAL_FACADES = [OCRE_APAGADO, TURQUESA_EMPOLVADO, CORAL_DESVAIDO, CREMA_SUCIA, CALIZA]


def _p(params: dict, key: str, default):
    return params.get(key, default)


def _color(params: dict, default):
    c = params.get("color")
    if isinstance(c, str):
        return hex_to_rgb01(c)
    if isinstance(c, (list, tuple)) and len(c) == 3:
        return tuple(float(v) / 255.0 if v > 1 else float(v) for v in c)
    return default


def _scale(rng, size, n, params):
    """Densidad del patrón (menos celdas = más grandes)."""
    return max(2, int(round(n * _p(params, "scale", 1.0))))


def _base_array(color, size):
    return np.tile(np.array(color, dtype=np.float64), (size, size, 1))


def _tint(albedo, color, mask):
    m = np.clip(mask, 0.0, 1.0)[..., None]
    return np.clip(albedo * (1 - m) + np.array(color, dtype=np.float64) * m, 0.0, 1.0)


def _cell_variation(ids: np.ndarray, cells: int, seed: int, low=0.82, high=1.18):
    """Multiplicador de brillo determinista por celda."""
    i = (ids // cells).astype(np.int64)
    j = (ids % cells).astype(np.int64)
    return low + (high - low) * nz.hash01(i, j, seed)


# ============================================================ TIPOS (18)
def grass_tropical(rng, size, params):
    """Césped tropical: variación de tono, parches secos, briznas agrupadas."""
    wear = _p(params, "wear", 0.25)
    h = nz.fbm(rng, size, base_cells=_scale(rng, size, 5, params), octaves=5)
    blades = nz.strokes(rng, size, n=int(size * size / 220), length=int(size / 90))
    dry = np.clip((nz.fbm(rng, size, base_cells=3, octaves=4) - 0.55) * 3.0, 0.0, 1.0)

    albedo = _base_array(MANIGUA, size)
    tone = 0.75 + 0.5 * nz.fbm(rng, size, base_cells=7, octaves=4)
    albedo = albedo * tone[..., None]
    albedo = _tint(albedo, MANIGUA_CLARO, blades * 0.55)
    albedo = _tint(albedo, OCRE_APAGADO, dry * _p(params, "dryness", 0.45))  # parches secos
    albedo = apply_wear(albedo, h, wear * 0.5, rng)
    return {
        "height": np.clip(h * 0.35 + blades * 0.12, 0.0, 1.0),
        "albedo": albedo,
        "roughness_base": 0.92,
        "roughness_mod": 1.0 - blades * 0.5,
        "metallic_base": 0.0,
        "metallic_mask": None,
        "normal_strength": 0.55,
        "ao_gain": 0.8,
    }


def earth_red(rng, size, params):
    """Tierra roja cubana: terrones, roderas suaves y piedras pequeñas."""
    wear = _p(params, "wear", 0.3)
    clumps = nz.fbm(rng, size, base_cells=_scale(rng, size, 4, params), octaves=5)
    pebbles = nz.speckles(rng, size, n=int(size * size / 600), radius=1)
    ruts = 0.5 + 0.5 * np.cos(np.linspace(0, 2 * np.pi * 2, size))  # 2 roderas periódicas
    ruts = np.tile(ruts, (size, 1))

    albedo = _base_array(_color(params, TIERRA_ROJA), size)
    albedo = albedo * (0.78 + 0.44 * clumps)[..., None]
    albedo = _tint(albedo, BARRO, np.clip(clumps - 0.55, 0, 1) * 1.6)      # barro oscuro
    albedo = _tint(albedo, CALIZA, pebbles * 0.5)                          # piedras claras
    albedo = _tint(albedo, CARBON, (ruts > 0.86).astype(float) * 0.22)     # huellas comprimidas
    albedo = apply_wear(albedo, clumps, wear, rng)
    height = np.clip(0.45 + 0.3 * clumps + 0.25 * pebbles - 0.08 * ruts, 0.0, 1.0)
    return {
        "height": height,
        "albedo": albedo,
        "roughness_base": 0.95,
        "roughness_mod": 1.0 - pebbles * 0.55,
        "metallic_base": 0.0,
        "metallic_mask": None,
        "normal_strength": 0.8,
        "ao_gain": 1.1,
    }


def mud_wet(rng, size, params):
    """Barro húmedo con charcos (roughness baja = reflejos económicos)."""
    clumps = nz.fbm(rng, size, base_cells=_scale(rng, size, 4, params), octaves=5)
    puddle_field = nz.fbm(rng, size, base_cells=3, octaves=4)
    puddles = np.clip((puddle_field - 0.62) * 4.0, 0.0, 1.0)
    leaves = nz.speckles(rng, size, n=int(size * size / 1400), radius=1, intensity=0.8)

    albedo = _base_array(_color(params, BARRO), size)
    albedo = albedo * (0.8 + 0.35 * clumps)[..., None]
    albedo = _tint(albedo, tuple(c * 0.55 for c in PETROLEO), puddles)  # charcos oscuros
    albedo = _tint(albedo, (0.55, 0.4, 0.15), leaves * 0.6)               # hojas caídas
    return {
        "height": np.clip(clumps * 0.5 - puddles * 0.35, 0.0, 1.0),
        "albedo": albedo,
        "roughness_base": 0.85,
        "roughness_mod": 1.0 - puddles * 0.85,   # chargos casi espejo
        "metallic_base": 0.0,
        "metallic_mask": None,
        "normal_strength": 0.5,
        "ao_gain": 1.3,
    }


def sand(rng, size, params):
    """Arena: grano fino + ondulaciones de viento."""
    fine = nz.fbm(rng, size, base_cells=_scale(rng, size, 16, params), octaves=4)
    rip_amp = nz.fbm(rng, size, base_cells=3, octaves=3)
    xx = np.arange(size)[None, :] / size
    yy = np.arange(size)[:, None] / size
    ripples = 0.5 + 0.5 * np.sin(2 * np.pi * (6 * xx + 0.8 * rip_amp))
    h = np.clip(0.35 * fine + 0.65 * ripples * (0.6 + 0.4 * rip_amp), 0.0, 1.0)

    albedo = _base_array(_color(params, (0.78, 0.68, 0.5)), size)
    albedo = albedo * (0.88 + 0.24 * fine)[..., None]
    albedo = _tint(albedo, OCRE_APAGADO, (1 - ripples) * 0.25)
    return {
        "height": h,
        "albedo": albedo,
        "roughness_base": 0.88,
        "roughness_mod": fine,
        "metallic_base": 0.0,
        "metallic_mask": None,
        "normal_strength": 0.65,
        "ao_gain": 0.9,
    }


def limestone(rng, size, params):
    """Piedra caliza: grietas, erosión y musgo (canon artístico §2)."""
    wear = _p(params, "wear", 0.35)
    moss_amount = _p(params, "moss", 0.35)
    base = nz.fbm(rng, size, base_cells=_scale(rng, size, 5, params), octaves=5)
    erosion = nz.fbm(rng, size, base_cells=11, octaves=4)
    cracks = nz.cracks(rng, size, n_cracks=int(6 * _p(params, "scale", 1.0)), length=int(size / 3))

    h = np.clip(base - 0.55 * cracks - 0.12 * erosion, 0.0, 1.0)
    albedo = _base_array(_color(params, CALIZA), size)
    albedo = albedo * (0.85 + 0.3 * erosion)[..., None]
    albedo = _tint(albedo, (0.55, 0.52, 0.46), cracks * 0.85)              # grietas sombreadas
    albedo = apply_wear(albedo, h, wear, rng)
    albedo = moss_overlay(albedo, rng, MUSGO, moss_amount)
    return {
        "height": h,
        "albedo": albedo,
        "roughness_base": 0.9,
        "roughness_mod": 1.0 - cracks * 0.3,
        "metallic_base": 0.0,
        "metallic_mask": None,
        "normal_strength": 1.05,
        "ao_gain": 1.25,
    }


def stone_cobble(rng, size, params):
    """Adoquín de caliza con juntas oscuras y variación por piedra."""
    cells = _scale(rng, size, 9, params)
    dist, ids = nz.voronoi(rng, size, cells)
    var = _cell_variation(ids, cells, int(rng.integers(1, 2**30)))
    joints = np.clip((dist - 0.30) * 6.0, 0.0, 1.0)      # mortero entre piedras
    dome = np.clip(1.0 - dist * 1.8, 0.0, 1.0)           # bombe del adoquín

    albedo = _base_array(CALIZA, size) * (0.72 + 0.5 * var)[..., None]
    albedo = _tint(albedo, (0.45, 0.42, 0.36), joints)
    albedo = apply_wear(albedo, dome, _p(params, "wear", 0.3), rng)
    albedo = moss_overlay(albedo, rng, MUSGO, _p(params, "moss", 0.22))
    return {
        "height": np.clip(dome * 0.8 - joints * 0.5, 0.0, 1.0),
        "albedo": albedo,
        "roughness_base": 0.93,
        "roughness_mod": 1.0 - dome * 0.15,
        "metallic_base": 0.0,
        "metallic_mask": None,
        "normal_strength": 1.1,
        "ao_gain": 1.35,
    }


def stone_granite(rng, size, params):
    """Granito: cristales multiton (moteado determinista)."""
    dark = nz.speckles(rng, size, n=int(size * size / 300), radius=1)
    light = nz.speckles(rng, size, n=int(size * size / 500), radius=1)
    h = nz.fbm(rng, size, base_cells=14, octaves=4)

    albedo = _base_array((0.52, 0.5, 0.52), size)
    albedo = _tint(albedo, (0.24, 0.23, 0.26), dark * 0.8)
    albedo = _tint(albedo, (0.78, 0.76, 0.72), light * 0.7)
    return {
        "height": np.clip(h * 0.3 + dark * 0.25, 0.0, 1.0),
        "albedo": albedo,
        "roughness_base": 0.82,
        "roughness_mod": h,
        "metallic_base": 0.0,
        "metallic_mask": None,
        "normal_strength": 0.45,
        "ao_gain": 0.6,
    }


def brick_old(rng, size, params):
    """Ladrillo viejo: hiladas corridas, juntas de cal, desconchados."""
    rows = max(2, int(round(_p(params, "rows", 7) * _p(params, "scale", 1.0))))
    per_row = max(2, int(round(_p(params, "bricks_per_row", 4) * _p(params, "scale", 1.0))))
    # hiladas IMPARES: el running bond (media pieza de desfase) cierra al envolver
    if rows % 2 == 0:
        rows += 1
    mortar_w = _p(params, "mortar", 0.045)

    yy = np.arange(size)[:, None] / size
    xx = np.arange(size)[None, :] / size
    row = np.floor(yy * rows).astype(np.int64)
    frac_r = yy * rows - row
    u = (xx + 0.5 * (row % 2) / per_row) * per_row
    col = np.floor(u).astype(np.int64) % per_row
    frac_c = u - np.floor(u)

    dr = np.minimum(frac_r, 1 - frac_r)
    dc = np.minimum(frac_c, 1 - frac_c)
    joint = np.clip((mortar_w * rows - dr) * 8 + (mortar_w * per_row - dc) * 8, 0.0, 1.0)
    var = nz.hash01(row, col, int(rng.integers(1, 2**30)))  # (size,1)+(size,size) -> broadcast

    base_c = _color(params, (0.52, 0.3, 0.24))
    albedo = _base_array(base_c, size) * (0.66 + 0.62 * var)[..., None]
    albedo = _tint(albedo, (0.66, 0.63, 0.56), np.clip(joint, 0, 1))       # junta de cal
    albedo = apply_wear(albedo, 1 - joint, _p(params, "wear", 0.45), rng)
    albedo = moss_overlay(albedo, rng, MUSGO, _p(params, "moss", 0.18))
    bevel = np.clip(dr * dc * 6.0, 0.0, 1.0)
    return {
        "height": np.clip(bevel - joint * 0.6 + 0.15, 0.0, 1.0),
        "albedo": albedo,
        "roughness_base": 0.95,
        "roughness_mod": 1.0 - joint * 0.1,
        "metallic_base": 0.0,
        "metallic_mask": None,
        "normal_strength": 1.0,
        "ao_gain": 1.4,
    }


def stucco(rng, size, params):
    """Estuco colonial: grano fino, manchas de humedad y grietas finas.
    El parámetro 'color' crea variantes de fachada reales (tinte distinto)."""
    wear = _p(params, "wear", 0.4)
    grain = nz.fbm(rng, size, base_cells=_scale(rng, size, 18, params), octaves=4)
    damp = np.clip((nz.fbm(rng, size, base_cells=3, octaves=4) - 0.5) * 2.4, 0.0, 1.0)
    cracks = nz.cracks(rng, size, n_cracks=3, length=int(size / 4)) * 0.6
    h = np.clip(0.5 + 0.28 * grain - 0.35 * cracks, 0.0, 1.0)

    albedo = _base_array(_color(params, CREMA_SUCIA), size)
    albedo = albedo * (0.92 + 0.16 * grain)[..., None]
    albedo = _tint(albedo, (0.46, 0.5, 0.42), damp * wear)                 # humedad verdosa
    albedo = _tint(albedo, (0.5, 0.47, 0.42), cracks)
    return {
        "height": h,
        "albedo": albedo,
        "roughness_base": 0.9,
        "roughness_mod": 1.0 - damp * 0.35,
        "metallic_base": 0.0,
        "metallic_mask": None,
        "normal_strength": 0.8,
        "ao_gain": 0.9,
    }


def concrete(rng, size, params):
    """Hormigón: poros, manchas y juntas de panel (2x2 periódicas)."""
    pores = nz.speckles(rng, size, n=int(size * size / 480), radius=1)
    stain = nz.fbm(rng, size, base_cells=4, octaves=5)
    h = nz.fbm(rng, size, base_cells=12, octaves=4)

    yy = np.arange(size)[:, None] / size
    xx = np.arange(size)[None, :] / size
    seam = np.minimum(
        np.abs(np.sin(np.pi * yy * 2)) , np.abs(np.sin(np.pi * xx * 2))
    )
    seam_mask = (seam < 0.02).astype(float)

    albedo = _base_array(_color(params, (0.62, 0.61, 0.58)), size)
    albedo = albedo * (0.9 + 0.2 * h)[..., None]
    albedo = _tint(albedo, (0.4, 0.4, 0.38), pores * 0.7)                  # poros
    albedo = _tint(albedo, (0.5, 0.49, 0.45), np.clip(stain - 0.55, 0, 1) * 1.8)
    albedo = _tint(albedo, (0.42, 0.42, 0.4), seam_mask * 0.5)
    return {
        "height": np.clip(h * 0.6 - pores * 0.3 - seam_mask * 0.4 + 0.2, 0.0, 1.0),
        "albedo": albedo,
        "roughness_base": 0.92,
        "roughness_mod": h,
        "metallic_base": 0.0,
        "metallic_mask": None,
        "normal_strength": 0.7,
        "ao_gain": 1.0,
    }


def asphalt(rng, size, params):
    """Asfalto: árido multiton, grietas y parches de alquitrán lisos."""
    wear = _p(params, "wear", 0.3)
    aggregate = nz.fbm(rng, size, base_cells=_scale(rng, size, 24, params), octaves=3)
    stones = nz.speckles(rng, size, n=int(size * size / 380), radius=1)
    cracks = nz.cracks(rng, size, n_cracks=5, length=int(size / 3))
    tar = np.clip((nz.fbm(rng, size, base_cells=3, octaves=4) - 0.66) * 4.0, 0.0, 1.0)

    albedo = _base_array(_color(params, (0.16, 0.17, 0.18)), size)
    albedo = albedo * (0.75 + 0.6 * aggregate)[..., None]
    albedo = _tint(albedo, (0.45, 0.44, 0.42), stones * 0.5)              # árido claro
    albedo = _tint(albedo, tuple(c * 0.8 for c in CARBON), np.clip(cracks, 0, 1) * 0.8)
    albedo = _tint(albedo, CARBON, tar)                                   # parche de brea
    albedo = apply_wear(albedo, aggregate, wear * 0.4, rng)
    return {
        "height": np.clip(aggregate * 0.3 + stones * 0.22 - cracks * 0.35, 0.0, 1.0),
        "albedo": albedo,
        "roughness_base": 0.96,
        "roughness_mod": 1.0 - tar * 0.6,
        "metallic_base": 0.0,
        "metallic_mask": None,
        "normal_strength": 0.6,
        "ao_gain": 1.0,
    }


def wood_planks(rng, size, params):
    """Tablones de madera tropical: vetas anisótropas, nudos y juntas."""
    n_planks = max(2, int(round(_p(params, "planks", 6) * _p(params, "scale", 1.0))))
    grain = nz.value_noise(rng, size, cells_x=6, cells_y=64 * 6)  # estirado en X
    grain = (grain - grain.min()) / max(np.ptp(grain), 1e-6)
    fine = nz.fbm(rng, size, base_cells=40, octaves=3)

    yy = np.arange(size)[:, None] / size
    row = np.floor(yy * n_planks).astype(np.int64)
    frac_r = yy * n_planks - row
    dr = np.minimum(frac_r, 1 - frac_r)
    gap = (dr < 0.045).astype(float)
    var = nz.hash01(row.ravel(), np.zeros(size, dtype=np.int64), int(rng.integers(1, 2**30)))
    var = np.tile(var.reshape(-1, 1), (1, size))

    base_c = _color(params, MADERA_CLARA)
    albedo = _base_array(base_c, size) * (0.7 + 0.24 * var)[..., None]
    albedo = albedo * (0.8 + 0.45 * grain)[..., None]                      # vetas
    albedo = _tint(albedo, MADERA_TROPICAL, (1 - grain) * 0.35)
    knots = nz.speckles(rng, size, n=int(n_planks * 2), radius=int(size / 60))
    albedo = _tint(albedo, (0.3, 0.2, 0.1), knots * 0.85)                 # nudos
    albedo = _tint(albedo, tuple(c * 0.7 for c in CARBON), gap * 0.8)     # juntas
    albedo = apply_wear(albedo, grain, _p(params, "wear", 0.2), rng)
    return {
        "height": np.clip(0.55 + 0.3 * grain - gap * 0.5 - knots * 0.2, 0.0, 1.0),
        "albedo": albedo,
        "roughness_base": 0.72,
        "roughness_mod": 1.0 - grain * 0.25,
        "metallic_base": 0.0,
        "metallic_mask": None,
        "normal_strength": 0.75,
        "ao_gain": 1.0,
    }


def wood_weathered(rng, size, params):
    """Madera envejecida a la intemperie: grisada, agrietada, algo de musgo."""
    p = dict(params)
    p.setdefault("color", (0.52, 0.5, 0.46))
    p.setdefault("wear", 0.55)
    out = wood_planks(rng, size, p)
    cracks = nz.cracks(rng, size, n_cracks=8, length=int(size / 3))
    out["albedo"] = _tint(out["albedo"], (0.42, 0.41, 0.38), np.clip(cracks, 0, 1) * 0.7)
    out["albedo"] = moss_overlay(out["albedo"], rng, MUSGO, _p(params, "moss", 0.3))
    out["height"] = np.clip(out["height"] - cracks * 0.4, 0.0, 1.0)
    out["roughness_base"] = 0.88
    out["normal_strength"] = 1.15
    return out


def metal_zinc(rng, size, params):
    """Zinc ondulado: acanalado periódico, óxido carmesí-ocre y rayones."""
    ridges = max(4, int(round(_p(params, "ridges", 8) * _p(params, "scale", 1.0))))
    xx = np.arange(size)[None, :] / size
    corr = np.abs(np.sin(np.pi * ridges * xx))                              # 0..1 acanalado
    corr = np.tile(corr, (size, 1))
    rust = np.clip((nz.fbm(rng, size, base_cells=4, octaves=5) - 0.52) * 2.6, 0.0, 1.0)
    rust *= 0.55 + 0.45 * (1 - corr)                                        # óxido en valles
    scratches = nz.strokes(rng, size, n=int(size * size / 900), length=int(size / 24))

    albedo = _base_array(_color(params, ZINC), size)
    albedo = albedo * (0.72 + 0.4 * corr)[..., None]
    albedo = _tint(albedo, OXIDO, rust)                                     # corrosión
    albedo = _tint(albedo, (0.95, 0.95, 0.92), scratches * 0.35)            # rayones brillantes
    albedo = apply_wear(albedo, corr, _p(params, "wear", 0.25), rng)
    return {
        "height": np.clip(corr * 0.85 - rust * 0.25, 0.0, 1.0),
        "albedo": albedo,
        "roughness_base": 0.42,
        "roughness_mod": 0.55 + 0.5 * rust + 0.1 * corr,
        "metallic_base": 0.92,
        "metallic_mask": 1.0 - rust,                                        # óxido = no metal
        "normal_strength": 1.3,
        "ao_gain": 1.2,
    }


def roof_tiles_terracotta(rng, size, params):
    """Tejas curvas coloniales: perfil semicilíndrico, solape y liquen."""
    rows = max(2, int(round(_p(params, "rows", 7) * _p(params, "scale", 1.0))))
    cols = max(3, int(round(_p(params, "cols", 5) * _p(params, "scale", 1.0))))
    # hiladas IMPARES para que el solape de tejas cierre al envolver
    if rows % 2 == 0:
        rows += 1
    yy = np.arange(size)[:, None] / size
    xx = np.arange(size)[None, :] / size
    row = np.floor(yy * rows).astype(np.int64)
    frac_r = yy * rows - row
    off = (row % 2) * 0.5 / cols
    u = (xx + off) * cols
    col = np.floor(u).astype(np.int64) % cols
    frac_c = u - np.floor(u)

    dome = np.sqrt(np.clip(1.0 - (2 * frac_c - 1) ** 2, 0.0, 1.0))         # perfil teja
    taper = np.clip(np.sin(np.pi * frac_c), 0.2, 1.0)
    var = nz.hash01(row, col, int(rng.integers(1, 2**30)))
    shade = 0.78 + 0.5 * dome                                              # solape sombreado

    albedo = _base_array(_color(params, TEJA), size) * (0.66 + 0.6 * var)[..., None]
    albedo = albedo * shade[..., None] * taper[..., None]
    lichen = np.clip((nz.fbm(rng, size, base_cells=6, octaves=4) - 0.6) * 3.0, 0.0, 1.0)
    albedo = _tint(albedo, (0.68, 0.7, 0.58), lichen * _p(params, "moss", 0.35))  # liquen
    albedo = apply_wear(albedo, dome, _p(params, "wear", 0.4), rng)
    return {
        "height": np.clip(dome * taper * 0.9 + 0.05, 0.0, 1.0),
        "albedo": albedo,
        "roughness_base": 0.9,
        "roughness_mod": 1.0 - dome * 0.2,
        "metallic_base": 0.0,
        "metallic_mask": None,
        "normal_strength": 1.35,
        "ao_gain": 1.25,
    }


def marble(rng, size, params):
    """Mármol blanco con vetas petróleo/oro viejo (turbulencia + bandas)."""
    turb = nz.fbm(rng, size, base_cells=_scale(rng, size, 4, params), octaves=5)
    xx = np.arange(size)[None, :] / size
    band = np.sin(2 * np.pi * (2 * xx + turb * 2.4))   # coeficiente entero = periódico
    veins = np.clip((np.abs(band) - 0.72) * 8.0, 0.0, 1.0)
    veins = nz.wrap_gaussian(veins, 1.5)
    veins = veins / max(veins.max(), 1e-6)

    albedo = _base_array(_color(params, (0.88, 0.86, 0.8)), size)
    albedo = _tint(albedo, tuple(c * 0.75 for c in PETROLEO), veins * 0.7)
    albedo = _tint(albedo, ORO_VIEJO, veins * nz.fbm(rng, size, base_cells=8, octaves=3) * 0.25)
    return {
        "height": np.clip(0.6 - veins * 0.5 + turb * 0.2, 0.0, 1.0),
        "albedo": albedo,
        "roughness_base": 0.25,
        "roughness_mod": 0.6 + 0.4 * veins,
        "metallic_base": 0.0,
        "metallic_mask": None,
        "normal_strength": 0.5,
        "ao_gain": 0.7,
    }


def water(rng, size, params):
    """Agua estilizada: ondas multidireccionales y espuma ámbar dispersa."""
    xx = np.arange(size)[None, :] / size
    yy = np.arange(size)[:, None] / size
    warp = nz.fbm(rng, size, base_cells=3, octaves=4)
    r1 = np.sin(2 * np.pi * (5 * xx + 2 * yy + warp * 1.4))   # coeficientes ENTEROS = periódico
    r2 = np.sin(2 * np.pi * (4 * xx - 3 * yy + warp))
    h = np.clip((r1 + r2) * 0.3 + 0.5, 0.0, 1.0)
    foam = np.clip((nz.fbm(rng, size, base_cells=9, octaves=4) - 0.74) * 6.0, 0.0, 1.0)

    albedo = _base_array(_color(params, tuple(c * 0.85 for c in PETROLEO)), size)
    albedo = albedo * (0.7 + 0.6 * h)[..., None]
    albedo = _tint(albedo, (0.85, 0.9, 0.88), foam * 0.6)
    albedo = _tint(albedo, tuple(c * 0.8 for c in AMBAR), foam * h * 0.25)  # reflejo de farol
    return {
        "height": h,
        "albedo": albedo,
        "roughness_base": 0.12,
        "roughness_mod": 0.25 + 0.75 * h,   # facetas de onda: brillo variable
        "metallic_base": 0.0,
        "metallic_mask": None,
        "normal_strength": 0.9,
        "ao_gain": 0.4,
    }


def vegetation_foliage(rng, size, params):
    """Follaje de manigua: matas de hoja con nervadura y flores dispersas."""
    cells = _scale(rng, size, 7, params)
    dist, ids = nz.voronoi(rng, size, cells)
    var = _cell_variation(ids, cells, int(rng.integers(1, 2**30)), 0.7, 1.3)
    leaf = np.clip(1.0 - dist * 2.2, 0.0, 1.0)                            # mata de hoja
    veins = np.clip(0.5 + 0.5 * np.sin(dist * 60.0), 0.0, 1.0)
    flowers = nz.speckles(rng, size, n=int(size * size / 2400), radius=1)

    albedo = _base_array(MANIGUA, size) * (0.6 + 0.7 * var)[..., None]
    albedo = albedo * (0.75 + 0.35 * leaf)[..., None]
    albedo = _tint(albedo, MANIGUA_CLARO, veins * leaf * 0.5)
    fcol = _color(params, CARMESI)
    albedo = _tint(albedo, fcol, flowers * _p(params, "flowers", 0.35))   # flores carmesí
    return {
        "height": np.clip(leaf * 0.8, 0.0, 1.0),
        "albedo": albedo,
        "roughness_base": 0.7,
        "roughness_mod": 1.0 - leaf * 0.3,
        "metallic_base": 0.0,
        "metallic_mask": None,
        "normal_strength": 0.7,
        "ao_gain": 0.9,
    }


def cement_smooth(rng, size, params):
    """Cemento liso: gris uniforme con grano mínimo (losetas interiores)."""
    h = nz.fbm(rng, size, base_cells=_scale(rng, size, 20, params), octaves=4)
    albedo = _base_array(_color(params, (0.66, 0.65, 0.62)), size)
    albedo = albedo * (0.92 + 0.14 * h)[..., None]
    return {
        "height": h,
        "albedo": albedo,
        "roughness_base": 0.78,
        "roughness_mod": h,
        "metallic_base": 0.0,
        "metallic_mask": None,
        "normal_strength": 0.4,
        "ao_gain": 0.5,
    }


# ---------------------------------------------------------------- registro
TEXTURE_BUILDERS = {
    "grass_tropical": (grass_tropical, "ground"),
    "earth_red": (earth_red, "ground"),
    "mud_wet": (mud_wet, "ground"),
    "sand": (sand, "ground"),
    "limestone": (limestone, "stone"),
    "stone_cobble": (stone_cobble, "stone"),
    "stone_granite": (stone_granite, "stone"),
    "brick_old": (brick_old, "stone"),
    "stucco": (stucco, "concrete"),
    "concrete": (concrete, "concrete"),
    "cement_smooth": (cement_smooth, "concrete"),
    "asphalt": (asphalt, "concrete"),
    "wood_planks": (wood_planks, "wood"),
    "wood_weathered": (wood_weathered, "wood"),
    "metal_zinc": (metal_zinc, "metal"),
    "roof_tiles_terracotta": (roof_tiles_terracotta, "tiles"),
    "marble": (marble, "tiles"),
    "water": (water, "water"),
    "vegetation_foliage": (vegetation_foliage, "vegetation"),
}

"""Pruebas del generador de texturas y la derivación PBR."""
import numpy as np
import pytest
from PIL import Image

from generators.textures.generator import generate_texture
from generators.textures.textures import TEXTURE_BUILDERS


@pytest.mark.parametrize("kind", ["grass_tropical", "stone_cobble", "wood_planks",
                                  "metal_zinc", "roof_tiles_terracotta"])
def test_genera_mapas_pbr_completos(kind):
    d = generate_texture(kind, {}, seed=1234, resolution=256, job_id=f"t_{kind}")
    for role in ("albedo", "normal", "roughness", "metallic", "ao", "height"):
        assert role in d.files, f"falta {role} en {kind}"
        p = d.files[role]
        assert p.exists() and p.stat().st_size > 0
    img = Image.open(d.files["albedo"])
    assert img.size == (256, 256)


def test_resoluciones_permitidas_y_rechazadas():
    for res in (256, 512):
        d = generate_texture("sand", {}, seed=1, resolution=res, job_id=f"res_{res}")
        assert Image.open(d.files["albedo"]).size == (res, res)
    with pytest.raises(ValueError):
        generate_texture("sand", {}, seed=1, resolution=333, job_id="bad")


def test_roughness_variada_y_normal_azul():
    d = generate_texture("concrete", {}, seed=77, resolution=256, job_id="pbrcheck")
    r = np.asarray(Image.open(d.files["roughness"]).convert("L"), dtype=float) / 255
    assert r.std() > 0.02, "roughness no puede ser constante"
    n = np.asarray(Image.open(d.files["normal"]).convert("RGB"), dtype=float) / 255
    assert n[..., 2].mean() > 0.5, "normal map debe dominar el canal azul"


def test_mapas_pbr_distintos():
    d = generate_texture("limestone", {}, seed=55, resolution=256, job_id="distinct")
    sums = {}
    for role in ("albedo", "normal", "roughness", "ao", "height"):
        a = np.asarray(Image.open(d.files[role]).convert("L"), dtype=float)
        sums[role] = float(a.sum())
    assert len(set(sums.values())) == len(sums), "los mapas PBR no pueden ser copias"


def test_metal_zinc_metalico_real():
    d = generate_texture("metal_zinc", {}, seed=9, resolution=256, job_id="zinc")
    m = np.asarray(Image.open(d.files["metallic"]).convert("L"), dtype=float) / 255
    assert m.std() > 0.05, "el zinc debe tener máscara metálica variable"
    assert m.mean() > 0.3


def test_dielctrico_metalico_cero():
    d = generate_texture("marble", {}, seed=9, resolution=256, job_id="marble_m")
    m = np.asarray(Image.open(d.files["metallic"]).convert("L"), dtype=float) / 255
    assert m.max() < 0.05


def test_todos_los_constructores_existen():
    expected = {
        "grass_tropical", "earth_red", "mud_wet", "sand", "limestone", "stone_cobble",
        "stone_granite", "brick_old", "stucco", "concrete", "cement_smooth", "asphalt",
        "wood_planks", "wood_weathered", "metal_zinc", "roof_tiles_terracotta",
        "marble", "water", "vegetation_foliage",
    }
    assert expected.issubset(set(TEXTURE_BUILDERS)), "faltan tipos obligatorios del mandato §7"

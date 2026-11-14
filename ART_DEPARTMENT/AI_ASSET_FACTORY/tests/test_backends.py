"""Pruebas de los backends geométricos y el generador de modelos."""
import numpy as np
import pytest

import trimesh

from generators.models.backends import TrimeshBackend, make_backend


def _bounds(glb_path):
    scene = trimesh.load(glb_path, process=False)
    geoms = list(scene.geometry.values()) if hasattr(scene, "geometry") else [scene]
    V = np.concatenate([g.vertices for g in geoms], axis=0)
    return V.min(axis=0), V.max(axis=0)


def test_backend_trimesh_disponible():
    b = make_backend("trimesh")
    assert b.name == "trimesh"


def test_cilindro_alineado_eje_y():
    b = TrimeshBackend()
    b.mat("m", (1, 0, 0))
    b.part("cylinder", "m", radius=0.5, depth=2.0, location=(0, 1, 0), segments=8)
    out = b.export_glb("/tmp/factory_test_cyl.glb")
    mn, mx = _bounds("/tmp/factory_test_cyl.glb")
    assert abs(mn[1] - 0.0) < 1e-6 and abs(mx[1] - 2.0) < 1e-6, "el eje debe ser +Y"
    assert abs(mx[1] - mn[1] - 2.0) < 1e-6


def test_cono_base_en_origen_punta_positiva():
    b = TrimeshBackend()
    b.mat("m", (0, 1, 0))
    b.part("cone", "m", radius=0.5, depth=1.5, location=(0, 2, 0), segments=6)
    b.export_glb("/tmp/factory_test_cone.glb")
    mn, mx = _bounds("/tmp/factory_test_cone.glb")
    assert abs(mn[1] - 2.0) < 1e-6, "la base del cono debe estar en el location"
    assert abs(mx[1] - 3.5) < 1e-6, "la punta debe apuntar a +Y"


def test_caja_sombreado_plano_y_transform():
    b = TrimeshBackend()
    b.mat("m", (0, 0, 1))
    b.part("box", "m", size=(2.0, 0.2, 1.0), location=(0, 1.0, 0),
           rotation=(0, 0, np.pi / 4))
    stats = b.export_glb("/tmp/factory_test_box.glb")
    assert stats["triangles"] == 12  # caja = 12 triángulos exactos
    scene = trimesh.load("/tmp/factory_test_box.glb", process=False)
    g = list(scene.geometry.values())[0]
    assert len(g.vertices) == 36  # 3 por triángulo (sombreado plano: bordes nítidos)


def test_fusion_por_material_y_uv():
    b = TrimeshBackend()
    b.mat("madera", (0.5, 0.3, 0.1))
    b.mat("hierro", (0.1, 0.1, 0.1))
    for i in range(3):
        b.part("box", "madera", size=(0.3, 0.3, 0.3), location=(i * 0.4, 0.15, 0))
    b.part("cylinder", "hierro", radius=0.05, depth=1.0, location=(0, 0.5, 0.5))
    stats = b.export_glb("/tmp/factory_test_join.glb")
    assert stats["meshes"] == 2, "debe fusionar por material (2 draw calls)"
    scene = trimesh.load("/tmp/factory_test_join.glb", process=False)
    for g in scene.geometry.values():
        assert g.visual.uv is not None and len(g.visual.uv) == len(g.vertices), "UV presentes"


def test_exportacion_glb_valida():
    b = TrimeshBackend()
    b.mat("m", (0.7, 0.7, 0.7), roughness=0.5, metallic=0.2)
    b.part("box", "m", size=(1, 1, 1), location=(0, 0.5, 0))
    b.part("sphere", "m", radius=0.4, location=(0, 1.4, 0), segments=8, smooth=True)
    b.export_glb("/tmp/factory_test_valid.glb")
    scene = trimesh.load("/tmp/factory_test_valid.glb", process=False)
    for g in scene.geometry.values():
        assert np.isfinite(g.vertices).all()
        assert len(g.faces) > 0


# --------------------------------------------------------------- modelos
@pytest.mark.parametrize("name", ["palm_royal", "door_colonial", "house_colonial_01",
                                  "bench_park", "rock_boulder", "barrel_rum"])
def test_generador_modelo_completo(name):
    from generators.models.generator import generate_model

    m = generate_model(name, {}, seed=31, profile="MOBILE", backend_name="trimesh",
                       job_id=f"test_{name}")
    glb = m.files["glb"]
    assert glb.exists() and glb.stat().st_size > 1000
    mn, _ = _bounds(glb)
    assert -0.02 <= mn[1] <= 0.35, f"pivote en base (y_min={mn[1]:.3f})"
    assert m.triangles > 10
    assert len(m.materials) > 0


def test_variaciones_reales_por_semilla():
    from core.utils import stable_seed
    from generators.models.generator import generate_model

    m1 = generate_model("tree_mango", {}, seed=100, profile="MOBILE",
                        backend_name="trimesh", job_id="v1")
    m2 = generate_model("tree_mango", {}, seed=200, profile="MOBILE",
                        backend_name="trimesh", job_id="v2")
    h1 = open(m1.files["glb"], "rb").read()
    h2 = open(m2.files["glb"], "rb").read()
    assert h1 != h2, "semillas distintas deben producir variaciones reales"


def test_perfiles_calidad():
    from generators.models.generator import generate_model

    mobile = generate_model("palm_coconut", {}, seed=5, profile="MOBILE",
                            backend_name="trimesh", job_id="pm")
    balanced = generate_model("palm_coconut", {}, seed=5, profile="BALANCED",
                              backend_name="trimesh", job_id="pb")
    assert mobile.triangles <= balanced.triangles, "MOBILE debe ser más ligero"

"""Pruebas de la cola de trabajos, el Asset Manager, el catálogo y los validadores."""
import json

import pytest


# ------------------------------------------------------------------ cola
def test_cola_ciclo_de_vida():
    from core.queue_manager import QueueManager

    q = QueueManager(path=_tmp_path("q.json"))
    q.add_job("j1", category="texture", name="t1", generator="texture:sand",
              priority=1, seed=1)
    q.add_job("j2", category="model", name="m1", generator="model:palm_royal",
              priority=3, seed=2)
    job = q.take_next()
    assert job["id"] == "j1" and job["estado"] == "processing"
    q.complete(job, "asset_x")
    q.mark_validated("j1")
    assert q.jobs("validated")[0]["id"] == "j1"


def test_cola_reintentos_limitados():
    from core.queue_manager import QueueManager

    q = QueueManager(path=_tmp_path("q2.json"))
    q.add_job("j1", category="texture", name="t", generator="texture:sand", seed=3)
    for i in range(3):
        job = q.take_next()
        final = q.fail(job, "error simulado")
    assert job["estado"] == "failed"
    assert final == "failed"
    assert job["intentos"] == 3


def test_cola_reanudacion_stale():
    from core.config import FactoryConfig
    from core.queue_manager import QueueManager

    cfg = FactoryConfig()
    cfg.stale_processing_minutes = 0  # caduca inmediatamente
    q = QueueManager(path=_tmp_path("q3.json"), config=cfg)
    q.add_job("j1", category="texture", name="t", generator="texture:sand", seed=4)
    q.take_next()
    n = q.reset_stale()
    assert n == 1
    assert q.jobs("pending")[0]["id"] == "j1"


def test_cola_no_duplica_ids():
    from core.queue_manager import QueueManager

    q = QueueManager(path=_tmp_path("q4.json"))
    q.add_job("j1", category="texture", name="t", generator="texture:sand", seed=5)
    with pytest.raises(ValueError):
        q.add_job("j1", category="texture", name="t", generator="texture:sand", seed=6)


# -------------------------------------------------------- asset manager
def test_publicacion_textura_campos_del_mandato():
    from core.asset_manager import AssetManager
    from generators.textures.generator import generate_texture

    am = AssetManager()
    d = generate_texture("stucco", {"color": "#B89C5A"}, seed=21, resolution=256,
                         job_id="am_tex")
    entry = am.publish(d)
    for campo in ("id", "nombre", "categoria", "descripcion", "ruta", "formato",
                  "resolucion", "procedencia", "licencia", "fecha", "estado",
                  "perfil", "hash"):
        assert entry.get(campo), f"falta campo obligatorio {campo}"
    assert entry["files"]["albedo"].endswith("_albedo.png")


def test_publicacion_modelo_y_duplicado():
    from core.asset_manager import AssetManager, DuplicateAssetError
    from generators.models.generator import generate_model

    am = AssetManager()
    d = generate_model("fence_iron", {}, seed=77, profile="MOBILE",
                       backend_name="trimesh", job_id="am_mdl")
    entry = am.publish(d)
    assert entry["ruta"].endswith(".glb")
    assert entry["poligonos"] > 0
    assert entry["colisiones"].startswith("caja simple")
    # contenido idéntico -> rechazado (mandato: nada de recursos idénticos)
    d2 = generate_model("fence_iron", {}, seed=77, profile="MOBILE",
                        backend_name="trimesh", job_id="am_mdl_dup")
    with pytest.raises(DuplicateAssetError):
        am.publish(d2)


def test_ids_y_rutas_estables():
    from core.asset_manager import AssetManager
    from generators.textures.generator import generate_texture

    am = AssetManager()
    e1 = am.publish(generate_texture("sand", {}, seed=1, resolution=256, job_id="s1"))
    e2 = am.publish(generate_texture("sand", {}, seed=2, resolution=256, job_id="s2"))
    assert e1["id"] != e2["id"]
    assert e2["id"].startswith("tex_ground_sand_")
    assert e1["ruta"] != e2["ruta"]


# ------------------------------------------------------------ validadores
def test_validador_textura_pass_y_fail():
    from core.asset_manager import AssetManager
    from generators.textures.generator import generate_texture
    from validators.validators import validate_texture

    am = AssetManager()
    entry = am.publish(generate_texture("stone_cobble", {}, seed=33, resolution=256,
                                        job_id="val"))
    rep = validate_texture(entry)
    assert rep.ok, [c for c in rep.checks if c["resultado"] == "FAIL"]
    # romper un archivo -> FAIL
    entry["files"]["normal"] = "no/existe.png"
    rep2 = validate_texture(entry)
    assert not rep2.ok


def test_validador_modelo():
    from core.asset_manager import AssetManager
    from generators.models.generator import generate_model
    from validators.validators import validate_model

    am = AssetManager()
    entry = am.publish(generate_model("table_wood", {}, seed=8, profile="BALANCED",
                                      backend_name="trimesh", job_id="vm"))
    rep = validate_model(entry)
    assert rep.ok, [c for c in rep.checks if c["resultado"] == "FAIL"]


# ----------------------------------------------------------------- utils
def _tmp_path(name):
    from pathlib import Path

    import tempfile

    d = Path(tempfile.mkdtemp(prefix="factory_test_"))
    return d / name

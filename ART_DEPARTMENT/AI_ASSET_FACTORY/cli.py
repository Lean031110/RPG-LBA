"""CLI de RPG-LBA AI Asset Factory.

Uso (desde la raíz del repo):
  python ART_DEPARTMENT/AI_ASSET_FACTORY/cli.py preset first-batch
  python ART_DEPARTMENT/AI_ASSET_FACTORY/cli.py process --limit 5
  python ART_DEPARTMENT/AI_ASSET_FACTORY/cli.py validate --all
  python ART_DEPARTMENT/AI_ASSET_FACTORY/cli.py preview --all
  python ART_DEPARTMENT/AI_ASSET_FACTORY/cli.py gallery
  python ART_DEPARTMENT/AI_ASSET_FACTORY/cli.py status

Estados de la cola (mandato §9):
  pending → processing → completed → validated → published / failed
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
import time
from pathlib import Path

FACTORY_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(FACTORY_DIR))

from core import paths  # noqa: E402
from core.asset_manager import AssetManager, DuplicateAssetError  # noqa: E402
from core.catalog import Catalog  # noqa: E402
from core.config import FactoryConfig, Profiles  # noqa: E402
from core.queue_manager import QueueManager, now_iso  # noqa: E402
from core.utils import stable_seed  # noqa: E402
from generators.registry import dispatch  # noqa: E402

LOG = Path(paths.ARTIFACTS)


def _log(msg: str) -> None:
    print(msg, flush=True)


# ------------------------------------------------------------ primer lote
def preset_first_batch(profile: str) -> None:
    q = QueueManager()
    profiles = Profiles()
    res = profiles.texture_resolution(profile)
    n = q.counts()["total"]

    def add(generator, category, name, params=None, resolution=None, priority=3):
        nonlocal n
        job_id = f"job_{n + 1:04d}"
        q.add_job(
            job_id, category=category, name=name, generator=generator,
            params={"name": name, **(params or {})}, resolution=resolution,
            priority=priority, profile=profile,
            seed=stable_seed(job_id, name) % (2**31),
        )
        n += 1

    # ---- 21 texturas (18 tipos + 3 variantes coloniales de estuco)
    tex_jobs = [
        ("grass_tropical", "terreno: césped tropical con parches secos", 1),
        ("earth_red", "terreno: tierra roja cubana con roderas", 1),
        ("mud_wet", "terreno: barro húmedo con charcos", 1),
        ("limestone", "piedra caliza con grietas y musgo", 1),
        ("stone_cobble", "adoquín de caliza con juntas", 1),
        ("stone_granite", "granito moteado", 2),
        ("brick_old", "ladrillo viejo con juntas de cal", 2),
        ("stucco", "estuco colonial envejecido (base)", 1),
        ("concrete", "hormigón con poros y juntas", 2),
        ("asphalt", "asfalto con grietas y parches", 2),
        ("wood_planks", "tablones de madera tropical", 1),
        ("wood_weathered", "madera envejecida a la intemperie", 2),
        ("metal_zinc", "zinc ondulado con óxido (tejados de bohío)", 1),
        ("roof_tiles_terracotta", "tejas curvas coloniales", 1),
        ("marble", "mármol con vetas", 2),
        ("vegetation_foliage", "follaje de manigua (decals)", 2),
        ("sand", "arena de playa con ripples", 2),
        ("water", "agua estilizada", 2),
    ]
    for kind, desc, prio in tex_jobs:
        add(f"texture:{kind}", "texture", kind,
            {"description": desc}, resolution=res, priority=prio)
    for color_name, color in (
        ("stucco_colonial_ocre", "#B89C5A"),
        ("stucco_colonial_turquesa", "#6E9A96"),
        ("stucco_colonial_coral", "#B96A5A"),
    ):
        add("texture:stucco", "texture", color_name,
            {"color": color, "description": f"Estuco colonial teñido {color_name.split('_')[-1]}"},
            resolution=res, priority=1)

    # ---- 62 modelos
    model_jobs = [
        # (categoría, generador, params extra)
        ("vegetation", "palm_royal", {}),
        ("vegetation", "palm_coconut", {}),
        ("vegetation", "tree_ceiba", {}),
        ("vegetation", "tree_mango", {}),
        ("vegetation", "tree_flamboyan", {}),
        ("vegetation", "bush_tropical", {}),
        ("vegetation", "grass_clump", {}),
        ("vegetation", "fern", {}),
        ("vegetation", "hedge", {}),
        ("vegetation", "flowers_patch", {}),
        ("rocks", "rock_boulder", {}),
        ("rocks", "rock_round", {}),
        ("rocks", "rock_mossy", {}),
        ("rocks", "rock_sandstone", {}),
        ("rocks", "pebbles_set", {}),
        ("rocks", "rock_roadside", {}),
        ("rocks", "rock_volcanic", {}),
        ("rocks", "rock_coral", {}),
        ("rocks", "rock_stack_cairn", {}),
        ("rocks", "log_fallen", {}),
        ("urban", "lamppost_colonial", {}),
        ("urban", "lamppost_modern", {}),
        ("urban", "bench_park", {}),
        ("urban", "bench_street", {}),
        ("urban", "trash_bin", {}),
        ("urban", "bus_stop", {}),
        ("urban", "manhole_cover", {}),
        ("urban", "traffic_sign_stop", {}),
        ("urban", "bollard", {}),
        ("urban", "planter_urban", {}),
        ("furniture", "table_wood", {}),
        ("furniture", "chair_wood", {}),
        ("furniture", "rocking_chair", {}),
        ("furniture", "sofa", {}),
        ("furniture", "wardrobe", {}),
        ("furniture", "bed", {}),
        ("furniture", "bookshelf", {}),
        ("furniture", "lamp_floor", {}),
        ("furniture", "desk", {}),
        ("furniture", "counter_shop", {}),
        ("architecture", "door_colonial", {}),
        ("architecture", "door_simple", {}),
        ("architecture", "window_colonial", {}),
        ("architecture", "window_modern", {}),
        ("architecture", "column_colonial", {}),
        ("architecture", "stairs_run", {}),
        ("architecture", "balcony_module", {}),
        ("architecture", "arch_colonial", {}),
        ("architecture", "fence_iron", {}),
        ("architecture", "roof_hip_tile", {}),
        ("buildings", "house_colonial_01", {"facade": "ocre"}),
        ("buildings", "house_colonial_01", {"facade": "turquesa", "decay": 0.55,
                                            "width": 7.2, "depth": 6.0}),
        ("buildings", "house_colonial_02", {"facade": "coral"}),
        ("buildings", "house_colonial_02", {"facade": "crema", "floors": 3}),
        ("buildings", "shop_facade", {}),
        ("buildings", "apartment_block", {}),
        ("buildings", "corner_house", {}),
        ("objects", "barrel_rum", {}),
        ("objects", "crate_wood", {}),
        ("objects", "terracotta_pot", {}),
        ("objects", "hanging_sign", {}),
        ("objects", "crate_stack", {}),
    ]
    for cat, gen, extra in model_jobs:
        add(f"model:{gen}", cat, gen, extra, priority=3)

    # ---- 10 materiales (dependen de texturas ya publicadas)
    materials = [
        ("stucco_coral", {"texture_id": "tex_concrete_stucco_001", "color_base": "#B96A5A",
                          "roughness": 0.9, "categoria": "fachadas"}),
        ("stucco_turquesa", {"texture_id": "tex_concrete_stucco_001", "color_base": "#6E9A96",
                             "roughness": 0.9, "categoria": "fachadas"}),
        ("stucco_ocre", {"texture_id": "tex_concrete_stucco_001", "color_base": "#B89C5A",
                         "roughness": 0.9, "categoria": "fachadas"}),
        ("madera_pino", {"texture_id": "tex_wood_wood_planks_001", "color_base": "#9C7A4A",
                         "roughness": 0.75, "categoria": "maderas"}),
        ("tejas_terracotta", {"texture_id": "tex_tiles_roof_tiles_terracotta_001",
                              "color_base": "#9C4A2F", "roughness": 0.9, "categoria": "tejados"}),
        ("adoquin_caliza", {"texture_id": "tex_stone_stone_cobble_001", "color_base": "#C9BFAB",
                            "roughness": 0.93, "categoria": "suelos"}),
        ("asfalto_calle", {"texture_id": "tex_concrete_asphalt_001", "color_base": "#28292A",
                           "roughness": 0.96, "categoria": "suelos"}),
        ("marmol_blanco", {"texture_id": "tex_tiles_marble_001", "color_base": "#E0DCD2",
                           "roughness": 0.25, "categoria": "interiores"}),
        ("zinc_envejecido", {"texture_id": "tex_metal_metal_zinc_001", "color_base": "#8A9096",
                            "roughness": 0.5, "metallic": 0.9, "categoria": "metales"}),
        ("cesped_tropical", {"texture_id": "tex_ground_grass_tropical_001", "color_base": "#3E5A38",
                            "roughness": 0.92, "categoria": "terreno"}),
    ]
    for name, extra in materials:
        add(f"material:{name}", "material", name, extra, priority=2)

    _log(f"[PRESET] Cola sembrada con {q.counts()['total']} trabajos "
         f"(perfil {profile}, texturas {res}px).")


# ---------------------------------------------------------------- worker
def process(limit: int, profile: str | None, backend: str, category: str | None) -> None:
    cfg = FactoryConfig.load()
    q = QueueManager()
    reset = q.reset_stale()
    if reset:
        _log(f"[QUEUE] {reset} trabajos interrumpidos devueltos a pending (reanudación).")
    am = AssetManager(Catalog(), cfg)
    cat = am.catalog
    blocked: set[str] = set()
    done = 0
    t_all = time.time()

    while done < limit:
        job = q.take_next(exclude_generators=blocked)
        if job is None:
            break
        if category and not job["categoria"].startswith(category):
            job["estado"] = "pending"
            q.save()
            blocked.add(job["generador"])
            continue
        # dependencias: material requiere su textura publicada
        if job["generador"].startswith("material:"):
            dep = (job.get("parametros") or {}).get("texture_id")
            dep_entry = cat.get(dep) if dep else None
            if dep_entry is None:
                job["estado"] = "pending"
                job["fecha_actualizacion"] = now_iso()
                q.save()
                _log(f"[WAIT] {job['id']} espera la textura {dep}")
                blocked.add(job["generador"])
                continue
        t0 = time.time()
        entry = None
        try:
            delivery = dispatch(
                job["generador"], job.get("parametros") or {}, job["semilla"],
                job.get("resolucion"), job.get("perfil") or profile or cfg.default_profile,
                job["id"],
            )
            entry = am.publish(delivery)
            # preview + validación
            from processors.preview import preview_for_entry
            from validators.validators import validate_entry

            prev = preview_for_entry(entry)
            entry["preview"] = paths.rel(prev)
            rep = validate_entry(entry)
            rep_path = rep.save()
            entry["validacion"] = paths.rel(rep_path)
            if rep.ok:
                entry["estado"] = "validated"
                cat.save()
                q.complete(job, entry["id"])
                q.mark_validated(job["id"])
                _log(f"[OK] {entry['id']} -> {entry['ruta']} "
                     f"({time.time() - t0:.1f}s, {rep.summary()})")
                done += 1
            else:
                _rollback(cat, entry)
                final = q.fail(job, f"validación FALLIDA: {rep.summary()}")
                _log(f"[FAIL] {entry['id']} validación fallida -> {final}")
        except DuplicateAssetError as e:
            q.fail(job, f"duplicado: {e}")
            _log(f"[DUP] {job['id']} rechazado: {e}")
        except Exception as e:
            if entry is not None:
                _rollback(cat, entry)  # deshacer el intento fallido
            final = q.fail(job, f"{type(e).__name__}: {e}")
            _log(f"[ERR] {job['id']} {job['generador']}: {e} -> {final}")
        finally:
            stage = paths.ARTIFACTS / "staging" / job["id"]
            if stage.exists():
                shutil.rmtree(stage, ignore_errors=True)

    _log(f"[DONE] {done} recursos procesados en {time.time() - t_all:.1f}s. "
         f"Cola: {q.counts()}")


def _rollback(cat: Catalog, entry: dict) -> None:
    """Elimina archivos y registro de un recurso que no pasó validación."""
    for rel in [entry.get("ruta"), entry.get("preview")] + list(entry.get("files", {}).values()) \
            + list(entry.get("lod", [])):
        if rel:
            p = paths.ROOT / rel
            if p.exists():
                p.unlink()
    cat.remove(entry["id"])


# ----------------------------------------------------------- otros comandos
def cmd_validate(scope: str) -> None:
    from validators.validators import duplicates_check, validate_entry, validate_manifest

    cat = Catalog()
    targets = cat.all_assets() if scope == "all" else [e for e in cat.all_assets() if scope in (e["id"],)]
    fails = 0
    for e in targets:
        rep = validate_entry(e)
        rep_path = rep.save()
        e["validacion"] = paths.rel(rep_path)
        if not rep.ok:
            fails += 1
            e["estado"] = "invalid"
        _log(f"[{rep.summary()}] {e['id']} ({rep.to_dict()['pasadas']} ok / "
             f"{rep.to_dict()['fallidas']} fail / {rep.to_dict()['omitidas']} skip)")
    rep_m = validate_manifest()
    rep_m.save()
    rep_d = duplicates_check()
    rep_d.save()
    cat.save()
    _log(f"[VALIDATE] {len(targets)} recursos; {fails} con fallos; manifest={rep_m.summary()}; "
         f"duplicados={rep_d.summary()}")


def cmd_preview(all_assets: bool) -> None:
    from processors.preview import preview_for_entry

    cat = Catalog()
    n = 0
    for e in cat.all_assets():
        if not all_assets and e.get("preview"):
            continue
        try:
            p = preview_for_entry(e)
            e["preview"] = paths.rel(p)
            n += 1
        except Exception as ex:
            _log(f"[ERR preview] {e['id']}: {ex}")
    cat.save()
    _log(f"[PREVIEW] {n} previews generados en {paths.rel(paths.PREVIEWS_DIR)}/")


def cmd_status() -> None:
    q = QueueManager()
    cat = Catalog()
    s = cat.stats()
    _log(json.dumps({"queue": q.counts(), "catalog": s}, ensure_ascii=False, indent=2))


def main() -> None:
    ap = argparse.ArgumentParser(description="RPG-LBA AI Asset Factory")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("preset")
    p.add_argument("name", choices=["first-batch"])
    p.add_argument("--profile", default="BALANCED")

    p = sub.add_parser("process")
    p.add_argument("--limit", type=int, default=5)
    p.add_argument("--profile", default=None)
    p.add_argument("--backend", default="auto")
    p.add_argument("--category", default=None)

    p = sub.add_parser("validate")
    p.add_argument("scope", nargs="?", default="all")

    p = sub.add_parser("preview")
    p.add_argument("--all", action="store_true")

    sub.add_parser("gallery")
    sub.add_parser("status")

    p = sub.add_parser("mark-published")
    p.add_argument("scope", nargs="?", default="all")

    args = ap.parse_args()
    if args.cmd == "preset":
        preset_first_batch(args.profile)
    elif args.cmd == "process":
        process(args.limit, args.profile, args.backend, args.category)
    elif args.cmd == "validate":
        cmd_validate(args.scope)
    elif args.cmd == "preview":
        cmd_preview(args.all)
    elif args.cmd == "gallery":
        from processors.gallery import build_gallery

        out = build_gallery()
        _log(f"[GALLERY] {paths.rel(out)}")
    elif args.cmd == "status":
        cmd_status()
    elif args.cmd == "mark-published":
        q = QueueManager()
        n = q.mark_all_published()
        cat = Catalog()
        for e in cat.all_assets():
            if e.get("estado") == "validated":
                e["estado"] = "published"
        cat.save()
        _log(f"[PUBLISH] {n} trabajos y recursos marcados como published.")


if __name__ == "__main__":
    paths.ensure_dirs()
    main()

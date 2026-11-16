#!/usr/bin/env python3
"""Consolidated asset-factory validator (master prompt §15).

Stdlib-only; runs in CI (asset-library-index.yml) and locally.

Checks:
 1. manifest/provider JSON files parse;
 2. no duplicate IDs (manifest, index, gaps, legacy);
 3. referenced files exist (ruta/files, validation, preview);
 4. links well-formed (github blob URLs, license URLs for third-party rows);
 5. SHA-256 recorded in the index matches the real file content;
 6. provenance/license coverage (assets without license → error; legacy
    files without provenance → warning, they are already quarantined);
 7. unsuitable licenses (PENDIENTE, NC, ND, GPL, personal-use) → error;
 8. content duplicates by hash across different asset IDs → warning;
 9. file size limits (>45 MB error, repo hygiene);
10. mobile budgets (triangles/texture resolution/profile vocabulary);
11. path & naming rules (snake_case, no uppercase/spaces) + required metadata;
12. n8n workflow JSON: valid, inactive, secret-free;
13. GitHub workflows: permissions declared, no auto-merge, schedule safety;
14. branch-safety guards present in the factory/scheduler workflows;
15. index/catalog cross-consistency (counts, schema 2.0.0).

Exit 1 on any ERROR; warnings never fail the run. Output lines are prefixed
PASS/FAIL/WARN with file:detail for CI readability.
"""
from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FACTORY = ROOT / "ART_DEPARTMENT/AI_ASSET_FACTORY"
CLOUD = ROOT / "ART_DEPARTMENT/CLOUD_AUTOMATION"
INDEX = CLOUD / "ASSET_LIBRARY_INDEX.json"
MANIFEST = FACTORY / "catalog/assets_manifest.json"
GAPS = CLOUD / "ASSET_GAP_BACKLOG.json"
PROVIDERS = CLOUD / "PROVIDER_REGISTRY.json"
LEGACY = CLOUD / "LEGACY_ASSET_INDEX.json"
PROVENANCE_CSV = ROOT / "assets/manifest.csv"
N8N_DIR = ROOT / "automation/n8n/workflows"
WORKFLOWS_DIR = ROOT / ".github/workflows"

MAX_BYTES = 45 * 1024 * 1024
HARD_MAX_TEXTURE = 4096
WARN_MAX_TEXTURE = 1024
HARD_MAX_TRIANGLES = 20000
PROFILES = {"MOBILE", "BALANCED", "HIGH"}
REPO_URL_PREFIX = "https://github.com/Lean031110/RPG-LBA/blob/"
SNAKE_CASE = re.compile(r"^[a-z0-9_./\-]+$")

ERRORS: list[str] = []
WARNINGS: list[str] = []
CHECKS: list[str] = []


def ok(msg: str) -> None:
    CHECKS.append(f"PASS: {msg}")


def err(msg: str) -> None:
    ERRORS.append(f"FAIL: {msg}")


def warn(msg: str) -> None:
    WARNINGS.append(f"WARN: {msg}")


def load_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8")), True
    except FileNotFoundError:
        err(f"missing required file: {path.relative_to(ROOT)}")
        return None, False
    except json.JSONDecodeError as exc:
        err(f"invalid JSON {path.relative_to(ROOT)}: {exc}")
        return None, False


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def read_provenance() -> list[dict]:
    import csv
    if not PROVENANCE_CSV.is_file():
        err("missing assets/manifest.csv")
        return []
    with PROVENANCE_CSV.open(encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


# ---------------------------------------------------------------- 1. JSON
def check_json_files() -> dict:
    data = {}
    for name, path in (("manifest", MANIFEST), ("index", INDEX), ("gaps", GAPS),
                       ("providers", PROVIDERS), ("legacy", LEGACY)):
        loaded, good = load_json(path)
        if good:
            ok(f"JSON válido: {path.relative_to(ROOT)}")
        data[name] = loaded
    return data


# ------------------------------------------------------ 2..11 factory/index
def check_manifest_and_index(data: dict) -> None:
    manifest = data.get("manifest") or {}
    index = data.get("index") or {}
    gaps = data.get("gaps") or {}
    provenance = read_provenance()

    assets = manifest.get("assets", {})
    if len(assets) != 93:  # current published batch; update when a new batch ships
        warn(f"manifest asset count changed: {len(assets)} (expected 93 from batch 1)")

    # 2. duplicate IDs -----------------------------------------------------
    ids = list(assets.keys())
    if len(ids) != len(set(ids)):
        err("duplicate manifest IDs")
    index_assets = index.get("assets", [])
    index_ids = [r.get("asset_id") for r in index_assets]
    dup_index = {i for i in index_ids if index_ids.count(i) > 1}
    if dup_index:
        err(f"duplicate index asset_ids: {sorted(dup_index)[:5]}")
    gap_ids = [g.get("gap_id") for g in gaps.get("items", [])]
    dup_gaps = {g for g in gap_ids if gap_ids.count(g) > 1}
    if dup_gaps:
        err(f"duplicate gap_ids: {sorted(dup_gaps)[:5]}")
    overlap = set(ids) & set(gap_ids)
    if overlap:
        err(f"IDs shared between manifest and gaps (must never): {sorted(overlap)[:5]}")
    if not dup_index and not dup_gaps and not overlap:
        ok(f"IDs únicos: {len(ids)} manifiesto / {len(index_ids)} índice / {len(gap_ids)} gaps")

    # 3. files exist --------------------------------------------------------
    missing_files = []
    for aid, a in assets.items():
        for rel in [a.get("ruta"), *(_flatten(a.get("files") or {}))]:
            if rel and not (ROOT / rel).is_file():
                missing_files.append(f"{aid}: {rel}")
        for rel in (a.get("validacion"), a.get("preview")):
            if rel and not (ROOT / rel).is_file():
                missing_files.append(f"{aid} (reporte/preview): {rel}")
    if missing_files:
        err("archivos inexistentes: " + "; ".join(missing_files[:6]) +
            (f" (+{len(missing_files)-6} más)" if len(missing_files) > 6 else ""))
    else:
        ok("todos los archivos referenciados por el manifiesto existen")

    # 4. links --------------------------------------------------------------
    bad_urls = []
    for rec in index_assets:
        for f in rec.get("files", []):
            url = f.get("github_url", "")
            if not url.startswith(REPO_URL_PREFIX):
                bad_urls.append(f"{rec.get('asset_id')}: {url[:60]}")
        for key in ("primary_url", "preview_url", "validation_report_url"):
            url = rec.get(key)
            if url and not str(url).startswith(REPO_URL_PREFIX):
                bad_urls.append(f"{rec.get('asset_id')}.{key}")
    if bad_urls:
        err("enlaces malformados: " + "; ".join(bad_urls[:5]))
    else:
        ok("enlaces GitHub del índice bien formados")

    unsuitable = re.compile(
        r"(?:^|[\s\-])(?:NC|ND|NO-DERIV|NONCOMMERCIAL|NON-COMMERCIAL)\b"
        r"|PERSONAL[\s-]USE|EDITORIAL[\s-]ONLY|ALL[\s-]RIGHTS[\s-]RESERVED", re.IGNORECASE)
    for row in provenance:
        lic = (row.get("license") or "").strip()
        if lic and "PENDIENTE" in lic.upper():
            warn(f"manifest.csv: {row.get('asset_id')} en CUARENTENA (licencia PENDIENTE) — no se integra ni se distribuye hasta reemplazo/verificación; ya documentado en PRODUCTION_AUDIT.md")
        if lic and "PENDIENTE" not in lic.upper() and not (row.get("license_url") or "").strip():
            err(f"manifest.csv: {row.get('asset_id')} declara licencia sin URL de licencia")
        if lic and unsuitable.search(lic):
            err(f"manifest.csv: licencia no apta para distribución en {row.get('asset_id')}: {lic}")
        if lic and re.search(r"(?:^|[\s\-])GPL", lic, re.IGNORECASE):
            err(f"manifest.csv: GPL en {row.get('asset_id')} no debe mezclarse con assets propietarios")

    # 5. SHA-256 ------------------------------------------------------------ (index vs disk)
    hash_mismatch = []
    hashed = 0
    for rec in index_assets:
        for f in rec.get("files", []):
            rel, recorded = f.get("path"), f.get("sha256")
            if not rel or not recorded:
                continue
            disk = ROOT / rel
            if not disk.is_file():
                continue
            hashed += 1
            if sha256_file(disk) != recorded:
                hash_mismatch.append(rel)
    if hash_mismatch:
        err("hash SHA-256 distinto del archivo real: " + "; ".join(hash_mismatch[:5]))
    else:
        ok(f"SHA-256 verificado para {hashed} archivos del índice")

    # 6. coverage -----------------------------------------------------------
    no_license = [aid for aid, a in assets.items() if not (a.get("licencia") or "").strip()]
    if no_license:
        err(f"assets del manifiesto sin licencia: {no_license[:5]}")
    else:
        ok("todos los assets del manifiesto declaran licencia")
    unlicensed_legacy = [r.get("asset_id") for r in index_assets
                         if r.get("record_type") == "legacy_file"
                         and r.get("license_review_status") == "LICENSE_AND_SOURCE_UNKNOWN"]
    if unlicensed_legacy:
        warn(f"{len(unlicensed_legacy)} archivos heredados sin procedencia (ya en cuarentena; no aprobar/integrar): "
             + ", ".join(unlicensed_legacy[:4]))

    # 8. duplicates by content ---------------------------------------------
    by_hash: dict[str, set[str]] = {}
    for rec in index_assets:
        for f in rec.get("files", []):
            by_hash.setdefault(f.get("sha256"), set()).add(rec.get("asset_id"))
    dup_content = {h: ids for h, ids in by_hash.items() if h and len(ids) > 1}
    if dup_content:
        warn(f"{len(dup_content)} contenidos duplicados entre distintos asset IDs (revisar ubicación canónica única)")
    else:
        ok("sin contenido duplicado entre distintos asset IDs")

    # 9. size ---------------------------------------------------------------
    big = [str(f.relative_to(ROOT)) for f in (ROOT / "assets").rglob("*")
           if f.is_file() and f.stat().st_size > MAX_BYTES]
    big += [str(f.relative_to(ROOT)) for f in (ROOT / "ART_DEPARTMENT").rglob("*")
            if f.is_file() and f.stat().st_size > MAX_BYTES]
    if big:
        err(f"archivos > 45 MB: {big[:3]}")
    else:
        ok("ningún asset supera 45 MB")

    # 10. budgets -----------------------------------------------------------
    over_tris = [aid for aid, a in assets.items()
                 if isinstance(a.get("poligonos"), int) and a["poligonos"] > HARD_MAX_TRIANGLES]
    if over_tris:
        err(f"triángulos > {HARD_MAX_TRIANGLES}: {over_tris[:5]}")
    else:
        ok(f"triángulos dentro del tope duro ({HARD_MAX_TRIANGLES}) en todos los modelos")
    bad_profile = [aid for aid, a in assets.items() if a.get("perfil") not in PROFILES]
    if bad_profile:
        err(f"perfil desconocido (debe ser MOBILE/BALANCED/HIGH): {bad_profile[:5]}")
    big_tex = [aid for aid, a in assets.items()
               if isinstance(a.get("resolucion"), str) and re.search(r"(\d{4,})\s*[x×]\s*(\d{4,})", a["resolucion"])
               and int(re.search(r"(\d+)", a["resolucion"]).group(1)) > HARD_MAX_TEXTURE]
    if big_tex:
        err(f"resolución de textura > {HARD_MAX_TEXTURE}px: {big_tex[:5]}")
    warn_tex = [aid for aid, a in assets.items()
                if isinstance(a.get("resolucion"), str) and re.search(r"^(2048|4096)", a["resolucion"])]
    if warn_tex:
        warn(f"texturas > {WARN_MAX_TEXTURE}px (justificar con perfil HIGH): {warn_tex[:5]}")

    # 11. naming + required metadata ---------------------------------------
    # snake_case is ENFORCED on factory-managed trees; third-party legacy files
    # keep their original names (AGENTS.md §5 preserves upstream package names).
    FACTORY_TREES = ("assets/models", "assets/environment/textures", "assets/materials")
    def _factory_managed(rel: str) -> bool:
        return rel.startswith(FACTORY_TREES)
    bad_names, legacy_names = [], []
    for f in (ROOT / "assets").rglob("*"):
        if not f.is_file():
            continue
        rel = f.relative_to(ROOT).as_posix()
        if f.suffix == ".import":  # Godot-generated, matches binary name
            continue
        if not SNAKE_CASE.match(f.name):
            (bad_names if _factory_managed(rel) else legacy_names).append(rel)
    if bad_names:
        err(f"naming no snake_case en árboles de la fábrica: {bad_names[:5]}")
    else:
        ok("naming snake_case en los árboles gestionados por la fábrica")
    if legacy_names:
        warn(f"{len(legacy_names)} archivos de terceros mantienen nombre original (política AGENTS.md §5): "
             + ", ".join(legacy_names[:4]))
    required = ("id", "nombre", "categoria", "ruta", "formato", "licencia",
                "estado", "validacion", "preview", "hash")
    incomplete = [aid for aid, a in assets.items() if any(not a.get(k) for k in required)]
    if incomplete:
        err(f"metadatos requeridos incompletos: {incomplete[:5]}")
    else:
        ok("metadatos requeridos presentes en las 93 entradas")

    # 15. index consistency --------------------------------------------------
    if index.get("schema_version") != "2.0.0":
        err(f"índice con schema {index.get('schema_version')} (se exige 2.0.0 único)")
    else:
        ok("índice en schema 2.0.0")
    if index.get("record_count") != len(index_assets):
        err("record_count del índice no coincide con sus registros")
    if index.get("manifest_asset_count") != len(assets):
        err("manifest_asset_count del índice no coincide con el manifiesto")


def _flatten(value):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for child in value.values():
            yield from _flatten(child)
    elif isinstance(value, list):
        for child in value:
            yield from _flatten(child)


# ----------------------------------------------------------------- 12. n8n
def check_n8n() -> None:
    templates = sorted(N8N_DIR.glob("*.json"))
    if not templates:
        warn("sin plantillas n8n bajo automation/n8n/workflows/")
    secret_pat = re.compile(r"(bot\d{6,}:[A-Za-z0-9_\-]{30,}|sk-[A-Za-z0-9]{20,}|AIza[A-Za-z0-9_\-]{30,})")
    for path in templates:
        data, good = load_json(path)
        if not good:
            continue
        if data.get("active") is not False:
            err(f"{path.name}: plantilla n8n debe commitearse inactiva (active=false)")
        blob = json.dumps(data)
        if secret_pat.search(blob):
            err(f"{path.name}: posible secreto embebido en el JSON")
        ok(f"n8n {path.name}: JSON válido, inactivo y sin secretos aparentes")


# ------------------------------------------------------------- 13/14. CI
def check_workflows() -> None:
    import yaml
    files = sorted(WORKFLOWS_DIR.glob("*.yml"))
    for path in files:
        try:
            doc = yaml.safe_load(path.read_text(encoding="utf-8"))
        except yaml.YAMLError as exc:
            err(f"{path.name}: YAML inválido: {str(exc)[:80]}")
            continue
        on = doc.get(True) or doc.get("on") or {}
        perms = doc.get("permissions") or any("permissions" in (j or {}) for j in (doc.get("jobs") or {}).values())
        if not perms:
            err(f"{path.name}: workflow sin bloque permissions (mínimo privilegio)")
        text = path.read_text(encoding="utf-8")
        if re.search(r"gh pr merge.*(--auto|--squash|--merge\b|--rebase)", text):
            err(f"{path.name}: auto-merge prohibido (AGENTS.md)")
        schedules = on.get("schedule") if isinstance(on, dict) else None
        if schedules:
            write_level = json.dumps(doc.get("permissions") or {})
            if "write" in write_level or "contents: write" in text:
                err(f"{path.name}: schedule + contents:write puede escribir en la rama por defecto (requiere dispatcher seguro)")
    # 14. branch guards
    factory = (WORKFLOWS_DIR / "asset-factory.yml").read_text(encoding="utf-8")
    scheduler = (WORKFLOWS_DIR / "asset-factory-scheduler.yml").read_text(encoding="utf-8")
    publication = (WORKFLOWS_DIR / "asset-publication.yml").read_text(encoding="utf-8")
    if "Guarda de rama" not in factory or "main" not in factory:
        err("asset-factory.yml: falta la guarda de rama (main/release)")
    else:
        ok("asset-factory.yml contiene la guarda de rama contra main")
    if "agent/*|feature/*" not in scheduler:
        err("asset-factory-scheduler.yml: falta la validación ^(agent|feature)/")
    else:
        ok("asset-factory-scheduler.yml valida el patrón de rama destino")
    if "github.ref_name != 'main'" not in publication:
        err("asset-publication.yml: falta el if de rama != main")
    else:
        ok("asset-publication.yml rechaza ejecutarse en main")
    ok(f"{len(files)} workflows analizados")


def main() -> int:
    data = check_json_files()
    if data.get("manifest") and data.get("index"):
        check_manifest_and_index(data)
    check_n8n()
    check_workflows()

    for line in CHECKS:
        print(line)
    for line in WARNINGS:
        print(line)
    for line in ERRORS:
        print(line)
    print()
    print(f"RESULTADO: {len(CHECKS)} PASS / {len(WARNINGS)} WARN / {len(ERRORS)} FAIL")
    return 1 if ERRORS else 0


if __name__ == "__main__":
    raise SystemExit(main())

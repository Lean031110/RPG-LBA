#!/usr/bin/env python3
"""Build a stable, linked inventory of every game asset file and manifest item."""
from __future__ import annotations
import argparse
import csv
import hashlib
import json
import os
import sys
from pathlib import Path

SUPPORTED = {".glb", ".fbx", ".png", ".svg", ".tres", ".json", ".ttf",
             ".wav", ".ogg", ".mp3", ".hdr", ".exr", ".blend", ".obj",
             ".mtl", ".jpg", ".jpeg", ".webp"}
REPO_DEFAULT = "Lean031110/RPG-LBA"


def github_url(repo: str, ref: str, path: str) -> str:
    return f"https://github.com/{repo}/blob/{ref}/" + "/".join(
        __import__("urllib.parse", fromlist=["quote"]).quote(part, safe="") for part in path.split("/")
    )


def flatten_paths(value):
    if isinstance(value, str):
        if value.startswith("assets/"):
            yield value
    elif isinstance(value, dict):
        for child in value.values():
            yield from flatten_paths(child)
    elif isinstance(value, list):
        for child in value:
            yield from flatten_paths(child)


def read_provenance(root: Path) -> list[dict]:
    path = root / "assets/manifest.csv"
    if not path.exists():
        return []
    with path.open(encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def provenance_for(path: str, records: list[dict]) -> dict | None:
    matches = []
    for row in records:
        local = (row.get("local_path") or "").rstrip("/")
        if local and (path == local or path.startswith(local + "/")):
            matches.append((len(local), row))
    return max(matches, key=lambda item: item[0])[1] if matches else None


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def asset_family(path: str) -> str:
    parts = Path(path).parts
    if len(parts) > 1:
        return "/".join(parts[1:-1]) or parts[1]
    return "misc"


def build(root: Path, repo: str, ref: str, source_commit: str) -> dict:
    manifest_path = root / "ART_DEPARTMENT/AI_ASSET_FACTORY/catalog/assets_manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    provenance = read_provenance(root)
    records = []
    claimed: set[str] = set()
    ids: set[str] = set()

    def add_id(asset_id: str):
        if asset_id in ids:
            raise ValueError(f"Duplicate asset id: {asset_id}")
        ids.add(asset_id)

    for source in sorted(manifest.get("assets", {}).values(), key=lambda a: a.get("id", "")):
        asset_id = source.get("id")
        if not asset_id:
            raise ValueError("Manifest entry has no stable id")
        add_id(asset_id)
        record_from_factory = True
        paths = list(dict.fromkeys([p for p in [source.get("ruta"), *flatten_paths(source.get("files", {}))] if p]))
        files = []
        for rel in paths:
            file_path = root / rel
            claimed.add(rel)
            if not file_path.is_file():
                raise FileNotFoundError(f"{asset_id}: missing file {rel}")
            files.append({
                "path": rel,
                "github_url": github_url(repo, ref, rel),
                "sha256": sha256_file(file_path),
                "bytes": file_path.stat().st_size,
            })
        validation = source.get("validacion")
        preview = source.get("preview")
        for rel in (validation, preview):
            if rel and not (root / rel).is_file():
                raise FileNotFoundError(f"{asset_id}: missing linked report/preview {rel}")
        records.append({
            "asset_id": asset_id,
            "name": source.get("nombre", asset_id),
            "record_type": "manifest_asset",
            "category": source.get("categoria", "uncategorized"),
            "description": source.get("descripcion", ""),
            "files": files,
            "primary_path": source.get("ruta"),
            "primary_url": github_url(repo, ref, source["ruta"]) if source.get("ruta") else None,
            "preview_path": preview,
            "preview_url": github_url(repo, ref, preview) if preview else None,
            "validation_report_path": validation,
            "validation_report_url": github_url(repo, ref, validation) if validation else None,
            "format": source.get("formato"),
            "resolution": source.get("resolucion"),
            "triangles": source.get("poligonos"),
            "vertices": source.get("vertices"),
            "materials": source.get("materiales"),
            "textures": source.get("texturas"),
            "scale": source.get("escala"),
            "pivot": source.get("pivote"),
            "collisions": source.get("colisiones"),
            "lod": source.get("lod"),
            "profile": source.get("perfil"),
            "origin": source.get("procedencia"),
            "creator": source.get("procedencia"),
            "source_url": github_url(repo, ref, "ART_DEPARTMENT/AI_ASSET_FACTORY/catalog/assets_manifest.json") if record_from_factory else None,
            "license": source.get("licencia"),
            "license_checked_date": source.get("fecha"),
            "technical_status": source.get("estado"),
            "human_visual_review": "NOT_REVIEWED",
            "godot_import_status": "NOT_TESTED",
            "scene_integration_status": "NOT_TESTED",
            "android_device_status": "NOT_TESTED",
            "seed": source.get("seed", source.get("semilla")),
            "backend": source.get("backend"),
            "generation_parameters": source.get("parametros"),
            "manifest_sha256": source.get("hash"),
        })

    legacy_count = 0
    for file_path in sorted((root / "assets").rglob("*")):
        if not file_path.is_file() or file_path.suffix.lower() not in SUPPORTED:
            continue
        rel = file_path.relative_to(root).as_posix()
        if rel in claimed:
            continue
        record = provenance_for(rel, provenance)
        asset_id = "LEGACY_" + hashlib.sha256(rel.encode("utf-8")).hexdigest()[:16].upper()
        add_id(asset_id)
        lic = (record or {}).get("license", "PENDING_LICENSE_REVIEW")
        license_state = "LICENSE_REVIEW_REQUIRED" if "PENDIENTE" in lic.upper() or "PENDING" in lic.upper() else (
            "PROVENANCE_RECORDED_REQUIRES_FILE_LEVEL_CHECK" if record else "LICENSE_AND_SOURCE_UNKNOWN"
        )
        source_url = (record or {}).get("source_url")
        note = "Legacy file not represented as a separate canonical manifest record; stable ID derives from path."
        if rel.startswith("assets/items/hats/"):
            note += " Exact per-hat source URL is listed in assets/items/ATTRIBUTIONS.md; do not reuse the group source URL as the exact model source."
        records.append({
            "asset_id": asset_id,
            "name": file_path.stem.replace("_", " ").replace("-", " ").title(),
            "record_type": "legacy_file",
            "category": asset_family(rel),
            "description": note,
            "files": [{
                "path": rel,
                "github_url": github_url(repo, ref, rel),
                "sha256": sha256_file(file_path),
                "bytes": file_path.stat().st_size,
            }],
            "primary_path": rel,
            "primary_url": github_url(repo, ref, rel),
            "preview_path": None,
            "preview_url": None,
            "validation_report_path": None,
            "validation_report_url": None,
            "origin": (record or {}).get("author") or "Unknown / legacy",
            "source_url": source_url,
            "license": lic,
            "license_url": (record or {}).get("license_url"),
            "license_review_status": license_state,
            "technical_status": "NOT_TESTED",
            "human_visual_review": "NOT_REVIEWED",
            "godot_import_status": "NOT_TESTED",
            "scene_integration_status": "NOT_TESTED",
            "android_device_status": "NOT_TESTED",
            "git_note": "Legacy record ID is path-derived; do not move this file without migration.",
        })
        legacy_count += 1

    records.sort(key=lambda a: a["asset_id"])
    return {
        "schema_version": "2.0.0",
        "generated_from": "ART_DEPARTMENT/AI_ASSET_FACTORY/catalog/assets_manifest.json + assets/ tree",
        "generated_at_utc": manifest.get("updated"),
        "source_repository": repo,
        "source_ref": ref,
        "source_commit": source_commit or None,
        "canonical_manifest": "ART_DEPARTMENT/AI_ASSET_FACTORY/catalog/assets_manifest.json",
        "asset_file_count": sum(len(x["files"]) for x in records),
        "manifest_asset_count": len(manifest.get("assets", {})),
        "legacy_file_count": legacy_count,
        "record_count": len(records),
        "policy": {
            "stable_ids": True,
            "path_derived_legacy_ids": True,
            "license_unknown_means_do_not_ship": True,
            "technical_validation_does_not_equal_human_visual_approval": True,
            "godot_and_android_states_require_real_tests": True,
            "never_overwrite_or_move_asset_ids_silently": True,
        },
        "assets": records,
    }


def normalize_for_check(text: str, repo: str) -> str:
    """Drop volatile provenance metadata before comparing index snapshots.

    `source_ref`, `source_commit` and the ref embedded in github_url change with
    the branch/commit the index was generated on; they must not make a
    content-identical index look stale (e.g. after merging into main).
    """
    obj = json.loads(text)
    obj.pop("source_ref", None)
    obj.pop("source_commit", None)
    rendered = json.dumps(obj, ensure_ascii=False, sort_keys=True)
    # neutralize the ref segment inside blob URLs
    import re
    rendered = re.sub(
        rf"(https://github\.com/{re.escape(repo)}/blob/)[^/\"]+/",
        r"\1CANONICAL_REF/",
        rendered,
    )
    return rendered


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--repo", default=os.getenv("GITHUB_REPOSITORY", REPO_DEFAULT))
    parser.add_argument("--ref", default=os.getenv("GITHUB_REF_NAME", "main"))
    parser.add_argument("--commit", default=os.getenv("GITHUB_SHA", ""))
    parser.add_argument("--output", type=Path, default=Path("ART_DEPARTMENT/CLOUD_AUTOMATION/ASSET_LIBRARY_INDEX.json"))
    parser.add_argument("--check", action="store_true", help="fail if the checked-in index is stale; do not write")
    args = parser.parse_args()
    root = args.root.resolve()
    output = args.output if args.output.is_absolute() else root / args.output
    data = build(root, args.repo, args.ref, args.commit)
    rendered = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    if args.check:
        if not output.is_file():
            print(f"Missing index: {output}", file=sys.stderr)
            return 1
        current = output.read_text(encoding="utf-8")
        if normalize_for_check(current, args.repo) != normalize_for_check(rendered, args.repo):
            print("ASSET_LIBRARY_INDEX.json is stale. Run the generator and commit the result.", file=sys.stderr)
            return 1
        print(f"PASS: {data['record_count']} records / {data['asset_file_count']} files")
        return 0
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(rendered, encoding="utf-8")
    print(f"Updated {output}: {data['record_count']} records / {data['asset_file_count']} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

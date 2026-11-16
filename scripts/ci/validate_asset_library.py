#!/usr/bin/env python3
"""Validate the RPG LBA asset catalog without third-party dependencies."""
from __future__ import annotations

import csv
import hashlib
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CATALOG = ROOT / "assets" / "library" / "catalog.csv"
MANIFEST = ROOT / "assets" / "manifest.csv"
REQUIRED = {
    "asset_id", "display_name", "category", "subcategory", "status",
    "source_url", "license_status", "license", "actual_path",
    "expected_path", "related_entity_id", "sha256", "notes",
}
STATUSES = {
    "MISSING", "PLANNED", "DISCOVERED", "LICENSE_REVIEW", "GENERATING",
    "PROCESSING", "QA", "REVIEW", "APPROVED", "INTEGRATED",
    "NEEDS_IMPROVEMENT", "REJECTED", "QUARANTINED",
}
errors: list[str] = []
warnings: list[str] = []


def read_csv(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    if not path.is_file():
        errors.append(f"Missing required file: {path.relative_to(ROOT)}")
        return [], []
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        return list(reader.fieldnames or []), list(reader)


headers, rows = read_csv(CATALOG)
missing = REQUIRED - set(headers)
if missing:
    errors.append(f"Catalog missing columns: {', '.join(sorted(missing))}")

ids: set[str] = set()
for line, row in enumerate(rows, start=2):
    asset_id = (row.get("asset_id") or "").strip()
    if not asset_id:
        errors.append(f"catalog.csv:{line}: empty asset_id")
    elif asset_id in ids:
        errors.append(f"catalog.csv:{line}: duplicate asset_id {asset_id}")
    ids.add(asset_id)

    status = (row.get("status") or "").strip()
    if status not in STATUSES:
        errors.append(f"catalog.csv:{line}: invalid status {status!r}")

    sha = (row.get("sha256") or "").strip()
    if sha and (len(sha) != 64 or any(c not in "0123456789abcdefABCDEF" for c in sha)):
        errors.append(f"catalog.csv:{line}: sha256 must be 64 hex chars")

    actual_path = (row.get("actual_path") or "").strip()
    if status in {"APPROVED", "INTEGRATED"} and not actual_path:
        errors.append(f"catalog.csv:{line}: {status} requires actual_path")
    if actual_path:
        candidate = (ROOT / actual_path).resolve()
        if ROOT.resolve() not in candidate.parents and candidate != ROOT.resolve():
            errors.append(f"catalog.csv:{line}: path escapes repository")
        elif not candidate.exists():
            errors.append(f"catalog.csv:{line}: actual_path does not exist: {actual_path}")
        elif status in {"APPROVED", "INTEGRATED"}:
            if not sha:
                errors.append(f"catalog.csv:{line}: {status} requires sha256")
            elif candidate.is_file():
                digest = hashlib.sha256(candidate.read_bytes()).hexdigest()
                if digest.lower() != sha.lower():
                    errors.append(f"catalog.csv:{line}: sha256 mismatch for {actual_path}")

    license_status = (row.get("license_status") or "").strip()
    if status in {"APPROVED", "INTEGRATED"} and license_status not in {"VERIFIED", "ORIGINAL"}:
        errors.append(f"catalog.csv:{line}: {status} requires VERIFIED or ORIGINAL license")

manifest_headers, manifest_rows = read_csv(MANIFEST)
if manifest_rows and "asset_name" not in manifest_headers:
    errors.append("assets/manifest.csv missing asset_name column")

print(f"Asset catalog rows: {len(rows)}")
print(f"Unique asset IDs: {len(ids)}")
print(f"Manifest rows: {len(manifest_rows)}")
for warning in warnings:
    print(f"WARNING: {warning}")
for error in errors:
    print(f"ERROR: {error}")
if errors:
    sys.exit(1)
print("PASS: asset library catalog structure")

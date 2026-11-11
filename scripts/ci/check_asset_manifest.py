#!/usr/bin/env python3
"""Basic audit: require a manifest row and verifiable source/license fields for every listed asset."""
import csv
import sys
from pathlib import Path

manifest = Path(sys.argv[1] if len(sys.argv) > 1 else "assets/manifest.csv")
if not manifest.exists():
    print(f"NOT READY: {manifest} does not exist. Create it when third-party assets are introduced.")
    sys.exit(0)

required = ["asset_id", "asset_name", "author", "source_url", "license", "license_url", "checked_date", "local_path"]
with manifest.open(newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    missing_headers = [name for name in required if name not in (reader.fieldnames or [])]
    if missing_headers:
        print("FAIL: missing manifest headers:", ", ".join(missing_headers))
        sys.exit(1)
    rows = list(reader)

errors = []
for index, row in enumerate(rows, start=2):
    for field in required:
        if not (row.get(field) or "").strip():
            errors.append(f"line {index}: empty {field}")
if errors:
    print("FAIL: asset manifest incomplete")
    print("\n".join(errors))
    sys.exit(1)
print(f"PASS: {len(rows)} asset manifest rows have required metadata. Human license review is still required.")

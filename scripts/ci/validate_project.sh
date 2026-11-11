#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${1:-.}"
GODOT_BIN="${GODOT_BIN:-godot}"
LOG_DIR="${PROJECT_DIR}/artifacts/local-ci"
mkdir -p "$LOG_DIR"

if [[ ! -f "$PROJECT_DIR/project.godot" ]]; then
  echo "ERROR: project.godot not found in $PROJECT_DIR" >&2
  exit 2
fi

"$GODOT_BIN" --version
"$GODOT_BIN" --headless --editor --path "$PROJECT_DIR" --quit --verbose 2>&1 | tee "$LOG_DIR/import.log"
if grep -E "SCRIPT ERROR:|Parse Error|Failed loading resource|ERROR:" "$LOG_DIR/import.log"; then
  echo "Import reported critical errors." >&2
  exit 1
fi

timeout 90s "$GODOT_BIN" --headless --audio-driver Dummy --path "$PROJECT_DIR" --quit-after 180 2>&1 | tee "$LOG_DIR/smoke.log"
if grep -E "SCRIPT ERROR:|Parse Error|Failed loading resource|ERROR:" "$LOG_DIR/smoke.log"; then
  echo "Smoke test reported critical errors." >&2
  exit 1
fi

echo "PASS: headless import and smoke completed. This does not replace visual or physical-device tests."

#!/usr/bin/env bash
# Envoltorio local del smoke multijugador (servidor dedicado + 2 clientes headless).
# Localiza Godot y delega en tests/multiplayer/run_multiplayer_smoke.sh.
set -euo pipefail

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project="$(cd -- "$here/../.." && pwd)"

if [[ -z "${GODOT_BIN:-}" ]]; then
        if command -v godot >/dev/null 2>&1; then
                GODOT_BIN="$(command -v godot)"
        else
                echo "ERROR: Godot no encontrado. Instala Godot 4.7.2 Standard y" >&2
                echo "ponlo en PATH o exporta GODOT_BIN=/ruta/a/Godot_v4.7.2-stable_linux.x86_64" >&2
                exit 127
        fi
fi

if ! "$GODOT_BIN" --version 2>/dev/null | grep -q "^4.7.2"; then
        echo "ADVERTENCIA: se esperaba Godot 4.7.2; version detectada:" >&2
        "$GODOT_BIN" --version >&2 || true
        echo "Continuando bajo tu responsabilidad (ADR-001 fija 4.7.2)." >&2
fi

exec bash "$project/tests/multiplayer/run_multiplayer_smoke.sh" "$project"

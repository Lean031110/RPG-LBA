#!/usr/bin/env bash
# Suite de capturas visuales para CI (mandato §10.G).
# Requiere: DISPLAY activo (Xvfb), GODOT apuntando al binario 4.7.2,
# y una importacion previa de recursos.
set -uo pipefail
OUT="${1:-artifacts/visual}"
GODOT="${GODOT:?GODOT must point to the Godot 4.7.2 binary}"
mkdir -p "$OUT"

declare -a SCENES=(
  "menu_principal|scenes/arpg/menu/main_menu.tscn||1280x720"
  "menu_principal_209|scenes/arpg/menu/main_menu.tscn||1600x720"
  "presentacion|scenes/arpg/menu/intro_splash.tscn||1280x720"
  "ajustes|scenes/arpg/menu/settings_menu.tscn||1280x720"
  "creditos|scenes/arpg/menu/credits_menu.tscn||1280x720"
  "multijugador|scenes/arpg/menu/multiplayer_menu.tscn||1280x720"
  "partida_valdeluz_169|scenes/arpg/valdeluz/valdeluz_slice.tscn||1280x720"
  "partida_valdeluz_209|scenes/arpg/valdeluz/valdeluz_slice.tscn||1600x720"
  "inventario_valdeluz|scenes/arpg/valdeluz/valdeluz_slice.tscn|inventory|1280x720"
)

failed=0
for entry in "${SCENES[@]}"; do
  IFS='|' read -r name scene extra res <<< "$entry"
  echo "[visual] $name ($res)"
  timeout 90 "$GODOT" --path . --rendering-driver opengl3 --audio-driver Dummy \
    --script res://scripts/local/capture_hud.gd -- \
    "$scene" "$res" "$OUT/${name}.png" "$extra" 2>&1 \
    | grep -E 'CAPTURED|CAPTURE_FAILED|SCRIPT ERROR' || true
  if [ ! -s "$OUT/${name}.png" ]; then
    echo "[visual] ERROR: $name no produjo PNG"
    failed=1
  fi
done
exit $failed

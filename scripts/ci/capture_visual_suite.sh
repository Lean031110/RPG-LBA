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
  "artpass_terrain_benchmark_169|scenes/dev/art_benchmark/terrain_benchmark.tscn||1280x720"
  "artpass_terrain_benchmark_209|scenes/dev/art_benchmark/terrain_benchmark.tscn||1600x720"
  "artpass_path_alternatives_169|scenes/dev/art_benchmark/terrain_path_alternatives.tscn||1280x720"
  "artpass_path_alternatives_209|scenes/dev/art_benchmark/terrain_path_alternatives.tscn||1600x720"
)

failed=0
for entry in "${SCENES[@]}"; do
  IFS='|' read -r name scene extra res <<< "$entry"
  echo "[visual] $name ($res)"
  target="${OUT}/${name}.png"
  log_path="${OUT}/${name}.log"
  if [[ -e "$target" || -e "$log_path" ]]; then
    echo "[visual] ERROR: refusing to overwrite existing output for $name"
    failed=1
    continue
  fi
  tmpdir="$(mktemp -d "${OUT}/.${name}.XXXXXX")" || {
    echo "[visual] ERROR: could not create temporary directory for $name"
    failed=1
    continue
  }
  tmp_png="${tmpdir}/${name}.png"
  tmp_log="${tmpdir}/${name}.log"
  timeout 90 "$GODOT" --path . --rendering-driver opengl3 --audio-driver Dummy \
    --script res://scripts/local/capture_hud.gd -- \
    "$scene" "$res" "$tmp_png" "$extra" >"$tmp_log" 2>&1
  godot_status=$?
  grep -E 'CAPTURED|CAPTURE_FAILED|SCRIPT ERROR' "$tmp_log" || true
  if [ "$godot_status" -ne 0 ]; then
    echo "[visual] ERROR: Godot exited with status $godot_status for $name"
    tail -n 30 "$tmp_log"
    failed=1
  elif [ ! -s "$tmp_png" ]; then
    echo "[visual] ERROR: $name no produjo PNG"
    tail -n 30 "$tmp_log"
    failed=1
  elif ! mv "$tmp_png" "$target"; then
    echo "[visual] ERROR: could not publish PNG for $name"
    failed=1
  else
    mv "$tmp_log" "$log_path"
    echo "[visual] PASS: $target"
  fi
  if [ -f "$tmp_log" ] && [ ! -e "$log_path" ]; then
    mv "$tmp_log" "$log_path"
  fi
  rm -rf -- "$tmpdir"
done
exit $failed

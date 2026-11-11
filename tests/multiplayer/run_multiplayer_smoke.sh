#!/usr/bin/env bash
# Headless multiplayer smoke: 1 dedicated server + 2 independent clients on 127.0.0.1.
# Usage: GODOT_BIN=/path/to/Godot_v4.7.2-stable_linux.x86_64 PROJECT_DIR=. ./run_multiplayer_smoke.sh
# Reproduces the Phase 0 requirement "server with two clients" in CI without GPU.
# Each driver quits on its own (PASS after 2 registered players, FAIL after ~25s timeout).
set -uo pipefail

GODOT_BIN="${GODOT_BIN:?GODOT_BIN must point to the Godot 4.7.2 binary}"
PROJECT_DIR="${1:-.}"
LOG_DIR="${PROJECT_DIR}/artifacts/logs"
DRIVER_SCENE="res://tests/multiplayer/mp_driver.tscn"

mkdir -p "$LOG_DIR"

server_pid=""
client_a_pid=""
client_b_pid=""
cleanup() {
  for pid in "$server_pid" "$client_a_pid" "$client_b_pid"; do
    if [ -n "${pid:-}" ] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null
    fi
  done
}
trap cleanup EXIT INT TERM

echo "[mp-smoke] starting dedicated server (headless)"
LBA_MP_ROLE=server "$GODOT_BIN" --headless --audio-driver Dummy --path "$PROJECT_DIR" "$DRIVER_SCENE" \
  > "$LOG_DIR/mp_server.log" 2>&1 &
server_pid=$!
sleep 3

echo "[mp-smoke] starting client A and client B"
LBA_MP_ROLE=client LBA_MP_JOIN_DELAY=1.0 "$GODOT_BIN" --headless --audio-driver Dummy --path "$PROJECT_DIR" "$DRIVER_SCENE" \
  > "$LOG_DIR/mp_client_a.log" 2>&1 &
client_a_pid=$!

LBA_MP_ROLE=client LBA_MP_JOIN_DELAY=2.5 "$GODOT_BIN" --headless --audio-driver Dummy --path "$PROJECT_DIR" "$DRIVER_SCENE" \
  > "$LOG_DIR/mp_client_b.log" 2>&1 &
client_b_pid=$!

wait "$client_a_pid"; client_a_exit=$?
wait "$client_b_pid"; client_b_exit=$?
wait "$server_pid"; server_exit=$?

echo "[mp-smoke] exit codes: server=$server_exit client_a=$client_a_exit client_b=$client_b_exit"
grep -h "LBA_MP_RESULT" "$LOG_DIR/mp_server.log" "$LOG_DIR/mp_client_a.log" "$LOG_DIR/mp_client_b.log" || true

if [ "$server_exit" -ne 0 ] || [ "$client_a_exit" -ne 0 ] || [ "$client_b_exit" -ne 0 ]; then
  echo "[mp-smoke] FAIL (non-zero exit code)"
  exit 1
fi
if ! grep -q "status=PASS" "$LOG_DIR/mp_server.log" \
  || ! grep -q "status=PASS" "$LOG_DIR/mp_client_a.log" \
  || ! grep -q "status=PASS" "$LOG_DIR/mp_client_b.log"; then
  echo "[mp-smoke] FAIL (missing PASS markers)"
  exit 1
fi
echo "[mp-smoke] PASS: server and two clients registered and spawned players."
exit 0

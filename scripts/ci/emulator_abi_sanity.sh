#!/usr/bin/env bash
# Sanity de instalacion de la variante ARM64 en un emulador x86_64.
#
# CONTEXTO (verificado en la corrida 43471820109): el emulador de GitHub se
# niega a arrancar AVDs arm64 en host x86_64 ("Avd's CPU Architecture 'arm64'
# is not supported by the QEMU2 emulator on x86_64 host"). No hay forma
# honesta de EJECUTAR el APK arm64 en CI con estos runners. Lo que SI se puede
# verificar aqui:
#   1. `adb install` del APK arm64 en un emulador x86_64 llega HASTA la
#      comprobacion de ABI: eso significa que PackageManager lo PARSEO, valido
#      la firma v2/v3 y el manifiesto, y solo entonces lo rechazo con
#      INSTALL_FAILED_NO_MATCHING_ABIS (el rechazo EXACTO y esperado).
#   2. Si la imagen tuviera traduccion ARM (no es el caso hoy), el install
#      diria Success y este script seguira con el arranque normal.
#
# Esto NO es una prueba de ejecucion en arm64: eso queda PENDIENTE DE HARDWARE
# (telefono fisico, host arm64 o runner autohospedado).
#
# Env:
#   ANDROID_IMAGE   imagen x86_64 ya instalada por el workflow
#   AVD_NAME        nombre del AVD (default rpglba_ci_x86)
#   APK             ruta al APK ARM64
#   OUT             directorio de evidencia
#   PACKAGE         package id
set -euo pipefail

ANDROID_IMAGE="${ANDROID_IMAGE:?ANDROID_IMAGE requerida}"
AVD_NAME="${AVD_NAME:-rpglba_ci_x86}"
APK="${APK:?APK requerida}"
OUT="${OUT:?OUT requerido}"
PACKAGE="${PACKAGE:-com.lbagames.rpglba}"

mkdir -p "$OUT"
export ANDROID_AVD_HOME="${ANDROID_AVD_HOME:-$HOME/.android/avd}"
mkdir -p "$ANDROID_AVD_HOME"

echo "== AVD =="
avdmanager delete avd -n "$AVD_NAME" >/dev/null 2>&1 || true
echo no | avdmanager create avd -n "$AVD_NAME" -k "$ANDROID_IMAGE" --device pixel >/dev/null
if [ ! -f "$ANDROID_AVD_HOME/$AVD_NAME.ini" ]; then
  echo "ERROR: avdmanager no dejo el ini." >&2
  exit 1
fi

echo "== Boot =="
nohup emulator -avd "$AVD_NAME" -no-window -gpu angle_indirect -noaudio \
  -no-boot-anim -no-snapshot -accel on > /tmp/emulator.log 2>&1 &
EMU_PID=$!
_emu_alive() { kill -0 "$EMU_PID" 2>/dev/null; }
deadline=$((SECONDS + 480))
while :; do
  state="$(adb devices 2>/dev/null | awk 'NR>1 && NF {print $2}' | head -n1)"
  if [ "${state:-}" = "device" ]; then break; fi
  if ! _emu_alive; then echo "ERROR: el emulador murio antes de conectar." >&2; tail -n 40 /tmp/emulator.log >&2; exit 1; fi
  if [ "$SECONDS" -ge "$deadline" ]; then echo "ERROR: no llego a 'device'." >&2; exit 1; fi
  sleep 5
done
deadline=$((SECONDS + 480))
while [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
  if ! _emu_alive; then echo "ERROR: murio durante el arranque." >&2; exit 1; fi
  if [ "$SECONDS" -ge "$deadline" ]; then echo "ERROR: boot_completed no llego." >&2; exit 1; fi
  sleep 5
done
echo "Emulator booted."
adb shell input keyevent 82 || true

echo "== Install del APK ARM64 en x86_64 (rechazo esperado por ABI) =="
set +e
adb install -r "$APK" | tee "$OUT/install.txt"
INSTALL_RC=${PIPESTATUS[0]}
set -e
if grep -q "Success" "$OUT/install.txt"; then
  echo "NOTE: la imagen ACEPTO el APK arm64 (traduccion ARM presente); seguimos con arranque."
  echo "abi_sanity=accepted_with_translation" | tee -a "$OUT/install.txt"
  COMPONENT=$(adb shell cmd package resolve-activity --brief "$PACKAGE" | tail -n 1 | tr -d '\r')
  echo "$COMPONENT" | grep -q "/" || { echo "ERROR: sin actividad lanzable." >&2; exit 1; }
  adb shell am start -n "$COMPONENT"
  sleep 25
  if [ -z "$(adb shell pidof "$PACKAGE" | tr -d '\r')" ]; then
    echo "ERROR: el proceso no esta vivo 25s tras lanzar." >&2
    exit 1
  fi
  adb exec-out screencap -p > "$OUT/screenshot_01_menu_arm64_apk.png"
  echo "abi_sanity_result=installed_and_launched" | tee -a "$OUT/install.txt"
elif grep -q "INSTALL_FAILED_NO_MATCHING_ABIS" "$OUT/install.txt"; then
  # Llego hasta la comprobacion de ABI: parseo de APK, firma y manifiesto OK.
  echo "PASS: rechazo exacto INSTALL_FAILED_NO_MATCHING_ABIS (parseo+firma validados; ABI correcta)." | tee -a "$OUT/install.txt"
  echo "abi_sanity_result=rejected_by_abi_as_expected" | tee -a "$OUT/install.txt"
else
  echo "ERROR: fallo de instalacion INESPERADO (ni Success ni NO_MATCHING_ABIS): rc=$INSTALL_RC" >&2
  cat "$OUT/install.txt" >&2
  exit 1
fi

adb logcat -d > "$OUT/logcat.txt" || true
echo "== Cleanup =="
adb uninstall "$PACKAGE" >/dev/null 2>&1 || true
adb emu kill || true
pkill -f qemu-system || true
echo "RESULT: PASS - sanity de ABI de la variante ARM64 completado (ver cabecera para limites)."

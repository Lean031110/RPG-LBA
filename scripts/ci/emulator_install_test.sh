#!/usr/bin/env bash
# Prueba de instalacion y arranque de un APK de RPG LBA en un emulador headless.
# Genera evidencia real (capturas, logcat, informe de instalacion, PERF) y falla
# si hay crash, si no se instala o si no se presenta un fotograma no negro.
#
# NO sustituye la prueba en dispositivo fisico: queda NOT TESTED en hardware real.
#
# Env:
#   ANDROID_IMAGE   imagen del sistema, p.ej. "system-images;android-36;default;x86_64"
#   AVD_NAME        nombre del AVD (default rpglba_ci)
#   APK             ruta al APK a instalar
#   OUT             directorio de evidencia (se crea)
#   PACKAGE         package id (default com.lbagames.rpglba)
#   BOOT_BUDGET_S   presupuesto de arranque en s (default 480; ARM64 necesita mas)
#   RENDER_BUDGET_S presupuesto del primer fotograma no negro en s (default 240)
#   TRY_VALDELUZ    "1" = capturar tambien una escena jugable:
#                   tap "Nueva partida" -> "Jugar" (Valdeluz); si falla, fallback
#                   a "Prototipo (Fase 2)" con relanzamiento.
#
# Requiere: adb/avdmanager/emulator en PATH, KVM accesible, y que sdkmanager ya
# haya instalado la imagen ANDROID_IMAGE.
set -euo pipefail

ANDROID_IMAGE="${ANDROID_IMAGE:?ANDROID_IMAGE requerida}"
AVD_NAME="${AVD_NAME:-rpglba_ci}"
APK="${APK:?APK requerida}"
OUT="${OUT:?OUT requerido}"
PACKAGE="${PACKAGE:-com.lbagames.rpglba}"
BOOT_BUDGET_S="${BOOT_BUDGET_S:-480}"
RENDER_BUDGET_S="${RENDER_BUDGET_S:-240}"
TRY_VALDELUZ="${TRY_VALDELUZ:-1}"

mkdir -p "$OUT"
export ANDROID_AVD_HOME="${ANDROID_AVD_HOME:-$HOME/.android/avd}"
mkdir -p "$ANDROID_AVD_HOME"

echo "== AVD =="
avdmanager delete avd -n "$AVD_NAME" >/dev/null 2>&1 || true
echo no | avdmanager create avd -n "$AVD_NAME" -k "$ANDROID_IMAGE" --device pixel >/dev/null
if [ ! -f "$ANDROID_AVD_HOME/$AVD_NAME.ini" ]; then
  echo "ERROR: avdmanager no dejo el ini en ANDROID_AVD_HOME." >&2
  exit 1
fi
emulator -list-avds || true

echo "== Boot (presupuesto ${BOOT_BUDGET_S}s) =="
nohup emulator -avd "$AVD_NAME" -no-window -gpu angle_indirect -noaudio \
  -no-boot-anim -no-snapshot -accel on > /tmp/emulator.log 2>&1 &
EMU_PID=$!
_emu_alive() { kill -0 "$EMU_PID" 2>/dev/null; }
_emu_dump() { echo "--- emulator.log (tail) ---" >&2; tail -n 60 /tmp/emulator.log >&2 || true; }

deadline=$((SECONDS + BOOT_BUDGET_S))
while :; do
  state="$(adb devices 2>/dev/null | awk 'NR>1 && NF {print $2}' | head -n1)"
  if [ "${state:-}" = "device" ]; then break; fi
  if ! _emu_alive; then echo "ERROR: el emulador murio antes de conectar." >&2; _emu_dump; exit 1; fi
  if [ "$SECONDS" -ge "$deadline" ]; then echo "ERROR: no llego a 'device' en ${BOOT_BUDGET_S}s." >&2; _emu_dump; exit 1; fi
  sleep 5
done
deadline=$((SECONDS + BOOT_BUDGET_S))
while [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
  if ! _emu_alive; then echo "ERROR: el emulador murio durante el arranque." >&2; _emu_dump; exit 1; fi
  if [ "$SECONDS" -ge "$deadline" ]; then echo "ERROR: boot_completed no llego en ${BOOT_BUDGET_S}s." >&2; _emu_dump; exit 1; fi
  sleep 5
done
echo "Emulator booted."
adb shell input keyevent 82 || true

echo "== Install =="
adb install -r "$APK" | tee "$OUT/install.txt"
grep -q "Success" "$OUT/install.txt" || { echo "ERROR: adb install no reporto Success." >&2; exit 1; }

echo "== Launch =="
adb logcat -c
# Prevenir el dialogo de consentimiento inmersivo (panel claro que atrapa los
# taps; corridas 43474930008/43476646209/43478758547: cubria ~60% superior, no se
# cancela con BACK y todo el flujo daba falsos positivos). Mecanismo canonico
# AOSP: Settings.Secure.IMMERSIVE_MODE_CONFIRMATIONS = "confirmed" marca el
# consentimiento como ya dado y el dialogo no llega a mostrarse.
adb shell settings put secure immersive_mode_confirmations confirmed > /dev/null 2>&1 || true
COMPONENT=$(adb shell cmd package resolve-activity --brief "$PACKAGE" | tail -n 1 | tr -d '\r')
echo "Launchable component: $COMPONENT" | tee -a "$OUT/install.txt"
echo "$COMPONENT" | grep -q "/" || { echo "ERROR: sin actividad lanzable." >&2; exit 1; }
adb shell am start -n "$COMPONENT"
sleep 25
PID=$(adb shell pidof "$PACKAGE" | tr -d '\r')
if [ -z "$PID" ]; then
  echo "ERROR: el proceso no esta vivo 25s tras el lanzamiento." >&2
  adb logcat -d | tail -80 >&2
  exit 1
fi
echo "Process alive (pid $PID) 25s after launch."

# Dialogo inmersivo de respaldo: si quedara un panel claro, uiautomator
# localiza el boton positivo (Allow/Permitir) y lo pulsa; BACK como ultima
# instancia (lecciones de la corrida 43478758547: el dialogo no se cancela con
# BACK y central luma quedo clavado en ~179).
_dismiss_immersive_notice() {
  adb exec-out screencap > /tmp/frame.raw || true
  local top_bright
  top_bright=$(python3 - <<'PY'
import struct
try:
    d = open('/tmp/frame.raw', 'rb').read()
    w, h, fmt = struct.unpack('<III', d[:12])
    px = d[12:]
    x0, x1 = int(w * 0.20), int(w * 0.80)
    y0, y1 = int(h * 0.06), int(h * 0.30)
    total = 0
    count = 0
    stride = w * 4
    for y in range(y0, y1, 4):
        row = px[y * stride:(y + 1) * stride]
        for x in range(x0, x1, 4):
            o = x * 4
            total += (row[o] + row[o + 1] + row[o + 2]) / 3.0
            count += 1
    print(int(total / max(count, 1)))
except Exception:
    print(0)
PY
)
  if [ "${top_bright:-0}" -lt 120 ]; then
    echo "NOTE: sin dialogo inmersivo (banda superior luma=$top_bright)."
    return 0
  fi
  echo "NOTE: dialogo inmersivo presente (banda superior luma=$top_bright); intentando descartarlo."
  # 1) Pulsar el boton positivo via uiautomator (el dialogo del sistema SI expone
  #    su jerarquia de accesibilidad, a diferencia de la UI del juego Godot).
  adb shell uiautomator dump /sdcard/ui.xml > /dev/null 2>&1 || true
  adb shell cat /sdcard/ui.xml > /tmp/ui.xml 2>/dev/null || true
  local bounds
  bounds=$(python3 - <<'PY'
import re
try:
    d = open('/tmp/ui.xml', encoding='utf-8', errors='replace').read()
    for word in ['Permitir', 'Allow', 'ALLOW', 'permitir']:
        m = re.search(r'text="[^"]*' + word + r'[^"]*"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', d)
        if m:
            x1, y1, x2, y2 = map(int, m.groups())
            if x2 > x1 and y2 > y1:
                print((x1 + x2) // 2, (y1 + y2) // 2)
                break
except Exception:
    pass
PY
)
  if [ -n "${bounds:-}" ]; then
    local bx by
    read -r bx by <<EOF
$bounds
EOF
    echo "NOTE: pulsando boton positivo del dialogo en ($bx, $by)."
    adb shell input tap "$bx" "$by"
    sleep 3
  fi
  # 2) Verificar; si sigue el panel, BACK como ultima instancia.
  adb exec-out screencap > /tmp/frame.raw || true
  local still
  still=$(python3 - <<'PY'
import struct
try:
    d = open('/tmp/frame.raw', 'rb').read()
    w, h, fmt = struct.unpack('<III', d[:12])
    px = d[12:]
    x0, x1 = int(w * 0.20), int(w * 0.80)
    y0, y1 = int(h * 0.06), int(h * 0.30)
    total = 0
    count = 0
    stride = w * 4
    for y in range(y0, y1, 4):
        row = px[y * stride:(y + 1) * stride]
        for x in range(x0, x1, 4):
            o = x * 4
            total += (row[o] + row[o + 1] + row[o + 2]) / 3.0
            count += 1
    print(int(total / max(count, 1)))
except Exception:
    print(0)
PY
)
  if [ "${still:-0}" -ge 120 ]; then
    echo "NOTE: el panel sigue (luma=$still); BACK como ultima instancia."
    adb shell input keyevent 4
    sleep 3
  else
    echo "NOTE: dialogo descartado (luma tras el intento: $still)."
  fi
}
_dismiss_immersive_notice

_dump_failure_evidence() {
  # En cualquier fallo: dejar captura, logcat y foco de ventana en $OUT para
  # poder diagnosticar desde el artefacto (lecciones de las corridas 43474930008
  # y 43473507397: sin esto, el fallo no deja evidencia).
  adb exec-out screencap -p > "$OUT/screenshot_failure.png" || true
  adb shell dumpsys window windows 2>/dev/null | tr -d '\r' | grep -m4 -E 'mCurrentFocus|mFocusedApp' > "$OUT/window_focus.txt" || true
  adb logcat -d > "$OUT/logcat.txt" || true
  echo "---- logcat Godot/shader (head) ----"
  grep -m40 -iE 'godot|shader|ERROR' "$OUT/logcat.txt" || true
}

_foreground_ok() {
  TOP="$(adb shell dumpsys activity activities 2>/dev/null | tr -d '\r' | grep -m1 -E 'topResumedActivity|mResumedActivity' || true)"
  echo "$TOP" | grep -q "$PACKAGE"
}

_luma_probe() {
  # Promedio de luma de la region central (sin franja superior del aviso del
  # sistema). Umbral 7: "no negro". Devuelve el entero por stdout.
  adb exec-out screencap > /tmp/frame.raw || true
  python3 - <<'PY'
import struct
try:
    d = open('/tmp/frame.raw', 'rb').read()
    w, h, fmt = struct.unpack('<III', d[:12])
    px = d[12:]
    x0, x1 = int(w * 0.25), int(w * 0.75)
    y0, y1 = int(h * 0.30), int(h * 0.75)
    total = 0
    count = 0
    stride = w * 4
    for y in range(y0, y1, 8):
        row = px[y * stride:(y + 1) * stride]
        for x in range(x0, x1, 8):
            o = x * 4
            total += row[o] + row[o + 1] + row[o + 2]
            count += 3
    print(int(total / max(count, 1)))
except Exception:
    print(0)
PY
}

_sky_probe() {
  # "1" si la franja superior parece cielo del juego (azul por encima de rojo
  # y con brillo); "0" si no. Discrimina la escena 3D del menu (fondo casi negro).
  adb exec-out screencap > /tmp/frame.raw || true
  python3 - <<'PY'
import struct
try:
    d = open('/tmp/frame.raw', 'rb').read()
    w, h, fmt = struct.unpack('<III', d[:12])
    px = d[12:]
    x0, x1 = int(w * 0.20), int(w * 0.80)
    y0, y1 = int(h * 0.04), int(h * 0.18)
    blue = 0
    red = 0
    count = 0
    stride = w * 4
    for y in range(y0, y1, 4):
        row = px[y * stride:(y + 1) * stride]
        for x in range(x0, x1, 4):
            o = x * 4
            red += row[o]
            blue += row[o + 2]
            count += 1
    if count == 0:
        print(0)
    else:
        b = blue / count
        r = red / count
        print(1 if (b >= 60.0 and b >= r + 10.0) else 0)
except Exception:
    print(0)
PY
}

# _wait_render <presupuesto_s> <etiqueta>
# Devuelve 0 si se presento un fotograma no negro; 1 si no (sin exit).
_wait_render() {
  local budget="$1" label="$2" mean=0
  local deadline=$((SECONDS + budget))
  while [ "$SECONDS" -lt "$deadline" ]; do
    if ! _foreground_ok; then
      echo "ERROR: el juego dejo de estar en primer plano esperando $label." >&2
      adb logcat -d | tail -60 >&2 || true
      return 1
    fi
    mean=$(_luma_probe)
    echo "render probe [$label]: central mean luma = $mean (threshold 7)"
    if [ "$mean" -ge 7 ]; then
      echo "First render confirmed [$label] (mean=$mean)."
      return 0
    fi
    sleep 10
  done
  echo "ERROR: sin fotograma no negro en ${budget}s para $label (mean=$mean)." >&2
  adb logcat -d | tail -60 >&2 || true
  return 1
}

echo "== Menu render =="
if ! _wait_render "$RENDER_BUDGET_S" menu; then
  echo "ERROR: el menu no se presento." >&2
  _dump_failure_evidence
  exit 1
fi
adb exec-out screencap -p > "$OUT/screenshot_01_menu.png"

# Coordenadas de tap en px de pantalla a partir del layout medido del menu
# (scripts/local/measure_menu_layout.gd; canvas 1280x720, stretch expand):
#   Nueva partida: (w/2, 423*escala);  Jugar: (w/2+174*esc, h/2+159*esc);
#   Prototipo:     (w/2, 489*escala).  escala = min(w/1280, h/720) en landscape.
# Los taps caen en el centro de la pantalla: lejos de la zona de gesto del
# sistema (leccion de la corrida 43339724542).
# IMPORTANTE: las dimensiones se toman de la CAPTURA REAL (screencap), no de
# `wm size`: en la corrida 43480672530, wm size informaba 2880x1080 mientras el
# framebuffer era 1920x1080 y los taps caian fuera de los botones.
adb exec-out screencap > /tmp/tap_frame.raw || true
adb shell wm size | tr -d '\r' > "$OUT/wm_size.txt" || true
read -r T1_X T1_Y T2_X T2_Y T3_X T3_Y <<EOF
$(python3 - <<'PY'
import struct
d = open('/tmp/tap_frame.raw', 'rb').read()
w, h, _fmt = struct.unpack('<III', d[:12])
# landscape: el juego fuerza sensor_landscape; ordenar por si el raw viniera en portrait.
if w < h:
    w, h = h, w
scale = min(w / 1280.0, h / 720.0)
def pt(x, y):
    return int(round(x * scale)), int(round(y * scale))
t1 = pt(w / 2, 423)          # Nueva partida (centro X = w/2)
t2x, t2y = pt(174, 159)      # Jugar: offset del panel de clase respecto al centro
t2 = (int(round(w / 2 + t2x)), int(round(h / 2 + t2y)))
t3 = pt(w / 2, 489)          # Prototipo (Fase 2)
print(t1[0], t1[1], t2[0], t2[1], t3[0], t3[1])
PY
)
EOF
echo "taps (pantalla real): nueva_partida=($T1_X,$T1_Y) jugar=($T2_X,$T2_Y) prototipo=($T3_X,$T3_Y)"
cat "$OUT/wm_size.txt" || true

if [ "$TRY_VALDELUZ" = "1" ]; then
  echo "== Escena jugable: Valdeluz (mejor esfuerzo, fallback a Prototipo) =="
  adb shell input tap "$T1_X" "$T1_Y"
  sleep 2
  adb shell input tap "$T2_X" "$T2_Y"
  # Asentamiento: dar tiempo al cambio de escena ANTES de sondear; si no, el
  # probe ve el menu todavia en pantalla y da un falso positivo (evidenciado en
  # la corrida 43471820109: capturas identicas byte a byte).
  sleep 8
  scene_ok=0
  deadline=$((SECONDS + RENDER_BUDGET_S))
  while [ "$SECONDS" -lt "$deadline" ]; do
    if ! _foreground_ok; then
      echo "NOTE: el juego salio de primer plano tras los taps." >&2
      break
    fi
    mean=$(_luma_probe)
    sky=$(_sky_probe)
    echo "render probe [valdeluz]: luma=$mean sky=$sky"
    if [ "$mean" -ge 7 ] && [ "$sky" = "1" ]; then
      scene_ok=1
      break
    fi
    sleep 10
  done
  if [ "$scene_ok" = "1" ]; then
    adb exec-out screencap -p > "$OUT/screenshot_02_valdeluz.png"
    # Guarda extra: si la captura es identica a la del menu, el cambio no ocurrio.
    if cmp -s "$OUT/screenshot_01_menu.png" "$OUT/screenshot_02_valdeluz.png"; then
      echo "NOTE: captura de Valdeluz identica al menu (transicion no capturada)." | tee -a "$OUT/install.txt"
      scene_ok=0
    fi
  fi
  if [ "$scene_ok" = "1" ]; then
    echo "playable_capture=valdeluz" | tee -a "$OUT/install.txt"
  else
    echo "NOTE: Valdeluz no presento fotograma con cielo; relanzo para Prototipo." | tee -a "$OUT/install.txt"
    adb shell am force-stop "$PACKAGE"
    sleep 2
    adb shell am start -n "$COMPONENT"
    sleep 25
    if ! _wait_render 120 menu_relance; then
      echo "ERROR: el menu no se presento tras relanzar." >&2
      _dump_failure_evidence
      exit 1
    fi
    adb shell input tap "$T3_X" "$T3_Y"
    sleep 8
    if _wait_render "$RENDER_BUDGET_S" prototipo; then
      adb exec-out screencap -p > "$OUT/screenshot_02_prototipo.png"
      if cmp -s "$OUT/screenshot_01_menu.png" "$OUT/screenshot_02_prototipo.png"; then
        echo "ERROR: captura del Prototipo identica al menu (el tap no entro)." >&2
        _dump_failure_evidence
        exit 1
      fi
      echo "playable_capture=prototipo_fallback" | tee -a "$OUT/install.txt"
    else
      echo "ERROR: tampoco el Prototipo presento fotograma." >&2
      exit 1
    fi
  fi
fi

echo "== Crashes / telemetria =="
if adb logcat -d | grep -q "FATAL EXCEPTION"; then
  echo "ERROR: FATAL EXCEPTION en logcat." >&2
  adb logcat -d | grep -A20 "FATAL EXCEPTION" >&2 || true
  _dump_failure_evidence
  exit 1
fi
adb logcat -d | grep "PERF:" > "$OUT/perf_emulator.txt" || true
adb logcat -d > "$OUT/logcat.txt"
adb logcat -d | grep -m1 "Godot Engine" || echo "note: sin banner Godot en logcat (no fatal por si mismo)."
if [ -s "$OUT/perf_emulator.txt" ]; then
  echo "Telemetria PERF del proceso (emulador; NO es benchmark de dispositivo):"
  head -n 4 "$OUT/perf_emulator.txt"
fi

echo "== Cleanup =="
adb uninstall "$PACKAGE" || true
adb emu kill || true
pkill -f qemu-system || true

echo "RESULT: PASS - instalado, arrancado, capturado y sin crashes."
